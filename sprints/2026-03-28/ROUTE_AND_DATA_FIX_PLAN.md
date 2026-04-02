# Sprint 2026-03-28 路由与数据修复计划

> 排查时间: 2026-04-02  
> 排查范围: wande-ai-front (apps/web-antd) + wande-ai-backend  
> 优先级: P0 → P1 → P2

---

## 一、P0 — 前端路由架构修复（影响页面404/空白）

### 修复项1-1：local.ts 中的 Dashboard 路由与后端模式冲突
**问题**: 系统配置了 `accessMode: 'backend'`，菜单由后端 API 返回。但 `local.ts` 的 `localMenuList` 中又定义了 `Dashboard` / `Analytics` / `Workspace` 路由，且这些路径在后端 `sys_menu` 表中无对应记录。后端路由模式合并后组件解析失败 → `/analytics` 和 `/workspace` 404。

同时 `dashboard.ts` 静态模块也定义了同名 `Dashboard` / `Analytics` / `Workspace`。

**修复方案**:
```ts
// local.ts
// 将整个 Dashboard 对象（path: '/' 的那个）从 localMenuList 中移除
// 仅保留 localRoutes（Profile / OssConfig / RoleAssign / WorkflowEdit / WorkflowRun）
```
原因：`local.ts` 的注释写得很清楚——"该文件放非后台返回的路由"，`Dashboard` 属于菜单级路由，不应该出现在这里。

如果业务上仍需要 `/analytics` 和 `/workspace` 页面，应在后端 `sys_menu` 表中补充对应菜单记录，由后端菜单驱动；或者如果这些页面已废弃，直接删除前端静态定义即可。

**涉及文件**: `apps/web-antd/src/router/routes/local.ts`

---

### 修复项1-2：wande.ts 中父路由同时设置 `component` 和 `children` 导致空白页
**问题**: `accessible.ts:47` 有段兼容逻辑：
```ts
if (route.children && route.children.length > 0) {
  delete route.component;
}
```
`wande.ts` 中有多个父路由同时设置了 `component` 和 `children`，导致父级 component 被删除，页面白屏。

确认受影响的父路由（同时有 component + children）：
- `WandeTender` (`/wande/tender`) — 有 children: evaluation, crawler
- `WandeProject` (`/wande/project`) — 有 children: index, mine-dashboard
- `WandeSample` (`/wande/sample`) — 有 children: inventory, kit, request, production, borrow
- `WandeCrm` (`/wande/crm`) — 有 children: followup, opportunity-kanban
- `WandeCompetitor` (`/wande/competitor`) — 有 children: alert, bid, products, benchmarking-matrix, timeline, cad-library
- `WandeAiRender` (`/wande/ai-render`) — 有 children: index, history
- `WandeFinance` (`/wande/finance`) — 有 children: receivable, accounts-payable, warning, lc-management
- `WandeDataManagement` (`/wande/data-management`) — 有 children: data-collection
- `WandeAsset` (`/wande/asset`) — 有 children: library/tag（注意此 name 在文件中出现了两次，见1-5）
- `InstallationAfterSales` (`/wande/installation-after-sales`) — 有 children: execution, warranty-after-sales
- `WandeCommon` (`/wande/common`) — 有 children: product-data, contract, execution, approval, notification, file-management

**修复方案**: 去掉这些父路由的 `component`，将原来的组件变成 `path: ''` 的默认子路由。以 `WandeCrm` 为例：

```ts
// ❌ 修改前
{
  path: 'crm',
  name: 'WandeCrm',
  component: () => import('#/views/wande/crm/index.vue'),
  meta: { ... },
  children: [ ... ]
}

// ✅ 修改后
{
  path: 'crm',
  name: 'WandeCrm',
  meta: { ... },
  children: [
    {
      path: '',
      name: 'WandeCrmIndex',
      component: () => import('#/views/wande/crm/index.vue'),
      meta: { ... } // 继承父级或自定义
    },
    ... // 其他子路由
  ]
}
```

