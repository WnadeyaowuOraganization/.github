#!/bin/bash

################################################################################
# Quick-Fix 工具库 — 自动化脚本和函数集合
# 版本：1.1（2026-04-21）
# 用途：快速修复流程的强制验证、部署、回滚、截图等自动化
# 注意：本文件设计为被 source 到交互 shell，不可用 set -e（会导致 shell 退出）
################################################################################

# ============================================================================
# 全局配置
# ============================================================================

REPO="WnadeyaowuOraganization/wande-play"
QF_DIR="/data/home/ubuntu/projects/wande-play-quick-fix"
E2E_DIR="/data/home/ubuntu/projects/wande-play-e2e-top"
BACKEND_PORT=6040
FRONTEND_URL="http://localhost:8080"
BACKEND_URL="http://localhost:${BACKEND_PORT}"

# 日志颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# 【优化1】GH Token 一次性初始化（流程开头调用一次）
# ============================================================================

function init-gh-token() {
  if [ -z "$GH_TOKEN" ]; then
    export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py 2>/dev/null)
    if [ -z "$GH_TOKEN" ]; then
      echo -e "${RED}❌ Failed to get GH_TOKEN${NC}"
      return 1
    fi
    echo -e "${GREEN}✅ GH_TOKEN initialized${NC}"
  fi
  return 0
}

# ============================================================================
# dev 分支同步 — push 前必须调用，避免冲突和重复构建
# ============================================================================

