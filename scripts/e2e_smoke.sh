#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# e2e_smoke.sh — Dev环境Smoke探活（每30分钟，纯脚本，零AI消耗）
# crontab: */30 * * * *
#
# 跑 smoke 测试 + health check，失败时由 e2e-result-handler.py 自动创建Issue
# 不使用AI，不使用Claude Code
#
# 操作:
#   tail -f ${HOME_DIR}/cc_scheduler/logs/e2e-smoke.log    查看日志
#   bash ${HOME_DIR}/projects/.github/scripts/e2e_smoke.sh  手动执行

LOCK_FILE="${HOME_DIR}/cc_scheduler/e2e_smoke.lock"
E2E_DIR="${HOME_DIR}/projects/wande-play/e2e"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDLER="$SCRIPT_DIR/e2e-result-handler.py"
LOGDIR="${HOME_DIR}/cc_scheduler/logs"
LOGFILE="$LOGDIR/e2e-smoke.log"

mkdir -p "$LOGDIR"

# 防止并发
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"; }

# --- 环境准备 ---
export GH_TOKEN=$(bash "$SCRIPT_DIR/get-gh-token.sh")
export PATH="${HOME_DIR}/.local/bin:$PATH"
export HOME="${HOME_DIR}"

cd "$E2E_DIR" || { log "❌ 目录不存在: $E2E_DIR"; exit 1; }

# 拉取最新测试代码
git fetch origin dev && git reset --hard origin/dev && git clean -fd 2>/dev/null

log "🔍 Smoke探活开始"

# --- Step 1: 后端健康检查 ---
BACKEND_OK=false
if curl -sf "http://localhost:6040/" > /dev/null 2>&1; then
    BACKEND_OK=true
    log "✅ 后端健康检查通过 (:6040)"
else
    log "❌ 后端不可达 (:6040)"
fi

# --- Step 2: 前端健康检查 ---
FRONTEND_OK=false
if curl -sf "http://localhost:8083/" > /dev/null 2>&1; then
    FRONTEND_OK=true
    log "✅ 前端健康检查通过 (:8083)"
else
    log "❌ 前端不可达 (:8083)"
fi

# 如果后端和前端都不可达，跳过Playwright测试（环境未启动）
if [ "$BACKEND_OK" = "false" ] && [ "$FRONTEND_OK" = "false" ]; then
    log "⚠️ Dev环境未启动，跳过Playwright测试"
    exit 0
fi

# --- Step 3: Playwright Smoke测试 ---
# 清理旧报告
rm -f test-results/reports/results.json

EXIT_CODE=0

# 后端API smoke（health + auth）
if [ "$BACKEND_OK" = "true" ]; then
    log ">>> 运行后端API smoke测试"
    npx playwright test tests/backend/api/health.spec.ts tests/backend/api/auth.spec.ts \
        --grep-invert "@external" \
        --reporter=json,list \
        --timeout=30000 2>&1 | tail -5 >> "$LOGFILE" || EXIT_CODE=$?
fi

# 前端smoke（如果目录存在）
if [ "$FRONTEND_OK" = "true" ] && [ -d "tests/front/smoke" ]; then
    log ">>> 运行前端smoke测试"
    npx playwright test tests/front/smoke/ \
        --grep-invert "@external" \
        --reporter=json,list \
        --timeout=30000 2>&1 | tail -5 >> "$LOGFILE" || EXIT_CODE=$?
fi

# --- Step 4: 结果处理 ---
REPORT="test-results/reports/results.json"

if [ $EXIT_CODE -eq 0 ]; then
    log "✅ Smoke探活全部通过"
    # 通过时不调handler，减少API调用
else
    log "❌ Smoke探活发现失败，调用结果处理器"
    # 无--pr无--issue → handler自动创建Issue
    python3 "$HANDLER" --report "$REPORT" --source smoke 2>&1 >> "$LOGFILE"
    log "📌 结果处理完成"
fi

log "🔍 Smoke探活结束 (exit=$EXIT_CODE)"
