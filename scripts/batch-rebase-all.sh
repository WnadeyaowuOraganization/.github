#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# batch-rebase-all.sh — 批量 rebase 所有外挂目录的 feature 分支
# 用法: bash scripts/batch-rebase-all.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GH_TOKEN已由caller设置（CC tmux会话），或自动获取
[ -n "$GH_TOKEN" ] || export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)

echo "=== 开始批量 rebase ==="
echo "时间: $(date)"

for i in $(seq 1 20); do
  dir="${HOME_DIR}/projects/wande-play-kimi$i"

  if [ ! -d "$dir" ]; then
    continue
  fi

  cd "$dir"
  branch=$(git branch --show-current 2>/dev/null)

  if [[ ! "$branch" =~ ^feature ]]; then
    echo "kimi$i: 跳过非 feature 分支 ($branch)"
    continue
  fi

  echo ""
  echo "=== kimi$i: $branch ==="

  # 清理工作目录
  git checkout -- . 2>/dev/null || true
  git clean -fd 2>/dev/null || true

  # 获取最新 dev
  git fetch origin dev 2>/dev/null

  # 尝试 rebase
  if git rebase origin/dev 2>&1; then
    echo "Rebase 成功"
    git push --force origin "$branch" 2>&1 || echo "Push 失败"
    echo "✅ kimi$i 完成"
  else
    # 有冲突，自动解决
    echo "检测到冲突，自动解决..."
    conflict_files=$(git diff --name-only --diff-filter=U 2>/dev/null)

    for file in $conflict_files; do
      echo "  解决: $file"
      git checkout --theirs "$file" 2>/dev/null || git checkout --ours "$file" 2>/dev/null || true
      git add "$file" 2>/dev/null || true
    done

    if git rebase --continue 2>&1; then
      git push --force origin "$branch" 2>&1 || echo "Push 失败"
      echo "✅ kimi$i 完成（已解决冲突）"
    else
      echo "❌ kimi$i rebase 失败"
      git rebase --abort 2>/dev/null || true
    fi
  fi
done

echo ""
echo "=== 批量 rebase 完成 ==="
echo "时间: $(date)"
