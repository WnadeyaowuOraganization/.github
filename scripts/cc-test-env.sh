#!/bin/bash
# cc-test-env.sh — 编程CC独立测试环境管理
#
# 隔离策略:
#   MySQL: 同实例不同schema — wande-ai-kimi{N} (dev主环境: wande-ai)
#   Redis: 同实例不同DB    — db{N}            (dev主环境: db0)
#   端口:  kimi{N}        — backend:7100+N, frontend:8100+N
#   后端:  mvn spring-boot:run（源码启动，无需编译jar）
#   前端:  pnpm dev（vite dev server，HMR热更新）
#
# 用法:
#   cc-test-env.sh init-db <kimi_tag>  创建独立MySQL schema + Redis DB（run-cc.sh预调用）
#   cc-test-env.sh start  <kimi_tag>   启动后端+前端服务（非阻塞，立即返回）
#   cc-test-env.sh wait   <kimi_tag>   等待后端健康检查通过（默认300s，WAIT_TIMEOUT可调）
#   cc-test-env.sh stop   <kimi_tag>   停止服务 + 删除数据库
#   cc-test-env.sh status <kimi_tag>   检查环境状态
#   cc-test-env.sh port   <kimi_tag>   输出端口分配

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === MySQL/Redis 连接配置 ===
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASS="root"
MYSQL_USER="wande"
MYSQL_PASS="wande_dev_2026"
MYSQL_DEV_DB="wande-ai"
REDIS_HOST="localhost"
REDIS_PORT="6379"
FLYWAY_DIR="${HOME_DIR}/projects/wande-play/backend/ruoyi-admin/src/main/resources/db/migration"

# === 端口+隔离分配 ===
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
}

# === 目录解析 ===
get_dirs() {
  local tag="$1"
  KIMI_DIR="${HOME_DIR}/projects/wande-play-${tag}"
  LOG_DIR="/apps/wande-ai-backend-${tag}/logs"
  PID_FILE="/tmp/cc-test-${tag}-backend.pid"
  FRONT_PID_FILE="/tmp/cc-test-${tag}-frontend.pid"
}

# ============================================================
#  init-db: 创建独立 MySQL schema + Redis DB
#  由 run-cc.sh 在启动CC前调用，秒级完成
# ============================================================
cmd_init_db() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  echo "=== ${tag} 数据库初始化 ==="

  # MySQL: 创建schema + 导入baseline
  echo -n "  MySQL: ${KIMI_DB}..."
  docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
    -e "CREATE DATABASE IF NOT EXISTS \`${KIMI_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null

  local existing_tables
  existing_tables=$(docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" -N \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${KIMI_DB}';" 2>/dev/null)

  if [ "${existing_tables:-0}" -lt 10 ]; then
    echo " 初始化中"
    mkdir -p "$LOG_DIR"
    local flyway_log="$LOG_DIR/init-db-flyway.log"
    : > "$flyway_log"
    # 依版本号顺序应用全部 V*.sql（baseline + 所有后续迁移）
    # kimi 环境后端启动时 --spring.flyway.enabled=false，由本脚本一次性把 schema 拉到最新
    # --force 容忍已知非关键错误（如 create_by='admin' 字符串→bigint、重复列 '广东省' 等）
    local applied=0 failed=0
    for f in $(ls "$FLYWAY_DIR"/V*.sql 2>/dev/null | sort -V); do
      local fname
      fname=$(basename "$f")
      if docker exec -i mysql-dev mysql --force -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" "$KIMI_DB" \
        < "$f" >>"$flyway_log" 2>&1; then
        echo "    ✓ $fname"
        applied=$((applied+1))
      else
        echo "    ✗ $fname (详见 $flyway_log)"
        failed=$((failed+1))
      fi
    done
    echo "  Flyway: 应用 $applied 个脚本 (失败 $failed)，日志: $flyway_log"
  else
    echo " 已存在(${existing_tables}表)，跳过 Flyway"
  fi

  # 授权
  docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
    -e "GRANT ALL PRIVILEGES ON \`${KIMI_DB}\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null

  # Redis: 清空kimi专属DB
  echo "  Redis: db${REDIS_DB} (FLUSHDB)"
  docker exec redis-dev redis-cli -n "$REDIS_DB" FLUSHDB 2>/dev/null >/dev/null

  # 确保日志目录
  mkdir -p "$LOG_DIR"

  # 同步 .env 文件（被 .gitignore 忽略，kimi目录不会自动有）
  local base_env="${HOME_DIR}/projects/wande-play/frontend/apps/web-antd/.env"
  local kimi_env="$KIMI_DIR/frontend/apps/web-antd/.env"
  if [ -f "$base_env" ] && [ -d "$(dirname "$kimi_env")" ]; then
    cp "$base_env" "$kimi_env"
    echo "  .env: 已同步"
  fi

  echo "✅ ${tag} 数据库就绪 (mysql:${KIMI_DB}, redis:db${REDIS_DB})"
}

