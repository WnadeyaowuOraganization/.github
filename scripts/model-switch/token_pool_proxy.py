#!/usr/bin/env python3
"""
Token Pool Proxy — 多源Key自动切换代理 v2
==========================================
监听 0.0.0.0:9855，提供 Anthropic Messages API 兼容端点
CC(Claude Code) 通过 ANTHROPIC_BASE_URL=http://localhost:9855 连接

支持两种上游类型:
  - zhipu: 智谱Coding Plan直连 (Anthropic Messages API格式)
  - openai_compat: New API兼容中转站如aiopus (OpenAI格式，自动做Anthropic↔OpenAI转换)

优先级链: 智谱直连Key → 中转站Key → 本地vLLM保底

功能:
  1. 维护多源Key池，按优先级+轮询分配
  2. 检测限额错误(1302/429/余额不足)自动切换到下一个Key重试
  3. 所有Key耗尽时降级到本地vLLM(Qwen3.5-122B), 做Anthropic↔OpenAI格式转换
  4. Key冷却状态持久化，进程重启不丢失
  5. GET /status 查看所有Key状态

部署: systemd token-pool-proxy.service
配置: keys.json (同目录)
"""

import json
import time
import os
import sys
import logging
import hashlib
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

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [TokenPool] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(SCRIPT_DIR, "proxy.log"), encoding="utf-8"),
    ],
)
logger = logging.getLogger(__name__)

# ===================== Key池管理 =====================

_lock = threading.Lock()
_config = {}
_pool_state = {}  # {key_name: {"cooldown_until": iso_str, "type": "rate"|"weekly"|"balance", "error_timestamps": [iso_str]}}
_round_robin_index = 0
_stats = {}  # {key_name: {"requests": int, "errors": int, "last_used": iso_str}}

# 冷却升级的时间窗口(秒): 只统计最近WINDOW秒内的错误次数
_COOLDOWN_WINDOW_SECS = 300  # 5分钟窗口


def _now():
    return datetime.now(CST)


def _load_config():
    global _config
    with open(KEYS_FILE, "r") as f:
        _config = json.load(f)
    enabled = [k for k in _config["keys"] if k["enabled"]]
    zhipu_direct = [k for k in enabled if k.get("type", "zhipu") == "zhipu" and not k.get("api_url")]
    zhipu_proxy = [k for k in enabled if k.get("type", "zhipu") == "zhipu" and k.get("api_url")]
    pool_keys = [k for k in enabled if k.get("type") == "openai_compat"]
    logger.info(f"配置加载: {len(enabled)} 个启用Key (智谱直连:{len(zhipu_direct)}, 中转站(Anthropic):{len(zhipu_proxy)}, 中转站(OpenAI):{len(pool_keys)})")


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
    """按优先级分组返回Key列表: 先智谱直连，再中转站"""
    enabled = _get_enabled_keys()
    zhipu_keys = [k for k in enabled if k.get("type", "zhipu") == "zhipu"]
    pool_keys = [k for k in enabled if k.get("type") == "openai_compat"]
    return zhipu_keys + pool_keys


def _is_key_available(key_name):
    """检查Key是否可用(未在冷却中)"""
    state = _pool_state.get(key_name, {})
    cooldown_until = state.get("cooldown_until")
    if not cooldown_until:
        return True
    try:
        until = datetime.fromisoformat(cooldown_until)
        if _now() >= until:
            # 冷却结束，清除状态
            if key_name in _pool_state:
                logger.info(f"[{key_name}] 冷却结束，恢复可用")
                del _pool_state[key_name]
                _save_state()
            return True
        return False
    except Exception:
        return True


