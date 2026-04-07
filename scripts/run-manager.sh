#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# ==============================================================
# run-manager.sh — 启动并保活两个研发经理CC
# crontab: */30 * * * *
# 会话存在则跳过，崩溃则重启；经理内部用 \loop 10m 自驱动
# 查看日志: tail -f ~/cc_scheduler/manager.log
# ==============================================================

GITHUB_DIR="${HOME_DIR}/projects/.github"
SCRIPT_DIR="${GITHUB_DIR}/scripts"
LOG_FILE="${HOME_DIR}/cc_scheduler/manager.log"

mkdir -p "$(dirname "$LOG_FILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)

# Proxy模式API环境（effort=medium）
PROXY_API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; \
export ANTHROPIC_API_KEY=dummy; \
export API_TIMEOUT_MS=3000000; \
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"

# 启动单个经理CC（幂等，会话存在则跳过）
start_manager() {
  local ROLE="$1"      # 排程经理 | 研发经理
  local LOOP_PROMPT="$2"
  local SESSION="manager-${ROLE}"

  if tmux has-session -t "$SESSION" 2>/dev/null; then
    log "✓ ${ROLE} 运行中 (${SESSION})，跳过"
    return 0
  fi

  log "启动 ${ROLE} → ${SESSION}"

  # 隔离 claude config（同 run-cc.sh proxy 模式）
  local CONFIG_DIR="/tmp/cc-config-${SESSION}"
  mkdir -p "$CONFIG_DIR"
  rsync -a --exclude='.credentials.json' --exclude='projects' \
    "${HOME_DIR}/.claude/" "$CONFIG_DIR/" 2>/dev/null
  ln -sfn "${HOME_DIR}/.claude/projects" "$CONFIG_DIR/projects"
  cat > "$CONFIG_DIR/.credentials.json" << 'CREDS'
{"claudeAiOauth":{"accessToken":"stub-proxy-mode","refreshToken":"stub-proxy-mode","expiresAt":1,"scopes":["user:inference"],"subscriptionType":"free","rateLimitTier":"free"}}
CREDS
  [ -f "${HOME_DIR}/.claude.json" ] && cp "${HOME_DIR}/.claude.json" "$CONFIG_DIR/.claude.json"

  tmux new-session -d -s "$SESSION" -c "$GITHUB_DIR" \
    "export GH_TOKEN=${GH_TOKEN}; \
     export HOME=${HOME_DIR}; \
     export PATH=${HOME_DIR}/.local/bin:\$PATH; \
     ${PROXY_API_ENV} \
     export CLAUDE_CONFIG_DIR=${CONFIG_DIR}; \
     claude --model claude-opus-4-6 --dangerously-skip-permissions; \
     rm -rf ${CONFIG_DIR}; exec bash"

  # 等待 Claude Code CLI 初始化
  sleep 6

  # 注入 loop 提示词（自驱动，每10分钟执行一轮）
  tmux send-keys -t "$SESSION" "$LOOP_PROMPT" Enter

  log "✓ ${ROLE} 已启动，loop已注入"
}

start_manager "排程经理" "\\loop 10m 你是排程经理，按 docs/agent-docs/manager/scheduler-guide.md 执行本轮巡检"
start_manager "研发经理" "\\loop 10m 你是研发经理，按 docs/agent-docs/manager/assign-guide.md 执行本轮任务"
