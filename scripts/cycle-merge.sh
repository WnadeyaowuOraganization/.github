#!/bin/bash
# cycle-merge.sh — 批量rebase feature分支，解决冲突
# 用法: bash scripts/cycle-merge.sh [max_cycles]
#
# 职责：只负责让feature分支与dev保持同步（rebase）
# PR合并由 pr-test.yml auto-merge job 负责（E2E通过后自动合并）

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
    export GIT_EDITOR=true  # 防止弹出编辑器
    if git rebase origin/dev 2>/dev/null; then
      git push --force origin "$branch" 2>/dev/null || true
      echo "✅ $(basename $dir): $branch rebase成功"
      rebase_count=$((rebase_count + 1))
      continue
    fi

    # rebase失败，检查冲突文件
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
      # 从分支名提取Issue号
      PR_NUM=$(gh pr list --repo WnadeyaowuOraganization/wande-play --head "$branch" --json number --jq '.[0].number' 2>/dev/null)
      if [ -n "$PR_NUM" ]; then
        echo "⚠️ $(basename $dir): $branch 有复杂冲突，触发CC解决 (PR#$PR_NUM)"
        bash "$SCRIPT_DIR/trigger-conflict-resolver.sh" "$PR_NUM" 2>/dev/null || true &
      else
        echo "⚠️ $(basename $dir): $branch 有复杂冲突，无对应PR"
      fi
    else
      # 只有简单冲突，继续rebase
      if GIT_EDITOR=true git rebase --continue 2>/dev/null; then
        git push --force origin "$branch" 2>/dev/null || true
        echo "✅ $(basename $dir): $branch rebase成功（简单冲突已解决）"
        rebase_count=$((rebase_count + 1))
      else
        git rebase --abort 2>/dev/null || true
        echo "❌ $(basename $dir): $branch rebase失败"
      fi
    fi
  done

  echo ""
  echo "本周期rebase成功: $rebase_count 个分支"

  [ $rebase_count -eq 0 ] && break  # 没有可处理的分支，退出
  sleep 10
done

echo ""
echo "=== 完成 ==="
echo "处理了 $cycle 个周期"
