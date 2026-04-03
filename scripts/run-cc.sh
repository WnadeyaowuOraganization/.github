#!/bin/bash
# run-cc.sh — 在tmux中启动编程CC（stream-json实时日志）
# 用法: run-cc.sh <repo> <issue_number> <model> [dir_suffix]
# repo: backend | frontend | pipeline | app(fullstack) | plugins | gh-plugins
# model: claude-opus-4-6（默认）、claude-sonnet-4-6、claude-haiku-4-5-20251001
# dir_suffix: 可选，指定外接目录后缀（如 kimi1~kimi20）
#
# 退出码:
#   0: 成功启动 或 会话已存在
#   1: 参数错误 / 目录不存在
#   2: 目录被其他CC占用（研发经理CC收到此码后应指派其他目录）

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
    echo "  dir_suffix: kimi1~kimi20（可选）"
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

# === 目录占用检测（核心防重复逻辑）===
# 检查 BASE_DIR 下是否有任何 claude 进程在运行（不管是 backend/frontend/app）
# 一个目录同一时间只允许一个CC会话
# 匹配方式：扫描所有 "claude -p" 进程的 cwd
OCCUPIED_PID=""
OCCUPIED_INFO=""

while IFS= read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    [ -z "$pid" ] && continue
    cwd=$(readlink /proc/$pid/cwd 2>/dev/null)
    [ -z "$cwd" ] && continue
    case "$cwd" in
        ${BASE_DIR}|${BASE_DIR}/*)
            OCCUPIED_PID="$pid"
            # 提取Issue号
            OCCUPIED_INFO=$(ps -o args= -p $pid 2>/dev/null | grep -oP "Issue #\K\d+")
            break
            ;;
    esac
done < <(ps -u ubuntu -o pid,args 2>/dev/null | grep "claude -p" | grep -v grep | awk '{print $1}')

if [ -n "$OCCUPIED_PID" ]; then
    echo "目录占用: ${BASE_DIR} 已有CC在运行 (PID=$OCCUPIED_PID, Issue#${OCCUPIED_INFO:-?})"
    exit 2
fi

# === tmux session 名冲突检测 ===
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
    exit 0
fi

# Token
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# 清空日志
> "$LOGFILE"
> "$RAW_LOG"

echo "[$(date)] CC started for ${REPO}#${ISSUE} in ${BASE_DIR}" >> "$LOGFILE"

# stream-json模式 → tee保存原始JSON → python解析为可读日志
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; export ANTHROPIC_BASE_URL=http://localhost:9855; cd $PROJECT_DIR; \
   claude -p '拾取（包含评论）并完成 Issue #${ISSUE}' --model ${MODEL} --max-turns 500 \
     --output-format stream-json --include-partial-messages --verbose \
   2>/dev/null | tee -a '$RAW_LOG' | python3 '$PARSER' >> '$LOGFILE' 2>&1; \
   echo '' >> '$LOGFILE'; echo [$(date)] CC COMPLETED >> '$LOGFILE'; \
   tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (目录: $BASE_DIR)"
echo "  实时日志: tail -f $LOGFILE"
echo "  原始JSON: tail -f $RAW_LOG"
echo "  tmux会话: tmux attach -t $SESSION"
