#!/bin/bash
# set-lock-state.sh — 根据 Issue 号更新对应 lock 文件的 state 字段
# 用法: bash set-lock-state.sh <issue_number> <new_state>
#
# 场景：CI workflow 失败时标记 lock 状态，供 claude-office attention.stage 展示：
#   PR_CHECK_FAILED  — pr-test.yml（单测/构建/E2E）失败
#   DEPLOY_FAILED    — build-deploy-dev.yml 部署失败
#
# 仅修改 state 行；其他字段保持不变。找不到对应 lock 时静默退出 0（CI 不应被阻断）。

ISSUE=$1
NEW_STATE=$2
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
LOCK_DIR="${HOME_DIR}/cc_scheduler/lock"

if [ -z "$ISSUE" ] || [ -z "$NEW_STATE" ]; then
  echo "用法: $0 <issue_number> <new_state>"
  exit 1
fi

for lockfile in "$LOCK_DIR"/wande-play-kimi*.lock; do
  [ ! -f "$lockfile" ] && continue
  LOCK_ISSUE=$(grep "^issue=" "$lockfile" 2>/dev/null | cut -d= -f2)
  [ "$LOCK_ISSUE" != "$ISSUE" ] && continue

  if grep -q "^state=" "$lockfile"; then
    sed -i "s/^state=.*/state=${NEW_STATE}/" "$lockfile"
  else
    echo "state=${NEW_STATE}" >> "$lockfile"
  fi
  echo "[set-lock-state] ✅ $(basename "$lockfile") state → $NEW_STATE"
  exit 0
done

echo "[set-lock-state] 未找到 Issue #$ISSUE 的 lock 文件（可能已释放），跳过"
exit 0