**涉及文件**: `apps/web-antd/src/router/routes/modules/wande.ts`

---

### 修复项1-3：dashboard.ts 中重复的 `SuperAdminConfirmationCenter`
**问题**: 开发者反馈 `dashboard.ts` 中有两个 `SuperAdminConfirmationCenter`。但经代码排查，当前文件中仅在第303行出现一次（另一个可能是历史版本或已经被修掉）。

**核对结果**: 当前 `dashboard.ts` 中 `SuperAdminConfirmationCenter` 只出现一次（line 303），无重复。若开发者本地有重复，请删除末尾重复的那个。**此项视开发者本地实际情况而定**。

---

### 修复项1-4：vben.ts 中 `VbenAbout` 重复定义
**问题**: `vben.ts` 中 `VbenAbout` 出现了两次：
- 第一次在 `VbenProject` 的 children 中（line 26）
- 第二次作为独立路由（line 79）

Vue Router 会用后者覆盖前者，虽然当前影响较小（关于页），但属于 name 冲突。

**修复方案**: 如果第二个独立路由是为了在非 VbenProject 结构下也能访问，可以保留独立路由，删除 `children` 中的那个；反之亦然。建议保留 `children` 中的，删除独立路由。

**涉及文件**: `apps/web-antd/src/router/routes/modules/vben.ts`

---

### 修复项1-5：wande.ts 中 `WandeAsset` name 重复
**问题**: `wande.ts` 中 `WandeAsset` 出现了两次：
- 第一次约在 line 376（path: 'asset'，children: [library]）
- 第二次约在 line 486（path: 'asset'，children: [library, tag]）

同一文件中同名路由，后者会覆盖前者，导致第一次定义的素材库路由失效。

**修复方案**: 合并为一个 `WandeAsset`，保留完整的 children（library + tag），删除重复段。

**涉及文件**: `apps/web-antd/src/router/routes/modules/wande.ts`

---

## 二、P0 — 前端双路由体系冲突（wande.ts vs business.ts）

**核心问题**: 平台同时存在两套平行的菜单结构，引用完全相同的 Vue 组件：

| 组件文件 | wande.ts 引用 | business.ts 引用 | 其他 |
|---------|--------------|-----------------|------|
| `views/wande/project/index.vue` | `WandeProjectIndex` | `BusinessProject` | — |
| `views/wande/opportunity/index.vue` | `WandeOpportunity` | `BusinessOpportunity` | — |
| `views/wande/tender/index.vue` | `WandeTender` | `BusinessTender` | — |
| `views/wande/crm/index.vue` | `WandeCrm` | `BusinessCustomerList` | — |
| `views/wande/followup/index.vue` | `WandeFollowup` | `BusinessFollowup` | — |
| `views/wande/opportunity/kanban.vue` | `WandeOpportunityKanban` | `BusinessOpportunityKanban` | — |

**后端 API 检查结果**:
- `business.ts` 中除 `agent-workbench` 和 `international-trade` 两个空页面外，其余所有组件全部来自 `views/wande/` 目录。
- 这些组件调用的 API 也完全相同（如 `#/api/wande/crm`、`#/api/wande/project`、`#/api/wande/tender` 等）。
- **结论**：并不存在独立的 "business 端 API"，`business.ts` 和 `wande.ts` 的重复路由只是同一套功能走了两个不同的菜单入口。

**影响**: 
- 同一组件在多个路由下渲染，`keep-alive` 缓存异常，组件状态混乱。
- 后端菜单如果也返回了同类路径，前端路由合并后行为不可预测。
- 用户可能通过不同入口（商务部→CRM / 万德管理→CRM）访问到相同页面但不同 name，导致 tab 缓存、activePath 高亮异常。

**修复方案**：

