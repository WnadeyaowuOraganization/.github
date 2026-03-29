#!/bin/bash
# create-pr-with-backup-token.sh - 使用备用token创建PR
# 用法: create-pr-with-backup-token.sh <REPO> <ISSUE_NUM> <TITLE> <HEAD_BRANCH> [BODY]

# 加载token管理库
source /home/ubuntu/projects/.github/scripts/github-token-lib.sh

REPO="$1"
ISSUE_NUM="$2"
TITLE="$3"
HEAD_BRANCH="$4"
BODY="$5"

if [ -z "$REPO" ] || [ -z "$ISSUE_NUM" ] || [ -z "$TITLE" ] || [ -z "$HEAD_BRANCH" ]; then
    echo "用法: $0 <REPO> <ISSUE_NUM> <TITLE> <HEAD_BRANCH> [BODY]"
    exit 1
fi

# 默认body
if [ -z "$BODY" ]; then
    BODY="Fixes #$ISSUE_NUM"
fi

# 初始化token
init_tokens

# 创建PR函数
create_pr() {
    local token="$1"
    curl -s -X POST -H "Authorization: Bearer $token" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$REPO/pulls" \
      -d "{
        \"title\": \"$TITLE\",
        \"head\": \"$HEAD_BRANCH\",
        \"base\": \"dev\",
        \"body\": \"$BODY\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\"
      }" 2>&1
}

# 先用主token尝试
echo "尝试用主token创建PR..."
RESULT=$(create_pr "$MAIN_TOKEN")

PR_NUM=$(echo "$RESULT" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('number',''))" 2>/dev/null)

if [ -n "$PR_NUM" ]; then
    PR_URL=$(echo "$RESULT" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('html_url',''))" 2>/dev/null)
    echo "✅ PR #$PR_NUM 创建成功 (主token): $PR_URL"
    exit 0
fi

# 检查是否是rate limit错误
if echo "$RESULT" | grep -qi "rate.limit"; then
    echo "主token rate limit，切换备用token..."
    RESULT=$(create_pr "$BACKUP_TOKEN")
    
    PR_NUM=$(echo "$RESULT" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('number',''))" 2>/dev/null)
    
    if [ -n "$PR_NUM" ]; then
        PR_URL=$(echo "$RESULT" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('html_url',''))" 2>/dev/null)
        echo "✅ PR #$PR_NUM 创建成功 (备用token): $PR_URL"
        exit 0
    fi
fi

# 失败
echo "❌ PR创建失败: $RESULT"
exit 1
