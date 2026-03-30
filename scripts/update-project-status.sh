#!/bin/bash
# update-project-status.sh - 更新Project #2看板的Status字段
# 用法: update-project-status.sh <ISSUE_NUMBER> <STATUS>
# STATUS: Plan | Todo | In Progress | Done | pause | Fail
#
# v2 (2026-03-30): 通过Issue.projectItems反查Item ID，彻底消除分页问题
#   - 1次query(4仓库并行) + N次mutation = 最少2次API调用
#   - 解决v1的items>100找不到问题
#   - 同号issue(如#248在backend和front都有)全部更新

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

# 1次查询: 4个仓库并行查询，通过Issue.projectItems反查Item ID
# 不存在的issue number返回null（GraphQL partial error），不影响其他仓库的结果
QUERY='query($owner: String!, $number: Int!) {
  backend: repository(owner: $owner, name: "wande-ai-backend") {
    issue(number: $number) {
      projectItems(first: 3) {
        nodes { id project { id } }
      }
    }
  }
  front: repository(owner: $owner, name: "wande-ai-front") {
    issue(number: $number) {
      projectItems(first: 3) {
        nodes { id project { id } }
      }
    }
  }
  pipeline: repository(owner: $owner, name: "wande-data-pipeline") {
    issue(number: $number) {
      projectItems(first: 3) {
        nodes { id project { id } }
      }
    }
  }
  plugins: repository(owner: $owner, name: "wande-gh-plugins") {
    issue(number: $number) {
      projectItems(first: 3) {
        nodes { id project { id } }
      }
    }
  }
}'

# 提取所有匹配Project#2的Item ID（同号issue可能在多个仓库）
ITEM_IDS=$(gh api graphql --raw-field query="$QUERY" \
  -F owner="WnadeyaowuOraganization" -F number="$ISSUE_NUMBER" 2>/dev/null \
  | python3 -c "
import json, sys

raw = sys.stdin.read()
# gh api 可能在JSON后追加error文本，只解析第一个完整JSON对象
depth = 0
for i, c in enumerate(raw):
    if c == '{': depth += 1
    elif c == '}': depth -= 1
    if depth == 0 and i > 0:
        data = json.loads(raw[:i+1]).get('data', {})
        break
else:
    data = {}

target_project = '$PROJECT_ID'
items = []
for repo, val in data.items():
    if val and val.get('issue'):
        for pi in val['issue']['projectItems']['nodes']:
            if pi['project']['id'] == target_project:
                items.append(f'{pi[\"id\"]}|{repo}')

for item in items:
    print(item)
")

if [ -z "$ITEM_IDS" ]; then
    echo "错误: 未找到 Issue #$ISSUE_NUMBER 在Project #2 中的 Item"
    exit 1
fi

# 更新每个匹配的Item（通常1个，同号issue时可能多个）
MUTATION='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) { projectV2Item { id } }
}'

UPDATED=0
while IFS='|' read -r ITEM_ID REPO_NAME; do
    gh api graphql --raw-field query="$MUTATION" \
      -F projectId="$PROJECT_ID" -F itemId="$ITEM_ID" \
      -F fieldId="$FIELD_ID" -F optionId="$OPTION_ID" > /dev/null 2>&1
    UPDATED=$((UPDATED + 1))
    echo "✓ Issue #$ISSUE_NUMBER ($REPO_NAME) Status → $NEW_STATUS"
done <<< "$ITEM_IDS"

if [ "$UPDATED" -gt 1 ]; then
    echo "  (同号issue在${UPDATED}个仓库，全部已更新)"
fi
