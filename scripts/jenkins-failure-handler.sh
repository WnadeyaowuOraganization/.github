#!/bin/bash
# jenkins-failure-handler.sh — 从 Jenkins console 提取错误并通知 CC
# 由 Jenkinsfile post-failure 阶段调用，避免 Groovy sh block 复杂拼接导致的 exit 128 问题

set +e  # 不允许任何命令失败导致脚本退出

PR_NUMBER=${FAIL_PR_NUM:-""}
BUILD_URL=${FAIL_BUILD_URL:-""}
REPO="WnadeyaowuOraganization/wande-play"
GH_TOKEN=${GH_TOKEN:-$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)}

SCRIPTS_DIR="/data/home/ubuntu/projects/.github/scripts"
JENKINS_DIR="/data/home/ubuntu/projects/.github/jenkins"

if [ -z "$PR_NUMBER" ]; then
    echo "[failure-handler] 缺少 FAIL_PR_NUM 环境变量，跳过"
    exit 0
fi

# 1. 从 PR 获取分支名 → 提取 Issue 编号
BRANCH_NAME=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json headRefName --jq '.headRefName' 2>/dev/null || echo "")
ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -oP '(?<=Issue-|issue-)\d+' | head -1)

echo "[failure-handler] PR #$PR_NUMBER branch=$BRANCH_NAME issue=$ISSUE_NUM"

# 2. 提取错误日志（从 Jenkins console URL）
ERROR_LOG="无法获取详细日志"
if [ -n "$BUILD_URL" ]; then
    CONSOLE_URL="${BUILD_URL}consoleText"
    ERROR_LOG=$(curl -sf "$CONSOLE_URL" 2>/dev/null | \
        grep -v '^\[Pipeline\]' | \
        grep -v "^${SCRIPTS_DIR}/" | \
        grep -v "^${JENKINS_DIR}/" | \
        grep -B 3 -A 10 -E '❌|ERROR:|exit code [1-9]|Tests run.*Errors|失败|×|✘' | \
        grep . | head -25 || echo "无法获取详细日志")
fi

# 3. 构造提示词
PROMPT_MSG="CI失败，请修复以下问题后重新推送代码。

Jenkins 错误详情：
$ERROR_LOG

完整日志(免认证)：${BUILD_URL}consoleText"

# 4. 注入 CC
if [ -n "$ISSUE_NUM" ]; then
    echo "[failure-handler] 注入 CC Issue #$ISSUE_NUM..."
    bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "$PROMPT_MSG" || true
else
    echo "[failure-handler] 无法从分支名提取 Issue 编号，跳过注入"
fi

# 5. PR 评论通知
echo "[failure-handler] PR #${PR_NUMBER} 评论通知..."
bash "$JENKINS_DIR/notify-failure.sh" "$PR_NUMBER" "${BUILD_URL:-}" || true

echo "[failure-handler] 完成"
exit 0
