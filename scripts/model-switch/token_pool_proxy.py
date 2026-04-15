#!/usr/bin/env python3
"""
Token Pool Proxy v3 — 多源Key自动切换代理
==========================================
监听 0.0.0.0:9855，提供 Anthropic Messages API 兼容端点
CC(Claude Code) 通过 ANTHROPIC_BASE_URL=http://localhost:9855 连接

v4 核心改进（相比v2）：
  1. 三种上游类型: zhipu(直连) / anthropic_compat(中转站) / openai_compat(OpenAI格式)
  2. 按 priority 字段严格分组，同优先级内 round-robin 轮询
  3. 统一错误分类: RATE_LIMIT / PLATFORM_OVERLOAD / QUOTA_EXHAUSTED / BALANCE_EXHAUSTED / UNRECOVERABLE
  4. 智谱错误码精确区分: 1302/1303(速率) vs 1308/1310(限额) vs 1309/1311(不可恢复)
  5. deadline-driven 重试: 120s 内持续重试，CC 无感知; 超时才透传错误
  6. 并发信号量: 控制同时向上游发出的请求数，从源头减少 429
  7. 详尽日志: 每次异常记录 key名/错误类型/原始返回/决策动作

优先级链: 智谱直连Key(priority=1) → 中转站Key(priority=2) → 本地vLLM保底(priority=3)
降级规则: 只有 QUOTA_EXHAUSTED/BALANCE_EXHAUSTED 才触发降级，RATE_LIMIT 只换同优先级Key

部署: systemd token-pool-proxy.service
配置: keys.json (同目录)
"""

import json
import time
import os
import sys
import logging
import hashlib
import random
import re
from enum import Enum
from datetime import datetime, timezone, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import urllib.request
import urllib.error
import threading

# ===================== 配置 =====================

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
KEYS_FILE = os.path.join(SCRIPT_DIR, "keys.json")
STATE_FILE = os.path.join(SCRIPT_DIR, "pool_state.json")
PORT = 9855
CST = timezone(timedelta(hours=8))

# 重试配置
REQUEST_DEADLINE_SECS = 120      # 单次请求的总超时（秒）
BACKOFF_BASE_SECS = 2            # 指数退避基数
BACKOFF_CAP_SECS = 30            # 退避上限
BACKOFF_JITTER = 0.3             # 抖动比例 ±30%
CONCURRENCY_PER_PRIORITY = 6     # 每个优先级的并发信号量（可在keys.json中覆盖）

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [TokenPool] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(SCRIPT_DIR, "proxy.log"), encoding="utf-8"),
    ],
)
logger = logging.getLogger(__name__)


# ===================== 错误分类枚举 =====================

class ErrorType(Enum):
    RATE_LIMIT = "rate_limit"              # 换key重试，CC无感知
    PLATFORM_OVERLOAD = "platform_overload" # backoff等待，CC无感知
    QUOTA_EXHAUSTED = "quota_exhausted"     # 标记冷却+降级到下一优先级
    BALANCE_EXHAUSTED = "balance_exhausted" # 长期冷却+降级
    UNRECOVERABLE = "unrecoverable"         # 直接透传给CC


# ===================== Key池管理 =====================

_lock = threading.Lock()
_config = {}
_pool_state = {}   # {key_name: {"cooldown_until": iso_str, "error_code": str, "error_type": str, ...}}
_round_robin = {}  # {priority: index} — 每个优先级独立的轮询指针
_stats = {}        # {key_name: {"requests": int, "errors": int, "last_used": iso_str}}
_semaphores = {}   # {priority: threading.Semaphore} — 每个优先级的并发控制
_start_time = None

# ===================== 用量上报 =====================

# 上报队列，用于控制并发上报数量
_usage_report_queue = []
_usage_report_lock = threading.Lock()
_MAX_REPORT_QUEUE_SIZE = 100  # 队列满时丢弃最老的


def _report_usage_async(key_name, model, prompt_tokens, completion_tokens, latency_ms, status_code, error_msg=None):
    """异步上报用量数据到万德后端

    Args:
        key_name: 使用的Key名称
        model: 请求的模型名
        prompt_tokens: 输入token数
        completion_tokens: 输出token数
        latency_ms: 请求耗时(毫秒)
        status_code: HTTP状态码
        error_msg: 错误信息(如果有)
    """
    usage_report_cfg = _config.get("usage_report", {})
    if not usage_report_cfg.get("enabled", False):
        return

    report_url = usage_report_cfg.get("url", "")
    if not report_url:
        return

    timeout_secs = usage_report_cfg.get("timeout_secs", 5)

    report_data = {
        "key_name": key_name,
        "model": model,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "latency_ms": latency_ms,
        "status_code": status_code,
        "error_msg": error_msg,
        "timestamp": _now().isoformat(),
    }

    def _do_report():
        try:
            req = urllib.request.Request(
                report_url,
                data=json.dumps(report_data).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout_secs) as resp:
                if resp.status == 200:
                    logger.debug(f"[usage_report] 上报成功: {key_name} model={model} tokens={prompt_tokens}+{completion_tokens}")
                else:
                    logger.warning(f"[usage_report] 上报返回非200: HTTP {resp.status}")
        except Exception as e:
            # 上报失败静默处理，不影响主流程
            logger.debug(f"[usage_report] 上报失败: {e}")

            # 重试一次
            try:
                time.sleep(0.5)
                req = urllib.request.Request(
                    report_url,
                    data=json.dumps(report_data).encode("utf-8"),
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=timeout_secs) as resp:
                    if resp.status == 200:
                        logger.debug(f"[usage_report] 重试上报成功: {key_name}")
            except Exception as e2:
                logger.debug(f"[usage_report] 重试上报失败，放弃: {e2}")

    # 启动独立线程进行异步上报
    try:
        with _usage_report_lock:
            # 队列满时丢弃最老的
            while len(_usage_report_queue) >= _MAX_REPORT_QUEUE_SIZE:
                old_thread = _usage_report_queue.pop(0)
                # 不join，让旧线程自然结束

            t = threading.Thread(target=_do_report, daemon=True)
            t.start()
            _usage_report_queue.append(t)
    except Exception as e:
        logger.debug(f"[usage_report] 启动上报线程失败: {e}")


def _parse_usage_from_response(resp_body, key_type="anthropic_compat"):
    """从响应体中解析token用量

    Returns: (prompt_tokens, completion_tokens) 或 (0, 0)
    """
    try:
        data = json.loads(resp_body) if isinstance(resp_body, bytes) else resp_body
        if not isinstance(data, dict):
            return 0, 0

        usage = data.get("usage", {})
        if not usage:
            return 0, 0

        # 智谱格式: input_tokens / output_tokens
        prompt_tokens = usage.get("input_tokens", 0)
        completion_tokens = usage.get("output_tokens", 0)

        # OpenAI格式: prompt_tokens / completion_tokens
        if prompt_tokens == 0 and completion_tokens == 0:
            prompt_tokens = usage.get("prompt_tokens", 0)
            completion_tokens = usage.get("completion_tokens", 0)

        return prompt_tokens, completion_tokens
    except Exception:
        return 0, 0


def _now():
    return datetime.now(CST)


def _load_config():
    global _config
    with open(KEYS_FILE, "r") as f:
        _config = json.load(f)

    enabled = [k for k in _config["keys"] if k.get("enabled")]

    # 按 provider 分类统计
    provider_counts = {}
    for k in enabled:
        p = k.get("provider", k.get("name", "unknown"))
        provider_counts[p] = provider_counts.get(p, 0) + 1

    # 初始化并发信号量
    concurrency = _config.get("concurrency_per_priority", CONCURRENCY_PER_PRIORITY)
    priorities = set(k.get("priority", 1) for k in enabled)
    for p in priorities:
        if p not in _semaphores:
            _semaphores[p] = threading.Semaphore(concurrency)

    provider_str = ", ".join(f"{p}:{c}" for p, c in sorted(provider_counts.items()))
    logger.info(f"配置加载: {len(enabled)} 个启用Key ({provider_str}), 并发信号量: {concurrency}/优先级")


