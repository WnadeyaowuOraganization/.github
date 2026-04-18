#!/usr/bin/env python3
"""明道云 → 万德AI新平台 数据迁移脚本 (Phase 1 + Phase 2)"""

import pymongo
import pymysql
import json
from datetime import datetime

MONGO_URI = "mongodb://127.0.0.1:27017"
MDY_MYSQL = dict(host="127.0.0.1", port=3307, user="root", password="", charset="utf8mb4")
TARGET_MYSQL = dict(host="127.0.0.1", port=3306, user="root", password="root", db="wande-ai", charset="utf8mb4")

USER_ID_OFFSET = 10000
DEPT_ID_OFFSET = 10000

mongo = pymongo.MongoClient(MONGO_URI)


def get_mdy():
    return pymysql.connect(**MDY_MYSQL, cursorclass=pymysql.cursors.DictCursor)


def get_target():
    return pymysql.connect(**TARGET_MYSQL, cursorclass=pymysql.cursors.DictCursor)


# ============================================================
# Phase 1: 用户 + 部门
# ============================================================

def phase1():
    print("=" * 60)
    print("Phase 1: 用户和部门迁移")
    print("=" * 60)

    mdy = get_mdy()
    tgt = get_target()

    # --- 部门 ---
    print("\n[1.1] 迁移部门...")
    with mdy.cursor() as cur:
        cur.execute("SELECT DepartmentID, DepartmentName, ParentId, SortIndex FROM MDProject.Project_Department WHERE Deleted=0 ORDER BY SortIndex")
        depts = cur.fetchall()

    dept_map = {}
    all_ids = {d["DepartmentID"] for d in depts}
    for i, d in enumerate(depts):
        dept_map[d["DepartmentID"]] = DEPT_ID_OFFSET + i + 1

    root_id = DEPT_ID_OFFSET
    inserts = [{"dept_id": root_id, "parent_id": 0, "ancestors": "0", "dept_name": "万德体育集团", "order_num": 0}]
    for d in depts:
        nid = dept_map[d["DepartmentID"]]
        pid = dept_map.get(d["ParentId"], root_id) if d["ParentId"] else root_id
        anc = f"0,{root_id}" if pid == root_id else f"0,{root_id},{pid}"
        inserts.append({"dept_id": nid, "parent_id": pid, "ancestors": anc,
                        "dept_name": (d["DepartmentName"] or "未命名")[:30], "order_num": max(0, (d["SortIndex"] or 0) + 100001)})

    with tgt.cursor() as cur:
        for di in inserts:
            cur.execute("""INSERT INTO sys_dept (dept_id, tenant_id, parent_id, ancestors, dept_name, order_num, status, del_flag, create_time)
                VALUES (%(dept_id)s,'000000',%(parent_id)s,%(ancestors)s,%(dept_name)s,%(order_num)s,'0','0',NOW())
                ON DUPLICATE KEY UPDATE dept_name=VALUES(dept_name)""", di)
    tgt.commit()
    print(f"  {len(inserts)} 个部门")

    # --- 用户 ---
    print("\n[1.2] 迁移用户...")
    with mdy.cursor() as cur:
        cur.execute("""SELECT a.AutoId, a.AccountId, a.MobilePhone, a.Email, a.Status,
            i.Fullname, i.Gender FROM MDProject.Account a
            LEFT JOIN MDProject.AccountInfo i ON a.AccountId=i.AccountId
            WHERE a.Status IN (1,4) ORDER BY a.AutoId""")
        users = cur.fetchall()

    with mdy.cursor() as cur:
        cur.execute("SELECT AccountId, DepartmentId FROM MDProject.Project_DepartmentAccount")
        ud_rows = cur.fetchall()
    ud_map = {r["AccountId"]: r["DepartmentId"] for r in ud_rows}

    user_map = {}
    with tgt.cursor() as cur:
        for u in users:
            uid = USER_ID_OFFSET + u["AutoId"]
            user_map[u["AccountId"]] = uid
            phone = (u["MobilePhone"] or "").replace("+86", "").strip()[:11]
            did = dept_map.get(ud_map.get(u["AccountId"]))
            st = "0" if u["Status"] == 1 else "1"
            cur.execute("""INSERT INTO sys_user (user_id, tenant_id, dept_id, user_name, nick_name, email, phonenumber, sex,
                password, status, del_flag, create_time, remark)
                VALUES (%s,'000000',%s,%s,%s,%s,%s,%s,'$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2',
                %s,'0',NOW(),%s) ON DUPLICATE KEY UPDATE nick_name=VALUES(nick_name), dept_id=VALUES(dept_id)""",
                (uid, did, f"mdy_{u['AutoId']}", (u["Fullname"] or f"用户{u['AutoId']}")[:30],
                 u["Email"] or "", phone, str(u["Gender"] or 0), st, f"mdy:{u['AccountId']}"))
    tgt.commit()
    print(f"  {len(user_map)} 个用户")

    with open("/data/mdy-migration/id_mapping.json", "w") as f:
        json.dump({"user_map": user_map, "dept_map": dept_map}, f, ensure_ascii=False, indent=2)
    print("  映射表保存完毕")

    mdy.close()
    tgt.close()
    return user_map, dept_map


