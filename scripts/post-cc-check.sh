#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# post-cc-check.sh — CC退出后自动检查产出，确保工作成果不丢失
#
# 处理逻辑:
#   有未commit改动 → commit+push+PR
#   有commit未push → push+PR
#   已push无PR → 创建PR
#   无任何改动 → Issue回退Todo
#   以上步骤失败 → 重新触发CC继续（最多3次）

# 参数解析
BASE_DIR="" ; ISSUE="0" ; GH_REPO="none" ; MODE="issue"
SCRIPT_DIR="" ; DIR="" ; MODEL="" ; EFFORT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --base-dir)   BASE_DIR="$2"; shift 2 ;;
    --issue)      ISSUE="$2"; shift 2 ;;
    --repo)       GH_REPO="$2"; shift 2 ;;
    --mode)       MODE="$2"; shift 2 ;;
    --script-dir) SCRIPT_DIR="$2"; shift 2 ;;
    --dir)        DIR="$2"; shift 2 ;;
    --model)      MODEL="$2"; shift 2 ;;
    --effort)     EFFORT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# prompt模式不做检查
[ "$MODE" != "issue" ] && exit 0
[ "$ISSUE" = "0" ] && exit 0

log() { echo "[post-check] $1"; }

cd "$BASE_DIR" || exit 0
BRANCH="feature-Issue-${ISSUE}"

log "CC退出，检查Issue#${ISSUE}产出..."

# === Step 1: 检查是否有未commit的改动 ===
UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -v "^issues/" | wc -l)

if [ "$((UNSTAGED + UNTRACKED))" -gt 0 ]; then
  log "发现${UNSTAGED}个未暂存+${UNTRACKED}个未跟踪文件，自动commit"
  git add -A 2>/dev/null
  git commit -m "feat: Issue #${ISSUE} 自动提交（CC异常退出恢复）" 2>/dev/null
  if [ $? -ne 0 ]; then
    log "commit失败，触发CC重试"
    bash "$SCRIPT_DIR/run-cc.sh" --module backend --issue "$ISSUE" --dir "$DIR" --effort "${EFFORT:-medium}" 2>/dev/null &
    exit 0
  fi
fi

# === Step 2: 检查是否有diff vs dev ===
DIFF_COUNT=$(git diff --stat dev..HEAD 2>/dev/null | grep "files\? changed" | grep -oP "\d+" | head -1)

if [ "${DIFF_COUNT:-0}" -eq 0 ]; then
  log "无代码变更，回退Issue#${ISSUE}到Todo"
  bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Todo" 2>/dev/null
  exit 0
fi

log "${DIFF_COUNT}个文件变更"

# === Step 3: push ===
git push origin "$BRANCH" 2>/dev/null
if [ $? -ne 0 ]; then
  # push失败，可能需要rebase
  log "push失败，尝试rebase后重试"
  git fetch origin dev 2>/dev/null
  export GIT_EDITOR=true
  if git rebase origin/dev 2>/dev/null; then
    git push --force-with-lease origin "$BRANCH" 2>/dev/null
  else
    git rebase --abort 2>/dev/null
    log "rebase失败，触发CC重试修复冲突"
    bash "$SCRIPT_DIR/run-cc.sh" --module backend --issue "$ISSUE" --dir "$DIR" --effort "${EFFORT:-medium}" 2>/dev/null &
    exit 0
  fi
fi

# === Step 4: 创建PR ===
EXISTING_PR=$(gh pr list --repo "$GH_REPO" --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null)
if [ -z "$EXISTING_PR" ] || [ "$EXISTING_PR" = "null" ]; then
  TITLE=$(git log -1 --pretty=%s)
  gh pr create --repo "$GH_REPO" --base dev --head "$BRANCH" \
    --title "$TITLE" --body "Fixes #${ISSUE}" 2>/dev/null
  if [ $? -eq 0 ]; then
    log "✅ PR创建成功"
  else
    log "PR创建失败（可能与dev无diff），回退Todo"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Todo" 2>/dev/null
  fi
else
  log "✅ PR#${EXISTING_PR}已存在"
fi
