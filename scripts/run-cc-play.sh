#!/bin/bash
# run-cc-play.sh — wande-play monorepo版CC启动脚本
# Usage: run-cc-play.sh <module> <issue_number> [model] [dir_suffix]
# module: backend | frontend | app (fullstack) | pipeline

MODULE="$1"
ISSUE="$2"
MODEL="${3:-claude-opus-4-6}"
DIR_SUFFIX="$4"

if [ -z "$MODULE" ] || [ -z "$ISSUE" ]; then
  echo "Usage: $0 <module> <issue_number> [model] [dir_suffix]"
  exit 1
fi

export PATH=/root/.local/bin:$PATH
export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh 2>/dev/null)
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy

# Determine base directory
case "$MODULE" in
  backend|frontend|app)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-play-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-play"
    fi
    ;;
  pipeline)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-data-pipeline-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-data-pipeline"
    fi
    ;;
  *)
    echo "Unknown module: $MODULE"
    exit 1
    ;;
esac

# Determine working directory within repo
case "$MODULE" in
  backend)  WORK_DIR="$BASE_DIR/backend" ;;
  frontend) WORK_DIR="$BASE_DIR/frontend" ;;
  app)      WORK_DIR="$BASE_DIR" ;;
  pipeline) WORK_DIR="$BASE_DIR" ;;
esac

if [ ! -d "$WORK_DIR" ]; then
  echo "Directory not found: $WORK_DIR"
  exit 1
fi

SESSION="cc-${MODULE}-${ISSUE}"
LOG="/home/ubuntu/cc_scheduler/logs/${MODULE}-${ISSUE}.log"

# Check if session already exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session $SESSION already running"
  exit 0
fi

echo "$(date): Starting CC $SESSION in $WORK_DIR (model=$MODEL)" | tee "$LOG"

# Start CC in tmux
tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
  "cd $WORK_DIR && claude -p '拾取并完成 Issue #${ISSUE}' --model $MODEL --output-format text 2>&1 | tee -a $LOG"

echo "CC started: tmux attach -t $SESSION"
