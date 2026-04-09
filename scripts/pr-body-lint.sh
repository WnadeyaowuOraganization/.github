#!/bin/bash
# pr-body-lint.sh — PR body / task.md 本地预检（P1.3 - 2026-04-09）
#
# 用途：CC 在 `gh pr create` 之前调用一次，确保不会被 quality-gate 拦截
#
# 检查项（与 quality-gate 三道门对齐）：
#   门 1 — PR body 无 `- [ ]` 未勾 checkbox
#   门 2 — task.md 无 `- [ ]` 未勾 steps
#   门 3 — 前端改动（frontend/apps/web-antd/src/views/**）PR body 必须含 Markdown 图片
#
# 用法：
#   bash scripts/pr-body-lint.sh --pr-body pr-body.md --issue 3458
#   bash scripts/pr-body-lint.sh --pr-body-stdin < pr-body.md --issue 3458
#   echo "$PR_BODY" | bash scripts/pr-body-lint.sh --pr-body-stdin --issue 3458
#
# 退出码：
#   0  通过
#   1  门 1 失败（PR body 未勾）
#   2  门 2 失败（task.md 未勾）
#   3  门 3 失败（前端无截图）
#   9  参数错误

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PR_BODY_FILE=""
PR_BODY_STDIN=false
ISSUE=""
FRONTEND_CHANGES_COUNT=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --pr-body)       PR_BODY_FILE="$2"; shift 2 ;;
    --pr-body-stdin) PR_BODY_STDIN=true; shift ;;
    --issue)         ISSUE="$2"; shift 2 ;;
    --frontend-changes) FRONTEND_CHANGES_COUNT="$2"; shift 2 ;;
    --verbose|-v)    VERBOSE=true; shift ;;
    *) echo "Unknown arg: $1"; exit 9 ;;
  esac
done

log() { $VERBOSE && echo "[lint] $*" >&2; true; }
fail() { echo "❌ $*" >&2; exit "$1"; }
ok()   { echo "✅ $*"; }

# 读取 PR body
if [ -n "$PR_BODY_FILE" ]; then
  [ ! -f "$PR_BODY_FILE" ] && fail 9 "PR body file not found: $PR_BODY_FILE"
  PR_BODY=$(cat "$PR_BODY_FILE")
elif $PR_BODY_STDIN; then
  PR_BODY=$(cat)
else
  fail 9 "必须指定 --pr-body <file> 或 --pr-body-stdin"
fi

log "PR body 长度: $(echo "$PR_BODY" | wc -c) 字符"

# ============================================================
# 门 1 — PR body 无 `- [ ]`
# ============================================================
UNCHECKED_PR=$(echo "$PR_BODY" | grep -c '^- \[ \]' 2>/dev/null || true)
UNCHECKED_PR=${UNCHECKED_PR:-0}
if [ "$UNCHECKED_PR" -gt 0 ]; then
  echo "═══ 门 1 失败：PR body 存在 $UNCHECKED_PR 项未勾 checkbox ═══"
  echo "$PR_BODY" | grep -n '^- \[ \]' | head -10
  fail 1 "门 1: PR body 必须全勾，请补齐或删除 placeholder 再提交"
fi
ok "门 1 通过：PR body 无未勾 checkbox"

# ============================================================
# 门 2 — task.md 无 `- [ ]`
# ============================================================
if [ -n "$ISSUE" ]; then
  TASK_FILE="$BASE_DIR/issues/issue-${ISSUE}/task.md"
  if [ ! -f "$TASK_FILE" ]; then
    # 也尝试 kimi 目录
    for kimi_dir in /home/ubuntu/projects/wande-play-kimi*/issues/issue-${ISSUE}/task.md; do
      if [ -f "$kimi_dir" ]; then
        TASK_FILE="$kimi_dir"
        break
      fi
    done
  fi
  if [ -f "$TASK_FILE" ]; then
    UNCHECKED_TASK=$(grep -c '^- \[ \]' "$TASK_FILE" 2>/dev/null || true)
    UNCHECKED_TASK=${UNCHECKED_TASK:-0}
    if [ "$UNCHECKED_TASK" -gt 0 ]; then
      echo "═══ 门 2 失败：$TASK_FILE 存在 $UNCHECKED_TASK 项未勾 steps ═══"
      grep -n '^- \[ \]' "$TASK_FILE" | head -10
      fail 2 "门 2: task.md 必须全勾，如无法完成请拆分为追补 Issue 后勾选"
    fi
    ok "门 2 通过：$TASK_FILE 无未勾 steps"
  else
    log "task.md 未找到，跳过门 2（非 issue 模式）"
  fi
else
  log "未指定 --issue，跳过门 2"
fi

# ============================================================
# 门 3 — 前端 PR 必须有截图
# ============================================================
# 自动检测前端改动数量（如果 --frontend-changes 未指定）
if [ -z "$FRONTEND_CHANGES_COUNT" ]; then
  if git -C "$BASE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    FRONTEND_CHANGES_COUNT=$(git -C "$BASE_DIR" diff --name-only origin/dev...HEAD 2>/dev/null | grep -c 'frontend/apps/web-antd/src/views' || true)
  else
    # 当前目录不是 git repo，尝试 wande-play 系列
    for kimi in /home/ubuntu/projects/wande-play-kimi* /home/ubuntu/projects/wande-play; do
      if [ -d "$kimi/.git" ]; then
        cnt=$(git -C "$kimi" diff --name-only origin/dev...HEAD 2>/dev/null | grep -c 'frontend/apps/web-antd/src/views' || true)
        if [ "${cnt:-0}" -gt 0 ]; then
          FRONTEND_CHANGES_COUNT=$cnt
          log "在 $kimi 检测到 $cnt 个前端改动"
          break
        fi
      fi
    done
  fi
  FRONTEND_CHANGES_COUNT=${FRONTEND_CHANGES_COUNT:-0}
fi

log "前端改动文件数: $FRONTEND_CHANGES_COUNT"

if [ "$FRONTEND_CHANGES_COUNT" -gt 0 ]; then
  # 检查 PR body 是否含 Markdown 图片
  if ! echo "$PR_BODY" | grep -qE '!\[[^]]*\]\([^)]+\.(png|jpg|jpeg|gif|webp)[^)]*\)'; then
    echo "═══ 门 3 失败：前端 PR（$FRONTEND_CHANGES_COUNT 个 views 文件改动）缺少视觉验证截图 ═══"
    echo ""
    echo "请按如下方式补充截图："
    echo "  1. Dev 环境: http://3.211.167.122:8083 (admin/admin123)"
    echo "  2. 打开你改过的页面路由 → 手动或用 Playwright 截图"
    echo "  3. 在 PR body 追加: ![页面描述](/path/to/screenshot.png)"
    fail 3 "门 3: 前端 PR 必须含 Markdown 图片（![](.*\.png)）"
  fi
  ok "门 3 通过：前端 PR 含截图"
else
  log "非前端 PR，跳过门 3"
fi

echo ""
echo "🎉 pr-body-lint 全部通过，可以 gh pr create"
exit 0
