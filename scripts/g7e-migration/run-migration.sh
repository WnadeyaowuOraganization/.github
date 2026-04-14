#!/bin/bash
# G7e PostgreSQL → m7i MySQL 全量迁移主脚本
#
# 用法：
#   G7E_HOST=3.211.167.122 G7E_USER=ubuntu G7E_SSH_KEY=~/.ssh/id_ed25519 \
#   bash run-migration.sh
#
# 流程：
#   1) 开 SSH 隧道把 G7e:5433 映射到 m7i:15433
#   2) 探活 PG 连接
#   3) 在 m7i MySQL 建 wande_ai_legacy 库
#   4) 运行 pgloader 按配置迁移
#   5) 对比源/目标 row count，输出验证报告
#   6) 关闭隧道

set -e

G7E_HOST="${G7E_HOST:-172.31.33.224}"       # VPC 内网实测 397MB/s 最快；备选公网 3.211.167.122 / tailscale 100.99.88.7
G7E_USER="${G7E_USER:-ubuntu}"
G7E_SSH_KEY="${G7E_SSH_KEY:-$HOME/.ssh/id_ed25519}"
G7E_SSH_PASS="${G7E_SSH_PASS:-}"             # 若设置了密码则优先用 sshpass 走密码认证
PG_USER="${PG_USER:-wande}"
PG_PASS="${PG_PASS:-wande_dev_2026}"
PG_DB="${PG_DB:-wande_ai}"
PG_REMOTE_PORT="${PG_REMOTE_PORT:-5433}"
PG_LOCAL_PORT="${PG_LOCAL_PORT:-15433}"
# VPC 直连模式：若 G7e PG 5433 内网直接可达，跳过 SSH 隧道（默认自动探测）
VPC_DIRECT="${VPC_DIRECT:-auto}"             # auto | yes | no
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-root}"
TARGET_DB="${TARGET_DB:-wande_ai_legacy}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/reports"
mkdir -p "$REPORT_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG="${REPORT_DIR}/migration_${TS}.log"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }
die() { log "FATAL: $*"; cleanup; exit 1; }

