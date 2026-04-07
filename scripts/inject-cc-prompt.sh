#!/bin/bash
# inject-cc-prompt.sh — 向指定Issue的CC会话注入提示词
# 用法: bash inject-cc-prompt.sh <issue_number> <prompt>
# 由CI失败时调用，让CC直接在现有会话中修复问题

ISSUE=$1
PROMPT=$2
HOME_DIR="${HOME_DIR:-/home/ubuntu}"

if [ -z "$ISSUE" ] || [ -z "$PROMPT" ]; then
  echo "用法: $0 <issue_number> <prompt>"
  exit 1
fi

SESSION=""
for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
  [ ! -f "$dir/.cc-lock" ] && continue
  LOCK_ISSUE=$(grep "^issue=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  [ "$LOCK_ISSUE" != "$ISSUE" ] && continue
  DIRNAME=$(basename "$dir")
  SESSION="cc-${DIRNAME}-${ISSUE}"
  break
done

if [ -z "$SESSION" ]; then
  echo "[inject] 未找到 Issue #$ISSUE 对应的CC会话，跳过注入"
  exit 0
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[inject] 会话 $SESSION 不存在，跳过注入"
  exit 0
fi

echo "[inject] → $SESSION"
tmux send-keys -t "$SESSION" "$PROMPT" Enter
echo "[inject] ✅ 已注入提示词"
