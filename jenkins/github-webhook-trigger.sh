#!/bin/bash
# GitHub Webhook 触发 Jenkins 的脚本
# 放在 Jenkins 的 /var/lib/jenkins/scripts/ 目录

JENKINS_URL="http://localhost:8080/jenkins"
WEBHOOK_SECRET="your-webhook-secret"

# 解析 webhook payload
PAYLOAD=$(cat)
EVENT_TYPE=$(echo "$PAYLOAD" | jq -r '.action' 2>/dev/null || echo "")

# 只处理 PR 事件
if [ "$EVENT_TYPE" != "opened" ] && [ "$EVENT_TYPE" != "synchronize" ]; then
    echo "忽略非 PR 事件: $EVENT_TYPE"
    exit 0
fi

PR_NUMBER=$(echo "$PAYLOAD" | jq -r '.pull_request.number')
BRANCH=$(echo "$PAYLOAD" | jq -r '.pull_request.head.ref')
REPO=$(echo "$PAYLOAD" | jq -r '.repository.full_name')

echo "触发 PR #$PR_NUMBER ($BRANCH) 构建"

# 触发 Jenkins pipeline
curl -s -X POST "${JENKINS_URL}/job/wande-play-pr/buildWithParameters" \
    --data-urlencode "PR_NUMBER=${PR_NUMBER}" \
    --data-urlencode "BRANCH=${BRANCH}" \
    --data-urlencode "REPO=${REPO}" \
    -u "admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword)"

echo "构建已触发"
