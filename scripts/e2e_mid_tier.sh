#!/bin/bash
# e2e_mid_tier.sh — 中层E2E测试（每15分钟，PR驱动）
# crontab: */15 * * * *

LOCK_FILE="/home/ubuntu/cc_scheduler/e2e_mid.lock"
LOG_FILE="/home/ubuntu/cc_scheduler/e2e_mid.log"
E2E_DIR="/home/ubuntu/projects/wande-ai-e2e"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# 防止并发
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        log "跳过: 上一轮仍在运行 (PID=$PID)"
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

echo $$ > "$LOCK_FILE"
log "启动中层E2E测试"

export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)
export PATH="/home/ubuntu/.local/bin:$PATH"
export HOME="/home/ubuntu"

cd "$E2E_DIR"
claude -p "执行中层测试" --output-format text >> "$LOG_FILE" 2>&1

log "中层E2E结束 (exit=$?)"
rm -f "$LOCK_FILE"
