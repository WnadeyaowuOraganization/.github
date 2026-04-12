#!/bin/bash
# cc-test-env.sh — 编程CC独立测试环境管理
#
# 为每个kimi目录分配独立端口+独立数据库，管理后端服务生命周期
# 编程CC在完成代码后调用此脚本启动独立测试环境
#
# 隔离策略:
#   MySQL: 同实例不同schema — wande-ai-kimi{N} (dev主环境: wande-ai)
#   Redis: 同实例不同DB    — db{N}            (dev主环境: db0)
#   端口:  kimi{N}        — backend:7100+N, frontend:8100+N
#
# 用法:
#   cc-test-env.sh start <kimi_tag>   启动kimi的独立测试环境
#   cc-test-env.sh stop  <kimi_tag>   停止kimi的独立测试环境
#   cc-test-env.sh status <kimi_tag>  检查环境状态
#   cc-test-env.sh port <kimi_tag>    输出端口分配

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === MySQL/Redis 连接配置 ===
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASS="wande_dev_2026"
MYSQL_USER="wande"
MYSQL_PASS="wande_dev_2026"
MYSQL_DEV_DB="wande-ai"
REDIS_HOST="localhost"
REDIS_PORT="6379"
FLYWAY_DIR="${HOME_DIR}/projects/wande-play/backend/ruoyi-admin/src/main/resources/db/migration"

# === 端口+隔离分配 ===
# kimi{N} -> backend:7100+N, frontend:8100+N, mysql:wande-ai-kimi{N}, redis:db{N}
get_ports() {
  local tag="$1"
  local num=$(echo "$tag" | grep -oE '[0-9]+$')
  if [ -z "$num" ]; then
    echo "ERROR: 无法从 '$tag' 提取kimi编号" >&2
    return 1
  fi
  BACKEND_PORT=$((7100 + num))
  FRONTEND_PORT=$((8100 + num))
  KIMI_NUM="$num"
  KIMI_DB="${MYSQL_DEV_DB}-kimi${num}"
  REDIS_DB="$num"
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
  FRONT_PID_FILE="/tmp/cc-test-${tag}-front.pid"
}

# === 启动前端 vite dev server ===
start_frontend() {
  local tag="$1"
  local be_port="$2"
  local fe_port="$3"

  local front_src="$KIMI_DIR/frontend"
  if [ ! -d "$front_src/apps/web-antd" ]; then
    echo "  ⚠️ 前端目录不存在，跳过前端启动"
    return 0
  fi

  # 检查是否已在运行
  if [ -f "$FRONT_PID_FILE" ]; then
    local old_front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$old_front_pid" 2>/dev/null; then
      echo "  前端已在运行 (PID=$old_front_pid)"
      return 0
    fi
    rm -f "$FRONT_PID_FILE"
  fi

  echo -n "  启动前端 vite dev (port=${fe_port}, proxy→${be_port})..."
  : > "$LOG_DIR/frontend.log"

  # VITE_PROXY_TARGET: vite.config.mts 读取此变量作为 /api proxy target
  # --port: 覆盖 .env 中的 VITE_PORT
  # --host: 允许外部访问
  cd "$front_src"
  VITE_PROXY_TARGET="http://127.0.0.1:${be_port}" \
    nohup npx pnpm -C apps/web-antd run dev -- --port "${fe_port}" --host 0.0.0.0 \
    > "$LOG_DIR/frontend.log" 2>&1 &

  local front_pid=$!
  echo "$front_pid" > "$FRONT_PID_FILE"

  # 等待vite就绪（最多20秒）
  for j in $(seq 1 20); do
    if ! kill -0 "$front_pid" 2>/dev/null; then
      echo " FAIL (进程退出)"
      tail -10 "$LOG_DIR/frontend.log"
      rm -f "$FRONT_PID_FILE"
      return 1
    fi
    if curl -sf "http://localhost:${fe_port}" --max-time 2 >/dev/null 2>&1; then
      echo " OK (${j}s, PID=$front_pid)"
      return 0
    fi
    sleep 1
  done

  echo " WARN (${front_pid}启动中，可能需要更多时间)"
  return 0
}

