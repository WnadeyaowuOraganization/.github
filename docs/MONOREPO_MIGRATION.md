# 万德AI平台 Monorepo 迁移方案

> 仓库: `WnadeyaowuOraganization/wande-play`
> 日期: 2026-04-02
> 状态: 执行中

---

## §1 背景与问题

### 核心痛点

前后端仓库分离（wande-ai-backend + wande-ai-front）导致：

1. **接口不匹配**: 编程CC对同一功能的Issue各自理解，前端猜测API路径，后端实际实现不同
2. **中层E2E盲区**: 只针对单仓库PR测试，无法发现跨仓库接口不一致
3. **测试环境大量404**: "no static resource"泄露到dev环境——前端请求路径在后端不存在
4. **Issue拆分低效**: 一个功能拆成两个Issue分别进入两个仓库，增加管理成本和对齐难度

### 解决方案

合并为 Monorepo `wande-play`，前后端在同一仓库、同一Issue、同一PR中原子性提交。

---

## §2 新仓库结构

```
wande-play/
├── CLAUDE.md                    # 公共层：架构概述、环境信息、Git规范、Agent Teams指南、契约机制
├── backend/
│   ├── CLAUDE.md                # 后端编程CC专用prompt
│   ├── ruoyi-admin/  ruoyi-common/  ruoyi-extend/  ruoyi-modules/  ruoyi-modules-api/
│   ├── sql/  migration/  script/  docs/  issues/
│   └── pom.xml
├── frontend/
│   ├── CLAUDE.md                # 前端编程CC专用prompt
│   ├── apps/  packages/  internal/  scripts/  docs/  issues/
│   └── package.json
├── e2e/
│   ├── CLAUDE.md                # 测试CC专用prompt（中层+顶层共用，章节区分）
│   ├── tests/
│   │   ├── smoke/               # 冒烟测试
│   │   ├── integration/         # 前后端集成验证（新增）
│   │   ├── features/            # 功能E2E
│   │   └── regression/          # 回归测试
│   ├── playwright.config.ts
│   └── package.json
├── shared/
│   └── api-contracts/           # 前后端接口契约文件（新增）
├── .github/
│   ├── workflows/
│   │   ├── build-deploy-dev.yml      # 统一dev CI/CD（paths filter区分前后端）
│   │   ├── build-deploy.yml          # 统一生产CI/CD（含顶层E2E守门前置job）
│   │   ├── ci-test.yml               # 统一CI测试
│   │   └── auto-add-to-project.yml   # Issue自动关联Project#2
│   └── CODEOWNERS
└── docs/
```

---

## §3 CLAUDE.md 分层架构

利用 Claude Code 向上遍历合并 CLAUDE.md 的机制，通过启动时 cd 到不同子目录实现 prompt 隔离：

| CC | 启动时 cd 到 | 读取的 CLAUDE.md | 效果 |
|---|---|---|---|
| 编程CC(纯后端) | `wande-play/backend` | 根 + backend/ | 只看到后端开发指导 |
| 编程CC(纯前端) | `wande-play/frontend` | 根 + frontend/ | 只看到前端开发指导 |
| 编程CC(fullstack) | `wande-play` | 根（含Agent Teams指南） | 全局视图+契约机制 |
| 中层测试CC | `wande-play/e2e` | 根 + e2e/ | 只看到测试流程 |
| 顶层测试CC | `wande-play-e2e-full/e2e` | 根 + e2e/（独立clone） | 同上，独立运行 |

### 各层内容划分

| 文件 | 内容 | 谁读 |
|---|---|---|
| 根 CLAUDE.md | 项目架构概述、目录导航、环境信息(IP/端口/DB)、Git规范、Agent Teams指南、接口契约机制 | 所有CC |
| backend/CLAUDE.md | 速查索引、TDD流程、@DS注解、数据库规范(wdpp_前缀)、mvn编译门控、四阶段工作流 | 编程CC(后端) |
| frontend/CLAUDE.md | 速查索引、Vben组件规范、API对接验证规则、菜单机制(sys_menu)、pnpm build门控、四阶段工作流 | 编程CC(前端) |
| e2e/CLAUDE.md | 测试CC角色、中层七步决策法、顶层守门员流程、测试编写规范、GitHub身份(wandeyaowu PAT) | 测试CC |

---

## §4 编程CC Agent Teams 模式

### 启用

所有编程CC的 settings.json:

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_THINKING": "1",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### Issue 类型判定

| 标签 | 模式 | 启动目录 |
|------|------|----------|
| `module:backend` | 单Agent后端TDD | `wande-play/backend` |
| `module:frontend` | 单Agent前端TDD | `wande-play/frontend` |
| `module:fullstack` | Agent Teams 3-Agent并行 | `wande-play`（根目录） |

### Agent Teams 流程（fullstack Issue）

