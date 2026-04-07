#!/bin/bash
# 回补未关联 Project#4 的 Issue
# 用法：bash scripts/backfill-project-issues.sh [起始Issue号，默认2830]

export GH_TOKEN=$(bash "$(dirname "$0")/get-gh-token.sh" 2>/dev/null)
PROJECT_ID="PVT_kwDOD3gg584BTjK2"
FIELD_ID="PVTSSF_lADOD3gg584BTjK2zhAxafs"
PLAN_OPTION="a07b604b"
REPO="WnadeyaowuOraganization/wande-play"
START_ISSUE="${1:-2830}"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

add_issue() {
  local number=$1
  local node_id
  node_id=$(gh api "repos/$REPO/issues/$number" --jq '.node_id' 2>/dev/null) || return

  # 已在 Project 则跳过
  local exists
  exists=$(gh api graphql -f query="{ node(id: \"$node_id\") {
    ... on Issue { projectItems(first:5) { nodes { project { id } } } }
  } }" --jq ".data.node.projectItems.nodes[] | select(.project.id==\"$PROJECT_ID\")" 2>/dev/null)
  [ -n "$exists" ] && { log "✓ #$number 已存在"; return; }

  # 加入 Project
  local item_id
  item_id=$(gh api graphql -f query="mutation {
    addProjectV2ItemById(input:{ projectId:\"$PROJECT_ID\", contentId:\"$node_id\" }) {
      item { id }
    }
  }" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null)
  [ -z "$item_id" ] && { log "❌ #$number 失败（rate limit？）"; sleep 3; return; }

  # 设为 Plan
  gh api graphql -f query="mutation {
    updateProjectV2ItemFieldValue(input:{
      projectId:\"$PROJECT_ID\", itemId:\"$item_id\",
      fieldId:\"$FIELD_ID\", value:{ singleSelectOptionId:\"$PLAN_OPTION\" }
    }) { projectV2Item { id } }
  }" > /dev/null 2>&1

  log "✅ #$number → Project#4/Plan"
  sleep 0.5
}

log "查询 #$START_ISSUE 之后的所有 Issue..."
NUMS=$(gh issue list --repo "$REPO" --state all --limit 1000 \
  --json number --jq "[.[] | .number | select(. >= $START_ISSUE)] | sort[]" 2>/dev/null)

COUNT=$(echo "$NUMS" | wc -l)
log "共 $COUNT 个 Issue，开始回补..."

for num in $NUMS; do
  add_issue "$num"
done

log "全部完成"
