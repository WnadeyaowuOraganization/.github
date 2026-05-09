#!/bin/bash
# E2E 测试环境启动脚本
# Jenkins CI E2E 阶段调用（JENKINS_DIR/start-all.sh）
# 复用 unit test 阶段已构建的 jar，跳过后端打包，只启动前后端服务
set -uo pipefail

CI_BACKEND_PORT="${CI_BACKEND_PORT:-6041}"
CI_FRONTEND_PORT="${CI_FRONTEND_PORT:-8084}"
CI_WORK_DIR="${CI_WORK_DIR:-/home/ubuntu/projects/wande-play-ci}"
CI_DB_NAME="${CI_DB_NAME:-wande-ai-ci}"
CI_BACKEND_DIR="/apps/wande-ai-backend-ci"
CI_FRONTEND_DIR="/apps/wande-ai-front-ci"
HEALTH_TIMEOUT=180

echo "[e2e/start-all] === 启动 CI 环境 (backend:${CI_BACKEND_PORT} frontend:${CI_FRONTEND_PORT}) ==="

# ── 1. 定位后端 jar（跳过 mvn package，复用 unit test 已构建的 jar）───
JAR_FILE=""
# 优先：CI_WORK_DIR 后端构建产出
if [ -f "${CI_WORK_DIR}/backend/ruoyi-admin/target/ruoyi-admin.jar" ]; then
    JAR_FILE="${CI_WORK_DIR}/backend/ruoyi-admin/target/ruoyi-admin.jar"
    echo "[e2e/start-all] ✅ 找到已构建 jar: ${JAR_FILE}"
elif [ -f "${CI_WORK_DIR}/backend/target/ruoyi-admin.jar" ]; then
    JAR_FILE="${CI_WORK_DIR}/backend/target/ruoyi-admin.jar"
    echo "[e2e/start-all] ✅ 找到已构建 jar: ${JAR_FILE}"
fi

# 回退：/apps 目录
if [ -z "${JAR_FILE}" ]; then
    if [ -f "${CI_BACKEND_DIR}/ruoyi-admin.jar" ]; then
        JAR_FILE="${CI_BACKEND_DIR}/ruoyi-admin.jar"
        echo "[e2e/start-all] ✅ 回退使用 /apps jar: ${JAR_FILE}"
    elif [ -f /apps/wande-ai-backend/ruoyi-admin.jar ]; then
        JAR_FILE=/apps/wande-ai-backend/ruoyi-admin.jar
        echo "[e2e/start-all] ✅ 回退使用 dev jar: ${JAR_FILE}"
    fi
fi

if [ -z "${JAR_FILE}" ] || [ ! -f "${JAR_FILE}" ]; then
    echo "[e2e/start-all] ❌ 找不到后端 jar"
    exit 1
fi

mkdir -p "${CI_BACKEND_DIR}/logs"
cp -f "${JAR_FILE}" "${CI_BACKEND_DIR}/ruoyi-admin.jar"
echo "[e2e/start-all] ✅ jar: ${JAR_FILE}"

# ── 2. 停止旧进程 ────────────────────────────────────────────────────────
stop_port() {
    local port=$1
    local pid=$(lsof -ti :${port} 2>/dev/null || true)
    [ -z "${pid}" ] && pid=$(pgrep -f "java.*:${port}" 2>/dev/null || true)
    if [ -n "${pid}" ]; then
        echo "[e2e/start-all] 停止旧进程 PID=${pid} (端口 :${port})"
        kill ${pid} 2>/dev/null || true; sleep 2; kill -9 ${pid} 2>/dev/null || true
    fi
}
stop_port "${CI_BACKEND_PORT}"
stop_port "${CI_FRONTEND_PORT}"

# ── 3. 启动后端 ─────────────────────────────────────────────────────────
echo "[e2e/start-all] 启动后端..."
nohup java -jar "${CI_BACKEND_DIR}/ruoyi-admin.jar" \
    --spring.profiles.active=test \
    --server.port="${CI_BACKEND_PORT}" \
    --spring.flyway.enabled=true \
    --spring.datasource.dynamic.datasource.master.url="jdbc:mysql://127.0.0.1:3306/${CI_DB_NAME}?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=false&serverTimezone=GMT%2B8&allowPublicKeyRetrieval=true" \
    --spring.datasource.dynamic.datasource.master.username=root \
    --spring.datasource.dynamic.datasource.master.password=root \
    --spring.data.redis.database=15 \
    > "${CI_BACKEND_DIR}/logs/backend.log" 2>&1 &
echo "[e2e/start-all] 后端 PID=$!"

