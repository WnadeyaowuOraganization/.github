#!/bin/bash
# e2e_top_tier.sh — 顶层E2E测试（每6小时，全量回归）
# crontab: 0 */6 * * *

LOCK_FILE="/home/ubuntu/cc_scheduler/e2e_top.lock"
LOG_FILE="/home/ubuntu/cc_scheduler/e2e_top.log"
E2E_DIR="/home/ubuntu/projects/wande-ai-e2e-full"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "跳过: 上一轮仍在运行 (PID=$PID)"
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

echo $$ > "$LOCK_FILE"
log "启动顶层E2E全量回归"

export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)
export PATH="/home/ubuntu/.local/bin:$PATH"
export HOME="/home/ubuntu"

cd "$E2E_DIR"
claude -p "执行顶层测试" --output-format text >> "$LOG_FILE" 2>&1

log "顶层E2E结束 (exit=$?)"
rm -f "$LOCK_FILE"
