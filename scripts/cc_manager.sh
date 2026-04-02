#!/bin/bash
# ==============================================================
# cc_manager.sh — 研发经理CC定时触发脚本
# crontab: */10 * * * *
# 功能：触发.github项目的研发经理CC，让其检查进行中的CC、
#       更新已完成Issue的排程状态、触发新的CC处理下一批Issue
#
# 查看实时日志: tail -f /home/ubuntu/cc_scheduler/manager.log
# ==============================================================

LOCK_FILE="/home/ubuntu/cc_scheduler/manager.lock"
LOG_FILE="/home/ubuntu/cc_scheduler/manager.log"
RAW_LOG="/home/ubuntu/cc_scheduler/manager-raw.jsonl"
GITHUB_DIR="/home/ubuntu/projects/.github"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# 防止并发（上一轮还没结束就不启动新的）
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "跳过: 上一轮研发经理CC仍在运行 (PID=$PID)"
        exit 0
    else
        log "清理: 上一轮PID=$PID已不存在，移除锁"
        rm -f "$LOCK_FILE"
    fi
fi

# 写入锁
echo $$ > "$LOCK_FILE"
log "启动研发经理CC"

# 获取GH_TOKEN
export GH_TOKEN=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
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy
export PATH="/home/ubuntu/.local/bin:$PATH"
export HOME="/home/ubuntu"

cd "$GITHUB_DIR"

# 触发研发经理CC（stream-json实时日志）
claude -p "继续完成任务二，如果任务二没有issue了，执行一次任务一后继续" \
  --model claude-opus-4-6 --output-format stream-json --include-partial-messages --verbose \
  2>/dev/null | tee -a "$RAW_LOG" | python3 "$PARSER" >> "$LOG_FILE" 2>&1

EXIT_CODE=${PIPESTATUS[0]}
log "研发经理CC结束 (exit=$EXIT_CODE)"

# 清理锁
rm -f "$LOCK_FILE"
