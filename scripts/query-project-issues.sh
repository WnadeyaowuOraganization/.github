#!/bin/bash
# query-project-issues.sh - 查询Project #4中指定仓库和状态的Issue
# 用法: query-project-issues.sh --repo play --status "Todo"
#       query-project-issues.sh --status "In Progress"
# repo: play | backend | frontend | pipeline | plugins | gh-plugins | all (默认all)
# status: Plan | Todo | In Progress | Done | pause | Fail | all (默认all)

# Auto-detect GH_TOKEN if not set
if [ -z "$GH_TOKEN" ]; then
  _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  export GH_TOKEN=$(bash "$_SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)
fi

set -e

# 参数解析（兼容旧的下标方式）
REPO_NAME="all"
STATUS_NAME="all"

if [ "$1" = "--repo" ] || [ "$1" = "--status" ]; then
  # 新的命名参数模式
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo)   REPO_NAME="$2"; shift 2 ;;
      --status) STATUS_NAME="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
else
  # 兼容旧的下标模式
  REPO_NAME="${1:-all}"
  STATUS_NAME="${2:-all}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

PROJECT_ID="PVT_kwDOD3gg584BTjK2"

# --- GraphQL查询模板 ---
# 带服务端过滤（指定status时使用）
QUERY_FILTERED='query($projectId: ID!, $filter: String!, $cursor: String) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, query: $filter, after: $cursor) {
        totalCount
        nodes {
          content {
            ... on Issue {
              number
              title
              state
              repository { nameWithOwner }
              labels(first: 10) { nodes { name } }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}'

# 无过滤（status=all时使用）
QUERY_ALL='query($projectId: ID!, $cursor: String) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, after: $cursor) {
        totalCount
        nodes {
          content {
            ... on Issue {
              number
              title
              state
              repository { nameWithOwner }
              labels(first: 10) { nodes { name } }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}'

# --- 分页获取items ---
TMPFILE=$(mktemp /tmp/project-items-XXXXXX.json)
trap "rm -f $TMPFILE" EXIT

echo '{"nodes":[]}' > "$TMPFILE"

CURSOR=""
PAGE=0

while true; do
    PAGE=$((PAGE + 1))

    # 构建gh api命令
    if [ "$STATUS_NAME" != "all" ]; then
        FILTER="status:\"$STATUS_NAME\""
        if [ -z "$CURSOR" ]; then
            RESPONSE=$(gh api graphql --raw-field query="$QUERY_FILTERED" \
                -F projectId="$PROJECT_ID" -F "filter=$FILTER" 2>/dev/null)
        else
            RESPONSE=$(gh api graphql --raw-field query="$QUERY_FILTERED" \
                -F projectId="$PROJECT_ID" -F "filter=$FILTER" -F "cursor=$CURSOR" 2>/dev/null)
        fi
    else
        if [ -z "$CURSOR" ]; then
            RESPONSE=$(gh api graphql --raw-field query="$QUERY_ALL" \
                -F projectId="$PROJECT_ID" 2>/dev/null)
        else
            RESPONSE=$(gh api graphql --raw-field query="$QUERY_ALL" \
                -F projectId="$PROJECT_ID" -F "cursor=$CURSOR" 2>/dev/null)
        fi
    fi

    # 解析并追加
    PARSE_RESULT=$(echo "$RESPONSE" | python3 -c "
import json, sys

new_data = json.load(sys.stdin)
items_data = new_data.get('data', {}).get('node', {}).get('items', {})
new_nodes = items_data.get('nodes', [])
total = items_data.get('totalCount', '?')
pi = items_data.get('pageInfo', {})

old = json.load(open('$TMPFILE'))
old['nodes'].extend(new_nodes)
old['totalCount'] = total

with open('$TMPFILE', 'w') as f:
    json.dump(old, f)

has_next = pi.get('hasNextPage', False)
cursor = pi.get('endCursor', '')
print(f'{len(old[\"nodes\"])}|{total}|{has_next}|{cursor}')
" 2>/dev/null)

    FETCHED=$(echo "$PARSE_RESULT" | cut -d'|' -f1)
    TOTAL=$(echo "$PARSE_RESULT" | cut -d'|' -f2)
    HAS_NEXT=$(echo "$PARSE_RESULT" | cut -d'|' -f3)
    CURSOR=$(echo "$PARSE_RESULT" | cut -d'|' -f4)

    echo "Page $PAGE: $FETCHED / $TOTAL items" >&2

    if [ "$HAS_NEXT" != "True" ]; then
        break
    fi
done

# --- 过滤与输出 ---
export REPO_NAME STATUS_NAME
python3 -c "
import json, sys, os

REPO_NAME = os.getenv('REPO_NAME', 'all')
STATUS_NAME = os.getenv('STATUS_NAME', 'all')

repo_map = {
    'WnadeyaowuOraganization/wande-play': 'play',
    'WnadeyaowuOraganization/wande-gh-plugins': 'plugins',
}

# Alias: 'gh-plugins' is equivalent to 'plugins'
if REPO_NAME == 'gh-plugins':
    REPO_NAME = 'plugins'

data = json.load(open('$TMPFILE'))
items = data.get('nodes', [])
total_items = data.get('totalCount', '?')

print(f'Project #4: {REPO_NAME if REPO_NAME != \"all\" else \"all\"} / {STATUS_NAME if STATUS_NAME != \"all\" else \"all\"}  (server totalCount: {total_items})')
print('=' * 100)

results = []
status_counts = {}
for item in items:
    content = item.get('content')
    if not content or not isinstance(content, dict):
        continue

    num = content.get('number')
    title = content.get('title', '')
    repo_full = (content.get('repository') or {}).get('nameWithOwner', '')
    repo_short = repo_map.get(repo_full, repo_full)
    issue_state = content.get('state', 'OPEN')
    labels = [l['name'] for l in (content.get('labels') or {}).get('nodes', []) if l]

    if not num:
        continue

    # Skip closed issues
    if issue_state == 'CLOSED':
        continue

    # 提取Status field
    status = '?'
    for fv in item.get('fieldValues', {}).get('nodes', []):
        field = fv.get('field') or {}
        if field.get('name') == 'Status':
            status = fv.get('name', '?')
            break

    status_counts[status] = status_counts.get(status, 0) + 1

    if REPO_NAME != 'all' and repo_short != REPO_NAME:
        continue

    # Extract key labels for display
    module = next((l.replace('module:', '') for l in labels if l.startswith('module:')), '-')
    priority = next((l.replace('priority/', '') for l in labels if l.startswith('priority/')), '-')

    results.append((status, num, repo_short, title, module, priority, labels))

# 按状态排序
status_order = {'Plan': 0, 'Todo': 1, 'In Progress': 2, 'pause': 3, 'Fail': 4, 'Done': 5, '?': 6}
results.sort(key=lambda x: (status_order.get(x[0], 9), x[1]))

for status, num, repo, title, module, priority, labels in results:
    print(f'{status:12} #{num:4} {module:10} {priority:3} {title[:65]}')

print()

# 状态汇总
if len(status_counts) > 1:
    print('--- 状态汇总 ---')
    for s, c in sorted(status_counts.items(), key=lambda x: status_order.get(x[0], 9)):
        print(f'  {s:15} : {c}')
    print()

print(f'匹配条件的Issue: {len(results)}')

# 机器可解析格式(stderr)
for status, num, repo, title, module, priority, labels in results:
    labels_str = ','.join(labels)
    print(f'ISSUE_{num}={status}|{module}|{priority}|{labels_str}', file=sys.stderr)
"
