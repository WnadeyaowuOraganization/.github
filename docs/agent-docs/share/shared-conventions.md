# 万德 CC 共享规范（唯一权威源）

> 所有编程 CC 启动时 `run-cc.sh` 自动注入本文件作为初始 prompt。
> 任何规则变更必须改本文件，不得分散到其他文件。

## 🚨 菜单规则（最高优先级）

**禁止 INSERT 新菜单**。平台菜单结构已通过 8 个 Issue 统一建好，所有页面都有对应的占位菜单。

开发新页面时：
1. 查 `sys_menu` 找到对应的占位菜单（`component` 为空或指向占位组件的记录）
2. 用 Flyway 增量 SQL **UPDATE** 该菜单的 `component` 字段，指向你的 Vue 组件路径
3. **前端优先替换占位页面** — 在 `frontend/apps/web-antd/src/views/` 对应路由目录下查找占位页面（含 `🚧` 或 `占位` 标识的组件），直接替换其内容为实际业务组件。没有占位页面时才新建文件
4. 菜单结构参考：`.github/docs/design/all-in-one/菜单重组完整规划.md`
5. 菜单规范详细文档：`.github/docs/agent-docs/backend/menu-contracts.md`

```sql
-- ✅ 正确：UPDATE 已有占位菜单
UPDATE sys_menu SET component = 'business/tender/project-mine/index' WHERE menu_name = '项目挖掘' AND menu_type = 'C';

-- ❌ 错误：INSERT 新菜单
INSERT INTO sys_menu (...) VALUES (...);
```

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
10. **阶段性主动汇报** — 4 个节点直接向研发经理汇报（tmux 即时 + notify），禁止静默工作：
    - 开工（读完 Issue + task.md 后）
    - 阶段完成（编译通过 / 单测绿 / 提 PR / PR merged）
    - 卡住（连续 10 分钟同一问题无进展）
    - **结论前**（下「问题不存在/无需修改/已修复」结论前必须先汇报等确认，禁止自行 close Issue）
    ```bash
    # 标准汇报命令（必须同时发 tmux + notify）
    MSG="[#${ISSUE}] <一句话现状>" && TYPE=info && \
    tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter 2>/dev/null; \
    curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
      -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"$TYPE\"}" >/dev/null
    # TYPE: info=进度 / warning=卡住需关注 / success=阶段完成 / error=必须介入
    ```

## 团队内沟通机制

### 通讯录

| 角色 | tmux 会话名 | 何时联系 |
|------|------------|---------|
| 研发经理 | `manager-研发经理` | 进度汇报 / 卡住求助 / 方案评审 / 结论确认 |
| 排程经理 | `manager-排程经理` | 依赖确认 / 排程疑问 |
| 自己（编程CC） | `tmux display-message -p '#S'`（格式：`cc-wande-play-kimiN-ISSUE`） | 填 from 字段 |

### 强制要求
**每次**发送消息给其他人，必须调用 notify API（方便人工查看沟通进度）。

### 标准流程
```bash
# 1. 发送详细内容到对应CC的tmux会话（回车符不可省略）
tmux send-keys -t 'manager-研发经理' "详细消息" Enter

# 2. 发送notify（强制）
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d '{"session":"manager-研发经理","message":"【类型】内容摘要","type":"info"}'
```

### 消息格式
**标题**：`【类型】- <回复标识> 一句话摘要`（≤50字）  
**类型**：方案评审 / 进度播报 / 异常发现 / 需人工介入  
**回复标识**：
- `【需回复】` - 需要对方确认/决策/反馈
- `【阅即可】` - 纯同步信息，无需回复

### 消息模板
```markdown
【方案评审】-【需回复】 Issue #2367建议采用纯数据库操作
from: <发送方tmux会话名称>
to: <接收方tmux会话名称>
=============
 <消息内容-`less is more`原则>
```

