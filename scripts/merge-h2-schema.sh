#!/bin/bash
# merge-h2-schema.sh — 合并模块化 schema 文件
# 用法: bash scripts/merge-h2-schema.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

SCHEMA_DIR="$PROJECT_ROOT/wande-play/backend/ruoyi-modules/wande-ai/src/test/resources/schemas"
OUTPUT_FILE="$PROJECT_ROOT/wande-play/backend/ruoyi-modules/wande-ai/src/test/resources/schema.sql"

# 如果目录不存在，跳过
if [ ! -d "$SCHEMA_DIR" ]; then
  echo "目录不存在: $SCHEMA_DIR"
  exit 0
fi

ORDER_FILE="$SCHEMA_DIR/SCHEMA_ORDER.txt"

# 生成 header
echo "-- H2 测试数据库 Schema (自动生成)" > "$OUTPUT_FILE"
echo "-- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "-- 警告: 此文件由脚本自动生成，请勿手动编辑" >> "$OUTPUT_FILE"
echo "-- 如需修改，请编辑 schemas/ 目录下的模块文件" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 如果有顺序文件，按顺序合并
if [ -f "$ORDER_FILE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # 跳过注释和空行
    [[ "$line" =~ ^#.* ]] && continue
    [[ -z "$line" ]] && continue
    
    file="$SCHEMA_DIR/$line"
    if [ -f "$file" ]; then
      echo "" >> "$OUTPUT_FILE"
      echo "-- === $line ===" >> "$OUTPUT_FILE"
      cat "$file" >> "$OUTPUT_FILE"
    fi
  done < "$ORDER_FILE"
else
  # 没有顺序文件，按字母顺序合并
  for file in "$SCHEMA_DIR"/*.sql; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      echo "" >> "$OUTPUT_FILE"
      echo "-- === $filename ===" >> "$OUTPUT_FILE"
      cat "$file" >> "$OUTPUT_FILE"
    fi
  done
fi

echo "✅ schema.sql 已重新生成: $OUTPUT_FILE"
