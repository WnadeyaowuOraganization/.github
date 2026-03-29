#!/bin/bash
# update-project-status.sh - 更新Project #2看板的Status字段
# 用法: update-project-status.sh <ISSUE_NUMBER> <STATUS>
# STATUS: Plan | Todo | In Progress | Done | pause | Fail
#
# 优化: 单次GraphQL搜索issue获取item ID（vs 逐repo试错最多3次查询）
#       cost ≈ 2 points (原版 3-7 points)

set -e

ISSUE_NUMBER="$1"
NEW_STATUS="$2"

if [ -z "$ISSUE_NUMBER" ] || [ -z "$NEW_STATUS" ]; then
    echo "用法: $0 <ISSUE_NUMBER> <STATUS>"
    echo "STATUS: Plan | Todo | In Progress | Done | pause | Fail"
    exit 1
fi

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

# 单次查询：直接从Project的items中找对应issue number的item ID
# 避免逐repo查询（原版最多3次GraphQL调用）
QUERY='query($projectId: ID!, $after: String) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          content {
            ... on Issue {
              number
            }
          }
        }
      }
    }
  }
}'

ITEM_ID=$(gh api graphql --raw-field query="$QUERY" -F projectId="$PROJECT_ID" 2>/dev/null \
  | python3 -c "
import json, sys
target = $ISSUE_NUMBER
data = json.load(sys.stdin)
items = data.get('data', {}).get('node', {}).get('items', {}).get('nodes', [])
for item in items:
    content = item.get('content')
    if content and isinstance(content, dict) and content.get('number') == target:
        print(item['id'])
        break
")

if [ -z "$ITEM_ID" ]; then
    echo "错误: 未找到 Issue #$ISSUE_NUMBER 在Project #2 中的 Item"
    exit 1
fi

# 更新Status (1次mutation)
MUTATION='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) { projectV2Item { id } }
}'
gh api graphql --raw-field query="$MUTATION" \
  -F projectId="$PROJECT_ID" -F itemId="$ITEM_ID" \
  -F fieldId="$FIELD_ID" -F optionId="$OPTION_ID" > /dev/null 2>&1

echo "✓ Issue #$ISSUE_NUMBER Status → $NEW_STATUS"
