# 万德 CC 共享规范（唯一权威源）

> 所有编程 CC 启动时 `run-cc.sh` 自动注入本文件作为初始 prompt。
> 任何规则变更必须改本文件，不得分散到其他文件。

阅读 `issues/issue-${ISSUE}/issue-source.md` 完成 Issue #${ISSUE}。

## 10 条硬约束（违反任一项被 quality-gate 拦截）

1. **task.md 全勾** — `issues/issue-${ISSUE}/task.md` 任何 `- [ ]` 都禁止；做不完拆追补 Issue 后勾选原步骤
2. **PR body 全勾 + 禁止假勾选** — body 不得有 `- [ ]`；勾了「截图/视觉/screenshot」类文字必须 body 同时有 `![](.*\.png)`
3. **前端必有截图** — 改动 `frontend/apps/web-antd/src/views/**` 时 PR body 必含至少 1 张 Markdown 图片
4. **vxe-table slot 返回 VNode** — `slots.default` 函数禁止返回 HTML 字符串（#3487 事故）
5. **集成链显式声明** — Issue body 声明的「依赖/被依赖」必须在 PR body 说明每项 `已接入 / 延后到 #X / N/A`
6. **单测本地跑通** — 禁写「测试配置待解决」「待 CI 验证」类免责语
7. **🚨 前端必补 smoke 用例** — 改动 `views/**/index.vue` 必须 `cp e2e/tests/front/smoke/_template.spec.ts e2e/tests/front/smoke/<module>-page.spec.ts` 并保留 3 条反事故断言
8. **PR create 前必 rebase + 必须 `--base dev`** — 禁止默认 base（repo default 是 main，默认会合到 main 导致反向污染 #3554 事故）
   ```bash
   git fetch origin dev && git rebase origin/dev && git push --force-with-lease
   gh pr create --base dev --title "..." --body "..."   # --base dev 必填,不能省
   ```
9. **PR create 后必轮询** — `while [ "$(gh pr view $PR --json state -q .state)" != "MERGED" ]; do sleep 120; done`；超 30min 未 merged 在 Issue 评论说明后退出
10. **阶段性主动汇报** — 4 个节点直接向研发经理汇报（tmux 即时 + claude-office 通知），禁止静默工作：
    - 开工（读完 Issue + task.md 后）
    - 阶段完成（编译通过 / 单测绿 / 提 PR / PR merged）
    - 卡住（连续 10 分钟同一问题无进展）
    - **结论前**（下「问题不存在/无需修改/已修复」结论前必须先汇报等确认，禁止自行 close Issue）
    ```bash
    # 一条命令同时发 tmux (研发经理即时收到) + claude-office 通知
    MSG="[#${ISSUE}] <一句话现状>" && TYPE=info && \
    tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter 2>/dev/null; \
    curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
      -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"$TYPE\"}" >/dev/null
    # TYPE: info=进度 / warning=卡住需关注 / success=阶段完成 / error=必须介入
    ```

## 绝对禁止（YOU MUST NOT）

- **YOU MUST NOT** 使用 `visible` 属性 — 用 `open`（Ant Design Vue 4.x）
- **YOU MUST NOT** 嵌套 Drawer/Modal — 独立组件 + 事件通信
- **YOU MUST NOT** 在 `useVbenDrawer/Modal` 的 `connectedComponent` 里用 `<Page>`/`<div>` 作 template 最外层 — 必须是 `<BasicDrawer>`/`<VbenDrawer>`/`<a-drawer>` overlay 容器（#3544 事故，详见 `frontend/ui-guide.md` §3.5）
- **YOU MUST NOT** 加前端路由而不配置后端 `sys_menu` 表
- **YOU MUST NOT** 使用 `any` 类型
- **YOU MUST NOT** 直接编辑 `schema.sql` — 新表用 `schemas/issue_XXXX.sql` + `script/sql/update/` 增量脚本
- **YOU MUST NOT** 在 `wande-ai-api` 目录新增业务代码（已废弃）— 写在 `ruoyi-modules/wande-ai/` 下
- **YOU MUST NOT** 用 root 执行 mvn（target 权限污染）— CC 已在 ubuntu 用户直接 `mvn` 即可
- **YOU MUST NOT** push 到 `dev` 或 `main` 分支 — 只 push `feature-Issue-<N>`

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
# 本地 pnpm dev 或 Playwright 连 Dev http://3.211.167.122:8083 (admin/admin123) 截图
gh release create screenshot-${PR_NUM} --notes "screenshot" /tmp/<file>.png
# 拿到 https://github.com/.../releases/download/... URL
gh pr edit ${PR_NUM} --body-file <body 末尾追加 ![desc](URL)>
```

## 环境信息

| 服务 | Dev (G7e) | 生产 (Lightsail) |
|------|-----------|----------------- |
| 前端 | http://3.211.167.122:8083 | http://47.131.77.9 |
| 后端 API | http://3.211.167.122:6040 | Docker |
| API 代理 | :8083/prod-api/ → :6040 | nginx |
| PostgreSQL | localhost:5433 / wande / wande_dev_2026 | Docker |
| Redis | localhost:6380 / redis_dev_2026 | Docker |

## Git 分支

| 分支 | 用途 |
|------|------|
| `main` | 生产，PR merge 触发 Lightsail 部署 |
| `dev` | 开发，PR merge 触发 Dev 环境部署 |
| `feature-Issue-<N>` | 从 dev 签出，PR → dev |

- Commit: `feat(scope): description #N`
- 开发前必须确认当前分支，不在 feature 分支则从 dev 签出新分支

