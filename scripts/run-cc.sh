#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# run-cc.sh — 统一CC启动脚本（Issue模式 + 自定义Prompt模式）
#
# Issue模式（默认）:
#   run-cc.sh <module> <issue_number> [model] [dir_suffix] [effort]
#   自动预取Issue内容、检测设计文档、重试限制
#
# 自定义Prompt模式:
#   run-cc.sh --prompt <module> "<prompt>" [model] [dir_suffix] [effort]
#   直接传入prompt，无Issue预取
#
# module: backend | frontend | pipeline | app(fullstack) | plugins | gh-plugins
# model: claude-sonnet-4-6（默认）、claude-opus-4-6、claude-haiku-4-5-20251001
# dir_suffix: 可选，指定外挂目录后缀（如 kimi1~kimi20）
# effort: low | medium（默认）| high | max
#
# 退出码:
#   0: 成功启动 或 会话已存在
#   1: 参数错误 / 目录不存在
#   2: 目录被其他CC占用（研发经理CC收到此码后应指派其他目录）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 解析模式 ===
MODE="issue"
if [ "$1" = "--prompt" ]; then
  MODE="prompt"
  shift
fi

REPO=$1
SECOND=$2  # Issue号 或 自定义prompt
MODEL=${3:-claude-sonnet-4-6}
DIR_SUFFIX=${4:-""}
EFFORT=${5:-medium}

if [ -z "$REPO" ] || [ -z "$SECOND" ]; then
    echo "用法:"
    echo "  Issue模式:  $0 <module> <issue_number> [model] [dir_suffix] [effort]"
    echo "  Prompt模式: $0 --prompt <module> \"<prompt>\" [model] [dir_suffix] [effort]"
    echo ""
    echo "  module: backend | frontend | pipeline | app | plugins | gh-plugins"
    echo "  effort: low | medium（默认）| high | max"
    exit 1
fi

# === 最大重试次数限制（仅Issue模式）===
if [ "$MODE" = "issue" ]; then
    ISSUE=$SECOND
    MAX_RETRIES=3
    RETRY_COUNT_FILE="/tmp/cc-retry-${REPO}-${ISSUE}"
    RETRY_COUNT=$(cat "$RETRY_COUNT_FILE" 2>/dev/null || echo 0)
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "ERROR: Issue#${ISSUE} 已达到最大重试次数($MAX_RETRIES)，需人工介入"
        bash "$SCRIPT_DIR/update-project-status.sh" play "$ISSUE" "Fail" 2>/dev/null || true
        exit 1
    fi
    echo $((RETRY_COUNT + 1)) > "$RETRY_COUNT_FILE"
fi

# === 目录解析 ===
case "$REPO" in
  backend|frontend|pipeline|app)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play-${DIR_SUFFIX}"
    elif [ "$MODE" = "prompt" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play"
    else
      echo "ERROR: Issue模式必须指定kimi目录（如 kimi1~kimi20），主目录仅--prompt模式可用"
      exit 1
    fi
    GH_REPO="WnadeyaowuOraganization/wande-play"
    ;;
  plugins|gh-plugins)
    if [ -n "$DIR_SUFFIX" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-gh-plugins-${DIR_SUFFIX}"
    else
      BASE_DIR="${HOME_DIR}/projects/wande-gh-plugins"
    fi
    GH_REPO="WnadeyaowuOraganization/wande-gh-plugins"
    ;;
  *)  echo "Unknown module: $REPO"; exit 1 ;;
esac

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

# === 目录占用检测 ===
OCCUPIED_PID=""
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

# === Session命名 ===
if [ "$MODE" = "issue" ]; then
  SESSION="cc-${REPO}-${ISSUE}"
else
  SESSION_ID=$(echo -n "$SECOND" | md5sum | cut -c1-8)
  SESSION="cc-${REPO}-${SESSION_ID}"
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
    exit 0
fi

# === Token ===
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# === Prompt构建 ===
if [ "$MODE" = "issue" ]; then
  # Issue预取
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

  # 检查详细设计文档
  DESIGN_DOC=$(find "$SCRIPT_DIR/../docs/design/" -name "*详细设计.md" -newer "$ISSUE_DIR" 2>/dev/null | head -1)
  if [ -z "$DESIGN_DOC" ]; then
    DESIGN_DOC=$(grep -rl "#${ISSUE}" "$SCRIPT_DIR/../docs/design/"*详细设计.md 2>/dev/null | head -1)
  fi
  if [ -n "$DESIGN_DOC" ]; then
    cp "$DESIGN_DOC" "$ISSUE_DIR/design.md"
    PROMPT="$PROMPT

重要：本Issue有详细设计文档，请先阅读 issues/issue-${ISSUE}/design.md 并严格按设计实现。"
    echo "$(date): 详细设计文档已注入: $(basename $DESIGN_DOC)"
  fi
else
  # 自定义Prompt模式
  PROMPT="$SECOND"
fi

# === API来源选择 ===
if [ "$EFFORT" = "max" ]; then
  API_ENV=""
  API_SOURCE="Claude Max订阅"
else
  API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; export ANTHROPIC_API_KEY=dummy; export API_TIMEOUT_MS=3000000; export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"
  API_SOURCE="Token Pool Proxy"
fi

# === 启动tmux（正常CLI界面，日志由Claude Code自动写入JSONL）===
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; ${API_ENV} cd $PROJECT_DIR; \
   claude -p '$PROMPT' --model ${MODEL} --effort ${EFFORT} --max-turns 500 --verbose; \
   tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (effort: $EFFORT, api: $API_SOURCE)"
echo "  tmux attach -t $SESSION    查看CLI界面"
echo "  Claude Office 页面查看日志"
