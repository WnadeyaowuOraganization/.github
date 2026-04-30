#!/bin/bash
# frontend-page-check.sh — 新增前端页面时编码前必做的3项检查
# 用法: bash scripts/frontend-page-check.sh <新增的页面名> <新增的API路径前缀>
# 例:  bash scripts/frontend-page-check.sh project-hub /project-hub
# 无参数时进入交互模式

set -e
PAGE_NAME="${1:-}"
API_PREFIX="${2:-}"

cd "$(git rev-parse --show-toplevel)" 2>/dev/null || cd ~/projects/wande-play-kimi*/ 2>/dev/null || cd .

if [ -z "$PAGE_NAME" ]; then
  echo "用法: bash scripts/frontend-page-check.sh <页面名> <API路径前缀>"
  echo "  例:  bash scripts/frontend-page-check.sh project-hub /project-hub"
  echo ""
  echo "无参数时进入交互模式..."
  read -p "页面名（如 project-hub）: " PAGE_NAME
  read -p "API路径前缀（如 /project-hub）: " API_PREFIX
fi

EXECUTION="frontend/apps/web-antd/src/router/modules/execution.ts"
FRONTEND_ROOT="frontend/apps/web-antd/src"
RET=0

echo "=== 检查1：路由是否已在 execution.ts 注册 ==="
if grep -q "path:.*'$PAGE_NAME'\|name:.*'$PAGE_NAME'" "$EXECUTION" 2>/dev/null; then
  echo "✅ 路由已注册: $(grep -n "path:.*'$PAGE_NAME'\|name:.*'$PAGE_NAME'" "$EXECUTION" 2>/dev/null | head -1)"
else
  echo "❌ 路由未注册！请先在 $EXECUTION 添加路由"
  RET=1
fi

echo ""
echo "=== 检查2：API路径前缀是否已有文件 ==="
if [ -n "$API_PREFIX" ]; then
  # 检查是否已有相同前缀的API文件
  EXACT_API=$(grep -r "'$API_PREFIX" "$FRONTEND_ROOT/api/wande/" 2>/dev/null | head -1)
  if [ -n "$EXACT_API" ]; then
    echo "✅ API路径已存在: $(echo $EXACT_API | cut -d: -f1)"
  else
    echo "⚠️  未找到 '$API_PREFIX' 前缀的API调用，确认data.ts中的API路径是否正确"
  fi
  # 检查是否有重复前缀问题（如你配置的路径是 /project/project-hub/xxx 而实际应为 /project-hub/xxx）
  DUPE_COUNT=$(grep -r "'/[^']*'\"$PAGE_NAME" "$FRONTEND_ROOT/api/" 2>/dev/null | wc -l || echo 0)
  if [ "$DUPE_COUNT" -gt 0 ]; then
    echo "⚠️  检测到 $DUPE_COUNT 处可能含重复前缀的API调用，请检查路径是否重复（如 /project/project-hub 而非 /project-hub）"
  fi
fi

echo ""
echo "=== 检查3：含params路由跳转是否有回退值 ==="
# 检查带参数跳转的router.push是否缺少params回退
STUCK_PUSH=$(grep -rn "router.push" "$FRONTEND_ROOT/views/" 2>/dev/null | grep -E "planId|projectId|businessId" | grep -v "\|\|" | grep -v "|| " | grep -v "route.params\|default\|:\s*\[" | head -5 || true)
if [ -n "$STUCK_PUSH" ]; then
  echo "⚠️  以下 router.push 可能缺少 params 回退值（params为空时页面空白）："
  echo "$STUCK_PUSH" | head -3
else
  echo "✅ 未发现明显缺少回退值的 params 跳转"
fi

echo ""
if [ $RET -eq 0 ]; then
  echo "✅ 3项检查全部通过，可以开始编码"
else
  echo "❌ 检查未通过，请先修复以上问题再编码"
fi
exit $RET
