#!/bin/bash
# run-cc-play.sh — wande-play monorepo版CC启动脚本（含stream-parser日志）
# Usage: run-cc-play.sh <module> <issue_number> [model] [dir_suffix]
# module: backend | frontend | app (fullstack) | pipeline

MODULE="$1"
ISSUE="$2"
MODEL="${3:-claude-opus-4-6}"
DIR_SUFFIX="$4"
LOGDIR=/home/ubuntu/cc_scheduler/logs
mkdir -p $LOGDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

if [ -z "$MODULE" ] || [ -z "$ISSUE" ]; then
  echo "Usage: $0 <module> <issue_number> [model] [dir_suffix]"
  echo "  module: backend | frontend | app | pipeline"
  exit 1
fi

export PATH=/root/.local/bin:$PATH
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy

case "$MODULE" in
  backend|frontend|app)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-play-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-play"
    fi
    ;;
  pipeline)
    BASE_DIR="/home/ubuntu/projects/wande-play"
    ;;
  *)
    echo "Unknown module: $MODULE"; exit 1
    ;;
esac

case "$MODULE" in
  backend)  WORK_DIR="$BASE_DIR/backend" ;;
  frontend) WORK_DIR="$BASE_DIR/frontend" ;;
  app)      WORK_DIR="$BASE_DIR" ;;
  pipeline) WORK_DIR="$BASE_DIR/pipeline" ;;
esac

if [ ! -d "$WORK_DIR" ]; then
  echo "Directory not found: $WORK_DIR"
  exit 1
fi

SESSION="cc-${MODULE}-${ISSUE}"
LOGFILE="$LOGDIR/${MODULE}-${ISSUE}.log"
RAW_LOG="$LOGDIR/${MODULE}-${ISSUE}-raw.jsonl"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session $SESSION already running: tmux attach -t $SESSION"
  exit 0
fi

> "$LOGFILE"
> "$RAW_LOG"

echo "$(date): Starting CC $SESSION in $WORK_DIR (model=$MODEL)" | tee "$LOGFILE"

# Use stream-parser if available, fallback to tee
if [ -f "$PARSER" ]; then
  tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
    "export GH_TOKEN=$GH_TOKEN && export ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL && export ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY && export PATH=/root/.local/bin:\$PATH && cd $WORK_DIR && claude -p '拾取并完成 Issue #${ISSUE}' --model $MODEL --output-format stream-json --verbose 2>&1 | tee $RAW_LOG | python3 $PARSER 2>&1 | tee -a $LOGFILE"
else
  tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
    "export GH_TOKEN=$GH_TOKEN && export ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL && export ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY && export PATH=/root/.local/bin:\$PATH && cd $WORK_DIR && claude -p '拾取并完成 Issue #${ISSUE}' --model $MODEL --output-format text 2>&1 | tee -a $LOGFILE"
fi

echo "CC started: tmux attach -t $SESSION"
echo "Log: tail -f $LOGFILE"