# === 停止前端 ===
stop_frontend() {
  if [ -f "$FRONT_PID_FILE" ]; then
    local front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$front_pid" 2>/dev/null; then
      echo "  停止前端 (PID=$front_pid)..."
      kill "$front_pid" 2>/dev/null
      sleep 2
      kill -9 "$front_pid" 2>/dev/null || true
    fi
    rm -f "$FRONT_PID_FILE"
  fi

  # 兜底：按前端端口清理
  if [ -n "$FRONTEND_PORT" ]; then
    local fe_leftover=$(lsof -ti ":${FRONTEND_PORT}" 2>/dev/null || true)
    if [ -n "$fe_leftover" ]; then
      kill -9 "$fe_leftover" 2>/dev/null || true
    fi
  fi
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

  # 检查是否已在运行（后端+前端都在才算运行中）
  if [ -f "$PID_FILE" ]; then
    local old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "✅ ${tag} 测试环境已在运行 (backend PID=$old_pid, port=${be_port})"
      return 0
    fi
    rm -f "$PID_FILE"
  fi

  # 停止可能占用端口的旧进程（后端+前端端口）
  for check_port in "$be_port" "$fe_port"; do
    local conflict_pid=$(lsof -ti ":${check_port}" 2>/dev/null || true)
    if [ -n "$conflict_pid" ]; then
      echo "⚠️ 端口 ${check_port} 被占用 (PID=$conflict_pid)，正在停止..."
      kill "$conflict_pid" 2>/dev/null; sleep 2
      kill -9 "$conflict_pid" 2>/dev/null || true
    fi
  done

  # === 创建独立MySQL schema ===
  echo -n "  MySQL: 创建 ${KIMI_DB}..."
  docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
    -e "CREATE DATABASE IF NOT EXISTS \`${KIMI_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null
  # 检查是否已有表（避免重复导入）
  local existing_tables
  existing_tables=$(docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" -N \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${KIMI_DB}';" 2>/dev/null)
  if [ "${existing_tables:-0}" -lt 10 ]; then
    # 导入baseline
    if [ -f "$FLYWAY_DIR/V1__baseline_wande_ai.sql" ]; then
      docker exec -i mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" "$KIMI_DB" 2>/dev/null \
        < "$FLYWAY_DIR/V1__baseline_wande_ai.sql"
      echo " baseline已导入"
    else
      echo " WARN: baseline文件不存在，使用空schema"
    fi
  else
    echo " 已存在(${existing_tables}表)，跳过导入"
  fi

  # === 授权kimi用户访问 ===
  docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
    -e "GRANT ALL PRIVILEGES ON \`${KIMI_DB}\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null

  # === Redis DB隔离：清空kimi专属DB ===
  echo "  Redis: 使用 db${REDIS_DB}"
  docker exec redis-dev redis-cli -n "$REDIS_DB" FLUSHDB 2>/dev/null >/dev/null

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

  # 启动后端（指向kimi独立的MySQL schema + Redis DB）
  : > "$LOG_DIR/backend.log"
  nohup java -jar "$jar_file" \
    --spring.profiles.active=dev \
    --server.port="${be_port}" \
    --spring.flyway.enabled=false \
    --spring.datasource.dynamic.datasource.master.url="jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${KIMI_DB}?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true" \
    --spring.datasource.dynamic.datasource.master.username="${MYSQL_USER}" \
    --spring.datasource.dynamic.datasource.master.password="${MYSQL_PASS}" \
    --spring.data.redis.host="${REDIS_HOST}" \
    --spring.data.redis.port="${REDIS_PORT}" \
    --spring.data.redis.database="${REDIS_DB}" \
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

      # === 启动前端 vite dev server ===
      start_frontend "$tag" "$be_port" "$fe_port"

      echo "✅ ${tag} 测试环境就绪"
      echo "   后端:  http://localhost:${be_port}"
      echo "   前端:  http://localhost:${fe_port}"
      echo "   MySQL: ${KIMI_DB} (port ${MYSQL_PORT})"
      echo "   Redis: db${REDIS_DB} (port ${REDIS_PORT})"
      echo "   日志(后端): $LOG_DIR/backend.log"
      echo "   日志(前端): $LOG_DIR/frontend.log"
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

  # 兜底：按后端端口清理
  local leftover=$(lsof -ti ":${be_port}" 2>/dev/null || true)
  if [ -n "$leftover" ]; then
    kill -9 "$leftover" 2>/dev/null || true
  fi

  # 停止前端
  stop_frontend

  # 清理独立MySQL schema
  if [ -n "$KIMI_DB" ]; then
    echo "  MySQL: 删除 ${KIMI_DB}..."
    docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
      -e "DROP DATABASE IF EXISTS \`${KIMI_DB}\`;" 2>/dev/null
  fi

  # 清理Redis DB
  if [ -n "$REDIS_DB" ] && [ "$REDIS_DB" -gt 0 ] 2>/dev/null; then
    echo "  Redis: 清空 db${REDIS_DB}"
    docker exec redis-dev redis-cli -n "$REDIS_DB" FLUSHDB 2>/dev/null >/dev/null
  fi

  echo "✅ ${tag} 测试环境已停止（含数据清理）"
}

# === 查看状态 ===
cmd_status() {
  local tag="$1"
  get_dirs "$tag"
  local ports
  ports=$(get_ports "$tag") || exit 1
  local be_port=$(echo "$ports" | awk '{print $1}')

  local fe_status="stopped"
  if [ -f "$FRONT_PID_FILE" ]; then
    local front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$front_pid" 2>/dev/null; then
      fe_status="running(PID=$front_pid)"
    fi
  fi

  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      if curl -sf "http://localhost:${be_port}/actuator/health" --max-time 2 >/dev/null 2>&1; then
        echo "RUNNING backend(PID=$pid,port=${be_port},healthy) frontend(${fe_status},port=${fe_port}) mysql:${KIMI_DB} redis:db${REDIS_DB}"
        echo "  日志(后端): $LOG_DIR/backend.log"
        echo "  日志(前端): $LOG_DIR/frontend.log"
      else
        echo "STARTING backend(PID=$pid,port=${be_port}) frontend(${fe_status},port=${fe_port}) mysql:${KIMI_DB} redis:db${REDIS_DB}"
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
  echo "backend=${be_port} frontend=${fe_port} mysql=${KIMI_DB} redis=db${REDIS_DB}"
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
