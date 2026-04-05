#!/bin/bash
# sync-project-status.sh - 同步Project #4看板状态与issue状态
#
# 解决的问题：
# 1. Done|OPEN: PR已merge但issue未关闭 → 关闭issue
# 2. CLOSED但看板非Done: issue已关闭但看板未更新 → 更新看板为Done
#
# 用法:
#   sync-project-status.sh              # 执行同步（dry-run）
#   sync-project-status.sh --apply      # 实际执行修改
#
# v1 (2026-04-05): 初始版本

set -e

APPLY_MODE="${1:-}"

if [ "$APPLY_MODE" != "--apply" ]; then
    echo "=== DRY-RUN 模式 ==="
    echo "使用 --apply 参数执行实际修改"
    echo
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

PROJECT_ID="PVT_kwDOD3gg584BTjK2"
FIELD_ID="PVTSSF_lADOD3gg584BTjK2zhAxafs"
DONE_OPTION_ID="c8f40892"
OWNER="WnadeyaowuOraganization"
REPO="wande-play"

# 收集所有items（分页）
collect_all_items() {
    local cursor=""
    local has_next="true"
    local all_data=""

    while [ "$has_next" = "true" ]; do
        if [ -z "$cursor" ]; then
            result=$(gh api graphql -f query='
query {
  node(id: "'"$PROJECT_ID"'") {
    ... on ProjectV2 {
      items(first: 100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            ... on Issue { number state }
          }
        }
      }
    }
  }
}' 2>/dev/null)
        else
            result=$(gh api graphql -f query='
query($after: String) {
  node(id: "'"$PROJECT_ID"'") {
    ... on ProjectV2 {
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            ... on Issue { number state }
          }
        }
      }
    }
  }
}' -f after="$cursor" 2>/dev/null)
        fi

        # 提取数据
        items=$(echo "$result" | jq -r '.data.node.items.nodes[] | select(.content.number != null) | "\(.id)|\(.fieldValueByName.name // "none")|\(.content.state)|\(.content.number)"')
        all_data="$all_data$items"$'\n'

        has_next=$(echo "$result" | jq -r '.data.node.items.pageInfo.hasNextPage')
        cursor=$(echo "$result" | jq -r '.data.node.items.pageInfo.endCursor')
    done

    echo "$all_data"
}

# 检查issue是否有merged PR
has_merged_pr() {
    local issue_num=$1
    local result=$(gh api graphql -f query='
query {
  repository(owner: "'"$OWNER"'", name: "'"$REPO"'") {
    issue(number: '"$issue_num"') {
      timelineItems(first: 20, itemTypes: [CROSS_REFERENCED_EVENT]) {
        nodes {
          ... on CrossReferencedEvent {
            source {
              ... on PullRequest { number state merged }
            }
          }
        }
      }
    }
  }
}' 2>/dev/null)

    local merged_count=$(echo "$result" | jq '[.data.repository.issue.timelineItems.nodes[].source | select(.merged == true)] | length')
    [ "$merged_count" -gt 0 ]
}

# 关闭issue
close_issue() {
    local issue_num=$1
    if [ "$APPLY_MODE" = "--apply" ]; then
        gh issue close "$issue_num" -R "$OWNER/$REPO" --comment "自动化关闭：PR已合并，任务完成" 2>/dev/null
        echo "  ✓ Issue #$issue_num 已关闭"
    else
        echo "  [DRY-RUN] 将关闭 Issue #$issue_num"
    fi
}

# 更新看板状态为Done
update_board_status() {
    local item_id=$1
    local issue_num=$2
    if [ "$APPLY_MODE" = "--apply" ]; then
        gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: "'"$DONE_OPTION_ID"'" }
  }) { projectV2Item { id } }
}' -F projectId="$PROJECT_ID" -F itemId="$item_id" -F fieldId="$FIELD_ID" > /dev/null 2>&1
        echo "  ✓ Issue #$issue_num 看板状态 → Done"
    else
        echo "  [DRY-RUN] 将更新 Issue #$issue_num 看板状态 → Done"
    fi
}

echo "收集Project #4所有items..."
ALL_ITEMS=$(collect_all_items)

# 统计
echo
echo "=== 状态统计 ==="
echo "$ALL_ITEMS" | grep -v '^$' | awk -F'|' '{print $2 "|" $3}' | sort | uniq -c | sort -rn

# 处理 Done|OPEN
echo
echo "=== 处理 Done|OPEN (PR已merge但issue未关闭) ==="
DONE_OPEN=$(echo "$ALL_ITEMS" | grep -v '^$' | awk -F'|' '$2 == "Done" && $3 == "OPEN" {print}')
DONE_OPEN_COUNT=$(echo "$DONE_OPEN" | grep -c . || true)
echo "发现 $DONE_OPEN_COUNT 个 Done|OPEN issue"

if [ -n "$DONE_OPEN" ]; then
    echo "$DONE_OPEN" | while IFS='|' read -r item_id status state issue_num; do
        [ -z "$issue_num" ] && continue
        if has_merged_pr "$issue_num"; then
            close_issue "$issue_num"
        else
            echo "  ⚠ Issue #$issue_num 无merged PR，跳过"
        fi
    done
fi

# 处理 CLOSED 但看板非Done
echo
echo "=== 处理 CLOSED 但看板非Done ==="
CLOSED_NOT_DONE=$(echo "$ALL_ITEMS" | grep -v '^$' | awk -F'|' '$3 == "CLOSED" && $2 != "Done" {print}')
CLOSED_COUNT=$(echo "$CLOSED_NOT_DONE" | grep -c . || true)
echo "发现 $CLOSED_COUNT 个 CLOSED 但看板非Done 的issue"

if [ -n "$CLOSED_NOT_DONE" ]; then
    echo "$CLOSED_NOT_DONE" | while IFS='|' read -r item_id status state issue_num; do
        [ -z "$issue_num" ] && continue
        echo "  Issue #$issue_num (当前: $status)"
        update_board_status "$item_id" "$issue_num"
    done
fi

echo
echo "=== 同步完成 ==="
if [ "$APPLY_MODE" != "--apply" ]; then
    echo "提示: 使用 --apply 参数执行实际修改"
fi
