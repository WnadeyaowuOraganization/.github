---
name: pr-visual-proof
description: Take browser screenshots from the kimi test environment (frontend 8101/8102 etc, admin/admin123), upload to GitHub Release as PR evidence, attach Markdown image references to PR body with before/after comparison, and run pr-body-lint.sh to pass quality-gate doors 2/3 (no unchecked boxes, no fake screenshot claims without matching images). Use before every gh pr create for any change under frontend/apps/web-antd/src/views/.
---

# PR 视觉证据

前端改动（`views/**`）的 PR body **必须**包含 Markdown 图片（quality-gate 门 3）。此 skill 覆盖：截图 → 上传 → 贴 PR body → 预检。

## 环境强制

**"after"/功能验证截图只能用自己的 kimi 测试环境**：

| 资源 | kimiN 值 | 登录 |
|------|---------|------|
| 前端 | `http://localhost:810N` | admin / admin123 |
| 后端 | `http://localhost:710N` | （token 走后端）|

**主环境 (`:6040` / `:8080`) 只读截图允许**（2026-04-14 起）：

- ✅ 修 bug 的**"修复前"对比图**可用主环境 `:6040` Playwright `goto` + `screenshot`
- ✅ 与线上 / 原型对照的参考截图
- ❌ 任何 POST/PUT/DELETE/PATCH（禁止创建/修改/删除数据）
- ❌ 主环境上做业务交互（填表、点提交、触发写接口）

硬红线：**"修复后"图（after）必须是自己 `:810N` 的截图**，不得用主环境冒充。

## 截图（Playwright）

### 单张截图脚本

```bash
cat > /tmp/screenshot.ts <<'EOF'
import { chromium } from '/data/home/ubuntu/projects/wande-play-kimiN/e2e/node_modules/playwright';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  await page.goto('http://localhost:8101/login');
  await page.fill('input[name="username"]', 'admin');
  await page.fill('input[name="password"]', 'admin123');
  await page.click('button[type="submit"]');
  await page.waitForURL('**/workbench');

  await page.goto('http://localhost:8101/business/tender/project-mine');
  await page.waitForSelector('.vxe-table--main-wrapper', { timeout: 10000 });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: '/tmp/after.png', fullPage: true });

  await browser.close();
})();
EOF
node --loader ts-node/esm /tmp/screenshot.ts
```

### 多步骤截图（展示交互）

覆盖关键节点：列表、弹窗打开、填表、提交后列表刷新。每步一张：

```ts
await page.screenshot({ path: '/tmp/01-list.png' });
await page.click('button:has-text("新增")');
await page.screenshot({ path: '/tmp/02-modal-open.png' });
await page.fill('#title', 'T');
await page.screenshot({ path: '/tmp/03-form-filled.png' });
await page.click('button:has-text("确定")');
await page.waitForResponse(r => r.url().includes('/list'));
await page.screenshot({ path: '/tmp/04-after-submit.png' });
```

## 上传到 Release

GitHub Release 作为静态图床（PR body 可直接用 URL）：

```bash
export GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py)
PR=3642  # 你的 PR 号

# 第一次建 release
gh release create screenshot-${PR} \
  --repo WnadeyaowuOraganization/wande-play \
  --title "Screenshots for PR #${PR}" \
  --notes "visual evidence" \
  /tmp/01-list.png /tmp/02-modal-open.png /tmp/03-form-filled.png /tmp/04-after-submit.png

# 追加新图
gh release upload screenshot-${PR} \
  --repo WnadeyaowuOraganization/wande-play /tmp/new.png

# 拿下载 URL
gh release view screenshot-${PR} --repo WnadeyaowuOraganization/wande-play --json assets \
  -q '.assets[] | "\(.name)\t\(.url)"'
```

## 贴 PR body

```markdown
## 截图证据

### 列表页
![列表](https://github.com/WnadeyaowuOraganization/wande-play/releases/download/screenshot-3642/01-list.png)

### 新增 Modal
![新增表单](.../02-modal-open.png)

### 前后对比（若修 bug）
**修复前：**
![before](.../before-list.png)
**修复后：**
![after](.../after-list.png)
```

追加到 PR body：

```bash
gh pr view ${PR} --repo WnadeyaowuOraganization/wande-play --json body -q .body > /tmp/pr-body.md
cat >> /tmp/pr-body.md <<'EOF'

## 截图证据
![列表](https://github.com/WnadeyaowuOraganization/wande-play/releases/download/screenshot-3642/01-list.png)
![新增](https://github.com/WnadeyaowuOraganization/wande-play/releases/download/screenshot-3642/02-modal-open.png)
EOF
gh pr edit ${PR} --repo WnadeyaowuOraganization/wande-play --body-file /tmp/pr-body.md
```

