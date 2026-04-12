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
LOCK_DIR="${HOME_DIR}/cc_scheduler/lock"

# 2026-04-09: lock 路径迁移到 ${LOCK_DIR}/<dirname>.lock
for lockfile in $LOCK_DIR/wande-play-kimi*.lock; do
  [ ! -f "$lockfile" ] && continue

  LOCK_ISSUE=$(grep "^issue=" "$lockfile" 2>/dev/null | cut -d= -f2)
  [ "$LOCK_ISSUE" != "$ISSUE" ] && continue

  DIRNAME=$(basename "$lockfile" .lock)   # wande-play-kimi1
  dir="${HOME_DIR}/projects/$DIRNAME"
  SESSION="cc-${DIRNAME}-${ISSUE}"

  # 停止 tmux 会话
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION" 2>/dev/null
    echo "[release-cc-lock] ✅ 已停止会话: $SESSION"
  else
    echo "[release-cc-lock] 会话不存在（已停止）: $SESSION"
  fi

  # 释放目录锁
  rm -f "$lockfile"
  echo "[release-cc-lock] ✅ 已释放锁: $lockfile"

  # 切回 dev 分支
  [ -d "$dir" ] && cd "$dir" && git checkout dev 2>/dev/null && echo "[release-cc-lock] ✅ 已切回 dev 分支"

  # Maven repo 已改为共享 ~/.m2（NVMe SSD），无需 per-kimi 清理

  FOUND=true
  break
done

if [ "$FOUND" = "false" ]; then
  echo "[release-cc-lock] 未找到 Issue #$ISSUE 对应的锁文件（可能已释放）"
fi
