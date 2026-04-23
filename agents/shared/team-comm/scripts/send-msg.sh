#!/bin/bash
# send-msg.sh — 团队沟通标准发送脚本
# 封装 tmux send-keys + curl notify 双通道，强制消息格式
#
# 用法:
#   bash .claude/skills/team-comm/scripts/send-msg.sh \
#     --to "manager-研发经理" \
#     --type "进度播报" \
#     --reply "阅即可" \
#     --msg "[#1234] 后端编译通过"

TO=""
TYPE=""
REPLY=""
MSG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --to)    TO="$2"; shift 2 ;;
    --type)  TYPE="$2"; shift 2 ;;
    --reply) REPLY="$2"; shift 2 ;;
    --msg)   MSG="$2"; shift 2 ;;
    *)       echo "❌ 未知参数: $1"; exit 1 ;;
  esac
done

# 参数校验
if [ -z "$TO" ] || [ -z "$TYPE" ] || [ -z "$REPLY" ] || [ -z "$MSG" ]; then
  echo "❌ 缺少必要参数"
  echo "用法: send-msg.sh --to <会话> --type <类型> --reply <需回复|阅即可> --msg <内容>"
  echo ""
  echo "  --to     目标tmux会话名 (manager-研发经理 / manager-排程经理 / cc-wande-play-kimiN-ISSUE)"
  echo "  --type   进度播报 / 方案评审 / 异常发现 / 需人工介入"
  echo "  --reply  需回复 / 阅即可"
  echo "  --msg    消息内容"
  exit 1
fi

# 类型校验
case "$TYPE" in
  进度播报)   NOTIFY_TYPE="success" ;;
  方案评审)   NOTIFY_TYPE="info" ;;
  异常发现)   NOTIFY_TYPE="warning" ;;
  需人工介入) NOTIFY_TYPE="error" ;;
  *)
    echo "❌ 无效类型: $TYPE"
    echo "   有效类型: 进度播报 / 方案评审 / 异常发现 / 需人工介入"
    exit 1
    ;;
esac

# 回复标识校验
case "$REPLY" in
  需回复|阅即可) ;;
  *)
    echo "❌ 无效回复标识: $REPLY"
    echo "   有效标识: 需回复 / 阅即可"
    exit 1
    ;;
esac

# 组装完整消息
FULL_MSG="【${TYPE}】-【${REPLY}】 ${MSG}"

# 通道1: tmux send-keys
if tmux has-session -t "$TO" 2>/dev/null; then
  tmux send-keys -t "$TO" "[CC-REPORT] $FULL_MSG" Enter
  echo "✅ tmux → $TO"
else
  echo "⚠️  tmux会话 $TO 不存在，跳过tmux通道"
fi

# 通道2: notify API
NOTIFY_RESP=$(curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"$TO\",\"message\":\"$FULL_MSG\",\"type\":\"$NOTIFY_TYPE\"}" 2>/dev/null)

if echo "$NOTIFY_RESP" | grep -q '"ok"'; then
  echo "✅ notify → $TO"
else
  echo "⚠️  notify发送失败: $NOTIFY_RESP"
fi

echo "📨 $FULL_MSG"
