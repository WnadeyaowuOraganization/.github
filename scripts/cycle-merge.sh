#!/bin/bash
# cycle-merge.sh — 循环处理 PR：rebase → 等待 → 合并 → 重复
# 用法: bash scripts/cycle-merge.sh [max_cycles]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)

MAX_CYCLES=${1:-10}
cycle=0

while [ $cycle -lt $MAX_CYCLES ]; do
  cycle=$((cycle + 1))
  echo ""
  echo "=========================================="
  echo "周期 $cycle/$MAX_CYCLES - $(date)"
  echo "=========================================="

  # Step 1: 检查可合并的 PR
  echo ""
  echo "=== Step 1: 检查可合并的 PR ==="
  mergeable=$(gh pr list --repo WnadeyaowuOraganization/wande-play --state open --limit 100 --json number,mergeable,headRefName 2>/dev/null | jq -r '.[] | select(.mergeable == true or .mergeable == "MERGEABLE") | select(.headRefName | startswith("feature")) | .number')

  if [ -n "$mergeable" ]; then
    echo "找到可合并的 PR: $mergeable"
    for pr in $mergeable; do
      echo "合并 PR #$pr..."
      gh pr merge "$pr" --repo WnadeyaowuOraganization/wande-play --squash --delete-branch 2>&1 || echo "合并失败"
      sleep 2
    done
    echo "等待 dev 分支更新..."
    sleep 10
    continue
  else
    echo "没有可合并的 PR"
  fi

  # Step 2: 批量 rebase
  echo ""
  echo "=== Step 2: 批量 rebase ==="

  for dir in /home/ubuntu/projects/wande-play-kimi{1..20}; do
    if [ ! -d "$dir" ]; then
      continue
    fi

    cd "$dir"
    branch=$(git branch --show-current 2>/dev/null)

    if [[ ! "$branch" =~ ^feature ]]; then
      continue
    fi

    # 清理并获取最新 dev
    git checkout -- . 2>/dev/null || true
    git clean -fd 2>/dev/null || true
    git fetch origin dev 2>/dev/null

    # Rebase
    if git rebase origin/dev 2>&1 | grep -q "Successfully rebased"; then
      git push --force origin "$branch" 2>/dev/null || true
      echo "✅ $branch rebase 成功"
    elif git diff --name-only --diff-filter=U 2>/dev/null | grep -q .; then
      # 有冲突，自动解决
      for file in $(git diff --name-only --diff-filter=U 2>/dev/null); do
        git checkout --theirs "$file" 2>/dev/null || git checkout --ours "$file" 2>/dev/null || true
        git add "$file" 2>/dev/null || true
      done
      if git rebase --continue 2>&1 | grep -q "Successfully rebased"; then
        git push --force origin "$branch" 2>/dev/null || true
        echo "✅ $branch rebase 成功（已解决冲突）"
      else
        git rebase --abort 2>/dev/null || true
        echo "❌ $branch rebase 失败"
      fi
    fi
  done

  # Step 3: 检查剩余 PR 数量
  echo ""
  echo "=== Step 3: 检查剩余 PR ==="
  remaining=$(gh pr list --repo WnadeyaowuOraganization/wande-play --state open --limit 100 --json number 2>/dev/null | jq 'length')
  echo "剩余打开的 PR: $remaining"

  if [ "$remaining" -le 1 ]; then
    echo "所有 PR 已处理完成！"
    break
  fi

  # 等待 GitHub 更新状态
  echo "等待 GitHub 更新状态..."
  sleep 15
done

echo ""
echo "=== 完成 ==="
echo "处理了 $cycle 个周期"
