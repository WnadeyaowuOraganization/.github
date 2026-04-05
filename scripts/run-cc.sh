#!/bin/bash
# run-cc.sh — 在tmux中启动编程CC（Issue预取+stream-json实时日志）
# 用法: run-cc.sh <repo> <issue_number> [model] [dir_suffix] [effort]
# repo: backend | frontend | pipeline | app(fullstack) | plugins | gh-plugins
# model: claude-opus-4-6（默认）、claude-sonnet-4-6、claude-haiku-4-5-20251001
# dir_suffix: 可选，指定外接目录后缀（如 kimi1~kimi20）
# effort: 可选，low | medium（默认）| high | max — 控制thinking深度
#
# 退出码:
#   0: 成功启动 或 会话已存在
#   1: 参数错误 / 目录不存在
#   2: 目录被其他CC占用（研发经理CC收到此码后应指派其他目录）

REPO=$1
ISSUE=$2
MODEL=${3:-claude-opus-4-6}
DIR_SUFFIX=${4:-""}
EFFORT=${5:-medium}
LOGDIR=/home/ubuntu/cc_scheduler/logs
mkdir -p $LOGDIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="$SCRIPT_DIR/cc-stream-parser.py"

if [ -z "$REPO" ] || [ -z "$ISSUE" ]; then
    echo "用法: $0 <repo> <issue_number> [model] [dir_suffix] [effort]"
    echo "  repo: backend | frontend | pipeline | app | plugins | gh-plugins"
    echo "  dir_suffix: kimi1~kimi20（可选）"
    echo "  effort: low | medium（默认）| high | max"
    exit 1
fi

# === 最大重试次数限制 ===
MAX_RETRIES=3
RETRY_COUNT_FILE="/tmp/cc-retry-${REPO}-${ISSUE}"
RETRY_COUNT=$(cat "$RETRY_COUNT_FILE" 2>/dev/null || echo 0)
if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Issue#${ISSUE} 已达到最大重试次数($MAX_RETRIES)，需人工介入"
    bash "$SCRIPT_DIR/update-project-status.sh" play "$ISSUE" "Fail" 2>/dev/null || true
    exit 1
fi
echo $((RETRY_COUNT + 1)) > "$RETRY_COUNT_FILE"

# wande-play monorepo: backend/frontend/pipeline/app 都在 wande-play 下
case "$REPO" in
  backend|frontend|pipeline|app)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-play-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-play"
    fi
    GH_REPO="WnadeyaowuOraganization/wande-play"
    ;;
  plugins|gh-plugins)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="/home/ubuntu/projects/wande-gh-plugins-${DIR_SUFFIX}"
    else
      BASE_DIR="/home/ubuntu/projects/wande-gh-plugins"
    fi
    GH_REPO="WnadeyaowuOraganization/wande-gh-plugins"
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

# === Issue预取：存到 issue-source.md ===
ISSUE_DIR="$BASE_DIR/issues/issue-${ISSUE}"
ISSUE_SOURCE="$ISSUE_DIR/issue-source.md"
mkdir -p "$ISSUE_DIR"

echo "$(date): Fetching Issue #${ISSUE} from GitHub ($GH_REPO)..."

ISSUE_BODY=$(gh issue view "$ISSUE" --repo "$GH_REPO" --json title,body,labels,state \
  --jq '"# Issue #'"$ISSUE"': " + .title + "\n\n**Labels**: " + ([.labels[].name] | join(", ")) + "\n**State**: " + .state + "\n\n## 需求内容\n\n" + .body' 2>/dev/null)

ISSUE_COMMENTS=$(gh issue view "$ISSUE" --repo "$GH_REPO" --comments --json comments \
  --jq 'if (.comments | length) > 0 then "\n\n## 评论\n\n" + ([.comments[] | "### " + .author.login + " (" + (.createdAt | split("T")[0]) + ")\n\n" + .body] | join("\n\n---\n\n")) else "" end' 2>/dev/null)

if [ -z "$ISSUE_BODY" ]; then
  echo "WARNING: Failed to fetch Issue #${ISSUE}, CC will fetch from GitHub"
  PROMPT="拾取（包含评论）并完成 Issue #${ISSUE}"
else
  echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
  echo "$(date): Issue #${ISSUE} saved to $ISSUE_SOURCE ($(wc -l < "$ISSUE_SOURCE") lines)"
  PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，然后按照开发流程完成任务。Issue 编号: #${ISSUE}"
fi

# === 检查是否有详细设计文档 ===
DESIGN_DOC=$(find "$SCRIPT_DIR/../docs/design/" -name "*详细设计.md" -newer "$ISSUE_DIR" 2>/dev/null | head -1)
if [ -z "$DESIGN_DOC" ]; then
  # 按Issue号搜索
  DESIGN_DOC=$(grep -rl "#${ISSUE}" "$SCRIPT_DIR/../docs/design/"*详细设计.md 2>/dev/null | head -1)
fi
if [ -n "$DESIGN_DOC" ]; then
  # 复制设计文档到Issue目录，让编程CC能直接读取
  cp "$DESIGN_DOC" "$ISSUE_DIR/design.md"
  PROMPT="$PROMPT

重要：本Issue有详细设计文档，请先阅读 issues/issue-${ISSUE}/design.md 并严格按设计实现。"
  echo "$(date): 详细设计文档已注入: $(basename $DESIGN_DOC)"
fi

# 清空日志
> "$LOGFILE"
> "$RAW_LOG"

# === API来源选择（根据effort决定）===
if [ "$EFFORT" = "max" ]; then
  # max级别：使用Claude Max订阅（真实模型，1M上下文）
  API_ENV=""
  API_SOURCE="Claude Max订阅"
else
  # 其他级别：使用Token Pool Proxy（模型重写+上下文截断）
  API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; export ANTHROPIC_API_KEY=dummy; export API_TIMEOUT_MS=3000000; export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"
  API_SOURCE="Token Pool Proxy"
fi

echo "[$(date)] CC started for ${REPO}#${ISSUE} in ${BASE_DIR} (effort=$EFFORT, api=$API_SOURCE)" >> "$LOGFILE"

# stream-json模式 → tee保存原始JSON → python解析为可读日志
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; ${API_ENV} cd $PROJECT_DIR; \
   claude -p '$PROMPT' --model ${MODEL} --effort ${EFFORT} --max-turns 500 \
     --output-format stream-json --include-partial-messages --verbose \
   2>/dev/null | tee -a '$RAW_LOG' | python3 '$PARSER' >> '$LOGFILE' 2>&1; \
   echo '' >> '$LOGFILE'; echo [$(date)] CC COMPLETED >> '$LOGFILE'; \
   tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (目录: $BASE_DIR, effort: $EFFORT, api: $API_SOURCE)"
echo "  实时日志: tail -f $LOGFILE"
echo "  原始JSON: tail -f $RAW_LOG"
echo "  tmux会话: tmux attach -t $SESSION"
