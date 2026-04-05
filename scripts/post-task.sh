#!/bin/bash
# post-task.sh — 统一版：编程CC完成后自动评论Issue+创建PR
# 由CI/CD在feature分支push后调用
# 位置: .github/scripts/post-task.sh
set -e

REPO_FULL="${REPO_FULL:-WnadeyaowuOraganization/wande-play}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

log() { echo -e "\033[0;32m>>> $1\033[0m"; }
warn() { echo -e "\033[1;33m>>> $1\033[0m"; }

# Step 1: 提取Issue号
log "Step 1: 提取Issue号..."
ISSUE_NUM=$(git log -1 --pretty=%s | grep -oP '#\K\d+' | head -1)
if [ -z "$ISSUE_NUM" ]; then
    warn "未从commit message中找到Issue号，跳过post-task"
    exit 0
fi
log "Issue: #$ISSUE_NUM, Branch: $BRANCH, Repo: $REPO_FULL"

# Step 2: 提取完成报告
log "Step 2: 提取完成报告..."
# 在monorepo中task.md可能在backend/issues/或frontend/issues/或根issues/
TASK_FILE=""
for dir in "./issues/issue-${ISSUE_NUM}" "./backend/issues/issue-${ISSUE_NUM}" "./frontend/issues/issue-${ISSUE_NUM}" "./pipeline/issues/issue-${ISSUE_NUM}"; do
    if [ -f "$dir/task.md" ]; then
        TASK_FILE="$dir/task.md"
        break
    fi
done

REPORT_FILE="/tmp/post_task_report_${ISSUE_NUM}.md"
if [ -n "$TASK_FILE" ]; then
    log "找到 $TASK_FILE"
    tail -50 "$TASK_FILE" | head -c 4000 > "$REPORT_FILE"
else
    warn "未找到task.md，使用commit message"
    git log -1 --pretty=%B > "$REPORT_FILE"
fi

# Step 3: 评论Issue
log "Step 3: 评论Issue #$ISSUE_NUM..."
gh issue comment "$ISSUE_NUM" --repo "$REPO_FULL" --body-file "$REPORT_FILE" 2>/dev/null || warn "评论失败"

# Step 4: 创建PR
log "Step 4: 创建PR ($BRANCH → dev)..."
EXISTING=$(gh pr list --repo "$REPO_FULL" --head "$BRANCH" --base dev --state open --json number --jq '.[0].number' 2>/dev/null || echo "")
if [ -n "$EXISTING" ]; then
    log "PR #$EXISTING 已存在"
else
    PR_TITLE=$(git log -1 --pretty=%s)
    # 注意：PR merge到dev分支不会自动关闭issue（dev不是默认分支）
    # sync-issue-closed.yml workflow会在issue手动关闭时同步看板状态
    gh pr create --repo "$REPO_FULL" --base dev --head "$BRANCH" \
        --title "$PR_TITLE" \
        --body "关联Issue: Closes #${ISSUE_NUM}

由CI/CD post-task自动创建。测试CC将在下一个周期执行E2E测试。

**注意**: PR merge到dev后，需要手动关闭issue或等待merge到main。" \
        2>/dev/null && log "PR创建成功" || warn "PR创建失败"
fi

rm -f "$REPORT_FILE"
log "post-task 完成 ✅"
