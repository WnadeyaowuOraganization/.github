#!/bin/bash
# ==============================================================
# migrate-post-task.sh — 批量迁移各项目的post-task.sh到统一版本
# 功能：
# 1. 备份项目原有的script/post-task.sh
# 2. 更新CI/CD配置指向统一版本
# 3. 可选：删除项目本地的post-task.sh
# ==============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_BASE="/home/ubuntu/projects"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
log() { echo -e "${GREEN}>>> $1${NC}"; }
warn() { echo -e "${YELLOW}>>> $1${NC}"; }
error() { echo -e "${RED}>>> $1${NC}"; }

# 项目列表
PROJECTS=(
    "wande-ai-backend"
    "wande-ai-front"
    "wande-data-pipeline"
)

log "开始批量迁移post-task.sh..."

for PROJECT in "${PROJECTS[@]}"; do
    PROJECT_DIR="${PROJECTS_BASE}/${PROJECT}"
    WORKFLOW_FILE="${PROJECT_DIR}/.github/workflows/build-deploy-dev.yml"

    if [ ! -d "$PROJECT_DIR" ]; then
        warn "项目目录不存在: $PROJECT_DIR"
        continue
    fi

    log "处理项目: $PROJECT"

    # 1. 备份原有的post-task.sh
    if [ -f "${PROJECT_DIR}/script/post-task.sh" ]; then
        BACKUP_FILE="${PROJECT_DIR}/script/post-task.sh.backup.$(date +%Y%m%d)"
        cp "${PROJECT_DIR}/script/post-task.sh" "$BACKUP_FILE"
        log "  已备份原脚本: $BACKUP_FILE"
    fi

    # 2. 更新CI/CD配置
    if [ -f "$WORKFLOW_FILE" ]; then
        # 检查是否已经迁移过
        if grep -q "/home/ubuntu/projects/.github/scripts/post-task.sh" "$WORKFLOW_FILE"; then
            log "  CI/CD配置已是最新，跳过"
        else
            # 创建临时文件进行替换
            sed -i 's|bash script/post-task.sh|bash /home/ubuntu/projects/.github/scripts/post-task.sh|g' "$WORKFLOW_FILE"
            log "  已更新CI/CD配置"
        fi
    else
        warn "  CI/CD配置文件不存在: $WORKFLOW_FILE"
    fi

    # 3. 删除项目本地的post-task.sh（可选，默认不删除）
    if [ "${DELETE_OLD:-false}" == "true" ] && [ -f "${PROJECT_DIR}/script/post-task.sh" ]; then
        rm "${PROJECT_DIR}/script/post-task.sh"
        log "  已删除本地post-task.sh"
    fi

    log "  完成"
done

log "批量迁移完成！"
log "提示：如需删除项目本地的post-task.sh，请设置环境变量 DELETE_OLD=true 后重新运行"
