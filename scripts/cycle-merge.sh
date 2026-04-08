#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# cycle-merge.sh — rebase feature分支 + 冲突解决
#
# 用法:
#   bash scripts/cycle-merge.sh <pr_number>     # 指定PR解决冲突
#   bash scripts/cycle-merge.sh --all [cycles]  # 批量扫描所有外挂目录
#
# 职责：
# 1. feature分支与dev保持同步（rebase）
# 2. 简单冲突自动解决（schema/pom/test）
# 3. 复杂冲突在CI目录触发编程CC智能解决
#
# PR合并由 pr-test.yml auto-merge job 负责

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GH_TOKEN已由caller设置（CC tmux会话），或自动获取
[ -n "$GH_TOKEN" ] || export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)
CI_DIR="${HOME_DIR}/projects/wande-play-ci"

# === 复杂冲突处理：在CI目录触发CC ===
resolve_complex_conflict() {
  local pr_num=$1
  local branch=$2

  [ -z "$pr_num" ] && return 1

  local title=$(gh pr view "$pr_num" --repo WnadeyaowuOraganization/wande-play --json title --jq '.title' 2>/dev/null)

  cd "$CI_DIR"
  git fetch origin dev "$branch" 2>/dev/null
  git checkout dev && git reset --hard origin/dev && git clean -fd
  git checkout -B "conflict-resolve-$pr_num" "origin/$branch" 2>/dev/null || return 1

  export GIT_EDITOR=true
  if git rebase origin/dev 2>/dev/null; then
    git push --force origin "$branch" 2>/dev/null || true
    git checkout dev 2>/dev/null
    return 0
  fi

  local conflict_files=$(git diff --name-only --diff-filter=U 2>/dev/null)
  local conflict_count=$(echo "$conflict_files" | grep -c .)
  git rebase --abort 2>/dev/null || true

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

  local prompt="解决 PR #$pr_num 的合并冲突。
阅读 issues/issue-pr-$pr_num/conflict.md 了解冲突详情。
对每个冲突文件理解双方修改意图，智能合并不丢失功能。
运行编译测试确保代码正确，完成后提交推送到 $branch 分支。"

  bash "$SCRIPT_DIR/run-cc.sh" --module app --prompt "$prompt" --model claude-sonnet-4-6 --dir ci --effort high || true

  git checkout dev 2>/dev/null
  return 0
}

# === 单个分支rebase ===
rebase_branch() {
  local dir=$1
  local branch=$2

  cd "$dir"
  git checkout -- . 2>/dev/null || true
  git clean -fd 2>/dev/null || true
  git fetch origin dev 2>/dev/null

  export GIT_EDITOR=true
  if git rebase origin/dev 2>/dev/null; then
    git push --force origin "$branch" 2>/dev/null || true
    echo "✅ $(basename $dir): $branch rebase成功"
    return 0
  fi

  CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)
  if [ -z "$CONFLICT_FILES" ]; then
    git rebase --abort 2>/dev/null || true
    echo "❌ $(basename $dir): $branch rebase失败（非冲突原因）"
    return 1
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
    local pr_num=$(gh pr list --repo WnadeyaowuOraganization/wande-play --head "$branch" --json number --jq '.[0].number' 2>/dev/null)
    echo "⚠️ $(basename $dir): $branch 有复杂冲突 (PR#${pr_num:-?})"
    resolve_complex_conflict "$pr_num" "$branch" &
    return 2
  elif GIT_EDITOR=true git rebase --continue 2>/dev/null; then
    git push --force origin "$branch" 2>/dev/null || true
    echo "✅ $(basename $dir): $branch rebase成功（简单冲突已解决）"
    return 0
  else
    git rebase --abort 2>/dev/null || true
    echo "❌ $(basename $dir): $branch rebase失败"
    return 1
  fi
}

# === 主入口 ===
if [ "$1" = "--all" ]; then
  # 批量模式：扫描所有外挂目录
  MAX_CYCLES=${2:-10}
  cycle=0

  while [ $cycle -lt $MAX_CYCLES ]; do
    cycle=$((cycle + 1))
    echo ""
    echo "=========================================="
    echo "周期 $cycle/$MAX_CYCLES - $(date)"
    echo "=========================================="

    rebase_count=0
    for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
      [ ! -d "$dir" ] && continue
      branch=$(cd "$dir" && git branch --show-current 2>/dev/null)
      [[ ! "$branch" =~ ^feature ]] && continue
      rebase_branch "$dir" "$branch" && rebase_count=$((rebase_count + 1))
    done

    echo "本周期rebase成功: $rebase_count 个分支"
    [ $rebase_count -eq 0 ] && break
    sleep 10
  done

  echo ""
  echo "=== 完成 ($cycle 个周期) ==="

else
  # 指定PR模式
  PR_NUM=$1
  if [ -z "$PR_NUM" ]; then
    echo "用法:"
    echo "  $0 <pr_number>      指定PR解决冲突"
    echo "  $0 --all [cycles]   批量扫描所有外挂目录"
    exit 1
  fi

  BRANCH=$(gh pr view "$PR_NUM" --repo WnadeyaowuOraganization/wande-play --json headRefName --jq '.headRefName' 2>/dev/null)
  if [ -z "$BRANCH" ]; then
    echo "ERROR: 无法获取PR #$PR_NUM 的分支信息"
    exit 1
  fi

  echo "=== 处理 PR #$PR_NUM ($BRANCH) ==="

  # 找到该分支所在的外挂目录
  TARGET_DIR=""
  for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
    [ ! -d "$dir" ] && continue
    current=$(cd "$dir" && git branch --show-current 2>/dev/null)
    if [ "$current" = "$BRANCH" ]; then
      TARGET_DIR="$dir"
      break
    fi
  done

  if [ -n "$TARGET_DIR" ]; then
    rebase_branch "$TARGET_DIR" "$BRANCH"
  else
    # 分支不在外挂目录，直接在CI目录处理
    echo "分支不在外挂目录，在CI目录处理"
    resolve_complex_conflict "$PR_NUM" "$BRANCH"
  fi
fi
