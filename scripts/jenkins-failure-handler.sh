#!/bin/bash
# jenkins-failure-handler.sh — PR CI 失败时自动在 PR 下评论并通知研发经理
set -e

PR_NUM="${FAIL_PR_NUM:-}"
BUILD_URL="${FAIL_BUILD_URL:-}"
REPO="${REPO:-WnadeyaowuOraganization/wande-play}"

export GH_TOKEN="${WEIPING_TOKEN:-$(gh auth token 2>/dev/null || echo '')}"

if [ -z "$PR_NUM" ]; then
    echo "[FAIL-HANDLER] PR number not set, skipping"
    exit 0
fi

echo "[FAIL-HANDLER] Handling failure for PR #${PR_NUM} (${BUILD_URL})"

# 在 PR 下评论通知
COMMENT_BODY="🤖 **CI 构建失败**

> **构建地址**: [${BUILD_URL}](${BUILD_URL})
> **处理建议**: 请检查失败原因，修复后重新 push 触发 CI

---
*由 Jenkins CI 自动生成*"

gh pr comment "$PR_NUM" --repo "$REPO" --body "$COMMENT_BODY" 2>/dev/null || true

# 通知研发经理 tmux 会话
MSG="【CI失败通知】-【需回复】PR #${PR_NUM} CI 失败，构建地址: ${BUILD_URL}，请确认处理"
tmux send-keys -t 'manager-研发经理' "$MSG" Enter 2>/dev/null || true

# 可选：POST 到 notify API
curl -s -X POST http://localhost:9872/api/notify \
    -H 'Content-Type: application/json' \
    -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"error\"}" 2>/dev/null || true

echo "[FAIL-HANDLER] Done for PR #${PR_NUM}"
