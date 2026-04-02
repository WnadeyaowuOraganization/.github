#!/bin/bash
# run-cc-with-prompt.sh — 在tmux中启动编程CC，自定义prompt（stream-json实时日志）
# 用法: run-cc-with-prompt.sh <repo> <prompt> <model> [dir_suffix]
# repo: backend | front | pipeline
# model: claude-opus-4-6（默认）、claude-sonnet-4-6、claude-haiku-4-5-20251001
# dir_suffix: 可选，指定外接目录后缀（如 kimi1, glm1）
#
# 操作:
#   tail -f /home/ubuntu/cc_scheduler/logs/<repo>-<issue>.log  查看实时日志
#   tmux attach -t cc-<repo>-<issue>                查看tmux会话
#   Ctrl+B D                                        脱离（CC继续运行）

REPO=$1
PROMPT=$2
SESSION_ID=$(echo -n "$PROMPT" | md5sum | cut -c1-8)
MODEL=${3:-claude-opus-4-6}
DIR_SUFFIX=${4:-""}
LOGDIR=/home/ubuntu/cc_scheduler/logs
mkdir -p $LOGDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

if [ -z "$REPO" ] || [ -z "$PROMPT" ]; then
    echo "用法: $0 <repo> <prompt> [model] [dir_suffix]"
    echo "  repo: backend | front | pipeline"
    echo "  dir_suffix: kimi1~kimi6, glm1 等（可选）"
    exit 1
fi

case "$REPO" in
  play-backend) BASE_DIR="wande-play"; SUBDIR="backend" ;;
  play-frontend) BASE_DIR="wande-play"; SUBDIR="frontend" ;;
  play-app) BASE_DIR="wande-play"; SUBDIR="" ;;
  play-backend) BASE_DIR="wande-play"; SUBDIR="backend" ;;
  play-frontend) BASE_DIR="wande-play"; SUBDIR="frontend" ;;
  play-app) BASE_DIR="wande-play"; SUBDIR="" ;;
  backend)  BASE_DIR="wande-ai-backend" ;;
  front)    BASE_DIR="wande-ai-front" ;;
  pipeline) BASE_DIR="wande-data-pipeline" ;;
  plugins)  BASE_DIR="wande-gh-plugins" ;;
  *)        echo "Unknown repo: $REPO"; exit 1 ;;
esac

if [ -n "$DIR_SUFFIX" ]; then
  PROJECT_DIR="/home/ubuntu/projects/${BASE_DIR}-${DIR_SUFFIX}"
else
  PROJECT_DIR="/home/ubuntu/projects/${BASE_DIR}"
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "错误: 目录不存在 $PROJECT_DIR"
    exit 1
fi


SESSION="cc-${REPO}-${SESSION_ID}"
LOGFILE="$LOGDIR/${REPO}-${SESSION_ID}.log"
RAW_LOG="$LOGDIR/${REPO}-${SESSION_ID}-raw.jsonl"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
    exit 0
fi

# Token
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# 清空日志
> "$LOGFILE"
> "$RAW_LOG"

echo "[$(date)] CC started for PROMPT: (${PROMPT})" >> "$LOGFILE"

# stream-json模式 → tee保存原始JSON → python解析为可读日志
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=http://localhost:9855; cd $PROJECT_DIR; \
   claude -p '${PROMPT}' --model ${MODEL} --max-turns 500 \
     --output-format stream-json --include-partial-messages --verbose \
   2>/dev/null | tee -a '$RAW_LOG' | python3 '$PARSER' >> '$LOGFILE' 2>&1; \
   echo '' >> '$LOGFILE'; echo [$(date)] CC COMPLETED >> '$LOGFILE'; \
   tmux kill-session -t "$SESSION""

echo "✓ CC已在tmux会话 '$SESSION' 中启动"
echo "  实时日志: tail -f $LOGFILE"
echo "  原始JSON: tail -f $RAW_LOG"
echo "  tmux会话: tmux attach -t $SESSION"
