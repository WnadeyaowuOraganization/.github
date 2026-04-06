#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# run-cc.sh — 统一CC启动脚本
#
# 用法:
#   run-cc.sh --module backend --issue 1234 --dir kimi1 --effort high [--model claude-sonnet-4-6]
#   run-cc.sh --module app --prompt "自定义任务" --dir kimi1 --effort medium
#   run-cc.sh --module backend --prompt "修复编译" (--prompt模式不传--dir则用主目录)
#
# 退出码: 0=成功, 1=参数错误, 2=目录占用

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 参数解析 ===
MODULE=""
ISSUE=""
PROMPT=""
MODEL="claude-sonnet-4-6"
DIR=""
EFFORT="medium"

while [ $# -gt 0 ]; do
  case "$1" in
    --module)  MODULE="$2"; shift 2 ;;
    --issue)   ISSUE="$2"; shift 2 ;;
    --prompt)  PROMPT="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    --dir)     DIR="$2"; shift 2 ;;
    --effort)  EFFORT="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

# === 校验 ===
if [ -z "$MODULE" ]; then
  echo "用法:"
  echo "  $0 --module <module> --issue <N> --dir <kimi目录> --effort <effort> [--model <model>]"
  echo "  $0 --module <module> --prompt \"<prompt>\" [--dir <kimi目录>] [--effort <effort>]"
  echo ""
  echo "  module: backend | frontend | pipeline | fullstack | plugins | gh-plugins"
  echo "  effort: low | medium | high | max"
  exit 1
fi

if [ -z "$ISSUE" ] && [ -z "$PROMPT" ]; then
  echo "ERROR: 必须指定 --issue 或 --prompt"
  exit 1
fi

# 判断模式
if [ -n "$ISSUE" ]; then
  MODE="issue"
else
  MODE="prompt"
fi

# Issue模式必须传--dir
if [ "$MODE" = "issue" ] && [ -z "$DIR" ]; then
  echo "ERROR: Issue模式必须指定 --dir（如 kimi1~kimi20），主目录仅--prompt模式可用"
  exit 1
fi

# === 最大重试次数限制（仅Issue模式）===
if [ "$MODE" = "issue" ]; then
  MAX_RETRIES=3
  RETRY_COUNT_FILE="/tmp/cc-retry-${MODULE}-${ISSUE}"
  RETRY_COUNT=$(cat "$RETRY_COUNT_FILE" 2>/dev/null || echo 0)
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Issue#${ISSUE} 已达到最大重试次数($MAX_RETRIES)，需人工介入"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Fail" 2>/dev/null || true
    exit 1
  fi
  echo $((RETRY_COUNT + 1)) > "$RETRY_COUNT_FILE"
fi

# === 目录解析 ===
# fullstack是app的别名
[ "$MODULE" = "fullstack" ] && MODULE="app"

