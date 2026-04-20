---
name: quick-fix
description: Full-stack engineer skill for rapid fixes to the main test environment (http://localhost:8080). Push directly to dev branch to trigger CI/CD auto-deployment. Emphasizes think-before-act, minimal blast radius, and full traceability via GitHub Issues with before/after screenshots.
---

# Quick-Fix — 主测试环境快速修复

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
  // TODO: 导航到问题页面
  await page.goto('http://localhost:8080/<问题页面路径>');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: '/tmp/before-fix.png', fullPage: true });
  await browser.close();
  console.log('截图完成: /tmp/before-fix.png');
})();
EOF
npx ts-node --esm /tmp/before-screenshot.ts 2>/dev/null || \
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

每一条甲方要求都必须有对应的 Issue 留痕：

```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

# 上传 before 截图到 GitHub Release
gh release upload sprint-assets /tmp/before-fix.png \
  --repo WnadeyaowuOraganization/wande-play \
  --clobber 2>/dev/null
BEFORE_URL="https://github.com/WnadeyaowuOraganization/wande-play/releases/download/sprint-assets/before-fix.png"

# 创建 Issue
ISSUE_NUM=$(gh issue create \
  --repo WnadeyaowuOraganization/wande-play \
  --title "[Quick-Fix] <一句话描述问题>" \
  --body "## 甲方要求

<甲方原话或截图描述>

## 整改时间

$(date '+%Y-%m-%d %H:%M')

## 问题现象（修复前）

![修复前](${BEFORE_URL})

## 根因分析

<简要说明根因>

## 改动范围

- [ ] 后端：<文件路径>
- [ ] 前端：<文件路径>
- [ ] 数据库：<SQL语句>

## 修复后截图

（修复完成后补充）" \
  --label "quick-fix" \
  2>/dev/null | grep -oP '(?<=issues/)\d+')

echo "Issue #${ISSUE_NUM} 已创建"
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
-- Flyway 增量迁移文件命名
-- V{yyyyMMddHHmmss}__{snake_case_desc}.sql
-- 文件放在: backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/

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

### 3.3 本地验证

**后端**：
```bash
cd /data/home/ubuntu/projects/wande-play-quick-fix/backend
mvn -pl ruoyi-modules/wande-ai compile -q 2>&1 | tail -10
# 如有单测：mvn -pl ruoyi-modules/wande-ai test -Dtest=<TestClass> -q
```

**前端**：
```bash
cd /data/home/ubuntu/projects/wande-play-quick-fix/frontend
pnpm build 2>&1 | tail -5
# 或只做类型检查（更快）
pnpm vue-tsc --noEmit 2>&1 | tail -10
```

**数据库变更**：在本机 DB 先执行验证（如有测试 DB 权限）：
```bash
mysql -h 127.0.0.1 -u root -p<密码> <db_name> < /tmp/fix.sql
```

---

## 阶段四：推送 dev 触发部署

### 4.1 提交代码

```bash
cd /data/home/ubuntu/projects/wande-play-quick-fix

git add <只添加改动文件，禁止 git add .>
git commit -m "fix: <一句话描述> (quick-fix #${ISSUE_NUM})"
git push origin dev
```

### 4.2 观察 CI/CD（必须等待结果）

```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

# 等待 CI 开始（push 后约 10-30s）
sleep 15

# 获取最新 run
RUN_ID=$(gh run list --repo WnadeyaowuOraganization/wande-play \
  --branch dev --workflow build-deploy-dev.yml \
  --limit 1 --json databaseId -q '.[0].databaseId')

echo "CI Run: https://github.com/WnadeyaowuOraganization/wande-play/actions/runs/${RUN_ID}"

# 轮询等待完成（后端部署约 3-5 分钟）
while true; do
  STATUS=$(gh run view $RUN_ID \
    --repo WnadeyaowuOraganization/wande-play \
    --json status,conclusion -q '.status + "/" + (.conclusion // "pending")')
  echo "[$(date '+%H:%M:%S')] $STATUS"
  [[ "$STATUS" == "completed/"* ]] && break
  sleep 15
