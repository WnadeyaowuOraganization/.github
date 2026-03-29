#!/bin/bash
# query-project-issues.sh - 查询Project #2中指定仓库和状态的Issue
# 用法: query-project-issues.sh [repo] [status]
# repo: backend | front | pipeline | all (默认all)
# status: Plan | Todo | In Progress | Done | pause | Fail | all (默认all)
# 输出: stdout=人类可读表格, stderr=机器可解析 ISSUE_<N>=<STATUS>
#
# 优化: 单次GraphQL查询 + GitHub App token (独立rate limit)
#       cost ≈ 2-3 points (vs gh project item-list 消耗 100+ points)

set -e

REPO_NAME="${1:-all}"
STATUS_NAME="${2:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

PROJECT_ID="PVT_kwDOD3gg584BSCFx"

# 单次GraphQL查询，拉取所有Project items
QUERY='query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
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
      }
    }
  }
}'

export REPO_NAME STATUS_NAME
gh api graphql --raw-field query="$QUERY" -F projectId="$PROJECT_ID" 2>/dev/null \
  | python3 -c "
import json, sys, os

REPO_NAME = os.getenv('REPO_NAME', 'all')
STATUS_NAME = os.getenv('STATUS_NAME', 'all')

repo_map = {
    'WnadeyaowuOraganization/wande-ai-backend': 'backend',
    'WnadeyaowuOraganization/wande-ai-front': 'front',
    'WnadeyaowuOraganization/wande-data-pipeline': 'pipeline',
    'WnadeyaowuOraganization/wande-gh-plugins': 'plugins',
}

data = json.load(sys.stdin)
items = data.get('data', {}).get('node', {}).get('items', {}).get('nodes', [])

print(f'Project #2: {REPO_NAME if REPO_NAME != \"all\" else \"all\"} / {STATUS_NAME if STATUS_NAME != \"all\" else \"all\"}')
print('=' * 100)

results = []
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
    if REPO_NAME != 'all' and repo_short != REPO_NAME:
        continue

    # 提取Status field
    status = '?'
    for fv in item.get('fieldValues', {}).get('nodes', []):
        field = fv.get('field') or {}
        if field.get('name') == 'Status':
            status = fv.get('name', '?')
            break

    if STATUS_NAME != 'all' and status != STATUS_NAME:
        continue

    results.append((status, num, repo_short, title))

# 按状态排序
status_order = {'Plan': 0, 'Todo': 1, 'In Progress': 2, 'pause': 3, 'Fail': 4, 'Done': 5, '?': 6}
results.sort(key=lambda x: (status_order.get(x[0], 9), x[1]))

for status, num, repo, title in results:
    print(f'{status:12} #{num:4} [{repo:20}] {title[:60]}')

print()
print(f'总数: {len(results)}')

# 机器可解析格式(stderr)
for status, num, repo, title in results:
    print(f'ISSUE_{num}={status}', file=sys.stderr)
"
