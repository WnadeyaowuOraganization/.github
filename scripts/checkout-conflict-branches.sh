#!/bin/bash
# checkout-conflict-branches.sh — 批量 checkout 有冲突的 PR 分支到外挂目录
# 用法: bash scripts/checkout-conflict-branches.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)

echo "=== 获取有冲突的 PR 分支列表 ==="

# 获取所有有冲突的 PR 分支
conflict_branches=$(gh pr list --repo WnadeyaowuOraganization/wande-play --state open --limit 100 --json headRefName 2>/dev/null | jq -r '.[] | select(.headRefName | startswith("feature")) | .headRefName')

# 获取外挂目录中已有的分支
declare -A existing_branches
for dir in /home/ubuntu/projects/wande-play-kimi{1..20}; do
  if [ -d "$dir" ]; then
    cd "$dir"
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
      existing_branches["$branch"]="$dir"
    fi
    cd - > /dev/null
  fi
done

# 找出需要 checkout 的分支
need_checkout=()
for branch in $conflict_branches; do
  if [ -z "${existing_branches[$branch]}" ]; then
    need_checkout+=("$branch")
  fi
done

echo "需要 checkout 的分支数量: ${#need_checkout[@]}"

# 找出空闲的外挂目录（其分支不在冲突列表中）
available_dirs=()
for dir in /home/ubuntu/projects/wande-play-kimi{1..20}; do
  if [ -d "$dir" ]; then
    cd "$dir"
    branch=$(git branch --show-current 2>/dev/null)
    # 如果当前分支不在冲突列表中，这个目录可以用来 checkout 新分支
    if ! echo "$conflict_branches" | grep -q "^${branch}$"; then
      available_dirs+=("$dir")
    fi
    cd - > /dev/null
  fi
done

echo "可用目录数量: ${#available_dirs[@]}"

# 批量 checkout
i=0
for branch in "${need_checkout[@]}"; do
  if [ $i -ge ${#available_dirs[@]} ]; then
    echo "没有更多可用目录"
    break
  fi

  dir="${available_dirs[$i]}"
  echo ""
  echo "=== Checkout $branch 到 $dir ==="

  cd "$dir"

  # 清理
  git checkout -- . 2>/dev/null || true
  git clean -fd 2>/dev/null || true

  # Checkout 分支
  if git checkout "$branch" 2>/dev/null; then
    echo "✅ 已 checkout $branch"
  else
    # 从远程 checkout
    git fetch origin "$branch" 2>/dev/null
    if git checkout -b "$branch" "origin/$branch" 2>&1; then
      echo "✅ 已从远程 checkout $branch"
    else
      echo "❌ 无法 checkout $branch"
    fi
  fi

  cd - > /dev/null
  i=$((i + 1))
done

echo ""
echo "=== 完成 ==="
echo "处理了 $i 个分支"
