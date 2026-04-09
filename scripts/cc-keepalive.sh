#!/bin/bash
# cc-keepalive.sh — CC保活巡检：检测CC进程异常退出并恢复
# cron每5分钟执行
# 策略：
#   session存在+claude运行 → 健康，跳过
#   session存在+claude不在 → 注入恢复提示词（CC自行继续）
#   session不存在（真崩溃）→ run-cc.sh重启（SAVED状态重入，feature分支继续）
# 注意：任何路径都不kill session，只有release-cc-lock.sh在部署成功后kill

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# GH_TOKEN已由caller设置（cron环境或手动调用），或自动获取
[ -n "$GH_TOKEN" ] || export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)

log() { echo "[cc-check] $1"; }

# 2026-04-09: lock 文件迁移到 /home/ubuntu/cc_scheduler/lock/<dirname>.lock
LOCK_DIR="${HOME_DIR}/cc_scheduler/lock"

for lockfile in $LOCK_DIR/wande-play-kimi*.lock; do
  [ ! -f "$lockfile" ] && continue

  KIMI_NAME=$(basename "$lockfile" .lock)   # wande-play-kimi1
  dir="${HOME_DIR}/projects/$KIMI_NAME"
  [ ! -d "$dir" ] && continue

  ISSUE=$(grep "^issue=" "$lockfile" | cut -d= -f2)
  MODULE=$(grep "^module=" "$lockfile" | cut -d= -f2)
  DIR_SUFFIX=$(grep "^dir=" "$lockfile" | cut -d= -f2)
  EFFORT=$(grep "^effort=" "$lockfile" | cut -d= -f2)
  RETRY=$(grep "^retry_count=" "$lockfile" | cut -d= -f2)
  RETRY=${RETRY:-0}
  DIRNAME=$(basename "$dir")

  [ -z "$ISSUE" ] && continue

  SESSION="cc-${DIRNAME}-${ISSUE}"

  # === 场景1：session存在，检查claude进程 ===
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    pane_pid=$(tmux list-panes -t "$SESSION" -F "#{pane_pid}" 2>/dev/null | head -1)
    if [ -n "$pane_pid" ] && ps --ppid "$pane_pid" -o comm= 2>/dev/null | grep -q "claude"; then
      # 健康运行中
      continue
    fi

    # claude进程没了，session还在 → 注入恢复提示词
    log "$DIRNAME Issue#$ISSUE: claude进程不在，注入恢复提示词"
    RECOVERY_PROMPT="检测到你的进程意外退出后恢复。请读取 ./issues/issue-${ISSUE}/task.md 确认当前进度，然后继续完成剩余工作。如果PR已创建，执行轮询等待合并的步骤。"
    tmux send-keys -t "$SESSION" "$RECOVERY_PROMPT" Enter
    continue
  fi

  # === 场景2：session不存在（真正崩溃）→ 重启 ===
  log "$DIRNAME Issue#$ISSUE: session不存在，准备重启 (retry=$RETRY)"

  # CLOSED 检查：issue已关闭则清锁退出，不重启（防止lock release链断裂时无限重试）
  ISSUE_STATE=$(gh issue view "$ISSUE" --repo WnadeyaowuOraganization/wande-play \
    --json state --jq '.state' 2>/dev/null)
  if [ "$ISSUE_STATE" = "CLOSED" ]; then
    log "$DIRNAME Issue#$ISSUE: 已CLOSED，清理锁文件，不重启"
    rm -f "$lockfile"
    cd "$dir" && git checkout dev 2>/dev/null && git branch -D "feature-Issue-${ISSUE}" 2>/dev/null
    continue
  fi

  MAX_RETRY=10
  if [ "$RETRY" -ge "$MAX_RETRY" ]; then
    log "$DIRNAME Issue#$ISSUE: 已重试${MAX_RETRY}次，标记Fail"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Fail" 2>/dev/null
    gh issue comment "$ISSUE" --repo WnadeyaowuOraganization/wande-play \
      --body "❌ CC自动恢复失败：已重试${MAX_RETRY}次，标记为Fail。目录: $DIRNAME" 2>/dev/null || true
    rm -f "$lockfile"
    cd "$dir" && git checkout dev 2>/dev/null && git branch -D "feature-Issue-${ISSUE}" 2>/dev/null
    continue
  fi

  # 更新重试次数
  NEW_RETRY=$((RETRY + 1))
  sed -i "s/^retry_count=.*/retry_count=${NEW_RETRY}/" "$lockfile"

  # run-cc.sh检测到锁存在且同Issue → SAVED状态重入，在feature分支继续
  bash "$SCRIPT_DIR/run-cc.sh" \
    --module "$MODULE" \
    --issue "$ISSUE" \
    --dir "$DIR_SUFFIX" \
    --effort "${EFFORT:-medium}" 2>/dev/null &

  log "$DIRNAME Issue#$ISSUE: 已触发重启 (retry=${NEW_RETRY})"
done
