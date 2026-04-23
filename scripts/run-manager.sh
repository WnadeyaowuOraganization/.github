#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# ==============================================================
# run-manager.sh — 启动并保活两个研发经理CC
# crontab: */10 * * * *
# 会话存在则跳过，崩溃则重启；经理内部用 \loop 10m 自驱动
# 模式：Claude Max 订阅
#   - 排程经理：Haiku 4.5（结构化清单驱动，省 token）
#   - 研发经理：Haiku 4.5（W1+W2+W3 改造后，巡检瘦身为 attention-only，
#     工作复杂度大幅下降；Done Guard 已硬隔离误判风险，可切 Haiku 省 token）
# 查看日志: tail -f ~/cc_scheduler/manager.log
# ==============================================================

GITHUB_DIR="${HOME_DIR}/projects/.github"
SCRIPT_DIR="${GITHUB_DIR}/scripts"
LOG_FILE="${HOME_DIR}/cc_scheduler/manager.log"
SESSION_MAP="/tmp/manager-session-map.json"
# 2026-04-12: M7i 迁移后 Claude 解析 realpath，JSONL 目录前缀从
# -home-ubuntu- 变为 -data-home-ubuntu-，需兼容两种格式
_JSONL_DIR_NEW="${HOME_DIR}/.claude/projects/-data-home-ubuntu-projects--github"
_JSONL_DIR_OLD="${HOME_DIR}/.claude/projects/-home-ubuntu-projects--github"
if [ -d "$_JSONL_DIR_NEW" ]; then
  JSONL_DIR="$_JSONL_DIR_NEW"
else
  JSONL_DIR="$_JSONL_DIR_OLD"
fi

mkdir -p "$(dirname "$LOG_FILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)

# 写入 tmux会话→JSONL 映射（供 Claude Office 精确关联日志）
_write_session_map() {
  local session="$1"
  local jsonl="$2"
  python3 -c "
import json, os
f='${SESSION_MAP}'
m = json.load(open(f)) if os.path.exists(f) else {}
m['${session}'] = '${jsonl}'
json.dump(m, open(f,'w'))
" 2>/dev/null
}

# 启动后等待新 JSONL 出现并写入映射（跳过已被其他会话占用的 JSONL）
_associate_jsonl() {
  local session="$1"
  local before_list="$2"   # 启动前的 JSONL 列表（换行分隔）
  local max_wait=40
  local elapsed=0
  while [ $elapsed -lt $max_wait ]; do
    sleep 2; elapsed=$((elapsed+2))
    # 读取已占用的 JSONL（其他会话已写入映射的）
    local claimed
    claimed=$(python3 -c "
import json,os
f='${SESSION_MAP}'
if os.path.exists(f):
    m=json.load(open(f))
    for k,v in m.items():
        if k != '${session}': print(v)
" 2>/dev/null)
    # 找新出现且未被占用的 JSONL
    local new_jsonl
    new_jsonl=$(ls -1t "${JSONL_DIR}"/*.jsonl 2>/dev/null \
      | while read -r f; do
          echo "$before_list" | grep -qxF "$f" && continue   # 启动前已存在
          echo "$claimed"    | grep -qxF "$f" && continue   # 已被其他会话占用
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

# 启动单个经理CC（幂等，会话存在则跳过）
start_manager() {
  local ROLE="$1"      # 排程经理 | 研发经理
  local LOOP_PROMPT="$2"
  local MODEL="${3:-claude-sonnet-4-6}"   # 默认 Sonnet 4.6；调用方可显式传 Haiku
  local SESSION="manager-${ROLE}"

  if tmux has-session -t "$SESSION" 2>/dev/null; then
    log "✓ ${ROLE} 运行中 (${SESSION})，跳过"
    return 0
  fi

  log "启动 ${ROLE} → ${SESSION}"

  # 记录启动前已有的 JSONL 列表
  local BEFORE_LIST
  BEFORE_LIST=$(ls -1 "${JSONL_DIR}"/*.jsonl 2>/dev/null | sort)

  # 隔离 claude config（使用真实订阅凭证）
  local CONFIG_DIR="/tmp/cc-config-${SESSION}"
  mkdir -p "$CONFIG_DIR"
  rsync -a --exclude='projects' \
    "${HOME_DIR}/.claude/" "$CONFIG_DIR/" 2>/dev/null
  ln -sfn "${HOME_DIR}/.claude/projects" "$CONFIG_DIR/projects"
  [ -f "${HOME_DIR}/.claude.json" ] && cp "${HOME_DIR}/.claude.json" "$CONFIG_DIR/.claude.json"

  # 加载共享 skill 到工作目录
  mkdir -p "$GITHUB_DIR/.claude/skills"
  SHARED_SKILLS="${GITHUB_DIR}/agents/shared"
  if [ -d "$SHARED_SKILLS" ]; then
    for skill_dir in "$SHARED_SKILLS"/*/; do
      [ -f "${skill_dir}SKILL.md" ] || continue
      ln -sfn "${skill_dir%/}" "$GITHUB_DIR/.claude/skills/$(basename "$skill_dir")"
    done
  fi

  tmux new-session -d -s "$SESSION" -c "$GITHUB_DIR" \
    "export GH_TOKEN=${GH_TOKEN}; \
     export HOME=${HOME_DIR}; \
     export PATH=${HOME_DIR}/.local/bin:\$PATH; \
     unset ANTHROPIC_API_KEY; unset ANTHROPIC_BASE_URL; \
     export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1; \
     export CLAUDE_CONFIG_DIR=${CONFIG_DIR}; \
     claude --model ${MODEL} --dangerously-skip-permissions; \
     rm -rf ${CONFIG_DIR}; exec bash"

  # 等待 Claude Code CLI 初始化并关联 JSONL（后台执行，不阻塞下一个经理启动）
  # ASSOC_DELAY：第几个经理*5秒，错开竞争窗口
  local ASSOC_DELAY=$(( $(grep -c 'start_manager' "$0" 2>/dev/null || echo 2) * 0 ))
  _MANAGER_START_SEQ=$(( ${_MANAGER_START_SEQ:-0} + 1 ))
  local MY_DELAY=$(( (_MANAGER_START_SEQ - 1) * 8 ))
  ( sleep 6
    tmux send-keys -t "$SESSION" "$LOOP_PROMPT" Enter
    sleep "$MY_DELAY"   # 错开：第1个0秒延迟，第2个8秒延迟
    _associate_jsonl "$SESSION" "$BEFORE_LIST"
  ) &

  log "✓ ${ROLE} 已启动 (model=${MODEL})，JSONL关联中..."
}

# 排程经理：结构化清单驱动 → Haiku 4.5（速度快、token 省）
start_manager "排程经理" "\\loop 10m 你是排程经理，按 agents/manager/scheduler-guide.md 执行本轮巡检" "claude-haiku-4-5-20251001"
# 研发经理：W1+W2+W3 改造后任务二瘦身为 attention-only，Done Guard 硬隔离 → Haiku 4.5
start_manager "研发经理" "\\loop 10m 你是研发经理，按 agents/manager/assign-guide.md 执行本轮任务" "claude-haiku-4-5-20251001"