# ── 4. 前端：构建 + 部署 nginx ──────────────────────────────────────────
DIST_DIR="${CI_WORK_DIR}/frontend/apps/web-antd/dist"
if [ -d "${DIST_DIR}" ] && [ -n "$(ls -A "${DIST_DIR}" 2>/dev/null)" ]; then
    echo "[e2e/start-all] ✅ 前端 dist 已存在，直接部署"
else
    echo "[e2e/start-all] ⚠️ 无前端 dist，开始构建..."
    cd "${CI_WORK_DIR}/frontend" || exit 1
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    pnpm build:antd
fi

mkdir -p "${CI_FRONTEND_DIR}"
rsync -a --delete "${DIST_DIR}/" "${CI_FRONTEND_DIR}/"
echo "[e2e/start-all] ✅ 前端已部署到 ${CI_FRONTEND_DIR}"

# nginx 配置并重启
sudo ln -sf /etc/nginx/sites-available/wande-ci /etc/nginx/sites-enabled/wande-ci 2>/dev/null || true
sudo pkill -f nginx 2>/dev/null || true
sleep 2
sudo nginx 2>/dev/null || sudo nginx -s reload 2>/dev/null || true
echo "[e2e/start-all] ✅ nginx :${CI_FRONTEND_PORT} 已上线"

# ── 5. 健康检查 ─────────────────────────────────────────────────────────
echo "[e2e/start-all] 等待 CI 环境就绪 (最多 ${HEALTH_TIMEOUT}s)..."
for i in $(seq 1 ${HEALTH_TIMEOUT}); do
    BE=false; FE=false
    curl -sf "http://localhost:${CI_BACKEND_PORT}/" > /dev/null 2>&1 && BE=true
    curl -sf "http://localhost:${CI_FRONTEND_PORT}/" > /dev/null 2>&1 && FE=true
    if [ "${BE}" = true ] && [ "${FE}" = true ]; then
        echo "[e2e/start-all] ✅ CI 环境就绪 (backend:${CI_BACKEND_PORT} frontend:${CI_FRONTEND_PORT})"
        exit 0
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "  等待... ${i}s / ${HEALTH_TIMEOUT}s (backend=\${BE} frontend=\${FE})"
    fi
    sleep 1
    if [ "$i" -eq "${HEALTH_TIMEOUT}" ]; then
        echo "[e2e/start-all] ❌ CI 环境启动超时"
        echo "===== 后端日志 (最后 50 行) ====="
        tail -50 "${CI_BACKEND_DIR}/logs/backend.log" 2>/dev/null || echo "(无日志)"

        # Flyway 特定错误检测，提供明确诊断
        LOG_FILE="${CI_BACKEND_DIR}/logs/backend.log"
        if grep -q "Found more than one migration with version" "${LOG_FILE}" 2>/dev/null; then
            echo ""
            echo "=============================================="
            echo "🚨 Flyway 版本冲突检测 — 多个迁移脚本使用相同版本号"
            echo ""
            echo "处理方法："
            echo "1. 在 wande-play 仓库执行以下命令找出重复版本："
            echo "   (ls backend/ruoyi-admin/src/main/resources/db/migration/;"
            echo "    ls backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/) \\"
            echo "   | sed 's/^V\([0-9]*\)__.*/\1/' | sort | uniq -c | sort -rn | head -10"
            echo ""
            echo "2. 重命名冲突文件（确保同一模块内版本唯一）："
            echo "   mv V20260509000000__A.sql V20260509000001__A.sql"
            echo ""
            echo "3. 删除跨模块重复（完全相同的文件只保留一处）："
            echo "   rm backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/<重复文件>"
            echo ""
            echo "4. 重建 jar："
            echo "   cd backend && mvn clean package -pl ruoyi-admin -am -Pprod -Dmaven.test.skip=true"
            echo "=============================================="
        elif grep -q "FlywayMigrateException\|flyway.*failed\|迁移失败" "${LOG_FILE}" 2>/dev/null; then
            echo ""
            echo "=============================================="
            echo "🚨 Flyway 迁移失败 — 检查以下常见原因："
            echo "1. 表/数据已存在（INSERT 重复）→ 手动 mark success=1"
            echo "   docker exec mysql-dev mysql -uroot -proot ${CI_DB_NAME} \\"
            echo "     -e \"UPDATE flyway_schema_history SET success=1 WHERE success=0;\""
            echo ""
            echo "2. 依赖表不存在（执行顺序问题）→ 检查迁移脚本依赖关系"
            echo ""
            echo "3. SQL 语法错误 → 查看上方日志中 'SQL State' 定位具体脚本"
            echo "=============================================="
        fi

        exit 1
    fi
done
