#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# check-route-integrity.sh — 检查前端路由是否都有后端菜单配置
# 用法: bash scripts/check-route-integrity.sh [wande-play-dir]
#
# 检查逻辑:
# 1. 从前端路由文件中提取所有 path 定义
# 2. 查询 PostgreSQL sys_menu 表中的 path 字段
# 3. 对比找出缺失的路由

set -e

PLAY_DIR="${1:-${HOME_DIR}/projects/wande-play}"
FRONTEND_DIR="$PLAY_DIR/frontend"

# PostgreSQL 连接参数
PG_HOST="localhost"
PG_PORT="5433"
PG_USER="wande"
PG_DB="ruoyi_ai"
export PGPASSWORD="wande_dev_2026"

echo "=== 路由完整性检查 ==="
echo "前端目录: $FRONTEND_DIR"
echo ""

# 提取前端路由路径（从 apps/web-antd/src/router/ 下的 .ts 文件）
ROUTER_DIR="$FRONTEND_DIR/apps/web-antd/src/router"
if [ ! -d "$ROUTER_DIR" ]; then
  echo "WARNING: 路由目录不存在: $ROUTER_DIR"
  exit 0
fi

FRONTEND_ROUTES=$(grep -rPoh "path:\s*['\"]([^'\"]+)['\"]" "$ROUTER_DIR" 2>/dev/null | \
  grep -oP "(?<=['\"])[^'\"]+(?=['\"])" | \
  grep -v "^/" | grep -v "^:" | grep -v "^\*" | \
  sort -u)

if [ -z "$FRONTEND_ROUTES" ]; then
  echo "未找到前端路由定义"
  exit 0
fi

ROUTE_COUNT=$(echo "$FRONTEND_ROUTES" | wc -l)
echo "找到 $ROUTE_COUNT 个前端路由"

# 查询后端菜单表
MISSING=0
for route in $FRONTEND_ROUTES; do
  exists=$(psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -tAc \
    "SELECT 1 FROM sys_menu WHERE path='$route' LIMIT 1" 2>/dev/null || echo "")
  if [ -z "$exists" ]; then
    echo "  WARNING: 路由 '$route' 未在 sys_menu 表中配置"
    MISSING=$((MISSING + 1))
  fi
done

echo ""
if [ $MISSING -gt 0 ]; then
  echo "发现 $MISSING 个路由缺少后端菜单配置"
  exit 1
else
  echo "所有前端路由均有后端菜单配置 ✓"
  exit 0
fi
