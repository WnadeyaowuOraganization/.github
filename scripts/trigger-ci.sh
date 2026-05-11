#!/bin/bash
# trigger-ci.sh — 本地直接触发 Jenkins CI（不依赖 GitHub webhook）
# 用法: bash trigger-ci.sh <PR_NUMBER> [BRANCH]
# 由 CC push 后直接调用，保证 CI 必定触发
set +e

PR_NUM="${1:-}"
BRANCH="${2:-}"
JENKINS_WEBHOOK="http://localhost:18080/jenkins/generic-webhook-trigger/invoke?token=wande-play-pr"
REPO="WnadeyaowuOraganization/wande-play"

if [ -z "$PR_NUM" ] && [ -z "$BRANCH" ]; then
    echo "用法: $0 <PR_NUMBER> [BRANCH]"
    echo "  $0 4623 feature-Issue-2686"
    echo "  $0 '' feature-Issue-2686  (从分支推导PR号)"
    exit 1
fi

# 如果只有分支名，推导 PR 号
if [ -z "$PR_NUM" ] && [ -n "$BRANCH" ]; then
    export GH_TOKEN="${GH_TOKEN:-$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)}"
    PR_NUM=$(gh pr list --head "$BRANCH" --repo "$REPO" --json number --jq '.[0].number' 2>/dev/null || echo "")
    if [ -z "$PR_NUM" ]; then
        echo "[trigger-ci] 未找到分支 $BRANCH 对应的 PR"
        exit 1
    fi
fi

# 从 PR 号推导分支名
if [ -z "$BRANCH" ]; then
    export GH_TOKEN="${GH_TOKEN:-$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)}"
    BRANCH=$(gh pr view "$PR_NUM" --repo "$REPO" --json headRefName --jq '.headRefName' 2>/dev/null || echo "")
fi

echo "[trigger-ci] 触发 CI: PR #$PR_NUM ($BRANCH)"

# 触发 Jenkins
RESPONSE=$(curl -sf "$JENKINS_WEBHOOK" -X POST \
    -H "Content-Type: application/json" \
    -d "{\"action\":\"synchronize\",\"pull_request\":{\"number\":${PR_NUM},\"head\":{\"ref\":\"${BRANCH}\"},\"base\":{\"ref\":\"dev\"}}}" 2>/dev/null)

if [ $? -eq 0 ]; then
    TRIGGERED=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('jobs',{}).get('wande-play-pr',{}).get('triggered',False))" 2>/dev/null)
    if [ "$TRIGGERED" = "True" ]; then
        echo "[trigger-ci] ✅ CI 已触发 PR #$PR_NUM"
    else
        echo "[trigger-ci] ❌ CI 触发失败: $RESPONSE"
        exit 1
    fi
else
    echo "[trigger-ci] ❌ Jenkins 连接失败"
    exit 1
fi
