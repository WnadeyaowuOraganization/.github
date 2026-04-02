#!/bin/bash
# ==============================================================
# post-task.sh — 编程CC完成后的自动化收尾脚本（统一版本）
# 由CI/CD在feature分支push后自动调用
# 功能：提取task.md完成报告 → 评论Issue → 创建feature→dev PR
# 支持rate limit时自动切换备用token
# ==============================================================
set -e

# 加载token管理库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/get-gh-token.sh"

# ===================== 参数 =====================
REPO_FULL="${REPO_FULL:-}"          # 如 WnadeyaowuOraganization/wande-ai-backend
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}" # 项目根目录
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
log() { echo -e "${GREEN}>>> $1${NC}"; }
warn() { echo -e "${YELLOW}>>> $1${NC}"; }
error() { echo -e "${RED}>>> $1${NC}"; }

# ===================== Step 1: 提取Issue号 =====================
log "Step 1: 提取Issue号..."

ISSUE_NUM=$(git log -1 --pretty=%s | grep -oP '#\K\d+' | head -1)

if [ -z "$ISSUE_NUM" ]; then
    warn "未从commit message中找到Issue号（格式: feat(x): xxx #123），跳过post-task"
    exit 0
fi

log "Issue: #$ISSUE_NUM, Branch: $BRANCH, Repo: $REPO_FULL"

# ===================== Step 2: 提取完成报告 =====================
log "Step 2: 提取完成报告..."

TASK_FILE="${PROJECT_DIR}/issues/issue-${ISSUE_NUM}/task.md"
REPORT_FILE="/tmp/post_task_report_${ISSUE_NUM}.md"

if [ -f "$TASK_FILE" ]; then
    log "找到 $TASK_FILE，提取完成报告"
    tail -50 "$TASK_FILE" | head -c 4000 > "$REPORT_FILE"
else
    warn "未找到task.md，使用commit message作为报告"
    git log -1 --pretty=%B > "$REPORT_FILE"
fi

# ===================== Step 3: 评论Issue =====================
log "Step 3: 评论Issue #$ISSUE_NUM..."

# 初始化token
init_tokens

# 评论函数（带备用token）
comment_issue() {
    local token="$1"
    GH_TOKEN="$token" gh issue comment "$ISSUE_NUM" \
        --repo "$REPO_FULL" \
        --body-file "$REPORT_FILE" 2>&1
}

RESULT=$(comment_issue "$MAIN_TOKEN")

# 检查是否rate limit
if echo "$RESULT" | grep -qi "rate.limit"; then
    warn "主token rate limit，切换备用token评论..."
    comment_issue "$BACKUP_TOKEN" > /dev/null || warn "评论失败（可能Issue已关闭）"
fi

# ===================== Step 4: 创建PR =====================
log "Step 4: 创建PR ($BRANCH → dev)..."

# 检查是否已有PR
check_existing_pr() {
    local token="$1"
    GH_TOKEN="$token" gh pr list --repo "$REPO_FULL" \
        --head "$BRANCH" --base dev --state open \
        --json number --jq '.[0].number' 2>/dev/null || echo ""
}

EXISTING=$(check_existing_pr "$MAIN_TOKEN")

# 检查rate limit
if echo "$EXISTING" | grep -qi "rate.limit"; then
    EXISTING=$(check_existing_pr "$BACKUP_TOKEN")
fi

if [ -n "$EXISTING" ] && [ "$EXISTING" != "" ]; then
    log "PR #$EXISTING 已存在，跳过创建"
else
    PR_TITLE=$(git log -1 --pretty=%s)

    # 创建PR函数（带备用token）
    create_pr() {
        local token="$1"
        GH_TOKEN="$token" gh pr create --repo "$REPO_FULL" \
            --base dev --head "$BRANCH" \
            --title "$PR_TITLE" \
            --body "## 自动创建的PR

关联Issue: Fixes #${ISSUE_NUM}

由CI/CD post-task自动创建。测试CC将在下一个周期执行E2E测试。

🤖 Generated with [Claude Code](https://claude.com/claude-code)
" 2>&1
    }

    RESULT=$(create_pr "$MAIN_TOKEN")

    # 检查是否rate limit
    if echo "$RESULT" | grep -qi "rate.limit"; then
        warn "主token rate limit，切换备用token创建PR..."
        RESULT=$(create_pr "$BACKUP_TOKEN")
    fi

    if echo "$RESULT" | grep -q "github.com"; then
        log "PR创建成功: $(echo "$RESULT" | grep -o 'https://.*')"
    else
        warn "PR创建失败: $RESULT"
    fi
fi

# ===================== 清理 =====================
rm -f "$REPORT_FILE"
log "post-task 完成 ✅"