```
Step 0: Team Lead 理解 Issue → 更新 shared/api-contracts/ 接口契约
        契约最低标准：HTTP方法 + 完整路径 + 参数传递方式 + 参数类型 + 返回字段
        契约先 commit: "contract: update xxx api contract for #N"

Step 1: 创建 3-Agent Team，三个 Agent 同时启动
  ┌─ Backend Agent:  按契约实现 Controller+Service+JUnit测试（只改 backend/）
  ├─ Frontend Agent: 按契约实现页面+API调用+Vitest测试（只改 frontend/）
  └─ Integration Agent: 编写契约验证脚本（只改 e2e/、shared/）

Step 2: Integration Agent 验证（等前两个 Agent 完成后）
  - 静态: 前端API路径 vs 后端@RequestMapping vs 契约三方一致
  - 运行时: Playwright 打开页面 → 无404/无JS错误

Step 3: Team Lead 合成 → 同一 commit 提交前后端代码
```

### 接口契约文件模板

```typescript
// shared/api-contracts/wande-tender.ts
export const TenderAPI = {
  list:   { method: 'GET',    path: '/wande/tender/list',   params: 'query',  response: ['id', 'title', 'region', 'status'] },
  detail: { method: 'GET',    path: '/wande/tender/{id}',   params: 'path',   response: ['id', 'title', 'region', 'detail'] },
  create: { method: 'POST',   path: '/wande/tender',        params: 'body',   response: ['id'] },
  update: { method: 'PUT',    path: '/wande/tender',        params: 'body',   response: ['id'] },
  delete: { method: 'DELETE',  path: '/wande/tender/{ids}',  params: 'path',   response: [] },
} as const;
```

---

## §5 中层 E2E 测试——七步决策法

| 步骤 | 内容 | 解决什么 |
|------|------|----------|
| Step 1 | 扫描 wande-play 的 open PR(base=dev) | — |
| Step 2 | 分析变更范围: backend/ / frontend/ / 两者 | — |
| **Step 3** | **后端API健康检查**: 对PR涉及的Controller端点发HTTP请求，断言200非404 | 发现后端404 |
| **Step 4** | **前端页面可达性**: Playwright打开页面，断言无404/无JS错误/无failed网络请求 | 发现"no static resource" |
| **Step 5** | **前后端契约验证**: 前端API路径 vs 后端@RequestMapping vs shared/api-contracts/ 三方静态对比 | 发现接口路径不匹配 |
| Step 6 | 功能E2E测试（仅PR相关用例，不重跑单元测试） | — |
| Step 7 | 结果处理: approve+merge 或 打回+test-failed | — |

---

## §6 顶层 E2E——生产守门员

### 触发时机

| 场景 | 触发方式 |
|------|----------|
| 生产守门 | PR→main 时作为 build-deploy.yml 前置 job |
| 定时回归 | 每8小时 cron + dev有新merge才执行 |

### 三层冒烟

| 层级 | 内容 | 时间 |
|------|------|------|
| Layer 1 | API /health返回200 + 前端首页加载 + 登录正常 | <30秒 |
| Layer 2 | 遍历sys_menu所有路由，每个页面200+无JS错误+无404资源 | <2分钟 |
| Layer 3 | 招投标/项目管理/CRM/管控台 基本CRUD | <5分钟 |

### 误杀防护

- `known-failures.json`: 已知缺陷不阻塞发布
- 每个失败用例重试2次
- 环境探针: 测试前检查dev环境是否可用
- 失败时自动创建P0 Issue + 附截图日志 + bisect定位问题PR

---

## §7 Issue 状态流转

```
Perplexity创建Issue（fullstack联动 → 单个Issue + module:fullstack标签）
  │
  ▼
[Plan] ← CI/CD auto-add-to-project.yml 自动关联 Project#2
  │
  ▼ 研发经理CC排程（每10分钟）
[Todo] ← test-failed 最优先
  │
  ▼ 研发经理CC pre-task + run-cc.sh
[In Progress]
  │ 编程CC判定类型:
  │ - module:backend   → cd backend/  → 单Agent TDD
  │ - module:frontend  → cd frontend/ → 单Agent TDD
  │ - module:fullstack → cd 根目录    → Agent Teams（3-Agent并行）
  │
  ▼ 编程CC push feature + 创建 PR(feature→dev)
[等待中层E2E]
  │
  ▼ 中层测试CC七步决策法（每15分钟）
  ├→ 通过 → approve+merge → [Done]
  └→ 失败 → 打回 → +test-failed → [Todo] → 原目录恢复CC修复
  │
  ▼ 创建 PR(dev→main)
[顶层E2E守门员] ← build-deploy.yml前置job
  ├→ 通过 → merge到main → CI/CD部署生产
  └→ 失败 → 阻止merge → 创P0 Issue → 通知吴耀
```

---

## §8 各CC职责边界

