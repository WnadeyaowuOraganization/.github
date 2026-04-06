#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# post-cc-check.sh — cron定时巡检：检测CC异常退出并恢复
# 用法: cron每5分钟执行
# 逻辑: 扫描所有.cc-lock，无claude进程则恢复（commit→push→PR），10次重试后标Fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_RETRY=10

if [ -z "$GH_TOKEN" ]; then
  export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)
fi

log() { echo "[recovery] $1"; }

for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
  [ ! -f "$dir/.cc-lock" ] && continue

  ISSUE=$(grep "^issue=" "$dir/.cc-lock" | cut -d= -f2)
  MODULE=$(grep "^module=" "$dir/.cc-lock" | cut -d= -f2)
  DIR_SUFFIX=$(grep "^dir=" "$dir/.cc-lock" | cut -d= -f2)
  MODEL=$(grep "^model=" "$dir/.cc-lock" | cut -d= -f2)
  EFFORT=$(grep "^effort=" "$dir/.cc-lock" | cut -d= -f2)
  RETRY=$(grep "^retry_count=" "$dir/.cc-lock" | cut -d= -f2)
  RETRY=${RETRY:-0}
  DIRNAME=$(basename "$dir")

  [ -z "$ISSUE" ] && continue

  # 检查是否有claude进程在该目录运行
  HAS_PROCESS=false
  for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^cc-"); do
    if echo "$session" | grep -q "$DIRNAME"; then
      pane_pid=$(tmux list-panes -t "$session" -F "#{pane_pid}" 2>/dev/null | head -1)
      if [ -n "$pane_pid" ] && ps --ppid "$pane_pid" -o comm= 2>/dev/null | grep -q "claude"; then
        HAS_PROCESS=true
        break
      fi
    fi
  done

  [ "$HAS_PROCESS" = "true" ] && continue

  # === 无进程，需要恢复 ===
  log "$DIRNAME Issue#$ISSUE: CC不在运行，检查产出 (retry=$RETRY)"

  # 重试次数检查
  if [ "$RETRY" -ge "$MAX_RETRY" ]; then
    log "$DIRNAME Issue#$ISSUE: 已重试${MAX_RETRY}次，标记Fail"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Fail" 2>/dev/null
    gh issue comment "$ISSUE" --repo WnadeyaowuOraganization/wande-play \
      --body "❌ CC自动恢复失败：已重试${MAX_RETRY}次，标记为Fail。目录: $DIRNAME" 2>/dev/null || true
    rm -f "$dir/.cc-lock"
    cd "$dir" && git checkout dev 2>/dev/null && git branch -D "feature-Issue-${ISSUE}" 2>/dev/null
    continue
  fi

  cd "$dir"
  NEW_RETRY=$((RETRY + 1))

  # Step 1: 有未commit改动？自动commit
  UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -cv "^issues/" 2>/dev/null)

  if [ "$((UNSTAGED + UNTRACKED))" -gt 0 ]; then
    log "$DIRNAME Issue#$ISSUE: ${UNSTAGED}个未暂存+${UNTRACKED}个未跟踪，自动commit"
    git add -A 2>/dev/null
    git commit -m "feat: Issue #${ISSUE} 自动提交（CC退出恢复 retry=${NEW_RETRY}）" 2>/dev/null
  fi

  # Step 2: 检查vs dev有没有diff
  DIFF_COUNT=$(git diff --stat dev..HEAD 2>/dev/null | grep "files\? changed" | grep -oP "\d+" | head -1)

  if [ "${DIFF_COUNT:-0}" -eq 0 ]; then
    log "$DIRNAME Issue#$ISSUE: 无代码变更，state=NO_CHANGES"
    sed -i "s/^state=.*/state=NO_CHANGES/" "$dir/.cc-lock"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Todo" 2>/dev/null
    rm -f "$dir/.cc-lock"
    git checkout dev 2>/dev/null && git branch -D "feature-Issue-${ISSUE}" 2>/dev/null
    continue
  fi

  # Step 3: push（保证代码不丢失）
  git push origin "feature-Issue-${ISSUE}" 2>/dev/null || \
    git push --force-with-lease origin "feature-Issue-${ISSUE}" 2>/dev/null

  # Step 4: 更新锁状态+重试次数
  sed -i "s/^state=.*/state=SAVED/" "$dir/.cc-lock"
  sed -i "s/^retry_count=.*/retry_count=${NEW_RETRY}/" "$dir/.cc-lock"

  if [ $? -eq 0 ]; then
    log "$DIRNAME Issue#$ISSUE: ✅ state=SAVED, retry=${NEW_RETRY}"
  else
    log "$DIRNAME Issue#$ISSUE: push失败, retry=${NEW_RETRY}"
  fi
done