## 强制要求

改动涉及 `frontend/apps/web-antd/src/views/**` → PR body 必须至少 1 张 `![alt](https://....png)` 格式图片。否则 quality-gate 门 3 block。

**禁止假勾选**：勾了 "截图 / 视觉 / screenshot" 类文字，body 必须有对应 `![](.*\.png)`。勾没图 = 门 3 拦截。

## 预检脚本（提 PR 前跑）

```bash
# 把 PR body 草稿保存到文件
cat > /tmp/pr-body-draft.md <<'EOF'
# PR body 内容...
EOF

bash .claude/skills/pr-visual-proof/scripts/pr-body-lint.sh --pr-body-stdin --issue ${ISSUE} < /tmp/pr-body-draft.md
```

检查：

| 门 | 条件 |
|---|------|
| 门 1 | PR body 无 `- [ ]` 未勾选 |
| 门 2 | `issues/issue-<N>/task.md` 无 `- [ ]` 未勾选 |
| 门 3 | 前端改动 PR body 含 `![](.*\.png)` + 勾选"截图"类文字必有图 |
| 门 4 | 新增 `views/**/index.vue` 有对应 `e2e/tests/front/smoke/<module>-page.spec.ts` |

**任一 fail → 不要 `gh pr create`**，先补齐再跑预检。

## 标准 PR body 模板

```markdown
## 需求背景
Fixes #<Issue号>

## 改动清单
- 后端：新增 `POST /wande/project/mine/batchEvaluate`
- 前端：index.vue + batch-evaluate-modal.vue
- 数据库：V20260414001__xxx.sql

## 集成链
- [x] 前置 #3620 已合并
- [x] 依赖接口契约 shared/api-contracts/wande/project-mine.yaml 已更新

## 自测
- [x] 后端 `mvn compile` 通过
- [x] 后端 `mvn test -pl ruoyi-modules/wande-ai` 全绿
- [x] Playwright API spec `backend/api/<module>.spec.ts` 全绿（断 status+body+落库）
- [x] 前端 `pnpm build:antd` 全量构建通过（零错误）
- [x] Playwright smoke：`<module>-page.spec.ts` 绿灯
- [x] E2E：`<module>-regression.spec.ts` 绿灯

## 截图证据
![列表](https://github.com/.../screenshot-${PR}/01-list.png)
![Modal](https://github.com/.../screenshot-${PR}/02-modal.png)

## 验收对账（原型 §X.X）
- [x] 表格列 13 项与 01-all.html 一致
- [x] 批量操作下拉 4 项全部 enabled
```

## 反模式

- ❌ "修复后"/"功能实现"截图用主 Dev 环境（after 必须是 `:810N`）
- ❌ 在主环境做写操作凑截图（POST/PUT/DELETE 全禁）
- ❌ PR body 写"已截图"但没真图
- ❌ 图片只贴本地路径 `file:///tmp/...`
- ❌ 只贴一张总览图，关键交互步骤没截
- ❌ 修 bug 不贴前后对比
- ❌ 跳过 pr-body-lint 直接 `gh pr create`（被门 block 还要重推送）

## 与 gh pr create 的顺序

```bash
# 1. rebase dev（约束 8）
git fetch origin dev && git rebase origin/dev
git push --force-with-lease

# 2. 【前端必做】全量构建验证（门禁，失败则不允许继续提 PR）
# ⚠️ 本步骤仅在有前端改动时执行；纯后端 PR 可跳过
cd frontend && pnpm build:antd
# 若失败，常见根因：
#   - <script setup> 内含 JSX 语法（h()/defineComponent 调用）→ 改为 <template> 或去掉 setup 属性
#   - import 路径不存在（如 `#/adapter/modal`）→ 先 grep 确认文件存在再 import
# 修完后重跑此步，确认零错误再继续

# 3. 预检
bash .claude/skills/pr-visual-proof/scripts/pr-body-lint.sh --pr-body-stdin --issue ${ISSUE} < /tmp/pr-body-draft.md

# 4. 截图 + 上传（若是首次发 PR，先建 draft PR 拿 PR 号再上传）
gh release create screenshot-${PR} ...

# 5. 创建 PR（必须 --base dev）
gh pr create --repo WnadeyaowuOraganization/wande-play \
  --base dev --head feature-Issue-${ISSUE} \
  --title "feat(模块): 描述 #${ISSUE}" \
  --body-file /tmp/pr-body-draft.md

# 6. 轮询到 merged（约束 9）
while [ "$(gh pr view $PR --repo WnadeyaowuOraganization/wande-play --json state -q .state)" != "MERGED" ]; do
  sleep 180
done
```
