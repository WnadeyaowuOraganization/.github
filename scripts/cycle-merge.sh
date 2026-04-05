#!/bin/bash
# cycle-merge.sh — 批量rebase feature分支 + 冲突解决
# 用法: bash scripts/cycle-merge.sh [max_cycles]
#
# 职责：
# 1. feature分支与dev保持同步（rebase）
# 2. 简单冲突自动解决（schema/pom/test）
# 3. 复杂冲突在CI目录触发编程CC智能解决
#
# PR合并由 pr-test.yml auto-merge job 负责

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)
CI_DIR="/home/ubuntu/projects/wande-play-ci"

MAX_CYCLES=${1:-10}
cycle=0

# === 复杂冲突处理：在CI目录触发CC ===
resolve_complex_conflict() {
  local pr_num=$1
  local branch=$2

  [ -z "$pr_num" ] && return 1

  # 获取PR信息
  local title=$(gh pr view "$pr_num" --repo WnadeyaowuOraganization/wande-play --json title --jq '.title' 2>/dev/null)

  # 在CI目录操作
  cd "$CI_DIR"
  git fetch origin dev "$branch" 2>/dev/null
  git checkout dev && git reset --hard origin/dev && git clean -fd
  git checkout -B "conflict-resolve-$pr_num" "origin/$branch" 2>/dev/null || return 1

  # rebase获取冲突详情
  export GIT_EDITOR=true
  if git rebase origin/dev 2>/dev/null; then
    # 无冲突了（可能其他分支已解决）
    git push --force origin "$branch" 2>/dev/null || true
    git checkout dev 2>/dev/null
    return 0
  fi

  # 收集冲突信息
  local conflict_files=$(git diff --name-only --diff-filter=U 2>/dev/null)
  local conflict_count=$(echo "$conflict_files" | grep -c .)
  git rebase --abort 2>/dev/null || true

  # 生成conflict.md
  mkdir -p "$CI_DIR/issues/issue-pr-$pr_num"
  cat > "$CI_DIR/issues/issue-pr-$pr_num/conflict.md" << EOF
# PR #$pr_num 合并冲突

## 基本信息
- PR: #$pr_num
- 标题: $title
- 分支: $branch -> dev

## 冲突文件 ($conflict_count 个)
\`\`\`
$conflict_files
\`\`\`

## 任务
1. 解决上述冲突文件
2. 确保合并后代码编译通过
3. 不要丢失任何功能代码
4. 完成后推送并通知
EOF

  # 触发CC
  local prompt="解决 PR #$pr_num 的合并冲突。
阅读 issues/issue-pr-$pr_num/conflict.md 了解冲突详情。
对每个冲突文件理解双方修改意图，智能合并不丢失功能。
运行编译测试确保代码正确，完成后提交推送到 $branch 分支。"

  bash "$SCRIPT_DIR/run-cc.sh" --prompt "conflict-resolver" "$prompt" "claude-sonnet-4-6" "ci" "high" || true

  git checkout dev 2>/dev/null
  return 0
}

# === 主循环 ===
while [ $cycle -lt $MAX_CYCLES ]; do
  cycle=$((cycle + 1))
  echo ""
  echo "=========================================="
  echo "周期 $cycle/$MAX_CYCLES - $(date)"
  echo "=========================================="

  rebase_count=0

  for dir in /home/ubuntu/projects/wande-play-kimi{1..20}; do
    [ ! -d "$dir" ] && continue

    cd "$dir"
    branch=$(git branch --show-current 2>/dev/null)
    [[ ! "$branch" =~ ^feature ]] && continue

    # 清理工作区
    git checkout -- . 2>/dev/null || true
    git clean -fd 2>/dev/null || true
    git fetch origin dev 2>/dev/null

    # 尝试rebase
    export GIT_EDITOR=true
    if git rebase origin/dev 2>/dev/null; then
      git push --force origin "$branch" 2>/dev/null || true
      echo "✅ $(basename $dir): $branch rebase成功"
      rebase_count=$((rebase_count + 1))
      continue
    fi

    # rebase失败，检查冲突
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
    if [ -z "$CONFLICT_FILES" ]; then
      git rebase --abort 2>/dev/null || true
      echo "❌ $(basename $dir): $branch rebase失败（非冲突原因）"
      continue
    fi

    # 分类冲突
    HAS_COMPLEX=false
    for file in $CONFLICT_FILES; do
      case "$file" in
        *schema*.sql|*h2*.sql|*pom.xml|*/test/*|*Test.java|*.test.ts|*.spec.ts)
          git checkout --theirs "$file" 2>/dev/null || true
          git add "$file" 2>/dev/null || true
          ;;
        *.java|*.ts|*.vue|*.tsx|*.py)
          HAS_COMPLEX=true
          break
          ;;
        *)
          git checkout --theirs "$file" 2>/dev/null || true
          git add "$file" 2>/dev/null || true
          ;;
      esac
    done

    if [ "$HAS_COMPLEX" = true ]; then
      git rebase --abort 2>/dev/null || true
      PR_NUM=$(gh pr list --repo WnadeyaowuOraganization/wande-play --head "$branch" --json number --jq '.[0].number' 2>/dev/null)
      echo "⚠️ $(basename $dir): $branch 有复杂冲突，触发CC解决 (PR#${PR_NUM:-?})"
      resolve_complex_conflict "$PR_NUM" "$branch" &
    elif GIT_EDITOR=true git rebase --continue 2>/dev/null; then
      git push --force origin "$branch" 2>/dev/null || true
      echo "✅ $(basename $dir): $branch rebase成功（简单冲突已解决）"
      rebase_count=$((rebase_count + 1))
    else
      git rebase --abort 2>/dev/null || true
      echo "❌ $(basename $dir): $branch rebase失败"
    fi
  done

  echo ""
  echo "本周期rebase成功: $rebase_count 个分支"

  [ $rebase_count -eq 0 ] && break
  sleep 10
done

echo ""
echo "=== 完成 ==="
echo "处理了 $cycle 个周期"
