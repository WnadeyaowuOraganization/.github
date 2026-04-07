#!/bin/bash
# prefetch-issues.sh — 批量预下载Issue详情（含评论）到 wande-play/issues/issue-N/issue-source.md
#                      提交并推送到 dev 分支，run-cc.sh 启动时可跳过 gh fetch 步骤
#
# 用法:
#   bash prefetch-issues.sh 1234 5678 9012
#   bash prefetch-issues.sh $(echo "1533 2256 2304 2471")

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
REPO="WnadeyaowuOraganization/wande-play"
BASE_DIR="${HOME_DIR}/projects/wande-play"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
  echo "用法: $0 <issue-number> [issue-number ...]"
  echo "示例: $0 1533 2256 2304 2471 2363"
  exit 1
fi

export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null || echo "$GH_TOKEN")

# 确保在 dev 分支且已 pull
cd "$BASE_DIR"
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "dev" ]; then
  echo "当前分支: $CURRENT_BRANCH，切换到 dev..."
  git stash 2>/dev/null
  git checkout dev 2>/dev/null
fi
git pull origin dev --quiet 2>/dev/null

FETCHED=0
SKIPPED=0
FAILED=0

for ISSUE in "$@"; do
  ISSUE_DIR="$BASE_DIR/issues/issue-${ISSUE}"
  ISSUE_SOURCE="$ISSUE_DIR/issue-source.md"
  mkdir -p "$ISSUE_DIR"

  # 已存在则跳过（避免覆盖 CC 运行中写入的内容）
  if [ -f "$ISSUE_SOURCE" ]; then
    echo "⏭  #${ISSUE} 已存在，跳过"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo -n "↓  #${ISSUE} 下载中... "

  # 下载 issue 基本信息
  ISSUE_BODY=$(gh issue view "$ISSUE" --repo "$REPO" \
    --json number,title,body,labels,state \
    --jq '"# Issue #\(.number): \(.title)\n\n**Labels**: \([.labels[].name] | join(", "))\n**State**: \(.state)\n\n## 需求内容\n\n\(.body)"' 2>/dev/null)

  if [ -z "$ISSUE_BODY" ]; then
    echo "✗ 下载失败"
    FAILED=$((FAILED + 1))
    continue
  fi

  # 下载评论
  ISSUE_COMMENTS=$(gh issue view "$ISSUE" --repo "$REPO" \
    --comments --json comments \
    --jq 'if (.comments | length) > 0 then "\n\n---\n\n## 评论\n\n" + ([.comments[] | "### \(.author.login) (\(.createdAt | split("T")[0]))\n\n\(.body)"] | join("\n\n---\n\n")) else "" end' 2>/dev/null)

  echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
  echo "✓ ($(wc -l < "$ISSUE_SOURCE") 行)"
  FETCHED=$((FETCHED + 1))
done

echo ""
echo "完成: ${FETCHED} 个下载, ${SKIPPED} 个跳过, ${FAILED} 个失败"

# 有新文件才 commit + push
if [ "$FETCHED" -gt 0 ]; then
  ISSUE_LIST=$(echo "$@" | tr ' ' ',')
  git add issues/
  git commit -m "chore: 预下载 Issue #${ISSUE_LIST} source.md 到 dev" \
    --author "Wande AI Bot <bot@wande.ai>" 2>/dev/null
  git push origin dev --quiet 2>/dev/null && echo "✓ 已推送到 dev 分支" || echo "✗ push 失败，请手动推送"
else
  echo "无新文件，跳过 commit"
fi
