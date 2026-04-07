#!/bin/bash
# ensure-test-pg.sh — 确保单元测试 PG 容器在端口 5434 运行，并为指定 kimi 目录创建独立测试 DB
#
# 用法：
#   bash ensure-test-pg.sh                  # 只确保容器存在（默认 wande_ai 库）
#   bash ensure-test-pg.sh kimi3            # 创建 wande_test_kimi3 库（每个 CC 隔离）
#   bash ensure-test-pg.sh ci               # 创建 wande_test_ci 库（pr-test.yml 用）
#
# 容器: wande-test-pg / 端口: 5434 / 用户: wande / 密码: wande_test
#
# 设计：所有 kimi 目录共享一个容器（节省内存），每个用独立 DB 物理隔离
# 即使多个 CC 并发跑 mvn test 也互不影响（DROP SCHEMA 只影响自己的 DB）

set -e

CONTAINER="wande-test-pg"
PORT=5434
TARGET_DIR="${1:-}"   # kimi1 / kimi2 / ci，为空则只 ensure 容器

# === Step 1: 确保容器存在并运行 ===
if docker ps --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
  : # 已运行
elif docker ps -a --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
  echo "▶ 启动已存在的 ${CONTAINER}"
  docker start "${CONTAINER}" >/dev/null
else
  echo "▶ 创建 ${CONTAINER}"
  docker run -d --name "${CONTAINER}" \
    --restart unless-stopped \
    -e POSTGRES_USER=wande \
    -e POSTGRES_PASSWORD=wande_test \
    -e POSTGRES_DB=wande_ai \
    -p ${PORT}:5432 \
    postgres:16-alpine >/dev/null
fi

# 等 ready
for i in $(seq 1 30); do
  if docker exec "${CONTAINER}" pg_isready -U wande >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! docker exec "${CONTAINER}" pg_isready -U wande >/dev/null 2>&1; then
  echo "❌ ${CONTAINER} 启动超时"
  exit 1
fi

# === Step 2: 如果指定了 kimi 目录，创建独立 DB ===
if [ -n "$TARGET_DIR" ]; then
  DB_NAME="wande_test_${TARGET_DIR}"
  EXISTS=$(docker exec "${CONTAINER}" psql -U wande -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'")
  if [ -z "$EXISTS" ]; then
    echo "▶ 创建测试库 ${DB_NAME}"
    docker exec "${CONTAINER}" psql -U wande -d postgres -c "CREATE DATABASE ${DB_NAME}" >/dev/null
  fi
  echo "✓ ${CONTAINER} 就绪 (端口 ${PORT}, DB=${DB_NAME})"
  echo ""
  echo "在 mvn test 前 export:"
  echo "  export TEST_PG_DB=${DB_NAME}"
else
  echo "✓ ${CONTAINER} 就绪 (端口 ${PORT})"
fi
