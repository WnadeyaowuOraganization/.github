#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# verify-issue-implementation.sh — Issue需求与代码实现对齐校验脚本
# 用途：防止Issue被错误关闭或代码未覆盖需求中的关键接口
#
# 用法：
#   bash verify-issue-implementation.sh <repo> <issue_number> [mode]
#   repo: backend | front | pipeline | plugins
#   mode: code-exists (默认) | pr-check

set -e

REPO=$1
ISSUE=$2
MODE=${3:-code-exists}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/get-gh-token.sh"

case "$REPO" in
  backend)   BASE_DIR="wande-play/backend"; REPO_FULL="WnadeyaowuOraganization/wande-play" ;;
  frontend)  BASE_DIR="wande-play/frontend"; REPO_FULL="WnadeyaowuOraganization/wande-play" ;;
  pipeline)  BASE_DIR="wande-play/pipeline"; REPO_FULL="WnadeyaowuOraganization/wande-play" ;;
  plugins)   BASE_DIR="wande-gh-plugins"; REPO_FULL="WnadeyaowuOraganization/wande-gh-plugins" ;;
  *)         echo "Unknown repo: $REPO"; exit 1 ;;
esac

PROJECT_DIR="${HOME_DIR}/projects/${BASE_DIR}"
ISSUE_INFO_FILE="/tmp/issue_${ISSUE}_info.json"
REPORT_FILE="/tmp/verify_issue_${ISSUE}_report.md"

echo "# Issue #${ISSUE} 实现完整性校验报告" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- 校验模式: ${MODE}" >> "$REPORT_FILE"
echo "- 仓库: ${REPO}" >> "$REPORT_FILE"
echo "- 时间: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ===================== Step 1: 拉取Issue信息 =====================
echo "拉取 Issue #${ISSUE} 信息..."
GH_TOKEN=$(bash "${SCRIPT_DIR}/get-gh-token.sh")
GH_TOKEN="$GH_TOKEN" gh issue view "${ISSUE}" \
    --repo "${REPO_FULL}" \
    --json title,body,state > "$ISSUE_INFO_FILE" 2>/dev/null || {
    echo "❌ 无法拉取Issue #${ISSUE}信息" >> "$REPORT_FILE"
    cat "$REPORT_FILE"
    exit 1
}

ISSUE_TITLE=$(jq -r '.title' "$ISSUE_INFO_FILE")
ISSUE_BODY=$(jq -r '.body' "$ISSUE_INFO_FILE")
ISSUE_STATE=$(jq -r '.state' "$ISSUE_INFO_FILE")

echo "## Issue 基本信息" >> "$REPORT_FILE"
echo "- 标题: ${ISSUE_TITLE}" >> "$REPORT_FILE"
echo "- 状态: ${ISSUE_STATE}" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ===================== Step 2: 从Issue body中提取关键API路径 =====================
# 匹配模式：GET/POST/PUT/DELETE + 空格 + /path（去掉query string）
API_PATHS=$(echo "$ISSUE_BODY" | grep -oP '(GET|POST|PUT|DELETE)\s+/[^ ]+' | sed 's/\?.*//' | sort -u || true)

# 匹配模式：Controller 类名（如 DashboardEfficiencyController）
CONTROLLER_NAMES=$(echo "$ISSUE_BODY" | grep -oP '[A-Z][a-zA-Z0-9]*Controller' | sort -u || true)

# 匹配模式：Service 类名（如 DashboardEfficiencyService）
SERVICE_NAMES=$(echo "$ISSUE_BODY" | grep -oP '[A-Z][a-zA-Z0-9]*Service' | sort -u || true)

echo "## 从需求文档中提取的关键实现点" >> "$REPORT_FILE"
if [ -n "$API_PATHS" ]; then
    echo "### API 路径" >> "$REPORT_FILE"
    echo "$API_PATHS" | sed 's/^/- /' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi
if [ -n "$CONTROLLER_NAMES" ]; then
    echo "### Controller 类" >> "$REPORT_FILE"
    echo "$CONTROLLER_NAMES" | sed 's/^/- /' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi
if [ -n "$SERVICE_NAMES" ]; then
    echo "### Service 类" >> "$REPORT_FILE"
    echo "$SERVICE_NAMES" | sed 's/^/- /' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

if [ -z "$API_PATHS" ] && [ -z "$CONTROLLER_NAMES" ] && [ -z "$SERVICE_NAMES" ]; then
    echo "ℹ️ 未从Issue body中提取到明确的API路径或类名，跳过代码存在性检查。" >> "$REPORT_FILE"
    echo "建议：在Issue body中使用明确的 `GET /api/xxx/xxx` 或 `XxxController` 格式描述需求。" >> "$REPORT_FILE"
    cat "$REPORT_FILE"
    rm -f "$ISSUE_INFO_FILE" "$REPORT_FILE"
    exit 0
fi

# ===================== Step 3: 校验 =====================
MISSING_COUNT=0

echo "## 校验结果" >> "$REPORT_FILE"

