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

# 通过issue号直接获取关联的Project Item ID（不拉拉取所有items）
QUERY='query($num: Int!) {
  organization(login: "WnadeyaowuOraganization") {
    repository(name: "wande-ai-backend") {
      issue(number: $num) {
        projectItems(first: 10) {
          nodes {
            id
            project { number }
          }
        }
      }
    }
  }
}'
ITEM_ID=$(gh api graphql --raw-field query="$QUERY" -F num="$ISSUE_NUMBER" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data['data']['organization']['repository']['issue']['projectItems']['nodes']
for item in items:
    if item.get('project', {}).get('number') == 2:
        print(item['id'])
        break
" 2>/dev/null)

if [ -z "$ITEM_ID" ]; then
    # backend没找到，试试front和pipeline
    for repo in "wande-ai-front" "wande-data-pipeline"; do
        QUERY='query($repo: String!, $num: Int!) {
          organization(login: "WnadeyaowuOraganization") {
            repository(name: $repo) {
              issue(number: $num) {
                projectItems(first: 10) {
                  nodes {
                    id
                    project { number }
                  }
                }
              }
            }
          }
        }'
        ITEM_ID=$(gh api graphql --raw-field query="$QUERY" -F repo="$repo" -F num="$ISSUE_NUMBER" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data['data']['organization']['repository']['issue']['projectItems']['nodes']
for item in items:
    if item.get('project', {}).get('number') == 2:
        print(item['id'])
        break
" 2>/dev/null)
        if [ -n "$ITEM_ID" ]; then
            break
        fi
    done
fi

if [ -z "$ITEM_ID" ]; then
    echo "错误: 未找到 Issue #$ISSUE_NUMBER 在Project #2 中的 Item"
    exit 1
fi

MUTATION='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) { projectV2Item { id } }
}'
gh api graphql --raw-field query="$MUTATION" -F projectId="$PROJECT_ID" -F itemId="$ITEM_ID" -F fieldId="$FIELD_ID" -F optionId="$OPTION_ID" > /dev/null 2>&1

echo "✓ Issue #$ISSUE_NUMBER Status → $NEW_STATUS"
