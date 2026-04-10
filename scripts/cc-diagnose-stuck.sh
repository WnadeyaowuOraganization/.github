#!/bin/bash
# cc-diagnose-stuck.sh — 诊断卡住的编程 CC，分析原因并尝试修复
# 用法: bash scripts/cc-diagnose-stuck.sh
#
# 功能：
# 1. 扫描所有 lock 文件，找出异常状态（非 RUNNING）或长时间运行的 CC
# 2. 分析卡住原因（PR失败、部署失败、运行时间过长等）
# 3. 能自动修复的通过 tmux 发送提示给编程 CC
# 4. 需人工介入的输出到当前会话

set -e

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
LOCK_DIR="${HOME_DIR}/cc_scheduler/lock"
NOW=$(date +%s)
MAX_RUNTIME=$((3600 * 2))  # 2小时视为过长

echo "# 编程CC诊断报告"
echo "扫描时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

STUCK_ISSUES=()
AUTO_FIXABLE=()
NEED_MANUAL=()

# 遍历所有 lock 文件
for lockfile in "$LOCK_DIR"/wande-play-kimi*.lock; do
  [ ! -f "$lockfile" ] && continue

  DIRNAME=$(basename "$lockfile" .lock)
  KIMI_TAG=$(echo "$DIRNAME" | sed 's/^wande-play-//')

  # 解析 lock 文件
  ISSUE=$(grep "^issue=" "$lockfile" 2>/dev/null | cut -d= -f2)
  STATE=$(grep "^state=" "$lockfile" 2>/dev/null | cut -d= -f2)
  TIMESTAMP=$(grep "^timestamp=" "$lockfile" 2>/dev/null | cut -d= -f2)
  MODULE=$(grep "^module=" "$lockfile" 2>/dev/null | cut -d= -f2)
  EFFORT=$(grep "^effort=" "$lockfile" 2>/dev/null | cut -d= -f2)

  [ -z "$ISSUE" ] && continue
  [ -z "$STATE" ] && STATE="UNKNOWN"

  # 计算运行时长
  if [ -n "$TIMESTAMP" ] && [ "$TIMESTAMP" -gt 0 ] 2>/dev/null; then
    RUNTIME=$((NOW - TIMESTAMP))
    RUNTIME_MIN=$((RUNTIME / 60))
  else
    RUNTIME=0
    RUNTIME_MIN=0
  fi

  # 检查 tmux 会话是否存在
  SESSION="cc-${DIRNAME}-${ISSUE}"
  SESSION_EXISTS=false
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    SESSION_EXISTS=true
  fi

  # 判断问题类型
  PROBLEM_TYPE=""

  # 1. PR_CHECK_FAILED - CI检查失败
  if [ "$STATE" = "PR_CHECK_FAILED" ]; then
    PROBLEM_TYPE="PR_CHECK_FAILED"

    # 获取最新 PR 状态
    export GH_TOKEN=$(python3 "${HOME_DIR}/projects/.github/scripts/gh-app-token.py" 2>/dev/null)
    PR_NUM=$(gh pr list --repo WnadeyaowuOraganization/wande-play --head "feature-Issue-${ISSUE}" --state open --json number --jq '.[0].number' 2>/dev/null)

    if [ -n "$PR_NUM" ] && [ "$PR_NUM" != "null" ]; then
      # 检查失败原因
      PR_STATUS=$(gh pr checks "$PR_NUM" --repo WnadeyaowuOraganization/wande-play 2>/dev/null || echo "无法获取")
      PROBLEM_DETAIL="PR #$PR_NUM CI失败\n$PR_STATUS"

      # 尝试自动修复：让 CC 重新运行测试
      if [ "$SESSION_EXISTS" = "true" ]; then
        AUTO_FIXABLE+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|$PR_NUM")
      else
        NEED_MANUAL+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|$PROBLEM_DETAIL")
      fi
    else
      NEED_MANUAL+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|无法找到对应PR")
    fi

  # 2. DEPLOY_FAILED - 部署失败
  elif [ "$STATE" = "DEPLOY_FAILED" ]; then
    PROBLEM_TYPE="DEPLOY_FAILED"
    NEED_MANUAL+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|需要人工检查部署日志")

  # 3. RUNNING 时间过长（>2小时）
  elif [ "$STATE" = "RUNNING" ] && [ "$RUNTIME" -gt "$MAX_RUNTIME" ]; then
    PROBLEM_TYPE="LONG_RUNNING"
    NEED_MANUAL+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|已运行${RUNTIME_MIN}分钟，可能卡住")

  # 4. RUNNING 但会话不存在
  elif [ "$STATE" = "RUNNING" ] && [ "$SESSION_EXISTS" = "false" ]; then
    PROBLEM_TYPE="ORPHAN_LOCK"
    NEED_MANUAL+=("$DIRNAME|$ISSUE|$PROBLEM_TYPE|lock存在但tmux会话已消失")
  fi

done

echo ""
echo "## 发现问题统计"
echo "- 自动可修复: ${#AUTO_FIXABLE[@]} 个"
echo "- 需人工介入: ${#NEED_MANUAL[@]} 个"
echo ""

# 处理自动可修复的问题
if [ ${#AUTO_FIXABLE[@]} -gt 0 ]; then
  echo "## 🔧 自动修复中..."
  echo ""

  for item in "${AUTO_FIXABLE[@]}"; do
    IFS='|' read -r DIRNAME ISSUE PROBLEM_TYPE PR_NUM <<< "$item"
    SESSION="cc-${DIRNAME}-${ISSUE}"

    echo "### $DIRNAME Issue #$ISSUE ($PROBLEM_TYPE)"

    case "$PROBLEM_TYPE" in
      "PR_CHECK_FAILED")
        # 发送提示给 CC，告知 PR 失败并建议查看日志
        MESSAGE="⚠️ 检测到 PR #$PR_NUM CI 失败。请检查构建日志，修复问题后重新提交。"
        tmux send-keys -t "$SESSION" "$MESSAGE" C-m 2>/dev/null && \
          echo "✅ 已通过 tmux 发送提示" || \
          echo "❌ tmux 发送失败"
        ;;
    esac
    echo ""
  done
fi

# 输出需人工介入的问题
if [ ${#NEED_MANUAL[@]} -gt 0 ]; then
  echo "## ⚠️ 需人工介入"
  echo ""

  for item in "${NEED_MANUAL[@]}"; do
    IFS='|' read -r DIRNAME ISSUE PROBLEM_TYPE DETAIL <<< "$item"
    echo "- **$DIRNAME Issue #$ISSUE** ($PROBLEM_TYPE): $DETAIL"
  done
  echo ""
fi

# 总结
echo "---"
echo "诊断完成。"