### 结论：保留 wande.ts，以 redirect 方式收敛 business.ts（短期）
原因：
- `wande.ts` 中的路由路径（如 `/wande/crm`、`/wande/project`）已经被大量历史数据、后端菜单、用户收藏夹和权限码引用，迁移成本高、风险大。
- `business.ts` 虽然结构更清晰，但本质上是同一套功能的"菜单包装"，且 `views/business/` 目录下目前只有两个空页面，没有完全独立的业务实现。
- 考虑到稳定性和最小改动原则，**不宜直接废弃 wande.ts**。

**推荐步骤**：
1. **保留 `wande.ts` 作为唯一路由定义源**，修复它的 component+children 问题（见修复项 1-2）。
2. **将 `business.ts` 中的重复路由改为 `redirect`** 指向 `wande.ts` 的对应路由：
   ```ts
   // business.ts
   {
     path: 'project',
     name: 'BusinessProject',
     redirect: '/wande/project/index',
     meta: { hideInMenu: true }, // 或直接删除，视菜单需要
   },
   {
     path: 'opportunity',
     name: 'BusinessOpportunity',
     redirect: '/wande/opportunity',
     meta: { hideInMenu: true },
   },
   // ... 同处理 tender、crm 子路由
   ```
3. 如果业务上需要保留 "商务部" 这个菜单分组，可以在后端 `sys_menu` 表中把商务部的菜单 URL 直接配置为 `wande.ts` 的路由路径（如 `/wande/project/index`），不需要前端再定义一遍重复路由。
4. `business.ts` 中真正独立的两个页面 `agent-workbench` 和 `international-trade` 保留。

**长期方向**：
- 如果未来要完全切换到 `business.ts` 的菜单结构，需要：
  1. 把 `views/wande/` 下的业务组件逐步迁移到 `views/business/` 下；
  2. 为 business 侧独立开发 API（如 `/api/business/...`）；
  3. 统一后端菜单表、权限码和前端路由。
- **当前 Sprint 不建议做这么大的重构**，先以 redirect 收敛问题，消除 keep-alive 缓存冲突。

**涉及文件**:
- `apps/web-antd/src/router/routes/modules/wande.ts`
- `apps/web-antd/src/router/routes/modules/business.ts`
- 后端 `sys_menu` 表相关记录

---

## 三、P1 — 后端数据类型/API修复

### 修复项2-1：`has_embedding` 字段类型不匹配
**问题**: 
- 数据库建表脚本定义 `has_embedding integer DEFAULT 0`
- 但 Java 实体 `TenderData.java` / `TenderDataVo.java` 中定义为 `private Integer hasEmbedding`
- 实际 PG 数据库中该字段存储了 boolean 值（'t' / 'f'），导致 MyBatis / MapStruct 映射时可能抛类型转换异常，表现为列表数据全0或查询失败

**修复方案（建议方案A，兼容性好）**:
```sql
ALTER TABLE wdpp_tender_data 
ALTER COLUMN has_embedding TYPE integer 
USING CASE WHEN has_embedding::text = 't' THEN 1 ELSE 0 END;
```

如果数据库中还有其他表（如 `wande_project`、`dashboard` 相关表）存在同类型问题，一并检查修复。

**涉及文件**:
- `script/sql/wande-ai-pg.sql`
- `script/sql/update/...`（如有新增 migration 脚本）

---

### 修复项2-2：补充仪表盘缺失的两个 API 端点
**问题**: 前端 `api/wande/dashboard.ts` 调用了：
- `GET /wande/dashboard/funnel`
- `GET /wande/dashboard/client-level`

但后端 `DashboardController.java` 中只定义了：
- `/overview`
- `/quick-stats`
- `/recent-activities`
- `/trend`

缺少 `/funnel` 和 `/client-level`，导致仪表盘漏斗图和客户等级分布图表无法加载数据。

**修复方案**: 在 `DashboardController.java` 中补充两个端点：
```java
@GetMapping("/funnel")
public R<List<DashboardVo.FunnelStageVo>> getFunnelData() { ... }

@GetMapping("/client-level")
public R<List<DashboardVo.ClientLevelVo>> getClientLevelData() { ... }
```
并在 `IDashboardService` / 实现类中补充对应的 mock 或真实查询逻辑。如果暂时没有真实业务数据，可以先返回空数组或 mock 数据，避免前端报错。

