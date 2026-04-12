#!/bin/bash
# post-cc-cleanup.sh — CC 退出后的兜底清理
# 检查 PR 是否已合并，如果是则自动 close issue + 标 Done
# 用法: post-cc-cleanup.sh <issue_number>

ISSUE="$1"
[ -z "$ISSUE" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="WnadeyaowuOraganization/wande-play"

# 确保有 GH_TOKEN
export GH_TOKEN="${GH_TOKEN:-$(python3 ${SCRIPT_DIR}/gh-app-token.py 2>/dev/null)}"
[ -z "$GH_TOKEN" ] && exit 0

# 检查是否有已合并的 PR
PR_MERGED=$(gh pr list --repo "$REPO" --search "Issue-${ISSUE} in:branch" --state merged \
  --json number,mergedAt --jq '.[0].mergedAt // empty' 2>/dev/null)

if [ -z "$PR_MERGED" ]; then
  echo "[post-cc-cleanup] Issue #${ISSUE} 无已合并 PR，跳过"
  exit 0
fi

# 检查 Issue 是否已关闭
ISSUE_STATE=$(gh issue view "$ISSUE" --repo "$REPO" --json state --jq '.state' 2>/dev/null)
if [ "$ISSUE_STATE" = "OPEN" ]; then
  echo "[post-cc-cleanup] 关闭 Issue #${ISSUE}（PR 已合并但 Issue 未关闭）"
  gh issue close "$ISSUE" --repo "$REPO" --reason completed 2>/dev/null
fi

# 检查看板状态是否为 Done
echo "[post-cc-cleanup] 标记 Issue #${ISSUE} → Done"
bash "${SCRIPT_DIR}/update-project-status.sh" --repo play --issue "$ISSUE" --status "Done" 2>/dev/null