def _mark_key_cooldown(key_name, cooldown_type="rate"):
    """标记Key进入冷却，打印详细冷却信息

    升级逻辑基于时间窗口内的错误次数(非简单累计):
    - 5分钟窗口内错误<=2次: 普通速率冷却(默认1h)
    - 5分钟窗口内错误>=3次: 升级为较长冷却(默认4h)
    - 余额/认证类错误: 长期冷却(默认24h)
    """
    with _lock:
        state = _pool_state.get(key_name, {})
        now = _now()

        # 维护时间窗口内的错误时间戳列表
        error_ts = state.get("error_timestamps", [])
        error_ts.append(now.isoformat())
        # 只保留最近窗口内的记录
        window_start = now - timedelta(seconds=_COOLDOWN_WINDOW_SECS)
        error_ts = [t for t in error_ts if datetime.fromisoformat(t) >= window_start]
        state["error_timestamps"] = error_ts
        recent_count = len(error_ts)

        cooldown_cfg = _config.get("cooldown", {})

        # 统计池中可用Key数
        all_keys = _get_enabled_keys()
        available_count = sum(1 for k in all_keys if _is_key_available(k["name"]) and k["name"] != key_name)

        if cooldown_type == "balance":
            # 余额不足/认证失败 → 长期冷却(默认24h，非30天)
            hours = cooldown_cfg.get("balance_exhausted_hours", 24)
            state["type"] = "balance"
            cooldown_until = now + timedelta(hours=hours)
            logger.warning(f"[{key_name}] 冷却标记: 余额/认证问题 → {hours}h冷却 (至 {cooldown_until.strftime('%m-%d %H:%M')}) | 窗口内{recent_count}次错误 | 剩余可用Key: {available_count}")
        elif recent_count >= 5:
            # 窗口内频繁触发 → 较长冷却(默认4h)
            hours = cooldown_cfg.get("weekly_limit_hours", 4)
            state["type"] = "escalated"
            cooldown_until = now + timedelta(hours=hours)
            logger.warning(f"[{key_name}] 冷却标记: 高频触发(5min内{recent_count}次) → {hours}h冷却 (至 {cooldown_until.strftime('%m-%d %H:%M')}) | 剩余可用Key: {available_count}")
        else:
            # 普通速率限制 → 短冷却(默认1h)
            hours = cooldown_cfg.get("rate_limit_hours", 1)
            state["type"] = "rate"
            cooldown_until = now + timedelta(hours=hours)
            logger.warning(f"[{key_name}] 冷却标记: 速率限制 → {hours}h冷却 (至 {cooldown_until.strftime('%m-%d %H:%M')}) | 窗口内{recent_count}次错误 | 剩余可用Key: {available_count}")

        state["cooldown_until"] = cooldown_until.isoformat()
        state["marked_at"] = now.isoformat()
        _pool_state[key_name] = state
        _save_state()


def get_next_key():
    """获取下一个可用Key (按优先级: 智谱直连 → 中转站, 同类内轮询)"""
    global _round_robin_index
    keys = _get_keys_by_priority()
    if not keys:
        return None

    with _lock:
        # 先尝试找任意可用Key (保持优先级)
        for key in keys:
            if _is_key_available(key["name"]):
                name = key["name"]
                if name not in _stats:
                    _stats[name] = {"requests": 0, "errors": 0}
                _stats[name]["requests"] += 1
                _stats[name]["last_used"] = _now().isoformat()
                return key

    return None  # 所有Key都在冷却


def record_key_error(key_name):
    with _lock:
        if key_name not in _stats:
            _stats[key_name] = {"requests": 0, "errors": 0}
        _stats[key_name]["errors"] += 1


# ===================== Anthropic ↔ OpenAI 格式转换 =====================

def anthropic_to_openai(anthropic_body, model_override=None):
    """将Anthropic Messages API请求转换为OpenAI Chat Completions格式"""
    messages = []

    # system字段 → system message
    system = anthropic_body.get("system")
    if system:
        if isinstance(system, str):
            messages.append({"role": "system", "content": system})
        elif isinstance(system, list):
            text = " ".join(b.get("text", "") for b in system if b.get("type") == "text")
            if text:
                messages.append({"role": "system", "content": text})

    # messages转换
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

    openai_body = {
        "model": model,
        "messages": messages,
        "max_tokens": anthropic_body.get("max_tokens", 4096),
        "temperature": anthropic_body.get("temperature", 0.7),
        "stream": False,
    }

    return openai_body


