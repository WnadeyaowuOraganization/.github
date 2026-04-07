#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# ==============================================================
# CI专用测试环境 启动/停止/健康检查
# 用途: pr-test.yml 调用，与dev环境(:6040/:8083)隔离
# 端口: 后端6041 / 前端8084
# 数据库: 共用dev环境 localhost:5433（无需双份迁移）
# ==============================================================
set -e

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
    if [ "$BACKEND_CHANGED" != "true" ]; then
        log "后端无变更，检查CI后端是否已运行..."
        if curl -sf http://localhost:$CI_BACKEND_PORT/ > /dev/null 2>&1; then
            log "CI后端已在运行，跳过启动"
            return 0
        fi
        warn "CI后端未运行且无后端变更 — 使用现有jar包启动"
    fi

    mkdir -p "$CI_BACKEND_DIR/logs"

    if [ "$BACKEND_CHANGED" = "true" ]; then
        log "构建CI后端..."
        cd "$CI_DIR"
        # 如果有PR分支，切换到PR分支构建
        if [ -n "$PR_BRANCH" ]; then
            log "使用PR分支: $PR_BRANCH"
            git fetch origin "$PR_BRANCH"
            git checkout -B "$PR_BRANCH" "origin/$PR_BRANCH"
        fi
        cd "$CI_DIR/backend"
        mvn clean package -Pprod -Dmaven.test.skip=true -q 2>&1 | tail -5
        JAR_FILE=$(find ruoyi-admin/target -name "*.jar" -type f | head -1)
        if [ -z "$JAR_FILE" ]; then
            err "后端编译失败"
            exit 1
        fi
        cp "$JAR_FILE" "$CI_BACKEND_DIR/ruoyi-admin.jar"
        log "编译成功: $JAR_FILE"
    fi

    # 如果没有jar包（首次运行且无变更），从dev复制
    if [ ! -f "$CI_BACKEND_DIR/ruoyi-admin.jar" ]; then
        if [ -f "/apps/wande-ai-backend/ruoyi-admin.jar" ]; then
            cp /apps/wande-ai-backend/ruoyi-admin.jar "$CI_BACKEND_DIR/ruoyi-admin.jar"
            warn "使用dev环境jar包"
        else
            err "无可用jar包"
            exit 1
        fi
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
    if [ "$FRONTEND_CHANGED" != "true" ]; then
        log "前端无变更，检查CI前端是否可达..."
        if curl -sf http://localhost:$CI_FRONTEND_PORT/ > /dev/null 2>&1; then
            log "CI前端已在运行，跳过构建"
            return 0
        fi
        warn "CI前端不可达 — 复制dev前端资源"
        if [ ! -d "$CI_FRONTEND_DIR" ] || [ -z "$(ls -A $CI_FRONTEND_DIR 2>/dev/null)" ]; then
            mkdir -p "$CI_FRONTEND_DIR"
            rsync -a /apps/wande-ai-front/ "$CI_FRONTEND_DIR/"
        fi
        sudo nginx -s reload 2>/dev/null || true
        return 0
    fi

    log "构建CI前端..."
    cd "$CI_DIR/frontend"
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    pnpm build

    DIST_DIR="$CI_DIR/frontend/apps/web-antd/dist"
    if [ ! -d "$DIST_DIR" ]; then
        err "前端构建失败"
        exit 1
    fi

    mkdir -p "$CI_FRONTEND_DIR"
    rsync -a --delete "$DIST_DIR/" "$CI_FRONTEND_DIR/"
    sudo nginx -s reload
    log "CI前端部署完成"
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
        log "=== 启动CI专用测试环境 ==="
        start_ci_backend
        start_ci_frontend
        if ! wait_healthy; then
            # 启动失败，强制重新构建
            warn "CI环境启动失败，强制重新构建..."
            BACKEND_CHANGED=true
            start_ci_backend
            start_ci_frontend
            wait_healthy
        fi
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