def _load_state():
    global _pool_state
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                _pool_state = json.load(f)
        except Exception:
            _pool_state = {}


def _save_state():
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(_pool_state, f, indent=2, ensure_ascii=False)
    except Exception as e:
        logger.error(f"状态保存失败: {e}")


def _get_enabled_keys():
    return [k for k in _config.get("keys", []) if k.get("enabled")]


def _get_keys_by_priority():
    """按 priority 字段严格分组返回 {priority: [key_list]}"""
    enabled = _get_enabled_keys()
    groups = {}
    for k in enabled:
        p = k.get("priority", 1)
        groups.setdefault(p, []).append(k)
    return groups


def _is_key_available(key_name):
    """检查Key是否可用(未在冷却中)"""
    state = _pool_state.get(key_name, {})
    cooldown_until = state.get("cooldown_until")
    if not cooldown_until:
        return True
    try:
        until = datetime.fromisoformat(cooldown_until)
        if _now() >= until:
            if key_name in _pool_state:
                logger.info(f"[{key_name}] 冷却结束，恢复可用")
                del _pool_state[key_name]
                _save_state()
            return True
        return False
    except Exception:
        return True


def _mark_key_cooldown(key_name, error_type, error_code=None, cooldown_until_iso=None, raw_error=""):
    """标记Key进入冷却

    Args:
        key_name: Key名称
        error_type: ErrorType 枚举
        error_code: 原始错误码（如 1308, 1310）
        cooldown_until_iso: 精确的冷却截止时间（如智谱返回的 next_flush_time）
        raw_error: 原始错误信息（用于日志）
    """
    with _lock:
        now = _now()

        if cooldown_until_iso:
            # 使用上游返回的精确重置时间
            try:
                cooldown_until = datetime.fromisoformat(cooldown_until_iso)
                # 确保有时区信息
                if cooldown_until.tzinfo is None:
                    cooldown_until = cooldown_until.replace(tzinfo=CST)
            except Exception:
                cooldown_until = now + timedelta(hours=5)  # 解析失败默认5h
        elif error_type == ErrorType.BALANCE_EXHAUSTED:
            cooldown_until = now + timedelta(hours=5)  # Kimi 每 5h 重置配额（直到周上限），非 24h
        elif error_type == ErrorType.QUOTA_EXHAUSTED:
            cooldown_until = now + timedelta(hours=5)  # 默认5h，有精确时间时会被覆盖
        elif error_type == ErrorType.UNRECOVERABLE:
            cooldown_until = now + timedelta(hours=720)  # 30天
        else:
            cooldown_until = now + timedelta(hours=1)

        # 统计池中剩余可用Key
        all_keys = _get_enabled_keys()
        available_count = sum(1 for k in all_keys if _is_key_available(k["name"]) and k["name"] != key_name)

        state = {
            "cooldown_until": cooldown_until.isoformat(),
            "marked_at": now.isoformat(),
            "error_type": error_type.value,
            "error_code": str(error_code) if error_code else None,
            "raw_error": raw_error[:500],  # 截断保存
        }
        _pool_state[key_name] = state
        _save_state()

        logger.warning(
            f"[{key_name}] 冷却标记: {error_type.value} | 错误码: {error_code} | "
            f"冷却至: {cooldown_until.strftime('%m-%d %H:%M')} | "
            f"剩余可用Key: {available_count} | 原因: {raw_error[:200]}"
        )


def get_next_key_in_priority(priority, skip_keys=None):
    """在指定优先级内 round-robin 选择下一个可用Key

    Args:
        priority: 优先级数字
        skip_keys: 本次请求中已尝试过的key名称集合

    Returns:
        key配置dict 或 None
    """
    skip_keys = skip_keys or set()
    groups = _get_keys_by_priority()
    keys = groups.get(priority, [])
    if not keys:
        return None

    with _lock:
        if priority not in _round_robin:
            _round_robin[priority] = 0

        n = len(keys)
        start_idx = _round_robin[priority]

        for i in range(n):
            idx = (start_idx + i) % n
            key = keys[idx]
            if key["name"] not in skip_keys and _is_key_available(key["name"]):
                _round_robin[priority] = (idx + 1) % n  # 推进指针
                name = key["name"]
                if name not in _stats:
                    _stats[name] = {"requests": 0, "errors": 0}
                _stats[name]["requests"] += 1
                _stats[name]["last_used"] = _now().isoformat()
                return key

    return None


def record_key_error(key_name):
    with _lock:
        if key_name not in _stats:
            _stats[key_name] = {"requests": 0, "errors": 0}
        _stats[key_name]["errors"] += 1


# ===================== 错误分类函数 =====================

def _extract_error_fields(resp_body):
    """从响应体提取错误信息字段"""
    try:
        data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
        if not isinstance(data, dict):
            return {}, ""

        # 尝试 error 字段
        error = data.get("error", {})
        if isinstance(error, dict):
            code = str(error.get("code", ""))
            err_type = error.get("type", "")
            message = error.get("message", "")
            return {"code": code, "type": err_type, "message": message}, message

        # 顶层 code/message（智谱格式）
        top_code = str(data.get("code", ""))
        top_msg = data.get("message", "")
        return {"code": top_code, "type": "", "message": top_msg}, top_msg
    except Exception:
        return {}, ""


def _parse_flush_time(message):
    """从智谱错误消息中解析 next_flush_time"""
    # 尝试匹配常见的时间格式
    # "已达到...的使用上限。您的限额将在 2026-03-31T18:00:00+08:00 重置"
    # "您已达到每周/每月使用上限，您的限额将在 2026-04-07T00:00:00+08:00 重置"
    patterns = [
        r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+\-]\d{2}:\d{2})',  # ISO 8601 with tz
        r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})',                    # ISO 8601 no tz
        r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',                    # datetime
    ]
    for pattern in patterns:
        match = re.search(pattern, message)
        if match:
            return match.group(1)
    return None


