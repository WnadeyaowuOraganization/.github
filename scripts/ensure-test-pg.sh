#!/bin/bash
# ensure-test-pg.sh — 确保单元测试 PG 容器在端口 5434 运行
# 由 pr-test.yml 的 unit-test job 调用
#
# 容器名: wande-test-pg
# 端口:   5434 (与 dev 5433 隔离)
# 库:     wande_ai
# 用户:   wande / wande_test

set -e

CONTAINER="wande-test-pg"
PORT=5434

# 已运行 → 跳过
if docker ps --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
  echo "✓ ${CONTAINER} 已运行"
  exit 0
fi

# 已停止 → 启动
if docker ps -a --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
  echo "▶ 启动已存在的 ${CONTAINER}"
  docker start "${CONTAINER}"
else
  # 首次创建
  echo "▶ 创建 ${CONTAINER}"
  docker run -d --name "${CONTAINER}" \
    --restart unless-stopped \
    -e POSTGRES_USER=wande \
    -e POSTGRES_PASSWORD=wande_test \
    -e POSTGRES_DB=wande_ai \
    -p ${PORT}:5432 \
    postgres:16-alpine
fi

# 等待 ready
for i in $(seq 1 20); do
  if docker exec "${CONTAINER}" pg_isready -U wande -d wande_ai >/dev/null 2>&1; then
    echo "✓ ${CONTAINER} 就绪 (端口 ${PORT})"
    exit 0
  fi
  sleep 1
done
echo "❌ ${CONTAINER} 启动超时"
exit 1
