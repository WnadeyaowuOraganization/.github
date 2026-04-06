#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# ==============================================================
# cc_manager.sh — 研发经理CC定时触发脚本
# crontab: */10 * * * *
# 功能：触发.github项目的研发经理CC，让其检查进行中的CC、
#       更新已完成Issue的排程状态、触发新的CC处理下一批Issue
#
# 查看实时日志: tail -f ${HOME_DIR}/cc_scheduler/manager.log
# ==============================================================

LOCK_FILE="${HOME_DIR}/cc_scheduler/manager.lock"
LOG_FILE="${HOME_DIR}/cc_scheduler/manager.log"
GITHUB_DIR="${HOME_DIR}/projects/.github"
SCRIPT_DIR="${GITHUB_DIR}/scripts"

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
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy
export PATH="${HOME_DIR}/.local/bin:$PATH"
export HOME="${HOME_DIR}"

cd "$GITHUB_DIR"

# 调度前：恢复异常退出的CC + 清理僵尸锁
log "执行cron恢复检查..."
bash "$SCRIPT_DIR/post-cc-check.sh" >> "$LOG_FILE" 2>&1

# 触发研发经理CC（日志由Claude Code自动写入JSONL）
claude -p "继续完成任务二，如果任务二没有issue了，执行一次任务一后继续" \
  --model claude-opus-4-6 --effort medium --max-turns 200 --verbose \
  >> "$LOG_FILE" 2>&1

EXIT_CODE=$?
log "研发经理CC结束 (exit=$EXIT_CODE)"

# 清理锁
rm -f "$LOCK_FILE"