def classify_zhipu_provider(status_code, resp_body):
    """智谱直连错误分类（open.bigmodel.cn）

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    fields, message = _extract_error_fields(resp_body)
    code = fields.get("code", "")

    # 也检查顶层code
    try:
        data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
        if isinstance(data, dict) and not code:
            code = str(data.get("code", ""))
            if not message:
                message = data.get("message", "")
    except Exception:
        pass

    # 速率限制（秒级恢复，换key即可）
    if code in ("1302", "1303"):
        return ErrorType.RATE_LIMIT, code, None, message

    # 平台过载（分钟级恢复，backoff等待）
    if code in ("1305", "1312"):
        return ErrorType.PLATFORM_OVERLOAD, code, None, message

    # 限额耗尽（5h/日/周/月，需要冷却）
    if code == "1308":
        flush_time = _parse_flush_time(message)
        return ErrorType.QUOTA_EXHAUSTED, code, flush_time, message
    if code == "1310":
        flush_time = _parse_flush_time(message)
        return ErrorType.QUOTA_EXHAUSTED, code, flush_time, message
    if code == "1304":
        return ErrorType.QUOTA_EXHAUSTED, code, None, message

    # 不可恢复
    if code in ("1309", "1311", "1313"):
        return ErrorType.UNRECOVERABLE, code, None, message

    # 认证错误
    if code in ("1000", "1001", "1002", "1003", "1004"):
        return ErrorType.UNRECOVERABLE, code, None, message

    # 余额不足
    if code == "1113":
        return ErrorType.BALANCE_EXHAUSTED, code, None, message

    # HTTP 状态码兜底
    if status_code in (401, 403):
        return ErrorType.UNRECOVERABLE, f"HTTP{status_code}", None, message
    if status_code == 402:
        return ErrorType.BALANCE_EXHAUSTED, f"HTTP{status_code}", None, message

    # 未知429按速率限制处理（保守策略）
    if status_code == 429:
        return ErrorType.RATE_LIMIT, code or f"HTTP{status_code}", None, message

    # 其他错误
    return ErrorType.UNRECOVERABLE, code or f"HTTP{status_code}", None, message


def classify_anthropic_compat(status_code, resp_body):
    """Anthropic 格式中转站错误分类（如 aiopus/aisonnet）

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    fields, message = _extract_error_fields(resp_body)
    err_type = fields.get("type", "")
    message_lower = message.lower()

    # 认证错误
    if status_code in (401, 403) or err_type in ("authentication_error", "permission_error"):
        return ErrorType.UNRECOVERABLE, err_type or f"HTTP{status_code}", None, message

    # 余额不足
    if status_code == 402:
        return ErrorType.BALANCE_EXHAUSTED, f"HTTP{status_code}", None, message
    if any(kw in message_lower for kw in ("insufficient", "balance", "余额", "额度不足", "credit")):
        return ErrorType.BALANCE_EXHAUSTED, err_type, None, message

    # 限额耗尽（含 quota/exceeded/5-hour 关键词，不强求 err_type，兼容火山方舟等 OpenAI 兼容格式）
    if status_code == 429 and any(kw in message_lower for kw in ("quota", "exceeded", "limit reached", "usage quota")):
        # 解析精确 reset 时间（格式: "reset at 2026-04-16 06:18:33 +0800 CST"）
        reset_iso = None
        _m = re.search(r'reset at (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+\+0800', message)
        if _m:
            reset_iso = _m.group(1).replace(' ', 'T') + '+08:00'
        return ErrorType.QUOTA_EXHAUSTED, err_type or "quota_exceeded", reset_iso, message

    # 速率限制（不含 quota 关键词）
    if err_type == "rate_limit_error" or status_code == 429:
        return ErrorType.RATE_LIMIT, err_type or f"HTTP{status_code}", None, message

    # 服务过载
    if err_type == "overloaded_error" or status_code == 529:
        return ErrorType.PLATFORM_OVERLOAD, err_type or f"HTTP{status_code}", None, message

    # 其他
    return ErrorType.UNRECOVERABLE, err_type or f"HTTP{status_code}", None, message


def classify_openai_compat(status_code, resp_body):
    """OpenAI 格式中转站错误分类

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    fields, message = _extract_error_fields(resp_body)
    err_type = fields.get("type", "")
    code = fields.get("code", "")
    message_lower = message.lower()

    # 认证错误
    if status_code in (401, 403) or code in ("invalid_api_key", "authentication_error"):
        return ErrorType.UNRECOVERABLE, code or f"HTTP{status_code}", None, message

    # 余额不足
    if status_code == 402 or code == "insufficient_quota":
        return ErrorType.BALANCE_EXHAUSTED, code or f"HTTP{status_code}", None, message
    if any(kw in message_lower for kw in ("insufficient", "balance", "quota exceeded")):
        return ErrorType.BALANCE_EXHAUSTED, code, None, message

    # 限额耗尽
    if status_code == 429 and any(kw in message_lower for kw in ("quota", "exceeded", "limit reached")):
        return ErrorType.QUOTA_EXHAUSTED, code or "quota", None, message

    # 速率限制
    if status_code == 429:
        return ErrorType.RATE_LIMIT, code or f"HTTP{status_code}", None, message

    # 服务过载
    if status_code in (500, 502, 503):
        return ErrorType.PLATFORM_OVERLOAD, code or f"HTTP{status_code}", None, message

    return ErrorType.UNRECOVERABLE, code or f"HTTP{status_code}", None, message


def classify_kimi_provider(status_code, resp_body):
    """Kimi (Moonshot) 直连错误分类（platform.kimi.com）

    官方文档: https://platform.kimi.com/docs/api/chat
    Kimi 使用 OpenAI 兼容格式: {"error": {"type": "...", "message": "..."}}

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    fields, message = _extract_error_fields(resp_body)
    err_type = fields.get("type", "")
    message_lower = message.lower()

    # 余额不足 / 账户暂停
    if status_code in (401, 402, 403)  or err_type == "exceeded_current_quota_error":
        return ErrorType.BALANCE_EXHAUSTED, err_type or f"HTTP{status_code}", None, message
    if any(kw in message_lower for kw in ("suspended", "billing", "balance", "quota", "余额不足", "额度不足")):
        return ErrorType.BALANCE_EXHAUSTED, err_type, None, message

    # 内容过滤 / 请求参数错误 -> 不可恢复（换 key 也一样）
    if err_type in ("content_filter", "invalid_request_error"):
        return ErrorType.UNRECOVERABLE, err_type, None, message

    # 资源不存在
    if status_code == 404 or err_type == "resource_not_found_error":
        return ErrorType.UNRECOVERABLE, err_type or f"HTTP{status_code}", None, message

    # 服务过载（节点级，backoff 等待）
    if err_type == "engine_overloaded_error" or status_code in (500, 502, 503):
        return ErrorType.PLATFORM_OVERLOAD, err_type or f"HTTP{status_code}", None, message

    # 速率限制（并发 / RPM / TPM / TPD，换 key 即可）
    if err_type == "rate_limit_reached_error" or status_code == 429:
        return ErrorType.RATE_LIMIT, err_type or f"HTTP{status_code}", None, message

    # 未知错误
    return ErrorType.UNRECOVERABLE, err_type or f"HTTP{status_code}", None, message