function sync-dev() {
  cd "$QF_DIR"

  # 确保 remote URL 使用最新 token
  if [ -n "$GH_TOKEN" ]; then
    git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git" 2>/dev/null
  fi

  git fetch origin dev -q
  local behind=$(git rev-list HEAD..origin/dev --count 2>/dev/null || echo 0)

  if [ "$behind" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  dev 分支落后 $behind 个commit，正在同步...${NC}"
    local has_changes=0
    git diff --quiet 2>/dev/null || has_changes=1

    if [ "$has_changes" -eq 1 ]; then
      git stash -q 2>/dev/null
    fi

    if ! git rebase origin/dev -q 2>/dev/null; then
      echo -e "${RED}❌ rebase 冲突，中止 rebase 并恢复${NC}"
      git rebase --abort 2>/dev/null
      if [ "$has_changes" -eq 1 ]; then
        git stash pop -q 2>/dev/null || true
      fi
      echo -e "${RED}请手动解决冲突后再 push${NC}"
      return 1
    fi

    if [ "$has_changes" -eq 1 ]; then
      git stash pop -q 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ 已同步到最新 dev (合入 $behind 个commit)${NC}"
  else
    echo -e "${GREEN}✅ dev 已是最新${NC}"
  fi
  return 0
}

# ============================================================================
# 【优化1】本地验证 Gate — 强制 backend compile 和 frontend build
# ============================================================================

function verify-backend() {
  local module="${1:-ruoyi-modules/wande-ai}"
  echo -e "${BLUE}⏳ Verifying backend compilation: $module${NC}"

  cd "$QF_DIR/backend"
  # 使用共享 Maven 本地仓库（quick-fix 是 fresh clone，本地无 parent 模块）
  local m2_repo="/home/ubuntu/.m2/repository"
  if ! mvn -pl "$module" compile -q -Dmaven.repo.local="$m2_repo" 2>&1 | tail -20 > /tmp/mvn-error.log; then
    echo -e "${RED}❌ Backend compilation failed:${NC}"
    cat /tmp/mvn-error.log
    return 1
  fi

  echo -e "${GREEN}✅ Backend compilation OK${NC}"
  return 0
}

function verify-frontend() {
  local timeout=60
  echo -e "${BLUE}⏳ Verifying frontend build (${timeout}s timeout)${NC}"

  cd "$QF_DIR/frontend"

  # 类型检查（比完整 build 快 10x）
  if ! timeout $timeout pnpm vue-tsc --noEmit 2>&1 | tail -20 > /tmp/tsc-error.log; then
    echo -e "${RED}❌ Frontend type check failed:${NC}"
    cat /tmp/tsc-error.log
    return 1
  fi

  echo -e "${GREEN}✅ Frontend type check OK${NC}"
  return 0
}

function verify-local() {
  echo -e "${BLUE}========== Local Verification Gate ==========${NC}"

  verify-backend "$1" || return 1
  verify-frontend || return 1

  echo -e "${GREEN}✅ All local verifications passed — Ready to push${NC}"
  return 0
}

# ============================================================================
# 【优化3】CI 轮询函数化 + 指数退避
# ============================================================================

function wait-ci-complete() {
  local run_id=$1
  local max_wait=${2:-600}  # 默认 10 分钟超时
  local elapsed=0
  local wait_interval=15

  if [ -z "$run_id" ]; then
    echo -e "${RED}❌ Usage: wait-ci-complete <RUN_ID> [MAX_WAIT_SECONDS]${NC}"
    return 1
  fi

  echo -e "${BLUE}⏳ Waiting for CI to complete (Run: $run_id, timeout: ${max_wait}s)${NC}"

  while [ $elapsed -lt $max_wait ]; do
    local status_line=$(gh run view "$run_id" \
      --repo "$REPO" \
      --json status,conclusion 2>/dev/null | jq -r '"status=\(.status) conclusion=\(.conclusion // "pending")"' || echo "status=error conclusion=error")

    echo "[$(date '+%H:%M:%S')] $status_line"

    if echo "$status_line" | grep -q "status=completed"; then
      if echo "$status_line" | grep -q "conclusion=success"; then
        echo -e "${GREEN}✅ CI completed successfully${NC}"
        return 0
      else
        echo -e "${RED}❌ CI failed${NC}"
        return 1
      fi
    fi

    # 指数退避：15s + 随机 0-10s 抖动
    sleep $((wait_interval + RANDOM % 10))
    elapsed=$((elapsed + wait_interval + 5))
  done

  echo -e "${RED}❌ CI timeout after ${max_wait}s${NC}"
  return 2
}

# ============================================================================
# 【优化2】部署失败回滚 — 后端 + 前端 + DB 检查
# ============================================================================

function rollback-backend() {
  echo -e "${YELLOW}⏳ Rolling back backend...${NC}"

  if [ ! -f /apps/wande-ai-backend/ruoyi-admin.jar.bak ]; then
    echo -e "${RED}❌ No backup JAR found${NC}"
    return 1
  fi

  pkill -9 -f "java.*ruoyi-admin.jar.*${BACKEND_PORT}" 2>/dev/null || true
  sleep 2

  cp /apps/wande-ai-backend/ruoyi-admin.jar.bak /apps/wande-ai-backend/ruoyi-admin.jar
  bash /apps/wande-ai-backend/start.sh 2>/dev/null || true

  sleep 5
  if curl -sf "$BACKEND_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend rolled back and healthy${NC}"
    return 0
  else
    echo -e "${RED}❌ Backend still unhealthy after rollback${NC}"
    return 1
  fi
}

function rollback-frontend() {
  echo -e "${YELLOW}⏳ Rolling back frontend...${NC}"

  if [ ! -f /apps/wande-ai-front/dist.bak.tar ]; then
    echo -e "${YELLOW}⚠️  No frontend backup found (skipping)${NC}"
    return 0
  fi

  cd /apps/wande-ai-front
  rm -rf js css _app.config.js index.html
  tar -xf dist.bak.tar
  nginx -s reload 2>/dev/null || true

  sleep 3
  if curl -sf "$FRONTEND_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend rolled back and healthy${NC}"
    return 0
  else
    echo -e "${RED}❌ Frontend still unhealthy after rollback${NC}"
    return 1
  fi
}

function health-check() {
  echo -e "${BLUE}⏳ Checking health...${NC}"

  local backend_ok=0
  local frontend_ok=0

  if curl -sf "$BACKEND_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ Backend: OK${NC}"
    backend_ok=1
  else
    echo -e "${RED}  ❌ Backend: DOWN${NC}"
  fi

  if curl -sf "$FRONTEND_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ Frontend: OK${NC}"
    frontend_ok=1
  else
    echo -e "${RED}  ❌ Frontend: DOWN${NC}"
  fi

  [ $backend_ok -eq 1 ] && [ $frontend_ok -eq 1 ]
}

function rollback-complete() {
  echo -e "${YELLOW}🔄 Starting complete rollback...${NC}"

  rollback-backend || true
  rollback-frontend || true

  if health-check; then
    echo -e "${GREEN}✅ Complete rollback successful${NC}"
    return 0
  else
    echo -e "${RED}❌ Rollback incomplete — manual intervention needed${NC}"
    return 1
  fi
}

# ============================================================================
# 【优化5】截图函数库 — 参数化 before/after 截图
# ============================================================================

function take-screenshot() {
  local url=$1
  local output_file=$2
  local login_user=${3:-admin}
  local login_pass=${4:-admin123}
  local wait_ms=${5:-2000}
  local viewport_width=${6:-1440}
  local viewport_height=${7:-900}

  if [ -z "$url" ] || [ -z "$output_file" ]; then
    echo -e "${RED}❌ Usage: take-screenshot <URL> <OUTPUT_FILE> [LOGIN_USER] [LOGIN_PASS] [WAIT_MS] [WIDTH] [HEIGHT]${NC}"
    return 1
  fi

  local tmpscript="/tmp/screenshot-$$.mjs"

  cat > "$tmpscript" << 'SCRIPT_EOF'
import { chromium } from '/data/home/ubuntu/projects/wande-play-e2e-top/e2e/node_modules/playwright/index.mjs';

const url = process.argv[2];
const output = process.argv[3];
const user = process.argv[4];
const pass = process.argv[5];
const waitMs = parseInt(process.argv[6]);
const width = parseInt(process.argv[7]);
const height = parseInt(process.argv[8]);

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width, height } });

  try {
    await page.goto('http://localhost:8080/login', { waitUntil: 'networkidle' });
    await page.fill('input[placeholder*="账号"]', user);
    await page.fill('input[placeholder*="密码"]', pass);
    await page.click('button[type="submit"]');
    await page.waitForTimeout(2000);

    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(waitMs);

    await page.screenshot({ path: output, fullPage: true });
    console.log(`✅ Screenshot saved: ${output}`);
  } catch (err) {
    console.error(`❌ Screenshot failed: ${err.message}`);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
SCRIPT_EOF

  echo -e "${BLUE}⏳ Taking screenshot: $url → $output_file${NC}"

  cd "$E2E_DIR/e2e"
  if node "$tmpscript" "$url" "$output_file" "$login_user" "$login_pass" "$wait_ms" "$viewport_width" "$viewport_height"; then
    rm -f "$tmpscript"
    echo -e "${GREEN}✅ Screenshot OK: $output_file${NC}"
    return 0
  else
    rm -f "$tmpscript"
    echo -e "${RED}❌ Screenshot failed${NC}"
    return 1
  fi
}

