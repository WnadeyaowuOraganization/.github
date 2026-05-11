#!/bin/bash
# check-conflict.sh — 检测 PR 是否冲突，有则自动合并，并设置 FORCE_FULL_BUILD flag
set -e

PR_NUM="${1}"
REPO="${2:-WnadeyaowuOraganization/wande-play}"
JENKINS_DIR="${3:-/data/home/ubuntu/projects/.github/jenkins}"
CI_WORK_DIR="${4:-/home/ubuntu/projects/wande-play-ci}"
export GH_TOKEN WEIPING_TOKEN REPO

if [ -z "$PR_NUM" ]; then
    echo "PR_NUMBER not provided (push event), skipping conflict check"
    exit 0
fi

MERGEABLE=$(gh pr view "$PR_NUM" --repo "$REPO" --json mergeable --jq '.mergeable')
echo "PR #${PR_NUM} mergeable: $MERGEABLE"

if [ "$MERGEABLE" = "CONFLICTING" ]; then
    echo "PR #${PR_NUM} has conflict, auto-resolving..."
    bash "${JENKINS_DIR}/cycle-merge.sh" "$PR_NUM" || true
    echo "Waiting for GitHub to refresh mergeability..."
    sleep 30
fi

# 检测 working tree 中是否仍有未解决的冲突标记（find + grep，避免正则表达式冲突）
CONFLICT_FILES=$(find "${CI_WORK_DIR}/frontend" "${CI_WORK_DIR}/backend" \
    \( -name "*.ts" -o -name "*.java" -o -name "*.vue" -o -name "*.xml" -o -name "*.yaml" -o -name "*.yml" \) \
    -exec grep -l "<<<<<<" {} \; 2>/dev/null || echo "")

if [ -n "$CONFLICT_FILES" ]; then
    echo "WARNING: Working tree still has unresolved conflict markers — forcing full build"
    echo "FORCE_FULL_BUILD=true" > "${CI_WORK_DIR}/.build_env"
fi
