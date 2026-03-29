#!/bin/bash
# run-cc.sh — 在tmux中启动编程CC
# 用法: run-cc.sh <repo> <issue_number> [dir_suffix]
# repo: backend | front | pipeline
# dir_suffix: 可选，指定外接目录后缀（如 kimi1, glm1）
#
# 操作:
#   tmux attach -t cc-<repo>-<issue>    查看实时输出
#   tmux list-sessions                   列出所有CC会话
#   Ctrl+B D                             脱离（CC继续运行）

REPO=$1
ISSUE=$2
DIR_SUFFIX=${3:-""}
LOGDIR=/var/log/coding-cc
mkdir -p $LOGDIR

if [ -z "$REPO" ] || [ -z "$ISSUE" ]; then
    echo "用法: $0 <repo> <issue_number> [dir_suffix]"
    echo "  repo: backend | front | pipeline"
    echo "  dir_suffix: kimi1~kimi6, glm1 等（可选）"
    echo ""
    echo "示例:"
    echo "  $0 backend 272"
    echo "  $0 backend 332 kimi1"
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
GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# 写一个临时启动脚本给tmux执行（避免嵌套引号问题）
LAUNCHER="/tmp/cc-launch-${REPO}-${ISSUE}.sh"
cat > "$LAUNCHER" << LAUNCH_EOF
#!/bin/bash
export GH_TOKEN="$GH_TOKEN"
export HOME="/home/ubuntu"
export PATH="/home/ubuntu/.local/bin:\$PATH"
cd "$PROJECT_DIR"
echo "[$(date)] CC started for ${REPO}#${ISSUE} in ${PROJECT_DIR}" | tee "$LOGFILE"
claude -p "拾取并完成 Issue #${ISSUE}" --output-format text 2>&1 | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"
echo "[$(date)] CC COMPLETED for ${REPO}#${ISSUE}" | tee -a "$LOGFILE"
echo "按Enter关闭会话..."
read
LAUNCH_EOF
chmod +x "$LAUNCHER"
chown ubuntu:ubuntu "$LAUNCHER"

# 以ubuntu用户启动tmux会话
tmux new-session -d -s "$SESSION" "su - ubuntu -c 'bash $LAUNCHER'"

echo "✓ CC已在tmux会话 '$SESSION' 中启动"
echo "  查看: tmux attach -t $SESSION"
echo "  脱离: Ctrl+B D"
echo "  日志: $LOGFILE"
