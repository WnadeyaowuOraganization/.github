#!/usr/bin/env python3
"""明道云商机 → wdpp_project_mine 迁移脚本"""

import pymongo
import pymysql
import json
from datetime import datetime

MONGO_URI = "mongodb://127.0.0.1:27017"
MDY_MYSQL = dict(host="127.0.0.1", port=3307, user="root", password="", charset="utf8mb4")
TARGET_MYSQL = dict(host="127.0.0.1", port=3306, user="root", password="root", db="wande-ai", charset="utf8mb4")

mongo = pymongo.MongoClient(MONGO_URI)

with open("/data/mdy-migration/id_mapping.json") as f:
    id_maps = json.load(f)
user_map = id_maps["user_map"]


def load_user_names():
    conn = pymysql.connect(**MDY_MYSQL, cursorclass=pymysql.cursors.DictCursor)
    with conn.cursor() as cur:
        cur.execute("SELECT AccountId, Fullname FROM MDProject.AccountInfo")
        rows = cur.fetchall()
    conn.close()
    return {r["AccountId"]: r["Fullname"] for r in rows}


user_names = load_user_names()


def get_target():
    return pymysql.connect(**TARGET_MYSQL, cursorclass=pymysql.cursors.DictCursor)


def build_fmap(wsid):
    ctrls = list(mongo["mdworksheet"].wscontrols.find({"wsid": wsid}))
    return {c["cid"]: {"name": c.get("name", "") or c.get("cname", ""), "type": c.get("type", 0)} for c in ctrls}


def build_opts_map(wsid):
    """构建选项字段的 UUID → 显示值 映射（支持字段名模糊匹配）"""
    ctrls = list(mongo["mdworksheet"].wscontrols.find({"wsid": wsid, "type": 11}))
    result = {}
    for c in ctrls:
        name = c.get("name", "") or c.get("cname", "")
        opts = c.get("opts", [])
        omap = {}
        for o in opts:
            omap[o["k"]] = o["v"]
        result[name] = omap
    return result


def get_rows(wsid):
    cn = f"ws{wsid}"
    db = mongo["mdwsrows"]
    return list(db[cn].find()) if cn in db.list_collection_names() else []


def translate_row(row, fmap):
    result = {}
    for k, v in row.items():
        if k in fmap:
            result[fmap[k]["name"]] = v
    return result


def resolve_opt_multi(translated, field_names, opts_map):
    """解析选项字段，支持多个候选字段名"""
    for fname in field_names:
        val = translated.get(fname)
        if not val:
            continue
        omap = opts_map.get(fname, {})
        if isinstance(val, list):
            resolved = [omap.get(v, v) for v in val if isinstance(v, str)]
            return resolved[0] if resolved else None
        if isinstance(val, str):
            return omap.get(val, val)
        return str(val)
    return None


def to_float(v):
    if v is None:
        return None
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


def ts(v):
    if isinstance(v, datetime):
        return v.strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(v, str) and v:
        return v[:19].replace("T", " ")
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def get_first(translated, *names):
    """从翻译后的行中取第一个匹配的非空字段值"""
    for n in names:
        v = translated.get(n)
        if v is not None and v != "" and v != []:
            if isinstance(v, (dict, list)):
                return json.dumps(v, ensure_ascii=False)[:500]
            return str(v)[:500]
    return None


def is_uuid(s):
    """检查是否像 UUID（用于检测未解析的选项值）"""
    if not isinstance(s, str):
        return False
    return len(s) == 36 and s.count("-") == 4


# 完整阶段 → mine_status 映射
STAGE_TO_MINE_STATUS = {
    "新建商机": "unassigned",
    "线索": "unassigned",
    "商机报备": "unassigned",
    "0%新建商机": "unassigned",
    "10%商机报备": "unassigned",
    "商务谈判": "contacted",
    "30%商务谈判": "contacted",
    "20%推进计划": "tracking",
    "30%商机报价": "tracking",
    "30%商机设计": "tracking",
    "招投标": "bid_preparing",
    "招投标 ": "bid_preparing",
    "60%商机招投标": "bid_preparing",
    "60%商机招投标 ": "bid_preparing",
    "70%赢单": "won",
    "95%销售订单": "won",
    "签订合同": "won",
    "合同签订": "won",
    "回款阶段": "won",
    "验收阶段": "won",
    "赢单": "won",
    "结束": "won",
    "项目完成结束": "won",
    "商机结束": "won",
    "输单": "lost",
    "无效": "invalid",
    # 进行中状态
    "进行中": "tracking",
    "正常": "tracking",
}

# 流程状态 → mine_status 覆盖
FLOW_STATUS_OVERRIDE = {
    "赢单": "won",
    "无效结束": "invalid",
    "输单结束": "lost",
    "完成结束": "won",
    "正常": "tracking",
    "新建商机": "unassigned",
    "待审核": "verified",
    "待审批": "verified",
    "待报备": "unassigned",
    "报备审批中": "verified",
    "无效/作废审批中": "invalid",
}

