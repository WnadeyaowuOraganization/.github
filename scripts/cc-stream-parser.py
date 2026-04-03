#!/usr/bin/env python3
"""cc-stream-parser.py — 实时解析 claude stream-json 输出为可读日志（v2）

用法: claude -p '...' --output-format stream-json --include-partial-messages --verbose 2>/dev/null | python3 cc-stream-parser.py >> logfile.log

v2 变更（2026-04-04）：
- 修复截断：tool输入/文本/结果按字段类型智能分配长度，不再硬截断200字符
- 修复stream_event嵌套：正确解包 stream_event.event 中的 content_block_*
- 去重：忽略assistant汇总消息（stream_event已完整输出，assistant是重复副本）
- content_block_delta累积：在content_block_stop时输出完整工具调用
- result完整输出：最终结果不截断
- 新增INIT行：显示model和session信息
- 新增duration格式化
"""
import sys, json, time

# ---------- 配置 ----------
MAX_TEXT = 500          # 🤖 文本消息最大字符
MAX_TOOL_SUMMARY = 400  # 🔧 tool摘要最大字符
MAX_RESULT = 0          # ✅ result不截断（0=无限制）
MAX_DELTA_LINE = 300    # 💭 delta行最大字符

def fmt_time():
    return time.strftime("%H:%M:%S")

def trunc(s, limit):
    """截断字符串，limit=0表示不截断"""
    if not s or limit == 0:
        return s
    if len(s) <= limit:
        return s
    return s[:limit] + "...(+" + str(len(s) - limit) + ")"

def format_tool_input(name, inp):
    """智能格式化tool输入：保留关键字段完整，压缩大内容"""
    if not isinstance(inp, dict):
        return trunc(json.dumps(inp, ensure_ascii=False), MAX_TOOL_SUMMARY)

    parts = []

    # file_path / path — 永远完整显示
    for key in ("file_path", "path", "pattern", "glob"):
        if key in inp:
            parts.append(key + "=" + str(inp[key]))

    # command — 给足够空间
    if "command" in inp:
        cmd = inp["command"]
        parts.append("cmd=" + trunc(cmd, 300))

    # content / new_string — 只显示前100字符 + 行数
    for key in ("content", "new_string", "old_string"):
        if key in inp:
            val = inp[key]
            lines = val.count("\n") + 1 if isinstance(val, str) else 0
            preview = trunc(str(val), 100)
            parts.append(key + "=(" + str(lines) + "L) " + preview)

    # description — 完整显示
    if "description" in inp:
        parts.append("desc=" + str(inp["description"]))

    # 其他字段
    shown_keys = {"file_path", "path", "pattern", "glob", "command", "content",
                  "new_string", "old_string", "description"}
    for key, val in inp.items():
        if key not in shown_keys:
            s = json.dumps(val, ensure_ascii=False) if not isinstance(val, str) else val
            parts.append(key + "=" + trunc(s, 80))

    result = " | ".join(parts)
    return trunc(result, MAX_TOOL_SUMMARY) if MAX_TOOL_SUMMARY else result

# ---------- 状态管理 ----------
class ParserState:
    def __init__(self):
        self.text_buf = ""
        self.tool_name = ""
        self.tool_json_buf = ""
        self.current_index = -1

    def flush_text(self):
        """输出累积的文本（按行拆分）"""
        if not self.text_buf.strip():
            self.text_buf = ""
            return
        for line in self.text_buf.split("\n"):
            if line.strip():
                print("[" + fmt_time() + "] 🤖 " + trunc(line.strip(), MAX_DELTA_LINE), flush=True)
        self.text_buf = ""

    def flush_tool(self):
        """输出累积的tool JSON"""
        if self.tool_name and self.tool_json_buf:
            try:
                inp = json.loads(self.tool_json_buf)
                summary = format_tool_input(self.tool_name, inp)
                print("[" + fmt_time() + "] 🔧 tool:" + self.tool_name + " " + summary, flush=True)
            except json.JSONDecodeError:
                print("[" + fmt_time() + "] 🔧 tool:" + self.tool_name + " " + trunc(self.tool_json_buf, MAX_TOOL_SUMMARY), flush=True)
        self.tool_name = ""
        self.tool_json_buf = ""

    def start_block(self, index):
        """新的content_block开始前，flush上一个block的残余"""
        if index != self.current_index:
            self.flush_text()
            self.flush_tool()
            self.current_index = index

state = ParserState()

