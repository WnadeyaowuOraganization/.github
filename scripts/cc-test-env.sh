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
#   cc-test-env.sh init-db <kimi_tag>           创建独立MySQL schema + Redis DB（run-cc.sh预调用）
#   cc-test-env.sh start          <kimi_tag>    启动后端+前端（非阻塞）
#   cc-test-env.sh start-backend  <kimi_tag>    只启动后端（后端代码改动场景）
#   cc-test-env.sh start-frontend <kimi_tag>    只启动前端（前端代码改动场景）
#   cc-test-env.sh wait           <kimi_tag>    等待后端+前端就绪，并预生成 kimi auth state（playwright storageState，6h复用）
#   cc-test-env.sh stop           <kimi_tag>    停止服务 + 删除数据库
#   cc-test-env.sh stop-backend   <kimi_tag>    只停后端进程（不删库）
#   cc-test-env.sh stop-frontend  <kimi_tag>    只停前端进程（不删库）
#   cc-test-env.sh restart-backend  <kimi_tag>  只重启后端（后端改代码高频场景，不删库）
#   cc-test-env.sh restart-frontend <kimi_tag>  只重启前端（前端改代码高频场景，不删库）
#   cc-test-env.sh status <kimi_tag>            检查环境状态
#   cc-test-env.sh port   <kimi_tag>            输出端口分配
#
# 💡 调优指南：
#   - 只改了后端代码 → restart-backend（保前端 HMR，省 Maven 重新解析）
#   - 只改了前端代码 → 通常无需重启（vite HMR 自动热更新）；彻底重启用 restart-frontend
#   - 改了 Flyway V*.sql → 必须走 restart（删库 + init-db + start），或手动 init-db + restart-backend
#   - 初次启动或换分支后 → start（一把拉起）

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

  # ── 生成 kimi 专属 Spring Boot 配置（防止 CC 直接跑 mvn 时连到主库）──────────
  # Spring Boot 优先级：./config/application-dev.yml > classpath:/application-dev.yml
  # 工作目录 = backend/ruoyi-admin，故此文件自动覆盖 classpath 配置，无需命令行参数
  local spring_config_dir="${KIMI_DIR}/backend/ruoyi-admin/config"
  mkdir -p "$spring_config_dir"
  cat > "${spring_config_dir}/application-dev.yml" << SPRINGCFG
# 自动生成 by cc-test-env.sh init-db — 禁止手动修改，重跑 init-db 会覆盖
# 作用：确保 mvn spring-boot:run 直接运行时也连接 kimi 独立库，而非主库
spring:
  datasource:
    dynamic:
      datasource:
        master:
          url: jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${KIMI_DB}?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true
          username: ${MYSQL_USER}
          password: ${MYSQL_PASS}
  data:
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
      database: ${REDIS_DB}
server:
  port: ${BACKEND_PORT}
SPRINGCFG
  echo "  spring config: ${spring_config_dir}/application-dev.yml (kimi专属，自动覆盖classpath)"
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
  echo "   后端:  http://localhost:${BACKEND_PORT}"
  echo "   前端:  http://localhost:${FRONTEND_PORT}"
  echo "   日志(后端): $LOG_DIR/backend.log"
  echo "   日志(前端): $LOG_DIR/frontend.log"
  return 0
}

