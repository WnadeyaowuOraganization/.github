#!/bin/bash
# query-project-issues.sh - 查询Project #2中指定仓库和状态的Issue（全量分页版）
# 用法: query-project-issues.sh [repo] [status]
# repo: backend | front | pipeline | plugins | all (默认all)
# status: Plan | Todo | In Progress | Done | pause | Fail | all (默认all)
# 输出: stdout=人类可读表格, stderr=机器可解析 ISSUE_<N>=<STATUS>
#
# v2 (2026-03-30): 支持分页遍历全部Project items（解决items>100时漏查问题）
#   - 首页查询 items(first:100)，后续用 endCursor 翻页直到 hasNextPage=false
#   - 988个items约需10次API调用，GraphQL cost ≈ 20-30 points
#   - 比 gh project item-list 的 100+ points 仍然高效

set -e

REPO_NAME="${1:-all}"
STATUS_NAME="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

PROJECT_ID="PVT_kwDOD3gg584BSCFx"

# --- GraphQL查询模板 ---
# 首页查询（无cursor）
QUERY_FIRST='query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
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

# 翻页查询（带cursor）
QUERY_NEXT='query($projectId: ID!, $cursor: String!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, after: $cursor) {
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

# --- 分页获取全部items，写入临时文件 ---
TMPFILE=$(mktemp /tmp/project-items-XXXXXX.json)
trap "rm -f $TMPFILE" EXIT

# 首页
RESPONSE=$(gh api graphql --raw-field query="$QUERY_FIRST" -F projectId="$PROJECT_ID" 2>/dev/null)
TOTAL=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['node']['items']['totalCount'])" 2>/dev/null || echo "?")

# 初始化JSON数组
echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data['data']['node']['items']
result = {
    'nodes': items['nodes'],
    'hasNextPage': items['pageInfo']['hasNextPage'],
    'endCursor': items['pageInfo'].get('endCursor')
}
json.dump(result, sys.stdout)
" > "$TMPFILE"

PAGE=1
echo "Page $PAGE: fetched 100 / $TOTAL items" >&2

# 翻页循环
while true; do
    HAS_NEXT=$(python3 -c "import json; d=json.load(open('$TMPFILE')); print(d['hasNextPage'])")
    if [ "$HAS_NEXT" != "True" ]; then
        break
    fi

    CURSOR=$(python3 -c "import json; d=json.load(open('$TMPFILE')); print(d['endCursor'])")
    RESPONSE=$(gh api graphql --raw-field query="$QUERY_NEXT" -F projectId="$PROJECT_ID" -F cursor="$CURSOR" 2>/dev/null)

    PAGE=$((PAGE + 1))

    # 追加nodes到临时文件，更新翻页信息
    echo "$RESPONSE" | python3 -c "
import json, sys

new_data = json.load(sys.stdin)
new_items = new_data['data']['node']['items']

old = json.load(open('$TMPFILE'))
old['nodes'].extend(new_items['nodes'])
old['hasNextPage'] = new_items['pageInfo']['hasNextPage']
old['endCursor'] = new_items['pageInfo'].get('endCursor')

with open('$TMPFILE', 'w') as f:
    json.dump(old, f)

print(f'Page $PAGE: fetched {len(old[\"nodes\"])} / $TOTAL items', file=sys.stderr)
" 2>&2
done

# --- 过滤与输出（逻辑与v1一致） ---
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

print(f'Project #2: {REPO_NAME if REPO_NAME != \"all\" else \"all\"} / {STATUS_NAME if STATUS_NAME != \"all\" else \"all\"}  (total items: {len(items)})')
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
    if STATUS_NAME != 'all' and status != STATUS_NAME:
        continue

    results.append((status, num, repo_short, title))

# 按状态排序
status_order = {'Plan': 0, 'Todo': 1, 'In Progress': 2, 'pause': 3, 'Fail': 4, 'Done': 5, '?': 6}
results.sort(key=lambda x: (status_order.get(x[0], 9), x[1]))

for status, num, repo, title in results:
    print(f'{status:12} #{num:4} [{repo:20}] {title[:60]}')

print()

# 状态汇总（始终显示，便于总览）
print('--- 状态汇总 ---')
for s, c in sorted(status_counts.items(), key=lambda x: status_order.get(x[0], 9)):
    marker = ' ◀' if STATUS_NAME != 'all' and s == STATUS_NAME else ''
    print(f'  {s:15} : {c}{marker}')

print()
print(f'匹配条件的Issue: {len(results)}')

# 机器可解析格式(stderr)
for status, num, repo, title in results:
    print(f'ISSUE_{num}={status}', file=sys.stderr)
"
