#!/bin/bash
# restart-vllm.sh — vLLM 服务重启脚本
# 用法：sudo bash restart-vllm.sh
# 或：sst restart-vllm （如果已配置 sudo 无密码）

set -e

echo "=== vLLM 服务重启程序 ==="
echo "时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
  echo "❌ 错误：此脚本需要 root 权限"
  echo "请使用：sudo bash $0"
  exit 1
fi

# 获取现有的 vLLM 进程信息
VLLM_PID=$(pgrep -f "vllm serve" | head -1)
if [ -z "$VLLM_PID" ]; then
  echo "⚠️  vLLM 进程未找到，已启动过吗？"
  exit 0
fi

echo "✓ 发现 vLLM 主进程：PID $VLLM_PID"

# 获取启动参数
VLLM_CMD=$(ps -p $VLLM_PID -o args= | sed 's/^.*vllm //')
echo "✓ 当前启动参数："
echo "  $VLLM_CMD"
echo ""

# 停止 vLLM 进程
echo "=== 第1步：停止 vLLM 进程 ==="
echo "正在发送 SIGTERM 信号到 PID $VLLM_PID..."
kill -TERM $VLLM_PID

# 等待优雅退出
for i in {1..30}; do
  if ! ps -p $VLLM_PID > /dev/null 2>&1; then
    echo "✓ vLLM 主进程已优雅退出（尝试 $i/30）"
    break
  fi
  sleep 1
  if [ $i -eq 30 ]; then
    echo "⚠️  强制终止 vLLM 进程..."
    kill -9 $VLLM_PID
    sleep 2
  fi
done

# 清理 GPU 内存
echo ""
echo "=== 第2步：清理 GPU 资源 ==="
sleep 3
pgrep -f "VLLM::" | xargs -r kill -9 2>/dev/null || true
sleep 2
echo "✓ GPU 工作进程已清理"

# 验证符号链接
echo ""
echo "=== 第3步：验证模型目录 ==="
if [ -L /model ]; then
  TARGET=$(readlink /model)
  echo "✓ /model 符号链接已设置：$TARGET"
elif [ -d /model ]; then
  if [ -z "$(ls -A /model)" ]; then
    echo "⚠️  /model 目录为空，未创建符号链接"
  fi
else
  echo "❌ /model 目录不存在"
  exit 1
fi

# 重新启动 vLLM
echo ""
echo "=== 第4步：重新启动 vLLM ==="
echo "执行：/usr/bin/python3 /usr/local/bin/vllm serve $VLLM_CMD"
echo ""

nohup /usr/bin/python3 /usr/local/bin/vllm serve $VLLM_CMD > /tmp/vllm-restart.log 2>&1 &
NEW_PID=$!

echo "✓ vLLM 已在后台启动：PID $NEW_PID"
echo "✓ 日志文件：/tmp/vllm-restart.log"

# 等待服务启动
echo ""
echo "=== 第5步：等待服务就绪 ==="
for i in {1..60}; do
  if curl -s http://localhost:8000/v1/models > /dev/null 2>&1; then
    echo "✓ vLLM 服务已响应（尝试 $i/60）"

    # 获取模型信息
    MODEL_ID=$(curl -s http://localhost:8000/v1/models | jq -r '.data[0].id')
    echo "✓ 加载的模型：$MODEL_ID"
    break
  fi
  sleep 1
  if [ $i -eq 60 ]; then
    echo "❌ vLLM 服务启动超时"
    exit 1
  fi
done

echo ""
echo "=== 重启完成 ✓ ==="
echo "时间：$(date '+%Y-%m-%d %H:%M:%S')"
