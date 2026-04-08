#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# e2e_top_tier.sh — 顶层E2E测试（每6小时，全量回归）
# crontab: 0 */6 * * *
# 保活：cron每6小时检查，会话存在则跳过，崩溃则重启
#
# 操作:
#   tmux attach -t e2e-top    查看/注入消息
#   Ctrl+B D                  脱离（测试继续运行）

E2E_DIR="${HOME_DIR}/projects/wande-play-e2e-top/e2e"
SESSION="e2e-top"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_MAP="/tmp/manager-session-map.json"
JSONL_DIR="${HOME_DIR}/.claude/projects/-home-ubuntu-projects-wande-play-e2e-top-e2e"

LOG_FILE="${HOME_DIR}/cc_scheduler/manager.log"
mkdir -p "$(dirname "$LOG_FILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# 写入 tmux会话→JSONL 映射（供 Claude Office 精确关联日志）
_write_session_map() {
  local session="$1" jsonl="$2"
  python3 -c "
import json, os
f='${SESSION_MAP}'
m = json.load(open(f)) if os.path.exists(f) else {}
m['${session}'] = '${jsonl}'
json.dump(m, open(f,'w'))
" 2>/dev/null
}

# 启动后等待新 JSONL 出现并写入映射
_associate_jsonl() {
  local session="$1" before_list="$2"
  local max_wait=40 elapsed=0
  while [ $elapsed -lt $max_wait ]; do
    sleep 2; elapsed=$((elapsed+2))
    local claimed
    claimed=$(python3 -c "
import json,os
f='${SESSION_MAP}'
if os.path.exists(f):
    m=json.load(open(f))
    for k,v in m.items():
        if k != '${session}': print(v)
" 2>/dev/null)
    local new_jsonl
    new_jsonl=$(ls -1t "${JSONL_DIR}"/*.jsonl 2>/dev/null \
      | while read -r f; do
          echo "$before_list" | grep -qxF "$f" && continue
          echo "$claimed"     | grep -qxF "$f" && continue
          echo "$f"; break
        done)
    if [ -n "$new_jsonl" ]; then
      _write_session_map "$session" "$new_jsonl"
      log "✓ ${session} → $(basename $new_jsonl)"
      return
    fi
  done
  log "⚠ ${session} JSONL关联超时，将由server.py时序匹配"
}

# 幂等：会话已存在则跳过
if tmux has-session -t "$SESSION" 2>/dev/null; then
    log "✓ e2e-top 运行中，跳过"
    exit 0
fi

log "启动 e2e-top → ${SESSION}"

# pre-task：切换 dev 分支并 pull
cd "$E2E_DIR"
git checkout dev 2>/dev/null && git pull origin dev 2>/dev/null

# Token：使用个人账号PAT（App token无法自审核自己创建的PR）
export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" weiping)

# API来源：Token Pool Proxy（同 run-cc.sh effort!=max）
API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; export ANTHROPIC_API_KEY=dummy; export API_TIMEOUT_MS=3000000; export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"

CONFIG_DIR="/tmp/cc-config-${SESSION}"
mkdir -p "$CONFIG_DIR"
rsync -a --exclude='.credentials.json' --exclude='projects' \
  "${HOME_DIR}/.claude/" "$CONFIG_DIR/" 2>/dev/null
ln -sfn "${HOME_DIR}/.claude/projects" "$CONFIG_DIR/projects"
# 使用真实 credentials（避免 stub 触发 OAuth 刷新失败后写回 ~/.claude/.credentials.json 污染经理CC）
# API 调用走 proxy（ANTHROPIC_BASE_URL），credentials 仅用于 claude.ai 会话认证，不影响计费
cp "${HOME_DIR}/.claude/.credentials.json" "$CONFIG_DIR/.credentials.json" 2>/dev/null
[ -f "${HOME_DIR}/.claude.json" ] && cp "${HOME_DIR}/.claude.json" "$CONFIG_DIR/.claude.json"

# 备份真实 credentials（防御性措施：确保运行后恢复）
CREDS_BACKUP="/tmp/creds-backup-${SESSION}.json"
cp "${HOME_DIR}/.claude/.credentials.json" "$CREDS_BACKUP" 2>/dev/null

# 记录启动前已有的 JSONL 列表
mkdir -p "$JSONL_DIR"
BEFORE_LIST=$(ls -1 "${JSONL_DIR}"/*.jsonl 2>/dev/null | sort)

tmux new-session -d -s "$SESSION" -c "$E2E_DIR" \
  "export GH_TOKEN=${GH_TOKEN}; \
   export HOME=${HOME_DIR}; \
   export PATH=${HOME_DIR}/.local/bin:\$PATH; \
   ${API_ENV} \
   export CLAUDE_CONFIG_DIR=${CONFIG_DIR}; \
   claude --model claude-opus-4-6 --dangerously-skip-permissions; \
   rm -rf ${CONFIG_DIR}; \
   cp ${CREDS_BACKUP} ${HOME_DIR}/.claude/.credentials.json 2>/dev/null; \
   rm -f ${CREDS_BACKUP}; \
   tmux kill-session -t ${SESSION}"

# 后台：注入prompt + 关联JSONL
( sleep 6
  tmux send-keys -t "$SESSION" "执行顶层E2E全量回归测试" Enter
  _associate_jsonl "$SESSION" "$BEFORE_LIST"
) &

log "✓ e2e-top 已启动，JSONL关联中..."
echo "  tmux attach -t $SESSION    查看/注入消息"
