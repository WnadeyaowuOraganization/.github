#!/bin/bash
# resolve-pr-conflicts.sh — 批量解决 PR 合并冲突
# 用法: bash scripts/resolve-pr-conflicts.sh <pr_number> <dir_suffix>
# 例如: bash scripts/resolve-pr-conflicts.sh 2863 kimi18

set -e

PR_NUMBER=$1
DIR_SUFFIX=$2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)

if [ -z "$PR_NUMBER" ] || [ -z "$DIR_SUFFIX" ]; then
    echo "用法: $0 <pr_number> <dir_suffix>"
    exit 1
fi

WORK_DIR="/home/ubuntu/projects/wande-play-$DIR_SUFFIX"

if [ ! -d "$WORK_DIR" ]; then
    echo "错误: 目录 $WORK_DIR 不存在"
    exit 2
fi

echo "=== 处理 PR #$PR_NUMBER 在 $WORK_DIR ==="

cd "$WORK_DIR"

# 获取 PR 信息
PR_INFO=$(gh api "repos/WnadeyaowuOraganization/wande-play/pulls/$PR_NUMBER" --jq '.head.ref, .title' 2>/dev/null)
BRANCH=$(echo "$PR_INFO" | head -1)
TITLE=$(echo "$PR_INFO" | tail -1)

echo "分支: $BRANCH"
echo "标题: $TITLE"

# 检查当前分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "切换到分支 $BRANCH"
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH"
fi

# 获取最新 dev
echo "获取最新 dev 分支..."
git fetch origin dev

# 尝试 rebase
echo "Rebase 到 origin/dev..."
if git rebase origin/dev 2>&1; then
    echo "Rebase 成功，无冲突"
    echo "推送..."
    git push --force-with-lease origin "$BRANCH"
    echo "✅ PR #$PR_NUMBER 已解决"
    exit 0
fi

# 有冲突
echo "检测到冲突，检查冲突文件..."
CONFLICT_FILES=$(git diff --name-only --diff-filter=U)

echo "冲突文件:"
echo "$CONFLICT_FILES"

# 对所有冲突文件使用 theirs 策略（保留 dev 版本）
for file in $CONFLICT_FILES; do
    echo "解决冲突: $file (使用 dev 版本)"
    git checkout --theirs "$file" 2>/dev/null || git checkout --ours "$file" 2>/dev/null
    git add "$file"
done

git rebase --continue

# 再次检查是否有更多冲突
while git diff --name-only --diff-filter=U 2>/dev/null | grep -q .; do
    echo "还有冲突..."
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    for file in $CONFLICT_FILES; do
        echo "解决冲突: $file (使用 dev 版本)"
        git checkout --theirs "$file" 2>/dev/null || git checkout --ours "$file" 2>/dev/null
        git add "$file"
    done
    git rebase --continue
done

echo "推送..."
git push --force origin "$BRANCH"
echo "✅ PR #$PR_NUMBER 已解决"