case "$MODULE" in
  backend|frontend|pipeline|app)
    if [ -n "$DIR" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play-${DIR}"
    elif [ "$MODE" = "prompt" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play"
    else
      echo "ERROR: Issue模式必须指定 --dir（如 kimi1~kimi20），主目录仅--prompt模式可用"
      exit 1
    fi
    GH_REPO="WnadeyaowuOraganization/wande-play"
    ;;
  plugins|gh-plugins)
    if [ -n "$DIR" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-gh-plugins-${DIR}"
    else
      BASE_DIR="${HOME_DIR}/projects/wande-gh-plugins"
    fi
    GH_REPO="WnadeyaowuOraganization/wande-gh-plugins"
    ;;
  *)  echo "Unknown module: $MODULE"; exit 1 ;;
esac

case "$MODULE" in
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

# === Issue模式自动pre-task ===
if [ "$MODE" = "issue" ]; then
  cd "$BASE_DIR"
  echo "$(date): pre-task: checkout dev → pull → feature-Issue-${ISSUE}"
  git checkout dev 2>/dev/null && git pull origin dev 2>/dev/null
  git checkout -b "feature-Issue-${ISSUE}" 2>/dev/null || git checkout "feature-Issue-${ISSUE}" 2>/dev/null
  mkdir -p "./issues/issue-${ISSUE}"

  # 校验分支名
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if [ "$CURRENT_BRANCH" != "feature-Issue-${ISSUE}" ]; then
    echo "ERROR: 分支切换失败，当前分支=$CURRENT_BRANCH，期望=feature-Issue-${ISSUE}"
    exit 1
  fi
fi

# === 目录指派锁检测 ===
LOCK_FILE="${BASE_DIR}/.cc-lock"

if [ -f "$LOCK_FILE" ]; then
  LOCK_ISSUE=$(grep "^issue=" "$LOCK_FILE" 2>/dev/null | cut -d= -f2)
  LOCK_TIME=$(grep "^time=" "$LOCK_FILE" 2>/dev/null | cut -d= -f2)
  # 同一个Issue可以重入（重试场景）
  if [ "$MODE" = "issue" ] && [ "$LOCK_ISSUE" = "$ISSUE" ]; then
    echo "同Issue重入: #${ISSUE}，继续"
  else
    echo "目录被锁: ${BASE_DIR} → Issue#${LOCK_ISSUE} (锁定于 ${LOCK_TIME})"
    exit 2
  fi
fi

# 写入锁（Issue模式，API/模型信息在启动tmux前追加）
if [ "$MODE" = "issue" ]; then
  cat > "$LOCK_FILE" << EOF
issue=${ISSUE}
module=${MODULE}
dir=${DIR}
model=${MODEL}
effort=${EFFORT}
time=$(date '+%Y-%m-%d %H:%M:%S')
timestamp=$(date +%s)
EOF
  echo "$(date): 目录锁已写入 ${LOCK_FILE} → Issue#${ISSUE}"
fi

# === Session命名（使用真实目录名，与.claude/projects/一致）===
# PROJECT_DIR: /home/ubuntu/projects/wande-play-kimi1/backend → DIR_NAME: kimi1-backend
# PROJECT_DIR: /home/ubuntu/projects/wande-play-kimi1 → DIR_NAME: kimi1
REL_PATH=$(echo "$PROJECT_DIR" | sed "s|${HOME_DIR}/projects/wande-play-||; s|${HOME_DIR}/projects/wande-gh-plugins-||; s|${HOME_DIR}/projects/wande-play||; s|${HOME_DIR}/projects/wande-gh-plugins||")
REL_PATH=$(echo "$REL_PATH" | sed 's|^/||; s|/|-|g')  # kimi1/backend → kimi1-backend
[ -z "$REL_PATH" ] && REL_PATH="main"  # 主目录

if [ "$MODE" = "issue" ]; then
  SESSION="cc-${REL_PATH}-${ISSUE}"
else
  SESSION_ID=$(echo -n "$PROMPT" | md5sum | cut -c1-8)
  SESSION="cc-${REL_PATH}-${SESSION_ID}"
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "会话 $SESSION 已存在，使用 tmux attach -t $SESSION 查看"
  exit 0
fi

# === Token ===
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

# === Prompt构建 ===
if [ "$MODE" = "issue" ]; then
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
    CC_PROMPT="拾取（包含评论）并完成 Issue #${ISSUE}"
  else
    echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
    echo "$(date): Issue #${ISSUE} saved to $ISSUE_SOURCE ($(wc -l < "$ISSUE_SOURCE") lines)"
    CC_PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，然后按照开发流程完成任务。Issue 编号: #${ISSUE}"
  fi

  # 检查详细设计文档
  DESIGN_DOC=$(find "$SCRIPT_DIR/../docs/design/" -name "*详细设计.md" -newer "$ISSUE_DIR" 2>/dev/null | head -1)
  if [ -z "$DESIGN_DOC" ]; then
    DESIGN_DOC=$(grep -rl "#${ISSUE}" "$SCRIPT_DIR/../docs/design/"*详细设计.md 2>/dev/null | head -1)
  fi
  if [ -n "$DESIGN_DOC" ]; then
    cp "$DESIGN_DOC" "$ISSUE_DIR/design.md"
    CC_PROMPT="$CC_PROMPT

重要：本Issue有详细设计文档，请先阅读 issues/issue-${ISSUE}/design.md 并严格按设计实现。"
    echo "$(date): 详细设计文档已注入: $(basename $DESIGN_DOC)"
  fi
else
  CC_PROMPT="$PROMPT"
fi

# === API来源选择 ===
if [ "$EFFORT" = "max" ]; then
  API_ENV=""
  API_SOURCE="Claude Max订阅"
else
  API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; export ANTHROPIC_API_KEY=dummy; export API_TIMEOUT_MS=3000000; export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"
  API_SOURCE="Token Pool Proxy"
fi

# 追加API信息到锁文件
if [ "$MODE" = "issue" ] && [ -f "$LOCK_FILE" ]; then
  echo "api_source=${API_SOURCE}" >> "$LOCK_FILE"
fi

# === 启动tmux ===
tmux new-session -d -s "$SESSION" \
  "export GH_TOKEN=$GH_TOKEN; ${API_ENV} cd $PROJECT_DIR; \
   claude -p '$CC_PROMPT' --model ${MODEL} --effort ${EFFORT} --max-turns 500 --verbose; \
   tmux kill-session -t $SESSION"

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (effort: $EFFORT, api: $API_SOURCE)"
echo "  tmux attach -t $SESSION    查看CLI界面"
echo "  Claude Office 页面查看日志"
