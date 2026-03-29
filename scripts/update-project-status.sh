#!/bin/bash
# update-project-status.sh - 更新Project #2看板的Status字段
# 用法: update-project-status.sh <ISSUE_NUMBER> <STATUS>
# STATUS: Plan | Todo | In Progress | Done | pause | Fail
set -e

ISSUE_NUMBER="$1"
NEW_STATUS="$2"

if [ -z "$ISSUE_NUMBER" ] || [ -z "$NEW_STATUS" ]; then
    echo "用法: $0 <ISSUE_NUMBER> <STATUS>"
    echo "STATUS: Plan | Todo | In Progress | Done | pause | Fail"
    exit 1
fi

# Token
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# Status Option ID 映射
declare -A STATUS_MAP
STATUS_MAP["Plan"]="5ef24ffe"
STATUS_MAP["Todo"]="f75ad846"
STATUS_MAP["In Progress"]="47fc9ee4"
STATUS_MAP["Done"]="98236657"
STATUS_MAP["pause"]="1c220cdf"
STATUS_MAP["Fail"]="3bdb636e"

OPTION_ID="${STATUS_MAP[$NEW_STATUS]}"
if [ -z "$OPTION_ID" ]; then
    echo "错误: 未知状态 '$NEW_STATUS'"
    exit 1
fi

PROJECT_ID="PVT_kwDOD3gg584BSCFx"
FIELD_ID="PVTSSF_lADOD3gg584BSCFxzg_r2go"

ITEM_ID=$(gh api graphql -f query='
query($issueNum: Int!) {
  organization(login: "WnadeyaowuOraganization") {
    projectV2(number: 2) {
      items(first: 100) {
        nodes {
          id
          content { ... on Issue { number } }
        }
      }
    }
  }
}' -F issueNum="$ISSUE_NUMBER" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data['data']['organization']['projectV2']['items']['nodes']:
    if item.get('content', {}).get('number') == $ISSUE_NUMBER:
        print(item['id'])
        break
" 2>/dev/null)

if [ -z "$ITEM_ID" ]; then
    echo "错误: 未找到 Issue #$ISSUE_NUMBER 对应的Project Item"
    exit 1
fi

gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId itemId: $itemId fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) { projectV2Item { id } }
}' -F projectId="$PROJECT_ID" -F itemId="$ITEM_ID" -F fieldId="$FIELD_ID" -F optionId="$OPTION_ID" > /dev/null 2>&1

echo "✓ Issue #$ISSUE_NUMBER Status → $NEW_STATUS"