# ============================================================
#  start: 启动后端(mvn spring-boot:run) + 前端(pnpm dev)
#  不操作数据库，假设 init-db 已执行
# ============================================================
cmd_start() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  if [ ! -d "$KIMI_DIR" ]; then
    echo "ERROR: kimi目录不存在: $KIMI_DIR"
    exit 1
  fi

  mkdir -p "$LOG_DIR"

  # --- 后端 ---
  start_backend "$tag"

  # --- 前端 ---
  start_frontend "$tag"

  echo ""
  echo "✅ ${tag} 测试环境进程已启动（后端编译中，约2-3分钟后就绪）"
  echo "   后端:  http://localhost:${BACKEND_PORT}  (mvn spring-boot:run)"
  echo "   前端:  http://localhost:${FRONTEND_PORT}  (vite dev server)"
  echo "   MySQL: ${KIMI_DB} (port ${MYSQL_PORT})"
  echo "   Redis: db${REDIS_DB} (port ${REDIS_PORT})"
  echo "   日志(后端): $LOG_DIR/backend.log"
  echo "   日志(前端): $LOG_DIR/frontend.log"
  echo ""
  echo "💡 用 '$0 wait $tag' 等待后端健康检查通过"
  return 0
}

# ============================================================
#  wait: 等待后端健康检查通过（可被编程CC用timeout参数调用）
# ============================================================
cmd_wait() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  if [ ! -f "$PID_FILE" ]; then
    echo "ERROR: 后端未启动（PID文件不存在）"
    return 1
  fi

  local pid=$(cat "$PID_FILE")
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "ERROR: 后端进程已退出 (PID=$pid)"
    tail -30 "$LOG_DIR/backend.log"
    rm -f "$PID_FILE"
    return 1
  fi

  echo -n "等待后端就绪 (PID=$pid, port=${BACKEND_PORT})..."
  local max_wait=${WAIT_TIMEOUT:-300}
  for i in $(seq 1 "$max_wait"); do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo " FAIL (进程退出)"
      tail -30 "$LOG_DIR/backend.log"
      rm -f "$PID_FILE"
      return 1
    fi
    if curl -sf "http://localhost:${BACKEND_PORT}/actuator/health" --max-time 2 >/dev/null 2>&1; then
      echo " OK (${i}s)"
      return 0
    fi
    # 备用检查：如果actuator没开，检查端口是否在监听
    if [ "$i" -ge 60 ] && ss -tlnp 2>/dev/null | grep -q ":${BACKEND_PORT} " ; then
      # 端口已监听但actuator不通，再试一次基础HTTP
      if curl -sf "http://localhost:${BACKEND_PORT}/" --max-time 2 >/dev/null 2>&1; then
        echo " OK (${i}s, 端口已监听)"
        return 0
      fi
    fi
    [ $((i % 30)) -eq 0 ] && echo -n " ${i}s"
    sleep 1
  done

  echo " TIMEOUT (${max_wait}s)"
  echo "最后30行日志:"
  tail -30 "$LOG_DIR/backend.log"
  return 1
}

