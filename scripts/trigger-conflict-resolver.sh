#!/bin/bash
# trigger-conflict-resolver.sh — 触发 CC 解决 PR 冲突
# 用法: bash scripts/trigger-conflict-resolver.sh <pr_number>
#
# 设计思路：
# 1. 检测 PR 冲突类型
# 2. 将冲突信息写入 issues/issue-xxx/conflict.md
# 3. 在 wande-play-ci 目录触发 CC
# 4. CC 分析冲突并智能解决

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)

PR_NUMBER=$1

if [ -z "$PR_NUMBER" ]; then
    echo "用法: $0 <pr_number>"
    exit 1
fi

# 获取 PR 信息
PR_INFO=$(gh api "repos/WnadeyaowuOraganization/wande-play/pulls/$PR_NUMBER" --jq '.head.ref, .base.ref, .title, .body' 2>/dev/null)
HEAD_REF=$(echo "$PR_INFO" | head -1)
BASE_REF=$(echo "$PR_INFO" | sed -n '2p')
TITLE=$(echo "$PR_INFO" | sed -n '3p')

echo "=== PR #$PR_NUMBER 信息 ==="
echo "分支: $HEAD_REF -> $BASE_REF"
echo "标题: $TITLE"

# 切换到 CI 目录
CI_DIR="/home/ubuntu/projects/wande-play-ci"
cd "$CI_DIR"

# 更新 dev 分支
git fetch origin dev
git checkout dev
git reset --hard origin/dev
git clean -fd

# Checkout PR 分支
git fetch origin "$HEAD_REF"
git checkout -B "conflict-resolve-$PR_NUMBER" "origin/$HEAD_REF"

# 尝试 rebase 获取冲突信息
echo ""
echo "=== 检测冲突 ==="
if git rebase origin/dev 2>&1 | grep -q "Successfully rebased"; then
    echo "无冲突，可以直接合并"
    git push --force origin "conflict-resolve-$PR_NUMBER"
    gh pr merge $PR_NUMBER --repo WnadeyaowuOraganization/wande-play --squash --delete-branch
    exit 0
fi

# 有冲突，收集信息
CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
CONFLICT_COUNT=$(echo "$CONFLICT_FILES" | wc -l)

echo "发现 $CONFLICT_COUNT 个冲突文件:"
echo "$CONFLICT_FILES"

# 分析冲突类型
SIMPLE_FILES=""
COMPLEX_FILES=""

for file in $CONFLICT_FILES; do
    if [[ "$file" == *"schema.sql"* ]] || [[ "$file" == *"test/"* ]] || [[ "$file" == *"pom.xml"* ]]; then
        SIMPLE_FILES="$SIMPLE_FILES$file\n"
    else
        COMPLEX_FILES="$COMPLEX_FILES$file\n"
    fi
done

echo ""
echo "=== 冲突分类 ==="
echo "简单冲突（可自动解决）:"
echo -e "$SIMPLE_FILES"
echo "复杂冲突（需要 CC 处理）:"
echo -e "$COMPLEX_FILES"

# 创建冲突信息文件
mkdir -p "issues/issue-pr-$PR_NUMBER"
cat > "issues/issue-pr-$PR_NUMBER/conflict.md" << EOF
# PR #$PR_NUMBER 合并冲突

## 基本信息
- PR: #$PR_NUMBER
- 标题: $TITLE
- 分支: $HEAD_REF -> $BASE_REF

## 冲突文件 ($CONFLICT_COUNT 个)

### 简单冲突（自动解决）
\`\`\`
$SIMPLE_FILES
\`\`\`

### 复杂冲突（需要智能解决）
\`\`\`
$COMPLEX_FILES
\`\`\`

## 任务
1. 解决上述冲突文件
2. 确保合并后代码编译通过
3. 不要丢失任何功能代码
4. 完成后推送并通知
EOF

# 如果只有简单冲突，自动解决
if [ -z "$COMPLEX_FILES" ]; then
    echo "只有简单冲突，自动解决..."
    for file in $CONFLICT_FILES; do
        git checkout --theirs "$file" 2>/dev/null || true
        git add "$file" 2>/dev/null || true
    done
    git rebase --continue
    git push --force origin "conflict-resolve-$PR_NUMBER"
    echo "✅ 已解决并推送"
    exit 0
fi

# 有复杂冲突，触发 CC
echo ""
echo "=== 触发 CC 解决复杂冲突 ==="

# 生成 prompt
PROMPT="解决 PR #$PR_NUMBER 的合并冲突

## 背景
PR 标题: $TITLE
分支: $HEAD_REF -> dev

## 冲突文件
有 $CONFLICT_COUNT 个冲突文件，其中复杂冲突需要智能解决。

## 任务
1. 阅读 issues/issue-pr-$PR_NUMBER/conflict.md 了解冲突详情
2. 对每个冲突文件，理解双方修改意图
3. 智能合并，不要丢失任何功能代码
4. 运行编译测试确保代码正确
5. 提交并推送

## 当前目录
$CI_DIR

## 当前分支
conflict-resolve-$PR_NUMBER"

# 触发 CC
bash "$SCRIPT_DIR/run-cc.sh" --prompt "conflict-resolver" "$PROMPT" "claude-opus-4-6" "ci" "high"

echo ""
echo "CC 已触发，等待处理完成..."
