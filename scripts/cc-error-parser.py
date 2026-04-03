#!/usr/bin/env python3
"""cc-error-parser.py — G7e多源日志扫描与错误事件提取器

用法:
    python3 cc-error-parser.py                        # 扫描全部日志
    python3 cc-error-parser.py --since "2026-03-31T00:00:00"   # 增量模式
"""
import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


# ---------- 配置 ----------
CODING_CC_LOG_DIR = Path("/var/log/coding-cc")
PROXY_LOG_PATH = Path("/home/ubuntu/projects/.github/scripts/model-switch/proxy.log")
E2E_LOG_DIR = Path("/home/ubuntu/projects/wande-play/e2e/logs")
E2E_TRACE_PATH = Path("/home/ubuntu/projects/wande-play/e2e/traceability/requirement-map.json")
INFRA_LOG_PATH = Path("/var/log/wande-infra-monitor.log")


# ---------- 时间解析工具 ----------
def parse_iso_z(ts: str) -> datetime:
    """解析 ISO-8601 字符串（兼容 Z 后缀和无时区格式）为 UTC datetime。"""
    ts = ts.strip()
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(ts).astimezone(timezone.utc)
    except Exception:
        # 兜底：按无tz解析并视为 UTC
        return datetime.fromisoformat(ts.replace("+00:00", "")).replace(tzinfo=timezone.utc)