function upload-release-asset() {
  local file=$1
  local filename=$(basename "$file")

  if [ ! -f "$file" ]; then
    echo -e "${RED}❌ File not found: $file${NC}"
    return 1
  fi

  echo -e "${BLUE}⏳ Uploading to GitHub Release: $filename${NC}"

  if gh release upload sprint-assets "$file" \
    --repo "$REPO" \
    --clobber 2>/dev/null; then
    local url="https://github.com/$REPO/releases/download/sprint-assets/$filename"
    echo -e "${GREEN}✅ Uploaded: $url${NC}"
    echo "$url"
    return 0
  else
    echo -e "${RED}❌ Upload failed${NC}"
    return 1
  fi
}

# ============================================================================
# 【优化6】Issue 模板按类型分化
# ============================================================================

function create-issue-frontend() {
  local title=$1
  local before_url=$2
  local description=$3

  local body="## 甲方要求

$description

## 问题类型

🖼️ 前端页面问题 (样式 / 交互 / 渲染)

## 修复前截图

![Before]($before_url)

## 改动文件

- [ ] 前端：

## 修复后截图

(待修复后补充)

---

**修复前时间**：$(date '+%Y-%m-%d %H:%M')
"

  gh issue create \
    --repo "$REPO" \
    --title "[Quick-Fix] $title" \
    --body "$body" \
    --label "quick-fix,frontend" 2>/dev/null | grep -oP '(?<=issues/)\d+'
}

