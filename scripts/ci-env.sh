#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# ==============================================================
# CI专用测试环境 启动/停止/健康检查
# 用途: pr-test.yml 调用，与dev环境(:6040/:8083)隔离
# 端口: 后端6041 / 前端8084
# 数据库: 共用dev环境 localhost:5433（无需双份迁移）
#
# 安全约束（2026-04-08 修复漏洞）:
# 1. BACKEND_CHANGED=true 时，mvn 构建失败必须 hard fail，禁止 fallback 旧 jar
# 2. BACKEND_CHANGED=false 时，必须从当前 dev 部署的 jar 复制（不能用 CI 目录残留）
# 3. 构建日志全程保留到 /tmp/ci-build-${PR_NUM:-unknown}.log，供失败通知抽取
# ==============================================================
set -eo pipefail

PR_NUM="${PR_NUM:-unknown}"
BUILD_LOG="/tmp/ci-build-${PR_NUM}.log"
: > "$BUILD_LOG"

ACTION=${1:-start}
CI_DIR="${HOME_DIR}/projects/wande-play-ci"
CI_BACKEND_PORT=6041
CI_FRONTEND_PORT=8084
CI_FRONTEND_DIR="/apps/wande-ai-front-ci"
CI_BACKEND_DIR="/apps/wande-ai-backend-ci"
HEALTH_TIMEOUT=120

BACKEND_CHANGED=${BACKEND_CHANGED:-false}
FRONTEND_CHANGED=${FRONTEND_CHANGED:-false}

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[ci-env] $1${NC}"; }
warn() { echo -e "${YELLOW}[ci-env] $1${NC}"; }
err() { echo -e "${RED}[ci-env] $1${NC}"; }

stop_ci_backend() {
    local PID=$(lsof -ti :$CI_BACKEND_PORT 2>/dev/null || true)
    if [ -n "$PID" ]; then
        log "停止CI后端进程: $PID"
        kill $PID 2>/dev/null || true
        sleep 3
        kill -9 $PID 2>/dev/null || true
    fi
}

start_ci_backend() {
    mkdir -p "$CI_BACKEND_DIR/logs"

    if [ "$BACKEND_CHANGED" = "true" ]; then
        log "PR 修改了后端，构建 CI 后端..."
        cd "$CI_DIR"
        # 如果有PR分支，切换到PR分支构建
        if [ -n "$PR_BRANCH" ]; then
            log "使用PR分支: $PR_BRANCH"
            git fetch origin "${PR_BRANCH}:${PR_BRANCH}" --update-head-ok || git fetch origin "$PR_BRANCH"
            git checkout -B "$PR_BRANCH" || git checkout "$PR_BRANCH"
        fi
        cd "$CI_DIR/backend"

        # ⚠️ 安全：彻底清空 target，避免残留 jar 在 mvn 失败时被 find 找到
        find . -name target -type d -prune -exec rm -rf {} + 2>/dev/null || true

        # 全程把构建输出写入 BUILD_LOG，并通过 PIPESTATUS 严格检查 mvn 退出码
        log "执行 mvn clean package -Pprod -Dmaven.test.skip=true（日志: $BUILD_LOG）..."
        set +e
        mvn clean package -Pprod -Dmaven.test.skip=true -B 2>&1 | tee -a "$BUILD_LOG"
        MVN_RC=${PIPESTATUS[0]}
        set -e
        if [ "$MVN_RC" -ne 0 ]; then
            err "mvn 构建失败 (exit=$MVN_RC)，PR 不允许继续部署 CI 环境"
            err "完整构建日志：$BUILD_LOG"
            tail -40 "$BUILD_LOG"
            # ⚠️ 关键：禁止任何 fallback；构建失败立即 exit 1，让 workflow 走失败分支
            exit 1
        fi

        JAR_FILE=$(find ruoyi-admin/target -name "ruoyi-admin*.jar" -type f -newer "$BUILD_LOG" 2>/dev/null | head -1)
        if [ -z "$JAR_FILE" ] || [ ! -f "$JAR_FILE" ]; then
            err "mvn 退出 0 但未找到本次构建产物 jar — 视为构建失败"
            exit 1
        fi
        cp "$JAR_FILE" "$CI_BACKEND_DIR/ruoyi-admin.jar"
        log "编译成功: $JAR_FILE"
    else
        # PR 没改后端：从 dev 当前部署的 jar 复制（不是 CI 残留 jar，避免污染）
        if [ ! -f "/apps/wande-ai-backend/ruoyi-admin.jar" ]; then
            err "BACKEND_CHANGED=false 但 dev 部署的 jar 不存在 (/apps/wande-ai-backend/ruoyi-admin.jar)，无法构造 CI 环境"
            exit 1
        fi
        log "PR 未修改后端，从当前 dev 部署 jar 复制"
        cp -f /apps/wande-ai-backend/ruoyi-admin.jar "$CI_BACKEND_DIR/ruoyi-admin.jar"
    fi

    stop_ci_backend

    log "启动CI后端 :$CI_BACKEND_PORT..."
    nohup java -jar "$CI_BACKEND_DIR/ruoyi-admin.jar" \
        --spring.profiles.active=dev \
        --server.port=$CI_BACKEND_PORT \
        --spring.datasource.dynamic.datasource.master.url="jdbc:postgresql://localhost:5433/ruoyi_ai?stringtype=unspecified" \
        --spring.datasource.dynamic.datasource.master.username=wande \
        --spring.datasource.dynamic.datasource.master.password=wande_dev_2026 \
        --spring.datasource.dynamic.datasource.wande.url="jdbc:postgresql://localhost:5433/wande_ai?stringtype=unspecified" \
        --spring.datasource.dynamic.datasource.wande.username=wande \
        --spring.datasource.dynamic.datasource.wande.password=wande_dev_2026 \
        --spring.data.redis.host=localhost \
        --spring.data.redis.port=6380 \
        --spring.data.redis.password=redis_dev_2026 \
        > "$CI_BACKEND_DIR/logs/backend.log" 2>&1 &

    log "CI后端PID: $!"
}