start_backend() {
  local tag="$1"

  # 检查是否已在运行
  if [ -f "$PID_FILE" ]; then
    local old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "  后端已在运行 (PID=$old_pid, port=${BACKEND_PORT})"
      return 0
    fi
    rm -f "$PID_FILE"
  fi

  # 清理端口占用
  local conflict_pid=$(lsof -ti ":${BACKEND_PORT}" 2>/dev/null || true)
  if [ -n "$conflict_pid" ]; then
    echo "⚠️ 端口 ${BACKEND_PORT} 被占用 (PID=$conflict_pid)，停止..."
    kill "$conflict_pid" 2>/dev/null; sleep 2
    kill -9 "$conflict_pid" 2>/dev/null || true
  fi

  echo "  启动后端 mvn spring-boot:run (port=${BACKEND_PORT})..."
  : > "$LOG_DIR/backend.log"

  # 用 mvn spring-boot:run 从源码启动，无需预编译jar
  # 必须在 ruoyi-admin 子目录执行（spring-boot-maven-plugin 只在此模块定义）
  # per-kimi M2 隔离：强制用本 kimi 的 .m2-local 仓库（由 run-cc.sh 首次启动时 rsync seed）
  # 使用 setsid 确保进程独立于父shell，不会因脚本被杀而级联退出
  cd "$KIMI_DIR/backend/ruoyi-admin"
  KIMI_M2="${KIMI_DIR}/.m2-local/repository"
  [ -d "$KIMI_M2" ] && MVN_M2_OPT="-Dmaven.repo.local=${KIMI_M2}" || MVN_M2_OPT=""
  setsid mvn spring-boot:run $MVN_M2_OPT -o -Dspring-boot.run.profiles=dev -Dspring-boot.run.arguments="--server.port=${BACKEND_PORT} --spring.flyway.enabled=false --spring.datasource.dynamic.datasource.master.url=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${KIMI_DB}?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true --spring.datasource.dynamic.datasource.master.username=${MYSQL_USER} --spring.datasource.dynamic.datasource.master.password=${MYSQL_PASS} --spring.data.redis.host=${REDIS_HOST} --spring.data.redis.port=${REDIS_PORT} --spring.data.redis.database=${REDIS_DB}" > "$LOG_DIR/backend.log" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"
  echo "  后端进程已启动 (PID=$pid)，编译+启动约2-3分钟"
  echo "  日志: $LOG_DIR/backend.log"
  return 0
}

start_frontend() {
  local tag="$1"
  local front_src="$KIMI_DIR/frontend"

  if [ ! -d "$front_src/apps/web-antd" ]; then
    echo "  ⚠️ 前端目录不存在，跳过"
    return 0
  fi

  # 检查是否已在运行
  if [ -f "$FRONT_PID_FILE" ]; then
    local old_front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$old_front_pid" 2>/dev/null; then
      echo "  前端已在运行 (PID=$old_front_pid, port=${FRONTEND_PORT})"
      return 0
    fi
    rm -f "$FRONT_PID_FILE"
  fi

  # 清理端口占用
  local conflict_pid=$(lsof -ti ":${FRONTEND_PORT}" 2>/dev/null || true)
  if [ -n "$conflict_pid" ]; then
    kill "$conflict_pid" 2>/dev/null; sleep 1
    kill -9 "$conflict_pid" 2>/dev/null || true
  fi

  echo "  启动前端 vite dev (port=${FRONTEND_PORT}, proxy→${BACKEND_PORT})..."
  : > "$LOG_DIR/frontend.log"

  cd "$front_src"
  # setsid 确保进程独立于父shell
  VITE_PROXY_TARGET="http://127.0.0.1:${BACKEND_PORT}" \
    setsid npx pnpm -C apps/web-antd run dev -- --port "${FRONTEND_PORT}" --host 0.0.0.0 \
    > "$LOG_DIR/frontend.log" 2>&1 &

  local front_pid=$!
  echo "$front_pid" > "$FRONT_PID_FILE"
  echo "  前端进程已启动 (PID=$front_pid)"
  echo "  日志: $LOG_DIR/frontend.log"
  return 0
}

