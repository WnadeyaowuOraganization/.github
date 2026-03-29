#!/usr/bin/env python3
"""
Token Pool Proxy — 智谱Coding Plan多Key自动切换代理
==================================================
监听 0.0.0.0:9855，提供 Anthropic Messages API 兼容端点
CC(Claude Code) 通过 ANTHROPIC_BASE_URL=http://localhost:9855 连接

功能:
  1. 维护多个智谱API Key池，轮询分配
  2. 检测限额错误(1302)自动切换到下一个Key重试
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
_pool_state = {}  # {key_name: {"cooldown_until": iso_str, "type": "rate"|"weekly", "consecutive_hits": int}}
_round_robin_index = 0
_stats = {}  # {key_name: {"requests": int, "errors": int, "last_used": iso_str}}


def _now():
    return datetime.now(CST)


def _load_config():
    global _config
    with open(KEYS_FILE, "r") as f:
        _config = json.load(f)
    logger.info(f"配置加载: {len([k for k in _config['keys'] if k['enabled']])} 个启用Key")


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
    """标记Key进入冷却"""
    with _lock:
        state = _pool_state.get(key_name, {"consecutive_hits": 0})
        state["consecutive_hits"] = state.get("consecutive_hits", 0) + 1

        cooldown_cfg = _config.get("cooldown", {})

        # 连续触发2次以上 → 升级为周冷却
        if state["consecutive_hits"] >= 2 or cooldown_type == "weekly":
            hours = cooldown_cfg.get("weekly_limit_hours", 168)
            state["type"] = "weekly"
            logger.warning(f"[{key_name}] 周限额冷却 {hours}h (连续触发{state['consecutive_hits']}次)")
        else:
            hours = cooldown_cfg.get("rate_limit_hours", 5)
            state["type"] = "rate"
            logger.warning(f"[{key_name}] 5小时限额冷却 {hours}h")

        state["cooldown_until"] = (_now() + timedelta(hours=hours)).isoformat()
        state["marked_at"] = _now().isoformat()
        _pool_state[key_name] = state
        _save_state()


def get_next_key():
    """获取下一个可用Key (轮询+跳过冷却中的)"""
    global _round_robin_index
    keys = _get_enabled_keys()
    if not keys:
        return None

    with _lock:
        # 尝试所有Key
        for _ in range(len(keys)):
            idx = _round_robin_index % len(keys)
            _round_robin_index += 1
            key = keys[idx]
            if _is_key_available(key["name"]):
                # 更新统计
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

def anthropic_to_openai(anthropic_body):
    """将Anthropic Messages API请求转换为OpenAI Chat Completions格式"""
    messages = []

    # system字段 → system message
    system = anthropic_body.get("system")
    if system:
        if isinstance(system, str):
            messages.append({"role": "system", "content": system})
        elif isinstance(system, list):
            # Anthropic支持system为content blocks数组
            text = " ".join(b.get("text", "") for b in system if b.get("type") == "text")
            if text:
                messages.append({"role": "system", "content": text})

    # messages转换
    for msg in anthropic_body.get("messages", []):
        role = msg.get("role", "user")
        content = msg.get("content", "")

        # content可能是字符串或content blocks数组
        if isinstance(content, list):
            # 提取所有text blocks拼接
            text_parts = []
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    text_parts.append(block.get("text", ""))
                elif isinstance(block, str):
                    text_parts.append(block)
            content = "\n".join(text_parts)

        messages.append({"role": role, "content": content})

    openai_body = {
        "model": _config.get("fallback", {}).get("vllm_model", "/model"),
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


# ===================== 上游调用 =====================

def call_zhipu(body_bytes, api_key, path="/v1/messages"):
    """转发请求到智谱API"""
    base_url = _config.get("upstream", {}).get("base_url", "https://open.bigmodel.cn/api/anthropic")
    url = f"{base_url}{path}"

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
            # 从请求的model字段获取模型名（CC可能传的是glm-5.1等）
            requested_model = anthropic_body.get("model", "qwen3.5-122b-local")
            anthropic_resp = openai_to_anthropic(openai_resp, requested_model)
            return 200, anthropic_resp
    except Exception as e:
        logger.error(f"[本地vLLM] 调用失败: {e}")
        return 500, {
            "type": "error",
            "error": {"type": "fallback_error", "message": f"本地vLLM也失败: {e}"},
        }


def is_quota_error(status_code, resp_body):
    """判断是否为限额错误"""
    if status_code == 429:
        return True

    try:
        data = json.loads(resp_body) if isinstance(resp_body, (bytes, str)) else resp_body
        # 智谱错误码1302 = 速率限制
        error = data.get("error", {})
        if isinstance(error, dict):
            code = error.get("code", "")
            message = error.get("message", "").lower()
            if str(code) == "1302":
                return True
            if any(kw in message for kw in ["rate limit", "quota", "exceeded", "limit reached"]):
                return True
        # 有时错误直接在顶层
        if str(data.get("code", "")) == "1302":
            return True
    except Exception:
        pass

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
            self._send(200, {"status": "ok", "service": "TokenPoolProxy", "port": PORT})
            return

        if self.path == "/status":
            keys = _get_enabled_keys()
            key_status = []
            for k in keys:
                name = k["name"]
                available = _is_key_available(name)
                state = _pool_state.get(name, {})
                stats = _stats.get(name, {"requests": 0, "errors": 0})
                key_status.append({
                    "name": name,
                    "available": available,
                    "requests": stats["requests"],
                    "errors": stats["errors"],
                    "cooldown_type": state.get("type"),
                    "cooldown_until": state.get("cooldown_until"),
                    "consecutive_hits": state.get("consecutive_hits", 0),
                })

            fallback_cfg = _config.get("fallback", {})
            self._send(200, {
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

        # === 尝试智谱Key池 ===
        keys = _get_enabled_keys()
        tried_keys = set()

        for attempt in range(len(keys)):
            key = get_next_key()
            if key is None:
                break  # 所有Key都在冷却

            key_name = key["name"]
            if key_name in tried_keys:
                break  # 已经轮了一圈
            tried_keys.add(key_name)

            logger.info(f"[{key_name}] → 转发 {model_requested} (attempt {attempt + 1})")

            status, headers, resp_body = call_zhipu(body_bytes, key["api_key"], self.path)

            if status == 200:
                # 成功 — 如果之前有冷却记录，清除consecutive_hits
                with _lock:
                    if key_name in _pool_state:
                        _pool_state[key_name]["consecutive_hits"] = 0
                self._send(status, resp_body)
                return

            if is_quota_error(status, resp_body):
                logger.warning(f"[{key_name}] 限额触发(HTTP {status})，切换下一个Key")
                record_key_error(key_name)
                _mark_key_cooldown(key_name)
                continue  # 尝试下一个Key

            # 其他错误(非限额) — 直接返回给CC
            logger.error(f"[{key_name}] 非限额错误(HTTP {status})")
            self._send(status, resp_body)
            return

        # === 所有Key都不可用，降级到本地vLLM ===
        fallback_cfg = _config.get("fallback", {})
        if fallback_cfg.get("enabled", True):
            logger.warning(f"[FALLBACK] 所有Key耗尽，降级到本地Qwen3.5-122B")
            status, resp = call_local_vllm(body)
            self._send(status, resp)
            return

        # 保底也关了 — 返回错误
        self._send(429, {
            "type": "error",
            "error": {
                "type": "rate_limit_error",
                "message": "所有智谱Key已耗尽且本地保底已禁用",
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

    keys = _get_enabled_keys()
    logger.info(f"启动 Token Pool Proxy on :{PORT}")
    logger.info(f"  智谱Key: {len(keys)} 个启用")
    logger.info(f"  上游: {_config.get('upstream', {}).get('base_url', 'N/A')}")
    logger.info(f"  保底: {_config.get('fallback', {}).get('vllm_url', 'N/A')}")

    for k in keys:
        avail = "✅" if _is_key_available(k["name"]) else "❄️冷却中"
        logger.info(f"  [{k['name']}] {avail}")

    server = ThreadedHTTPServer(("0.0.0.0", PORT), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("关闭中...")
        server.shutdown()


if __name__ == "__main__":
    main()
