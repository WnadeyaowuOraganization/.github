阅读 `issues/issue-${ISSUE}/issue-source.md` 完成 Issue #${ISSUE}。

## 9 条硬约束（违反任一项被 quality-gate 拦截）

1. **task.md 全勾** — `issues/issue-${ISSUE}/task.md` 任何 `- [ ]` 都禁止；做不完拆追补 Issue 后勾选原步骤
2. **PR body 全勾 + 禁止假勾选** — body 不得有 `- [ ]`；勾了「截图/视觉/screenshot」类文字必须 body 同时有 `![](.*\.png)`
3. **前端必有截图** — 改动 `frontend/apps/web-antd/src/views/**` 时 PR body 必含至少 1 张 Markdown 图片
4. **vxe-table slot 返回 VNode** — `slots.default` 函数禁止返回 HTML 字符串，否则页面显示源代码（#3487 事故）
5. **集成链显式声明** — Issue body 声明的「依赖/被依赖」必须在 PR body 说明每项 `已接入 / 延后到 #X / N/A`
6. **单测本地跑通** — 禁写「测试配置待解决」「待 CI 验证」类免责语
7. **🚨 前端必补 smoke 用例** — 改动 `views/**/index.vue` 必须 `cp e2e/tests/front/smoke/_template.spec.ts e2e/tests/front/smoke/<module>-page.spec.ts` 并保留 3 条反事故断言
8. **PR create 前必 rebase** — `git fetch origin dev && git rebase origin/dev && git push --force-with-lease`
9. **PR create 后必轮询** — `while [ "$(gh pr view $PR --json state -q .state)" != "MERGED" ]; do sleep 120; done`；超 30min 未 merged 在 Issue 评论说明后退出

## slot VNode 正确写法（约束 4）

```ts
// ❌ 错: slots: { default: ({row}) => `<a-tag>${label}</a-tag>` }
// ✅ 对: slots: { default: 'colName' } + index.vue 内 <template #colName="{row}"><a-tag>...</a-tag></template>
// ✅ 或: import { h } from 'vue'; slots: { default: ({row}) => h(ATag, {color}, () => label) }
```

## 标准流程

读 Issue/design.md → TDD 红灯 → 实现 → 单测本地绿 → 本地构建 → 截图 → cp smoke 模板改 ROUTE/PAGE_NAME → task.md 全勾 → `bash ~/projects/.github/scripts/pr-body-lint.sh --pr-body-stdin --issue ${ISSUE}` → rebase → `gh pr create` → 轮询直到 merged

## quality-gate 4 道门

| 门 | 检查 | 失败 |
|---|------|------|
| 1 | PR body 无 `- [ ]` | block |
| 2 | task.md 无 `- [ ]` | block |
| 3 | 前端 PR body 含图片 + cross-check 假勾选 | block |
| 4 | `views/**/index.vue` 改动有对应 smoke 用例 | block |

被拦截 → 读 PR 评论的「门 X 拦截」诊断 → 按提示补齐 → push 重跑。

## 截图托管（参考 #3547 CC 做法）

```bash
# 本地启动 dev 或 Playwright 连 Dev http://3.211.167.122:8083 (admin/admin123) 截图
gh release create screenshot-${PR_NUM} --notes "screenshot" /tmp/<file>.png
# 拿到 https://github.com/.../releases/download/... URL
gh pr edit ${PR_NUM} --body-file <body 末尾追加 ![desc](URL)>
```

> 完整版本历史 + 度量方法见 [agent-docs/README.md](../README.md) 的「CC Prompt 版本化」章节