# 阶段 → 显示文字
STAGE_TO_DISPLAY = {
    "新建商机": "线索发现",
    "线索": "线索发现",
    "商机报备": "商机报备",
    "0%新建商机": "线索发现",
    "10%商机报备": "商机报备",
    "商务谈判": "商务谈判",
    "30%商务谈判": "商务谈判",
    "20%推进计划": "推进计划",
    "30%商机报价": "商机报价",
    "30%商机设计": "方案设计",
    "招投标": "招标中",
    "招投标 ": "招标中",
    "60%商机招投标": "招标中",
    "60%商机招投标 ": "招标中",
    "70%赢单": "赢单",
    "95%销售订单": "销售订单",
    "签订合同": "已签约",
    "合同签订": "已签约",
    "回款阶段": "回款中",
    "验收阶段": "验收中",
    "赢单": "赢单",
    "结束": "已结束",
    "项目完成结束": "已结束",
    "商机结束": "已结束",
    "输单": "输单",
    "无效": "无效",
    "进行中": "跟进中",
    "正常": "跟进中",
}


def migrate():
    print("=" * 60)
    print("明道云商机 → wdpp_project_mine 迁移")
    print("=" * 60)

    tgt = get_target()
    wsdb = mongo["mdworksheet"]

    opp_sheets = list(wsdb.worksheet.find({"alias": "xsfx"}))
    all_sheets = opp_sheets + list(wsdb.worksheet.find({"name": {"$regex": "商机"}, "alias": {"$ne": "xsfx"}}))
    seen_ws = set()
    sheets = []
    for ws in all_sheets:
        wid = str(ws["_id"])
        if wid not in seen_ws:
            seen_ws.add(wid)
            sheets.append(ws)

    print(f"找到 {len(sheets)} 个商机工作表")

    seen = set()
    project_count = 0
    assign_count = 0
    unresolved_stages = {}

    for ws in sheets:
        wsid = str(ws["_id"])
        fmap = build_fmap(wsid)
        opts_map = build_opts_map(wsid)
        rows = get_rows(wsid)
        if not rows:
            continue
        print(f"\n  {ws.get('name', '?')} ({wsid}): {len(rows)} 行")

        for row in rows:
            translated = translate_row(row, fmap)
            uid_field = translated.get("唯一性ID（必填）") or row.get("rowid", str(row.get("_id", "")))
            if uid_field in seen:
                continue
            seen.add(uid_field)

            # 项目名称
            project_name = get_first(
                translated,
                "商机名称（代号）", "商机名称", "项目需求",
                "客户姓名", "客户名称", "客户"
            ) or f"历史商机_{project_count}"
            project_name = str(project_name)[:500]

            # 项目编号
            project_code = get_first(translated, "商机代码（分享销客）", "商机代码", "商机代码(原)", "商机编号", "项目编号") or ""
            if isinstance(project_code, (int, float)):
                project_code = str(int(project_code))
            project_code = str(project_code)[:100]

            # 阶段（多个候选字段名）
            stage_text = resolve_opt_multi(
                translated,
                ["商机阶段", "商机阶段（必填）", "阶段状态"],
                opts_map
            ) or "新建商机"
            stage_text = stage_text.strip()

            # 流程状态
            flow_status = resolve_opt_multi(
                translated,
                ["流程状态", "生命状态"],
                opts_map
            )

            # 业务类型
            biz_type = resolve_opt_multi(
                translated,
                ["业务类型", "业务类型（必填）", "销售流程（必填）"],
                opts_map
            )

            # 信息来源
            source = resolve_opt_multi(
                translated,
                ["信息来源"],
                opts_map
            )
            # 有些表直接存文字
            if source and is_uuid(source):
                source = None

            # 行业
            industry = resolve_opt_multi(
                translated,
                ["项目所属行业"],
                opts_map
            )
            if industry and is_uuid(industry):
                industry = None

            # mine_status
            mine_status = "unassigned"
            if flow_status and flow_status in FLOW_STATUS_OVERRIDE:
                mine_status = FLOW_STATUS_OVERRIDE[flow_status]
            elif stage_text in STAGE_TO_MINE_STATUS:
                mine_status = STAGE_TO_MINE_STATUS[stage_text]

            # stage 显示文字
            if is_uuid(stage_text):
                unresolved_stages[stage_text] = unresolved_stages.get(stage_text, 0) + 1
                stage = "未知阶段"
            else:
                stage = STAGE_TO_DISPLAY.get(stage_text, stage_text)

            stage_detail = f"明道云阶段: {stage_text}"
            if flow_status:
                stage_detail += f", 流程: {flow_status}"
            if biz_type:
                stage_detail += f", 类型: {biz_type}"

            # 数值字段
            budget = to_float(get_first(translated, "项目整体预算（元）", "招标预算金额（元）", "项目总预算"))
            amount = to_float(get_first(translated, "我司预估成单金额（元）", "预测金额", "赢单金额（元）"))
            area = to_float(get_first(translated, "项目总面积（㎡）", "项目总面积"))
            trust_level = translated.get("意向等级")
            if isinstance(trust_level, (int, float)):
                trust_level = max(1, min(5, int(trust_level)))
            else:
                trust_level = None

            # 负责人
            owner_account_id = None
            for fname in ["负责人", "负责人（必填）"]:
                owner_ids = translated.get(fname)
                if isinstance(owner_ids, list) and owner_ids:
                    owner_account_id = owner_ids[0]
                    break
                elif isinstance(owner_ids, str) and owner_ids:
                    # 可能是用户名（商机信息数据表直接存名字）
                    if not is_uuid(owner_ids):
                        # 按名字反查
                        for aid, nm in user_names.items():
                            if nm == owner_ids:
                                owner_account_id = aid
                                break
                    else:
                        owner_account_id = owner_ids
                    break
            if not owner_account_id:
                owner_account_id = row.get("ownerid")

            owner_user_id = user_map.get(owner_account_id)
            owner_name = user_names.get(owner_account_id, "")

            # 客户名
            client_name = get_first(translated, "客户姓名", "客户名称", "客户", "业主方名称") or ""
            client_name = str(client_name)[:200]

            # 地址
            province = get_first(translated, "省") or ""
            city = get_first(translated, "市") or ""
            region = get_first(translated, "地区", "详细地址", "项目地址信息") or ""

            # 时间
            ct = ts(row.get("ctime"))
            ut = ts(row.get("utime") or row.get("ctime"))
            pub_raw = get_first(translated, "发布日期")
            publish_time = ts(pub_raw) if pub_raw else ct

            rid = row.get("rowid", str(row.get("_id", "")))

            # 投资信息
            investment_parts = []
            if area:
                investment_parts.append(f"总面积{area}㎡")
            product_area = to_float(get_first(translated, "我司产品涉及面积（㎡）"))
            if product_area:
                investment_parts.append(f"产品面积{product_area}㎡")
            investment_text = ", ".join(investment_parts) if investment_parts else None

            # 建设内容
            building_content = get_first(translated, "项目建设内容", "客户需求", "项目需求")

            try:
                with tgt.cursor() as cur:
                    cur.execute("""INSERT INTO wdpp_project_mine
                        (project_name, project_code, project_type, client_name,
                         region, province, city,
                         stage, stage_detail, mine_status, mine_category,
                         project_scale, budget_amount, investment_text, building_content,
                         trust_level, source_name, source_category, discovery_source,
                         publish_time, source_url,
                         create_by, create_time, update_time, del_flag, tenant_id,
                         verification_status, evaluation_status, filter_result)
                        VALUES (%s,%s,%s,%s, %s,%s,%s, %s,%s,%s,%s, %s,%s,%s,%s, %s,%s,%s,%s, %s,%s, %s,%s,%s,'0','000000', 'verified',1,'clean')
                        """,
                        (project_name, project_code or None, biz_type, client_name,
                         region[:200] if region else None, province[:100] if province else None, city[:100] if city else None,
                         stage[:100] if stage else None, stage_detail[:500] if stage_detail else None,
                         mine_status, industry[:50] if industry else None,
                         amount or 0, budget or 0, investment_text, building_content,
                         trust_level, source[:200] if source else None, "mingdao", "明道云历史数据",
                         publish_time, f"mdy:{rid}",
                         owner_user_id, ct, ut))

                    project_id = cur.lastrowid

                    if owner_user_id and project_id:
                        cur.execute("""INSERT INTO wdpp_project_mine_assign_log
                            (project_id, assigned_to, assigned_user_id, assigned_user_name,
                             assign_time, create_time, create_by, del_flag, tenant_id, remark)
                            VALUES (%s,%s,%s,%s, %s,%s,%s,'0','000000','明道云迁移')""",
                            (project_id, owner_name or f"user_{owner_user_id}",
                             owner_user_id, owner_name,
                             ct, ct, owner_user_id))
                        assign_count += 1

                project_count += 1
            except Exception as e:
                if project_count < 3:
                    print(f"  ⚠️ {e}")
                    import traceback; traceback.print_exc()

        tgt.commit()

    print(f"\n{'=' * 60}")
    print(f"完成: {project_count} 个商机 → wdpp_project_mine (去重后, 原始 {len(seen)})")
    print(f"      {assign_count} 条负责人分配记录 → wdpp_project_mine_assign_log")
    if unresolved_stages:
        print(f"\n  未解析的阶段 UUID ({len(unresolved_stages)} 种):")
        for k, v in sorted(unresolved_stages.items(), key=lambda x: -x[1])[:10]:
            print(f"    {k}: {v} 条")
    print(f"{'=' * 60}")

    tgt.close()


if __name__ == "__main__":
    print(f"明道云商机 → 项目矿场迁移 | {datetime.now():%Y-%m-%d %H:%M:%S}\n")
    migrate()
