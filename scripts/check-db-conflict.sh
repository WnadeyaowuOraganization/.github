#!/bin/bash
# check-db-conflict.sh — 检查 schema 文件是否有冲突风险
# 用法: bash scripts/check-db-conflict.sh [issue_number]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

ISSUE_NUMBER=$1
SCHEMA_DIR="$PROJECT_ROOT/wande-play/backend/ruoyi-modules/wande-ai/src/test/resources/schemas"

echo "=== 数据库脚本冲突检查 ==="
echo ""

# 检查目录是否存在
if [ ! -d "$SCHEMA_DIR" ]; then
  echo "⚠️  schemas 目录不存在，这是首次使用模块化方案"
  echo "   请运行: mkdir -p $SCHEMA_DIR"
  exit 0
fi

# 如果指定了 Issue 号，检查是否已存在
if [ -n "$ISSUE_NUMBER" ]; then
  echo "检查 Issue #$ISSUE_NUMBER 的文件..."
  if [ -f "$SCHEMA_DIR/issue_$ISSUE_NUMBER.sql" ]; then
    echo "⚠️  文件已存在: issue_$ISSUE_NUMBER.sql"
    echo "   如需修改，请编辑此文件"
  else
    echo "✅ 可以创建新文件: issue_$ISSUE_NUMBER.sql"
  fi
  exit 0
fi

# 检查所有文件
echo "当前 schemas 目录下的文件:"
echo ""
ls -la "$SCHEMA_DIR"/*.sql 2>/dev/null || echo "  (无 .sql 文件)"

echo ""
echo "=== 建议的文件命名规范 ==="
echo "  - 新表: issue_XXXX.sql"
echo "  - 修改表: _alter_issue_XXXX.sql"
echo "  - 模块表: module_xxx.sql"
echo "  - 基础表: _base.sql"
