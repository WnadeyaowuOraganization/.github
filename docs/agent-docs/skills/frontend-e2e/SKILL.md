---
name: frontend-e2e
description: End-to-end test Wande-Play frontend pages with Playwright in the isolated kimi environment (backend :810N, frontend :710N). Covers smoke template generation (cp _template.spec.ts), 3 anti-regression assertions, ant-tabs HTMLElement.click workaround for AntDV 4.x, Drawer/Modal assertions with v-model:open, screenshot capture for evidence, single-worker execution, and failure diagnostics via trace reports.
---

# 前端 E2E 测试

前端改动的**最终验证**。必须在**自己的 kimi 独立环境**（`:810N` backend / `:710N` frontend）执行，严禁占用主 Dev 环境（`:8080`）。

## 环境

| 资源 | kimiN 值 |
|------|---------|
| 后端 | `http://localhost:810N`（kimi1=8101 ...）|
| 前端 | `http://localhost:710N`（kimi1=7101 ...）|
| 登录 | `admin` / `admin123` / tenant `000000` |
| e2e 目录 | `/data/home/ubuntu/projects/wande-play-kimiN/e2e`（**不在 frontend 下**）|
| Playwright 依赖 | `e2e/node_modules/playwright/...` |

## 启动环境

```bash
cd /data/home/ubuntu/projects/wande-play-kimiN
bash e2e/scripts/start-all.sh        # 一键拉起 backend + frontend
# 或分开：
bash e2e/scripts/start-backend.sh &
cd frontend && pnpm dev --port 710N --host 0.0.0.0 &
# 等前端日志出现 "ready in ..." + 后端日志 "Started RuoYiApplication"
```

## 前端 smoke 用例（强制：views/**/index.vue 必补，约束 7）

改动 `frontend/apps/web-antd/src/views/**/index.vue` → 必须有对应 smoke。

### 生成方式

```bash
cd /data/home/ubuntu/projects/wande-play-kimiN/e2e
cp tests/front/smoke/_template.spec.ts tests/front/smoke/<module>-page.spec.ts
# 编辑新文件，替换 ROUTE / PAGE_NAME 等占位符
```

### 3 条反事故断言（保留，#3487 教训）

```ts
import { test, expect } from '@playwright/test';

const ROUTE = '/business/tender/project-mine';
const PAGE_NAME = '项目挖掘';

test.describe(`smoke: ${PAGE_NAME}`, () => {
  test('页面可渲染', async ({ page }) => {
    await page.goto('http://localhost:7101/login');
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL('**/workbench');

    await page.goto(`http://localhost:7101${ROUTE}`);

    // 反事故 1：页面容器渲染（非白屏）
    await expect(page.locator('.ant-page-container, [class*="Page"]')).toBeVisible();

    // 反事故 2：vxe 表格或主布局存在（非空 body）
    await expect(
      page.locator('.vxe-table, .ant-table, .vxe-grid').first()
    ).toBeVisible({ timeout: 10000 });

    // 反事故 3：无控制台错误 / slot 返回 HTML 字符串报错
    const errors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    await page.waitForTimeout(2000);
    expect(errors.filter((e) => !e.includes('favicon'))).toHaveLength(0);
  });
});
```

## E2E spec 执行

```bash
cd /data/home/ubuntu/projects/wande-play-kimiN/e2e
npx playwright test tests/front/e2e/<spec>.spec.ts \
  --project=e2e-tests --workers=1 --reporter=list
```

**强制 `--workers=1`**：多 worker 会抢占登录 session 导致 flaky。

## 目录约定

```
e2e/tests/
├── front/
│   ├── smoke/           # 编程CC 自己写的 smoke（最小反事故）
│   │   ├── _template.spec.ts
│   │   └── <module>-page.spec.ts
│   └── e2e/             # 完整业务回归（E2E CC 或 issue 特定）
│       └── <module>-regression.spec.ts
├── backend/
│   ├── smoke/
│   └── api/
└── top-e2e/             # 顶层全量 E2E
```

## AntDV 4.x Tabs 点击（#3626 教训）

Playwright `page.click('.ant-tabs-tab')` 在某些 AntDV 4.x 版本不触发切换。**workaround**：

```ts
// 用 HTMLElement.click() 原生触发
await page.locator('[data-node-key="tasks"]').evaluate((el: HTMLElement) => el.click());

// 或 page.evaluate 版本
await page.evaluate((sel) => {
  (document.querySelector(sel) as HTMLElement)?.click();
}, '[data-node-key="tasks"]');
```

优先用 `data-node-key` 定位（稳定），避免按文本（国际化会改）。

## Modal / Drawer 断言

```ts
// 打开 Modal
await page.getByRole('button', { name: /新增/ }).click();
await expect(page.locator('.ant-modal-title')).toHaveText('新增项目');
await page.fill('input#title', '测试项目');
await page.getByRole('button', { name: /确\s*定/ }).click();  // 中文按钮名注意空格

// 打开 Drawer（v-model:open）
await page.click('.ant-table-row >> text=项目A');
await expect(page.locator('.ant-drawer-title')).toContainText('详情');
```

## 表格行选中

```ts
const rows = page.locator('.vxe-table--main-wrapper .vxe-body--row');
await rows.nth(0).locator('.vxe-checkbox--icon').click();
await rows.nth(1).locator('.vxe-checkbox--icon').click();
```

## 截图作为证据

spec 过程中：

```ts
await page.screenshot({ path: '/tmp/step1-form.png', fullPage: true });
```

最终上传到 Release 作为 PR 证据，见 pr-visual-proof skill。

## 失败诊断

```bash
# 1. HTML trace
npx playwright show-report

# 2. 单步调试
npx playwright test tests/front/e2e/<spec>.spec.ts --headed --debug

# 3. 看 error context
cat test-results/<spec>-<case>/error-context.md
```

- 失败截图自动存 `test-results/<spec>/*.png`
- `trace: 'retain-on-failure'` 保留完整交互录像

## 常见陷阱

| 陷阱 | 解法 |
|------|------|
| `page.click('.ant-tabs-tab')` 不切换 | 用 `el.click()` evaluate（见上） |
| 表格 loading 时断言元素 | `page.waitForSelector('.vxe-loading', { state: 'hidden' })` |
| Modal 关闭前检查表格已刷新 | `await page.waitForResponse(r => r.url().includes('/list'))` |
| 登录 session 共享失败 | `storageState` 保存登录态，测前加载 |
| 中文按钮名带全角空格 | 用 regex `name: /确\s*定/` |
| `waitForTimeout(N)` 偶现 flaky | 换 `waitForSelector` / `waitForLoadState` |

## 禁止

- ❌ 连主 Dev 环境 `:8080` 跑 Playwright（污染共享数据）
- ❌ 改 `playwright.config.ts` 的 baseURL 绕过环境隔离
- ❌ 用 `waitForTimeout` 替代 `waitForSelector`
- ❌ 并行 worker > 1（session 抢占）
- ❌ 复制 spec 不改环境端口
- ❌ 新建 views/**/index.vue 不加 smoke（quality-gate 门 4 拦截）

## 自检清单（提 PR 前）

- [ ] smoke spec 文件存在 `e2e/tests/front/smoke/<module>-page.spec.ts`
- [ ] 3 条反事故断言保留（页面渲染 / 表格可见 / 无控制台 error）
- [ ] spec 通过 `npx playwright test` 绿灯
- [ ] 若涉及 Drawer / Tabs → 用 `v-model:open` / `data-node-key` 断言
- [ ] 失败截图 / trace 已检查
- [ ] 结果贴到 task.md 相应步骤勾选
