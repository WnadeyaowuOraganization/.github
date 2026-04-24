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
  IMG_COUNT=$(echo "$PR_BODY" | grep -cE '!\[[^]]*\]\([^)]+\.(png|jpg|jpeg|gif|webp)' || true)
  IMG_COUNT=${IMG_COUNT:-0}
  if [ "$IMG_COUNT" -eq 0 ]; then
    echo "═══ 门 3 失败：前端 PR（$FRONTEND_CHANGES_COUNT 个 views 文件改动）缺少视觉验证截图 ═══"
    echo ""
    echo "请按如下方式补充截图（参考 #3547 CC 的做法）："
    echo "  1. 本地 pnpm dev 启动前端 (端口从 vite 配置里看)"
    echo "  2. 用 Playwright headless 截图 / 或 chrome-headless --screenshot="
    echo "  3. gh release create screenshot-\$PR_NUM --repo <repo> --notes 'screenshot' file.png"
    echo "  4. 拿到 https://github.com/.../releases/download/... URL"
    echo "  5. gh pr edit \$PR_NUM --body-file <新body>  其中 body 末尾追加 ![desc](<url>)"
    fail 3 "门 3: 前端 PR 必须含 Markdown 图片（![](.*\.png)），当前 $IMG_COUNT 张"
  fi
  ok "门 3 通过：前端 PR 含 $IMG_COUNT 张截图"

  # 漏洞 F 修复：门 3 cross-check — 勾了"截图/视觉/Playwright"类文字但实际 0 图片 → 假勾选
  CHECKED_SCREENSHOT=$(echo "$PR_BODY" | grep -cE '^- \[x\].*(截图|视觉|screenshot|Screenshot|Playwright|视频)' || true)
  CHECKED_SCREENSHOT=${CHECKED_SCREENSHOT:-0}
  if [ "$CHECKED_SCREENSHOT" -gt 0 ] && [ "$IMG_COUNT" -eq 0 ]; then
    echo "═══ 门 3 cross-check 失败：假勾选检测 ═══"
    echo "PR body 勾了 $CHECKED_SCREENSHOT 项「截图/视觉」相关 checkbox，但实际无 Markdown 图片"
    echo "这是 #3487/#3547 事故同款反模式 — 勾 checkbox 不做实事"
    fail 3 "门 3 cross-check: 先截图贴图再勾 checkbox，严禁假勾选"
  fi
  log "门 3 cross-check OK（$CHECKED_SCREENSHOT checkbox + $IMG_COUNT 图片）"

  # 漏洞 D 修复：门 4 — 前端 index.vue 改动必须有 smoke 用例
  # （对齐 pr-test.yml quality-gate 门 4）
  for kimi in /home/ubuntu/projects/wande-play-kimi* /home/ubuntu/projects/wande-play; do
    if [ -d "$kimi/.git" ]; then
      INDEX_CHANGES=$(git -C "$kimi" diff --name-only origin/dev...HEAD 2>/dev/null | grep -E 'frontend/apps/web-antd/src/views/.*index\.vue$' || true)
      if [ -n "$INDEX_CHANGES" ]; then
        SMOKE_COUNT=$(git -C "$kimi" diff --name-only origin/dev...HEAD 2>/dev/null | grep -c 'e2e/tests/front/smoke/.*\.spec\.ts$' || true)
        SMOKE_COUNT=${SMOKE_COUNT:-0}
        if [ "$SMOKE_COUNT" -eq 0 ]; then
          echo "═══ 门 4 失败：前端 index.vue 改动无对应 smoke 用例 ═══"
          echo "改动文件："
          echo "$INDEX_CHANGES"
          echo ""
          echo "修复命令："
          echo "  cp e2e/tests/front/smoke/_template.spec.ts e2e/tests/front/smoke/<module>-page.spec.ts"
          echo "  # 修改 ROUTE 和 PAGE_NAME，保留 3 条反事故断言"
          fail 4 "门 4: 前端 index.vue 必须有对应 smoke 用例（防 #3487 slot 字符串事故）"
        fi
        ok "门 4 通过（$SMOKE_COUNT smoke 用例文件）"
        break
      fi
    fi
  done
else
  log "非前端 PR，跳过门 3/4"
fi

# 漏洞 B 修复：门 5 — 检查是否 rebase 过 dev（当前分支不应该 behind origin/dev）
# 修复 2026-04-15：只查 caller 所在的 kimi 目录（pwd 的 git toplevel），不 loop 其他 kimi
CALLER_KIMI=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$CALLER_KIMI" ] && [ -d "$CALLER_KIMI/.git" ]; then
  CURRENT_BRANCH=$(git -C "$CALLER_KIMI" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ] && [ "$CURRENT_BRANCH" != "dev" ] && [ "$CURRENT_BRANCH" != "main" ]; then
    git -C "$CALLER_KIMI" fetch origin dev --quiet 2>/dev/null || true
    BEHIND=$(git -C "$CALLER_KIMI" rev-list --count HEAD..origin/dev 2>/dev/null || echo 0)
    if [ "$BEHIND" -gt 0 ]; then
      echo "═══ 门 5 失败：当前分支 $CURRENT_BRANCH 落后 origin/dev $BEHIND 个 commit ═══"
      echo ""
      echo "修复命令："
      echo "  git fetch origin dev && git rebase origin/dev"
      echo "  # 解决冲突后"
      echo "  git push --force-with-lease"
      fail 5 "门 5: 提 PR 前必须 rebase origin/dev（防 mergeable_state=dirty 导致 CI skip）"
    fi
    log "门 5 通过（分支 $CURRENT_BRANCH 已 up-to-date with origin/dev）"
  else
    log "门 5 跳过（在 $CURRENT_BRANCH 上，非 feature 分支）"
  fi
else
  log "门 5 跳过（非 git 仓库）"
fi

# ============================================================
# 门 6 — Issue checkbox 全勾（甲方需求验收项必须全部满足）
# ============================================================
if [ -n "$ISSUE" ]; then
  ISSUE_SOURCE=""
  for kimi in /home/ubuntu/projects/wande-play-kimi* /home/ubuntu/projects/wande-play; do
    f="$kimi/issues/issue-${ISSUE}/issue-source.md"
    if [ -f "$f" ]; then
      ISSUE_SOURCE="$f"
      break
    fi
  done

  if [ -n "$ISSUE_SOURCE" ]; then
    UNCHECKED_ISSUE=$(grep -cE '^\s*- \[ \]' "$ISSUE_SOURCE" 2>/dev/null || true)
    UNCHECKED_ISSUE=${UNCHECKED_ISSUE:-0}
    if [ "$UNCHECKED_ISSUE" -gt 0 ]; then
      echo "═══ 门 6 失败：Issue #${ISSUE} 存在 $UNCHECKED_ISSUE 项未勾需求 ═══"
      echo ""
      echo "未满足的需求项："
      grep -nE '^\s*- \[ \]' "$ISSUE_SOURCE" | head -10
      echo ""
      echo "Issue checkbox 是甲方的需求验收清单，必须全部满足后才能提 PR。"
      echo "如果某项确认不做，在 task.md 备注原因并勾选该项。"
      fail 6 "门 6: Issue #${ISSUE} 需求清单存在 $UNCHECKED_ISSUE 项未勾"
    fi
    ok "门 6 通过：Issue #${ISSUE} 需求清单全部勾选（或无 checkbox）"
  else
    log "门 6 跳过：issue-source.md 未找到"
  fi
else
  log "门 6 跳过：未指定 --issue"
fi

echo ""
echo "🎉 pr-body-lint 全部 6 道门通过，可以 gh pr create"
exit 0
