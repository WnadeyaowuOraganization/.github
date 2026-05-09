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

# 2. 提取门控失败原因（精准匹配，优先质量门）
GATE_FAIL=""
CONSOLE_URL=""
if [ -n "$BUILD_URL" ]; then
    CONSOLE_URL="${BUILD_URL}consoleText"
    GATE_FAIL=$(curl -sf "$CONSOLE_URL" 2>/dev/null | \
        grep -E '❌|×|✘|quality-gate|门[0-9]' | \
        grep -v '^\[Pipeline\]' | \
        head -20 || echo "")
fi

# 3. 构造可执行的提示词
if [ -n "$GATE_FAIL" ]; then
    # 质量门失败：给出具体门号和修复指令
    PROMPT_MSG="CI 质量门失败，请立即修复并 push（无需关闭 PR，push 自动触发重跑）：

失败原因：
$GATE_FAIL

修复指令：
- 门1失败：PR body 有未勾 checkbox → 改为 \`- [x]\` 后 push
- 门2失败：task.md 有未勾 checkbox → 在 task.md 中改为 \`- [x]\` 后 push
- 门3失败：前端 PR 缺少截图 → 在 PR body 追加截图后 push
- 门5失败：E2E 硬编码端口 → 改用相对路径/环境变量后 push

完整日志：${CONSOLE_URL}"
else
    # 兜底：提取关键错误
    ERROR_SUMMARY=$(curl -sf "${CONSOLE_URL:-${BUILD_URL}consoleText}" 2>/dev/null | \
        grep -v '^\[Pipeline\]' | \
        grep -E 'ERROR:|Tests run.*Errors|失败|❌|exit code [1-9]' | \
        grep . | head -10 || echo "无法获取详细日志")
    PROMPT_MSG="CI 失败（exit code 非0），请修复后 push 重跑：

关键错误：
$ERROR_SUMMARY

完整日志：${CONSOLE_URL:-${BUILD_URL}consoleText}"
fi

# 4. 注入 CC
if [ -n "$ISSUE_NUM" ]; then
    echo "[failure-handler] 注入 CC Issue #$ISSUE_NUM..."
    bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "$PROMPT_MSG" || true
else
    echo "[failure-handler] 无法从分支名提取 Issue 编号，跳过注入"
fi

# 5. PR 评论通知（已在 quality-gate.sh 发了精确原因，此处发兜底）
echo "[failure-handler] PR #${PR_NUMBER} 评论通知..."
bash "$JENKINS_DIR/notify-failure.sh" "$PR_NUMBER" "${BUILD_URL:-}" || true

echo "[failure-handler] 完成"
exit 0