# ============================================================
#  stop: 停止服务 + 删除数据库
# ============================================================
cmd_stop() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  echo "=== 停止 ${tag} ==="

  # 停后端（setsid启动的进程需要杀整个进程组）
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "  停止后端 (PID=$pid)..."
      # 先尝试优雅关闭进程组
      kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null
      for i in $(seq 1 10); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 1
      done
      kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  # 兜底端口清理
  local be_left=$(lsof -ti ":${BACKEND_PORT}" 2>/dev/null || true)
  [ -n "$be_left" ] && kill -9 "$be_left" 2>/dev/null || true

  # 停前端（setsid启动的进程需要杀整个进程组）
  if [ -f "$FRONT_PID_FILE" ]; then
    local front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$front_pid" 2>/dev/null; then
      echo "  停止前端 (PID=$front_pid)..."
      kill -- -"$front_pid" 2>/dev/null || kill "$front_pid" 2>/dev/null
      sleep 2
      kill -9 -- -"$front_pid" 2>/dev/null || kill -9 "$front_pid" 2>/dev/null || true
    fi
    rm -f "$FRONT_PID_FILE"
  fi
  local fe_left=$(lsof -ti ":${FRONTEND_PORT}" 2>/dev/null || true)
  [ -n "$fe_left" ] && kill -9 "$fe_left" 2>/dev/null || true

  # 删除MySQL schema
  echo "  MySQL: DROP ${KIMI_DB}"
  docker exec mysql-dev mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASS" \
    -e "DROP DATABASE IF EXISTS \`${KIMI_DB}\`;" 2>/dev/null

  # 清空Redis DB
  echo "  Redis: FLUSHDB db${REDIS_DB}"
  docker exec redis-dev redis-cli -n "$REDIS_DB" FLUSHDB 2>/dev/null >/dev/null

  echo "✅ ${tag} 已停止（进程+数据库已清理）"
}

# ============================================================
#  status / port
# ============================================================
cmd_status() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  local be_status="stopped" fe_status="stopped"

  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      if curl -sf "http://localhost:${BACKEND_PORT}/actuator/health" --max-time 2 >/dev/null 2>&1; then
        be_status="running(PID=$pid,healthy)"
      else
        be_status="starting(PID=$pid)"
      fi
    fi
  fi

  if [ -f "$FRONT_PID_FILE" ]; then
    local front_pid=$(cat "$FRONT_PID_FILE")
    if kill -0 "$front_pid" 2>/dev/null; then
      fe_status="running(PID=$front_pid)"
    fi
  fi

  if [ "$be_status" = "stopped" ] && [ "$fe_status" = "stopped" ]; then
    echo "STOPPED"
    return 1
  fi

  echo "RUNNING backend(${be_status},port=${BACKEND_PORT}) frontend(${fe_status},port=${FRONTEND_PORT}) mysql:${KIMI_DB} redis:db${REDIS_DB}"
  echo "  日志(后端): $LOG_DIR/backend.log"
  echo "  日志(前端): $LOG_DIR/frontend.log"
  return 0
}

cmd_port() {
  local tag="$1"
  get_ports "$tag" || exit 1
  echo "backend=${BACKEND_PORT} frontend=${FRONTEND_PORT} mysql=${KIMI_DB} redis=db${REDIS_DB}"
}

# === 主入口 ===
ACTION="${1:-status}"
KIMI_TAG="${2:-}"

if [ -z "$KIMI_TAG" ]; then
  echo "用法: $0 <init-db|start|stop|restart|status|port> <kimi_tag>"
  echo "  例: $0 init-db kimi1    # run-cc.sh预调用"
  echo "  例: $0 start kimi1      # 编程CC调用"
  echo "  例: $0 stop kimi1       # 停止+清理数据库"
  exit 1
fi

case "$ACTION" in
  init-db)  cmd_init_db "$KIMI_TAG" ;;
  start)    cmd_start "$KIMI_TAG" ;;
  wait)     cmd_wait "$KIMI_TAG" ;;
  stop)     cmd_stop "$KIMI_TAG" ;;
  restart)  cmd_stop "$KIMI_TAG"; sleep 2; cmd_init_db "$KIMI_TAG"; cmd_start "$KIMI_TAG" ;;
  status)   cmd_status "$KIMI_TAG" ;;
  port)     cmd_port "$KIMI_TAG" ;;
  *)        echo "未知操作: $ACTION"; exit 1 ;;
esac
