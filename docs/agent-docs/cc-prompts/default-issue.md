# CC Default Issue Prompt (v2)

> **版本历史**：
> - v1 (~2026-03): 只有一句话 `阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，按流程完成任务`
> - **v2 (2026-04-09)**: 基于 #3458 生态三 PR 平均 5.43/10 事故，追加 6 条硬约束 + quality-gate 提示
> - 引用方：`scripts/run-cc.sh` 第 196/210 行（fallback 到 v1 纯字符串）

---

阅读 `issues/issue-${ISSUE}/issue-source.md` 中的 Issue 内容，按流程完成任务。Issue 编号: #${ISSUE}

## 🚦 硬约束（违反任一项禁止提 PR，quality-gate 会自动拦截）

以下约束是 #3458 事故后从 blood 里学到的，任何一条违反都会导致 PR 被 auto-merge 的 quality-gate job 拒绝合并（门 1/2/3）：

### 1️⃣ task.md 必须全勾
提 PR 前 `issues/issue-${ISSUE}/task.md` 的所有 `- [ ]` steps **必须全部勾选为 `- [x]`**。

- ❌ 反例（#3118 事故）：CC 写 `- [ ] 实现前端关系网络Tab页面` 但未勾就提 PR
- ✅ 正确做法：如果某步真的无法完成，**拆分为追补 Issue**（`gh issue create`），在 task.md 注明「已拆分到 #XXXX」后**勾选原步骤**

### 2️⃣ PR body 所有 checkbox 必须勾选
`gh pr create --body` 的正文中不得存在任何 `- [ ]`，必须 `- [x]`。

- ❌ 反例（#3487 事故）：PR body 6 项手动 E2E 全未勾，auto-merge 照样合并
- ✅ 正确做法：每项 checkbox 必须真的执行过再勾；严禁「下一阶段」「待完善」「待 CI 验证」这类免责文字

### 3️⃣ 前端 PR 必须有视觉验证截图
任何修改 `frontend/apps/web-antd/src/views/**` 的 PR，body 必须包含至少一张 Markdown 图片 `![](.*\.(png|jpg))`。

- ❌ 反例（#3487 事故）：data.ts 里 slot 返回 HTML 字符串，页面显示源代码，但没人打开页面看
- ✅ 正确做法：
  1. 本地 `pnpm dev` 或连 Dev 环境 `http://3.211.167.122:8083`
  2. 用 admin/admin123 登录
  3. 打开你改过的页面路由，截图（`xdotool` 或 Playwright headless）
  4. 上传到 PR body：`![trust-level-column](/tmp/<screenshot>.png)` 或用 `gh pr comment` 附图

### 4️⃣ vxe-table slot 必须返回 VNode，不得返回 HTML 字符串
vxe-table 的 `slots.default` 函数返回值会被 Vue 3 当成文本节点插入 DOM，返回 HTML 字符串 = 页面显示源代码。

- ❌ 反例（#3487 事故 data.ts:445）：
  ```ts
  slots: { default: ({ row }) => `<a-tag color="${color}">${label}</a-tag>` }  // 页面显示 <a-tag>...</a-tag>
  ```
- ✅ 正确做法（二选一）：
  - **模板插槽**（推荐）：
    ```ts
    // data.ts
    slots: { default: 'trustLevel' }
    // index.vue <BasicTable> 内
    <template #trustLevel="{ row }"><a-tag :color="row.trustColor">{{ row.trustLabel }}</a-tag></template>
    ```
  - **h 函数**：
    ```ts
    import { h } from 'vue'; import { Tag as ATag } from 'ant-design-vue';
    slots: { default: ({ row }) => h(ATag, { color: row.trustColor }, () => row.trustLabel) }
    ```

### 5️⃣ 集成链必须显式声明
如果 Issue body 中声明了「被依赖 #X / 依赖 #Y」关系，PR body 必须显式说明每个依赖的接入情况：`已接入` / `延后到 #Z 追补 Issue` / `N/A 仅后端 API`。

- ❌ 反例（#3542 事故）：#2391 body 明确「#3458 的 trustLevel 字段将使用本 Issue 的评分输出」，但 PR 未接入 #3458 的 data.ts
- ✅ 正确做法：PR body 增加 `## 集成链状态` 小节逐项说明

