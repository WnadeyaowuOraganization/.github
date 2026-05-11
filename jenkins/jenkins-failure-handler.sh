#!/bin/bash
# jenkins-failure-handler.sh — PR CI 失败时注入 CC 会话 + PR 评论
# inject-cc-prompt.sh 内部已处理：找不到 kimi → 自动 fallback 通知 manager
# 由 Jenkinsfile post-failure 阶段调用

set +e  # 不允许任何命令失败导致脚本退出

PR_NUMBER="${FAIL_PR_NUM:-}"
BUILD_URL="${FAIL_BUILD_URL:-}"
REPO="${REPO:-WnadeyaowuOraganization/wande-play}"
GH_TOKEN="${WEIPING_TOKEN:-$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)}"

SCRIPTS_DIR="/data/home/ubuntu/projects/.github/scripts"
JENKINS_DIR="/data/home/ubuntu/projects/.github/jenkins"

if [ -z "$PR_NUMBER" ]; then
    echo "[failure-handler] PR number not set, skipping"
    exit 0
fi

echo "[failure-handler] Handling failure for PR #$PR_NUMBER ($BUILD_URL)"

# 1. PR 评论通知
CONSOLE_URL="${BUILD_URL}consoleText"
COMMENT_BODY="🤖 **CI 构建失败**

> **构建地址**: [${BUILD_URL}](${BUILD_URL})
> **处理建议**: 请检查失败原因，修复后重新 push 触发 CI

---
*由 Jenkins CI 自动生成*"

gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$COMMENT_BODY" 2>/dev/null || true

# 2. 从 PR 获取分支名 → 提取 Issue 编号
BRANCH_NAME=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json headRefName --jq '.headRefName' 2>/dev/null || echo "")
ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -oE '[0-9]+' | tail -1 || echo "")
echo "[failure-handler] PR #$PR_NUMBER branch=$BRANCH_NAME issue=$ISSUE_NUM"

# 3. 提取失败原因
FAIL_MSG=""
if [ -n "$CONSOLE_URL" ]; then
    # 质量门失败（只匹配❌/✗/✘等失败标记，避免匹配到✅通过的输出）
    GATE_FAIL=$(curl -sf "$CONSOLE_URL" 2>/dev/null | \
        grep -E '❌|✗|✘|门[0-9].*失败|gate.*fail|quality.*fail' | \
        grep -viE '^\[Pipeline\]|^\s*ha://' | \
        head -10 || echo "")

    if [ -n "$GATE_FAIL" ]; then
        FAIL_LINES=$(echo "$GATE_FAIL" | head -5 | while IFS= read -r line; do echo "  $line"; done)
        FAIL_MSG="CI 质量门失败，请立即修复并 push（无需关闭 PR，push 自动触发重跑）：

失败原因：
$FAIL_LINES

修复指令：
- 门1失败：PR body 有未勾 checkbox → 修改 PR 描述，将 \`- [ ]\` 改为 \`- [x]\` 后 push
- 门2失败：task.md 有未勾 checkbox → 修改 \`issues/issue-N/task.md\`，将 \`- [ ]\` 改为 \`- [x]\` 后 push
- 门3失败：前端 PR 缺少截图 → 在 PR body 追加截图后 push
- 门5失败：E2E 硬编码端口 → 改用环境变量后 push

完整日志：$CONSOLE_URL"
    else
        # 编译/构建失败
        ERROR_LINES=$(curl -sf "$CONSOLE_URL" 2>/dev/null | \
            grep -viE '^\[Pipeline\]|^\s*ha://|^\[8mha' | \
            grep -iE 'error:|ERROR.*build|BUILD FAILURE|编译失败|cannot find symbol|Unexpected token' | \
            head -8 || echo "")
        if [ -n "$ERROR_LINES" ]; then
            FAIL_MSG="CI 构建失败，请修复后 push 重跑：

关键错误：
$ERROR_LINES

完整日志：$CONSOLE_URL"
        else
            FAIL_MSG="CI 构建失败（详情见日志），请检查并修复后 push 重跑：$CONSOLE_URL"
        fi
    fi
fi

# 4. 注入 CC 会话（inject-cc-prompt.sh 内部已处理 fallback 到 manager）
if [ -n "$ISSUE_NUM" ]; then
    echo "[failure-handler] 注入 CC Issue #$ISSUE_NUM..."
    bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "$FAIL_MSG" || true
else
    echo "[failure-handler] 无法从分支名提取 Issue 编号，跳过注入"
fi

echo "[failure-handler] Done for PR #$PR_NUMBER"
exit 0