# --- 3.1 检查 Controller 文件 ---
if [ -n "$CONTROLLER_NAMES" ]; then
    echo "### Controller 文件检查" >> "$REPORT_FILE"
    for name in $CONTROLLER_NAMES; do
        if [ "$MODE" = "pr-check" ]; then
            # 检查 PR diff 中是否包含该文件
            BRANCH=$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD)
            FOUND=$(cd "$PROJECT_DIR" && git diff --name-only "dev...${BRANCH}" | grep -i "${name}.java" || true)
        else
            # 检查代码库中是否存在该文件
            FOUND=$(find "$PROJECT_DIR" -name "${name}.java" -type f 2>/dev/null | head -1 || true)
        fi
        if [ -n "$FOUND" ]; then
            echo "✅ ${name} — 找到" >> "$REPORT_FILE"
        else
            echo "❌ ${name} — 未找到" >> "$REPORT_FILE"
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

# --- 3.2 检查 Service 文件 ---
if [ -n "$SERVICE_NAMES" ]; then
    echo "### Service 文件检查" >> "$REPORT_FILE"
    for name in $SERVICE_NAMES; do
        if [ "$MODE" = "pr-check" ]; then
            BRANCH=$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD)
            FOUND=$(cd "$PROJECT_DIR" && git diff --name-only "dev...${BRANCH}" | grep -iE "(${name}|I${name}|${name}Impl)\.java" || true)
        else
            FOUND=$(find "$PROJECT_DIR" \( -name "${name}.java" -o -name "I${name}.java" -o -name "${name}Impl.java" \) -type f 2>/dev/null | head -1 || true)
        fi
        if [ -n "$FOUND" ]; then
            echo "✅ ${name} — 找到" >> "$REPORT_FILE"
        else
            echo "❌ ${name} — 未找到" >> "$REPORT_FILE"
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done
    echo "" >> "$REPORT_FILE"
fi

# --- 3.3 检查 API Mapping（从代码中搜索 @GetMapping/@PostMapping 等） ---
if [ -n "$API_PATHS" ]; then
    echo "### API Mapping 检查" >> "$REPORT_FILE"
    while IFS= read -r api; do
        [ -z "$api" ] && continue
        METHOD=$(echo "$api" | awk '{print $1}')
        URL_PATH=$(echo "$api" | awk '{print $2}')
        # 去掉路径参数 {id}，用通配符搜索
        SEARCH_PATTERN=$(echo "$URL_PATH" | sed 's/{[^}]*}/[^\/]*/g')
        FOUND=$(find "$PROJECT_DIR" -name "*.java" -type f -print0 2>/dev/null | xargs -0 grep -rn "@.*Mapping.*\"${SEARCH_PATTERN}\"" 2>/dev/null | head -1 || true)

        # 如果没找到完整路径，尝试拆分 Controller 前缀 + endpoint
        if [ -z "$FOUND" ]; then
            PREFIX=$(echo "$URL_PATH" | sed 's|/[^/]*$||')
            ENDPOINT=$(echo "$URL_PATH" | sed 's|^.*/[^/]*|\0|' | sed 's|^.*\(/[^/]*\)$|\1|')
            # 上面 sed 处理 ENDPOINT 比较绕，用 awk 更稳：最后一个 / 后面的内容
            ENDPOINT="/${URL_PATH##*/}"
            if [ -n "$PREFIX" ] && [ "$PREFIX" != "$URL_PATH" ]; then
                CONTROLLER_FILE=$(find "$PROJECT_DIR" -name "*.java" -type f -print0 2>/dev/null | xargs -0 grep -rl "@RequestMapping.*\"${PREFIX}\"" 2>/dev/null | head -1 || true)
                if [ -n "$CONTROLLER_FILE" ]; then
                    FOUND=$(grep -rn "@${METHOD}Mapping.*\"${ENDPOINT}\"" "$CONTROLLER_FILE" 2>/dev/null | head -1 || true)
                    if [ -z "$FOUND" ]; then
                        # 再试不区分大小写的 method（GET -> Get）
                        FOUND=$(grep -rn "@.*Mapping.*\"${ENDPOINT}\"" "$CONTROLLER_FILE" 2>/dev/null | head -1 || true)
                    fi
                fi
            fi
        fi

        if [ -n "$FOUND" ]; then
            echo "✅ ${METHOD} ${URL_PATH} — 找到 mapping" >> "$REPORT_FILE"
        else
            echo "❌ ${METHOD} ${URL_PATH} — 未找到对应的 @Mapping" >> "$REPORT_FILE"
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done <<< "$API_PATHS"
    echo "" >> "$REPORT_FILE"
fi

# ===================== Step 4: 总结 =====================
echo "## 总结" >> "$REPORT_FILE"
if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "✅ 所有提取到的关键实现点均已找到，校验通过。" >> "$REPORT_FILE"
else
    echo "❌ 发现 ${MISSING_COUNT} 个缺失项。该 Issue 的实现不完整，不允许关闭或合并。" >> "$REPORT_FILE"
fi

cat "$REPORT_FILE"
rm -f "$ISSUE_INFO_FILE" "$REPORT_FILE"

if [ "$MISSING_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
