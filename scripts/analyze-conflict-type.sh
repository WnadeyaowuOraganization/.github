#!/bin/bash
# analyze-conflict-type.sh — 分析PR冲突文件类型，区分简单/复杂冲突
# 用法: bash scripts/analyze-conflict-type.sh <conflict_files_list>
# 输入: 一行一个冲突文件路径（从git diff --name-only --diff-filter=U获取）
# 输出: SIMPLE_FILES 和 COMPLEX_FILES 两个变量

SIMPLE_FILES=""
COMPLEX_FILES=""
SIMPLE_COUNT=0
COMPLEX_COUNT=0

while IFS= read -r file; do
  [ -z "$file" ] && continue

  case "$file" in
    # 简单冲突：自动解决（使用dev版本）
    *schema*.sql|*h2*.sql|*test-data*.sql)
      SIMPLE_FILES="$SIMPLE_FILES$file\n"
      SIMPLE_COUNT=$((SIMPLE_COUNT + 1))
      ;;
    *pom.xml)
      SIMPLE_FILES="$SIMPLE_FILES$file\n"
      SIMPLE_COUNT=$((SIMPLE_COUNT + 1))
      ;;
    */test/*|*/tests/*|*Test.java|*Test.ts|*.test.ts|*.spec.ts)
      SIMPLE_FILES="$SIMPLE_FILES$file\n"
      SIMPLE_COUNT=$((SIMPLE_COUNT + 1))
      ;;
    # 复杂冲突：需要CC智能解决
    *.java|*.ts|*.vue|*.tsx|*.jsx|*.py)
      COMPLEX_FILES="$COMPLEX_FILES$file\n"
      COMPLEX_COUNT=$((COMPLEX_COUNT + 1))
      ;;
    # 其他文件：默认归为简单
    *)
      SIMPLE_FILES="$SIMPLE_FILES$file\n"
      SIMPLE_COUNT=$((SIMPLE_COUNT + 1))
      ;;
  esac
done

echo "=== 冲突分类结果 ==="
echo "简单冲突（可自动解决）: $SIMPLE_COUNT 个"
echo -e "$SIMPLE_FILES" | grep -v '^$'
echo ""
echo "复杂冲突（需CC处理）: $COMPLEX_COUNT 个"
echo -e "$COMPLEX_FILES" | grep -v '^$'

# 导出供调用者使用
export SIMPLE_FILES COMPLEX_FILES SIMPLE_COUNT COMPLEX_COUNT
