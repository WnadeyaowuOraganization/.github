#!/bin/bash
# Round Executor: 按顺序执行6轮项目矿场/项目中心 P0 Issue
# 每轮backend+front并行，完成后自动下一轮

LOGDIR=/home/ubuntu/cc_scheduler/logs
STATUS_FILE=$LOGDIR/round-status.json
mkdir -p $LOGDIR

# 定义6轮任务
declare -A ROUNDS
ROUNDS[1]="359:54"
ROUNDS[2]="380:53"
ROUNDS[3]="381:162"
ROUNDS[4]="441:171"
ROUNDS[5]="442:172"
ROUNDS[6]="443:189"

GH_TOKEN_CMD="echo "$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)""

log() {
  echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a $LOGDIR/executor.log
}

check_issue_closed() {
  local repo=$1
  local issue_num=$2
  local state=$(su - ubuntu -c "gh issue view $issue_num --repo WnadeyaowuOraganization/$repo --json state -q .state" 2>/dev/null)
  [ "$state" = "CLOSED" ]
}

run_round() {
  local round=$1
  local backend_issue=$(echo ${ROUNDS[$round]} | cut -d: -f1)
  local front_issue=$(echo ${ROUNDS[$round]} | cut -d: -f2)
  
  log "========== ROUND $round START =========="
  log "Backend: #$backend_issue | Front: #$front_issue"
  
  # 更新状态
  echo "{\"current_round\": $round, \"backend_issue\": $backend_issue, \"front_issue\": $front_issue, \"status\": \"running\", \"started_at\": \"$(date -Iseconds)\"}" > $STATUS_FILE
  
  # 并行启动backend和front CC
  su - ubuntu -c "export GH_TOKEN=\$($GH_TOKEN_CMD) && cd /home/ubuntu/projects/wande-play/backend && claude -p '拾取并完成 Issue #$backend_issue' --output-format text" > $LOGDIR/backend-$backend_issue.log 2>&1 &
  local backend_pid=$!
  
  su - ubuntu -c "export GH_TOKEN=\$($GH_TOKEN_CMD) && cd /home/ubuntu/projects/wande-play/frontend && claude -p '拾取并完成 Issue #$front_issue' --output-format text" > $LOGDIR/front-$front_issue.log 2>&1 &
  local front_pid=$!
  
  log "Backend PID: $backend_pid | Front PID: $front_pid"
  
  # 等待两个都完成（最多20分钟）
  local timeout=1200
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    # 检查进程是否还在运行
    local b_running=0
    local f_running=0
    kill -0 $backend_pid 2>/dev/null && b_running=1
    kill -0 $front_pid 2>/dev/null && f_running=1
    
    if [ $b_running -eq 0 ] && [ $f_running -eq 0 ]; then
      log "Both CC processes finished"
      break
    fi
    
    sleep 30
    elapsed=$((elapsed + 30))
    log "Waiting... ${elapsed}s (backend:$b_running front:$f_running)"
  done
  
  # 超时强制杀
  kill $backend_pid 2>/dev/null
  kill $front_pid 2>/dev/null
  
  # 检查Issue状态
  sleep 5
  local b_closed=false
  local f_closed=false
  check_issue_closed wande-play $backend_issue && b_closed=true
  check_issue_closed wande-play $front_issue && f_closed=true
  
  log "Round $round Result: backend#$backend_issue=$b_closed front#$front_issue=$f_closed"
  
  # 更新状态
  echo "{\"current_round\": $round, \"backend_issue\": $backend_issue, \"front_issue\": $front_issue, \"backend_closed\": $b_closed, \"front_closed\": $f_closed, \"status\": \"completed\", \"completed_at\": \"$(date -Iseconds)\"}" > $STATUS_FILE
}

# 主循环：从Round 1到Round 6
log "===== PROJECT MINE P0 ISSUE EXECUTOR STARTED ====="
log "Total rounds: 6"

for round in 1 2 3 4 5 6; do
  backend_issue=$(echo ${ROUNDS[$round]} | cut -d: -f1)
  front_issue=$(echo ${ROUNDS[$round]} | cut -d: -f2)
  
  # 跳过已完成的
  b_done=false
  f_done=false
  check_issue_closed wande-play $backend_issue && b_done=true
  check_issue_closed wande-play $front_issue && f_done=true
  
  if [ "$b_done" = true ] && [ "$f_done" = true ]; then
    log "Round $round: SKIPPED (both issues already closed)"
    continue
  fi
  
  run_round $round
done

log "===== ALL ROUNDS COMPLETED ====="
echo "{\"status\": \"all_completed\", \"completed_at\": \"$(date -Iseconds)\"}" > $STATUS_FILE