done

# 检查结果
CONCLUSION=$(gh run view $RUN_ID \
  --repo WnadeyaowuOraganization/wande-play \
  --json conclusion -q '.conclusion')
echo "结果: $CONCLUSION"
```

### 4.3 部署失败处理

```bash
# 查看失败日志
gh run view $RUN_ID --repo WnadeyaowuOraganization/wande-play --log-failed | head -50

# 后端健康检查
curl -sf http://localhost:6040/ && echo "后端正常" || echo "后端异常"

# 如后端挂了，手动回滚
if [ -f /apps/wande-ai-backend/ruoyi-admin.jar.bak ]; then
  cp /apps/wande-ai-backend/ruoyi-admin.jar.bak /apps/wande-ai-backend/ruoyi-admin.jar
  bash /apps/wande-ai-backend/start.sh
  echo "已回滚到上一版本"
fi
```

> ⚠️ **CI 失败时**：立即通知研发经理，说明失败原因和影响，不要独自尝试多次 push 修复。

---

## 阶段五：验证 + 补充 Issue

### 5.1 功能验证截图（after 截图）

```bash
cat > /tmp/after-screenshot.ts << 'EOF'
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
  await page.screenshot({ path: '/tmp/after-fix.png', fullPage: true });
  await browser.close();
  console.log('截图完成: /tmp/after-fix.png');
})();
EOF
node --loader ts-node/esm /tmp/after-screenshot.ts
```

### 5.2 更新 Issue（补充 after 截图 + 关闭）

```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

# 上传 after 截图
gh release upload sprint-assets /tmp/after-fix.png \
  --repo WnadeyaowuOraganization/wande-play --clobber
AFTER_URL="https://github.com/WnadeyaowuOraganization/wande-play/releases/download/sprint-assets/after-fix.png"

# 追评 Issue，附修复后截图
gh issue comment $ISSUE_NUM \
  --repo WnadeyaowuOraganization/wande-play \
  --body "## ✅ 修复完成

**部署时间**：$(date '+%Y-%m-%d %H:%M')
**CI Run**：https://github.com/WnadeyaowuOraganization/wande-play/actions/runs/${RUN_ID}

### 修复后效果

![修复后](${AFTER_URL})

### 改动摘要

\`\`\`
$(git log --oneline -1)
\`\`\`"

# 关闭 Issue
gh issue close $ISSUE_NUM \
  --repo WnadeyaowuOraganization/wande-play \
  --comment "Quick-fix 已部署到主测试环境，请甲方验收。"
```

---

## 快速参考卡

```
甲方反馈问题
    ↓
1. 追问到清楚（不猜测）
2. 复现 + before 截图
3. 创建 Issue
4. 读代码 → 定位根因
5. 最小改动 + 本地验证
6. git push origin dev
7. 等 CI 完成（3-5分钟）
8. after 截图 + 更新 Issue + 关闭
```

### 常用命令速查

```bash
# 同步最新 dev
cd /data/home/ubuntu/projects/wande-play-quick-fix
git fetch origin dev && git reset --hard origin/dev

# 刷新 GH Token
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

# 后端编译检查
cd backend && mvn -pl ruoyi-modules/wande-ai compile -q

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

| # | 红线 |
|---|------|
| 1 | 禁止不创建 Issue 就推代码 |
| 2 | 禁止不复现问题就动代码 |
| 3 | 禁止 `git add .`（必须逐文件 add，防止带入临时文件）|
| 4 | 禁止推送后不观察 CI 结果就汇报「修复完成」|
| 5 | 禁止 CI 失败后独自连续 push 尝试（最多 1 次修复尝试，失败立即汇报）|
| 6 | 禁止改动不相关功能代码 |
| 7 | 禁止 DROP TABLE / TRUNCATE（数据操作不可逆）|
| 8 | 禁止 INSERT sys_menu（用 UPDATE 占位菜单）|
| 9 | 禁止 Issue 没有 before/after 截图就关闭 |
| 10 | 禁止影响主环境超过 10 分钟不汇报研发经理 |