| 角色 | 职责 | 不做 | 触发 |
|------|------|------|------|
| Perplexity | 需求→Issue创建→排程确认 | 不写代码、不触发CC | 吴耀交互 |
| 研发经理CC | Plan→Todo排程、触发编程CC、检查结果、持续优化 | 不写业务代码、不关闭Issue、不合并PR | 每10分钟cron |
| 编程CC | 拾取Issue→TDD开发→push feature→创建PR | 不merge到dev/main、不关闭Issue | 研发经理CC触发 |
| 编程CC(Teams) | 同上+创建3-Agent Team并行前后端 | 同上 | 研发经理CC触发(fullstack) |
| 中层测试CC | 扫描PR→七步决策法→merge或打回 | 只写测试代码，不碰backend//frontend/ | 每15分钟cron |
| 顶层测试CC | 全量冒烟→生产守门→失败创Issue | 不修改业务代码 | PR→main + 8小时cron |

---

## §9 标签变更

### 新增

| 标签 | 用途 |
|------|------|
| `module:fullstack` | 前后端联动Issue，触发Agent Teams模式 |
| `module:backend` | 纯后端Issue（迁移时自动加） |
| `module:frontend` | 纯前端Issue（迁移时自动加） |

### 保留不变

priority/P0~P3、type:feature/bugfix/enhancement、status:ready/in-progress/test-failed、source:*、approval:*、size/*、cross-repo 等全部保留。

---

## §10 CI/CD 改造

### build-deploy-dev.yml

- `backend/**` 变更 → 触发后端构建（mvn + jar部署）
- `frontend/**` 变更 → 触发前端构建（pnpm build + rsync + nginx reload）
- 两者都改 → 两个构建都触发
- feature分支push → 统一post-task.sh

### build-deploy.yml（生产）

- 新增前置job: 顶层E2E守门员（三层冒烟）
- E2E通过 → 后续构建部署job执行
- E2E失败 → 整个workflow失败，不部署
- 按paths filter决定构建前端/后端/两者

### Runner

从2个合并为1个 Self-hosted Runner。

---

## §11 G7e 基础设施改动

| 项 | 旧 | 新 |
|---|---|---|
| 编程CC主目录 | `wande-ai-backend` + `wande-ai-front` | `wande-play` |
| 外接目录 | `backend-kimi1~6` + `front-kimi1~4` | `play-kimi1~6` |
| Runner | 2个 | 1个 |
| 中层E2E目录 | `wande-ai-e2e` | `wande-play/e2e` |
| 顶层E2E目录 | `wande-ai-e2e-full` | `wande-play-e2e-full/e2e` |
| run-cc.sh | cd到项目根 | 按module参数cd到 backend//frontend//根 |
| settings.json | 只有DISABLE_THINKING | 新增AGENT_TEAMS |

---

## §12 Issue 迁移计划

### 规模

| 来源 | Open | Closed | 合计 |
|------|------|--------|------|
| backend | 644 | 254 | 898 |
| front | 251 | 129 | 380 |
| 合计 | 895 | 383 | 1278 |

### 策略

| 类型 | 处理 |
|------|------|
| Open Issue | GitHub API 批量迁移 + 自动加 module:backend/module:frontend |
| Closed/Done Issue | 同样迁移，正文补充溯源信息 |
| 前后端联动Issue | 合并为一个 + module:fullstack |
| Open PR (7个) | 关闭旧PR，新仓库重新创建 |
| 编号映射 | 建立映射表 old-backend#123 → new#456 |
| Project#2 | Item重新关联新仓库Issue |

---

## §13 执行计划

| Phase | 时间 | 内容 |
|-------|------|------|
| 1 | 即刻 | 创建wande-play仓库 ✅ |
| 2 | 即刻 | 推送迁移方案到.github/docs/ |
| 3 | ~1小时 | 合并backend/front/e2e代码（保留git历史） |
| 4 | ~30分钟 | 创建根CLAUDE.md + 子目录CLAUDE.md + shared/api-contracts/ |
| 5 | ~30分钟 | 创建统一CI/CD workflows |
| 6 | ~2小时 | 批量迁移1278个Issue |
| 7 | ~30分钟 | G7e工作目录+crontab脚本更新 |
| 8 | ~1小时 | 验证CI/CD+编程CC试跑 |
| 9 | 最后 | Archive旧仓库 |

---

## §14 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| Git历史丢失 | 高 | --allow-unrelated-histories保留，迁移前备份 |
| CI/CD中断 | 高 | 先验证新仓库CI/CD，再Archive旧仓库 |
| 编程CC不适应 | 中 | 先跑5-10个小Issue验证CLAUDE.md |
| 1278个Issue迁移出错 | 中 | 脚本迁移+映射表+旧仓库保留只读 |
| Agent Teams不稳定 | 中 | 实验性功能，fullstack Issue先少量试跑 |
