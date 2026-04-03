#!/bin/bash
# run-cc.sh — 在tmux中启动编程CC（stream-json实时日志）
# 用法: run-cc.sh <repo> <issue_number> <model> [dir_suffix]
# repo: backend | frontend | pipeline | app(fullstack) | plugins | gh-plugins
# model: claude-opus-4-6（默认）、claude-sonnet-4-6、claude-haiku-4-5-20251001
# dir_suffix: 可选，指定外接目录后缀（如 kimi1~kimi10）
#
# 操作:
#   tail -f /home/ubuntu/cc_scheduler/logs/<repo>-<issue>.log  查看实时日志
#   tmux attach -t cc-<repo>-<issue>                查看tmux会话
#   Ctrl+B D                                        脱离（CC继续运行）

REPO=$1
ISSUE=$2
MODEL=${3:-claude-opus-4-6}
DIR_SUFFIX=${4:-""}
LOGDIR=/home/ubuntu/cc_scheduler/logs
mkdir -p $LOGDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

if [ -z "$REPO" ] || [ -z "$ISSUE" ]; then
    echo "用法: $0 <repo> <issue_number> [model] [dir_suffix]"
    echo "  repo: backend | frontend | pipeline | app | plugins | gh-plugins"
    echo "  dir_suffix: kimi1~kimi10（可选）"
    exit 1
fi

# wande-play monorepo: backend/frontend/pipeline/app 都在 wande-play 下
case "$REPO" in
  backend|frontend|pipeline|app)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-play-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-play"
    fi
    ;;
  plugins|gh-plugins)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-gh-plugins-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-gh-plugins"
    fi
    ;;
  *)  echo "Unknown repo: $REPO"; exit 1 ;;
esac

# 根据 module cd 到对应子目录
case "$REPO" in
  backend)  PROJECT_DIR="$BASE_DIR/backend" ;;
  frontend) PROJECT_DIR="$BASE_DIR/frontend" ;;
  pipeline) PROJECT_DIR="$BASE_DIR/pipeline" ;;
  app)      PROJECT_DIR="$BASE_DIR" ;;
  plugins|gh-plugins)  PROJECT_DIR="$BASE_DIR" ;;
esac

if [ ! -d "$PROJECT_DIR" ]; then
    echo "错误: 目录不存在 $PROJECT_DIR"
    exit 1
fi

SESSION="cc-${REPO}-${ISSUE}"
LOGFILE="$LOGDIR/${REPO}-${ISSUE}.log"
RAW_LOG="$LOGDIR/${REPO}-${ISSUE}-raw.jsonl"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
    exit 0
fi

# Token
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# 清空日志
> "$LOGFILE"
> "$RAW_LOG"

echo "[$(date)] CC started for ${REPO}#${ISSUE}" >> "$LOGFILE"

# stream-json模式 → tee保存原始JSON → python解析为可读日志
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=http://localhost:9855; cd $PROJECT_DIR; \
   claude -p '拾取（包含评论）并完成 Issue #${ISSUE}' --model ${MODEL} --max-turns 500 \
     --output-format stream-json --include-partial-messages --verbose \
   2>/dev/null | tee -a '$RAW_LOG' | python3 '$PARSER' >> '$LOGFILE' 2>&1; \
   echo '' >> '$LOGFILE'; echo [$(date)] CC COMPLETED >> '$LOGFILE'; \
   tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动"
echo "  实时日志: tail -f $LOGFILE"
echo "  原始JSON: tail -f $RAW_LOG"
echo "  tmux会话: tmux attach -t $SESSION"
