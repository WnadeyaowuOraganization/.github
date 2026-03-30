#!/bin/bash
# ==============================================================
# cc_manager.sh — 研发经理CC定时触发脚本
# crontab: */10 * * * *
# 功能：触发.github项目的研发经理CC，让其检查进行中的CC、
#       更新已完成Issue的排程状态、触发新的CC处理下一批Issue
# ==============================================================

LOCK_FILE="/home/ubuntu/cc_scheduler/manager.lock"
LOG_FILE="/home/ubuntu/cc_scheduler/manager.log"
GITHUB_DIR="/home/ubuntu/projects/.github"

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
export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)
export PATH="/home/ubuntu/.local/bin:$PATH"
export HOME="/home/ubuntu"

cd "$GITHUB_DIR"

# 触发研发经理CC
claude -p "检查当前运行中的CC状态（查看/home/ubuntu/cc_scheduler/logs/下的日志和PID文件），更新SCHEDULE.md中已完成Issue的状态，然后为空闲目录触发新的CC处理排程中下一批Issue" --output-format text >> "$LOG_FILE" 2>&1

EXIT_CODE=$?
log "研发经理CC结束 (exit=$EXIT_CODE)"

# 清理锁
rm -f "$LOCK_FILE"
