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

  # 释放临时 maven repo（优先从 lock 文件读 m2_repo 字段，找不到则按 KIMI_TAG 兜底）
  M2_REPO_FROM_LOCK=$(grep "^m2_repo=" "$lockfile" 2>/dev/null | cut -d= -f2-)
  KIMI_TAG=$(echo "$DIRNAME" | sed 's/^wande-play-//')
  SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
  if [ -n "$M2_REPO_FROM_LOCK" ] && [[ "$M2_REPO_FROM_LOCK" == /dev/shm/* ]]; then
    # 直接 rm 锁里记录的路径（避免 KIMI_TAG 推算错）
    PARENT_DIR=$(dirname "$M2_REPO_FROM_LOCK")
    [ -d "$PARENT_DIR" ] && rm -rf "$PARENT_DIR" && echo "[release-cc-lock] ✅ 释放 maven repo: $PARENT_DIR"
    # 同时 refcount -1 / 可能释放 base
    if [ -x "$SCRIPT_DIR/m2-cc-cleanup.sh" ]; then
      bash "$SCRIPT_DIR/m2-cc-cleanup.sh" "$KIMI_TAG" 2>&1 | sed 's/^/[release-cc-lock] /'
    fi
  elif [ -x "$SCRIPT_DIR/m2-cc-cleanup.sh" ]; then
    bash "$SCRIPT_DIR/m2-cc-cleanup.sh" "$KIMI_TAG" 2>&1 | sed 's/^/[release-cc-lock] /'
  fi

  FOUND=true
  break
done

if [ "$FOUND" = "false" ]; then
  echo "[release-cc-lock] 未找到 Issue #$ISSUE 对应的锁文件（可能已释放）"
fi
