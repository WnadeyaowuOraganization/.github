#!/bin/bash
# jenkins-failure-handler.sh — CI 失败时提取错误日志并注入对应 CC
# 注意：必须用 bash 运行（Jenkins 默认 sh 不支持某些特性）
set -o pipefail
set +e

PR_NUMBER="${FAIL_PR_NUM:-}"
BUILD_URL="${FAIL_BUILD_URL:-}"
REPO="${REPO:-WnadeyaowuOraganization/wande-play}"
GH_TOKEN="${WEIPING_TOKEN:-$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)}"
SCRIPTS_DIR="/data/home/ubuntu/projects/.github/scripts"

if [ -z "$PR_NUMBER" ]; then
    echo "[failure-handler] PR number not set, skipping"
    exit 0
fi

echo "[failure-handler] PR #$PR_NUMBER ($BUILD_URL)"

# 1. PR 评论
gh pr comment "$PR_NUMBER" --repo "$REPO" \
    --body "🤖 **CI 构建失败**

> **构建地址**: [${BUILD_URL}](${BUILD_URL})
> **处理建议**: 请检查失败原因，修复后重新 push 触发 CI

---
*由 Jenkins CI 自动生成*" 2>/dev/null || true

# 2. 提取失败节点日志（过滤 Jenkins pipeline 噪音）
ERROR_LOG=$(curl -sf "${BUILD_URL}consoleText" 2>/dev/null | \
    grep -viE '^\[Pipeline\]|^\s*ha://|^\[8mha|Downloading|Progress|Downloaded' | \
    grep -iE 'error:|ERROR|FAIL|BUILD FAILURE|cannot find|Unexpected token|Tests run.*Fail|exit code [1-9]|编译失败|构建失败|门.*失败' | \
    head -20 || echo "无法获取日志，请查看: ${BUILD_URL}")

# 3. 从 PR 获取 Issue 编号
BRANCH_NAME=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json headRefName --jq '.headRefName' 2>/dev/null || echo "")
ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -oE '[0-9]+' | tail -1 || echo "")
echo "[failure-handler] PR #$PR_NUMBER issue=$ISSUE_NUM"

# 4. 注入 CC
if [ -n "$ISSUE_NUM" ]; then
    PROMPT="CI 失败，请修复后 push 重跑：

\`\`\`
$ERROR_LOG
\`\`\`

完整日志：${BUILD_URL}consoleText"
    bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "$PROMPT" || true
else
    echo "[failure-handler] 无法提取 Issue 编号"
fi

echo "[failure-handler] Done"
exit 0
