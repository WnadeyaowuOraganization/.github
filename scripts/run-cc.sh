#!/bin/bash
# run-cc.sh — 在tmux中启动编程CC
# 用法: run-cc.sh <repo> <issue_number> <model> [dir_suffix]
# repo: backend | front | pipeline
# model: glm-5.1（默认）、glm-5-turbo、glm-4.5-air
# dir_suffix: 可选，指定外接目录后缀（如 kimi1, glm1）
#
# 操作:
#   tmux attach -t cc-<repo>-<issue>    查看实时输出
#   tmux list-sessions                   列出所有CC会话
#   Ctrl+B D                             脱离（CC继续运行）

REPO=$1
ISSUE=$2
MODEL=$3
DIR_SUFFIX=${4:-""}
LOGDIR=/var/log/coding-cc
mkdir -p $LOGDIR

if [ -z "$REPO" ] || [ -z "$ISSUE" ]; then
    echo "用法: $0 <repo> <issue_number> [dir_suffix]"
    echo "  repo: backend | front | pipeline"
    echo "  dir_suffix: kimi1~kimi6, glm1 等（可选）"
    exit 1
fi

case "$REPO" in
  backend)  BASE_DIR="wande-ai-backend" ;;
  front)    BASE_DIR="wande-ai-front" ;;
  pipeline) BASE_DIR="wande-data-pipeline" ;;
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

SESSION="cc-${REPO}-${ISSUE}"
LOGFILE="$LOGDIR/${REPO}-${ISSUE}.log"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
    exit 0
fi

# Token
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# 直接在tmux中以当前用户(ubuntu)运行claude
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=http://localhost:9855; cd $PROJECT_DIR; echo [$(date)] CC started for ${REPO}#${ISSUE} | tee $LOGFILE; claude -p '拾取并完成 Issue #${ISSUE}' --model ${MODEL} --max-turns 200 2>&1 | tee -a $LOGFILE; echo '' | tee -a $LOGFILE; echo [$(date)] CC COMPLETED | tee -a $LOGFILE; tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动"
echo "  查看: tmux attach -t $SESSION"
echo "  脱离: Ctrl+B D"
echo "  日志: $LOGFILE"
