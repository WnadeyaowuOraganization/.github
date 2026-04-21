---
name: quick-fix
description: Full-stack engineer skill for rapid fixes to the main test environment (http://localhost:8080). Push directly to dev branch to trigger CI/CD auto-deployment. Emphasizes think-before-act, minimal blast radius, and full traceability via GitHub Issues with before/after screenshots. Use this skill whenever the user mentions bugs in test env, client complaints, quick patches, urgent fixes, mock data cleanup, or any change that must deploy immediately without going through the feature branch + PR workflow. NOT for feature development, refactoring, or cross-module restructuring.
---

# Quick-Fix — 主测试环境快速修复

> **快速开始**：
> ```bash
> source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh
> init-gh-token
> verify-local  # 必须通过才能 push
> wait-ci-complete "$RUN_ID"  # 自动轮询至完成或超时
> rollback-complete  # CI 失败时自动回滚
> ```

> **适用场景**：甲方在主测试环境（`http://localhost:8080`）发现问题，需要直接修复并立即生效，不走 feature 分支 + PR 流程，直接推 `dev` 触发 CI/CD 部署。
>
> **工作目录**：`/data/home/ubuntu/projects/wande-play-quick-fix`（专用目录，不与研发经理的 wande-play 主目录冲突）
>
> **角色**：全栈工程师 — 后端 + 前端均可修改，以最小改动快速交付为原则。

---

## 阶段一：理解需求（动手前必做，禁止跳过）

### 1.1 彻底读懂甲方要求

收到问题反馈后，**先不要看代码**，先完整理解以下内容：

- 甲方描述的**现象**是什么（页面表现 / 接口报错 / 数据异常）
- 甲方期望的**正确行为**是什么
- 是否有截图 / 视频 / 操作步骤

**如有任何不清晰，立即追问甲方**，宁可多问一次，不要猜测后改错：

```
不清楚就问，常见追问场景：
- 「哪个菜单 / 哪个页面」
- 「操作步骤是什么」
- 「期望结果是什么样的」
- 「是所有账号都有问题还是特定账号」
```

### 1.2 复现问题（建立事实基准）

在动代码之前，用 Playwright 截图记录**现象**（before 截图），作为 Issue 的 before 证据：

**🆕 使用工具函数（推荐）**：
```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 自动登录 + 截图（参数化）
take-screenshot \
  "http://localhost:8080/crm/customer/list" \
  "/tmp/before-fix.png" \
  "admin" \
  "admin123" \
  2000 \
  1440 \
  900
```

**或手动脚本**：
```bash
cat > /tmp/before-screenshot.ts << 'EOF'
import { chromium } from '/data/home/ubuntu/projects/wande-play-e2e-top/e2e/node_modules/playwright';
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://localhost:8080/login');
  await page.fill('input[placeholder*="账号"]', 'admin');
  await page.fill('input[placeholder*="密码"]', 'admin123');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(2000);
  await page.goto('http://localhost:8080/<问题页面路径>');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: '/tmp/before-fix.png', fullPage: true });
  await browser.close();
})();
EOF
node --loader ts-node/esm /tmp/before-screenshot.ts
```

### 1.3 阅读相关代码（定位根因）

**只读与问题直接相关的代码**，不要漫游整个代码库：

```bash
cd /data/home/ubuntu/projects/wande-play-quick-fix
git fetch origin dev && git reset --hard origin/dev

# 按问题类型定位代码
# 前端页面问题 → 找对应 views 目录
find frontend/apps/web-antd/src/views -name "*.vue" | xargs grep -l "<关键词>" 2>/dev/null

# 后端接口问题 → 找 Controller
find backend/ruoyi-modules/wande-ai/src -name "*Controller.java" | xargs grep -l "<接口路径关键词>" 2>/dev/null

# 数据问题 → 查 DB
# mysql -u root -p wande_play -e "SELECT ... FROM <表名> WHERE ..."
```

确认根因后，评估改动范围。**如果改动范围超出预期（涉及核心模块 / 多处联动），必须先向研发经理汇报再动手**。

---

## 阶段二：创建 Issue（动手前必做）

每一条甲方要求都必须有对应的 Issue 留痕。**按问题类型使用对应的 Issue 创建函数**：

**🆕 使用工具函数（推荐 — 自动化 + 模板分化）**：

```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 初始化 token（一次性）
init-gh-token

# 上传 before 截图
BEFORE_URL=$(upload-release-asset "/tmp/before-fix.png")

# 根据问题类型创建 Issue，自动填充对应模板
case "$PROBLEM_TYPE" in
  # 【优化6】前端问题 — 强调样式截图
  frontend)
    ISSUE_NUM=$(create-issue-frontend \
      "页面样式错误" \
      "$BEFORE_URL" \
      "用户反馈：CRM客户列表页面表头错位")
    ;;

  # 【优化6】API 问题 — 强调接口和返回值
  api)
    ISSUE_NUM=$(create-issue-api \
      "获取客户列表 API 超时" \
      "$BEFORE_URL" \
      "用户反馈：客户管理页面加载缓慢，API 返回 504" \
      "GET /api/crm/customer/list")
    ;;

  # 【优化6】数据问题 — 强调 SQL 和数据一致性
  data)
    ISSUE_NUM=$(create-issue-data \
      "客户数据不同步" \
      "$BEFORE_URL" \
      "用户反馈：新增客户后在报表中看不到" \
      "crm_customer")
    ;;
esac

echo "✅ Issue #$ISSUE_NUM created"
```

**或手动创建（不推荐，易遗漏细节）**：
```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)
gh release upload sprint-assets /tmp/before-fix.png --repo WnadeyaowuOraganization/wande-play --clobber
BEFORE_URL="https://github.com/WnadeyaowuOraganization/wande-play/releases/download/sprint-assets/before-fix.png"
ISSUE_NUM=$(gh issue create --repo WnadeyaowuOraganization/wande-play --title "[Quick-Fix] 标题" --body "..." --label "quick-fix" 2>/dev/null | grep -oP '(?<=issues/)\d+')
```

---

## 阶段三：修复代码

### 3.1 遵守开发规范（硬红线）

**后端规范（必读）**：

| 规则 | 说明 |
|------|------|
| 业务代码只在 `wande-ai` 模块 | 禁止改 `ruoyi-system` / `ruoyi-framework` 等基础模块 |
| 包路径 `org.ruoyi.wande.{feature}.*` | 禁止旧风格 `wande.domain.{feature}` |
| 新增 domain 包必须更新 `typeAliasesPackage` | `application.yml` 追加包名，否则 XML 别名 ClassNotFoundException |
| 禁止 `@DS` 注解 | 单库，无需多数据源 |
| 禁止 INSERT 新菜单 | 用 UPDATE 已有占位菜单 |
| Mapper 接口删除时同步删 XML | 否则启动报错 |

**前端规范（必读）**：

| 规则 | 说明 |
|------|------|
| 使用 `useVbenVxeGrid` | 禁止原生 a-table |
| 使用 `useVbenDrawer` | 禁止 a-modal 包裹业务 |
| vxe-table slot 必须返回 VNode | 禁止返回 HTML 字符串 |
| 禁止 `h()` 函数渲染 slot | 用 `<template #default="{ row }">` |
| 路由菜单用 UPDATE | 禁止 INSERT sys_menu |

**数据库规范**：

```sql
-- Flyway 增量迁移文件命名（时间戳必须精确到秒，禁止手动补0）
-- 先执行: TS=$(date +%Y%m%d%H%M%S)
-- 文件名: V${TS}__{snake_case_desc}.sql
-- 文件放在: backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/
-- ⛔ 禁止: date +%Y%m%d 然后手动补 000000（会导致多CC冲突）

-- 禁止在 quick-fix 中 DROP TABLE / TRUNCATE
-- 只允许: ALTER TABLE ADD COLUMN、UPDATE、INSERT（配置数据）
```

### 3.2 最小改动原则

```
✅ 只改与问题直接相关的文件
✅ 复用已有工具类 / 组件，不重造轮子
✅ 不顺手重构不相关代码
✅ 不顺手加「优化」「改进」

❌ 不相关文件不动
❌ 不修改配置文件（除非必须）
❌ 不升级依赖版本
```

### 3.3 本地验证 — 【优化1】强制 Gate（禁止不验证就推送）

**🆕 使用工具函数（推荐 — 自动化 + 强制拦截）**：
```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 一行命令通过所有验证，失败自动停止
verify-local "ruoyi-modules/wande-ai" || exit 1

echo "✅ 所有验证通过，可以 push"
```

**验证通过前，禁止执行以下命令**：
- ❌ `git push origin dev`
- ❌ `git commit -m ...`（会推送未验证代码）

**验证失败时的调试**：
```bash
# 后端编译详细错误
cd /data/home/ubuntu/projects/wande-play-quick-fix/backend
mvn -pl ruoyi-modules/wande-ai compile -Dmaven.repo.local=/home/ubuntu/.m2/repository 2>&1 | grep -A 20 "ERROR"

# 前端类型错误详细信息
cd /data/home/ubuntu/projects/wande-play-quick-fix/frontend
pnpm vue-tsc --noEmit 2>&1

# 数据库变更测试（如有权限）
mysql -h 127.0.0.1 -u root -p<password> <db_name> < backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/V*.sql
```

---

## 阶段四：推送 dev 触发部署

### 4.1 提交代码

> **push 前必须 sync-dev**：其他人可能已经push了新代码到dev，不同步会导致冲突或覆盖。

```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh
cd /data/home/ubuntu/projects/wande-play-quick-fix

# 1. 同步最新 dev（必做，检测远端新提交并 rebase）
sync-dev || exit 1

# 2. 必须逐文件 add，禁止 git add .（防止带入临时文件）
git add backend/ruoyi-modules/wande-ai/src/main/java/...
git add frontend/apps/web-antd/src/views/...
# ... 只添加改动文件

# 3. commit + push
git commit -m "fix: <一句话描述> (quick-fix #${ISSUE_NUM})"
git push origin dev
```

### 4.2 观察 CI/CD + 主动监听后端日志

> **重要**：不要被动等待CI轮询结果再去看日志。push后**立即主动监听后端启动日志**，能在健康检查失败前发现问题。

```bash
# 推送后立即开始监听后端日志（后台）
tail -f /apps/wande-ai-backend/logs/backend.log | grep -E "ERROR|Exception|Started|启动" &
LOG_PID=$!

# 同时轮询CI状态
sleep 15
RUN_ID=$(gh run list --repo WnadeyaowuOraganization/wande-play \
  --branch dev --workflow build-deploy-dev.yml \
  --limit 1 --json databaseId -q '.[0].databaseId')
echo "CI Run: https://github.com/WnadeyaowuOraganization/wande-play/actions/runs/${RUN_ID}"

# 轮询CI（最多10分钟）
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh
if wait-ci-complete "$RUN_ID" 600; then
  echo "✅ CI passed"
else
  echo "❌ CI failed"
  # 立即看日志定位原因
  tail -50 /apps/wande-ai-backend/logs/backend.log | grep -B5 "ERROR\|Exception"
  rollback-complete
fi

# 停止日志监听
kill $LOG_PID 2>/dev/null
```

**日志关注点**：
- `FlywayException` → SQL迁移脚本语法错误
- `BeanCreationException` → Spring Bean冲突（包扫描/重复注入）
- `ClassNotFoundException` → typeAliasesPackage 未更新
- `Started RuoYiApplication in` → 启动成功标志

**或手动观察（不推荐，不会自动回滚）**：
```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)
RUN_ID=$(gh run list --repo WnadeyaowuOraganization/wande-play --branch dev --workflow build-deploy-dev.yml --limit 1 --json databaseId -q '.[0].databaseId')
while true; do
  STATUS=$(gh run view $RUN_ID --repo WnadeyaowuOraganization/wande-play --json status,conclusion -q '.status + "/" + (.conclusion // "pending")')
  echo "[$(date '+%H:%M:%S')] $STATUS"
  [[ "$STATUS" == "completed/"* ]] && break
  sleep 15
done
```

### 4.3 部署失败处理 — 【优化2】自动回滚 + 完整检查

**🆕 使用工具函数（推荐 — 自动回滚后端 + 前端 + 验证）**：
```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 自动完整回滚
if ! rollback-complete; then
  echo "❌ Rollback incomplete — manual intervention required"
  # 通知研发经理
  exit 1
fi
```

**或手动回滚**：
```bash
# 后端回滚
pkill -9 -f "java.*6040"
cp /apps/wande-ai-backend/ruoyi-admin.jar.bak /apps/wande-ai-backend/ruoyi-admin.jar
bash /apps/wande-ai-backend/start.sh
sleep 5

# 前端回滚
pkill -9 -f nginx
cd /apps/wande-ai-front && tar -xf dist.bak.tar && nginx
sleep 3

# 验证
curl -sf http://localhost:6040 && curl -sf http://localhost:8080 && echo "✅ Rollback OK"
```

> **⛔ 红线**：CI 失败后，**最多尝试 1 次修复**，失败立即汇报研发经理。禁止连续多次 push 尝试修复。

---

## 阶段五：验证 + 补充 Issue

### 5.1 功能验证截图（after 截图）

**🆕 使用工具函数（推荐）**：
```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 自动登录 + 截图
take-screenshot \
  "http://localhost:8080/crm/customer/list" \
  "/tmp/after-fix.png" \
  "admin" \
  "admin123"

echo "✅ After 截图完成"
```

### 5.2 更新 Issue — 【优化6】按问题类型自动评论 + 关闭

**🆕 使用工具函数（推荐 — 自动填充改动摘要）**：
```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh

# 上传 after 截图
AFTER_URL=$(upload-release-asset "/tmp/after-fix.png")

# 自动评论 + 关闭 Issue
comment-issue-fixed "$ISSUE_NUM" "$AFTER_URL" "$RUN_ID"
close-issue-fixed "$ISSUE_NUM"

echo "✅ Issue #$ISSUE_NUM 已更新并关闭"
```

**或手动更新**：
```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)
gh release upload sprint-assets /tmp/after-fix.png --repo WnadeyaowuOraganization/wande-play --clobber
AFTER_URL="https://github.com/WnadeyaowuOraganization/wande-play/releases/download/sprint-assets/after-fix.png"
gh issue comment $ISSUE_NUM --repo WnadeyaowuOraganization/wande-play --body "## ✅ 修复完成\n\n![修复后](${AFTER_URL})\n\nCI: https://github.com/WnadeyaowuOraganization/wande-play/actions/runs/${RUN_ID}"
gh issue close $ISSUE_NUM --repo WnadeyaowuOraganization/wande-play
```

---

## 快速参考卡

```
甲方反馈问题
    ↓
1. source utils.sh && init-gh-token          ← 初始化工具库
2. 追问到清楚（不猜测）
3. take-screenshot 记录 before
4. create-issue-{frontend|api|data} 创建
5. 读代码 → 定位根因
6. 最小改动 + verify-local 强制验证通过    ← 【优化1】强制 gate
7. sync-dev && git add <逐文件> && commit && push  ← push前必须同步
8. tail -f 启动日志 + wait-ci-complete      ← 主动监听 + 轮询
9. take-screenshot 记录 after
10. comment-issue-fixed && close-issue-fixed ← 【优化6】自动评论
```

### 常用命令速查

```bash
# === 【推荐】使用工具库完整流程 ===
source /data/home/ubuntu/projects/.github/docs/agent-docs/hotfix-cc/quick-fix/scripts/utils.sh
init-gh-token
verify-local "ruoyi-modules/wande-ai"
wait-ci-complete "$RUN_ID"
rollback-complete

# === 【快捷】单个工具函数 ===
take-screenshot "http://localhost:8080/path" "/tmp/screen.png"
upload-release-asset "/tmp/screen.png"
verify-backend "ruoyi-modules/wande-ai"
verify-frontend

# === 【传统】原始命令 ===
# 同步最新 dev
cd /data/home/ubuntu/projects/wande-play-quick-fix && git fetch origin dev && git reset --hard origin/dev

# 刷新 GH Token
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

# 后端编译检查
cd backend && mvn -pl ruoyi-modules/wande-ai compile -q -Dmaven.repo.local=/home/ubuntu/.m2/repository

# 前端类型检查
cd frontend && pnpm vue-tsc --noEmit

# 查看最新部署日志
tail -50 /apps/wande-ai-backend/logs/backend.log

# 后端健康检查
curl -sf http://localhost:6040/ && echo "OK" || echo "DOWN"

# 前端部署状态
ls -la /apps/wande-ai-front/index.html
```

---

## ⛔ 红线清单（违反即停止，立即汇报研发经理）

| # | 红线 | 优化关联 |
|---|------|--------|
| 1 | 禁止不创建 Issue 就推代码 | 【优化6】Issue 按类型分化 |
| 2 | 禁止不复现问题就动代码 | 【优化5】take-screenshot |
| 3 | **禁止 `git add .`**（必须逐文件 add，防止带入临时文件）| |
| 4 | **禁止本地编译/类型检查失败就推送** | 【优化1】verify-local gate |
| 5 | 禁止推送后不观察 CI 结果就汇报「修复完成」| 【优化3】wait-ci-complete |
| 6 | **禁止 CI 失败后独自连续 push 尝试**（最多 1 次修复，失败立即汇报）| 【优化2】rollback-complete |
| 7 | 禁止改动不相关功能代码 | |
| 8 | 禁止 DROP TABLE / TRUNCATE（数据操作不可逆）| |
| 9 | 禁止 INSERT sys_menu（用 UPDATE 占位菜单）| |
| 10 | 禁止 Issue 没有 before/after 截图就关闭 | 【优化5】自动截图上传 |
| 11 | 禁止影响主环境超过 10 分钟不汇报研发经理 | 【优化2】自动回滚 |
| 12 | **禁止 Issue 创建时跳过模板**（必须选择问题类型） | 【优化6】按类型分化模板 |
