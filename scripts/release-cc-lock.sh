#!/bin/bash
# release-cc-lock.sh — PR合并到dev后，停止对应CC tmux会话并释放目录锁
# 用法: bash release-cc-lock.sh <issue_number>
# 由 release-cc-lock.yml workflow 在 PR merged 时调用

set -e

ISSUE=$1
HOME_DIR="${HOME_DIR:-/home/ubuntu}"

if [ -z "$ISSUE" ]; then
  echo "用法: $0 <issue_number>"
  exit 1
fi

echo "[release-cc-lock] 处理 Issue #$ISSUE"

FOUND=false

for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
  [ ! -f "$dir/.cc-lock" ] && continue

  LOCK_ISSUE=$(grep "^issue=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  [ "$LOCK_ISSUE" != "$ISSUE" ] && continue

  DIRNAME=$(basename "$dir")
  SESSION="cc-${DIRNAME}-${ISSUE}"

  # 停止 tmux 会话
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION" 2>/dev/null
    echo "[release-cc-lock] ✅ 已停止会话: $SESSION"
  else
    echo "[release-cc-lock] 会话不存在（已停止）: $SESSION"
  fi

  # 释放目录锁
  rm -f "$dir/.cc-lock"
  echo "[release-cc-lock] ✅ 已释放锁: $dir/.cc-lock"

  # 切回 dev 分支
  cd "$dir" && git checkout dev 2>/dev/null && echo "[release-cc-lock] ✅ 已切回 dev 分支"

  FOUND=true
  break
done

if [ "$FOUND" = "false" ]; then
  echo "[release-cc-lock] 未找到 Issue #$ISSUE 对应的锁文件（可能已释放）"
fi