**使用样例**：
```bash
# 场景：向研发经理汇报方案评审结论
CONTENT='【方案评审】-【需回复】 Issue #2367建议采用纯数据库操作
from: manager-排程经理
to: manager-研发经理
=============
分析结论：菜单重组无需前端改动，仅通过Flyway脚本操作sys_menu表即可。
实施步骤：1)创建资源中心一级菜单 2)迁移竞品情报子菜单 3)隐藏旧菜单
预计工时：0.5人日（仅后端脚本）
请确认此方案是否可行，或需要调整实施策略。'

tmux send-keys -t 'manager-研发经理' "$CONTENT" Enter

curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d '{"session":"manager-研发经理","message":"【方案评审】-【需回复】 Issue #2367建议采用纯数据库操作","type":"info"}'
```

### 场景速查

| 场景 | notify type | 回复标识 |
|-----|-------------|---------|
| 方案评审 | `info` | `[需回复]` |
| 进度播报 | `success` | `[阅即可]` |
| 异常发现 | `warning` | `[需回复]` |
| 需人工介入 | `error` | `[需回复]` |

## RuoYi 响应格式（违反导致前端弹窗报错、数据不展示）

**列表接口**：必须用 `TableDataInfo.build(list)` 构造响应。

```java
// ✅ 正确
return TableDataInfo.build(list);

// ❌ 错误：new TableDataInfo<>() 丢失 code/msg，前端拦截器判定失败
TableDataInfo<XxxVO> result = new TableDataInfo<>();
result.setRows(list);
result.setTotal(list.size());
return result;
```

**单体接口**：必须用 `R.ok(data)` / `R.fail(msg)`，禁止手动 `new R<>()`。

## 原型驱动开发（有设计文档/HTML原型的Issue必读）

Issue 引用了 `docs/design/` 下的设计文档或 HTML 原型时：

1. **开发前**：读原型 HTML 源码，在 task.md 中列出原型要求的字段/按钮/交互清单，标注对应设计文档章节号
2. **开发中**：逐项实现清单内容，每完成一项在 task.md 中勾选
3. **开发后**：curl 验证 API 响应格式 + 截图对照原型核对

```markdown
<!-- task.md 示例 -->
## 原型核对清单（§2.3 列表页）
- [x] 表格列：项目名称/项目编码/类型/区域/... （共13列，与01-all.html一致）
- [x] 筛选栏：项目类型/区域/真实性/等级/最低评分 （与原型一致）
- [x] 操作按钮：详情/修正/有效/无效/分配/删除 （tooltip文字已核对）
```

## 自测要求（API改动 + UI改动）

- **后端 API 改动**：修改后必须 curl 验证响应格式（`code=200` + 业务字段完整），结果贴到 task.md
- **前端 UI 改动**：修改后必须用 `/screenshot` 截图，对照原型核对渲染结果
- 禁止以"编译通过"替代功能验证

## 绝对禁止（YOU MUST NOT）

