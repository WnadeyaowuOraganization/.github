# 前端UI测试覆盖提升方案

> 创建时间：2026-04-06
> 背景：现有 smoke test 仅验证路由不返回404，无法发现组件渲染错误、数据加载失败、交互功能异常等真实UI问题。

---

## 一、现状分析

### 当前测试体系

| 类型 | 数量 | 实际覆盖 |
|------|------|---------|
| Backend API 测试 | ~130 | 接口响应格式、状态码 |
| Frontend Smoke 测试 | ~55 | 页面路由存在（不含404） |
| E2E 测试 | 1 | 登录流程 |
| Journey 测试 | ~4 | 关键业务流程（部分跳过） |

### Smoke 测试的根本缺陷

现有 smoke test 模板只做了：
```typescript
const content = await page.content();
expect(content).not.toContain('404 Not Found');
expect(content).not.toContain('页面不存在');
```

**无法发现的问题类型：**
- JS 运行时错误（组件崩溃，页面白屏）
- API 接口报错，表格/列表显示空
- AntDV 版本破坏性变更（如 `visible` → `open`）导致弹窗失效
- 权限配置错误导致整模块消失
- 表单、按钮点击无响应

---

## 二、提升方案

### 方案A：升级 Smoke 模板（低成本，立竿见影）

在现有所有 smoke test 基础上新增3项标准检查：

**1. Console 错误捕获**
```typescript
const errors: string[] = [];
page.on('console', msg => {
  if (msg.type() === 'error') errors.push(msg.text());
});
// 在断言前：
const criticalErrors = errors.filter(e =>
  !e.includes('favicon') && !e.includes('ResizeObserver')
);
expect(criticalErrors, `页面 Console 错误: ${criticalErrors.join('; ')}`).toHaveLength(0);
```

**2. 核心容器元素存在**

每个 smoke test 额外断言页面核心结构存在（非空白）：
```typescript
// 主内容区有实质内容（不是纯白屏）
const mainContent = page.locator('.ant-layout-content, #app, main').first();
await expect(mainContent).toBeVisible();

// 如果是列表页：表格容器存在
const table = page.locator('.ant-table-wrapper, .vxe-table').first();
if (await table.count() > 0) {
  await expect(table).toBeVisible();
}
```

**3. 失败时自动截图**

playwright.config.ts 已配置 `screenshot: 'only-on-failure'`，确保 CI 上传 artifacts。

**改造方式：** 生成一个新版 smoke 模板，新 Issue 的 smoke test 按新模板编写，存量测试在批量 Issue 中改造。

---

### 方案B：交互验证（针对核心功能，高价值）

对关键功能页面，在 smoke test 之上增加**最小可用交互验证**：

**验证原则：** 不测数据正确性，只测"交互功能是否可达"。

**适用场景：** 带弹窗的表单页、带筛选的列表页、带 Tab 的详情页。

**标准交互 Spec 模板：**
```typescript
test('新建弹窗可打开 @smoke @interactive', async ({ page, request }) => {
  await loginAndGoto(page, request, '/target/path');
  
  // 点击"新建"按钮
  const addBtn = page.locator('button').filter({ hasText: /新建|添加|创建/ }).first();
  await expect(addBtn).toBeVisible();
  await addBtn.click();
  
  // 弹窗/抽屉出现
  const modal = page.locator('.ant-modal-content, .ant-drawer-content').first();
  await expect(modal).toBeVisible({ timeout: 3000 });
  
  // 关闭弹窗
  await page.keyboard.press('Escape');
  await expect(modal).not.toBeVisible({ timeout: 2000 });
});
```

**优先覆盖页面（P0）：**
- 超管驾驶舱：问题新建、分配、关闭流程
- CRM模块：客户/商机新建弹窗
- 审批中心：审批操作按钮可点
- 预算管理：新建/编辑弹窗

---

### 方案C：视觉回归（PR级，发现布局变化）

使用 Playwright 内置截图对比，在 PR 合并前对关键页面进行截图比对。

**实现方式：**
```typescript
// 在 playwright.config.ts 中添加 visual 项目
{
  name: 'visual-regression',
  testMatch: /tests\/visual\/.*\.spec\.ts/,
  use: {
    ...devices['Desktop Chrome'],
    screenshot: 'on',
  },
  snapshotPathTemplate: '{testDir}/__snapshots__/{testFilePath}/{arg}{ext}',
}
```

**Spec 示例：**
```typescript
test('驾驶舱首页视觉回归 @visual', async ({ page, request }) => {
  await loginAndGoto(page, request, '/super-admin/cockpit');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(1000); // 等动画结束
  
  // 仅对核心区域截图（避免动态数据干扰）
  const mainArea = page.locator('.cockpit-layout, .ant-layout-content').first();
  await expect(mainArea).toMatchSnapshot('cockpit-main.png', {
    maxDiffPixelRatio: 0.05, // 允许5%差异（动态数字）
    mask: [page.locator('.realtime-data, .timestamp')], // 屏蔽动态区域
  });
});
```

