#!/bin/bash
PR_NUMBER=$1
BUILD_URL=$2
REPO="WnadeyaowuOraganization/wande-play"

# PR 评论
gh pr comment $PR_NUMBER --repo $REPO --body "❌ CI 失败

构建日志: ${BUILD_URL}console

请检查失败原因并修复后重新 push。" 2>/dev/null || true

# 钉钉通知（如果有配置）
if [ -n "$DINGTALK_WEBHOOK" ]; then
    curl -s -X POST "$DINGTALK_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"❌ PR #${PR_NUMBER} CI 失败\n日志: ${BUILD_URL}\"}}" 2>/dev/null || true
fi
