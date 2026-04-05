#!/bin/bash
# check-cc-status.sh — 检查CC状态和Issue完成情况

LOGDIR=/home/ubuntu/cc_scheduler/logs
SCRIPT_DIR="/home/ubuntu/projects/.github/scripts"
REPORT_FILE="/home/ubuntu/cc_scheduler/status-report.md"

echo "## CC状态检查报告 — $(date '+%Y-%m-%d %H:%M:%S')" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 1. 检查运行中的CC会话
echo "### 运行中的CC会话" >> "$REPORT_FILE"
tmux list-sessions 2>/dev/null | grep "^cc-" | while read line; do
    echo "- $line" >> "$REPORT_FILE"
done
echo "" >> "$REPORT_FILE"

# 2. 检查最近完成的CC（日志文件最后状态）
echo "### 最近完成的CC" >> "$REPORT_FILE"
for log in $LOGDIR/*.log; do
    if [ -f "$log" ]; then
        last_line=$(tail -1 "$log" 2>/dev/null)
        if echo "$last_line" | grep -q "COMPLETED"; then
            basename "$log" | sed 's/.log//' >> "$REPORT_FILE"
        fi
    fi
done
echo "" >> "$REPORT_FILE"

# 3. 检查In Progress的Issue的真实状态
# 检测逻辑：
# - 检查tmux会话是否存在
# - 检查会话中是否有活跃的claude进程（工作中）
# - 检查日志最后状态（COMPLETED/ERROR）
# - 检查PR是否已创建

echo "### In Progress Issue状态" >> "$REPORT_FILE"
for session in $(tmux list-sessions 2>/dev/null | grep "^cc-" | cut -d: -f1); do
    # 提取repo和issue number
    repo=$(echo "$session" | cut -d- -f2)
    issue=$(echo "$session" | cut -d- -f3)

    if [ "$repo" = "backend" ] || [ "$repo" = "frontend" ] || [ "$repo" = "pipeline" ]; then
        repo_full="WnadeyaowuOraganization/wande-play"
    else
        repo_full="WnadeyaowuOraganization/wande-gh-plugins"
    fi

    # 检查该session对应的tmux pane中是否有claude进程在运行
    pane_pid=$(tmux list-panes -t "$session" -F "#{pane_pid}" 2>/dev/null | head -1)
    has_claude_running="false"
    if [ -n "$pane_pid" ]; then
        # 检查该pane的后代进程中是否有claude
        if ps -o pid,args --ppid "$pane_pid" 2>/dev/null | grep -q "claude"; then
            has_claude_running="true"
        fi
    fi

    # 检查日志最后状态
    logfile="$LOGDIR/${repo}-${issue}.log"
    log_status=""
    if [ -f "$logfile" ]; then
        last_line=$(tail -5 "$logfile" 2>/dev/null | grep -E "(COMPLETED|ERROR|Failed)" | tail -1)
        if echo "$last_line" | grep -q "COMPLETED"; then
            log_status="completed"
        elif echo "$last_line" | grep -qE "(ERROR|Failed)"; then
            log_status="error"
        fi
    fi

    # 检查PR状态
    pr_count=$(gh pr list --repo "$repo_full" --search "Issue-$issue" --state open --json number -q '. | length' 2>/dev/null)
    pr_status=""
    if [ "$pr_count" -gt 0 ]; then
        pr_status="has_pr"
    fi

    # 综合判断状态
    if [ "$has_claude_running" = "true" ]; then
        # claude还在运行，检查最近活跃时间
        last_active=$(stat -c "%Y" "$logfile" 2>/dev/null)
        now=$(date +%s)
        idle_minutes=$(( (now - last_active) / 60 ))
        if [ "$idle_minutes" -lt 5 ]; then
            echo "- $session: 🔥 **工作中** (最近活跃)" >> "$REPORT_FILE"
        elif [ "$idle_minutes" -ge 20 ]; then
            echo "- $session: 🚨 **超时${idle_minutes}分钟，自动清理**" >> "$REPORT_FILE"
            # 超时处理：通知+标Fail+清理
            curl -s -X POST https://api.getmoshi.app/api/webhook \
              -H "Content-Type: application/json" \
              -d "{\"token\": \"RIVRunZDC2B2WzqII04IdKfzkr4MEfCS\", \"title\": \"CC超时\", \"message\": \"${repo}#${issue}已空闲${idle_minutes}分钟，自动清理\"}" 2>/dev/null || true
            bash "$SCRIPT_DIR/update-project-status.sh" play "$issue" "Fail" 2>/dev/null || true
            tmux kill-session -t "$session" 2>/dev/null || true
        else
            echo "- $session: ⏸️ **可能卡住** (${idle_minutes}分钟无输出)" >> "$REPORT_FILE"
        fi
    elif [ "$log_status" = "completed" ]; then
        if [ "$pr_status" = "has_pr" ]; then
            echo "- $session: ✅ **已完成，PR已创建**" >> "$REPORT_FILE"
        else
            echo "- $session: ⏳ **等待创建PR** (CC已完成)" >> "$REPORT_FILE"
        fi
    elif [ "$log_status" = "error" ]; then
        echo "- $session: ❌ **执行出错**" >> "$REPORT_FILE"
    else
        echo "- $session: ⏳ **等待PR** (状态未知)" >> "$REPORT_FILE"
    fi
done
echo "" >> "$REPORT_FILE"

# 4. 统计空闲目录
echo "### 目录使用情况" >> "$REPORT_FILE"
active_count=$(tmux list-sessions 2>/dev/null | grep "^cc-" | wc -l)
available_count=$((20 - active_count))
echo "- 活跃CC: $active_count" >> "$REPORT_FILE"
echo "- 空闲目录: $available_count" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 5. 检查Todo队列中的P0 Issue
echo "### 待处理P0 Issue数量" >> "$REPORT_FILE"
bash "$SCRIPT_DIR/query-project-issues.sh" play "Todo" 2>/dev/null | grep "P0" | wc -l | xargs -I {} echo "- wande-play Todo P0: {}" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 6. 读取编程CC进度（task.md）
echo "### 编程CC进度（task.md）" >> "$REPORT_FILE"
for dir in /home/ubuntu/projects/wande-play-kimi{1..20}; do
  if [ ! -d "$dir" ]; then continue; fi
  task=$(find "$dir" -path "*/issues/*/task.md" -mmin -120 2>/dev/null | head -1)
  if [ -n "$task" ]; then
    issue_dir=$(basename $(dirname "$task"))
    status=$(head -5 "$task" | grep "^## Status:" | sed 's/## Status: //')
    phase=$(head -5 "$task" | grep "^## Phase:" | sed 's/## Phase: //')
    echo "- $(basename $dir)/$issue_dir: **${status:-?}** (${phase:-?})" >> "$REPORT_FILE"
  fi
done
echo "" >> "$REPORT_FILE"

cat "$REPORT_FILE"