**难点：** baseline 管理需要在 CI 中持久化，首次运行需要人工确认 baseline 截图。适合稳定页面，不适合数据高度动态的页面。

---

## 三、实施建议

### 优先级

| 方案 | 实施成本 | 发现价值 | 优先级 |
|------|---------|---------|--------|
| A：Console错误 + 元素存在 | 低（改模板即可） | 中（能发现白屏/崩溃） | **P0，立即推进** |
| B：交互验证 | 中（按页面逐一编写） | 高（能发现弹窗失效） | P1，与Issue同步编写 |
| C：视觉回归 | 高（需baseline维护） | 中（易误报） | P2，选稳定页面试点 |

### 落地方式

**方案A（改造存量）：**
- 生成新版 `smoke-test-template.ts`（见 `docs/agent-docs/frontend/smoke-test-template.ts`）
- 在 frontend CLAUDE.md 中要求所有新 smoke test 使用新模板
- 存量 55 个 smoke test 作为一个专项 Issue 批量改造

**方案B（随 Issue 生产）：**
- 在 issue-workflow.md 的 E2E 章节中增加：凡是新增带弹窗/表单的页面，**必须**编写对应的交互 spec
- CC 在提 PR 时，若有新页面/弹窗功能，自动在 `tests/front/e2e/` 下新建对应 spec

**方案C（试点）：**
- 选 3~5 个功能稳定、无动态数据的页面（如登录页、用户管理页）做视觉回归试点
- 在 `tests/visual/` 目录下单独维护，不与 smoke/e2e 混合

---

## 四、Smoke 模板升级版本

保存在 `docs/agent-docs/frontend/smoke-test-template.ts`，CC 编写新 smoke test 时直接参照。

```typescript
// smoke-test-template.ts — v2 标准模板（含Console检查 + 元素可见性）
import { test, expect } from '@playwright/test';

const API_BASE = process.env.BASE_URL_API || 'http://localhost:6040';
const STORAGE_KEY = 'vben-web-antd-1.2.3-prod-core-access';

async function loginAndGoto(page: any, request: any, targetPath: string) {
  const response = await request.post(`${API_BASE}/auth/login`, {
    data: {
      username: process.env.TEST_USERNAME || 'admin',
      password: process.env.TEST_PASSWORD || 'admin123',
    },
  });
  const body = await response.json();
  const token = body.data.access_token;

  await page.goto('/');
  await page.waitForLoadState('domcontentloaded');
  await page.evaluate(
    ({ key, token }: { key: string; token: string }) => {
      localStorage.setItem(key, JSON.stringify({ accessToken: token, refreshToken: token, accessCodes: [] }));
    },
    { key: STORAGE_KEY, token },
  );
  await page.goto(targetPath);
  await page.waitForLoadState('networkidle');
}

// ─── 在 test.describe 内使用以下模式 ───

// 1. Console错误监听（在 beforeEach 中设置）
// const consoleErrors: string[] = [];
// test.beforeEach(async ({ page }) => {
//   page.on('console', msg => {
//     if (msg.type() === 'error') {
//       const text = msg.text();
//       // 过滤已知无害错误
//       if (!text.includes('favicon') && !text.includes('ResizeObserver')) {
//         consoleErrors.push(text);
//       }
//     }
//   });
// });

// 2. 标准断言组合
// test('XXX页面加载 @smoke @front @issue:front#NNN', async ({ page, request }) => {
//   await loginAndGoto(page, request, '/your/route/here');
//   await page.waitForTimeout(1500);
//
//   // A. 无 Console 错误
//   expect(consoleErrors, `Console错误: ${consoleErrors.join('; ')}`).toHaveLength(0);
//
//   // B. 无 404/错误页
//   const content = await page.content();
//   expect(content).not.toContain('404 Not Found');
//   expect(content).not.toContain('页面不存在');
//
//   // C. 主内容区可见（非白屏）
//   const mainContent = page.locator('.ant-layout-content, #app, main').first();
//   await expect(mainContent).toBeVisible();
//
//   // D. [可选] 如果是列表页，表格容器存在
//   // const table = page.locator('.ant-table-wrapper').first();
//   // await expect(table).toBeVisible();
//
//   // E. [可选] 页面标题/关键文字存在
//   // await expect(page.locator('h1, .page-title')).toContainText('你的页面标题');
// });
```

---

## 五、与 CC 编程流程的整合

在 `docs/agent-docs/issue-workflow.md` 的 E2E 章节补充以下约束：

1. **新 smoke test**：必须使用 v2 模板（含 Console 错误检查 + 主容器可见性）
2. **带弹窗/表单的新功能**：必须在 `tests/front/e2e/` 新建对应交互 spec，验证弹窗可打开/关闭
3. **视觉回归**：暂不强制，等 P2 试点完成后再推广
