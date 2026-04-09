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
# 2026-04-09: lock 文件迁移到 /home/ubuntu/cc_scheduler/lock/<dirname>.lock
# 不再放在 BASE_DIR 内，避免被 git tracked + 误 commit + 跨 kimi 目录污染
LOCK_DIR="${HOME_DIR}/cc_scheduler/lock"
mkdir -p "$LOCK_DIR" 2>/dev/null
LOCK_FILE="${LOCK_DIR}/$(basename ${BASE_DIR}).lock"

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
    # SAVED状态重入：session崩溃后cc-keepalive触发重启，直接checkout feature分支继续
    echo "$(date): SAVED状态重入，checkout feature-Issue-${ISSUE}"
    git checkout "feature-Issue-${ISSUE}" 2>/dev/null
  else
    # 首次或RUNNING状态：正常pre-task
    # 2026-04-09 #3554 事故修复：不再用 2>/dev/null 屏蔽 git 错误，pre-task 失败必须立即 exit
    echo "$(date): pre-task: 清理 dev 状态 → fetch → 重建 feature-Issue-${ISSUE}"

    # 1. 强制清理 dev 可能的本地改动（防止 pull 失败）
    git checkout -f dev 2>&1 | tail -3 || { echo "ERROR: checkout dev 失败"; exit 1; }
    git reset --hard HEAD 2>&1 | tail -3  # 清理任何未提交改动

    # 2. fetch 远端最新（不用 pull，避免 merge 冲突）
    git fetch origin dev 2>&1 | tail -3 || { echo "ERROR: fetch origin dev 失败"; exit 1; }

    # 3. 强制本地 dev 对齐远端（彻底消除分叉）
    git reset --hard origin/dev 2>&1 | tail -3 || { echo "ERROR: reset --hard origin/dev 失败"; exit 1; }

    # 4. 如果 feature 分支已存在，删除重建（防止基于老 dev 的陈旧分支复用 → #3554 同款事故）
    if git show-ref --verify --quiet "refs/heads/feature-Issue-${ISSUE}"; then
      echo "$(date): feature-Issue-${ISSUE} 已存在，删除重建（防 #3554 陈旧分支事故）"
      git branch -D "feature-Issue-${ISSUE}" 2>&1 | tail -1 || true
    fi

    # 5. 基于最新 dev 创建干净 feature 分支
    git checkout -b "feature-Issue-${ISSUE}" 2>&1 | tail -3 || { echo "ERROR: 创建 feature-Issue-${ISSUE} 失败"; exit 1; }

    echo "$(date): pre-task 完成，feature-Issue-${ISSUE} 基于 $(git rev-parse --short HEAD) = $(git rev-parse --short origin/dev)"
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
# 确保获取新鲜 token（run-cc.sh 需要为新 tmux 会话设置独立的 token）
export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py")

# === Prompt构建 ===
if [ "$MODE" = "issue" ]; then
  ISSUE_DIR="$BASE_DIR/issues/issue-${ISSUE}"
  ISSUE_SOURCE="$ISSUE_DIR/issue-source.md"
  mkdir -p "$ISSUE_DIR"

  # 优先使用 dev 分支预下载的 issue-source.md（由 prefetch-issues.sh 提前写入并推送）
  if [ -f "$ISSUE_SOURCE" ]; then
    echo "$(date): Issue #${ISSUE} 已预下载 ($(wc -l < "$ISSUE_SOURCE") 行)，跳过 gh fetch"
  else
    echo "$(date): Fetching Issue #${ISSUE} from GitHub ($GH_REPO)..."
    ISSUE_BODY=$(gh issue view "$ISSUE" --repo "$GH_REPO" --json number,title,body,labels,state \
      --jq '"# Issue #\(.number): \(.title)\n\n**Labels**: \([.labels[].name] | join(", "))\n**State**: \(.state)\n\n## 需求内容\n\n\(.body)"' 2>/dev/null)
    ISSUE_COMMENTS=$(gh issue view "$ISSUE" --repo "$GH_REPO" --comments --json comments \
      --jq 'if (.comments | length) > 0 then "\n\n---\n\n## 评论\n\n" + ([.comments[] | "### \(.author.login) (\(.createdAt | split("T")[0]))\n\n\(.body)"] | join("\n\n---\n\n")) else "" end' 2>/dev/null)

    if [ -n "$ISSUE_BODY" ]; then
      echo "${ISSUE_BODY}${ISSUE_COMMENTS}" > "$ISSUE_SOURCE"
      echo "$(date): Issue #${ISSUE} saved to $ISSUE_SOURCE ($(wc -l < "$ISSUE_SOURCE") lines)"
    fi
  fi

  # === 构建 prompt（v2.2 - 2026-04-09 起引用 share/shared-conventions.md 模板，含 9 条硬约束） ===
  PROMPT_TEMPLATE="$SCRIPT_DIR/../docs/agent-docs/share/shared-conventions.md"
  if [ -f "$PROMPT_TEMPLATE" ]; then
    # 用 envsubst 或 bash 字符串替换 ${ISSUE}
    CC_PROMPT=$(ISSUE="$ISSUE" envsubst '${ISSUE}' < "$PROMPT_TEMPLATE" 2>/dev/null || sed "s/\${ISSUE}/${ISSUE}/g" "$PROMPT_TEMPLATE")
    echo "$(date): 使用 prompt 模板 v2.2 (share/shared-conventions.md, $(wc -l < "$PROMPT_TEMPLATE") 行)"
  elif [ -f "$ISSUE_SOURCE" ]; then
    # fallback v1 纯字符串（兼容性）
    CC_PROMPT="阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，按流程完成任务。Issue 编号: #${ISSUE}"
    echo "$(date): [WARN] prompt 模板 v2 不存在，fallback 到 v1"
  else
    CC_PROMPT="拾取（包含评论）并完成 Issue #${ISSUE}"
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

