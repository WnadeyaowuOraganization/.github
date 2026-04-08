#!/bin/bash
# update-project-status.sh - 更新Project #4看板的Status字段
# 用法: update-project-status.sh --repo play --issue 1234 --status "In Progress"
# repo:   play | backend | frontend | pipeline | plugins | gh-plugins
# status: Jump | Plan | Todo | In Progress | Done | pause | Fail | E2E Fail | Reject

set -e

# 参数解析
REPO_SHORT=""
ISSUE_NUMBER=""
NEW_STATUS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)   REPO_SHORT="$2"; shift 2 ;;
    --issue)  ISSUE_NUMBER="$2"; shift 2 ;;
    --status) NEW_STATUS="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

if [ -z "$ISSUE_NUMBER" ] || [ -z "$NEW_STATUS" ]; then
    echo "用法: $0 --repo play --issue <N> --status \"<STATUS>\""
    echo "STATUS: Jump | Plan | Todo | In Progress | Done | pause | Fail | E2E Fail | Reject"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GH_TOKEN已由caller设置（CC tmux会话），或自动获取
[ -n "$GH_TOKEN" ] || export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py")

# Status Option ID 映射（2026-04-07更新，新增Jump状态）
declare -A STATUS_MAP
STATUS_MAP["Jump"]="03012e67"
STATUS_MAP["Plan"]="a07b604b"
STATUS_MAP["pause"]="895c6027"
STATUS_MAP["Todo"]="d14d5f74"
STATUS_MAP["In Progress"]="4a591864"
STATUS_MAP["E2E Fail"]="8d2164a2"
STATUS_MAP["Done"]="ba15b774"
STATUS_MAP["Fail"]="787b6892"
STATUS_MAP["Reject"]="5aef36fa"

OPTION_ID="${STATUS_MAP[$NEW_STATUS]}"
if [ -z "$OPTION_ID" ]; then
    echo "错误: 未知状态 '$NEW_STATUS'"
    exit 1
fi

# repo短名 → 仓库全名映射
declare -A REPO_MAP
REPO_MAP["backend"]="wande-play"
REPO_MAP["frontend"]="wande-play"
REPO_MAP["pipeline"]="wande-play"
REPO_MAP["plugins"]="wande-gh-plugins"
REPO_MAP["gh-plugins"]="wande-gh-plugins"
REPO_MAP["play"]="wande-play"
REPO_MAP["play"]="wande-play"

# Project routing by repo
if [ "$REPO_SHORT" = "play" ]; then
    PROJECT_ID="PVT_kwDOD3gg584BTjK2"
    FIELD_ID="PVTSSF_lADOD3gg584BTjK2zhAxafs"
    declare -A STATUS_MAP_PLAY
    STATUS_MAP_PLAY["Jump"]="03012e67"
    STATUS_MAP_PLAY["Plan"]="a07b604b"
    STATUS_MAP_PLAY["pause"]="895c6027"
    STATUS_MAP_PLAY["Todo"]="d14d5f74"
    STATUS_MAP_PLAY["In Progress"]="4a591864"
    STATUS_MAP_PLAY["E2E Fail"]="8d2164a2"
    STATUS_MAP_PLAY["Done"]="ba15b774"
    STATUS_MAP_PLAY["Fail"]="787b6892"
    STATUS_MAP_PLAY["Reject"]="5aef36fa"
    OPTION_ID="${STATUS_MAP_PLAY[$NEW_STATUS]}"
else
    PROJECT_ID="PVT_kwDOD3gg584BTjK2"
    FIELD_ID="PVTSSF_lADOD3gg584BTjK2zhAxafs"
fi

# --- 查询Item ID ---
if [ -n "$REPO_SHORT" ]; then
    # 指定repo: 只查1个仓库
    REPO_FULL="${REPO_MAP[$REPO_SHORT]}"
    if [ -z "$REPO_FULL" ]; then
        echo "错误: 未知仓库 '$REPO_SHORT' (可选: play | backend | frontend | pipeline | plugins | gh-plugins)"
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
      backend: repository(owner: $owner, name: "wande-play") {
        issue(number: $number) {
          projectItems(first: 3) {
            nodes { id project { id } }
          }
        }
      }
      front: repository(owner: $owner, name: "wande-play") {
        issue(number: $number) {
          projectItems(first: 3) {
            nodes { id project { id } }
          }
        }
      }
      pipeline: repository(owner: $owner, name: "wande-play") {
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
    # Issue 不在看板中，先添加再获取 Item ID
    echo "Issue #$ISSUE_NUMBER 不在看板中，自动添加..."
    REPO_FULL_ADD="${REPO_MAP[$REPO_SHORT]:-wande-play}"
    ISSUE_NODE_ID=$(gh api graphql --raw-field query='query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){issue(number:$n){id}}}' \
      -F owner="WnadeyaowuOraganization" -F repo="$REPO_FULL_ADD" -F n="$ISSUE_NUMBER" \
      --jq '.data.repository.issue.id' 2>/dev/null)
    if [ -z "$ISSUE_NODE_ID" ]; then
        echo "错误: 无法获取 Issue #$ISSUE_NUMBER 的 Node ID"
        exit 1
    fi
    NEW_ITEM_ID=$(gh api graphql --raw-field query='mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}' \
      -F p="$PROJECT_ID" -F c="$ISSUE_NODE_ID" \
      --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null)
    if [ -z "$NEW_ITEM_ID" ]; then
        echo "错误: 添加 Issue #$ISSUE_NUMBER 到看板失败"
        exit 1
    fi
    ITEM_IDS="${NEW_ITEM_ID}|${REPO_SHORT:-play}"
    echo "✓ Issue #$ISSUE_NUMBER 已添加到看板 (Item: $NEW_ITEM_ID)"
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