### 6️⃣ 单元测试必须本地跑通
禁止在 task.md 或 PR body 写「测试配置问题待解决」「代码已编写待 CI 验证」这类免责语。

- ❌ 反例（#3542 事故）：task.md 第 5 步「运行单元测试确认绿灯（测试配置问题待解决）」
- ✅ 正确做法：
  - 后端：`mvn test -pl <module> -Dtest=<TestClass>` 本地跑通
  - 前端：`pnpm --filter <pkg> test` 跑通
  - 如果环境问题确实阻塞，创建 blocker Issue 标 P0，**暂停提 PR**

### 7️⃣ 前端改动必须补对应 smoke 用例（图形测试覆盖）
前端 PR 改动 `frontend/apps/web-antd/src/views/**/index.vue` 时，必须在 `wande-play/e2e/tests/front/smoke/` 下新增或更新对应的 `<module>-page.spec.ts`。

**核心动机**：纯函数单测永远发现不了 vxe-table slot 返回 HTML 字符串这类渲染 bug。CC 必须写运行时 DOM 断言才能真正覆盖图形层。

**必须保留的 3 条反事故断言**（从 `_template.spec.ts` 模板复制过来）：

```ts
// 断言 1：标题正确
await expect(page).toHaveTitle(new RegExp(PAGE_NAME));

// 断言 2：关键组件可见
await expect(page.locator('.ant-tag, .vxe-body--row').first()).toBeVisible();

// 断言 3：核心反事故 — 表格首 20 个单元格文本不得以 `<` 开头
const cells = await page.locator('.vxe-body--row .vxe-cell').all();
for (const cell of cells.slice(0, 20)) {
  const text = (await cell.textContent())?.trim() || '';
  expect(text).not.toMatch(/^<[a-zA-Z-]+[\s>]/);
}
```

- ❌ 反例（#3487 事故）：PR 声称写了 16 个单元测试全部通过，但**全是纯函数**（倒计时公式/等级映射/Tab 配置），0 个 DOM 断言。结果 slot 返回 HTML 字符串的 bug 一个测试也测不到
- ✅ 正确做法：
  ```bash
  cp wande-play/e2e/tests/front/smoke/_template.spec.ts \
     wande-play/e2e/tests/front/smoke/wande-project-page.spec.ts
  # 修改 ROUTE 和 PAGE_NAME 常量
  # 按需追加额外断言（但 3 条反事故断言必须保留）
  # 本地跑通: cd wande-play/e2e && npx playwright test front/smoke/wande-project-page.spec.ts
  ```

**quality-gate 门 4** 会在 CI 级检查：前端 `index.vue` 有改动但 smoke 目录无对应文件 → block merge。

---

## 📋 标准流程（参考）

读 Issue → 读设计文档（若 `issues/issue-${ISSUE}/design.md` 存在）→ 设计 → TDD 红灯 → 实现 → 单测本地绿灯 → 本地构建 → **前端视觉验证（截图）** → task.md 全勾 → `bash scripts/pr-body-lint.sh` 本地预检 → `gh pr create` → 巡检 PR CI → quality-gate 通过 → auto-merge

## 🛡️ quality-gate 拦截规则（auto-merge 前执行）

| 门 | 检查 | 失败后果 |
|---|------|---------|
| 1 | PR body 无 `- [ ]` | ❌ block auto-merge |
| 2 | `issues/issue-${ISSUE}/task.md` 无 `- [ ]` | ❌ block auto-merge |
| 3 | 前端 PR（`frontend/**`）body 必须含 Markdown 图片 | ❌ block auto-merge |
| 4 | 前端 `index.vue` 改动必须有对应 `smoke/<module>-page.spec.ts` | ❌ block auto-merge |

## 📞 遇到问题

- 被 quality-gate 拦截 → 补齐未勾 checkbox 或追加截图，`git push` 再触发
- 如果 Issue 本身就是不可完成的（需求模糊/缺依赖）→ 在 Issue 上评论说明 + `gh issue edit --add-label blocked`，**不要强行提 PR**
