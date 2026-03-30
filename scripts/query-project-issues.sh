#!/bin/bash
# query-project-issues.sh - 查询Project #2中指定仓库和状态的Issue
# 用法: query-project-issues.sh [repo] [status]
# repo: backend | front | pipeline | plugins | all (默认all)
# status: Plan | Todo | In Progress | Done | pause | Fail | all (默认all)
# 输出: stdout=人类可读表格, stderr=机器可解析 ISSUE_<N>=<STATUS>
#
# v3 (2026-03-30): 使用GraphQL query参数服务端过滤，大幅减少API调用
#   - 指定status时: 服务端过滤，Todo/In Progress等通常1次API调用即可
#   - status=all时: 需遍历全部items，自动分页
#   - Plan状态(790+)仍需翻页，其他状态(<100)单次搞定
#   - GraphQL cost: 指定status≈2-3 points, all≈20-30 points

set -e

REPO_NAME="${1:-all}"
STATUS_NAME="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

PROJECT_ID="PVT_kwDOD3gg584BSCFx"

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
              repository { nameWithOwner }
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
              repository { nameWithOwner }
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
    'WnadeyaowuOraganization/wande-ai-backend': 'backend',
    'WnadeyaowuOraganization/wande-ai-front': 'front',
    'WnadeyaowuOraganization/wande-data-pipeline': 'pipeline',
    'WnadeyaowuOraganization/wande-gh-plugins': 'plugins',
}

data = json.load(open('$TMPFILE'))
items = data.get('nodes', [])
total_items = data.get('totalCount', '?')

print(f'Project #2: {REPO_NAME if REPO_NAME != \"all\" else \"all\"} / {STATUS_NAME if STATUS_NAME != \"all\" else \"all\"}  (server totalCount: {total_items})')
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

    if not num:
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

    results.append((status, num, repo_short, title))

# 按状态排序
status_order = {'Plan': 0, 'Todo': 1, 'In Progress': 2, 'pause': 3, 'Fail': 4, 'Done': 5, '?': 6}
results.sort(key=lambda x: (status_order.get(x[0], 9), x[1]))

for status, num, repo, title in results:
    print(f'{status:12} #{num:4} [{repo:20}] {title[:60]}')

print()

# 状态汇总
if len(status_counts) > 1:
    print('--- 状态汇总 ---')
    for s, c in sorted(status_counts.items(), key=lambda x: status_order.get(x[0], 9)):
        print(f'  {s:15} : {c}')
    print()

print(f'匹配条件的Issue: {len(results)}')

# 机器可解析格式(stderr)
for status, num, repo, title in results:
    print(f'ISSUE_{num}={status}', file=sys.stderr)
"
