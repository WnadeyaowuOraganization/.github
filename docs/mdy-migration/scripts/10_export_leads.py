#!/usr/bin/env python3
"""
明道云 sjcj（线索池）→ wande-ai.crm_leads 迁移脚本
Issue #4014: 线索统一池 + 评分引擎

用法:
  python3 10_export_leads.py --dry-run      # 仅预览，不写入
  python3 10_export_leads.py --execute      # 正式迁移（执行前需 mysqldump 快照）
  python3 10_export_leads.py --validate     # 迁移后验收断言

依赖:
  pip install pymongo pymysql

数据源:
  MongoDB: mongodb-mdy (m7i 54.234.200.59:27017)
  集合: mdwsrows.ws6886d61c074a71b93636d2da
  行数: 8,895 条（明道云"线索(sjcj)"工作表）

目标:
  MySQL: wande-ai.crm_leads
  DDL 由 Flyway V20260422013120 + V20260422203756 确保已创建
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from typing import Optional

# ──────────────────────────────────────────────
# 连接配置（从环境变量读取，兜底硬编码）
# ──────────────────────────────────────────────
import os

MONGO_URI = os.getenv("MDY_MONGO_URI", "mongodb://127.0.0.1:27017")
MDY_DB_NAME = "mongodb-mdy"
MDY_COLLECTION = "mdwsrows.ws6886d61c074a71b93636d2da"

TARGET_MYSQL = dict(
    host=os.getenv("TARGET_MYSQL_HOST", "127.0.0.1"),
    port=int(os.getenv("TARGET_MYSQL_PORT", "3306")),
    user=os.getenv("TARGET_MYSQL_USER", "root"),
    password=os.getenv("TARGET_MYSQL_PASS", "root"),
    db=os.getenv("TARGET_MYSQL_DB", "wande-ai"),
    charset="utf8mb4",
)

# 明道云 controlId 映射
CTRL_MDY_UNIQUE_ID = "689aaa04074a71b9363719a9"
CTRL_INTENT_LEVEL = "type28"   # 客户意向 opts 字段
CTRL_OWNER = "type26"          # 负责人
CTRL_DEPT = "type27"           # 部门

# 线索来源合并规则（48 → 8 枚举）
SOURCE_MAPPING = {
    "客户推荐": "referral",
    "推荐": "referral",
    "展会": "exhibition",
    "外展": "outreach",
    "外展邮件": "outreach",
    "经销商": "dealer",
    "经销": "dealer",
    "官网": "inbound",
    "表单": "inbound",
    "网站": "inbound",
    "互联网": "internet",
    "linkedin": "linkedin",
    "LinkedIn": "linkedin",
    "其他": "other",
}

# 系统迁移虚拟账号 id（ownerid=user-undefined 归入）
SYSTEM_MIGRATION_USER_ID = -1

# ──────────────────────────────────────────────
# 评分引擎（历史线索初始打分公式）
# ──────────────────────────────────────────────

def calc_score(intent_level: Optional[str], estimated_amount: Optional[float],
               no_followup_days: Optional[int], source: Optional[str]) -> tuple[int, dict]:
    """
    评分维度（满分 100）:
      score_demand_match   = 意向 → 高(40) / 中(25) / 低(10)
      score_budget         = 金额 → >=100万(25) / 50-100万(15) / <50万(5)
      score_timeliness     = 未跟进天数 → <=7天(20) / 8-30天(10) / >30天(0) / >90天(-10)
      score_source_quality = 来源 → referral(15) / exhibition(12) / internet(5) / other(3)
    """
    # 意向评分
    intent_map = {"高": 40, "中": 25, "低": 10}
    score_demand = intent_map.get(intent_level or "", 10)

    # 预算评分
    amt = estimated_amount or 0
    if amt >= 1_000_000:
        score_budget = 25
    elif amt >= 500_000:
        score_budget = 15
    else:
        score_budget = 5

    # 时效评分
    days = no_followup_days or 0
    if days <= 7:
        score_timeliness = 20
    elif days <= 30:
        score_timeliness = 10
    elif days <= 90:
        score_timeliness = 0
    else:
        score_timeliness = -10

    # 来源质量评分
    src_quality_map = {
        "referral": 15, "exhibition": 12, "linkedin": 10,
        "outreach": 8, "internet": 5, "inbound": 5,
        "dealer": 5, "other": 3,
    }
    score_source = src_quality_map.get(source or "other", 3)

    total = score_demand + score_budget + score_timeliness + score_source
    total = max(0, min(100, total))  # 0-100 clamp

    detail = {
        "demand_match": score_demand,
        "budget": score_budget,
        "timeliness": score_timeliness,
        "source_quality": score_source,
    }
    return total, detail


# ──────────────────────────────────────────────
# 字段提取帮助函数
# ──────────────────────────────────────────────

def get_opts_value(opts_list: list, ctrl_id: Optional[str] = None) -> Optional[str]:
    """从明道云 opts 字段提取 v（枚举值）"""
    if not opts_list:
        return None
    for item in opts_list:
        if isinstance(item, dict):
            if ctrl_id and item.get("controlId") != ctrl_id:
                continue
            if not item.get("isdel", False):
                return item.get("v")
    return None


def normalize_source(raw: Optional[str]) -> str:
    """将明道云原始来源字段合并为 8 枚举值"""
    if not raw:
        return "other"
    for k, v in SOURCE_MAPPING.items():
        if k.lower() in raw.lower():
            return v
    return "other"


def safe_decimal(val) -> Optional[float]:
    """安全转换为浮点金额"""
    try:
        return float(str(val).replace(",", "").strip()) if val else None
    except (ValueError, TypeError):
        return None


def safe_int(val) -> Optional[int]:
    try:
        return int(val) if val is not None else None
    except (ValueError, TypeError):
        return None


def safe_str(val, max_len: int = 200) -> Optional[str]:
    if val is None:
        return None
    s = str(val).strip()
    return s[:max_len] if s else None


# ──────────────────────────────────────────────
# 用户 ID 映射（明道云 account → sys_user.user_id）
# ──────────────────────────────────────────────

_USER_MAP_CACHE: Optional[dict] = None

def load_user_map(mysql_conn) -> dict:
    """从 sys_user 表加载 mdy_account_id → user_id 映射（已在 Phase 1 完成）"""
    global _USER_MAP_CACHE
    if _USER_MAP_CACHE is not None:
        return _USER_MAP_CACHE
    _USER_MAP_CACHE = {}
    try:
        with mysql_conn.cursor() as cur:
            cur.execute("SELECT user_id, remark FROM sys_user WHERE remark LIKE 'mdy:%'")
            for row in cur.fetchall():
                remark = row["remark"] or ""
                if remark.startswith("mdy:"):
                    mdy_id = remark[4:].strip()
                    _USER_MAP_CACHE[mdy_id] = row["user_id"]
    except Exception as e:
        print(f"  [WARN] 加载用户映射失败: {e}（ownerid=undefined 将归入系统账号）")
    return _USER_MAP_CACHE


def resolve_owner(owner_field, user_map: dict) -> int:
    """将明道云 ownerid 解析为 sys_user.user_id"""
    if not owner_field:
        return SYSTEM_MIGRATION_USER_ID
    account_id = None
    if isinstance(owner_field, dict):
        account_id = owner_field.get("accountId") or owner_field.get("id")
    elif isinstance(owner_field, str):
        account_id = owner_field
    if account_id and account_id != "user-undefined":
        return user_map.get(account_id, SYSTEM_MIGRATION_USER_ID)
    return SYSTEM_MIGRATION_USER_ID


# ──────────────────────────────────────────────
# 单条记录转换
# ──────────────────────────────────────────────

def transform_row(doc: dict, user_map: dict) -> dict:
    """将明道云 MongoDB 文档转换为 crm_leads 行"""

    # ---- 基础字段 ----
    lead_name = safe_str(doc.get("lead_name") or doc.get("线索名称") or doc.get("name"), 200)
    lead_code = safe_str(doc.get("lead_code") or doc.get("线索编号"), 50)
    contact_name = safe_str(doc.get("contact_name") or doc.get("联系人姓名") or doc.get("contactName"), 100)
    contact_phone = safe_str(doc.get("contact_phone") or doc.get("联系人电话"), 50)
    contact_status = safe_str(doc.get("contact_status") or doc.get("联系人状态"), 30)
    customer_name = safe_str(doc.get("customer_name") or doc.get("客户名称"), 200)
    industry = safe_str(doc.get("industry") or doc.get("项目所属行业") or doc.get("所属行业"), 100)
    region = safe_str(doc.get("region") or doc.get("地区"), 200)
    project_address = safe_str(doc.get("project_address") or doc.get("项目地址"), 500)
    process_status = safe_str(doc.get("process_status") or doc.get("流程状态"), 30)
    lead_type = safe_str(doc.get("lead_type") or doc.get("线索类型"), 50)
    lead_category = safe_str(doc.get("lead_category") or doc.get("线索分类"), 50)

    # ---- 来源 ----
    raw_source = doc.get("source") or doc.get("线索来源") or doc.get("lead_source")
    source = normalize_source(raw_source)

    # ---- 明道云唯一ID ----
    mdy_unique_id = safe_str(doc.get(CTRL_MDY_UNIQUE_ID) or doc.get("mdy_unique_id"), 50)
    mdy_row_id = safe_str(doc.get("_id") or doc.get("rowid"), 50)

    # ---- 意向（opts 解码） ----
    intent_opts = doc.get(CTRL_INTENT_LEVEL) or doc.get("intent_level")
    if isinstance(intent_opts, list):
        intent_level = get_opts_value(intent_opts)
    else:
        intent_level = safe_str(intent_opts, 20)

    # ---- 金额 ----
    estimated_amount = safe_decimal(doc.get("estimated_amount") or doc.get("项目预估成单金额"))

    # ---- 跟进 ----
    no_followup_days = safe_int(doc.get("no_followup_days") or doc.get("未跟进天数"))
    last_followup_raw = doc.get("last_followup_time") or doc.get("最近一次跟进日期")
    last_followup_time = None
    if last_followup_raw:
        try:
            if isinstance(last_followup_raw, datetime):
                last_followup_time = last_followup_raw.replace(tzinfo=None)
            else:
                last_followup_time = datetime.fromisoformat(str(last_followup_raw)[:19])
        except Exception:
            pass

    # ---- 附件 ----
    attachment = doc.get("attachment") or doc.get("附件")
    attachment_json = json.dumps(attachment, ensure_ascii=False) if attachment else None

    # ---- 负责人 ----
    owner_field = doc.get(CTRL_OWNER) or doc.get("ownerid") or doc.get("owner")
    owner_user_id = resolve_owner(owner_field, user_map)

    # ---- 评分 ----
    score, score_detail = calc_score(intent_level, estimated_amount, no_followup_days, source)

    # ---- 创建时间 ----
    created_raw = doc.get("create_time") or doc.get("创建日期") or doc.get("createdTime")
    create_time = None
    if created_raw:
        try:
            if isinstance(created_raw, datetime):
                create_time = created_raw.replace(tzinfo=None)
            else:
                create_time = datetime.fromisoformat(str(created_raw)[:19])
        except Exception:
            create_time = datetime.now()
    if create_time is None:
        create_time = datetime.now()

    return {
        # 应用字段（#3631 基础表）
        "name": lead_name or contact_name or "未知",
        "company": customer_name,
        "source_channel": source.upper() if source in ("outreach", "linkedin") else "WEBSITE",
        "status": "NEW",
        "total_score": score,
        "icp_match_score": 0,
        "del_flag": "0",
        "tenant_id": "000000",
        "create_time": create_time,
        # 迁移字段（#4014 新增）
        "lead_name": lead_name,
        "lead_code": lead_code,
        "contact_name": contact_name,
        "contact_phone": contact_phone,
        "contact_status": contact_status,
        "customer_name": customer_name,
        "intent_level": intent_level,
        "lead_type": lead_type,
        "lead_category": lead_category,
        "source": source,
        "industry": industry,
        "region": region,
        "project_address": project_address,
        "estimated_amount": estimated_amount,
        "owner_user_id": owner_user_id if owner_user_id != SYSTEM_MIGRATION_USER_ID else None,
        "owner_dept_id": None,  # dept 映射需二次回填
        "process_status": process_status,
        "score": score,
        "score_detail": json.dumps(score_detail, ensure_ascii=False),
        "no_followup_days": no_followup_days,
        "last_followup_time": last_followup_time,
        "attachment": attachment_json,
        "mdy_unique_id": mdy_unique_id,
        "mdy_row_id": mdy_row_id,
    }


# ──────────────────────────────────────────────
# 迁移主逻辑
# ──────────────────────────────────────────────

INSERT_SQL = """
INSERT INTO crm_leads (
  name, company, source_channel, status, total_score, icp_match_score,
  del_flag, tenant_id, create_time,
  lead_name, lead_code, contact_name, contact_phone, contact_status,
  customer_name, intent_level, lead_type, lead_category,
  source, industry, region, project_address, estimated_amount,
  owner_user_id, owner_dept_id, process_status,
  score, score_detail, no_followup_days, last_followup_time,
  attachment, mdy_unique_id, mdy_row_id
) VALUES (
  %(name)s, %(company)s, %(source_channel)s, %(status)s, %(total_score)s, %(icp_match_score)s,
  %(del_flag)s, %(tenant_id)s, %(create_time)s,
  %(lead_name)s, %(lead_code)s, %(contact_name)s, %(contact_phone)s, %(contact_status)s,
  %(customer_name)s, %(intent_level)s, %(lead_type)s, %(lead_category)s,
  %(source)s, %(industry)s, %(region)s, %(project_address)s, %(estimated_amount)s,
  %(owner_user_id)s, %(owner_dept_id)s, %(process_status)s,
  %(score)s, %(score_detail)s, %(no_followup_days)s, %(last_followup_time)s,
  %(attachment)s, %(mdy_unique_id)s, %(mdy_row_id)s
) ON DUPLICATE KEY UPDATE
  score = VALUES(score),
  score_detail = VALUES(score_detail),
  update_time = NOW()