- **YOU MUST NOT** 使用 `visible` 属性 — 用 `open`（Ant Design Vue 4.x）
- **YOU MUST NOT** 嵌套 Drawer/Modal — 独立组件 + 事件通信
- **YOU MUST NOT** 在 `useVbenDrawer/Modal` 的 `connectedComponent` 里用 `<Page>`/`<div>` 作 template 最外层 — 必须是 `<BasicDrawer>`/`<VbenDrawer>`/`<a-drawer>` overlay 容器（#3544 事故，详见 `frontend/ui-guide.md` §3.5）
- **YOU MUST NOT** 加前端路由而不配置后端 `sys_menu` 表
- **YOU MUST NOT** 为外部链接创建自定义 iframe Vue 组件 — 用 `sys_menu` path=http URL 配置即可
- **YOU MUST NOT** 使用 `any` 类型
- **YOU MUST NOT** 直接编辑基线 SQL — 新表/变更用 Flyway 增量脚本 `db/migration/V<N>__<desc>.sql`
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
# ⚠️ 截图必须使用你自己的 kimi 测试环境，禁止连接主 Dev 环境！
# kimi 测试环境地址：http://localhost:${CC_TEST_FRONTEND_PORT} (如 kimi1=8101)
# 登录凭证：admin/admin123
gh release create screenshot-${PR_NUM} --notes "screenshot" /tmp/<file>.png
# 拿到 https://github.com/.../releases/download/... URL
gh pr edit ${PR_NUM} --body-file <body 末尾追加 ![desc](URL)>
```

## 环境信息

| 服务 | Dev (m7i) | 生产 (Lightsail) |
|------|-----------|----------------- |
| 前端 | http://172.31.31.227:8080 | http://47.131.77.9 |
| 后端 API | http://172.31.31.227:6040 (test profile, root用户) | Docker |
| API 代理 | :8080/api/ → :6040 | nginx |
| MySQL | 127.0.0.1:3306 / wande-ai / root / root (Docker) | Docker |
| Redis | localhost:6379 / db0 | Docker |

> **编程CC 隔离环境**：每个 kimi 有独立 MySQL schema（`wande-ai-kimi{N}`）和 Redis DB（`db{N}`），使用 `wande` 用户。`wande` 用户**无**主 `wande-ai` 库权限，防止编程CC误操作主环境。

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
| `cd frontend && pnpm build:antd` | 前端全量构建（提 PR 前必须用此命令，`pnpm build` 走 turbo 缓存可能跳过） |

## 项目目录结构

```
$(git rev-parse --show-toplevel)/
├── backend/                  # 后端（Maven 多模块）
│   ├── ruoyi-admin/          # 主启动模块（spring-boot-maven-plugin 在此）
│   ├── ruoyi-common/
│   ├── ruoyi-extend/
│   └── ruoyi-modules/
│       └── wande-ai/         # 万德业务模块
├── frontend/                 # 前端（pnpm monorepo）
│   └── apps/web-antd/        # 主应用（vite.config.mts）
├── e2e/                      # E2E 测试（在项目根目录，不在 frontend 下！）
│   ├── tests/frontend/smoke/ # 前端 Smoke 测试用例（编程CC自己写，smoke-e2e定期回归主测试环境）
│   ├── tests/backend/smoke/  # 后端 Smoke 测试用例（编程CC自己写，smoke-e2e定期回归主测试环境）
│   ├── tests/top-e2e/        # 完整前后端回归测试用例（顶层E2E定时更新，有新issue完成，根据issue关联的原型和详细设计编写）
│   └── node_modules/         # Playwright 依赖
├── issues/                   # Issue 工作目录
│   └── issue-${ISSUE}/
│       ├── issue-source.md   # Issue 原文
│       ├── task.md           # 任务清单
│       └── design.md         # 详细设计（如有）
└── shared/api-contracts/     # 接口契约
```

> **注意**：`e2e/` 目录在**wande-play-[N]项目根**下，不在 `frontend/` 下。Playwright 脚本用 `import from '项目根/e2e/node_modules/playwright/...'`。

## 数据库规范

- **数据库**：MySQL 8.0，库名 `wande-ai`，单数据源（master），无需 `@DS` 注解
- **新表必须用 `wdpp_` 前缀**（如 `wdpp_tender_project`）
- 新表必须包含 `create_time` / `update_time`（与 BaseEntity 一致）
- 老表（`created_at`）需增量 SQL 或 `@TableField("created_at")` 映射
- **增量 SQL 使用 Flyway**：先执行 `TS=$(date +%Y%m%d%H%M%S)` 获取精确到秒的时间戳，文件名 `V${TS}__<desc>.sql`，放在 `backend/ruoyi-modules/wande-ai/src/main/resources/db/migration/` 或 `backend/ruoyi-admin/src/main/resources/db/migration/`。**禁止** `date +%Y%m%d` 后手动补 `000000`（多CC并发时必冲突）

## 认证机制

- **后端**：HTTP 状态码恒为 200，用 `body.code` 判断（`200` 成功 / `401` 未认证）
- **前端**：统一返回 `R<T>`（`R.ok(data)` / `R.fail(msg)`）

## 菜单机制（新增页面时必读）

**唯一权威规范**：[`shared/menu-contracts.md`](/home/ubuntu/projects/.github/docs/agent-docs/share/menu-contracts.md)

包含：操作步骤、Flyway模板、字段说明、component/perms前缀对照表、完整菜单目录树。新增页面前**必须阅读**。

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