# ---------- 主解析循环 ----------
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        print("[" + fmt_time() + "] " + line, flush=True)
        continue

    msg_type = obj.get("type", "")

    # ===== stream_event 包装 — 解包内层event =====
    if msg_type == "stream_event":
        event = obj.get("event", {})
        inner_type = event.get("type", "")

        if inner_type == "message_start":
            msg = event.get("message", {})
            model = msg.get("model", "")
            usage = msg.get("usage", {})
            inp_tokens = usage.get("input_tokens", 0)
            if model:
                print("[" + fmt_time() + "] 📡 model=" + model + " input_tokens=" + str(inp_tokens), flush=True)

        elif inner_type == "content_block_start":
            index = event.get("index", -1)
            state.start_block(index)
            cb = event.get("content_block", {})
            if cb.get("type") == "tool_use":
                state.tool_name = cb.get("name", "?")
                state.tool_json_buf = ""
                # tool_use的input在start时通常为空{}，在delta中逐步填充
                inp = cb.get("input", {})
                if inp:
                    summary = format_tool_input(state.tool_name, inp)
                    print("[" + fmt_time() + "] 🔧 tool:" + state.tool_name + " " + summary, flush=True)
                    state.tool_name = ""  # 已输出，清除避免stop时重复
            elif cb.get("type") == "text":
                text = cb.get("text", "")
                if text.strip():
                    state.text_buf += text

        elif inner_type == "content_block_delta":
            delta = event.get("delta", {})
            if delta.get("type") == "text_delta":
                text = delta.get("text", "")
                state.text_buf += text
                # 遇到换行时逐行输出
                while "\n" in state.text_buf:
                    line_text, state.text_buf = state.text_buf.split("\n", 1)
                    if line_text.strip():
                        print("[" + fmt_time() + "] 🤖 " + trunc(line_text.strip(), MAX_DELTA_LINE), flush=True)
            elif delta.get("type") == "input_json_delta":
                state.tool_json_buf += delta.get("partial_json", "")

        elif inner_type == "content_block_stop":
            state.flush_text()
            state.flush_tool()

        elif inner_type == "message_delta":
            delta = event.get("delta", {})
            usage = event.get("usage", {})
            stop = delta.get("stop_reason", "")
            out_tokens = usage.get("output_tokens", 0)
            if stop and stop != "tool_use":
                print("[" + fmt_time() + "] 📊 stop=" + stop + " output_tokens=" + str(out_tokens), flush=True)

        # message_stop — 不需要额外处理

    # ===== assistant（stream的汇总副本）— 跳过，stream_event已完整输出 =====
    elif msg_type == "assistant":
        pass

    # ===== result =====
    elif msg_type == "result":
        state.flush_text()
        state.flush_tool()
        result = obj.get("result", "")
        cost = obj.get("cost_usd", "")
        turns = obj.get("num_turns", "")
        duration = obj.get("duration_ms", "")
        duration_str = ""
        if duration:
            try:
                mins = int(duration) // 60000
                secs = (int(duration) % 60000) // 1000
                duration_str = " duration=" + str(mins) + "m" + str(secs) + "s"
            except (ValueError, TypeError):
                pass
        print("[" + fmt_time() + "] " + "✅ DONE turns=" + str(turns) + " cost=$" + str(cost) + duration_str, flush=True)
        if result:
            if MAX_RESULT:
                print("[" + fmt_time() + "] " + trunc(str(result), MAX_RESULT), flush=True)
            else:
                print("[" + fmt_time() + "] " + str(result), flush=True)

    # ===== system =====
    elif msg_type == "system":
        state.flush_text()
        state.flush_tool()
        sub = obj.get("subtype", "")
        if sub == "init":
            model = obj.get("model", "")
            session = obj.get("session_id", "")[:12]
            cwd = obj.get("cwd", "")
            print("[" + fmt_time() + "] " + "⚙️ INIT model=" + model + " session=" + session + "... cwd=" + cwd, flush=True)
        else:
            msg_text = obj.get("message", "")
            if msg_text:
                print("[" + fmt_time() + "] " + "⚙️ " + trunc(str(msg_text), MAX_TEXT), flush=True)

    # ===== error =====
    elif msg_type == "error":
        state.flush_text()
        state.flush_tool()
        err = obj.get("error", {})
        print("[" + fmt_time() + "] " + "❌ ERROR: " + str(err), flush=True)

    # ===== user (tool结果回传) — 不输出，内容太冗长 =====
    # elif msg_type == "user": pass