# === 准备测试 PG 独立 DB（per-kimi 隔离）===
# BASE_DIR 形如 .../wande-play-kimi3，提取 kimi3 作为 DB suffix
KIMI_TAG=$(basename "$BASE_DIR" | sed 's/wande-play-//;s/wande-play//')
[ -z "$KIMI_TAG" ] && KIMI_TAG="main"
TEST_PG_DB="wande_test_${KIMI_TAG}"
bash "$SCRIPT_DIR/ensure-test-pg.sh" "$KIMI_TAG" 2>&1 | tail -3 || true
TEST_PG_ENV="export TEST_PG_HOST=localhost; export TEST_PG_PORT=5434; export TEST_PG_DB=${TEST_PG_DB}; export TEST_PG_USER=wande; export TEST_PG_PASSWORD=wande_test;"

# === 每个 kimi 用独立 maven repo（避免并发 mvn install race condition）===
# 实现：m2-cc-prepare.sh 在 /dev/shm/m2-cc-${KIMI_TAG} 准备一份独立 repo
#   - 第一次调用时把 ~/.m2-base 加载到 /dev/shm/m2-base/（共享 base，refcount 管理）
#   - 每次调用 cp -a base → /dev/shm/m2-cc-${KIMI_TAG}/（独立写入区）
#   - CC 退出时由 release-cc-lock.sh 调 m2-cc-cleanup.sh 释放
# 完全 tmpfs，无 hardlink 元信息污染。base 共享只占 1 份内存。
# 注：所有 module 都准备 maven repo（CC 是全栈开发，前端任务可能需要跑后端测试或反向）
# 兜底：如果 m2-cc-prepare.sh 不存在（升级中）或失败，回退到旧的 .m2-${KIMI_TAG} 模式
M2_OPTS=$(bash "$SCRIPT_DIR/m2-cc-prepare.sh" "$KIMI_TAG" 2>&1 | tail -1)
if [ -n "$M2_OPTS" ] && echo "$M2_OPTS" | grep -q "^-Dmaven.repo.local="; then
  MAVEN_ENV="export MAVEN_OPTS='${M2_OPTS}';"
  M2_REPO_PATH="${M2_OPTS#-Dmaven.repo.local=}"
else
  echo "⚠️ m2-cc-prepare.sh 失败，回退到磁盘 .m2-${KIMI_TAG} 模式"
  M2_REPO_PATH="${HOME_DIR}/.m2-${KIMI_TAG}/repository"
  if [ ! -d "$M2_REPO_PATH" ]; then
    mkdir -p "$M2_REPO_PATH"
    cp -al "${HOME_DIR}/.m2/repository/." "$M2_REPO_PATH/" 2>/dev/null || true
  fi
  MAVEN_ENV="export MAVEN_OPTS='-Dmaven.repo.local=${M2_REPO_PATH}';"
fi

# 把 maven repo 路径写入锁文件，便于 cleanup / 监控
if [ "$MODE" = "issue" ] && [ -f "$LOCK_FILE" ]; then
  if grep -q "^m2_repo=" "$LOCK_FILE" 2>/dev/null; then
    sed -i "s|^m2_repo=.*|m2_repo=${M2_REPO_PATH}|" "$LOCK_FILE"
  else
    echo "m2_repo=${M2_REPO_PATH}" >> "$LOCK_FILE"
  fi
fi

# === 启动tmux（交互模式，支持attach和注入）===
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" \
  "export GH_TOKEN=$GH_TOKEN; ${API_ENV} ${CONFIG_DIR_ENV} ${TEST_PG_ENV} ${MAVEN_ENV} \
   claude --model ${MODEL} --dangerously-skip-permissions; \
   ${CLEANUP_CMD} exec bash"

# 等待 Claude Code CLI 初始化完成（出现输入提示符）
sleep 5

# 注入初始 prompt
# v2 prompt (126 行) 会被 Claude Code CLI 识别为 paste mode，需补一个额外 Enter 触发提交
# v1 单行 prompt 也能兼容额外 Enter（只是多一次空回车）
tmux send-keys -t "$SESSION" "$CC_PROMPT" Enter
sleep 3
tmux send-keys -t "$SESSION" "" Enter

echo "✓ CC已在tmux会话 '$SESSION' 中启动 (effort: $EFFORT, api: $API_SOURCE)"
echo "  tmux attach -t $SESSION    查看/注入消息"
echo "  Claude Office 页面查看日志"