"""

VALID_SOURCE_VALUES = {"internet", "referral", "exhibition", "outreach", "dealer", "inbound", "linkedin", "other"}


def migrate(dry_run: bool = True, batch_size: int = 200) -> int:
    import pymongo
    import pymysql

    print(f"{'[DRY-RUN] ' if dry_run else ''}开始迁移明道云线索池 → crm_leads")
    print(f"  MongoDB: {MONGO_URI}")
    print(f"  MySQL: {TARGET_MYSQL['host']}:{TARGET_MYSQL['port']}/{TARGET_MYSQL['db']}")
    print()

    # 连接 MongoDB
    mongo_client = pymongo.MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    try:
        mongo_client.server_info()
    except Exception as e:
        print(f"[ERROR] 无法连接 MongoDB: {e}")
        sys.exit(1)

    # 数据库名含连字符，需用 get_database
    db_name = MDY_DB_NAME
    coll_name = MDY_COLLECTION
    # 集合名含点号，需用 get_collection
    mongo_db = mongo_client.get_database(db_name)
    collection = mongo_db.get_collection(coll_name)

    total_docs = collection.count_documents({})
    print(f"  MongoDB 文档总数: {total_docs}")

    # 连接 MySQL
    mysql_conn = pymysql.connect(**TARGET_MYSQL, cursorclass=pymysql.cursors.DictCursor)
    user_map = load_user_map(mysql_conn)
    print(f"  已加载用户映射 {len(user_map)} 条")

    inserted = 0
    skipped = 0
    errors = 0
    batch = []

    cursor = collection.find({})
    for i, doc in enumerate(cursor):
        try:
            row = transform_row(doc, user_map)
            batch.append(row)
        except Exception as e:
            print(f"  [WARN] 第 {i+1} 条转换失败: {e}")
            errors += 1
            continue

        if len(batch) >= batch_size:
            if not dry_run:
                with mysql_conn.cursor() as cur:
                    cur.executemany(INSERT_SQL, batch)
                mysql_conn.commit()
            inserted += len(batch)
            batch = []
            print(f"  已处理 {inserted}/{total_docs}...", end="\r")

    # 最后一批
    if batch:
        if not dry_run:
            with mysql_conn.cursor() as cur:
                cur.executemany(INSERT_SQL, batch)
            mysql_conn.commit()
        inserted += len(batch)

    mysql_conn.close()
    mongo_client.close()

    print(f"\n{'[DRY-RUN] ' if dry_run else ''}迁移完成:")
    print(f"  处理: {inserted}, 跳过: {skipped}, 错误: {errors}")
    return inserted


def validate():
    """执行迁移后验收断言"""
    import pymysql

    print("执行验收断言...")
    conn = pymysql.connect(**TARGET_MYSQL, cursorclass=pymysql.cursors.DictCursor)
    ok = True

    with conn.cursor() as cur:
        # V1: 总行数
        cur.execute("SELECT COUNT(*) as cnt FROM crm_leads WHERE del_flag='0'")
        cnt = cur.fetchone()["cnt"]
        v1_pass = cnt >= 8800
        print(f"  V1 总行数: {cnt} {'✅' if v1_pass else '❌ (期望 >= 8800)'}")
        ok &= v1_pass

        # V2: mdy_unique_id 唯一
        cur.execute("SELECT COUNT(*) as cnt FROM (SELECT mdy_unique_id FROM crm_leads WHERE mdy_unique_id IS NOT NULL GROUP BY mdy_unique_id HAVING COUNT(*) > 1) t")
        dup = cur.fetchone()["cnt"]
        v2_pass = dup == 0
        print(f"  V2 mdy_unique_id 无重复: {'✅' if v2_pass else f'❌ {dup} 条重复'}")
        ok &= v2_pass

        # V3: source 枚举合规
        cur.execute("SELECT DISTINCT source FROM crm_leads WHERE source IS NOT NULL")
        sources = {row["source"] for row in cur.fetchall()}
        invalid = sources - VALID_SOURCE_VALUES
        v3_pass = len(invalid) == 0
        print(f"  V3 source 枚举: {sources} {'✅' if v3_pass else f'❌ 非法值={invalid}'}")
        ok &= v3_pass

        # V4: 评分覆盖率
        cur.execute("SELECT COUNT(*) as cnt FROM crm_leads WHERE del_flag='0' AND score > 0")
        scored = cur.fetchone()["cnt"]
        rate = scored / max(cnt, 1) * 100
        v4_pass = rate >= 80
        print(f"  V4 非零评分覆盖率: {rate:.1f}% {'✅' if v4_pass else '❌ (期望 >= 80%)'}")
        ok &= v4_pass

        # V5: owner_user_id 归属
        cur.execute("SELECT COUNT(*) as cnt FROM crm_leads WHERE del_flag='0' AND owner_user_id IS NULL")
        null_owner = cur.fetchone()["cnt"]
        v5_pass = null_owner <= 50
        print(f"  V5 未归属 owner: {null_owner} {'✅' if v5_pass else '❌ (期望 <= 50)'}")
        ok &= v5_pass

    conn.close()
    print(f"\n验收结果: {'全部通过 ✅' if ok else '存在失败 ❌'}")
    return 0 if ok else 1


# ──────────────────────────────────────────────
# CLI 入口
# ──────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="明道云线索池 → crm_leads 迁移脚本 (Issue #4014)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true", help="预览模式，不写入数据库")
    group.add_argument("--execute", action="store_true", help="正式执行迁移（需提前 mysqldump 快照）")
    group.add_argument("--validate", action="store_true", help="执行验收断言（迁移后运行）")
    parser.add_argument("--batch-size", type=int, default=200, help="批次大小（默认 200）")
    args = parser.parse_args()

    if args.validate:
        sys.exit(validate())
    else:
        n = migrate(dry_run=args.dry_run, batch_size=args.batch_size)
        if not args.dry_run and n < 8800:
            print(f"[ERROR] 迁移行数 {n} < 8800，请检查数据或回滚！")
            sys.exit(1)
        sys.exit(0)