def ts_to_iso(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# coding-cc *.log 时间戳解析
def parse_log_timestamp(line: str, default_year: int = 2026) -> datetime | None:
    # [Wed Apr  1 06:29:10 UTC 2026] ...
    m = re.match(r"^\[([A-Z][a-z]{2}\s+[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+UTC\s+\d{4})\]", line)
    if m:
        try:
            return datetime.strptime(m.group(1), "%a %b %d %H:%M:%S UTC %Y").replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    # [06:29:10] ...  (只有时间，取文件mtime的日期)
    m2 = re.match(r"^\[(\d{2}:\d{2}:\d{2})\]", line)
    if m2:
        try:
            t = datetime.strptime(m2.group(1), "%H:%M:%S").time()
            return datetime(default_year, 1, 1, t.hour, t.minute, t.second, tzinfo=timezone.utc)
        except ValueError:
            pass
    return None


def parse_proxy_timestamp(line: str) -> datetime | None:
    # 2026-03-30 09:54:29,248 ...
    m = re.match(r"^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}),\d+", line)
    if m:
        try:
            return datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return None


def parse_infra_timestamp(line: str) -> datetime | None:
    # [2026-03-07 22:23:51] ...
    m = re.match(r"^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\]", line)
    if m:
        try:
            return datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return None


# ---------- 文件名解析 ----------
def extract_repo_issue_from_filename(filename: str) -> tuple[str, int | None]:
    """从 <repo>-<issue>.log 或 <repo>-<issue>-raw.jsonl 提取 repo 和 issue_number。"""
    base = os.path.splitext(filename)[0]
    if base.endswith("-raw"):
        base = base[:-4]
    # 尝试匹配尾部数字/issue号（hex或纯数字）
    # 常见模式: backend-133, backend-010989b6, front-335, pipeline-38
    m = re.match(r"^([a-zA-Z0-9_-]+)-([0-9a-fA-Z]+)$", base)
    if m:
        repo = m.group(1)
        issue_str = m.group(2)
        try:
            issue_num = int(issue_str)
        except ValueError:
            issue_num = None
        return repo, issue_num
    return base, None


# ---------- 事件构建 ----------
def make_event(
    repo: str,
    issue_number: int | None,
    phase: str,
    error_type: str,
    error_message: str,
    source_file: str,
    session_id: str | None = None,
    model: str | None = None,
    token_cost: float = 0.0,
    duration_ms: int = 0,
    create_time: str | None = None,
) -> dict:
    return {
        "repo": repo,
        "issue_number": issue_number,
        "phase": phase,
        "error_type": error_type,
        "error_message": error_message,
        "source_file": source_file,
        "session_id": session_id or "",
        "model": model or "",
        "token_cost": float(token_cost),
        "duration_ms": int(duration_ms),
        "create_time": create_time or ts_to_iso(datetime.now(timezone.utc)),
    }


# ---------- coding-cc *.log 解析 ----------
CC_ERROR_PATTERNS = [
    (re.compile(r"API Error:\s*(\d+)\s*(.*)"), "api_error"),
    (re.compile(r"Reached max turns\s*\((\d+)\)"), "max_turns"),
    (re.compile(r"compilation failure|编译失败|BUILD FAILURE"), "compilation_failure"),
    (re.compile(r"pr create fail|创建PR失败|Failed to create PR"), "pr_create_fail"),
    (re.compile(r"❌\s*ERROR:\s*(.*)"), "claude_error"),
    (re.compile(r"Error:\s*Reached max turns"), "max_turns"),
]


def parse_coding_cc_logs(since_dt: datetime | None, session_cache: dict[str, dict] | None = None) -> list[dict]:
    events = []
    if not CODING_CC_LOG_DIR.exists():
        return events

    for log_path in sorted(CODING_CC_LOG_DIR.glob("*.log")):
        repo, issue_num = extract_repo_issue_from_filename(log_path.name)
        # 用文件修改时间作为只有时间的行的默认年份/日期
        mtime = datetime.fromtimestamp(log_path.stat().st_mtime, tz=timezone.utc)

        # 从缓存中获取对应的 session_id 和 model
        base = log_path.name.replace(".log", "")
        cached_info = session_cache.get(base, {}) if session_cache else {}
        session_id = cached_info.get("session_id", "")
        model = cached_info.get("model", "")

        with open(log_path, "rb") as f:
            data = f.read().decode("utf-8", errors="replace")

        for line in data.split("\n"):
            line = line.rstrip("\r\n")
            if not line:
                continue

            ts = parse_log_timestamp(line, default_year=mtime.year)
            if ts and since_dt and ts < since_dt:
                continue
            # 没有时间戳的行，若 since 很新也跳过（保守策略）
            if ts is None and since_dt and mtime < since_dt:
                continue

            create_time = ts_to_iso(ts) if ts else ts_to_iso(mtime)

            for pat, err_type in CC_ERROR_PATTERNS:
                m = pat.search(line)
                if m:
                    msg = m.group(0)
                    if err_type == "api_error" and len(m.groups()) >= 2:
                        msg = f"API Error {m.group(1)}: {m.group(2).strip()}"
                    elif err_type == "max_turns" and len(m.groups()) >= 1:
                        msg = f"Reached max turns ({m.group(1)})"
                    elif err_type == "claude_error" and len(m.groups()) >= 1:
                        msg = f"Claude ERROR: {m.group(1).strip()}"

                    events.append(make_event(
                        repo=repo,
                        issue_number=issue_num,
                        phase="execution",
                        error_type=err_type,
                        error_message=msg,
                        source_file=str(log_path),
                        session_id=session_id,
                        model=model,
                        create_time=create_time,
                    ))
                    break  # 一行只算一种错误
    return events


# ---------- raw.jsonl 解析 ----------
def parse_raw_jsonl(since_dt: datetime | None) -> list[dict]:
    events = []
    if not CODING_CC_LOG_DIR.exists():
        return events

    session_cache = {}  # session_id -> {model, repo, issue}

    for jsonl_path in sorted(CODING_CC_LOG_DIR.glob("*-raw.jsonl")):
        repo, issue_num = extract_repo_issue_from_filename(jsonl_path.name)
        mtime = datetime.fromtimestamp(jsonl_path.stat().st_mtime, tz=timezone.utc)
        if since_dt and mtime < since_dt:
            # 文件整体太旧则跳过（raw.jsonl 内无独立时间戳）
            continue

        with open(jsonl_path, "rb") as f:
            data = f.read().decode("utf-8", errors="replace")

        for line in data.split("\n"):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            sess_id = obj.get("session_id") or obj.get("uuid", "")

            # 缓存 model 信息
            if obj.get("type") == "system" and obj.get("model"):
                session_cache[sess_id] = {
                    "model": obj.get("model", ""),
                    "repo": repo,
                    "issue": issue_num,
                }

            # 提取 result 错误
            if obj.get("type") == "result":
                is_error = obj.get("is_error") is True or obj.get("subtype") == "error"
                result_val = obj.get("result", "")
                if is_error or (isinstance(result_val, str) and result_val.startswith("API Error")):
                    cached = session_cache.get(sess_id, {})
                    events.append(make_event(
                        repo=cached.get("repo", repo),
                        issue_number=cached.get("issue", issue_num),
                        phase="execution",
                        error_type="api_error" if "API Error" in str(result_val) else "execution_error",
                        error_message=str(result_val)[:500],
                        source_file=str(jsonl_path),
                        session_id=sess_id,
                        model=cached.get("model", obj.get("model", "")),
                        token_cost=0.0,
                        duration_ms=obj.get("duration_ms", 0) or 0,
                        create_time=ts_to_iso(mtime),
                    ))

            # 提取 tool_result success=false（目前 tool_use_result 结构里没有 success 字段，
            # 存的是 stdout/stderr，我们检测 stderr 中是否有错误关键词）
            if obj.get("type") == "user" and obj.get("tool_use_result"):
                tr = obj.get("tool_use_result")
                if isinstance(tr, dict) and tr.get("stderr"):
                    stderr = tr.get("stderr", "")
                    if stderr.strip():
                        cached = session_cache.get(sess_id, {})
                        events.append(make_event(
                            repo=cached.get("repo", repo),
                            issue_number=cached.get("issue", issue_num),
                            phase="execution",
                            error_type="tool_error",
                            error_message=stderr.strip()[:500],
                            source_file=str(jsonl_path),
                            session_id=sess_id,
                            model=cached.get("model", ""),
                            create_time=ts_to_iso(mtime),
                        ))

            # 统计 token（从 result 记录提取，如果后面 API 支持 cost_usd）
            if obj.get("type") == "result" and isinstance(result_val, str) and not is_error:
                # 这里只记录错误事件，不输出成功结果
                pass

    return events


def parse_raw_jsonl_token_stats(since_dt: datetime | None) -> dict[tuple, dict]:
    """额外统计 raw.jsonl 的 token/duration（按 session_id 聚合），以 (repo,issue,session_id) 为键。"""
    stats = {}
    if not CODING_CC_LOG_DIR.exists():
        return stats
    for jsonl_path in sorted(CODING_CC_LOG_DIR.glob("*-raw.jsonl")):
        repo, issue_num = extract_repo_issue_from_filename(jsonl_path.name)
        mtime = datetime.fromtimestamp(jsonl_path.stat().st_mtime, tz=timezone.utc)
        if since_dt and mtime < since_dt:
            continue
        with open(jsonl_path, "rb") as f:
            data = f.read().decode("utf-8", errors="replace")
        for line in data.split("\n"):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") == "result":
                sess = obj.get("session_id") or obj.get("uuid", "")
                key = (repo, issue_num, sess)
                dur = obj.get("duration_ms", 0) or 0
                # cost_usd 在 cc-stream-parser 的 result 对象里；这里 result 是字符串没有该字段
                # 原 obj 本身可能有 cost_usd？如果有则记录
                cost = obj.get("cost_usd", 0.0) or 0.0
                stats[key] = {
                    "duration_ms": dur,
                    "token_cost": cost,
                }
    return stats


def build_session_cache(since_dt: datetime | None) -> dict[str, dict]:
    """构建文件名 -> session_id/model 映射，用于给 .log 事件补充信息。

    返回: {base_filename: {"session_id": ..., "model": ...}}
    例如 {"backend-133": {"session_id": "xxx", "model": "kimi-for-coding"}}
    """
    cache = {}
    if not CODING_CC_LOG_DIR.exists():
        return cache

    for jsonl_path in sorted(CODING_CC_LOG_DIR.glob("*-raw.jsonl")):
        mtime = datetime.fromtimestamp(jsonl_path.stat().st_mtime, tz=timezone.utc)
        if since_dt and mtime < since_dt:
            continue

        # 从文件名提取 base（去掉 -raw.jsonl 后缀）
        base = jsonl_path.name.replace("-raw.jsonl", "")
        repo, issue_num = extract_repo_issue_from_filename(jsonl_path.name)

        with open(jsonl_path, "rb") as f:
            data = f.read().decode("utf-8", errors="replace")

        session_id = None
        model = None

        for line in data.split("\n"):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            # 从 system/init 记录提取 session_id 和 model
            if obj.get("type") == "system" and obj.get("subtype") == "init":
                session_id = obj.get("session_id") or obj.get("uuid")
                model = obj.get("model")
                break  # 只需要第一条

        if session_id or model:
            cache[base] = {
                "session_id": session_id or "",
                "model": model or "",
                "repo": repo,
                "issue_number": issue_num,
            }

    return cache


# ---------- proxy.log 解析 ----------
PROXY_PATTERNS = [
    (re.compile(r"限额触发\(HTTP\s+429\)"), "quota_rate_limit", "HTTP 429 quota rate limit triggered"),
    (re.compile(r"HTTP\s+429.*code=1302"), "rate_limit_1302", "HTTP 429 code=1302 rate limit"),
    (re.compile(r"您的账户额度已用尽"), "quota_exhausted", "Quota exhausted"),
    (re.compile(r"您的账户已达到速率限制"), "rate_limit", "Rate limit reached"),
    (re.compile(r"HTTP\s+502"), "http_502", "HTTP 502 Bad Gateway"),
    (re.compile(r"❄️\s*冷却中"), "cooldown", "Token pool cooldown"),
]


def parse_proxy_log(since_dt: datetime | None) -> list[dict]:
    events = []
    if not PROXY_LOG_PATH.exists():
        return events

    mtime = datetime.fromtimestamp(PROXY_LOG_PATH.stat().st_mtime, tz=timezone.utc)
    with open(PROXY_LOG_PATH, "rb") as f:
        data = f.read().decode("utf-8", errors="replace")

    for line in data.split("\n"):
        line = line.rstrip("\r\n")
        if not line:
            continue
        ts = parse_proxy_timestamp(line)
        if ts and since_dt and ts < since_dt:
            continue
        if ts is None and since_dt and mtime < since_dt:
            continue

        create_time = ts_to_iso(ts) if ts else ts_to_iso(mtime)
        for pat, err_type, msg in PROXY_PATTERNS:
            if pat.search(line):
                events.append(make_event(
                    repo="model-switch-proxy",
                    issue_number=None,
                    phase="infrastructure",
                    error_type=err_type,
                    error_message=f"{msg}: {line[:300]}",
                    source_file=str(PROXY_LOG_PATH),
                    create_time=create_time,
                ))
                break
    return events


# ---------- infra monitor log 解析 ----------
INFRA_PATTERN = re.compile(r"^(ERROR|FAIL|CRITICAL):?\s*(.*)", re.I)


def parse_infra_log(since_dt: datetime | None) -> list[dict]:
    events = []
    if not INFRA_LOG_PATH.exists():
        return events

    mtime = datetime.fromtimestamp(INFRA_LOG_PATH.stat().st_mtime, tz=timezone.utc)
    with open(INFRA_LOG_PATH, "rb") as f:
        data = f.read().decode("utf-8", errors="replace")

    for line in data.split("\n"):
        line = line.rstrip("\r\n")
        if not line:
            continue
        ts = parse_infra_timestamp(line)
        if ts and since_dt and ts < since_dt:
            continue
        if ts is None and since_dt and mtime < since_dt:
            continue

        create_time = ts_to_iso(ts) if ts else ts_to_iso(mtime)
        m = INFRA_PATTERN.search(line)
        if m:
            events.append(make_event(
                repo="wande-infra",
                issue_number=None,
                phase="infrastructure",
                error_type="infra_monitor_alert",
                error_message=line.strip()[:500],
                source_file=str(INFRA_LOG_PATH),
                create_time=create_time,
            ))
    return events


# ---------- E2E logs 解析 ----------
E2E_SYSERROR_PATTERN = re.compile(r"(Exception|Error|Traceback).*", re.I)


def parse_e2e_logs(since_dt: datetime | None) -> list[dict]:
    events = []
    sys_error_path = E2E_LOG_DIR / "sys-error.log"
    if sys_error_path.exists():
        mtime = datetime.fromtimestamp(sys_error_path.stat().st_mtime, tz=timezone.utc)
        with open(sys_error_path, "rb") as f:
            data = f.read().decode("utf-8", errors="replace")
        for line in data.split("\n"):
            line = line.rstrip("\r\n")
            if not line:
                continue
            # sys-error.log 通常没有时间戳，使用 mtime
            if since_dt and mtime < since_dt:
                continue
            m = E2E_SYSERROR_PATTERN.search(line)
            if m:
                events.append(make_event(
                    repo="wande-play",
                    issue_number=None,
                    phase="testing",
                    error_type="e2e_exception",
                    error_message=line.strip()[:500],
                    source_file=str(sys_error_path),
                    create_time=ts_to_iso(mtime),
                ))

    # test-results 目录中的失败
    test_results_dir = E2E_LOG_DIR / "test-results"
    if test_results_dir.exists():
        for tr_path in test_results_dir.glob("*"):
            if tr_path.is_file():
                tr_mtime = datetime.fromtimestamp(tr_path.stat().st_mtime, tz=timezone.utc)
                if since_dt and tr_mtime < since_dt:
                    continue
                with open(tr_path, "rb") as f:
                    content = f.read().decode("utf-8", errors="replace")
                if "failed" in content.lower() or "failure" in content.lower():
                    events.append(make_event(
                        repo="wande-play",
                        issue_number=None,
                        phase="testing",
                        error_type="e2e_test_failed",
                        error_message=f"Test results contain failures in {tr_path.name}",
                        source_file=str(tr_path),
                        create_time=ts_to_iso(tr_mtime),
                    ))
    return events


def parse_e2e_traceability(since_dt: datetime | None) -> list[dict]:
    events = []
    if not E2E_TRACE_PATH.exists():
        return events

    mtime = datetime.fromtimestamp(E2E_TRACE_PATH.stat().st_mtime, tz=timezone.utc)
    if since_dt and mtime < since_dt:
        return events

    try:
        with open(E2E_TRACE_PATH, "rb") as f:
            data = json.load(f)
    except Exception:
        return events

    # 简单检查 requirement-map 里的 failed 指标
    failed_issues = []
    if isinstance(data, dict):
        for k, v in data.items():
            if isinstance(v, dict) and v.get("status") == "failed":
                failed_issues.append(k)
            if isinstance(v, dict) and isinstance(v.get("tests"), list):
                for t in v.get("tests", []):
                    if isinstance(t, dict) and t.get("status") == "failed":
                        failed_issues.append(f"{k}:{t.get('name','')}")

    if failed_issues:
        events.append(make_event(
            repo="wande-play",
            issue_number=None,
            phase="testing",
            error_type="e2e_traceability_failed",
            error_message=f"Failed traceability entries: {', '.join(failed_issues[:20])}",
            source_file=str(E2E_TRACE_PATH),
            create_time=ts_to_iso(mtime),
        ))
    return events


# ---------- 主函数 ----------
def main():
    parser = argparse.ArgumentParser(description="G7e日志解析脚本")
    parser.add_argument("--since", type=str, default=None, help="ISO-8601 起始时间，只扫描该时间之后的日志")
    args = parser.parse_args()

    since_dt = None
    if args.since:
        since_dt = parse_iso_z(args.since)

    # 先构建 session 缓存，用于给 .log 事件补充 session_id/model
    session_cache = build_session_cache(since_dt)

    all_events = []
    all_events.extend(parse_coding_cc_logs(since_dt, session_cache))
    all_events.extend(parse_raw_jsonl(since_dt))
    all_events.extend(parse_proxy_log(since_dt))
    all_events.extend(parse_infra_log(since_dt))
    all_events.extend(parse_e2e_logs(since_dt))
    all_events.extend(parse_e2e_traceability(since_dt))

    # 去重：基于 source_file + error_message + create_time（前三秒合并）
    dedup = []
    seen = set()
    for ev in sorted(all_events, key=lambda x: x["create_time"]):
        key = (ev["source_file"], ev["error_type"], ev["error_message"][:120], ev["create_time"][:16])
        if key not in seen:
            seen.add(key)
            dedup.append(ev)

    # 关联 token/duration 统计到已生成事件
    token_stats = parse_raw_jsonl_token_stats(since_dt)
    for ev in dedup:
        if ev.get("session_id"):
            key = (ev["repo"], ev.get("issue_number"), ev["session_id"])
            if key in token_stats:
                ev["duration_ms"] = token_stats[key].get("duration_ms", ev.get("duration_ms", 0))
                ev["token_cost"] = token_stats[key].get("token_cost", ev.get("token_cost", 0.0))

    print(json.dumps(dedup, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