TUNNEL_PID=""
cleanup() {
  if [ -n "$TUNNEL_PID" ] && kill -0 "$TUNNEL_PID" 2>/dev/null; then
    log "关闭 SSH 隧道 (pid=$TUNNEL_PID)"
    kill "$TUNNEL_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

#=============================================================================
# Step 1: 建立 PG 连接（优先 VPC 直连，否则回退 SSH 隧道）
#=============================================================================
log "=== Step 1: 建立 PostgreSQL 连接 ==="
log "G7E_HOST=$G7E_HOST G7E_USER=$G7E_USER VPC_DIRECT=$VPC_DIRECT"

# 自动探测 VPC 直连
if [ "$VPC_DIRECT" = "auto" ]; then
  if nc -zw3 "$G7E_HOST" "$PG_REMOTE_PORT" 2>/dev/null; then
    VPC_DIRECT=yes
    log "✓ 自动探测：PG 5433 内网直连可达"
  else
    VPC_DIRECT=no
    log "·  自动探测：PG 5433 不可直连，回退 SSH 隧道"
  fi
fi

if [ "$VPC_DIRECT" = "yes" ]; then
  # 直连模式：不开隧道，PG_LOCAL_PORT 改为远端真实地址
  PG_CONN_HOST="$G7E_HOST"
  PG_CONN_PORT="$PG_REMOTE_PORT"
  log "✓ 使用 VPC 直连模式：PG 目标 ${PG_CONN_HOST}:${PG_CONN_PORT}"
else
  # 隧道模式：探活 SSH 再建隧道
  if ! nc -zw3 "$G7E_HOST" 22 2>/dev/null; then
    die "G7e ($G7E_HOST:22) SSH 不可达，且 PG 也不直连；请确认机器已启动"
  fi
  log "✓ G7e SSH 端口可达"

  SSH_BASE_OPTS="-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -N -L ${PG_LOCAL_PORT}:localhost:${PG_REMOTE_PORT}"
  if [ -n "$G7E_SSH_PASS" ]; then
    if ! command -v sshpass >/dev/null; then
      die "需要 sshpass (apt install sshpass) 才能使用 G7E_SSH_PASS"
    fi
    log "使用密码认证 (sshpass)"
    SSHPASS="$G7E_SSH_PASS" sshpass -e ssh -o PreferredAuthentications=password $SSH_BASE_OPTS "${G7E_USER}@${G7E_HOST}" &
  else
    log "使用 key 认证 ($G7E_SSH_KEY)"
    ssh -i "$G7E_SSH_KEY" $SSH_BASE_OPTS "${G7E_USER}@${G7E_HOST}" &
  fi
  TUNNEL_PID=$!
  sleep 3

  if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
    die "SSH 隧道建立失败"
  fi
  log "✓ SSH 隧道已建立 (pid=$TUNNEL_PID)"
  PG_CONN_HOST="127.0.0.1"
  PG_CONN_PORT="$PG_LOCAL_PORT"
fi

#=============================================================================
# Step 2: 探活 PG 连接
#=============================================================================
log "=== Step 2: 探活 PostgreSQL ==="
export PGPASSWORD="$PG_PASS"
if ! psql -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" -c "SELECT version();" >/dev/null 2>&1; then
  die "PostgreSQL 连接失败 — 检查凭据 ${PG_USER}@localhost:${PG_LOCAL_PORT}/${PG_DB}"
fi
PG_VERSION=$(psql -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" -tAc "SELECT version();")
log "✓ PG 版本：$PG_VERSION"

# 源端表清单 + 行数快照
log "--- 源端表清单（schema=public）---"
psql -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" -c "
  SELECT table_name FROM information_schema.tables
   WHERE table_schema='public' ORDER BY table_name;
" | tee -a "$LOG"

log "--- 源端行数快照 ---"
psql -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" -tAc "
  SELECT 'SELECT '''||table_name||''' AS t, COUNT(*) FROM '||quote_ident(table_name)
    FROM information_schema.tables
   WHERE table_schema='public';
" | tr '\n' ' ' | sed 's/ SELECT/ UNION ALL SELECT/g' | \
  xargs -I{} psql -h "$PG_CONN_HOST" -p "$PG_CONN_PORT" -U "$PG_USER" -d "$PG_DB" -c "{} ORDER BY t;" > "${REPORT_DIR}/pg_rowcount_${TS}.txt" 2>&1 || true
cat "${REPORT_DIR}/pg_rowcount_${TS}.txt" | tee -a "$LOG"

#=============================================================================
# Step 3: 建 MySQL 目标库
#=============================================================================
log "=== Step 3: 建 MySQL 目标库 ${TARGET_DB} ==="
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" <<SQL 2>&1 | tee -a "$LOG"
DROP DATABASE IF EXISTS \`${TARGET_DB}\`;
CREATE DATABASE \`${TARGET_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL
log "✓ 目标库 ${TARGET_DB} 已就绪（已 DROP 重建）"

#=============================================================================
# Step 4: pgloader 迁移
#=============================================================================
log "=== Step 4: pgloader 迁移（可能需要 2-10 分钟） ==="
cd "$SCRIPT_DIR"

# pgloader 3.6.7 跨引擎迁移必须走 load 文件（命令行模式只支持 PG→PG）
# 动态生成 load 文件，替换连接串
GEN_LOAD="${REPORT_DIR}/migration_runtime_${TS}.load"
sed -E \
  -e "s|127\.0\.0\.1:15433|${PG_CONN_HOST}:${PG_CONN_PORT}|g" \
  -e "s|wande:wande_dev_2026|${PG_USER}:${PG_PASS}|g" \
  -e "s|root:root|${MYSQL_USER}:${MYSQL_PASS}|g" \
  -e "s|wande_ai_legacy|${TARGET_DB}|g" \
  migration.load > "$GEN_LOAD"
log "生成运行时配置：$GEN_LOAD"

set +e
# Ubuntu pgloader 3.6.7 没编 MySQL 支持，用 Docker 版
# --network=host 保证容器能直接访问 m7i 上的 15433 SSH 隧道 + 3306 MySQL
docker run --rm --network=host \
  -v "${REPORT_DIR}:/reports:ro" \
  ghcr.io/dimitri/pgloader:latest \
  pgloader --verbose "/reports/$(basename $GEN_LOAD)" 2>&1 | tee -a "$LOG"
PGLOADER_RC=${PIPESTATUS[0]}
set -e
if [ "$PGLOADER_RC" -ne 0 ]; then
  log "⚠️ pgloader 退出码 $PGLOADER_RC（可能是部分失败，继续验证）"
fi

#=============================================================================
# Step 5: 验证
#=============================================================================
log "=== Step 5: 验证 row count ==="
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "${TARGET_DB}" -e "
  SELECT table_name, table_rows
    FROM information_schema.tables
   WHERE table_schema='${TARGET_DB}'
   ORDER BY table_name;
" 2>&1 | tee "${REPORT_DIR}/mysql_rowcount_${TS}.txt" | tee -a "$LOG"

log "=== 完成 ==="
log "源端快照：${REPORT_DIR}/pg_rowcount_${TS}.txt"
log "目标快照：${REPORT_DIR}/mysql_rowcount_${TS}.txt"
log "完整日志：${LOG}"
log ""
log "下一步："
log "  1) 人工比对两份 rowcount 文件，确认一致"
log "  2) 查看 ${TARGET_DB} 中的表，按 integration-plan.md 规划字段映射"
log "  3) 通知吴耀可以关 G7e"
