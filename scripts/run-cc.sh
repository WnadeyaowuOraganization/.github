#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# run-cc.sh — 统一CC启动脚本
#
# 用法:
#   run-cc.sh --module backend --issue 1234 --dir kimi1 --effort high [--model claude-sonnet-4-6]
#   run-cc.sh --module fullstack --issue 1234 --dir kimi1 --effort high
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

if [ -n "$ISSUE" ]; then MODE="issue"; else MODE="prompt"; fi

if [ "$MODE" = "issue" ] && [ -z "$DIR" ]; then
  echo "ERROR: Issue模式必须指定 --dir（如 kimi1~kimi20）"
  exit 1
fi

# === 目录解析 ===
[ "$MODULE" = "fullstack" ] && MODULE="app"

case "$MODULE" in
  backend|frontend|pipeline|app)
    if [ -n "$DIR" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play-${DIR}"
    elif [ "$MODE" = "prompt" ]; then
      BASE_DIR="${HOME_DIR}/projects/wande-play"
    else
      exit 1
    fi
    GH_REPO="WnadeyaowuOraganization/wande-play"
    ;;
  plugins|gh-plugins)
    BASE_DIR="${HOME_DIR}/projects/wande-gh-plugins${DIR:+-$DIR}"
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

# === 锁检测（在pre-task之前，避免checkout dev丢弃SAVED状态的改动）===
LOCK_FILE="${BASE_DIR}/.cc-lock"

if [ -f "$LOCK_FILE" ]; then
  LOCK_ISSUE=$(grep "^issue=" "$LOCK_FILE" 2>/dev/null | cut -d= -f2)
  LOCK_STATE=$(grep "^state=" "$LOCK_FILE" 2>/dev/null | cut -d= -f2)
  LOCK_RETRY=$(grep "^retry_count=" "$LOCK_FILE" 2>/dev/null | cut -d= -f2)

  if [ "$MODE" = "issue" ] && [ "$LOCK_ISSUE" = "$ISSUE" ]; then
    echo "同Issue重入: #${ISSUE} (state=${LOCK_STATE}, retry=${LOCK_RETRY:-0})"
  else
    echo "目录被锁: ${BASE_DIR} → Issue#${LOCK_ISSUE} (state=${LOCK_STATE})"
    exit 2
  fi
fi

# === 重试次数检查（统一用.cc-lock中的retry_count）===
if [ "$MODE" = "issue" ]; then
  RETRY=${LOCK_RETRY:-0}
  MAX_RETRIES=10
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Issue#${ISSUE} 已重试${MAX_RETRIES}次，标记Fail"
    bash "$SCRIPT_DIR/update-project-status.sh" --repo play --issue "$ISSUE" --status "Fail" 2>/dev/null || true
    gh issue comment "$ISSUE" --repo "$GH_REPO" \
      --body "❌ CC重试${MAX_RETRIES}次仍失败，标记Fail。目录: $(basename $BASE_DIR)" 2>/dev/null || true
    rm -f "$LOCK_FILE"
    cd "$BASE_DIR" && git checkout dev 2>/dev/null && git branch -D "feature-Issue-${ISSUE}" 2>/dev/null
    exit 1
  fi
fi

# === Issue模式pre-task ===
if [ "$MODE" = "issue" ]; then
  cd "$BASE_DIR"

  if [ "$LOCK_STATE" = "SAVED" ]; then
    # SAVED状态重入：session崩溃后post-cc-check触发重启，直接checkout feature分支继续
    echo "$(date): SAVED状态重入，checkout feature-Issue-${ISSUE}"
    git checkout "feature-Issue-${ISSUE}" 2>/dev/null
  else
    # 首次或RUNNING状态：正常pre-task
    echo "$(date): pre-task: checkout dev → pull → feature-Issue-${ISSUE}"
    git checkout dev 2>/dev/null && git pull origin dev 2>/dev/null
    git checkout -b "feature-Issue-${ISSUE}" 2>/dev/null || git checkout "feature-Issue-${ISSUE}" 2>/dev/null
  fi

  mkdir -p "./issues/issue-${ISSUE}"

  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
  if [ "$CURRENT_BRANCH" != "feature-Issue-${ISSUE}" ]; then
    echo "ERROR: 分支切换失败，当前=$CURRENT_BRANCH，期望=feature-Issue-${ISSUE}"
    exit 1
  fi
fi

# === 写入/更新锁 ===
if [ "$MODE" = "issue" ]; then
  cat > "$LOCK_FILE" << EOF
issue=${ISSUE}
module=${MODULE}
dir=${DIR}
model=${MODEL}
effort=${EFFORT}
state=RUNNING
time=$(date '+%Y-%m-%d %H:%M:%S')
timestamp=$(date +%s)
retry_count=${RETRY:-0}
api_source=
EOF
fi

# === Session命名：cc-{BASE_DIR_NAME}-{issue/hash} ===
# 一个kimi目录只处理一个issue，session用dirname+issue唯一标识
BASE_DIRNAME=$(basename "$BASE_DIR")
[ -z "$BASE_DIRNAME" ] || [ "$BASE_DIRNAME" = "." ] && BASE_DIRNAME="main"

