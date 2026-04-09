#!/bin/bash
# refresh-gh-token.sh — 周期性刷新 GitHub App installation token (TTL 1h)
#
# 触发: cron */45 * * * *  （45 分钟一次，留 15 分钟余量）
# 作用:
#   1. 调 gh-app-token.py 生成新 installation token
#   2. 写到 ~/.config/gh/hosts.yml (gh CLI fallback 路径)
#   3. 写到 /tmp/.gh-token.env (供 wrapper / 其它脚本 source)
#   4. 给所有 cc-* 和 manager-* tmux 会话用 set-environment 更新 GH_TOKEN
#      （已启动的 claude 进程内部的 env 无法热更新，只对它们 spawn 的子进程生效）
#
# 注意: 这只解决"新 spawn 的子进程能拿到新 token"的问题。
#       已经在跑的 claude 主进程的 env 是 fork 时刻的快照，无法热更。
#       要让现有 CC 完全恢复，需要重启 CC（或让 CC 跑 git/gh 时显式 unset GH_TOKEN
#       让 gh CLI 走 hosts.yml）。

set -e

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="${HOME_DIR}/projects/.github/scripts"
LOG_FILE="${HOME_DIR}/cc_scheduler/refresh-gh-token.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# 1. 拿新 token
TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)
if [ -z "$TOKEN" ] || [ "${#TOKEN}" -lt 20 ]; then
    log "❌ gh-app-token.py 生成失败，token 长度=${#TOKEN}"
    exit 1
fi

# 2. 写到 gh CLI hosts.yml（让 gh CLI fallback 时能用）
echo "$TOKEN" | gh auth login --with-token -h github.com 2>/dev/null \
    && log "✓ hosts.yml 已更新 (${TOKEN:0:12}...)" \
    || log "⚠ hosts.yml 更新失败"

# 3. 写到固定文件，供 wrapper / 其它脚本 source
echo "export GH_TOKEN=$TOKEN" > /tmp/.gh-token.env
chmod 600 /tmp/.gh-token.env
log "✓ /tmp/.gh-token.env 已更新"

# 4. 给所有 cc-* 和 manager-* tmux 会话更新 set-environment
#    （仅对它们后续 spawn 的子进程生效）
UPDATED=0
for sn in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -E '^(cc-|manager-|e2e-)'); do
    tmux set-environment -t "$sn" GH_TOKEN "$TOKEN" 2>/dev/null && UPDATED=$((UPDATED+1))
done
log "✓ 已更新 $UPDATED 个 tmux 会话的 GH_TOKEN"

# 5. 验证新 token 能 hit GitHub API
if curl -sfI -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/WnadeyaowuOraganization/wande-play" \
        > /dev/null 2>&1; then
    log "✅ token 验证成功"
else
    log "❌ token 验证失败 (curl /repos/wande-play)"
    exit 2
fi
