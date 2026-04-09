# CC Agent Docs 导航

本目录是万德AI平台所有 prompt / CC 文档的唯一权威源。除 `CLAUDE.md` 外，prompt 相关文档都放在这里。

## 更新规范
1、更新本目录下文档时务必采取`less is more`原则，不要说“为什么”，只描述“怎么做”，表述要精准、明确，不可有歧义！
2、严格按照目录结构分类存放
3、除非得到用户授权，否则禁止擅自更改本目录下的任何文档（安全红线）
4、同一类型的说明更新到同一个文档中，新增文档必须在各CC的入口文档`*-guide.md`里增加引用

## 引用规范

- **业务仓库引用** → 用 `~/projects/.github/docs/agent-docs/...` 绝对路径
- **agent-docs 内部互引** → 同目录用 `./xxx.md` 相对路径 OK
- **禁止** → 跨仓库 `./` `../` 或裸文件名

## 目录结构

```
docs/agent-docs/
├── README.md                      ← 本导航文档（含业务仓库引用规范）
├── share/                         ← 前后端共享文档
│   ├── shared-conventions.md      ← Git分支、环境、通用规则
│   ├── issue-workflow.md          ← Issue生命周期与三阶段开发流程
│   ├── api-contracts.md           ← 前后端接口契约规范
│   ├── db-schema.md               ← 数据库列名规范（新旧表差异）
│   └── cc-default-prompt.md       ← 🚦 CC 启动 prompt 模板 v2.2（9 条硬约束 + quality-gate 4 道门，run-cc.sh 引用）
├── backend/                       ← 后端CC专属文档
│   ├── backend-guide.md           ← 主指引（必读）
│   ├── common-pitfalls.md         ← ⚠️ 高频错误与规范
│   ├── architecture.md            ← 项目概述与技术栈
│   ├── conventions.md             ← Entity/Mapper/Service/Controller模板
│   ├── db-schema.md               ← 数据库变更管理与增量SQL流程
│   ├── testing.md                 ← TDD流程与单元测试规范
│   ├── workflow.md                ← TDD三阶段开发流程
│   ├── menu-config.md             ← 菜单与权限注册
│   └── wechat-integration.md      ← 企微/微信集成规范
├── frontend/                      ← 前端CC专属文档
│   ├── frontend-guide.md          ← 主指引（必读）
│   ├── ui-guide.md                ← ⚠️ 页面开发强制规范
│   ├── conventions.md             ← 命名规范与文件组织
│   ├── testing.md                 ← 组件测试规范（Vitest）
│   ├── workflow.md                ← 三阶段开发流程
│   └── antdv-constraints.md       ← Ant Design Vue 4.x废弃API
├── manager/                       ← 经理CC文档
│   ├── scheduler-guide.md         ← 排程经理指南
│   ├── assign-guide.md            ← 研发经理指南
│   ├── issue-creation-sop.md      ← Issue创建SOP v3.0
│   └── wande-label.md             ← 统一标签规范 v2.1
├── pipeline/                      ← 管线CC文档
│   ├── README.md                  ← 管线CC主指引
│   ├── conventions.md             ← 管线编码规范
│   ├── environment.md             ← 运行环境说明
│   ├── workflow.md                ← 管线开发流程
│   └── pipeline-*.md              ← 各类管线专项文档
└── e2e/                           ← E2E测试CC文档
    └── testing-guide.md           ← 顶层E2E回归测试指南
```

## 文档分层说明

| 层级 | 目录 | 说明 |
|------|------|------|
| **共享层** | `share/` | 前后端CC必须了解的通用规范，两份主指引均有引用 |
| **后端层** | `backend/` | 仅后端CC需要的Spring Boot / MyBatis-Plus开发规范 |
| **前端层** | `frontend/` | 仅前端CC需要的Vue3 / Vben Admin开发规范 |
| **经理层** | `manager/` | 排程经理与研发经理CC的决策指南 |
| **管线层** | `pipeline/` | Python数据采集管线专项文档 |
| **测试层** | `e2e/` | 顶层E2E全量回归测试指南 |

## CC主指引快速导航

| CC角色 | 主指引 | 启动入口 |
|--------|--------|---------|
| **后端CC** | [backend-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/backend-guide.md) | CLAUDE.md → 后端CC指南 |
| **前端CC** | [frontend-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/frontend-guide.md) | CLAUDE.md → 前端CC指南 |
| **排程经理** | [scheduler-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/manager/scheduler-guide.md) | CLAUDE.md → 排程经理指南 |
| **研发经理** | [assign-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/manager/assign-guide.md) | CLAUDE.md → 研发经理指南 |
| **管线CC** | [pipeline/README.md](/home/ubuntu/projects/.github/docs/agent-docs/pipeline/README.md) | CLAUDE.md → 管线CC指南 |
| **E2E测试CC** | [e2e/testing-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/e2e/testing-guide.md) | e2e_top_tier.sh prompt |

## 共享文档说明

以下文档前后端CC均须知晓，在各自主指引的"共享文档"节中引用：

| 文档 | 内容摘要 |
|------|---------|
| [shared-conventions.md](/home/ubuntu/projects/.github/docs/agent-docs/share/shared-conventions.md) | Git分支规范（main/dev/feature）、开发环境端口、数据库连接信息、通用禁止事项 |
| [issue-workflow.md](/home/ubuntu/projects/.github/docs/agent-docs/share/issue-workflow.md) | Issue从Plan到Done的完整生命周期、三阶段开发流程（准备→执行→提交） |
| [api-contracts.md](/home/ubuntu/projects/.github/docs/agent-docs/share/api-contracts.md) | 前后端接口契约文件路径规范、YAML契约格式、修改流程 |
| [db-schema.md](/home/ubuntu/projects/.github/docs/agent-docs/share/db-schema.md) | 数据库列名规范（create_time/created_at差异）、新表wdpp_前缀、BaseEntity字段映射 |
| [cc-default-prompt.md](/home/ubuntu/projects/.github/docs/agent-docs/share/cc-default-prompt.md) | 🚦 **CC 启动 prompt 模板 v2.2** — 9 条硬约束（task.md 全勾 / PR body 全勾 / 前端截图 / slot VNode / 集成链 / 单测 / smoke 用例 / rebase / 轮询 PR）+ quality-gate 4 道门规则。`scripts/run-cc.sh` 第 196 行引用，`pr-test.yml` 评论里也会指向此文档 |

## CC Prompt 版本化

| 版本 | 日期 | 触发 | 变更 |
|-----|------|------|------|
| v1 | 2026-03 | 初版 | 一句话 prompt |
| v2 | 2026-04-09 | #3458 事故 4.2/10 | + 6 条硬约束 |
| v2.1 | 2026-04-09 | 图形测试覆盖 | + 约束 7 + 门 4 |
| v2.2 | 2026-04-09 | #3543 压测漏洞 B/E/F | + 约束 8/9 + 假勾选警告 |

度量：`scripts/weekly-quality-report.sh` 对比前后平均分。目标 +0.5/版本。
事故档案：`docs/workflow/新harness验证报告.md`，评分 < 6 必须新建章节。

## 仓库信息

- **组织**: WnadeyaowuOraganization
- **主仓库**: wande-play
- **Project看板**: https://github.com/orgs/WnadeyaowuOraganization/projects/4
- **CI/CD**: GitHub Actions（pr-test.yml + build-deploy-dev.yml）
