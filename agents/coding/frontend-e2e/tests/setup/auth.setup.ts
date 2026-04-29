/**
 * auth.setup.ts — 统一认证预热
 *
 * 运行时机：
 *   - playwright setup project（每次 test suite 启动前自动执行）
 *   - 手动：npx ts-node setup/auth.setup.ts [--env main|kimi<N>]
 *
 * 输出：
 *   /tmp/e2e-auth-state-main.json     ← 主环境（8080/6040），Top E2E + CC before 截图共用
 *   /tmp/e2e-auth-state-kimi<N>.json  ← 各 CC 自己的环境（810N/710N）
 *
 * 复用规则：每次 test suite 启动都重新认证，避免后端重启后 Redis session 失效
 * 导致旧 token 被复用（#3557 根因）。
 */

import { test as setup, expect } from '@playwright/test';

// ── 环境参数 ──────────────────────────────────────────────────────────────────
// run-cc.sh 注入：CC_TEST_FRONTEND_URL / KIMI_ID
// e2e_top_tier.sh / 手动运行时：E2E_ENV=main（默认）
const ENV_TAG   = process.env.KIMI_ID ? `kimi${process.env.KIMI_ID}` : (process.env.E2E_ENV || 'main');
const FE_URL    = process.env.CC_TEST_FRONTEND_URL || process.env.BASE_URL_FRONT || 'http://localhost:8080';
const AUTH_FILE = process.env.E2E_AUTH_STATE || `/tmp/e2e-auth-state-${ENV_TAG}.json`;

// ── Setup 用例 ────────────────────────────────────────────────────────────────
setup(`authenticate [${ENV_TAG}]`, async ({ page }) => {
  console.log(`⟳ 登录 ${FE_URL} → ${AUTH_FILE}`);

  await page.goto(`${FE_URL}/auth/login`, { waitUntil: 'domcontentloaded', timeout: 20000 });

  const accessToken = process.env.E2E_ACCESS_TOKEN || '';

  // 将 token 写入两种可能的 namespace 前缀（兼容旧/新前端版本）
  await page.evaluate(
    (token) => {
      const accessStore = {
        accessCodes: ['*:*:*'],
        accessToken: token,
        isLockScreen: false,
        refreshToken: token,
      };
      const prefixes = ['undefined-1.5.2-dev', 'vben-web-antd-1.5.2-dev'];
      for (const ns of prefixes) {
        localStorage.setItem(`${ns}-core-access`, JSON.stringify(accessStore));
        localStorage.setItem(`${ns}-preferences-locale`, JSON.stringify({ value: 'zh-CN' }));
      }
    },
    accessToken,
  );

  await page.fill('input[name="username"]', process.env.E2E_USER || 'admin');
  await page.fill('input[name="password"]', process.env.E2E_PASS || 'admin123');

  // 关闭可能遮挡登录按钮的升级提示弹窗
  try {
    const modal = page.locator('.ant-modal-wrap');
    await modal.waitFor({ state: 'visible', timeout: 3000 });
    const okBtn = page.locator('.ant-modal .ant-btn-primary, .ant-modal button:has-text("我知道了")');
    await okBtn.first().click();
    await page.waitForTimeout(500);
  } catch { /* 弹窗可能不存在，正常跳过 */ }

  // 点击登录按钮（优先 aria-label，兜底文字匹配，排除手机号/扫码按钮）
  const loginBtn =
    (await page.locator('button[aria-label="login"]').isVisible().catch(() => false))
      ? page.locator('button[aria-label="login"]')
      : page.locator('button:has-text("登录"):not(:has-text("手机号")):not(:has-text("扫码"))').first();
  await loginBtn.click();

  await page.waitForURL(url => !url.pathname.includes('/auth/login'), { timeout: 20000 });
  await page.waitForTimeout(1500); // 等动态路由加载完成

  // 验证登录成功（断言页面不再是登录页）
  expect(page.url()).not.toContain('/auth/login');

  // 保存 cookies + localStorage（含 token）
  await page.context().storageState({ path: AUTH_FILE });
  console.log(`✓ auth 已保存 ${AUTH_FILE}`);
});