def openai_to_anthropic(openai_resp, requested_model="qwen3.5-122b-local"):
    """将OpenAI Chat Completions响应转换为Anthropic Messages API格式"""
    choice = openai_resp.get("choices", [{}])[0]
    content_text = choice.get("message", {}).get("content", "")
    usage = openai_resp.get("usage", {})

    # 清洗思维链泄漏
    if "<think>" in content_text:
        import re
        content_text = re.sub(r'<think>.*?</think>', '', content_text, flags=re.DOTALL).strip()

    anthropic_resp = {
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

    return anthropic_resp


# ===================== 模型映射 =====================

def _resolve_model_for_pool(key_cfg, requested_model):
    """根据CC请求的模型名，映射到中转站实际使用的模型名"""
    model_map = key_cfg.get("model_map", {})
    if model_map and requested_model in model_map:
        return model_map[requested_model]
    # 默认使用key配置中的model字段
    return key_cfg.get("model", requested_model)


# ===================== 上游调用 =====================

def call_zhipu(body_bytes, api_key, path="/v1/messages", base_url_override=None, model_map=None):
    """转发请求到Anthropic Messages格式端点(智谱直连或中转站)"""
    base_url = base_url_override or _config.get("upstream", {}).get("base_url", "https://open.bigmodel.cn/api/anthropic")
    url = f"{base_url}{path}"

    # 模型名重写 (中转站可能不支持某些模型名)
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
            resp_body = resp.read()
            return resp.status, resp.headers, resp_body
    except urllib.error.HTTPError as e:
        err_body = e.read() if e.fp else b"{}"
        return e.code, e.headers, err_body
    except Exception as e:
        error_resp = json.dumps({"type": "error", "error": {"type": "proxy_error", "message": str(e)}}).encode()
        return 502, {}, error_resp


def call_openai_compat(anthropic_body, key_cfg):
    """调用OpenAI兼容中转站(如aiopus)，做Anthropic→OpenAI→Anthropic格式转换"""
    api_url = key_cfg.get("api_url", "")
    api_key = key_cfg.get("api_key", "")
    requested_model = anthropic_body.get("model", "unknown")
    target_model = _resolve_model_for_pool(key_cfg, requested_model)

    # 构建完整URL
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
        url,
        data=json.dumps(openai_body).encode(),
        headers=headers,
        method="POST",
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


def _parse_error_detail(status_code, resp_body):
    """从响应体中提取错误详情用于日志"""
    try:
        data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
        if not isinstance(data, dict):
            return f"HTTP {status_code}, non-dict body"
        error = data.get("error", {})
        if isinstance(error, dict):
            code = error.get("code", "")
            err_type = error.get("type", "")
            message = error.get("message", "")
            parts = [f"HTTP {status_code}"]
            if code:
                parts.append(f"code={code}")
            if err_type:
                parts.append(f"type={err_type}")
            if message:
                # 截断过长的message
                display_msg = message[:200] + "..." if len(message) > 200 else message
                parts.append(f"msg={display_msg}")
            return ", ".join(parts)
        # 顶层code
        top_code = data.get("code", "")
        top_msg = data.get("message", "")
        if top_code or top_msg:
            return f"HTTP {status_code}, top-level code={top_code}, msg={top_msg[:200]}"
        return f"HTTP {status_code}, body={json.dumps(data, ensure_ascii=False)[:300]}"
    except Exception as e:
        return f"HTTP {status_code}, parse error: {e}"


def is_rate_limit_error(status_code, resp_body):
    """判断是否为速率限制(可重试，短暂sleep即可)，命中时打印详细日志"""
    # 智谱: 429 + code=1302 + message含"速率限制"/"请求频率" → 速率限制
    try:
        data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
        if isinstance(data, dict):
            # 检查error.code
            error = data.get("error", {})
            if isinstance(error, dict):
                code = str(error.get("code", ""))
                message = error.get("message", "").lower()
                if code == "1302" and ("速率限制" in message or "请求频率" in message or "rate" in message):
                    detail = _parse_error_detail(status_code, resp_body)
                    logger.warning(f"[速率限制检测] 命中: 智谱1302(速率限制) | 详情: {detail}")
                    return True
            # 检查顶层code
            top_code = str(data.get("code", ""))
            top_msg = str(data.get("message", "")).lower()
            if top_code == "1302" and ("速率限制" in top_msg or "请求频率" in top_msg or "rate" in top_msg):
                detail = _parse_error_detail(status_code, resp_body)
                logger.warning(f"[速率限制检测] 命中: 顶层1302(速率限制) | 详情: {detail}")
                return True
            # OpenAI格式: error.type=rate_limit_error 且消息不含quota/exceeded
            if isinstance(error, dict):
                err_type = error.get("type", "")
                message = error.get("message", "").lower()
                if err_type == "rate_limit_error" and "quota" not in message and "exceeded" not in message:
                    detail = _parse_error_detail(status_code, resp_body)
                    logger.warning(f"[速率限制检测] 命中: rate_limit_error | 详情: {detail}")
                    return True
    except Exception:
        pass

    return False


def is_quota_error(status_code, resp_body):
    """判断是否为真实限额/配额耗尽(需冷却切换Key)，命中时打印详细日志"""
    # 先排除速率限制
    if is_rate_limit_error(status_code, resp_body):
        return False

    matched_reason = None

    if status_code == 429:
        matched_reason = "HTTP 429(非速率限制)"

    if not matched_reason:
        try:
            data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
            if isinstance(data, dict):
                error = data.get("error", {})
                if isinstance(error, dict):
                    code = str(error.get("code", ""))
                    err_type = error.get("type", "")
                    message = error.get("message", "").lower()
                    if code == "1302" and ("速率限制" not in message and "请求频率" not in message):
                        matched_reason = "智谱错误码1302(非速率限制)"
                    elif any(kw in message for kw in ["quota", "exceeded", "limit reached"]):
                        matched_reason = "错误消息含限额关键词"
                    elif err_type == "rate_limit_error" and ("quota" in message or "exceeded" in message):
                        matched_reason = "error.type=rate_limit_error(含限额关键词)"

                if not matched_reason and str(data.get("code", "")) == "1302":
                    top_msg = str(data.get("message", "")).lower()
                    if "速率限制" not in top_msg and "请求频率" not in top_msg:
                        matched_reason = "顶层code=1302(非速率限制)"
        except Exception:
            pass

    if matched_reason:
        detail = _parse_error_detail(status_code, resp_body)
        logger.warning(f"[限额检测] 命中: {matched_reason} | 详情: {detail}")
        return True

    return False


def is_balance_error(status_code, resp_body):
    """判断是否为余额不足错误(主要针对中转站)，命中时打印详细日志"""
    matched_reason = None

    if status_code == 402:
        matched_reason = "HTTP 402"

    if not matched_reason:
        try:
            data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
            if isinstance(data, dict):
                error = data.get("error", {})
                if isinstance(error, dict):
                    message = error.get("message", "").lower()
                    matched_kw = next((kw for kw in ["insufficient", "balance", "余额", "额度不足", "credit"] if kw in message), None)
                    if matched_kw:
                        matched_reason = f"错误消息含余额关键词'{matched_kw}'"
        except Exception:
            pass

    if matched_reason:
        detail = _parse_error_detail(status_code, resp_body)
        logger.warning(f"[余额检测] 命中: {matched_reason} | 详情: {detail}")
        return True

    return False


def is_auth_error(status_code, resp_body):
    """判断是否为认证错误(Key无效/过期)，命中时打印详细日志"""
    matched_reason = None

    if status_code in (401, 403):
        matched_reason = f"HTTP {status_code}"

    if not matched_reason:
        try:
            data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
            if isinstance(data, dict):
                error = data.get("error", {})
                if isinstance(error, dict):
                    code = str(error.get("code", "") or error.get("type", ""))
                    message = error.get("message", "").lower()
                    if code in ("1000", "1001", "invalid_api_key", "authentication_error"):
                        matched_reason = f"错误码={code}"
                    elif any(kw in message for kw in ["身份验证", "认证失败", "invalid", "unauthorized", "authentication"]):
                        matched_reason = "错误消息含认证关键词"

                if not matched_reason and str(data.get("code", "")) in ("1000", "1001"):
                    matched_reason = f"顶层code={data.get('code')}"
        except Exception:
            pass

    if matched_reason:
        detail = _parse_error_detail(status_code, resp_body)
        logger.warning(f"[认证检测] 命中: {matched_reason} | 详情: {detail}")
        return True

    return False


# ===================== HTTP Handler =====================

class ProxyHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass  # 用logger代替默认stderr输出

    def _send(self, status, body, content_type="application/json"):
        if isinstance(body, dict):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, str):
            body = body.encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"status": "ok", "service": "TokenPoolProxy", "port": PORT, "version": "2.0"})
            return

        if self.path == "/status":
            keys = _get_enabled_keys()
            key_status = []
            for k in keys:
                name = k["name"]
                available = _is_key_available(name)
                state = _pool_state.get(name, {})
                stats = _stats.get(name, {"requests": 0, "errors": 0})
                # 计算当前窗口内的错误数
                error_ts = state.get("error_timestamps", [])
                now = _now()
                window_start = now - timedelta(seconds=_COOLDOWN_WINDOW_SECS)
                recent_errors = sum(1 for t in error_ts if datetime.fromisoformat(t) >= window_start)
                key_status.append({
                    "name": name,
                    "type": k.get("type", "zhipu"),
                    "available": available,
                    "requests": stats["requests"],
                    "errors": stats["errors"],
                    "cooldown_type": state.get("type"),
                    "cooldown_until": state.get("cooldown_until"),
                    "recent_errors_5min": recent_errors,
                })

            fallback_cfg = _config.get("fallback", {})
            self._send(200, {
                "version": "2.0",
                "keys": key_status,
                "fallback_enabled": fallback_cfg.get("enabled", True),
                "fallback_url": fallback_cfg.get("vllm_url", ""),
                "available_keys": sum(1 for ks in key_status if ks["available"]),
                "total_keys": len(key_status),
                "uptime_since": _start_time.isoformat(),
            })
            return

        # 兼容 /v1/models 请求
        if self.path in ("/v1/models", "/models"):
            models = _config.get("upstream", {}).get("default_models", {})
            self._send(200, {
                "object": "list",
                "data": [{"id": v, "object": "model"} for v in models.values()],
            })
            return

        self._send(404, {"error": f"Unknown path: {self.path}"})

    def do_POST(self):
        # 接受所有包含 /messages 的路径 (Claude Code可能发 /v1/messages)
        if "/messages" not in self.path:
            self._send(404, {"error": f"Unknown path: {self.path}"})
            return

        # 读取请求体
        content_length = int(self.headers.get("Content-Length", 0))
        body_bytes = self.rfile.read(content_length)

        try:
            body = json.loads(body_bytes)
        except json.JSONDecodeError as e:
            self._send(400, {"error": f"Invalid JSON: {e}"})
            return

        model_requested = body.get("model", "unknown")

        # === 尝试Key池 (按优先级: 智谱直连 → 中转站) ===
        keys = _get_keys_by_priority()
        tried_keys = set()

        rate_limit_retries = 0
        MAX_RATE_LIMIT_RETRIES = 3

        for attempt in range(len(keys) + MAX_RATE_LIMIT_RETRIES):
            key = get_next_key()
            if key is None:
                break  # 所有Key都在冷却

            key_name = key["name"]
            if key_name in tried_keys:
                break  # 已经轮了一圈
            tried_keys.add(key_name)

            key_type = key.get("type", "zhipu")

            if key_type == "openai_compat":
                # === 中转站Key (OpenAI格式) ===
                logger.info(f"[{key_name}] → 中转站转发 {model_requested} → {_resolve_model_for_pool(key, model_requested)} (attempt {attempt + 1})")

                status, anthropic_resp, err_body = call_openai_compat(body, key)

                if status == 200 and anthropic_resp:
                    with _lock:
                        if key_name in _pool_state:
                            _pool_state[key_name]["consecutive_hits"] = 0
                    self._send(200, anthropic_resp)
                    return

                # 检查错误类型
                if err_body and is_auth_error(status, err_body):
                    logger.warning(f"[{key_name}] 中转站认证错误(HTTP {status})，可能是临时问题，短冷却后重试")
                    record_key_error(key_name)
                    _mark_key_cooldown(key_name, "rate")  # 中转站认证错误用短冷却，避免误判
                    continue

                if err_body and is_balance_error(status, err_body):
                    logger.warning(f"[{key_name}] 余额不足，长期冷却")
                    record_key_error(key_name)
                    _mark_key_cooldown(key_name, "balance")
                    continue

                if err_body and is_rate_limit_error(status, err_body):
                    rate_limit_retries += 1
                    if rate_limit_retries <= MAX_RATE_LIMIT_RETRIES:
                        logger.info(f"[{key_name}] 速率限制，sleep 1s后重试 ({rate_limit_retries}/{MAX_RATE_LIMIT_RETRIES})")
                        time.sleep(1)
                        tried_keys.discard(key_name)
                        continue
                    logger.warning(f"[{key_name}] 速率限制重试耗尽，切换下一个Key")

                if err_body and is_quota_error(status, err_body):
                    logger.warning(f"[{key_name}] 中转站限额触发(HTTP {status})，切换下一个Key | 可用Key剩余: {len(keys) - len(tried_keys)}")
                    record_key_error(key_name)
                    _mark_key_cooldown(key_name)
                    continue

                # 其他错误
                if err_body:
                    err_detail = _parse_error_detail(status, err_body)
                    logger.error(f"[{key_name}] 中转站非限额错误 | {err_detail}")
                    self._send(status, err_body)
                    return

            else:
                # === Anthropic Messages格式端点 (智谱直连或中转站) ===
                key_base_url = key.get("api_url")  # 自定义base_url (aiopus等中转站)
                label = f"中转站" if key_base_url else "智谱直连"
                logger.info(f"[{key_name}] → {label}转发 {model_requested} (attempt {attempt + 1})")

                key_model_map = key.get("model_map")  # 模型名映射
                status, headers, resp_body = call_zhipu(body_bytes, key["api_key"], self.path, base_url_override=key_base_url, model_map=key_model_map)

                if status == 200:
                    with _lock:
                        if key_name in _pool_state:
                            _pool_state[key_name]["consecutive_hits"] = 0
                    self._send(status, resp_body)
                    return

                if is_auth_error(status, resp_body):
                    # 区分: 真正的本地直连Key vs 有自定义api_url的中转站
                    # 中转站的403可能是临时问题(如中转站限流)，不应长期冷却
                    if key_base_url:
                        logger.warning(f"[{key_name}] 中转站认证错误(HTTP {status})，可能是临时问题，短冷却后重试")
                        record_key_error(key_name)
                        _mark_key_cooldown(key_name, "rate")  # 中转站403用短冷却
                    else:
                        logger.warning(f"[{key_name}] 认证失败(HTTP {status})，Key无效，长期冷却并切换下一个")
                        record_key_error(key_name)
                        _mark_key_cooldown(key_name, "balance")
                    continue

                if is_rate_limit_error(status, resp_body):
                    rate_limit_retries += 1
                    if rate_limit_retries <= MAX_RATE_LIMIT_RETRIES:
                        logger.info(f"[{key_name}] {label}速率限制，sleep 1s后重试 ({rate_limit_retries}/{MAX_RATE_LIMIT_RETRIES})")
                        time.sleep(1)
                        tried_keys.discard(key_name)
                        continue
                    logger.warning(f"[{key_name}] {label}速率限制重试耗尽，切换下一个Key")

                if is_quota_error(status, resp_body):
                    logger.warning(f"[{key_name}] {label}限额触发(HTTP {status})，切换下一个Key | 可用Key剩余: {len(keys) - len(tried_keys)}")
                    record_key_error(key_name)
                    _mark_key_cooldown(key_name)
                    continue

                # 其他错误(非限额/非认证) — 直接返回给CC
                err_detail = _parse_error_detail(status, resp_body)
                logger.error(f"[{key_name}] {label}非限额错误 | {err_detail}")
                self._send(status, resp_body)
                return

        # === 所有Key都不可用，降级到本地vLLM ===
        fallback_cfg = _config.get("fallback", {})
        if fallback_cfg.get("enabled", True):
            cooling_keys = [name for name, s in _pool_state.items() if s.get("cooldown_until")]
            logger.warning(f"[FALLBACK] 所有Key耗尽({len(keys)}个Key, {len(cooling_keys)}个冷却中)，降级到本地Qwen3.5-122B | 冷却Key: {', '.join(cooling_keys) if cooling_keys else '无'}")
            status, resp = call_local_vllm(body)
            self._send(status, resp)
            return

        # 保底也关了 — 返回错误
        self._send(429, {
            "type": "error",
            "error": {
                "type": "rate_limit_error",
                "message": "所有Key已耗尽且本地保底已禁用",
            },
        })


# ===================== 启动 =====================

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

_start_time = None

def main():
    global _start_time
    _start_time = _now()

    _load_config()
    _load_state()

    keys = _get_keys_by_priority()
    zhipu_keys = [k for k in keys if k.get("type", "zhipu") == "zhipu"]
    pool_keys = [k for k in keys if k.get("type") == "openai_compat"]

    logger.info(f"启动 Token Pool Proxy v2 on :{PORT}")
    logger.info(f"  智谱直连Key: {len(zhipu_keys)} 个")
    logger.info(f"  中转站Key: {len(pool_keys)} 个")
    logger.info(f"  上游: {_config.get('upstream', {}).get('base_url', 'N/A')}")
    logger.info(f"  保底: {_config.get('fallback', {}).get('vllm_url', 'N/A')}")

    for k in keys:
        avail = "✅" if _is_key_available(k["name"]) else "❄️冷却中"
        ktype = "智谱" if k.get("type", "zhipu") == "zhipu" else "中转站"
        logger.info(f"  [{k['name']}] ({ktype}) {avail}")

    server = ThreadedHTTPServer(("0.0.0.0", PORT), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("关闭中...")
        server.shutdown()


if __name__ == "__main__":
    main()
