#!/usr/bin/env python3
"""cc-stream-parser.py — 实时解析 claude stream-json 输出为可读日志

用法: claude -p '...' --output-format stream-json --include-partial-messages --verbose 2>/dev/null | python3 cc-stream-parser.py >> logfile.log
"""
import sys, json, time

def fmt_time():
    return time.strftime("%H:%M:%S")

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except:
        print(f"[{fmt_time()}] {line}", flush=True)
        continue

    msg_type = obj.get("type", "")

    if msg_type == "assistant":
        content = obj.get("message", {}).get("content", [])
        for block in content:
            if block.get("type") == "text":
                text = block.get("text", "")[:200]
                if text.strip():
                    print(f"[{fmt_time()}] 🤖 {text}", flush=True)
            elif block.get("type") == "tool_use":
                tool = block.get("name", "?")
                inp = json.dumps(block.get("input", {}), ensure_ascii=False)[:150]
                print(f"[{fmt_time()}] 🔧 tool:{tool} {inp}", flush=True)

    elif msg_type == "content_block_start":
        cb = obj.get("content_block", {})
        if cb.get("type") == "tool_use":
            tool = cb.get("name", "?")
            inp = json.dumps(cb.get("input", {}), ensure_ascii=False)[:150]
            print(f"[{fmt_time()}] 🔧 tool:{tool} {inp}", flush=True)
        elif cb.get("type") == "text":
            text = cb.get("text", "")
            if text.strip():
                print(f"[{fmt_time()}] 🤖 {text[:200]}", flush=True)

    elif msg_type == "content_block_delta":
        delta = obj.get("delta", {})
        if delta.get("type") == "text_delta":
            text = delta.get("text", "")
            if text.strip():
                if any(kw in text.lower() for kw in ["read", "write", "edit", "bash", "create", "search", "file", "run", "test", "commit"]):
                    print(f"[{fmt_time()}] 💭 {text.strip()[:150]}", flush=True)
        elif delta.get("type") == "input_json_delta":
            pass

    elif msg_type == "result":
        result = obj.get("result", "")
        cost = obj.get("cost_usd", "")
        turns = obj.get("num_turns", "")
        print(f"[{fmt_time()}] ✅ DONE turns={turns} cost=${cost}", flush=True)
        if result:
            print(f"[{fmt_time()}] {result[:300]}", flush=True)

    elif msg_type == "system":
        msg = obj.get("message", "")
        if msg:
            print(f"[{fmt_time()}] ⚙️ {msg[:200]}", flush=True)

    elif msg_type == "error":
        err = obj.get("error", {})
        print(f"[{fmt_time()}] ❌ ERROR: {err}", flush=True)
