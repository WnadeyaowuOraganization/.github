#!/bin/bash
# update-project-status.sh - 更新Project #2看板的Status字段
# 用法: update-project-status.sh <repo> <ISSUE_NUMBER> <STATUS>
# repo:   backend | front | pipeline | plugins (可选，不传则查全部4个仓库)
# STATUS: Plan | Todo | In Progress | Done | pause | Fail
#
# v3 (2026-03-30): 新增可选repo参数
#   - 传repo: 只查1个仓库，1次query + 1次mutation = 2次API调用
#   - 不传:   查全部4仓库，1次query + N次mutation（兼容v2行为）

set -e

REPO_SHORT="$1"
ISSUE_NUMBER="$2"
NEW_STATUS="$3"

if [ -z "$ISSUE_NUMBER" ] || [ -z "$NEW_STATUS" ]; then
    echo "用法: $0 <repo> <ISSUE_NUMBER> <STATUS>"
    echo "REPO:   backend | front | pipeline | plugins (可选)"
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

# repo短名 → 仓库全名映射
declare -A REPO_MAP
REPO_MAP["backend"]="wande-ai-backend"
REPO_MAP["front"]="wande-ai-front"
REPO_MAP["pipeline"]="wande-data-pipeline"
REPO_MAP["plugins"]="wande-gh-plugins"
REPO_MAP["play"]="wande-play"
REPO_MAP["play"]="wande-play"

# Project routing by repo
if [ "$REPO_SHORT" = "play" ]; then
    PROJECT_ID="PVT_kwDOD3gg584BTjK2"
    FIELD_ID="PVTSSF_lADOD3gg584BTjK2zhAxafs"
    declare -A STATUS_MAP_PLAY
    STATUS_MAP_PLAY["Plan"]="7beef254"
    STATUS_MAP_PLAY["Todo"]="69f47110"
    STATUS_MAP_PLAY["In Progress"]="c1875ac0"
    STATUS_MAP_PLAY["Done"]="c8f40892"
    STATUS_MAP_PLAY["pause"]="434faed7"
    STATUS_MAP_PLAY["Fail"]="8a0d3051"
    OPTION_ID="${STATUS_MAP_PLAY[$NEW_STATUS]}"
else
    PROJECT_ID="PVT_kwDOD3gg584BSCFx"
    FIELD_ID="PVTSSF_lADOD3gg584BSCFxzg_r2go"
fi
    FIELD_ID="PVTSSF_lADOD3gg584BSCFxzg_r2go"
fi

# --- 查询Item ID ---
if [ -n "$REPO_SHORT" ]; then
    # 指定repo: 只查1个仓库
    REPO_FULL="${REPO_MAP[$REPO_SHORT]}"
    if [ -z "$REPO_FULL" ]; then
        echo "错误: 未知仓库 '$REPO_SHORT' (可选: backend | front | pipeline | plugins)"
        exit 1
    fi

    QUERY='query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          projectItems(first: 3) {
            nodes { id project { id } }
          }
        }
      }
    }'

    ITEM_IDS=$(gh api graphql --raw-field query="$QUERY" \
      -F owner="WnadeyaowuOraganization" -F repo="$REPO_FULL" -F number="$ISSUE_NUMBER" 2>/dev/null \
      | python3 -c "
import json, sys
data = json.load(sys.stdin).get('data', {})
repo_data = data.get('repository', {})
issue = repo_data.get('issue') if repo_data else None
if issue:
    for pi in issue['projectItems']['nodes']:
        if pi['project']['id'] == '$PROJECT_ID':
            print(f'{pi[\"id\"]}|$REPO_SHORT')
")
else
    # 不传repo: 并行查4个仓库
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
for repo, val in data.items():
    if val and val.get('issue'):
        for pi in val['issue']['projectItems']['nodes']:
            if pi['project']['id'] == target_project:
                print(f'{pi[\"id\"]}|{repo}')
")
fi

if [ -z "$ITEM_IDS" ]; then
    echo "错误: 未找到 Issue #$ISSUE_NUMBER 在Project #2 中的 Item"
    exit 1
fi

# --- 更新Status ---
# 将optionId直接嵌入mutation，避免-F将纯数字作为数值类型传递导致GraphQL类型错误
MUTATION_TEMPLATE='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: "OPTION_ID_PLACEHOLDER" }
  }) { projectV2Item { id } }
}'

UPDATED=0
while IFS='|' read -r ITEM_ID REPO_NAME; do
    MUTATION="${MUTATION_TEMPLATE/OPTION_ID_PLACEHOLDER/$OPTION_ID}"
    gh api graphql --raw-field query="$MUTATION" \
      -F projectId="$PROJECT_ID" -F itemId="$ITEM_ID" \
      -F fieldId="$FIELD_ID" > /dev/null 2>&1
    UPDATED=$((UPDATED + 1))
    echo "✓ Issue #$ISSUE_NUMBER ($REPO_NAME) Status → $NEW_STATUS"
done <<< "$ITEM_IDS"

if [ "$UPDATED" -gt 1 ]; then
    echo "  (同号issue在${UPDATED}个仓库，全部已更新)"
fi