# ============================================================
# Phase 2: CRM
# ============================================================

def build_fmap(wsid):
    ctrls = list(mongo["mdworksheet"].wscontrols.find({"wsid": wsid}))
    return {c["cid"]: {"name": c.get("name", "") or c.get("cname", ""), "type": c.get("type", 0)} for c in ctrls}


def get_rows(wsid):
    cn = f"ws{wsid}"
    db = mongo["mdwsrows"]
    return list(db[cn].find()) if cn in db.list_collection_names() else []


def val(row, fmap, *names):
    """从翻译后的行中取第一个匹配的字段值"""
    translated = {}
    for k, v in row.items():
        if k in fmap:
            translated[fmap[k]["name"]] = v
    for n in names:
        if n in translated and translated[n] is not None and translated[n] != "":
            r = translated[n]
            if isinstance(r, (dict, list)):
                return json.dumps(r, ensure_ascii=False)[:500]
            return str(r)[:500]
    return None


def ts(v):
    if isinstance(v, datetime):
        return v.strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(v, str) and v:
        return v[:19]
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def to_float(v):
    if v is None:
        return None
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


STAGE_MAP = {
    "新建商机": "NEW", "商务谈判": "NEGOTIATION", "招投标": "BIDDING", "招投标 ": "BIDDING",
    "签订合同": "CONTRACT", "合同签订": "CONTRACT", "回款阶段": "PAYMENT", "验收阶段": "ACCEPTANCE",
    "结束": "CLOSED", "项目完成结束": "CLOSED", "商机结束": "CLOSED",
    "0%新建商机": "NEW", "10%商机报备": "REPORT", "20%推进计划": "PLAN",
    "30%商机报价": "QUOTE", "30%商机设计": "DESIGN", "30%商务谈判": "NEGOTIATION",
    "60%商机招投标": "BIDDING", "60%商机招投标 ": "BIDDING", "70%赢单": "WON",
}


