#!/bin/bash
# weekly-quality-report.sh — P3.1 质量评分周报
#
# 从 docs/workflow/新harness验证报告.md 的「批次评估」章节提取评分
# 生成周报：平均分 / 低分 PR 清单 / kimi 质量画像 / 反模式统计
#
# 用法：
#   bash scripts/weekly-quality-report.sh            # 本周
#   bash scripts/weekly-quality-report.sh --days 14  # 近 14 天

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT="$BASE_DIR/docs/workflow/新harness验证报告.md"

DAYS=7
while [[ $# -gt 0 ]]; do
  case $1 in
    --days) DAYS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ ! -f "$REPORT" ]; then
  echo "❌ 报告不存在: $REPORT"
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  质量评分周报 — 近 $DAYS 天"
echo "  生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════"
echo ""

# 提取所有批次评估的总分行
# 格式示例：**综合评分：🔴 5.40 / 10 — 不合格**
# 或：**加权总分** + `= N.NN / 10`
SCORES=$(grep -nE "综合评分[：:].*[0-9]\.[0-9]+\s*/\s*10|= [0-9]\.[0-9]+ / 10" "$REPORT" || true)

if [ -z "$SCORES" ]; then
  echo "⚠️ 报告中未找到评分数据"
  exit 0
fi

echo "📊 最近批次评估汇总："
echo "$SCORES" | head -20
echo ""

# 计算平均分（简化 awk）
AVG=$(echo "$SCORES" | grep -oE '[0-9]\.[0-9]+\s*/\s*10' | grep -oE '[0-9]\.[0-9]+' | awk '{s+=$1; c++} END { if(c>0) printf "%.2f", s/c; else print "N/A" }')
COUNT=$(echo "$SCORES" | grep -c '/\s*10' || echo 0)

echo "▸ 批次数：$COUNT"
echo "▸ 平均分：$AVG / 10"
echo ""

# 反模式出现次数统计（从报告中全文搜索）
echo "🔍 反模式出现次数（全报告累计）："
for pattern in "slot 返回 HTML 字符串" "半成品合并" "task.md.*未勾" "checkbox.*未勾" "前端.*未做" "集成.*未"; do
  cnt=$(grep -c "$pattern" "$REPORT" || true)
  printf "  %-40s %s\n" "$pattern" "$cnt 次"
done
echo ""

# 低分 PR 列表（< 7.0）
echo "🔴 低分 PR 清单（< 7.0）："
echo "$SCORES" | grep -oE 'PR\s*#?[0-9]+.*[0-9]\.[0-9]+\s*/\s*10' 2>/dev/null | awk -F/ '{
  for (i=1; i<=NF; i++) {
    if ($i ~ /[0-9]\.[0-9]+/) {
      match($i, /[0-9]\.[0-9]+/, m)
      if (m[0]+0 < 7.0) print $0
    }
  }
}' | head -10

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  建议动作"
echo "═══════════════════════════════════════════════════════"
if awk -v avg="$AVG" 'BEGIN { exit !(avg < 7.0) }'; then
  echo "⚠️ 平均分 $AVG < 7.0，建议："
  echo "  1. 暂停恢复常规 auto-merge 指派，优先推进 P1.1 quality-gate 补丁"
  echo "  2. 召集超管 review 反模式，更新 ~/projects/.github/docs/agent-docs/share/shared-conventions.md"
  echo "  3. 低分 PR 的负责 kimi 下一轮默认 effort 提一档"
else
  echo "✅ 平均分 $AVG ≥ 7.0，质量趋势正常"
fi
