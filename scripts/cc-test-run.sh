#!/bin/bash
# cc-test-run.sh — 编程CC本地E2E测试一键执行
#
# 编程CC完成代码修改后，调用此脚本在独立环境中完成：
#   编译(可选) → 启动后端 → 健康检查 → 执行E2E测试 → 输出结果 → 清理
#
# 用法:
#   cc-test-run.sh <kimi_tag> [选项]
#
# 选项:
#   --smoke          只跑smoke测试（默认）
#   --api            只跑后端API测试
#   --spec <file>    指定测试文件
#   --full           跑全部测试
#   --compile        先编译后端jar（否则复用现有jar）
#   --stop           测试后停止后端服务（默认常驻）
#   --workers <N>    并行度（默认4）
#
# 示例:
#   cc-test-run.sh kimi18                          # smoke测试
#   cc-test-run.sh kimi18 --api                    # API测试
#   cc-test-run.sh kimi18 --compile --full          # 编译+全量测试
#   cc-test-run.sh kimi18 --spec tests/backend/api/auth.spec.ts

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 参数解析 ===
KIMI_TAG="${1:-}"
shift 2>/dev/null || true

MODE="smoke"
DO_COMPILE=false
KEEP_ENV=true
WORKERS=4
SPEC_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --smoke)    MODE="smoke"; shift ;;
    --api)      MODE="api"; shift ;;
    --full)     MODE="full"; shift ;;
    --spec)     MODE="spec"; SPEC_FILE="$2"; shift 2 ;;
    --compile)  DO_COMPILE=true; shift ;;
    --stop)     KEEP_ENV=false; shift ;;
    --workers)  WORKERS="$2"; shift 2 ;;
    *)          echo "未知参数: $1"; exit 1 ;;
  esac
done

if [ -z "$KIMI_TAG" ]; then
  echo "用法: $0 <kimi_tag> [--smoke|--api|--full|--spec <file>] [--compile] [--keep]"
  exit 1
fi

# === 路径解析 ===
KIMI_DIR="${HOME_DIR}/projects/wande-play-${KIMI_TAG}"
E2E_DIR="${KIMI_DIR}/e2e"
PRODUCT_DIR="/apps/wande-ai-backend-${KIMI_TAG}"

if [ ! -d "$KIMI_DIR" ]; then
  echo "❌ kimi目录不存在: $KIMI_DIR"
  exit 1
fi

# 获取端口
KIMI_NUM=$(echo "$KIMI_TAG" | grep -oE '[0-9]+$')
BACKEND_PORT=$((7100 + KIMI_NUM))

STARTED_BY_US=false
START_TIME=$(date +%s)

FRONTEND_PORT_DISPLAY=$((8100 + KIMI_NUM))
echo "═══════════════════════════════════════════"
echo "  E2E测试 — ${KIMI_TAG}"
echo "  后端:${BACKEND_PORT} 前端:${FRONTEND_PORT_DISPLAY}"
echo "  模式: ${MODE}  编译: ${DO_COMPILE}"
echo "═══════════════════════════════════════════"

# === Step 1: 编译（可选）===
if [ "$DO_COMPILE" = true ]; then
  echo ""
  echo "▶ [1/4] 编译后端..."
  cd "$KIMI_DIR/backend" || exit 1

  # 使用共享Maven缓存
  MAVEN_REPO="${HOME_DIR}/.m2/repository"
  mvn clean package -Pprod -DskipTests -T 1C -B \
    -Dmaven.repo.local="$MAVEN_REPO" 2>&1 | tail -5

  JAR_FILE=$(find ruoyi-admin/target -name "ruoyi-admin*.jar" -type f 2>/dev/null | head -1)
  if [ -z "$JAR_FILE" ]; then
    echo "❌ 编译失败：未找到jar产物"
    exit 1
  fi

  mkdir -p "$PRODUCT_DIR"
  cp -f "$JAR_FILE" "$PRODUCT_DIR/ruoyi-admin.jar"
  echo "✅ 后端编译完成"

  # 编译前端（如果前端目录存在）
  FRONT_DIR="/apps/wande-ai-front-${KIMI_TAG}"
  if [ -d "$KIMI_DIR/frontend" ]; then
    echo "  编译前端..."
    cd "$KIMI_DIR/frontend"
    PNPM_STORE="${HOME_DIR}/.pnpm-store"
    pnpm install --store-dir "$PNPM_STORE" --frozen-lockfile 2>/dev/null || pnpm install --store-dir "$PNPM_STORE" 2>/dev/null
    pnpm build 2>&1 | tail -3
    if [ -d "apps/web-antd/dist" ]; then
      mkdir -p "$FRONT_DIR"
      rsync -a --delete apps/web-antd/dist/ "$FRONT_DIR/"
      echo "✅ 前端编译完成"
    fi
  fi
