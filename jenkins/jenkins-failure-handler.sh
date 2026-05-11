#!/bin/bash
# jenkins-failure-handler.sh — PR CI 失败时注入 CC 会话 + PR 评论
# 优先级：通知对应 kimi tmux 会话 → fallback 到研发经理 tmux
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

# 1. PR 评论通知（直接发，gh token 问题不影响后续）
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

# 3. 提取失败原因（优先质量门，其次编译/构建错误）
FAIL_MSG=""
if [ -n "$CONSOLE_URL" ]; then
    # 质量门失败
    GATE_FAIL=$(curl -sf "$CONSOLE_URL" 2>/dev/null | \
        grep -iE '❌|×|✘|quality-gate|门[0-9]|gate[0-9]' | \
        grep -viE '^\[Pipeline\]|^\s*ha://' | \
        head -10 || echo "")

    if [ -n "$GATE_FAIL" ] && echo "$GATE_FAIL" | grep -qiE '门[0-9]|gate|❌|quality|checkbox'; then
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
            grep -iE 'error:|ERROR.*build|BUILD FAILURE|编译失败|构建失败|cannot find symbol|Unexpected token' | \
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

# 4. 注入对应 kimi 的 tmux 会话（优先），fallback 到研发经理
if [ -n "$ISSUE_NUM" ]; then
    echo "[failure-handler] 注入 CC Issue #$ISSUE_NUM..."
    INJECT_RESULT=$(bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "$FAIL_MSG" 2>&1) || true
    echo "[failure-handler] inject-cc-prompt: $INJECT_RESULT"
else
    echo "[failure-handler] 无法从分支名提取 Issue 编号，跳过注入"
fi

# 5. 如果 inject-cc-prompt 失败（找不到活跃 kimi），fallback 到研发经理
if [ -n "$ISSUE_NUM" ]; then
    # 检查 inject-cc-prompt 是否成功（退出码 0 表示找到会话）
    INJECTED=$(bash "$SCRIPTS_DIR/inject-cc-prompt.sh" "$ISSUE_NUM" "test" 2>/dev/null; echo $?)
    if [ "$INJECTED" != "0" ]; then
        echo "[failure-handler] 未找到活跃 kimi，fallback 到研发经理"
        MSG="【CI失败通知】-【需回复】PR #${PR_NUMBER} CI 失败，构建地址: ${BUILD_URL}，请确认处理"
        tmux send-keys -t 'manager-研发经理' "$MSG" Enter 2>/dev/null || true
        curl -s -X POST http://localhost:9872/api/notify \
            -H 'Content-Type: application/json' \
            -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"error\"}" 2>/dev/null || true
    fi
else
    echo "[failure-handler] 无 Issue 号，直接 fallback 到研发经理"
    MSG="【CI失败通知】-【需回复】PR #${PR_NUMBER} CI 失败，构建地址: ${BUILD_URL}，请确认处理"
    tmux send-keys -t 'manager-研发经理' "$MSG" Enter 2>/dev/null || true
    curl -s -X POST http://localhost:9872/api/notify \
        -H 'Content-Type: application/json' \
        -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"error\"}" 2>/dev/null || true
fi

echo "[failure-handler] Done for PR #$PR_NUMBER"
exit 0