function create-issue-api() {
  local title=$1
  local before_url=$2
  local description=$3
  local endpoint=${4:-""}

  local body="## 甲方要求

$description

## 问题类型

🔌 API / 后端问题 (接口报错 / 返回值异常 / 逻辑错误)

## 问题现象

**Endpoint**: \`$endpoint\`

![Before]($before_url)

## 根因分析

(修复时填充)

## 改动文件

- [ ] 后端：

## 修复后验证

- [ ] API 返回 200 OK
- [ ] 数据正确
- [ ] 无副作用

---

**修复前时间**：$(date '+%Y-%m-%d %H:%M')
"

  gh issue create \
    --repo "$REPO" \
    --title "[Quick-Fix] $title" \
    --body "$body" \
    --label "quick-fix,backend" 2>/dev/null | grep -oP '(?<=issues/)\d+'
}

function create-issue-data() {
  local title=$1
  local before_url=$2
  local description=$3
  local table_name=${4:-""}

  local body="## 甲方要求

$description

## 问题类型

💾 数据异常 (数据库数据错误 / 计算异常 / 一致性问题)

## 受影响表

\`\`\`sql
SELECT COUNT(*) FROM $table_name WHERE <条件>;
\`\`\`

![Before]($before_url)

## 修复方案

\`\`\`sql
-- Flyway 迁移脚本
-- V{yyyyMMddHHmmss}__{desc}.sql
UPDATE $table_name SET ... WHERE ...;
\`\`\`

## 修复前后对比

(修复后补充)

---

**修复前时间**：$(date '+%Y-%m-%d %H:%M')
"

  gh issue create \
    --repo "$REPO" \
    --title "[Quick-Fix] $title" \
    --body "$body" \
    --label "quick-fix,data" 2>/dev/null | grep -oP '(?<=issues/)\d+'
}

function comment-issue-fixed() {
  local issue_num=$1
  local after_url=$2
  local run_id=${3:-""}

  local ci_link=""
  if [ -n "$run_id" ]; then
    ci_link="**CI Run**: https://github.com/$REPO/actions/runs/$run_id"
  fi

  local body="## ✅ 修复完成

**部署时间**: $(date '+%Y-%m-%d %H:%M')
$ci_link

### 修复后效果

![After]($after_url)

### 改动摘要

\`\`\`
$(git log --oneline -1)
\`\`\`
"

  gh issue comment "$issue_num" \
    --repo "$REPO" \
    --body "$body"
}

function close-issue-fixed() {
  local issue_num=$1

  gh issue close "$issue_num" \
    --repo "$REPO" \
    --comment "✅ Quick-fix 已部署到主测试环境。请甲方验收。"
}

# ============================================================================
# 综合流程编排（全自动化示例）
# ============================================================================

function quickfix-workflow() {
  local issue_type=$1  # frontend | api | data
  local before_page_url=$2
  local after_page_url=$3
  local description=$4
  local title=$5

  echo -e "${BLUE}========== Quick-Fix Workflow ==========${NC}"

  # 1. 初始化
  init-gh-token || return 1

  # 2. 本地验证
  verify-local || return 1

  # 3. 创建 Issue
  echo -e "${BLUE}📝 Creating GitHub Issue...${NC}"
  local before_img="/tmp/before-${RANDOM}.png"
  take-screenshot "$before_page_url" "$before_img" || return 1
  local before_url=$(upload-release-asset "$before_img") || return 1

  local issue_num=""
  case "$issue_type" in
    frontend) issue_num=$(create-issue-frontend "$title" "$before_url" "$description") ;;
    api)      issue_num=$(create-issue-api "$title" "$before_url" "$description") ;;
    data)     issue_num=$(create-issue-data "$title" "$before_url" "$description") ;;
    *)        echo -e "${RED}❌ Unknown issue type: $issue_type${NC}"; return 1 ;;
  esac

  echo -e "${GREEN}✅ Issue created: #$issue_num${NC}"

  # 4. 推送到 dev（禁止 git add . — 必须逐文件 add）
  echo -e "${BLUE}📤 Pushing to dev...${NC}"
  echo -e "${YELLOW}⚠️  请手动执行 git add <逐文件> 后再调用此函数的后续步骤${NC}"
  echo -e "${RED}⛔ 禁止 git add . — 必须逐文件添加，防止带入临时文件${NC}"
  cd "$QF_DIR"
  git status --short
  echo -e "${BLUE}请确认以上文件均为本次修复涉及的文件，然后执行:${NC}"
  echo "  git add <file1> <file2> ..."
  echo "  git commit -m \"fix: $title (quick-fix #$issue_num)\""
  echo "  git push origin dev"
  return 0  # 交还控制权给用户手动 add/commit/push

  # 5. 等待 CI
  echo -e "${BLUE}⏳ Waiting for CI...${NC}"
  sleep 15

  local run_id=$(gh run list --repo "$REPO" --branch dev --workflow build-deploy-dev.yml \
    --limit 1 --json databaseId -q '.[0].databaseId')

  if ! wait-ci-complete "$run_id"; then
    echo -e "${RED}❌ CI failed — attempting rollback${NC}"
    rollback-complete
    return 1
  fi

  # 6. 验证修复
  echo -e "${BLUE}🔍 Verifying fix...${NC}"
  sleep 5

  local after_img="/tmp/after-${RANDOM}.png"
  take-screenshot "$after_page_url" "$after_img" || return 1
  local after_url=$(upload-release-asset "$after_img") || return 1

  # 7. 更新并关闭 Issue
  comment-issue-fixed "$issue_num" "$after_url" "$run_id"
  close-issue-fixed "$issue_num"

  echo -e "${GREEN}========== ✅ Quick-Fix Complete ==========${NC}"
  echo -e "${GREEN}Issue #$issue_num is fixed and deployed${NC}"
}

# ============================================================================
# 导出所有函数
# ============================================================================

# ============================================================================
# 帮助函数
# ============================================================================

function utils-help() {
  cat << 'HELP_EOF'
════════════════════════════════════════════════════════════════════════════
Quick-Fix Utils Library v1.1 — 快速修复工具库
════════════════════════════════════════════════════════════════════════════

【初始化】
  init-gh-token                    初始化 GitHub Token（一次性）

【强制验证】 ⛔ 不通过禁止 push
  verify-backend [module]          后端编译检查（默认 ruoyi-modules/wande-ai）
  verify-frontend                  前端类型检查（pnpm vue-tsc）
  verify-local [module]            完整验证 gate（后端 + 前端，失败停止）

【CI/CD 观察】 ⏳ 自动轮询 + 智能重试
  wait-ci-complete <RUN_ID> [MAX_WAIT]  轮询至完成（指数退避，最多 MAX_WAIT 秒）

【回滚恢复】 🔄 完整恢复流程
  rollback-backend                 后端回滚至最后一个备份 JAR
  rollback-frontend                前端回滚至 dist.bak.tar
  health-check                     检查后端 + 前端健康状态
  rollback-complete                完整回滚（后端 + 前端 + 验证）

【截图上传】 📸 参数化截图
  take-screenshot <URL> <OUTPUT> [USER] [PASS] [WAIT] [WIDTH] [HEIGHT]
                                   自动登录 + 截图（参数化）
  upload-release-asset <FILE>      上传到 GitHub Release（返回 URL）

【Issue 创建】 📝 按类型分化
  create-issue-frontend <title> <before_url> <description>
                                   创建前端问题 Issue（含样式模板）
  create-issue-api <title> <before_url> <description> [endpoint]
                                   创建 API 问题 Issue（含接口模板）
  create-issue-data <title> <before_url> <description> [table]
                                   创建数据问题 Issue（含 SQL 模板）

【Issue 关闭】 ✅ 自动评论 + 关闭
  comment-issue-fixed <issue> <after_url> [run_id]
                                   评论修复结果 + 自动截图
  close-issue-fixed <issue>        标记已关闭，等待甲方验收

【完整流程】 🚀 全自动化
  quickfix-workflow <type> <before_url> <after_url> <desc> <title>
                                   type: frontend|api|data
                                   一键完成：验证→Issue→push→CI→回滚→验证

════════════════════════════════════════════════════════════════════════════

【快速参考】

  # 1. 初始化
  source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/utils.sh
  init-gh-token

  # 2. 复现问题 + 记录 before
  take-screenshot "http://localhost:8080/crm/xxx" "/tmp/before.png"
  BEFORE_URL=$(upload-release-asset "/tmp/before.png")

  # 3. 创建 Issue
  ISSUE_NUM=$(create-issue-frontend "页面样式错位" "$BEFORE_URL" "甲方反馈...")

  # 4. 本地验证（强制 gate）
  verify-local "ruoyi-modules/wande-ai" || exit 1

  # 5. 推送
  git add <file>
  git commit -m "fix: 问题描述 (quick-fix #$ISSUE_NUM)"
  git push origin dev

  # 6. 等待 CI
  sleep 15
  RUN_ID=$(gh run list --repo WnadeyaowuOraganization/wande-play --branch dev --workflow build-deploy-dev.yml --limit 1 --json databaseId -q '.[0].databaseId')
  wait-ci-complete "$RUN_ID" || rollback-complete

  # 7. 验证 + 关闭
  take-screenshot "http://localhost:8080/crm/xxx" "/tmp/after.png"
  AFTER_URL=$(upload-release-asset "/tmp/after.png")
  comment-issue-fixed "$ISSUE_NUM" "$AFTER_URL" "$RUN_ID"
  close-issue-fixed "$ISSUE_NUM"

════════════════════════════════════════════════════════════════════════════
HELP_EOF
}

# ============================================================================
# 导出所有函数
# ============================================================================

export -f init-gh-token sync-dev
export -f verify-backend verify-frontend verify-local
export -f wait-ci-complete
export -f rollback-backend rollback-frontend health-check rollback-complete
export -f take-screenshot upload-release-asset
export -f create-issue-frontend create-issue-api create-issue-data
export -f comment-issue-fixed close-issue-fixed
export -f quickfix-workflow
export -f utils-help

# 加载时自动提示帮助（可选）
# echo -e "${BLUE}💡 Tip: 执行 utils-help 查看完整函数列表${NC}"