def phase2(user_map, dept_map):
    print("\n" + "=" * 60)
    print("Phase 2: CRM 数据迁移")
    print("=" * 60)

    tgt = get_target()
    wsdb = mongo["mdworksheet"]

    # --- 2.1 客户 ---
    print("\n[2.1] 客户...")
    cust_sheets = list(wsdb.worksheet.find({"name": {"$regex": "客户"}}))
    print(f"  找到 {len(cust_sheets)} 个客户工作表")

    cust_map = {}
    cust_count = 0
    for ws in cust_sheets:
        wsid = ws["_id"]
        fmap = build_fmap(wsid)
        rows = get_rows(wsid)
        if not rows:
            continue
        print(f"  {ws.get('name','?')} ({wsid}): {len(rows)} 行")

        for row in rows:
            name = val(row, fmap, "客户名称", "客户", "公司名称", "名称") or f"客户_{cust_count}"
            owner = user_map.get(row.get("ownerid"))
            ct = ts(row.get("ctime"))
            phone = val(row, fmap, "联系电话", "电话", "手机")
            addr = val(row, fmap, "地址", "公司地址", "详细地址")
            ind = val(row, fmap, "行业", "所属行业")
            rid = row.get("rowid", str(row.get("_id", "")))

            try:
                with tgt.cursor() as cur:
                    cur.execute("""INSERT INTO crm_customer (customer_name, industry, contact_phone, address,
                        owner_user_id, create_by, created_time, updated_time, deleted, tenant_id, remark)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,0,'000000',%s)""",
                        (name[:200], ind, phone, addr, owner, owner, ct, ct, f"mdy:{rid}"))
                cust_map[rid] = cur.lastrowid
                cust_count += 1
            except Exception as e:
                if cust_count == 0:
                    print(f"  ⚠️ {e}")

    tgt.commit()
    print(f"  客户: {cust_count} 条")

    # --- 2.2 商机 ---
    print("\n[2.2] 商机...")
    opp_sheets = list(wsdb.worksheet.find({"alias": "xsfx"}))
    print(f"  找到 {len(opp_sheets)} 个商机工作表")

    # 需要一个默认 customer_id（商机表要求 NOT NULL）
    default_cust_id = None
    with tgt.cursor() as cur:
        cur.execute("SELECT id FROM crm_customer LIMIT 1")
        r = cur.fetchone()
        if r:
            default_cust_id = r["id"]

    if not default_cust_id:
        with tgt.cursor() as cur:
            cur.execute("INSERT INTO crm_customer (customer_name, owner_user_id, created_time, updated_time, deleted, tenant_id) VALUES ('默认客户(迁移占位)', 1, NOW(), NOW(), 0, '000000')")
            default_cust_id = cur.lastrowid
        tgt.commit()

    opp_map = {}
    opp_count = 0
    seen = set()
    for ws in opp_sheets:
        wsid = ws["_id"]
        fmap = build_fmap(wsid)
        rows = get_rows(wsid)
        if not rows:
            continue
        print(f"  {ws.get('name','?')} ({wsid}): {len(rows)} 行")

        for row in rows:
            uid = val(row, fmap, "唯一性ID（必填）") or row.get("rowid", str(row.get("_id", "")))
            if uid in seen:
                continue
            seen.add(uid)

            name = val(row, fmap, "商机名称（代号）", "商机名称") or f"商机_{opp_count}"
            owner = user_map.get(row.get("ownerid")) or 1
            ct = ts(row.get("ctime"))
            stage_raw = val(row, fmap, "商机阶段") or "新建商机"
            stage = STAGE_MAP.get(stage_raw.strip(), "NEW") if stage_raw else "NEW"
            source = val(row, fmap, "信息来源")
            amount = to_float(val(row, fmap, "我司预估成单金额（元）"))
            rid = row.get("rowid", str(row.get("_id", "")))

            # 尝试关联客户
            cust_rowid = val(row, fmap, "客户")
            cust_id = cust_map.get(cust_rowid, default_cust_id) if cust_rowid else default_cust_id

            try:
                with tgt.cursor() as cur:
                    cur.execute("""INSERT INTO crm_opportunity (opportunity_name, customer_id, owner_user_id, stage,
                        source, estimated_amount, create_by, create_time, update_time, deleted, tenant_id, remark)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,0,'000000',%s)""",
                        (name[:200], cust_id, owner, stage, source, amount or 0, owner, ct, ct, f"mdy:{rid}"))
                opp_map[rid] = cur.lastrowid
                opp_count += 1
            except Exception as e:
                if opp_count == 0:
                    print(f"  ⚠️ {e}")

    tgt.commit()
    print(f"  商机: {opp_count} 条 (去重后, 原始 {len(seen)})")

    # --- 2.3 跟进记录 ---
    print("\n[2.3] 跟进记录...")
    act_sheets = list(wsdb.worksheet.find({"name": {"$regex": "跟进"}}))
    print(f"  找到 {len(act_sheets)} 个跟进记录工作表")

    ACT_TYPE_MAP = {"电话": 1, "拜访": 2, "微信": 3, "邮件": 4, "其他": 5, "QQ": 3, "视频": 6}
    act_count = 0
    for ws in act_sheets:
        wsid = ws["_id"]
        fmap = build_fmap(wsid)
        rows = get_rows(wsid)
        if not rows:
            continue
        print(f"  {ws.get('name','?')} ({wsid}): {len(rows)} 行")

        for row in rows:
            content = val(row, fmap, "跟进内容", "内容", "描述", "备注") or "(空)"
            atype_raw = val(row, fmap, "跟进方式", "类型", "联系方式") or "其他"
            atype = ACT_TYPE_MAP.get(atype_raw, 5)
            operator = user_map.get(row.get("ownerid")) or user_map.get(row.get("caid")) or 1
            ct = ts(row.get("ctime"))
            rid = row.get("rowid", str(row.get("_id", "")))

            try:
                with tgt.cursor() as cur:
                    cur.execute("""INSERT INTO crm_activity_log (activity_type, activity_content, activity_time,
                        operator_user_id, create_by, created_time, updated_time, deleted, tenant_id, remark)
                        VALUES (%s,%s,%s,%s,%s,%s,%s,0,'000000',%s)""",
                        (atype, content[:4000], ct, operator, operator, ct, ct, f"mdy:{rid}"))
                act_count += 1
            except Exception as e:
                if act_count == 0:
                    print(f"  ⚠️ {e}")
                    break

    tgt.commit()
    print(f"  跟进记录: {act_count} 条")

    # 保存映射
    maps = {"user_map": user_map, "dept_map": dept_map, "customer_map": {str(k): v for k, v in cust_map.items()}, "opportunity_map": {str(k): v for k, v in opp_map.items()}}
    with open("/data/mdy-migration/id_mapping.json", "w") as f:
        json.dump(maps, f, ensure_ascii=False, indent=2)

    tgt.close()
    return cust_count, opp_count, act_count


if __name__ == "__main__":
    print(f"明道云 → 万德AI 数据迁移 | {datetime.now():%Y-%m-%d %H:%M:%S}\n")
    umap, dmap = phase1()
    c, o, a = phase2(umap, dmap)
    print(f"\n{'='*60}\n完成: 部门 {len(dmap)+1} | 用户 {len(umap)} | 客户 {c} | 商机 {o} | 跟进 {a}\n映射表: /data/mdy-migration/id_mapping.json")