## 构建命令

| 命令 | 用途 |
|------|------|
| `cd backend && mvn clean compile -Pprod -DskipTests` | 后端编译 |
| `cd backend && mvn test -pl ruoyi-modules/wande-ai` | 后端测试 |
| `cd frontend && pnpm build` | 前端构建 |

## 数据库规范

- **新表必须用 `wdpp_` 前缀**（如 `wdpp_tender_project`）
- 新表必须包含 `create_time` / `update_time`（与 BaseEntity 一致）
- 老表（`created_at`）需增量 SQL 或 `@TableField("created_at")` 映射
- **万德业务 Mapper/Service 必须加 `@DS("wande")`** — 不加会走 master 库报错

## 认证机制

- **后端**：HTTP 状态码恒为 200，用 `body.code` 判断（`200` 成功 / `401` 未认证）
- **前端**：统一返回 `R<T>`（`R.ok(data)` / `R.fail(msg)`）

## 菜单机制

侧边栏菜单由**后端 `sys_menu` 表**驱动，不是前端路由静态定义。

新页面完整清单：
1. `views/wande/` 创建页面组件
2. `api/wande/` 创建 API 调用
3. **后端**创建 `sys_menu` 增量 SQL（决定菜单显示）
4. `component` 字段值匹配 `views/` 下路径（不含 `views/` 前缀和 `.vue` 后缀）

调试菜单不显示：检查 `/system/menu/getRouters` → `sys_menu` → `sys_role_menu` → `component` 路径。

## 接口契约

- 前后端接口契约是**唯一接口真相源**：`shared/api-contracts/*.yaml`
- 新增/改 API 必须先更新契约再写代码
- 契约最低字段：HTTP method、完整路径（含 `{param}`）、参数传递方式、类型、返回字段

## GitHub CLI

```bash
# 获取 Token（失效时调用）
export GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py)

# 常用命令
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments
bash ~/projects/.github/scripts/update-project-status.sh play <N> "<Status>"
```

## 模块专项指南

| 模块 | 指南 |
|------|------|
| 后端 | `~/projects/.github/docs/agent-docs/backend/backend-guide.md` |
| 前端 | `~/projects/.github/docs/agent-docs/frontend/frontend-guide.md` |
| 管线 | `~/projects/.github/docs/agent-docs/pipeline/README.md` |
| E2E | `~/projects/.github/docs/agent-docs/e2e/testing-guide.md` |
| Issue 流程 | `~/projects/.github/docs/agent-docs/share/issue-workflow.md` |
| API 契约规范 | `~/projects/.github/docs/agent-docs/share/api-contracts.md` |
| DB Schema 详细 | `~/projects/.github/docs/agent-docs/share/db-schema.md` |

## 组织信息

- **组织**：WnadeyaowuOraganization
- **Project 看板**：https://github.com/orgs/WnadeyaowuOraganization/projects/4
- **CODEOWNERS**：@wandeyaowu

> 版本历史 + 度量方法见 [agent-docs/README.md](../README.md) 的「CC Prompt 版本化」章节
