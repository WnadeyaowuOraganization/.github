#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# check-cc-status.sh — 检查CC状态和Issue完成情况

LOGDIR=${HOME_DIR}/cc_scheduler/logs
SCRIPT_DIR="${HOME_DIR}/projects/.github/scripts"
REPORT_FILE="${HOME_DIR}/cc_scheduler/status-report.md"

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
    # 解析格式 cc-{wande-play-kimiN}-{issue}
    # DIRNAME = wande-play-kimiN，从lock文件读取module等其他信息
    dirname_part=$(echo "$session" | sed 's/^cc-//' | rev | cut -d- -f2- | rev)
    kimi_dir=$(echo "$dirname_part" | grep -oP 'kimi\d+$')
    lock_file="${HOME_DIR}/projects/wande-play-${kimi_dir}/.cc-lock"
    if [ -n "$kimi_dir" ] && [ -f "$lock_file" ]; then
        issue=$(grep "^issue=" "$lock_file" | cut -d= -f2)
        module=$(grep "^module=" "$lock_file" | cut -d= -f2)
    else
        # 兼容/降级：直接从session名取最后一段作issue
        issue=$(echo "$session" | rev | cut -d- -f1 | rev)
        module="unknown"
        kimi_dir=""
    fi

    repo_full="WnadeyaowuOraganization/wande-play"

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
    logfile="$LOGDIR/${module}-${issue}.log"
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
        # claude还在运行，检查最近活跃时间（从 .claude/projects/ JSONL文件mtime）
        # 精确匹配：用Claude项目路径格式精确定位
        # Claude存储路径格式：-home-ubuntu-projects-wande-play-{kimiN}-{module}/
        if [ -n "$kimi_dir" ] && [ -n "$module" ] && [ "$module" != "unknown" ]; then
            proj_dir_name="-home-ubuntu-projects-wande-play-${kimi_dir}-${module}"
            jsonl_file=$(find "${HOME_DIR}/.claude/projects/${proj_dir_name}/" -name "*.jsonl" \
                -not -path "*/subagents/*" -mmin -120 2>/dev/null \
                | xargs -I{} stat -c "%Y {}" {} 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        elif [ -n "$kimi_dir" ]; then
            proj_dir_name="-home-ubuntu-projects-wande-play-${kimi_dir}"
            jsonl_file=$(find "${HOME_DIR}/.claude/projects/${proj_dir_name}/" -name "*.jsonl" \
                -not -path "*/subagents/*" -mmin -120 2>/dev/null \
                | xargs -I{} stat -c "%Y {}" {} 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        else
            jsonl_file=$(find ${HOME_DIR}/.claude/projects/ -name "*.jsonl" -path "*wande-play*" -mmin -120 2>/dev/null \
                | xargs -I{} stat -c "%Y {}" {} 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        fi
        if [ -z "$jsonl_file" ]; then
            jsonl_file="$logfile"  # fallback到旧日志
        fi
        last_active=$(stat -c "%Y" "$jsonl_file" 2>/dev/null || stat -c "%Y" "$logfile" 2>/dev/null)
        now=$(date +%s)
        idle_minutes=$(( (now - ${last_active:-now}) / 60 ))
        if [ "$idle_minutes" -lt 5 ]; then
            echo "- $session: 🔥 **工作中** (最近活跃)" >> "$REPORT_FILE"
        elif [ "$idle_minutes" -ge 30 ]; then
            echo "- $session: 🚨 **超时${idle_minutes}分钟，请重启CC**（kill-session → run-cc.sh 同参数）" >> "$REPORT_FILE"
            curl -s -X POST http://localhost:9872/api/notify \
              -H "Content-Type: application/json" \
              -d "{\"session\":\"manager\",\"message\":\"${session} Issue#${issue}空闲${idle_minutes}分钟，请kill后run-cc.sh重启\",\"type\":\"warning\"}" 2>/dev/null || true
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
MAX_CONCURRENT=5
active_count=$(tmux list-sessions 2>/dev/null | grep "^cc-" | wc -l)
available_count=$((MAX_CONCURRENT - active_count))
echo "- 活跃CC: $active_count / $MAX_CONCURRENT（并发上限）" >> "$REPORT_FILE"
echo "- 可新增: $available_count" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 5. 检查Todo队列中的P0 Issue
echo "### 待处理P0 Issue数量" >> "$REPORT_FILE"
bash "$SCRIPT_DIR/query-project-issues.sh" --repo play --status "Todo" 2>/dev/null | grep "P0" | wc -l | xargs -I {} echo "- wande-play Todo P0: {}" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 6. 读取编程CC进度（task.md）
echo "### 编程CC进度（task.md）" >> "$REPORT_FILE"
for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
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

# 7. 外接目录指派锁状态
echo "### 外接目录锁状态" >> "$REPORT_FILE"
NOW=$(date +%s)
TIMEOUT_SECS=3600
FREE_COUNT=0
LOCKED_COUNT=0
TIMEOUT_COUNT=0

for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20}; do
  [ ! -d "$dir" ] && continue
  DIRNAME=$(basename "$dir")

  if [ ! -f "$dir/.cc-lock" ]; then
    FREE_COUNT=$((FREE_COUNT + 1))
    continue
  fi

  LOCK_ISSUE=$(grep "^issue=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  LOCK_MODULE=$(grep "^module=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  LOCK_STATE=$(grep "^state=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  LOCK_RETRY=$(grep "^retry_count=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  LOCK_TS=$(grep "^timestamp=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  AGE_SECS=$((NOW - ${LOCK_TS:-0}))
  AGE_MINS=$((AGE_SECS / 60))

  CC_RUNNING=false
  for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^cc-"); do
    echo "$session" | grep -q "$DIRNAME" && CC_RUNNING=true && break
  done

  if [ "$LOCK_STATE" = "SAVED" ]; then
    # 代码已保存，需要研发经理CC重新触发继续
    echo "- 💾 $DIRNAME: Issue#${LOCK_ISSUE} ${LOCK_MODULE} (**SAVED, retry=${LOCK_RETRY:-0}, 需重新触发CC继续**)" >> "$REPORT_FILE"
    LOCKED_COUNT=$((LOCKED_COUNT + 1))
  elif [ "$CC_RUNNING" = "true" ]; then
    echo "- 🔧 $DIRNAME: Issue#${LOCK_ISSUE} ${LOCK_MODULE} (${AGE_MINS}分钟, CC运行中)" >> "$REPORT_FILE"
    LOCKED_COUNT=$((LOCKED_COUNT + 1))
  elif [ $AGE_SECS -gt $TIMEOUT_SECS ]; then
    echo "- 🚨 $DIRNAME: Issue#${LOCK_ISSUE} ${LOCK_MODULE} (**${AGE_MINS}分钟超时, 等待cron恢复**)" >> "$REPORT_FILE"
    TIMEOUT_COUNT=$((TIMEOUT_COUNT + 1))
    LOCKED_COUNT=$((LOCKED_COUNT + 1))
  else
    echo "- ⏳ $DIRNAME: Issue#${LOCK_ISSUE} ${LOCK_MODULE} (${AGE_MINS}分钟, state=${LOCK_STATE:-RUNNING})" >> "$REPORT_FILE"
    LOCKED_COUNT=$((LOCKED_COUNT + 1))
  fi
done

echo "- 空闲: ${FREE_COUNT}  锁定: ${LOCKED_COUNT}  超时需处理: ${TIMEOUT_COUNT}" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cat "$REPORT_FILE"
