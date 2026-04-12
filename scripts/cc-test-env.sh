#!/bin/bash
# cc-test-env.sh — 编程CC独立测试环境管理
#
# 为每个kimi目录分配独立端口，管理后端服务生命周期
# 编程CC在完成代码后调用此脚本启动独立测试环境
#
# 用法:
#   cc-test-env.sh start <kimi_tag>   启动kimi的独立测试环境
#   cc-test-env.sh stop  <kimi_tag>   停止kimi的独立测试环境
#   cc-test-env.sh status <kimi_tag>  检查环境状态
#   cc-test-env.sh port <kimi_tag>    输出端口分配

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 端口分配 ===
# kimi{N} -> backend:7100+N, frontend:8100+N
get_ports() {
  local tag="$1"
  local num=$(echo "$tag" | grep -oE '[0-9]+$')
  if [ -z "$num" ]; then
    echo "ERROR: 无法从 '$tag' 提取kimi编号" >&2
    return 1
  fi
  BACKEND_PORT=$((7100 + num))
  FRONTEND_PORT=$((8100 + num))
  echo "$BACKEND_PORT $FRONTEND_PORT"
}

# === 目录解析 ===
get_dirs() {
  local tag="$1"
  KIMI_DIR="${HOME_DIR}/projects/wande-play-${tag}"
  PRODUCT_DIR="/apps/wande-ai-backend-${tag}"
  FRONT_DIR="/apps/wande-ai-front-${tag}"
  LOG_DIR="${PRODUCT_DIR}/logs"
  PID_FILE="/tmp/cc-test-${tag}.pid"
}

# === 启动测试环境 ===
cmd_start() {
  local tag="$1"
  get_dirs "$tag"
  local ports
  ports=$(get_ports "$tag") || exit 1
  local be_port=$(echo "$ports" | awk '{print $1}')
  local fe_port=$(echo "$ports" | awk '{print $2}')

  # 检查kimi目录
  if [ ! -d "$KIMI_DIR" ]; then
    echo "ERROR: kimi目录不存在: $KIMI_DIR"
    exit 1
  fi

  # 检查是否已在运行
  if [ -f "$PID_FILE" ]; then
    local old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "✅ ${tag} 测试环境已在运行 (PID=$old_pid, backend:${be_port})"
      return 0
    fi
    rm -f "$PID_FILE"
  fi

  # 停止可能占用端口的旧进程
  local conflict_pid=$(lsof -ti ":${be_port}" 2>/dev/null || true)
  if [ -n "$conflict_pid" ]; then
    echo "⚠️ 端口 ${be_port} 被占用 (PID=$conflict_pid)，正在停止..."
    kill "$conflict_pid" 2>/dev/null; sleep 2
    kill -9 "$conflict_pid" 2>/dev/null || true
  fi

  # 确保产物目录存在
  mkdir -p "$PRODUCT_DIR" "$LOG_DIR"

  # 检查jar文件
  local jar_file="$PRODUCT_DIR/ruoyi-admin.jar"
  if [ ! -f "$jar_file" ]; then
    echo "INFO: ${tag} 无独立jar，从dev复制..."
    if [ -f /apps/wande-ai-backend/ruoyi-admin.jar ]; then
      cp -f /apps/wande-ai-backend/ruoyi-admin.jar "$jar_file"
    else
      echo "ERROR: dev环境jar不存在，需要先编译"
      return 1
    fi
  fi

  # 启动后端
  : > "$LOG_DIR/backend.log"
  nohup java -jar "$jar_file" \
    --spring.profiles.active=dev \
    --server.port="${be_port}" \
    --spring.datasource.dynamic.datasource.master.url="jdbc:mysql://127.0.0.1:3306/wande-ai?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true" \
    --spring.datasource.dynamic.datasource.master.username=wande \
    --spring.datasource.dynamic.datasource.master.password=wande_dev_2026 \
    --spring.data.redis.host=localhost \
    --spring.data.redis.port=6380 \
    --spring.data.redis.password=redis_dev_2026 \
    > "$LOG_DIR/backend.log" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"

  # 健康检查 (最多60秒)
  echo -n "启动 ${tag} 后端 (PID=$pid, port=${be_port})..."
  for i in $(seq 1 60); do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo " FAIL (进程退出)"
      tail -20 "$LOG_DIR/backend.log"
      rm -f "$PID_FILE"
      return 1
    fi
    if curl -sf "http://localhost:${be_port}/actuator/health" --max-time 2 >/dev/null 2>&1; then
      echo " OK (${i}s)"
      echo "✅ ${tag} 测试环境就绪"
      echo "   后端: http://localhost:${be_port}"
      echo "   前端: http://localhost:${fe_port}"
      echo "   PID: $pid"
      echo "   日志: $LOG_DIR/backend.log"
      return 0
    fi
    [ $((i % 10)) -eq 0 ] && echo -n " ${i}s"
    sleep 1
  done

  echo " TIMEOUT"
  echo "ERROR: 后端60秒内未就绪"
  tail -30 "$LOG_DIR/backend.log"
  kill "$pid" 2>/dev/null
  rm -f "$PID_FILE"
  return 1
}

# === 停止测试环境 ===
cmd_stop() {
  local tag="$1"
  get_dirs "$tag"
  local ports
  ports=$(get_ports "$tag") || exit 1
  local be_port=$(echo "$ports" | awk '{print $1}')

  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "停止 ${tag} 后端 (PID=$pid)..."
      kill "$pid" 2>/dev/null
      for i in $(seq 1 10); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 1
      done
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi

  # 兜底：按端口清理
  local leftover=$(lsof -ti ":${be_port}" 2>/dev/null || true)
  if [ -n "$leftover" ]; then
    kill -9 "$leftover" 2>/dev/null || true
  fi

  echo "✅ ${tag} 测试环境已停止"
}

# === 查看状态 ===
cmd_status() {
  local tag="$1"
  get_dirs "$tag"
  local ports
  ports=$(get_ports "$tag") || exit 1
  local be_port=$(echo "$ports" | awk '{print $1}')

  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      if curl -sf "http://localhost:${be_port}/actuator/health" --max-time 2 >/dev/null 2>&1; then
        echo "RUNNING (PID=$pid, port=${be_port}, healthy)"
      else
        echo "STARTING (PID=$pid, port=${be_port}, not yet healthy)"
      fi
      return 0
    fi
  fi
  echo "STOPPED"
  return 1
}

# === 输出端口 ===
cmd_port() {
  local tag="$1"
  local ports
  ports=$(get_ports "$tag") || exit 1
  local be_port=$(echo "$ports" | awk '{print $1}')
  local fe_port=$(echo "$ports" | awk '{print $2}')
  echo "backend=${be_port} frontend=${fe_port}"
}

# === 主入口 ===
ACTION="${1:-status}"
KIMI_TAG="${2:-}"

if [ -z "$KIMI_TAG" ]; then
  echo "用法: $0 <start|stop|restart|status|port> <kimi_tag>"
  echo "  例: $0 start kimi18"
  exit 1
fi

case "$ACTION" in
  start)   cmd_start "$KIMI_TAG" ;;
  stop)    cmd_stop "$KIMI_TAG" ;;
  restart) cmd_stop "$KIMI_TAG"; sleep 2; cmd_start "$KIMI_TAG" ;;
  status)  cmd_status "$KIMI_TAG" ;;
  port)    cmd_port "$KIMI_TAG" ;;
  *)       echo "未知操作: $ACTION"; exit 1 ;;
esac
