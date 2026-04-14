#!/bin/bash
# 备用方案：pgloader 失败时用 pg_dump 导出 SQL，保留原始数据以便日后手工处理。
#
# 与 run-migration.sh 共用相同 SSH 隧道与 PG 凭据环境变量。
# 这个脚本只做导出（data-only 用 INSERT 语句），不尝试 PG→MySQL 转换。

set -e

PG_USER="${PG_USER:-wande}"
PG_PASS="${PG_PASS:-wande_dev_2026}"
PG_DB="${PG_DB:-wande_ai}"
# 默认 VPC 直连 G7e 内网 IP；若走 SSH 隧道请设 PG_CONN_HOST=127.0.0.1 PG_CONN_PORT=15433
PG_CONN_HOST="${PG_CONN_HOST:-172.31.33.224}"
PG_CONN_PORT="${PG_CONN_PORT:-5433}"
# 兼容旧参数
PG_LOCAL_PORT="${PG_LOCAL_PORT:-$PG_CONN_PORT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="${SCRIPT_DIR}/dumps"
mkdir -p "$DUMP_DIR"
TS=$(date +%Y%m%d_%H%M%S)

export PGPASSWORD="$PG_PASS"

echo "[1/3] 导出 schema（仅结构）..."
pg_dump -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" \
  --schema=public --schema-only --no-owner --no-privileges \
  -f "${DUMP_DIR}/schema_${TS}.sql"
echo "   → ${DUMP_DIR}/schema_${TS}.sql"

echo "[2/3] 导出 data-only（INSERT 格式，便于跨库）..."
pg_dump -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" \
  --schema=public --data-only --column-inserts --no-owner \
  -f "${DUMP_DIR}/data_${TS}.sql"
echo "   → ${DUMP_DIR}/data_${TS}.sql"

echo "[3/3] 打包..."
tar czf "${DUMP_DIR}/g7e_pg_${TS}.tar.gz" -C "$DUMP_DIR" "schema_${TS}.sql" "data_${TS}.sql"
du -h "${DUMP_DIR}/g7e_pg_${TS}.tar.gz"
echo "完成。备份：${DUMP_DIR}/g7e_pg_${TS}.tar.gz"