if [ "$MODE" = "issue" ]; then
  SESSION="cc-${BASE_DIRNAME}-${ISSUE}"
else
  SESSION_ID=$(echo -n "$PROMPT" | md5sum | cut -c1-8)
  SESSION="cc-${BASE_DIRNAME}-${SESSION_ID}"
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

  # 优先使用 dev 分支预下载的 issue-source.md（由 prefetch-issues.sh 提前写入并推送）
  if [ -f "$ISSUE_SOURCE" ]; then
    echo "$(date): Issue #${ISSUE} 已预下载 ($(wc -l < "$ISSUE_SOURCE") 行)，跳过 gh fetch"
    CC_PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，按流程完成任务。Issue 编号: #${ISSUE}"
  else
    echo "$(date): Fetching Issue #${ISSUE} from GitHub ($GH_REPO)..."
    ISSUE_BODY=$(gh issue view "$ISSUE" --repo "$GH_REPO" --json number,title,body,labels,state \
      --jq '"# Issue #\(.number): \(.title)\n\n**Labels**: \([.labels[].name] | join(", "))\n**State**: \(.state)\n\n## 需求内容\n\n\(.body)"' 2>/dev/null)
    ISSUE_COMMENTS=$(gh issue view "$ISSUE" --repo "$GH_REPO" --comments --json comments \
      --jq 'if (.comments | length) > 0 then "\n\n---\n\n## 评论\n\n" + ([.comments[] | "### \(.author.login) (\(.createdAt | split("T")[0]))\n\n\(.body)"] | join("\n\n---\n\n")) else "" end' 2>/dev/null)

    if [ -z "$ISSUE_BODY" ]; then
      echo "WARNING: Failed to fetch Issue #${ISSUE}, CC will fetch from GitHub"
      CC_PROMPT="拾取（包含评论）并完成 Issue #${ISSUE}"
    else
      echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
      echo "$(date): Issue #${ISSUE} saved to $ISSUE_SOURCE ($(wc -l < "$ISSUE_SOURCE") lines)"
      CC_PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，按流程完成任务。Issue 编号: #${ISSUE}"
    fi
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
  API_ENV="unset ANTHROPIC_BASE_URL; unset ANTHROPIC_API_KEY; unset API_TIMEOUT_MS; unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC;"
  API_SOURCE="Claude Max订阅"
  CONFIG_DIR_ENV=""
  CLEANUP_CMD=""
else
  API_ENV="export ANTHROPIC_BASE_URL=http://localhost:9855; export ANTHROPIC_API_KEY=dummy; export API_TIMEOUT_MS=3000000; export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1;"
  API_SOURCE="Token Pool Proxy"
  # 隔离 claude.ai 凭证，避免 Auth conflict；日志目录软链到原始位置保证页面正常展示
  PROXY_CONFIG_DIR="/tmp/cc-config-${SESSION}"
  mkdir -p "$PROXY_CONFIG_DIR"
  rsync -a --exclude='.credentials.json' --exclude='projects' "${HOME_DIR}/.claude/" "$PROXY_CONFIG_DIR/"
  ln -sfn "${HOME_DIR}/.claude/projects" "$PROXY_CONFIG_DIR/projects"
  # 写入结构完整的 stub credentials：让 CC 跳过 onboarding 和主题选择
  # accessToken/refreshToken 为无效值，CC 检测到 ANTHROPIC_API_KEY 后会走代理路线
  cat > "$PROXY_CONFIG_DIR/.credentials.json" << 'CREDS_EOF'
{"claudeAiOauth":{"accessToken":"stub-proxy-mode","refreshToken":"stub-proxy-mode","expiresAt":1,"scopes":["user:inference"],"subscriptionType":"free","rateLimitTier":"free"}}
CREDS_EOF
  # 复制全局 .claude.json（含 onboarding 状态/主题/approved keys），剥离 oauth 凭证已在 .credentials.json 中处理
  [ -f "${HOME_DIR}/.claude.json" ] && cp "${HOME_DIR}/.claude.json" "$PROXY_CONFIG_DIR/.claude.json"
  CONFIG_DIR_ENV="export CLAUDE_CONFIG_DIR=${PROXY_CONFIG_DIR};"
  CLEANUP_CMD="rm -rf ${PROXY_CONFIG_DIR};"
fi

# 更新锁中的api_source
if [ "$MODE" = "issue" ] && [ -f "$LOCK_FILE" ]; then
  sed -i "s/^api_source=.*/api_source=${API_SOURCE}/" "$LOCK_FILE"
fi

# === 启动tmux（交互模式，支持attach和注入）===
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" \
  "export GH_TOKEN=$GH_TOKEN; ${API_ENV} ${CONFIG_DIR_ENV} \
   claude --model ${MODEL} --dangerously-skip-permissions; \
   ${CLEANUP_CMD} exec bash"

# 等待 Claude Code CLI 初始化完成（出现输入提示符）
sleep 5

# 注入初始 prompt
tmux send-keys -t "$SESSION" "$CC_PROMPT" Enter

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (effort: $EFFORT, api: $API_SOURCE)"
echo "  tmux attach -t $SESSION    查看/注入消息"
echo "  Claude Office 页面查看日志"