else
  echo ""
  echo "▶ [1/4] 跳过编译（复用现有产物）"

  # 确保产物目录有jar
  if [ ! -f "$PRODUCT_DIR/ruoyi-admin.jar" ]; then
    mkdir -p "$PRODUCT_DIR"
    if [ -f /apps/wande-ai-backend/ruoyi-admin.jar ]; then
      cp -f /apps/wande-ai-backend/ruoyi-admin.jar "$PRODUCT_DIR/ruoyi-admin.jar"
      echo "  从dev环境复制jar"
    else
      echo "❌ 无可用jar文件，请使用 --compile 参数"
      exit 1
    fi
  fi
fi

# === Step 2: 启动测试环境 ===
echo ""
echo "▶ [2/4] 启动测试环境..."

# 检查环境是否已在运行
ENV_STATUS=$(bash "$SCRIPT_DIR/cc-test-env.sh" status "$KIMI_TAG" 2>/dev/null || echo "STOPPED")

if echo "$ENV_STATUS" | grep -q "RUNNING"; then
  echo "  环境已在运行，复用"
else
  STARTED_BY_US=true
  bash "$SCRIPT_DIR/cc-test-env.sh" start "$KIMI_TAG"
  if [ $? -ne 0 ]; then
    echo "❌ 环境启动失败"
    exit 1
  fi
fi

# === Step 3: 执行E2E测试 ===
echo ""
echo "▶ [3/4] 执行E2E测试 (mode=${MODE}, workers=${WORKERS})..."

cd "$E2E_DIR" || { echo "❌ E2E目录不存在: $E2E_DIR"; exit 1; }

# 确保依赖已安装
if [ ! -d "node_modules" ]; then
  echo "  安装依赖..."
  npm ci --silent 2>/dev/null || npm install --silent 2>/dev/null
fi

# 设置环境变量指向独立后端
FRONTEND_PORT=$((8100 + KIMI_NUM))
export BASE_URL_API="http://localhost:${BACKEND_PORT}"
export BASE_URL_FRONT="http://localhost:${FRONTEND_PORT}"
export CI=false

# 构建测试命令
TEST_CMD="npx playwright test"
TEST_ARGS="--reporter=list --timeout=60000 --workers=${WORKERS}"

case "$MODE" in
  smoke)
    TEST_CMD="$TEST_CMD tests/front/smoke/ tests/backend/api/auth.spec.ts $TEST_ARGS"
    ;;
  api)
    TEST_CMD="$TEST_CMD tests/backend/api/ $TEST_ARGS"
    ;;
  full)
    TEST_CMD="$TEST_CMD $TEST_ARGS"
    ;;
  spec)
    if [ -z "$SPEC_FILE" ]; then
      echo "❌ --spec 需要指定文件"
      exit 1
    fi
    TEST_CMD="$TEST_CMD $SPEC_FILE $TEST_ARGS"
    ;;
esac

echo "  $TEST_CMD"
echo "---"

# 执行测试
TEST_EXIT=0
eval "$TEST_CMD" 2>&1 || TEST_EXIT=$?

echo "---"

# === Step 4: 结果汇总 ===
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "▶ [4/4] 测试结果"
echo "═══════════════════════════════════════════"

if [ $TEST_EXIT -eq 0 ]; then
  echo "  ✅ 测试通过"
else
  echo "  ❌ 测试失败 (exit=$TEST_EXIT)"

  # 如果有JSON报告，解析失败数
  REPORT_FILE="test-results/reports/results.json"
  if [ -f "$REPORT_FILE" ]; then
    python3 -c "
import json, sys
try:
    with open('$REPORT_FILE') as f:
        data = json.load(f)
    suites = data.get('suites', [])
    total = passed = failed = 0
    def count(s):
        global total, passed, failed
        for spec in s.get('specs', []):
            for test in spec.get('tests', []):
                total += 1
                if test.get('status') == 'expected':
                    passed += 1
                else:
                    failed += 1
        for child in s.get('suites', []):
            count(child)
    for s in suites:
        count(s)
    print(f'  通过: {passed}/{total}  失败: {failed}')
except:
    pass
" 2>/dev/null
  fi

  # 显示失败截图路径
  if ls test-results/*-*/ 2>/dev/null | head -1 >/dev/null 2>&1; then
    echo ""
    echo "  失败截图:"
    find test-results -name "*.png" -newer "$PRODUCT_DIR/logs/backend.log" 2>/dev/null | head -5 | while read f; do
      echo "    $f"
    done
  fi
fi

echo ""
echo "  耗时: ${ELAPSED}秒"
echo "  后端: http://localhost:${BACKEND_PORT}"
echo "  日志: ${PRODUCT_DIR}/logs/backend.log"
echo "═══════════════════════════════════════════"

# === 清理 ===
if [ "$KEEP_ENV" = false ] && [ "$STARTED_BY_US" = true ]; then
  echo ""
  echo "清理测试环境..."
  bash "$SCRIPT_DIR/cc-test-env.sh" stop "$KIMI_TAG"
fi

exit $TEST_EXIT
