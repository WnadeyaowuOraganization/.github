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
            cooldown_until = now + timedelta(hours=24)
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


def classify_zhipu_direct(status_code, resp_body):
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

    # 限额耗尽（含 quota/exceeded 关键词）
    if err_type == "rate_limit_error" and any(kw in message_lower for kw in ("quota", "exceeded", "limit reached")):
        return ErrorType.QUOTA_EXHAUSTED, err_type, None, message

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


def classify_error(key_cfg, status_code, resp_body):
    """根据 provider 分派到对应的错误分类函数

    Returns: (ErrorType, error_code, cooldown_until_iso, raw_message)
    """
    provider = key_cfg.get("provider", "")

    if provider == "zhipu":
        return classify_zhipu_direct(status_code, resp_body)
    else:
        # 其他供应商统一使用 anthropic_compat 错误分类
        return classify_anthropic_compat(status_code, resp_body)


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

# 缓存: {key_name: {"data": {...}, "fetched_at": iso_str}}
_quota_cache = {}
_QUOTA_CACHE_TTL_SECS = 60  # 缓存 60s，避免频繁调用上游


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
                "remaining_pct": percentage,
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


def query_key_quota(key_cfg):
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
    else:
        # 其他供应商暂无量子查询接口
        result = None

    # 更新缓存
    _quota_cache[key_name] = {"data": result, "_mono": now}
    return result


def call_anthropic_compat(body_bytes, api_key, path="/v1/messages", base_url=None, model_map=None):
    """调用Anthropic兼容供应商（智谱直连、Kimi、无问星穹、火山等）"""
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
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        err_body = e.read() if e.fp else b"{}"
        return e.code, err_body
    except Exception as e:
        error_resp = json.dumps({"type": "error", "error": {"type": "proxy_error", "message": str(e)}}).encode()
        return 502, error_resp


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

    # 应用 key 配置中的环境变量（仅对本次请求有效）
    env_cfg = key_cfg.get("env", {})
    old_env = _apply_env(env_cfg)

    try:
        if key_type == "anthropic_compat":
            base_url = key_cfg.get("api_url", "")
            model_map = key_cfg.get("model_map")
            status, resp_body = call_anthropic_compat(body_bytes, api_key, path, base_url, model_map)
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
                quota = query_key_quota(k)
                if quota:
                    entry["quota"] = quota

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

        # === deadline-driven 重试循环 ===
        deadline = time.monotonic() + REQUEST_DEADLINE_SECS
        groups = _get_keys_by_priority()
        sorted_priorities = sorted(groups.keys())
        backoff_count = 0
        last_error_status = 500
        last_error_body = b'{"error": {"message": "No available keys"}}'

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
            status, resp = call_local_vllm(body_dict)
            self._send(status, resp)
            return

        # === 真的全部失败，透传最后一次错误 ===
        elapsed = REQUEST_DEADLINE_SECS - (deadline - time.monotonic())
        logger.error(
            f"[路由] 全部失败 | 耗时={elapsed:.1f}s | "
            f"最后错误=HTTP {last_error_status}"
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


if __name__ == "__main__":
    main()
