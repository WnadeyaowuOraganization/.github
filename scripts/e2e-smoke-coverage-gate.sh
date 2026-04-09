#!/bin/bash
# e2e-smoke-coverage-gate.sh — P2.2 E2E smoke 用例覆盖率预检
#
# 用途：检查 PR 中新增的前端页面/路由是否有对应的 Playwright smoke 用例
# 失败：返回非 0 + 打印缺失的用例清单
#
# 用法：
#   bash scripts/e2e-smoke-coverage-gate.sh --pr 3487
#   bash scripts/e2e-smoke-coverage-gate.sh --branch feature-Issue-3458

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="WnadeyaowuOraganization/wande-play"

PR_NUM=""
BRANCH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --pr)     PR_NUM="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    *) echo "unknown: $1"; exit 9 ;;
  esac
done

if [ -z "$PR_NUM" ] && [ -z "$BRANCH" ]; then
  echo "必须指定 --pr <N> 或 --branch <name>"
  exit 9
fi

# 获取变更文件列表
if [ -n "$PR_NUM" ]; then
  CHANGED_FILES=$(gh pr view "$PR_NUM" --repo "$REPO" --json files --jq '.files[].path')
else
  WANDE_PLAY_DIR="/home/ubuntu/projects/wande-play"
  CHANGED_FILES=$(git -C "$WANDE_PLAY_DIR" diff --name-only origin/dev...origin/"$BRANCH" 2>/dev/null)
fi

# 筛出新增/修改的前端 .vue 视图文件（路由层）
CHANGED_VIEWS=$(echo "$CHANGED_FILES" | grep -E 'frontend/apps/web-antd/src/views/.*\.vue$' || true)
if [ -z "$CHANGED_VIEWS" ]; then
  echo "✅ 无前端视图改动，smoke coverage 检查跳过"
  exit 0
fi

echo "📋 前端视图改动："
echo "$CHANGED_VIEWS"
echo ""

# 映射规则：
#   views/wande/project/index.vue → tests/front/smoke/wande-project-page.spec.ts
#   views/wande/mine/ → tests/front/smoke/mine-*.spec.ts
WANDE_PLAY_DIR="/home/ubuntu/projects/wande-play"
SMOKE_DIR="$WANDE_PLAY_DIR/e2e/tests/front/smoke"
MISSING=()

while IFS= read -r vue_file; do
  [ -z "$vue_file" ] && continue
  # 只检查主 index.vue（页面入口），不检查子组件
  if [[ "$vue_file" != *"/index.vue" ]]; then
    continue
  fi
  # 提取模块路径：views/wande/project/index.vue → wande/project
  module_path=$(echo "$vue_file" | sed -E 's|.*views/||;s|/index\.vue$||')
  # 期望的 smoke 文件名规则：wande-project-page.spec.ts 或 wande/project/index.spec.ts
  expected_names=(
    "${module_path//\//-}-page.spec.ts"
    "${module_path//\//-}.spec.ts"
    "$(basename "$module_path")-page.spec.ts"
  )
  found=false
  for name in "${expected_names[@]}"; do
    if [ -f "$SMOKE_DIR/$name" ]; then
      echo "  ✓ $vue_file → $SMOKE_DIR/$name"
      found=true
      break
    fi
  done
  if ! $found; then
    MISSING+=("$vue_file → 期望 $SMOKE_DIR/{${expected_names[0]}}")
  fi
done <<< "$CHANGED_VIEWS"

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "❌ E2E smoke 覆盖率检查失败 — ${#MISSING[@]} 个新/改页面无对应 smoke 用例："
  printf '  - %s\n' "${MISSING[@]}"
  echo ""
  echo "请参考模板补充用例："
  echo "  模板：$WANDE_PLAY_DIR/e2e/tests/front/smoke/_template.spec.ts"
  echo "  规范：每个新页面至少 1 个 smoke，断言主组件可见 + 表格首单元格非 HTML 源码"
  exit 1
fi

echo ""
echo "🎉 E2E smoke 覆盖率检查通过"
exit 0