def classify_error(key_cfg, status_code, resp_body):
    """根据 provider 分派到对应的错误分类函数

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    provider = key_cfg.get("provider", "")

    if provider == "zhipu":
        return classify_zhipu_provider(status_code, resp_body)
    elif provider == "kimi":
        return classify_kimi_provider(status_code, resp_body)
    else:
        # 其他供应商统一使用 anthropic_compat 错误分类
        return classify_anthropic_compat(status_code, resp_body)


# ===================== 上下文窗口截断 =====================

def _estimate_tokens(text):
    """粗略估算token数（中英混合约3字符/token）"""
    if not text:
        return 0
    return len(str(text)) // 3

def _truncate_messages_if_needed(body_dict, context_window):
    """根据目标模型的context_window截断消息历史

    策略：保留system + 第一条消息(Issue内容) + 尽可能多的最近消息
    """
    if not context_window or context_window <= 0:
        return body_dict

    reserve_output = body_dict.get("max_tokens", 8192)
    max_input = context_window - reserve_output

    # 估算system prompt token数
    system = body_dict.get("system", "")
    system_tokens = _estimate_tokens(str(system))
    remaining = max_input - system_tokens

    messages = body_dict.get("messages", [])
    if len(messages) <= 2:
        return body_dict  # 太少，不截断

    # 估算总token数
    total_tokens = sum(_estimate_tokens(str(m.get("content", ""))) for m in messages)
    if total_tokens + system_tokens <= max_input:
        return body_dict  # 没超限，不截断

    # 保留第一条消息（通常含Issue内容）
    first_msg = messages[0]
    first_tokens = _estimate_tokens(str(first_msg.get("content", "")))
    remaining -= first_tokens

    # 从最新往前保留
    kept_tail = []
    for msg in reversed(messages[1:]):
        msg_tokens = _estimate_tokens(str(msg.get("content", "")))
        if remaining - msg_tokens < 0:
            break
        kept_tail.insert(0, msg)
        remaining -= msg_tokens

    truncated_count = len(messages) - 1 - len(kept_tail)
    if truncated_count > 0:
        logger.warning(
            f"[context_truncate] 截断{truncated_count}条消息 "
            f"(原{len(messages)}条, 保留{1 + len(kept_tail)}条, "
            f"context_window={context_window})"
        )

    body_dict = dict(body_dict)
    final_messages = [first_msg] + kept_tail

    # === 修复 tool_call/tool_result 配对完整性 ===
    # 收集所有保留的 tool_use id
    tool_call_ids = set()
    for msg in final_messages:
        if msg.get("role") == "assistant":
            content = msg.get("content", [])
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "tool_use":
                        tool_call_ids.add(block.get("id"))

    # 移除引用了不存在 tool_call_id 的 tool_result 消息
    cleaned = []
    removed_orphans = 0
    for msg in final_messages:
        if msg.get("role") == "user":
            content = msg.get("content", [])
            if isinstance(content, list):
                has_orphan = any(
                    isinstance(b, dict)
                    and b.get("type") == "tool_result"
                    and b.get("tool_use_id") not in tool_call_ids
                    for b in content
                )
                if has_orphan:
                    # 过滤掉孤立的 tool_result block，保留其他内容
                    filtered = [
                        b for b in content
                        if not (isinstance(b, dict)
                                and b.get("type") == "tool_result"
                                and b.get("tool_use_id") not in tool_call_ids)
                    ]
                    if filtered:
                        msg = dict(msg)
                        msg["content"] = filtered
                    else:
                        removed_orphans += 1
                        continue  # 整条消息都是孤立 tool_result，跳过
        cleaned.append(msg)

    if removed_orphans > 0:
        logger.info(f"[context_truncate] 移除{removed_orphans}条孤立tool_result消息")

    body_dict["messages"] = cleaned
    return body_dict


# ===================== Anthropic ↔ OpenAI 格式转换 =====================

def anthropic_to_openai(anthropic_body, model_override=None):
    """将Anthropic Messages API请求转换为OpenAI Chat Completions格式"""
    messages = []

    system = anthropic_body.get("system")
    if system:
        if isinstance(system, str):
            messages.append({"role": "system", "content": system})
        elif isinstance(system, list):
            text = " ".join(b.get("text", "") for b in system if b.get("type") == "text")
            if text:
                messages.append({"role": "system", "content": text})

    for msg in anthropic_body.get("messages", []):
        role = msg.get("role", "user")
        content = msg.get("content", "")

        if isinstance(content, list):
            text_parts = []
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    text_parts.append(block.get("text", ""))
                elif isinstance(block, str):
                    text_parts.append(block)
            content = "\n".join(text_parts)

        messages.append({"role": role, "content": content})

    model = model_override or _config.get("fallback", {}).get("vllm_model", "/model")

    return {
        "model": model,
        "messages": messages,
        "max_tokens": anthropic_body.get("max_tokens", 4096),
        "temperature": anthropic_body.get("temperature", 0.7),
        "stream": False,
    }


def openai_to_anthropic(openai_resp, requested_model="qwen3.5-122b-local"):
    """将OpenAI Chat Completions响应转换为Anthropic Messages API格式"""
    choice = openai_resp.get("choices", [{}])[0]
    content_text = choice.get("message", {}).get("content", "")
    usage = openai_resp.get("usage", {})

    # 清洗思维链泄漏
    if "<think>" in content_text:
        content_text = re.sub(r'<think>.*?</think>', '', content_text, flags=re.DOTALL).strip()

    return {
        "id": f"msg_{hashlib.md5(str(time.time()).encode()).hexdigest()[:24]}",
        "type": "message",
        "role": "assistant",
        "model": requested_model,
        "content": [{"type": "text", "text": content_text}],
        "stop_reason": "end_turn",
        "stop_sequence": None,
        "usage": {
            "input_tokens": usage.get("prompt_tokens", 0),
            "output_tokens": usage.get("completion_tokens", 0),
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        },
    }


# ===================== 模型映射 =====================

def _resolve_model(key_cfg, requested_model):
    """根据CC请求的模型名，映射到上游实际使用的模型名"""
    model_map = key_cfg.get("model_map", {})
    if model_map and requested_model in model_map:
        return model_map[requested_model]
    return key_cfg.get("model", requested_model)


# ===================== 用量查询适配器 =====================

# 用量查询缓存: {key_name: {"data": {...}, "fetched_at": iso_str}}
_quota_cache = {}
_QUOTA_CACHE_TTL_SECS = 60  # 缓存 60s，避免频繁调用上游

# Anthropic 响应 headers 用量缓存: {key_name: {"headers": {...}, "fetched_at": timestamp}}
_anthropic_quota_headers = {}
_ANTHROPIC_HEADERS_TTL_SECS = 30  # headers 缓存 30s


def _query_quota_zhipu(api_key, base_url=None):
    """智谱 Coding Plan 用量查询

    接口: GET {base_url}/api/monitor/usage/quota/limit
    认证: Authorization: {api_key} (不加Bearer)

    Returns: 统一格式 dict 或 None
    """
    host = base_url or _config.get("upstream", {}).get("base_url", "https://open.bigmodel.cn/api/anthropic")
    # 从 Anthropic 端点提取基址: https://open.bigmodel.cn/api/anthropic → https://open.bigmodel.cn
    # 从直接域名保持: https://open.bigmodel.cn → https://open.bigmodel.cn
    parts = host.split("/api/")
    api_host = parts[0] if parts else host

    url = f"{api_host}/api/monitor/usage/quota/limit"

    req = urllib.request.Request(url, headers={
        "Authorization": api_key,
        "Accept": "application/json",
        "Content-Type": "application/json",
    })

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())

        if not data.get("success"):
            return None

        limits = data.get("data", {}).get("limits", [])
        level = data.get("data", {}).get("level", "unknown")

        # 解析 unit: 3=小时, 4=天, 5=月, 6=周
        unit_map = {1: "min", 2: "min", 3: "hour", 4: "day", 5: "month", 6: "week"}

        quotas = []
        for limit in limits:
            limit_type = limit.get("type", "")
            unit = limit.get("unit", 0)
            number = limit.get("number", 1)
            percentage = limit.get("percentage", 0)  # 剩余百分比
            next_reset_ms = limit.get("nextResetTime", 0)

            # 构建窗口描述
            unit_label = unit_map.get(unit, f"unit{unit}")
            window = f"{number}{unit_label}"

            # 解析重置时间
            reset_time = None
            if next_reset_ms:
                try:
                    reset_time = datetime.fromtimestamp(next_reset_ms / 1000, tz=CST).isoformat()
                except Exception:
                    pass

            quota_entry = {
                "type": limit_type,      # TOKENS_LIMIT / TIME_LIMIT
                "window": window,         # "5hour" / "1week" / "1month"
                "used_pct": percentage,   # 已使用百分比（智谱返回的 percentage 是已用量）
                "next_reset": reset_time,
            }

            # TIME_LIMIT 有具体数据（MCP工具）
            if limit_type == "TIME_LIMIT":
                quota_entry["usage"] = limit.get("currentValue", 0)
                quota_entry["total"] = limit.get("usage", 0)  # 智谱的字段名比较迷惑，usage其实是总额
                quota_entry["remaining"] = limit.get("remaining", 0)

            quotas.append(quota_entry)

        return {
            "provider": "zhipu",
            "plan": level,
            "quotas": quotas,
        }

    except Exception as e:
        logger.debug(f"[quota] 智谱用量查询失败: {e}")
        return None


def _query_quota_kimi(api_key, api_url=None):
    """Kimi (Moonshot) 余额查询

    接口: GET https://api.moonshot.cn/v1/users/me/balance
    认证: Authorization: Bearer {api_key}
    文档: https://platform.moonshot.cn/docs/api/balance

    Returns: 统一格式 dict 或 None
    {
        "provider": "kimi",
        "plan": "coding_plan",
        "quotas": [
            {
                "type": "BALANCE",
                "available_balance": float,  # 可用余额
                "voucher_balance": float,    # 代金券余额
                "cash_balance": float        # 现金余额
            }
        ]
    }
    """
    url = "https://api.moonshot.cn/v1/users/me/balance"

    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
    })

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())

        # 解析余额数据
        # 返回格式: {"data": {"available_balance": 100.0, "voucher_balance": 50.0, "cash_balance": 50.0}}
        balance_data = data.get("data", {})

        available = balance_data.get("available_balance", 0)
        voucher = balance_data.get("voucher_balance", 0)
        cash = balance_data.get("cash_balance", 0)

        quotas = [{
            "type": "BALANCE",
            "available_balance": available,
            "voucher_balance": voucher,
            "cash_balance": cash,
        }]

        return {
            "provider": "kimi",
            "plan": "coding_plan",
            "quotas": quotas,
        }

    except urllib.error.HTTPError as e:
        try:
            resp_body = e.read().decode('utf-8')
        except:
            resp_body = ""
        logger.debug(f"[quota] Kimi 余额查询失败: HTTP {e.code} - {resp_body[:200]}")
        return None
    except Exception as e:
        logger.debug(f"[quota] Kimi 余额查询失败: {e}")
        return None


def _query_quota_anthropic_compat(api_key, api_url=None):
    """中转站(anthropic_compat)用量查询 — 预留接口

    不同中转站的用量查询接口各不相同，后续按需实现。
    返回统一格式或 None。
    """
    # TODO: 根据具体中转站实现
    return None


def _query_quota_openai_compat(api_key, api_url=None):
    """中转站(openai_compat)用量查询 — 预留接口

    部分中转站支持 /dashboard/billing/usage 或类似接口。
    返回统一格式或 None。
    """
    # TODO: 根据具体中转站实现
    return None


def query_provider_quota(key_cfg):
    """查询单个 key 的用量信息，带缓存

    Returns: 统一格式 dict 或 None
    {
        "provider": "zhipu",
        "plan": "max",
        "quotas": [
            {
                "type": "TOKENS_LIMIT",
                "window": "5hour",
                "remaining_pct": 100,
                "next_reset": "2026-03-31T14:15:31+08:00"
            },
            ...
        ]
    }
    """
    key_name = key_cfg["name"]
    now = time.monotonic()

    # 检查缓存
    cached = _quota_cache.get(key_name)
    if cached and (now - cached.get("_mono", 0)) < _QUOTA_CACHE_TTL_SECS:
        return cached.get("data")

    # 按 provider 分派查询
    key_provider = key_cfg.get("provider", key_name)
    api_key = key_cfg["api_key"]
    result = None

    if key_provider == "zhipu":
        result = _query_quota_zhipu(api_key)
        if result:
            result["provider"] = key_provider
    elif key_provider == "kimi":
        # Kimi coding plan 暂无余额查询 API，依赖 headers 解析
        result = None
    else:
        # 其他供应商暂无用量查询接口
        result = None

    # 更新缓存
    _quota_cache[key_name] = {"data": result, "_mono": now}
    return result


def _parse_anthropic_rate_limit_headers(resp_headers):
    """解析 Anthropic 响应 headers 中的用量信息

    Anthropic 会在响应 headers 中返回频限信息：
    - anthropic-ratelimit-requests-limit: 当前周期内最大请求数
    - anthropic-ratelimit-requests-remaining: 剩余可用请求数
    - anthropic-ratelimit-requests-reset: 请求限制重置时间
    - anthropic-ratelimit-input-tokens-limit: 输入 token 上限
    - anthropic-ratelimit-input-tokens-remaining: 剩余输入 token 数
    - anthropic-ratelimit-output-tokens-limit: 输出 token 上限
    - anthropic-ratelimit-output-tokens-remaining: 剩余输出 token 数

    Returns: dict 或 None
    """
    quotas = []

    # 请求数限制
    req_limit = resp_headers.get("anthropic-ratelimit-requests-limit")
    req_remaining = resp_headers.get("anthropic-ratelimit-requests-remaining")
    req_reset = resp_headers.get("anthropic-ratelimit-requests-reset")

    if req_limit and req_remaining:
        try:
            limit_val = int(req_limit)
            remaining_val = int(req_remaining)
            used_pct = round((limit_val - remaining_val) / limit_val * 100, 2) if limit_val > 0 else 0

            quota_entry = {
                "type": "REQUESTS_LIMIT",
                "limit": limit_val,
                "remaining": remaining_val,
                "used_pct": used_pct,
            }
            if req_reset:
                quota_entry["reset_at"] = req_reset
            quotas.append(quota_entry)
        except (ValueError, TypeError):
            pass

    # 输入 token 限制
    input_limit = resp_headers.get("anthropic-ratelimit-input-tokens-limit")
    input_remaining = resp_headers.get("anthropic-ratelimit-input-tokens-remaining")
    input_reset = resp_headers.get("anthropic-ratelimit-input-tokens-reset")

    if input_limit and input_remaining:
        try:
            limit_val = int(input_limit)
            remaining_val = int(input_remaining)
            used_pct = round((limit_val - remaining_val) / limit_val * 100, 2) if limit_val > 0 else 0

            quota_entry = {
                "type": "INPUT_TOKENS_LIMIT",
                "limit": limit_val,
                "remaining": remaining_val,
                "used_pct": used_pct,
            }
            if input_reset:
                quota_entry["reset_at"] = input_reset
            quotas.append(quota_entry)
        except (ValueError, TypeError):
            pass

    # 输出 token 限制
    output_limit = resp_headers.get("anthropic-ratelimit-output-tokens-limit")
    output_remaining = resp_headers.get("anthropic-ratelimit-output-tokens-remaining")
    output_reset = resp_headers.get("anthropic-ratelimit-output-tokens-reset")

    if output_limit and output_remaining:
        try:
            limit_val = int(output_limit)
            remaining_val = int(output_remaining)
            used_pct = round((limit_val - remaining_val) / limit_val * 100, 2) if limit_val > 0 else 0

            quota_entry = {
                "type": "OUTPUT_TOKENS_LIMIT",
                "limit": limit_val,
                "remaining": remaining_val,
                "used_pct": used_pct,
            }
            if output_reset:
                quota_entry["reset_at"] = output_reset
            quotas.append(quota_entry)
        except (ValueError, TypeError):
            pass

    if quotas:
        return {
            "quotas": quotas,
            "source": "response_headers",
        }
    return None


def _save_anthropic_quota_headers(key_name, resp_headers):
    """保存 Anthropic 响应 headers 中的用量信息"""
    # 调试：记录收到的 headers
    ratelimit_headers = {k: v for k, v in resp_headers.items() if "ratelimit" in k.lower() or "limit" in k.lower()}
    if ratelimit_headers:
        logger.debug(f"[{key_name}] 收到 ratelimit headers: {ratelimit_headers}")

    quota_info = _parse_anthropic_rate_limit_headers(resp_headers)
    if quota_info:
        _anthropic_quota_headers[key_name] = {
            "data": quota_info,
            "fetched_at": time.monotonic(),
        }
        logger.debug(f"[{key_name}] 保存 headers 用量信息: {len(quota_info.get('quotas', []))} 条配额")


def _get_anthropic_quota_headers(key_name):
    """获取缓存的 Anthropic headers 用量信息"""
    cached = _anthropic_quota_headers.get(key_name)
    if cached:
        age = time.monotonic() - cached.get("fetched_at", 0)
        if age < _ANTHROPIC_HEADERS_TTL_SECS:
            return cached.get("data")
    return None


def call_anthropic_compat(body_bytes, api_key, path="/v1/messages", base_url=None, model_map=None, key_name=None):
    """调用Anthropic兼容供应商（智谱直连、Kimi、无问星穹、火山等）

    Returns: (status_code, resp_body, resp_headers_dict)
    """
    url = f"{base_url}{path}"

    # 模型名重写
    if model_map:
        try:
            body_obj = json.loads(body_bytes)
            orig_model = body_obj.get("model", "")
            if orig_model in model_map:
                body_obj["model"] = model_map[orig_model]
                body_bytes = json.dumps(body_obj).encode()
                logger.info(f"  模型重写: {orig_model} → {model_map[orig_model]}")
        except Exception:
            pass

    headers = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
    }

    req = urllib.request.Request(url, data=body_bytes, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            resp_headers = dict(resp.headers)
            # 保存用量信息（如果 key_name 提供）
            if key_name:
                _save_anthropic_quota_headers(key_name, resp_headers)
            return resp.status, resp.read(), resp_headers
    except urllib.error.HTTPError as e:
        err_body = e.read() if e.fp else b"{}"
        # 即使是错误响应，也可能包含用量 headers
        if key_name and e.headers:
            _save_anthropic_quota_headers(key_name, dict(e.headers))
        return e.code, err_body, dict(e.headers) if e.headers else {}
    except Exception as e:
        error_resp = json.dumps({"type": "error", "error": {"type": "proxy_error", "message": str(e)}}).encode()
        return 502, error_resp, {}


def call_openai_compat(anthropic_body, key_cfg):
    """调用OpenAI兼容供应商，做Anthropic→OpenAI→Anthropic格式转换

    Returns: (status_code, anthropic_resp_dict_or_None, err_body_or_None)
    """
    api_url = key_cfg.get("api_url", "")
    api_key = key_cfg.get("api_key", "")
    requested_model = anthropic_body.get("model", "unknown")
    target_model = _resolve_model(key_cfg, requested_model)

    if not api_url.endswith("/v1/chat/completions"):
        url = api_url.rstrip("/") + "/v1/chat/completions"
    else:
        url = api_url

    openai_body = anthropic_to_openai(anthropic_body, model_override=target_model)

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }

    req = urllib.request.Request(
        url, data=json.dumps(openai_body).encode(), headers=headers, method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            openai_resp = json.loads(resp.read())
            anthropic_resp = openai_to_anthropic(openai_resp, requested_model)
            return 200, anthropic_resp, None
    except urllib.error.HTTPError as e:
        err_body = e.read() if e.fp else b"{}"
        return e.code, None, err_body
    except Exception as e:
        logger.error(f"[openai_compat] 调用失败: {e}")
        return 502, None, json.dumps({"error": {"message": str(e)}}).encode()


def call_local_vllm(anthropic_body):
    """调用本地vLLM作为保底，做格式转换"""
    fallback_cfg = _config.get("fallback", {})
    vllm_url = fallback_cfg.get("vllm_url", "http://localhost:8000/v1/chat/completions")

    openai_body = anthropic_to_openai(anthropic_body)

    req = urllib.request.Request(
        vllm_url,
        data=json.dumps(openai_body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            openai_resp = json.loads(resp.read())
            requested_model = anthropic_body.get("model", "qwen3.5-122b-local")
            anthropic_resp = openai_to_anthropic(openai_resp, requested_model)
            return 200, anthropic_resp
    except Exception as e:
        logger.error(f"[本地vLLM] 调用失败: {e}")
        return 500, {
            "type": "error",
            "error": {"type": "fallback_error", "message": f"本地vLLM也失败: {e}"},
        }


def _apply_env(env_cfg):
    """应用 key 配置中的环境变量，返回被覆盖的旧值"""
    if not env_cfg or not isinstance(env_cfg, dict):
        return {}

    old_values = {}
    for key, value in env_cfg.items():
        old_values[key] = os.environ.get(key)  # 保存旧值（可能为 None）
        os.environ[key] = str(value)
        logger.debug(f"  设置环境变量: {key}={value}")
    return old_values


def _restore_env(old_values):
    """恢复环境变量到调用前的状态"""
    for key, old_value in old_values.items():
        if old_value is None:
            os.environ.pop(key, None)  # 移除新设置的变量
        else:
            os.environ[key] = old_value  # 恢复旧值


def _call_upstream(key_cfg, body_bytes, body_dict, path):
    """根据 key type 调用对应的上游

    Returns: (status_code, resp_body_bytes_or_dict, is_openai_compat)
    """
    key_type = key_cfg.get("type", "anthropic_compat")
    api_key = key_cfg["api_key"]
    key_name = key_cfg.get("name")

    # === 上下文窗口截断 ===
    context_window = key_cfg.get("context_window", 0)
    if context_window > 0 and body_dict:
        body_dict = _truncate_messages_if_needed(body_dict, context_window)
        body_bytes = json.dumps(body_dict, ensure_ascii=False).encode("utf-8")

    # 应用 key 配置中的环境变量（仅对本次请求有效）
    env_cfg = key_cfg.get("env", {})
    old_env = _apply_env(env_cfg)

    try:
        if key_type == "anthropic_compat":
            base_url = key_cfg.get("api_url", "")
            model_map = key_cfg.get("model_map")
            status, resp_body, _ = call_anthropic_compat(body_bytes, api_key, path, base_url, model_map, key_name)
            return status, resp_body, False

        elif key_type == "openai_compat":
            status, anthropic_resp, err_body = call_openai_compat(body_dict, key_cfg)
            if status == 200 and anthropic_resp:
                return 200, anthropic_resp, True
            return status, err_body, True

        else:
            return 400, json.dumps({"error": {"message": f"Unknown key type: {key_type}"}}).encode(), False
    finally:
        # 恢复环境变量（确保不影响其他请求）
        _restore_env(old_env)


# ===================== HTTP Handler =====================

class ProxyHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass

    def _send(self, status, body, content_type="application/json"):
        if isinstance(body, dict):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, str):
            body = body.encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self._send(200, b"")

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"status": "ok", "service": "TokenPoolProxy", "port": PORT, "version": "3.0"})
            return

        if self.path == "/status":
            keys = _get_enabled_keys()
            key_status = []
            for k in keys:
                name = k["name"]
                available = _is_key_available(name)
                state = _pool_state.get(name, {})
                stats = _stats.get(name, {"requests": 0, "errors": 0})

                entry = {
                    "name": name,
                    "type": k.get("type", "zhipu"),
                    "provider": k.get("provider", name),
                    "priority": k.get("priority", 1),
                    "available": available,
                    "requests": stats["requests"],
                    "errors": stats["errors"],
                    "last_used": stats.get("last_used"),
                    "cooldown_type": state.get("error_type"),
                    "cooldown_code": state.get("error_code"),
                    "cooldown_until": state.get("cooldown_until"),
                }

                # 查询上游用量（带缓存，不阻塞主流程）
                quota = query_provider_quota(k)
                if quota:
                    entry["quota"] = quota

                # 对于 anthropic_compat 类型的供应商，尝试获取响应 headers 中的用量信息
                if k.get("type") == "anthropic_compat":
                    anthropic_quota = _get_anthropic_quota_headers(name)
                    if anthropic_quota:
                        # 合并到 quota 中，或单独作为一个字段
                        if "quota" not in entry:
                            entry["quota"] = {"provider": k.get("provider", name), "quotas": []}
                        # 添加 headers 来源的用量信息
                        entry["quota"]["headers_quotas"] = anthropic_quota.get("quotas", [])
                        entry["quota"]["headers_source"] = anthropic_quota.get("source", "response_headers")

                key_status.append(entry)

            fallback_cfg = _config.get("fallback", {})
            self._send(200, {
                "version": "3.0",
                "keys": key_status,
                "fallback_enabled": fallback_cfg.get("enabled", True),
                "fallback_url": fallback_cfg.get("vllm_url", ""),
                "available_keys": sum(1 for ks in key_status if ks["available"]),
                "total_keys": len(key_status),
                "concurrency_per_priority": _config.get("concurrency_per_priority", CONCURRENCY_PER_PRIORITY),
                "request_deadline_secs": REQUEST_DEADLINE_SECS,
                "uptime_since": _start_time.isoformat() if _start_time else None,
            })
            return

        if self.path in ("/v1/models", "/models"):
            models = _config.get("upstream", {}).get("default_models", {})
            self._send(200, {
                "object": "list",
                "data": [{"id": v, "object": "model"} for v in models.values()],
            })
            return

        self._send(404, {"error": f"Unknown path: {self.path}"})

    def do_POST(self):
        if "/messages" not in self.path:
            self._send(404, {"error": f"Unknown path: {self.path}"})
            return

        # 读取请求体
        content_length = int(self.headers.get("Content-Length", 0))
        body_bytes = self.rfile.read(content_length)

        try:
            body_dict = json.loads(body_bytes)
        except json.JSONDecodeError as e:
            self._send(400, {"error": f"Invalid JSON: {e}"})
            return

        model_requested = body_dict.get("model", "unknown")

        # 记录请求开始时间（用于计算latency）
        request_start_time = time.monotonic()

        # === deadline-driven 重试循环 ===
        deadline = time.monotonic() + REQUEST_DEADLINE_SECS
        groups = _get_keys_by_priority()
        sorted_priorities = sorted(groups.keys())
        backoff_count = 0
        last_error_status = 500
        last_error_body = b'{"error": {"message": "No available keys"}}'
        last_key_used = None  # 记录最后使用的key，用于失败上报

        for priority in sorted_priorities:
            if time.monotonic() >= deadline:
                break

            # 检查该优先级是否有可用key
            available_in_priority = [k for k in groups[priority] if _is_key_available(k["name"])]
            if not available_in_priority:
                logger.info(f"[路由] priority={priority} 无可用Key，尝试下一优先级")
                continue

            # 获取该优先级的信号量
            sem = _semaphores.get(priority)

            skip_keys = set()
            consecutive_rate_limits = 0

            while time.monotonic() < deadline:
                key = get_next_key_in_priority(priority, skip_keys)
                if key is None:
                    # 该优先级所有key都已尝试或不可用
                    if consecutive_rate_limits > 0:
                        # 所有key都是速率限制，backoff后重置skip_keys再来一轮
                        backoff_count += 1
                        delay = min(BACKOFF_BASE_SECS * (2 ** (backoff_count - 1)), BACKOFF_CAP_SECS)
                        jitter = delay * BACKOFF_JITTER * (2 * random.random() - 1)
                        sleep_time = max(0.5, delay + jitter)

                        if time.monotonic() + sleep_time >= deadline:
                            logger.warning(
                                f"[路由] priority={priority} 所有Key速率限制, "
                                f"backoff {sleep_time:.1f}s 将超过deadline, 尝试下一优先级"
                            )
                            break

                        logger.info(
                            f"[路由] priority={priority} 所有Key速率限制, "
                            f"backoff {sleep_time:.1f}s (第{backoff_count}次)"
                        )
                        time.sleep(sleep_time)
                        skip_keys.clear()
                        consecutive_rate_limits = 0
                        continue
                    else:
                        # 非速率限制原因用完了，降级
                        break

                key_name = key["name"]
                key_type = key.get("type", "zhipu")
                last_key_used = key  # 记录当前使用的key，用于上报

                # 并发信号量控制
                acquired = False
                if sem:
                    acquired = sem.acquire(timeout=max(0.1, deadline - time.monotonic()))
                    if not acquired:
                        logger.warning(f"[{key_name}] 并发信号量获取超时，尝试下一个Key")
                        skip_keys.add(key_name)
                        continue
                else:
                    acquired = True

                try:
                    logger.info(
                        f"[{key_name}] → {key_type}转发 provider={key.get('provider', '?')} model={model_requested} "
                        f"priority={priority} elapsed={REQUEST_DEADLINE_SECS - (deadline - time.monotonic()):.1f}s"
                    )

                    status, resp_body, is_dict_resp = _call_upstream(key, body_bytes, body_dict, self.path)

                    # === 成功 ===
                    if status == 200:
                        # 计算请求耗时
                        latency_ms = int((time.monotonic() - request_start_time) * 1000)

                        # 解析token用量
                        resp_bytes = resp_body if not is_dict_resp else json.dumps(resp_body).encode()
                        prompt_tokens, completion_tokens = _parse_usage_from_response(resp_bytes, key_type)

                        # 异步上报用量
                        _report_usage_async(
                            key_name=key_name,
                            model=model_requested,
                            prompt_tokens=prompt_tokens,
                            completion_tokens=completion_tokens,
                            latency_ms=latency_ms,
                            status_code=200,
                            error_msg=None,
                        )

                        if is_dict_resp:
                            self._send(200, resp_body)  # dict
                        else:
                            self._send(200, resp_body)  # bytes
                        return

                    # === 失败: 分类错误 ===
                    error_body_for_classify = resp_body if not is_dict_resp else json.dumps(resp_body).encode() if resp_body else b"{}"
                    err_type, err_code, flush_time, raw_msg = classify_error(key, status, error_body_for_classify)

                    record_key_error(key_name)
                    last_error_status = status
                    last_error_body = error_body_for_classify if not is_dict_resp else json.dumps(resp_body).encode() if resp_body else b"{}"

                    # 详细日志
                    action_map = {
                        ErrorType.RATE_LIMIT: "换Key重试",
                        ErrorType.PLATFORM_OVERLOAD: "backoff等待",
                        ErrorType.QUOTA_EXHAUSTED: "标记冷却+降级",
                        ErrorType.BALANCE_EXHAUSTED: "长期冷却+降级",
                        ErrorType.UNRECOVERABLE: "透传给CC",
                    }
                    logger.warning(
                        f"[{key_name}] 错误 | type={key_type} | HTTP {status} | "
                        f"分类={err_type.value} | 错误码={err_code} | "
                        f"动作={action_map.get(err_type, '未知')} | "
                        f"原始消息={raw_msg[:300]}"
                    )

                    if err_type == ErrorType.RATE_LIMIT:
                        # 换同优先级下一个key，不冷却、不降级
                        logger.info(f"  → 换同优先级下一个Key (skip {key_name})")
                        skip_keys.add(key_name)
                        consecutive_rate_limits += 1
                        continue

                    elif err_type == ErrorType.PLATFORM_OVERLOAD:
                        # 平台过载，换key也没用，直接backoff
                        logger.info(f"  → 平台过载, backoff等待")
                        backoff_count += 1
                        delay = min(BACKOFF_BASE_SECS * (2 ** (backoff_count - 1)), BACKOFF_CAP_SECS)
                        jitter = delay * BACKOFF_JITTER * (2 * random.random() - 1)
                        sleep_time = max(0.5, delay + jitter)
                        if time.monotonic() + sleep_time < deadline:
                            time.sleep(sleep_time)
                        continue

                    elif err_type == ErrorType.QUOTA_EXHAUSTED:
                        # 限额耗尽，标记冷却，该key在本次和后续请求中都不再使用
                        logger.info(f"  → 限额耗尽, 标记冷却, 尝试同优先级其他Key或降级")
                        _mark_key_cooldown(key_name, err_type, err_code, flush_time, raw_msg)
                        skip_keys.add(key_name)
                        # 清除之前因速率限制被 skip 但未被冷却的 key，它们可能已经恢复
                        # 只保留真正在冷却中的 key
                        cooled_keys = {k["name"] for k in _get_enabled_keys() if not _is_key_available(k["name"])}
                        skip_keys = skip_keys & cooled_keys
                        consecutive_rate_limits = 0
                        logger.info(f"  → 清除速率限制skip, 保留冷却key: {skip_keys}")
                        continue

                    elif err_type == ErrorType.BALANCE_EXHAUSTED:
                        logger.info(f"  → 余额耗尽, 长期冷却, 降级")
                        _mark_key_cooldown(key_name, err_type, err_code, None, raw_msg)
                        skip_keys.add(key_name)
                        # 同上，清除因速率限制被 skip 但未被冷却的 key
                        cooled_keys = {k["name"] for k in _get_enabled_keys() if not _is_key_available(k["name"])}
                        skip_keys = skip_keys & cooled_keys
                        consecutive_rate_limits = 0
                        logger.info(f"  → 清除速率限制skip, 保留冷却key: {skip_keys}")
                        continue

                    elif err_type == ErrorType.UNRECOVERABLE:
                        # 不可恢复，直接透传给CC
                        logger.warning(f"  → 不可恢复错误, 直接透传给CC")

                        # 上报失败用量
                        latency_ms = int((time.monotonic() - request_start_time) * 1000)
                        _report_usage_async(
                            key_name=key_name,
                            model=model_requested,
                            prompt_tokens=0,
                            completion_tokens=0,
                            latency_ms=latency_ms,
                            status_code=status,
                            error_msg=raw_msg[:500],
                        )

                        if is_dict_resp and resp_body:
                            self._send(status, resp_body)
                        else:
                            self._send(status, error_body_for_classify)
                        return

                finally:
                    if sem and acquired:
                        sem.release()

        # === 所有优先级都尝试完了，尝试本地vLLM保底 ===
        fallback_cfg = _config.get("fallback", {})
        if fallback_cfg.get("enabled", True):
            logger.warning(f"[路由] 所有Key不可用，降级到本地vLLM保底")
            vllm_start_time = time.monotonic()
            status, resp = call_local_vllm(body_dict)

            # 上报vLLM用量
            vllm_latency_ms = int((time.monotonic() - vllm_start_time) * 1000)
            vllm_prompt_tokens, vllm_completion_tokens = _parse_usage_from_response(resp, "openai_compat")
            _report_usage_async(
                key_name="local_vllm",
                model=model_requested,
                prompt_tokens=vllm_prompt_tokens,
                completion_tokens=vllm_completion_tokens,
                latency_ms=vllm_latency_ms,
                status_code=status,
                error_msg=None if status == 200 else "vLLM fallback failed",
            )

            self._send(status, resp)
            return

        # === 真的全部失败，透传最后一次错误 ===
        elapsed = REQUEST_DEADLINE_SECS - (deadline - time.monotonic())
        logger.error(
            f"[路由] 全部失败 | 耗时={elapsed:.1f}s | "
            f"最后错误=HTTP {last_error_status}"
        )

        # 上报最终失败
        if last_key_used:
            latency_ms = int((time.monotonic() - request_start_time) * 1000)
            _report_usage_async(
                key_name=last_key_used["name"],
                model=model_requested,
                prompt_tokens=0,
                completion_tokens=0,
                latency_ms=latency_ms,
                status_code=last_error_status,
                error_msg=f"All retries failed, last error: HTTP {last_error_status}",
            )

        self._send(last_error_status, last_error_body)


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


# ===================== 启动 =====================

def main():
    global _start_time
    _start_time = _now()

    _load_config()
    _load_state()

    server = ThreadedHTTPServer(("0.0.0.0", PORT), ProxyHandler)
    logger.info(f"Token Pool Proxy v3 启动 | 端口: {PORT} | deadline: {REQUEST_DEADLINE_SECS}s")
    logger.info(f"优先级分组: {', '.join(f'P{p}={len(keys)}个Key' for p, keys in sorted(_get_keys_by_priority().items()))}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("收到中断信号，关闭服务...")
        server.shutdown()


# ===================== 命令行用量查询 =====================

def cli_query_quota(key_name=None, provider=None):
    """命令行查询用量信息

    用法：
        python3 token_pool_proxy.py --quota              # 查询所有启用 Key 的用量
        python3 token_pool_proxy.py --quota kimi         # 查询指定 Key 的用量
        python3 token_pool_proxy.py --quota-provider kimi # 查询指定 provider 的所有 Key
    """
    _load_config()
    _load_state()

    keys = _get_enabled_keys()
    if not keys:
        print("没有启用的 Key")
        return

    if key_name:
        # 查询指定 Key
        target_keys = [k for k in keys if k["name"] == key_name]
        if not target_keys:
            print(f"未找到 Key: {key_name}")
            return
        keys = target_keys

    if provider:
        # 查询指定 provider 的所有 Key
        keys = [k for k in keys if k.get("provider") == provider]
        if not keys:
            print(f"未找到 Provider: {provider}")
            return

    print(f"\n{'='*60}")
    print(f"用量查询结果")
    print(f"{'='*60}\n")

    for key_cfg in keys:
        key_name = key_cfg["name"]
        key_provider = key_cfg.get("provider", "unknown")
        print(f"Key: {key_name} (provider: {key_provider}, priority: {key_cfg.get('priority', 1)})")

        result = query_provider_quota(key_cfg)
        if result:
            print(f"  套餐：{result.get('plan', 'unknown')}")
            quotas = result.get("quotas", [])
            if quotas:
                for q in quotas:
                    window = q.get("window", "unknown")
                    total = q.get("total")
                    used = q.get("used")
                    remaining = q.get("remaining")
                    used_pct = q.get("used_pct", 0)
                    # 格式化输出
                    total_str = f"{total:,}" if isinstance(total, int) else str(total)
                    remaining_str = f"{remaining:,}" if isinstance(remaining, int) else str(remaining)
                    if total is not None and remaining is not None:
                        print(f"  [{window}] 总额：{total_str}, 剩余：{remaining_str} ({100-used_pct:.0f}% 可用)")
                    elif used_pct is not None:
                        print(f"  [{window}] 已使用：{used_pct:.0f}%")
                    else:
                        print(f"  [{window}] 用量数据不可用")
            else:
                print("  无用量数据")
        else:
            # 根据 provider 给出更明确的提示
            if key_provider == "kimi":
                print("  提示：Kimi coding plan 暂无公开用量查询 API")
                print("        请登录 Kimi 控制台查看：https://platform.moonshot.cn/console/billing")
            elif key_provider == "infini":
                print("  提示：无问星穹暂不支持用量查询 API")
            elif key_provider == "volcengine":
                print("  提示：火山方舟暂不支持用量查询 API")
            else:
                print("  查询失败或未支持")

        print()

    print(f"{'='*60}")


if __name__ == "__main__":
    import sys

    # 检查命令行参数
    if len(sys.argv) > 1:
        if sys.argv[1] == "--quota" or sys.argv[1] == "-q":
            # 查询指定 Key 或所有 Key
            key_name = sys.argv[2] if len(sys.argv) > 2 else None
            cli_query_quota(key_name=key_name)
            exit(0)
        elif sys.argv[1] == "--quota-provider" or sys.argv[1] == "-qp":
            # 查询指定 provider
            provider = sys.argv[2] if len(sys.argv) > 2 else None
            if not provider:
                print("用法：python3 token_pool_proxy.py --quota-provider <provider>")
                exit(1)
            cli_query_quota(provider=provider)
            exit(0)
        elif sys.argv[1] == "--help" or sys.argv[1] == "-h":
            print("""
Token Pool Proxy v3 - 用量查询

用法:
    python3 token_pool_proxy.py                 # 启动代理服务
    python3 token_pool_proxy.py --quota         # 查询所有启用 Key 的用量
    python3 token_pool_proxy.py --quota <name>  # 查询指定 Key 的用量
    python3 token_pool_proxy.py --quota-provider <provider>  # 查询指定 provider 的所有 Key

示例:
    python3 token_pool_proxy.py --quota kimi            # 查询 kimi Key 用量
    python3 token_pool_proxy.py --quota-provider kimi   # 查询所有 kimi provider 的 Key
    python3 token_pool_proxy.py --quota-provider zhipu  # 查询所有 zhipu provider 的 Key
""")
            exit(0)

    # 默认启动服务
    main()