**涉及文件**:
- `ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/controller/DashboardController.java`
- `ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/service/IDashboardService.java`
- `ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/service/impl/DashboardServiceImpl.java`
- `ruoyi-modules-api/wande-ai-api/src/main/java/org/ruoyi/wande/domain/vo/DashboardVo.java`

---

### 修复项2-3：工作流模块 SQL 报错
**问题**: 开发者反馈工作流模块存在 "SQL语法错误（PG类型转换问题）"。

**排查结果**: 当前 `ruoyi-workflow-api` 使用的是 MyBatis-Plus `ChainWrappers` 链式查询，没有手写 XML SQL。但前端 `/workflow` 对应的其实是另一个工作流系统（`adapters.httpPost('/workflow/add'...)`）。

**建议**: 如果报错发生在前端自定义的工作流设计师模块（`#/views/workflow/`）或其 API 调用中，需要进一步定位具体 SQL。请开发者提供报错日志中的完整 SQL 和堆栈，或者检查 `workflow_api` 相关表（如 `workflow_component`、`workflow_node` 等）是否存在隐式类型转换。若报错在 `ruoyi-workflow`（flowable）侧，请单独提 Issue 排查。

---

## 四、P2 — 工程化与规范建设

### 修复项3-1：添加路由完整性 CI 检查
在前端仓库添加一个脚本或 Vitest 测试，自动拦截以下问题：

```ts
// route-integrity.test.ts
// 1. 所有路由 name 全局唯一（包括 local.ts + modules/*.ts + core.ts）
// 2. 有 children 的路由不应同时有 component
// 3. 同一个 import('#/views/...') 不应被多个路由引用（允许 exceptions 如 coming-soon）
// 4. local.ts 中所有非根路由都应设置 hideInMenu: true
```

### 修复项3-2：在前端 CLAUDE.md 中加入路由规范
已有内容基础上补充 "规则2：component 和 children 互斥" 和 "规则3：一个 Vue 组件只被一个路由引用"。

---

## 五、执行顺序建议

| 顺序 | 修复项 | 负责端 | 预估时间 |
|-----|--------|--------|---------|
| 1 | 1-1 移除 local.ts Dashboard | front | 10 min |
| 2 | 1-2 修复 wande.ts component+children | front | 30 min |
| 3 | 1-4 / 1-5 修复 vben.ts / wande.ts 重复 name | front | 10 min |
| 4 | 2-1 修复 has_embedding 类型 | backend/db | 15 min |
| 5 | 2-2 补充 funnel / client-level API | backend | 1 h |
| 6 | 1-? 双路由体系去重（wande vs business） | front | 2 h（涉及菜单表同步） |
| 7 | 3-1 添加路由 CI 检查 | front | 1 h |

---

## 六、自检命令（开发者修完后执行）

```bash
# 1. 检查路由 name 唯一性
grep -rh "name:" apps/web-antd/src/router/routes/ | grep -oP "'[^']+'" | sort | uniq -d
# 输出必须为空

# 2. 检查 component + children 互斥
# 这条需要手动审计，或运行新加的 route-integrity.test.ts

# 3. 检查 component _import 重复引用
grep -rh "import('#/views/" apps/web-antd/src/router/routes/modules/ | grep -oP "'[^']+'\.vue" | sort | uniq -d
# 输出只能包含通用的 coming-soon.vue 等例外
```

---

**验收标准**: 
- `/analytics`、`/workspace` 不再 404 或根据业务决策正确移除
- `/wande-crm/crm` 客户列表正常显示，不再白屏
- 仪表盘漏斗图和客户等级图表有数据返回
- 招投标列表 `has_embedding` 正常显示 0/1，不再全0
- `tmux list-sessions` 无 CC 中断会话残留
