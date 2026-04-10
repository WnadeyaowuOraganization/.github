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
# e2e-smoke使用个人账号PAT（App token无法自审核自己创建的PR）
export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py" weiping)
export PATH="${HOME_DIR}/.local/bin:$PATH"
export HOME="${HOME_DIR}"

cd "$E2E_DIR" || { log "❌ 目录不存在: $E2E_DIR"; exit 1; }

# 拉取最新测试代码
git fetch origin dev && git reset --hard origin/dev && git clean -fd 2>/dev/null

log "🔍 Smoke探活开始"

# --- Step 1: 后端健康检查 ---
BACKEND_OK=false
BACKEND_PID=""

# 检查进程是否存在且端口被占用
check_backend_process() {
    local pid=$(pgrep -f "ruoyi-admin" 2>/dev/null || true)
    if [ -n "$pid" ]; then
        # 检查端口是否被占用
        if ss -tlnp 2>/dev/null | grep -q ":6040"; then
            echo "$pid"
            return 0
        fi
    fi
    return 1
}

# 尝试检测僵死进程（端口占用但不响应HTTP）
detect_zombie_backend() {
    local pid=$(check_backend_process)
    if [ -n "$pid" ]; then
        # 端口被占用但HTTP不响应
        if ! curl -sf "http://localhost:6040/" > /dev/null 2>&1; then
            log "⚠️ 检测到僵死进程 PID=$pid（端口6040占用但HTTP无响应）"
            return 0
        fi
    fi
    return 1
}

# 尝试恢复后端服务
recover_backend() {
    log "🔄 尝试恢复后端服务..."

    # 先尝试使用 systemd 重启
    if systemctl is-active wande-backend > /dev/null 2>&1 || systemctl is-enabled wande-backend > /dev/null 2>&1; then
        log ">>> 使用 systemctl 重启 wande-backend"
        sudo systemctl restart wande-backend 2>&1 | head -5 >> "$LOGFILE"
        sleep 10
    else
        # 回退到传统方式
        log ">>> 使用传统方式重启"
        local pid=$(pgrep -f "ruoyi-admin" 2>/dev/null || true)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
            sleep 3
        fi
        if [ -x "/apps/wande-ai-backend/start.sh" ]; then
            bash "/apps/wande-ai-backend/start.sh" > /dev/null 2>&1 &
            sleep 10
        fi
    fi

    # 验证恢复结果
    if curl -sf "http://localhost:6040/" > /dev/null 2>&1; then
        log "✅ 后端服务恢复成功"
        return 0
    else
        log "❌ 后端服务恢复失败"
        return 1
    fi
}

# 主检查逻辑
if curl -sf "http://localhost:6040/" > /dev/null 2>&1; then
    BACKEND_OK=true
    log "✅ 后端健康检查通过 (:6040)"
else
    log "❌ 后端HTTP不可达 (:6040)"

    # 检测是否为僵死进程
    if detect_zombie_backend; then
        log "🔴 发现僵死进程，尝试自动恢复..."
        if recover_backend; then
            BACKEND_OK=true
        fi
    fi
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