start_ci_frontend() {
    mkdir -p "$CI_FRONTEND_DIR"

    if [ "$FRONTEND_CHANGED" = "true" ]; then
        log "PR 修改了前端，构建 CI 前端（日志: $BUILD_LOG）..."
        cd "$CI_DIR/frontend"

        set +e
        pnpm install --frozen-lockfile 2>&1 | tee -a "$BUILD_LOG"
        INST_RC=${PIPESTATUS[0]}
        if [ "$INST_RC" -ne 0 ]; then
            warn "frozen-lockfile 安装失败，回退普通 install"
            pnpm install 2>&1 | tee -a "$BUILD_LOG"
            INST_RC=${PIPESTATUS[0]}
        fi
        if [ "$INST_RC" -ne 0 ]; then
            set -e
            err "pnpm install 失败 (exit=$INST_RC)"
            tail -40 "$BUILD_LOG"
            exit 1
        fi

        pnpm build 2>&1 | tee -a "$BUILD_LOG"
        BUILD_RC=${PIPESTATUS[0]}
        set -e
        if [ "$BUILD_RC" -ne 0 ]; then
            err "前端构建失败 (exit=$BUILD_RC)"
            tail -40 "$BUILD_LOG"
            exit 1
        fi

        DIST_DIR="$CI_DIR/frontend/apps/web-antd/dist"
        if [ ! -d "$DIST_DIR" ] || [ -z "$(ls -A "$DIST_DIR" 2>/dev/null)" ]; then
            err "前端构建退出 0 但 dist 为空 — 视为失败"
            exit 1
        fi

        rsync -a --delete "$DIST_DIR/" "$CI_FRONTEND_DIR/"
        sudo nginx -s reload
        log "CI前端构建+部署完成"
    else
        # PR 没改前端：从当前 dev 部署的 dist 复制（不能用 CI 残留）
        if [ ! -d "/apps/wande-ai-front" ] || [ -z "$(ls -A /apps/wande-ai-front 2>/dev/null)" ]; then
            err "BACKEND_CHANGED=false 但 dev 部署的前端目录为空，无法构造 CI 环境"
            exit 1
        fi
        log "PR 未修改前端，从当前 dev 部署 dist 复制"
        rsync -a --delete /apps/wande-ai-front/ "$CI_FRONTEND_DIR/"
        sudo nginx -s reload 2>/dev/null || true
    fi
}

wait_healthy() {
    log "等待CI环境就绪..."
    for i in $(seq 1 $((HEALTH_TIMEOUT / 3))); do
        local BACKEND_OK=true
        local FRONTEND_OK=true

        if ! curl -sf http://localhost:$CI_BACKEND_PORT/ > /dev/null 2>&1; then
            BACKEND_OK=false
        fi
        if ! curl -sf http://localhost:$CI_FRONTEND_PORT/ > /dev/null 2>&1; then
            FRONTEND_OK=false
        fi

        if [ "$BACKEND_OK" = true ] && [ "$FRONTEND_OK" = true ]; then
            log "CI环境就绪 ✅ (后端:$CI_BACKEND_PORT 前端:$CI_FRONTEND_PORT)"
            return 0
        fi
        echo "  等待中... ($((i * 3))s/${HEALTH_TIMEOUT}s) backend=$BACKEND_OK frontend=$FRONTEND_OK"
        sleep 3
    done

    err "CI环境未在${HEALTH_TIMEOUT}s内就绪"
    if [ -f "$CI_BACKEND_DIR/logs/backend.log" ]; then
        echo "--- CI后端最后10行日志 ---"
        tail -10 "$CI_BACKEND_DIR/logs/backend.log"
    fi
    return 1
}

case $ACTION in
    start)
        log "=== 启动CI专用测试环境 (PR=$PR_NUM) ==="
        start_ci_backend
        start_ci_frontend
        # ⚠️ 不允许 fallback 重新构建覆盖：起不来就直接失败，让 PR 暴露问题
        wait_healthy
        ;;
    stop)
        log "=== 停止CI专用测试环境 ==="
        stop_ci_backend
        log "CI后端已停止（前端nginx保持，不影响其他服务）"
        ;;
    status)
        BACKEND_OK=$(curl -sf http://localhost:$CI_BACKEND_PORT/ > /dev/null 2>&1 && echo "✅" || echo "❌")
        FRONTEND_OK=$(curl -sf http://localhost:$CI_FRONTEND_PORT/ > /dev/null 2>&1 && echo "✅" || echo "❌")
        echo "CI后端 :$CI_BACKEND_PORT $BACKEND_OK"
        echo "CI前端 :$CI_FRONTEND_PORT $FRONTEND_OK"
        ;;
    *)
        echo "用法: $0 {start|stop|status}"
        echo "环境变量: BACKEND_CHANGED=true/false FRONTEND_CHANGED=true/false"
        exit 1
        ;;
esac
