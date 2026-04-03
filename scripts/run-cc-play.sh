#!/bin/bash
# run-cc-play.sh — wande-play monorepo版CC启动脚本（含Issue预取+stream-parser日志）
# Usage: run-cc-play.sh <module> <issue_number> [model] [dir_suffix] [effort]
# module: backend | frontend | app (fullstack) | pipeline
# effort: low | medium（默认）| high | max — 控制thinking深度

MODULE="$1"
ISSUE="$2"
MODEL="${3:-claude-opus-4-6}"
DIR_SUFFIX="$4"
EFFORT="${5:-medium}"
LOGDIR=/home/ubuntu/cc_scheduler/logs
mkdir -p $LOGDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

if [ -z "$MODULE" ] || [ -z "$ISSUE" ]; then
  echo "Usage: $0 <module> <issue_number> [model] [dir_suffix] [effort]"
  echo "  module: backend | frontend | app | pipeline"
  echo "  effort: low | medium（默认）| high | max"
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

# ============================================================
# Pre-task: 预取 Issue 内容到本地文件
# ============================================================
ISSUE_DIR="$BASE_DIR/issues/issue-${ISSUE}"
ISSUE_SOURCE="$ISSUE_DIR/issue-source.md"
mkdir -p "$ISSUE_DIR"

echo "$(date): Fetching Issue #${ISSUE} from GitHub..."

# 获取 Issue 主体
ISSUE_BODY=$(gh issue view "$ISSUE" --repo WnadeyaowuOraganization/wande-play --json title,body,labels,state --jq '"# Issue #'"$ISSUE"': " + .title + "\n\n**Labels**: " + ([.labels[].name] | join(", ")) + "\n**State**: " + .state + "\n\n## 需求内容\n\n" + .body' 2>/dev/null)

# 获取 Issue 评论
ISSUE_COMMENTS=$(gh issue view "$ISSUE" --repo WnadeyaowuOraganization/wande-play --comments --json comments --jq 'if (.comments | length) > 0 then "\n\n## 评论\n\n" + ([.comments[] | "### " + .author.login + " (" + (.createdAt | split("T")[0]) + ")\n\n" + .body] | join("\n\n---\n\n")) else "" end' 2>/dev/null)

if [ -z "$ISSUE_BODY" ]; then
  echo "WARNING: Failed to fetch Issue #${ISSUE}, CC will need to fetch from GitHub"
  PROMPT="拾取（包含评论）并完成 Issue #${ISSUE}"
else
  # 写入 issue-source.md
  echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
  echo "$(date): Issue #${ISSUE} saved to $ISSUE_SOURCE ($(wc -l < "$ISSUE_SOURCE") lines)"
  PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，然后按照开发流程完成任务。Issue 编号: #${ISSUE}"
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

echo "[$(date '+%a %b %d %H:%M:%S %Z %Y')] CC started for ${MODULE}#${ISSUE} in $WORK_DIR (effort=$EFFORT)" | tee "$LOGFILE"

# Use stream-parser if available, fallback to tee
if [ -f "$PARSER" ]; then
  tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
    "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL; \
    cd $WORK_DIR; \
   claude -p '$PROMPT' --model $MODEL --effort $EFFORT --max-turns 500 \
     --output-format stream-json --include-partial-messages --verbose \
   2>/dev/null | tee -a '$RAW_LOG' | python3 '$PARSER' >> '$LOGFILE' 2>&1; \
   echo '' >> '$LOGFILE'; echo [$(date '+%a %b %d %H:%M:%S %Z %Y')] CC COMPLETED >> '$LOGFILE'; \
   tmux kill-session -t $SESSION"
else
  tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
    "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL; \
    cd $WORK_DIR; \
   claude -p '$PROMPT' --model $MODEL --effort $EFFORT --max-turns 500 \
     --output-format text \
   2>&1 | tee -a '$LOGFILE'; \
   tmux kill-session -t $SESSION"
fi

echo "CC started: tmux attach -t $SESSION"
echo "Log: tail -f $LOGFILE"