# ============================================================
#  wait: 等待后端+前端就绪，并预生成 kimi auth state
#   1. 轮询后端 /actuator/health（默认300s，WAIT_TIMEOUT可调）
#   2. 轮询前端 HTTP /（默认120s，FE_WAIT_TIMEOUT可调）
#   3. 若 auth state 超过6h，运行 auth.setup.ts 预热 storageState
#  完成后 CC 可直接 npx playwright test 跑图形化测试
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

  # ── 1. 等待后端就绪 ──────────────────────────────────────────────────────────
  echo -n "等待后端就绪 (PID=$pid, port=${BACKEND_PORT})..."
  local max_wait=${WAIT_TIMEOUT:-300}
  for i in $(seq 1 "$max_wait"); do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo " FAIL (进程退出)"
      tail -30 "$LOG_DIR/backend.log"
      rm -f "$PID_FILE"
      return 1
    fi
    # 401=Spring Security 已启动需认证，视为 UP；只有 000（连接拒绝）才视为未就绪
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${BACKEND_PORT}/actuator/health" --max-time 2 2>/dev/null)
    if [ "$http_code" != "000" ] && [ -n "$http_code" ]; then
      echo " OK (${i}s, HTTP=${http_code})"
      break
    fi
    # 备用检查：端口已监听
    if [ "$i" -ge 60 ] && ss -tlnp 2>/dev/null | grep -q ":${BACKEND_PORT} " ; then
      echo " OK (${i}s, 端口已监听)"
      break
    fi
    [ $((i % 30)) -eq 0 ] && echo -n " ${i}s"
    sleep 1
    if [ "$i" -eq "$max_wait" ]; then
      echo " TIMEOUT (${max_wait}s)"
      echo "最后30行日志:"
      tail -30 "$LOG_DIR/backend.log"
      return 1
    fi
  done

  # ── 2. 等待前端就绪（Vite dev server） ───────────────────────────────────────
  echo -n "等待前端就绪 (port=${FRONTEND_PORT})..."
  local fe_wait=${FE_WAIT_TIMEOUT:-120}
  for i in $(seq 1 "$fe_wait"); do
    local fe_code
    fe_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${FRONTEND_PORT}/" --max-time 2 2>/dev/null)
    if [ "$fe_code" != "000" ] && [ -n "$fe_code" ]; then
      echo " OK (${i}s, HTTP=${fe_code})"
      break
    fi
    [ $((i % 30)) -eq 0 ] && echo -n " ${i}s"
    sleep 1
    if [ "$i" -eq "$fe_wait" ]; then
      echo " TIMEOUT (${fe_wait}s) — 前端可能尚未 start，跳过 auth 预热"
      return 0
    fi
  done

  # ── 3. 预生成 kimi auth state（给 playwright storageState 使用） ────────────
  local auth_file="/tmp/e2e-auth-state-${tag}.json"
  local auth_age=99999
  if [ -f "$auth_file" ]; then
    auth_age=$(( ($(date +%s) - $(stat -c %Y "$auth_file" 2>/dev/null || echo 0)) / 3600 ))
  fi
  if [ "$auth_age" -ge 6 ]; then
    echo "🔑 生成 ${tag} auth state → ${auth_file}"
    local e2e_dir="${KIMI_DIR}/e2e"
    if [ -d "$e2e_dir" ]; then
      (cd "$e2e_dir" && \
        E2E_ENV="${tag}" \
        CC_TEST_FRONTEND_URL="http://localhost:${FRONTEND_PORT}" \
        BASE_URL_FRONT="http://localhost:${FRONTEND_PORT}" \
        E2E_AUTH_STATE="${auth_file}" \
        npx playwright test tests/setup/auth.setup.ts --project=setup 2>/dev/null \
        && echo "✓ auth state 已生成: ${auth_file}" \
        || echo "⚠ auth.setup.ts 运行失败，CC 首次跑 playwright 时再手动登录"
      )
    else
      echo "⚠ e2e 目录不存在 (${e2e_dir})，跳过 auth 预热"
    fi
  else
    echo "✓ auth state 有效 (age=${auth_age}h)，跳过预热"
  fi

  return 0
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

  echo "  启动后端 (port=${BACKEND_PORT})..."
  : > "$LOG_DIR/backend.log"

  # 用 mvn spring-boot:run 从源码启动，无需预编译jar
  # 必须在 ruoyi-admin 子目录执行（spring-boot-maven-plugin 只在此模块定义）
  # per-kimi M2 隔离：放在项目外 ${HOME}/cc_scheduler/m2/<kimi>/repository（由 run-cc.sh 首次启动 rsync seed）
  # 2026-04-14: 取消 -o offline 模式。per-kimi M2 互相隔离，install 仅写自己库，不再有并发写锁和跨 CC 污染风险；
  # 允许 Maven 在 seed 残缺时（如 BOM 缺失）自动补齐，规避「M2 seed 残缺 + offline」双重故障（今天 kimi4 case）
  # 使用 setsid 确保进程独立于父shell，不会因脚本被杀而级联退出
  cd "$KIMI_DIR/backend/ruoyi-admin"
  KIMI_M2="${HOME:-/home/ubuntu}/cc_scheduler/m2/${tag}/repository"
  [ -d "$KIMI_M2" ] && MVN_M2_OPT="-Dmaven.repo.local=${KIMI_M2}" || MVN_M2_OPT=""

  # 自愈：若 per-kimi M2 缺 ruoyi-common-bom（seed rsync 排除了 org/ruoyi/），
  # 先把源码业务模块装进去，规避 kimi4 类型的「Non-resolvable import POM」启动失败。
  # 原因：BOM 是源码 sibling module（backend/ruoyi-common/ruoyi-common-bom），远程镜像没有；
  # spring-boot:run 单模块启动不会触发 reactor 构建，缺 BOM 就直接挂。
  if [ -n "$MVN_M2_OPT" ] && [ ! -d "${KIMI_M2}/org/ruoyi/ruoyi-common-bom" ]; then
    echo "  🔧 per-kimi M2 缺 ruoyi-common-bom，先装业务模块（约 30s）..."
    # 清理可能的失败缓存
    rm -rf "${KIMI_M2}/org/ruoyi/ruoyi-common-bom" 2>/dev/null
    (cd "$KIMI_DIR/backend" && mvn install -pl ruoyi-common -am -DskipTests $MVN_M2_OPT -q 2>&1 | tail -5) \
      || { echo "  ❌ ruoyi-common 预装失败，后端启动大概率也会失败"; }
  fi

  # 自愈：若 per-kimi M2 缺 wande-ai（根 POM 非远程 artifact，.lastUpdated 残留导致 Maven 拒绝使用本地缓存）
  # 现象：Could not find artifact org.ruoyi:wande-ai:jar:3.0.0（kimi20 2026-04-19 事故）
  # 修复：从主 M2 复制（主 M2 由 run-cc.sh seed rsync 保证存在）
  if [ -n "$MVN_M2_OPT" ]; then
    local wande_ai_jar="${KIMI_M2}/org/ruoyi/wande-ai/3.0.0/wande-ai-3.0.0.jar"
    if [ ! -f "$wande_ai_jar" ]; then
      echo "  🔧 per-kimi M2 缺 wande-ai，从主 M2 复制..."
      mkdir -p "$(dirname "$wande_ai_jar")"
      # 清除 lastUpdated 残留
      rm -f "$(dirname "$wande_ai_jar")"/*.lastUpdated 2>/dev/null
      cp ~/.m2/repository/org/ruoyi/wande-ai/3.0.0/* "$(dirname "$wande_ai_jar")/" 2>/dev/null \
        || echo "  ⚠ 主 M2 也缺 wande-ai，后端启动可能失败"
    fi
  fi

  setsid mvn spring-boot:run $MVN_M2_OPT -Dspring-boot.run.profiles=dev -Dspring-boot.run.arguments="--server.port=${BACKEND_PORT} --spring.flyway.enabled=false --spring.datasource.dynamic.datasource.master.url=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${KIMI_DB}?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8&autoReconnect=true&rewriteBatchedStatements=true&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true --spring.datasource.dynamic.datasource.master.username=${MYSQL_USER} --spring.datasource.dynamic.datasource.master.password=${MYSQL_PASS} --spring.data.redis.host=${REDIS_HOST} --spring.data.redis.port=${REDIS_PORT} --spring.data.redis.database=${REDIS_DB}" > "$LOG_DIR/backend.log" 2>&1 &

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

  # 清理端口占用 — 用 fuser 能看到 root 进程（含 nginx）；lsof 仅能看自己的
  local port_holder=$(sudo -n fuser "${FRONTEND_PORT}/tcp" 2>/dev/null | awk '{print $1}' || true)
  if [ -n "$port_holder" ]; then
    # 如果是 nginx 根据之前事故不应 kill，而是报错提示 rm /etc/nginx/sites-enabled/wande-kimiN
    local holder_cmd=$(ps -p "$port_holder" -o comm= 2>/dev/null || echo unknown)
    if [ "$holder_cmd" = "nginx" ]; then
      echo "⚠️  端口 ${FRONTEND_PORT} 被 nginx 占用（残留的 /etc/nginx/sites-enabled/wande-kimi<N>）"
      echo "    请执行：sudo rm /etc/nginx/sites-enabled/wande-kimi${KIMI_NUM} && sudo nginx -s reload"
      return 1
    fi
    kill "$port_holder" 2>/dev/null; sleep 1
    kill -9 "$port_holder" 2>/dev/null || true
  fi

  echo "  启动前端 (port=${FRONTEND_PORT})..."
  : > "$LOG_DIR/frontend.log"

  cd "$front_src"

  # 同步前端依赖（dev分支新增包时kimi node_modules可能落后）
  # --frozen-lockfile 保证与 pnpm-lock.yaml 一致，不升级版本，通常 < 10s（包已在 pnpm store）
  echo "  📦 pnpm install --frozen-lockfile (同步前端依赖)..."
  pnpm install --frozen-lockfile --prefer-offline >> "$LOG_DIR/frontend.log" 2>&1 \
    || echo "  ⚠️ pnpm install 失败，尝试继续启动（依赖可能不完整）"

  # setsid 确保进程独立于父shell
  # 修复：直接调 vite 二进制传 --port，避免 `pnpm run dev -- --port` 双 -- 吞参数导致 vite fallback 到 5666
  VITE_PROXY_TARGET="http://127.0.0.1:${BACKEND_PORT}" \
    setsid npx pnpm -C apps/web-antd exec vite --mode development --port "${FRONTEND_PORT}" --host 0.0.0.0 \
    > "$LOG_DIR/frontend.log" 2>&1 &

  local front_pid=$!
  echo "$front_pid" > "$FRONT_PID_FILE"
  echo "  前端进程已启动 (PID=$front_pid)"
  echo "  日志: $LOG_DIR/frontend.log"
  return 0
}

# ============================================================
#  stop_backend / stop_frontend: 只停进程，不碰数据库（供 restart-* 复用）
# ============================================================
stop_backend() {
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "  停止后端 (PID=$pid)..."
      kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null
      for i in $(seq 1 10); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 1
      done
      kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
  local be_left=$(lsof -ti ":${BACKEND_PORT}" 2>/dev/null || true)
  [ -n "$be_left" ] && kill -9 "$be_left" 2>/dev/null || true
}

stop_frontend() {
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
}

cmd_start_backend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  [ ! -d "$KIMI_DIR" ] && { echo "ERROR: kimi目录不存在: $KIMI_DIR"; exit 1; }
  mkdir -p "$LOG_DIR"
  start_backend "$tag"
  echo ""
  echo "✅ ${tag} 后端已启动 → http://localhost:${BACKEND_PORT} (日志: $LOG_DIR/backend.log)"
}

cmd_start_frontend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  [ ! -d "$KIMI_DIR" ] && { echo "ERROR: kimi目录不存在: $KIMI_DIR"; exit 1; }
  mkdir -p "$LOG_DIR"
  start_frontend "$tag"
  echo ""
  echo "✅ ${tag} 前端已启动 → http://localhost:${FRONTEND_PORT} (日志: $LOG_DIR/frontend.log)"
}

cmd_stop_backend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  echo "=== 停止 ${tag} 后端 ==="
  stop_backend
  echo "✅ 后端已停止（数据库保留）"
}

cmd_stop_frontend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  echo "=== 停止 ${tag} 前端 ==="
  stop_frontend
  echo "✅ 前端已停止"
}

cmd_restart_backend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  echo "=== 重启 ${tag} 后端（保留前端 + 数据库）==="
  stop_backend
  sleep 1
  mkdir -p "$LOG_DIR"
  start_backend "$tag"
  echo "✅ 后端重启进程已拉起 → http://localhost:${BACKEND_PORT}（编译+启动约 2-3 分钟）"
}

cmd_restart_frontend() {
  local tag="$1"
  get_dirs "$tag"; get_ports "$tag" || exit 1
  echo "=== 重启 ${tag} 前端（保留后端 + 数据库）==="
  stop_frontend
  sleep 1
  mkdir -p "$LOG_DIR"
  start_frontend "$tag"
  echo "✅ 前端已重启 → http://localhost:${FRONTEND_PORT}"
}

# ============================================================
#  stop: 停止服务 + 删除数据库
# ============================================================
cmd_stop() {
  local tag="$1"
  get_dirs "$tag"
  get_ports "$tag" || exit 1

  echo "=== 停止 ${tag} ==="

  stop_backend
  stop_frontend

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
      local _hc
      _hc=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${BACKEND_PORT}/actuator/health" --max-time 2 2>/dev/null)
      if [ "$_hc" != "000" ] && [ -n "$_hc" ]; then
        be_status="running(PID=$pid,HTTP=${_hc})"
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
  echo "用法: $0 <action> <kimi_tag>"
  echo "  action:"
  echo "    init-db | start | stop | restart | status | port | wait"
  echo "    start-backend  | start-frontend"
  echo "    stop-backend   | stop-frontend"
  echo "    restart-backend  (后端改代码高频，保前端+DB)"
  echo "    restart-frontend (前端彻底重启，保后端+DB)"
  exit 1
fi

case "$ACTION" in
  init-db)           cmd_init_db "$KIMI_TAG" ;;
  start)             cmd_start "$KIMI_TAG" ;;
  start-backend)     cmd_start_backend "$KIMI_TAG" ;;
  start-frontend)    cmd_start_frontend "$KIMI_TAG" ;;
  wait)              cmd_wait "$KIMI_TAG" ;;
  stop)              cmd_stop "$KIMI_TAG" ;;
  stop-backend)      cmd_stop_backend "$KIMI_TAG" ;;
  stop-frontend)     cmd_stop_frontend "$KIMI_TAG" ;;
  restart)           cmd_stop "$KIMI_TAG"; sleep 2; cmd_init_db "$KIMI_TAG"; cmd_start "$KIMI_TAG" ;;
  restart-backend)   cmd_restart_backend "$KIMI_TAG" ;;
  restart-frontend)  cmd_restart_frontend "$KIMI_TAG" ;;
  status)            cmd_status "$KIMI_TAG" ;;
  port)              cmd_port "$KIMI_TAG" ;;
  *)                 echo "未知操作: $ACTION"; exit 1 ;;
esac
