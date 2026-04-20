#!/bin/bash
# ==============================================================
# run-hotfix-cc.sh — 启动 Hotfix CC
#
# 用途：对主测试环境（http://localhost:8080）进行快速修复，
#       代码直接推 dev 触发 CI/CD 部署，不走 feature 分支 + PR 流程。
#
# 工作目录：/data/home/ubuntu/projects/wande-play-quick-fix
# Skill 加载：quick-fix（首位加载）+ 全部普通 CC skills
# 模型：默认 Sonnet 4.6（可传 --model 覆盖）
#
# 用法：
#   bash scripts/run-hotfix-cc.sh
#   bash scripts/run-hotfix-cc.sh --model claude-opus-4-6
# ==============================================================

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
GITHUB_DIR="${HOME_DIR}/projects/.github"
SCRIPT_DIR="${GITHUB_DIR}/scripts"
WORK_DIR="/data/home/ubuntu/projects/wande-play-quick-fix"
SESSION="hotfix-cc"
MODEL="claude-sonnet-4-6"

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

# ==============================================================
# 前置检查
# ==============================================================

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠️  hotfix-cc 已在运行 (session: $SESSION)"
  echo "   tmux attach -t $SESSION"
  exit 0
fi

if [ ! -d "$WORK_DIR/.git" ]; then
  echo "❌ 工作目录不存在或非 git repo: $WORK_DIR"
  echo "   请先执行: git clone <repo> $WORK_DIR && cd $WORK_DIR && git checkout dev"
  exit 1
fi

# ==============================================================
# 同步工作目录到最新 dev
# ==============================================================

GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)
echo "🔄 同步 wande-play-quick-fix → origin/dev ..."
cd "$WORK_DIR"
git remote set-url origin \
  "https://x-access-token:${GH_TOKEN}@github.com/WnadeyaowuOraganization/wande-play.git" \
  2>/dev/null
git fetch origin dev -q
git checkout dev -q 2>/dev/null || true
git reset --hard origin/dev -q
echo "   当前 HEAD: $(git log --oneline -1)"

# ==============================================================
# 配置 skill 加载（quick-fix 首位 + 所有普通 skills）
# ==============================================================

SKILLS_DIR="$WORK_DIR/.claude/skills"
mkdir -p "$SKILLS_DIR"

# 清掉旧 symlink
find "$SKILLS_DIR" -maxdepth 1 -type l -exec rm -f {} \; 2>/dev/null || true

# 1. 首位加载 quick-fix（前缀 000- 保证字母序最先）
HOTFIX_SKILL_SRC="${GITHUB_DIR}/docs/agent-docs/hotfix-cc/quick-fix"
if [ -f "${HOTFIX_SKILL_SRC}/SKILL.md" ]; then
  ln -sfn "$HOTFIX_SKILL_SRC" "$SKILLS_DIR/000-quick-fix"
  echo "✅ 首位 skill: 000-quick-fix → hotfix-cc/quick-fix"
else
  echo "❌ quick-fix SKILL.md 不存在: ${HOTFIX_SKILL_SRC}/SKILL.md"
  exit 1
fi

# 2. 追加所有普通 CC skills（正常字母序，排在 quick-fix 之后）
REGULAR_SKILLS_SRC="${GITHUB_DIR}/docs/agent-docs/skills"
skill_count=0
for skill_dir in "$REGULAR_SKILLS_SRC"/*/; do
  [ -f "${skill_dir}SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  ln -sfn "${skill_dir%/}" "$SKILLS_DIR/$skill_name"
  skill_count=$((skill_count + 1))
done
echo "✅ 普通 skills: $skill_count 个"
echo "   加载顺序: $(ls -1 "$SKILLS_DIR" | head -5 | tr '\n' ' ')..."

# ==============================================================
# 同步 CLAUDE.md
# ==============================================================

if [ -f "${REGULAR_SKILLS_SRC}/CLAUDE.md" ]; then
  cp -f "${REGULAR_SKILLS_SRC}/CLAUDE.md" "$WORK_DIR/CLAUDE.md"
fi

# ==============================================================
# 隔离 Claude config（使用当前用户 Claude 订阅凭证）
# ==============================================================

CONFIG_DIR="/tmp/cc-config-${SESSION}"
mkdir -p "$CONFIG_DIR"
rsync -a --exclude='projects' "${HOME_DIR}/.claude/" "$CONFIG_DIR/" 2>/dev/null
ln -sfn "${HOME_DIR}/.claude/projects" "$CONFIG_DIR/projects"
[ -f "${HOME_DIR}/.claude.json" ] && cp "${HOME_DIR}/.claude.json" "$CONFIG_DIR/.claude.json"

# ==============================================================
# 启动 tmux session
# ==============================================================

INIT_PROMPT="你是 Hotfix CC，专职对主测试环境（http://localhost:8080）进行快速修复。\
工作目录已就绪（/data/home/ubuntu/projects/wande-play-quick-fix，dev 分支最新）。\
请优先阅读 000-quick-fix skill（/skill:000-quick-fix），然后等待甲方提出具体问题。"

tmux new-session -d -s "$SESSION" -c "$WORK_DIR" \
  "export GH_TOKEN=${GH_TOKEN}; \
   export HOME=${HOME_DIR}; \
   export PATH=${HOME_DIR}/.local/bin:\$PATH; \
   unset ANTHROPIC_API_KEY; unset ANTHROPIC_BASE_URL; \
   export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1; \
   export CLAUDE_CONFIG_DIR=${CONFIG_DIR}; \
   claude --model ${MODEL} --dangerously-skip-permissions; \
   rm -rf ${CONFIG_DIR}; exec bash"

sleep 8
tmux send-keys -t "$SESSION" "$INIT_PROMPT" Enter

echo ""
echo "🚀 Hotfix CC 已启动"
echo "   session : $SESSION"
echo "   model   : $MODEL"
echo "   workdir : $WORK_DIR"
echo "   skills  : 000-quick-fix (首位) + ${skill_count} 个普通 skills"
echo ""
echo "   tmux attach -t $SESSION"
