# 项目挖掘页面 — 详细设计文档

> 原型预览: https://www.perplexity.ai/computer/a/mo-de-aiping-tai-xiang-mu-wa-j-ql_RHIoATe.JVSYXtK4mKw
> 创建日期: 2026-04-09
> 状态: 已实现（归档版）
> 关联Bug: [#2852 Drawer内容泄漏导致表格完全不可用](https://github.com/WnadeyaowuOraganization/wande-play/issues/2852)（Open/P0）

---

## 1. 页面概述

| 属性 | 值 |
|------|-----|
| **路由** | `/wande-project/project` |
| **菜单层级** | 商务部 > 项目挖掘 |
| **权限标识** | `wande:project:mine:list` / `mine:query` / `mine:add` / `mine:edit` / `mine:remove` / `mine:export` |
| **所属模块** | `module:fullstack`（前后端联动） |
| **主要用户** | 商务人员（销售线索发现+跟进）、吴耀（超管视角） |
| **业务定位** | 国内招投标项目线索发现系统，接收 pipeline 自动采集的 9,015+ 条招标信号，商务逐一审核、分配、跟进 |

---

## 2. 页面布局

页面采用「顶部KPI + Tab切换 + 筛选栏 + 工具栏 + 表格/卡片」复合布局。主体分为两种视图：表格视图（全部Tab默认）和卡片视图（待我确认Tab专用）。

```
┌──────────────────────────────────────────────┐
│  顶部导航栏（万德AI平台 | 项目挖掘 | 吴耀）     │
├──────────────────────────────────────────────┤
│  面包屑: 首页 / 商务部 / 项目挖掘              │
├──────────────────────────────────────────────┤
│  [KPI卡片区] 总项目数 | A级 | B级 | 爬虫状态  │
├──────────────────────────────────────────────┤
│  [Tab栏] 全部|前期金矿|当前可投|待我确认|竞对动态|休眠/无效|垃圾桶 │
├──────────────────────────────────────────────┤
│  [筛选栏] 项目名称 | 省份 | 阶段 | 验证状态 | 匹配等级 | 最低评分 │
├──────────────────────────────────────────────┤
│  [工具栏] 新增 | 导出 | 重新评估 | 批量操作▼  ←→ 表格视图/卡片视图 │
├──────────────────────────────────────────────┤
│  [数据表格 / 卡片视图]                         │
│    └── 点击行 → 右侧抽屉（900px）              │
├──────────────────────────────────────────────┤
│  [分页器]                                      │
└──────────────────────────────────────────────┘
```

---

## 3. 功能区域详细说明

### 3.1 KPI统计卡片区

- **组件**: `a-statistic` + `a-card` + `a-row`/`a-col`
- **数据源**: `GET /wande/project/mine/stats` → `ProjectMineStatVo`
- **字段**:
  - `totalCount`: 总项目数
  - `aGradeCount`: A级项目数
  - `bGradeCount`: B级项目数
  - `crawlerStatus`: 爬虫状态（`running` | `stopped`）
- **刷新时机**: 页面加载 + 表格操作后调用 `loadStats()`
- **交互**: 无点击行为，只读展示

### 3.2 Tab栏

- **组件**: `a-tabs`（Ant Design Vue）
- **Tab列表**:

| key | 标签 | 图标 | 视图类型 | 筛选逻辑 |
|-----|------|------|----------|---------|
| `all` | 全部 | — | 表格 | 排除 `invalid` + `dormant` |
| `early_gold` | 前期金矿 | — | 表格 | `mineCategory = early_gold` |
| `investable` | 当前可投 | — | 表格 | `status IN (assigned, contacted, tracking, bid_preparing)` |
| `needs_confirm` | 待我确认 | — | **卡片** | `verificationStatus = needs_confirm` |
| `competitor` | 竞对动态 | — | 表格 | 竞品相关项目（后端逻辑） |
| `dormant_invalid` | 休眠/无效 | WarningOutlined | 表格 | `status IN (dormant, invalid)` |
| `trash` | 垃圾桶 | DeleteOutlined | 表格 | `deleted = 1`（软删除） |

- **切换行为**: 清空表单筛选 + 更新 `tabFilterParams` + 重新请求表格数据

### 3.3 搜索筛选栏

- **组件**: `VbenForm`（5列网格 `xl:grid-cols-5`）
- **字段**:

| 字段名 | 类型 | 绑定参数 |
|--------|------|---------|
| 项目名称 | Input | `title` |
| 省份 | Select多选 | `provinceFilter[]` |
| 阶段 | Select多选 | `stageCategoryFilter[]` |
| 验证状态 | Select单选 | `verificationStatusFilter` |
| 匹配等级 | Select单选 | `matchGradeFilter` |
| 最低评分 | InputNumber (0-100) | `minScore` |

### 3.4 工具栏

- **组件**: `a-space` + `a-button` + `a-dropdown`
- **按钮功能**:

| 按钮 | 图标 | 行为 | 权限 |
|------|------|------|------|
| 新增 | PlusOutlined | 打开新增抽屉（mode='add'） | `mine:add` |
| 导出 | DownloadOutlined | 调用 `POST /wande/project/mine/export` 下载Excel | `mine:export` |
| 搜索 | SearchOutlined | 触发表格查询 | — |
| 重新评估 | BarChartOutlined | 批量调用 `POST /wande/project/mine/matchGrade` | `mine:edit` |
| 批量操作▼ | DownOutlined | 展开下拉菜单（见下） | — |
| 表格视图 | — | 切换为 VxeGrid 表格 | — |
| 卡片视图 | — | 切换为卡片网格 | — |

- **批量操作下拉菜单**:
  - 批量标记有效线索（`feedbackType = good_lead`）
  - 批量标记无效线索（弹窗填原因 → `feedbackType = bad_lead`）
  - 批量催更新（弹窗填附言 → `nudgeBatchSend`）

### 3.5 数据表格

- **组件**: `VxeGrid`（Vben Admin封装，`id: 'wande-project-index'`）
- **数据源**: `GET /wande/project/mine/list`（分页+排序+筛选）
- **默认排序**: `scoreTotal DESC`
- **行点击**: 调用 `detailDrawerApi.open()` 打开右侧详情抽屉

**表格列定义**:

| 列标题 | 字段 | 宽度 | 类型 | 备注 |
|--------|------|------|------|------|
| 复选框 | — | 50 | checkbox | 支持跨页保留选中 |
| 项目标题 | `title` | 300 | 链接文本 | 固定左侧，超长截断 |
| 省份 | `province` | 80 | 文本 | — |
| 分类 | `mineCategory` | 100 | Tag | 见分类枚举 |
| 阶段 | `stageCategory` | 100 | 文本 | — |
| 匹配等级 | `matchGrade` | 80 | Badge | A红/B橙/C绿 |
| 总分 | `scoreTotal` | 80 | 数字 | 可排序 |
| 投资金额 | `investmentAmount` | 120 | 数字+万元 | — |
| 验证状态 | `verificationStatus` | 100 | Tag | 见验证状态枚举 |
| 状态 | `status` | 100 | Tag | 11种状态+颜色 |
| 发现时间 | `discoveredAt` | 160 | 日期时间 | — |
| 反馈 | `feedbackType` | 100 | Tag | 有效线索绿/无效线索红/- |
| 操作 | — | 280 | 按钮组 | 固定右侧，见操作说明 |

**行操作按钮**:
- `详情` → 打开详情抽屉 (mode='view')
- `编辑` → 打开编辑抽屉 (mode='edit')
- `重新评估` → `POST /wande/project/mine/{id}/matchGrade`
- `有效线索` → FeedbackButtons 组件 (feedbackType=good_lead)
- `无效线索` → FeedbackButtons 组件 (feedbackType=bad_lead)
- `流转▼` → 下拉菜单，显示当前状态的合法流转目标（STATUS_TRANSITIONS规则）→ `PUT /wande/project/mine/{id}/status`
- `催更新` → NudgeButton 组件 → `POST /wande/nudge/send`
- `删除` → Popconfirm确认 → `DELETE /wande/project/mine/{ids}`
- `恢复`（垃圾桶Tab专用）→ 恢复软删除

### 3.6 详情抽屉（MineDetailDrawer）

- **组件**: `useVbenDrawer({ connectedComponent: MineDetailDrawer })` — 当前存在 #2852 Bug（a-drawer嵌套+visible废弃API导致内容泄漏）
- **触发**: 点击表格行调用 `detailDrawerApi.open()`
- **宽度**: 900px
- **标题**: 动态，view=「项目详情」/ add=「新增项目」/ edit=「编辑项目」
- **数据加载**: view模式下并行调用 `projectMineInfo(id)` + `projectMineEnriched(id)` (含关联招标数据)

**内部7个Tab**:

| Tab | 内容 | 组件/数据 |
|-----|------|---------|
| 基本信息 | 两列表单（15个字段） | VbenForm + formSchema |
| 招标数据 | 招标信息表格 | `EnrichedProjectItem.tenderData[]` |
| 样品管理 | 样品统计卡片+申请表格 | SampleManagementTab |
| 配合单位 | 角色列表（甲方/代建方/设计院/施工总包/监理/劳务） | CounterpartManagementTab |
| 任务看板 | 三列看板（待接收/进行中/已完成） | TaskManagementTab |
| 操作记录 | 时间线 | ActivityTimeline |
| AI分析 | AI评分+匹配建议 | 展示 `matchReason` + `aiRecommendation` |

**基本信息表单字段**:

| 字段标签 | 字段名 | 类型 | 必填 |
|----------|--------|------|------|
| 项目标题 | `title` | Input | ✅ |
| 省份 | `province` | Input | ✅ |
| 城市 | `city` | Input | — |
| 分类 | `mineCategory` | Select | — |
| 阶段 | `stageCategory` | Input | — |
| 匹配等级 | `matchGrade` | Select (A/B/C) | — |
| 总分 | `scoreTotal` | InputNumber 0-100 | — |
| 投资金额 | `investmentAmount` | InputNumber + 万 | — |
| 验证状态 | `verificationStatus` | Select | — |
| 状态 | `status` | Select (11个) | — |
| 来源 | `sourceName` | Input | — |
| 信源链接 | `sourceUrl` | Input | — |
| 分配给 | `assignedTo` | Input | — |
| 预估金额 | `wandeEstimatedAmount` | InputNumber + 万 | — |
| 匹配理由 | `matchReason` | TextArea rows=3 | — |
| AI建议 | `aiRecommendation` | TextArea rows=3 | — |
| 发现时间 | `discoveredAt` | Input | — |

### 3.7 待我确认 — 卡片视图

- **触发条件**: Tab切换到 `needs_confirm`
- **组件**: `ProjectCard.vue`（自定义卡片）
- **布局**: `a-row` gutter=[16,16]，xs=24 / sm=12 / md=8 / lg=6（4列）
- **单卡片内容**: 项目名、省份+分类Tag、投资金额、评分Badge、AI建议摘要、三个操作按钮
- **卡片操作**:
  - `确认通过` → 更新 verificationStatus=verified
  - `留待观察` → 更新 verificationStatus=pending（观察）
  - `垃圾桶` → 软删除（弹窗填原因）
- **批量操作**: 多选后顶部浮动操作栏（批量确认通过/留待观察/垃圾桶）
- **分页**: `a-pagination`，独立的 cardPage 状态（pageSize=12）

### 3.8 弹窗组件

| 弹窗 | 触发 | 内容 |
|------|------|------|
| 垃圾桶原因弹窗 | 单项删除 | Select选择原因（6个预设 + 其他） |
| 批量标记无效线索 | 批量操作 | Select + 快速Tag选择 + TextArea（选其他时） |
| 批量催更新 | 批量操作 | TextArea附言 + 24h限制提示 |

---

## 4. 状态机定义

### 4.1 矿场状态（11个）

| 状态 | Key | Tag颜色 | 说明 |
|------|-----|---------|------|
| 未分配 | `unassigned` | default（灰） | 新入库未处理 |
| 已验证 | `verified` | blue | 人工验证通过 |
| 已分配 | `assigned` | orange | 已分配给商务 |
| 已联系 | `contacted` | cyan | 已联系甲方 |
| 跟进中 | `tracking` | green | 积极跟进 |
| 备标中 | `bid_preparing` | purple | 准备投标文件 |
| 已投标 | `bid_submitted` | magenta | 已提交投标 |
| 已中标 | `won` | gold | 赢得项目 |
| 已流失 | `lost` | red | 跟进失败 |
| 无效 | `invalid` | #595959（深灰） | 废弃 |
| 休眠 | `dormant` | #d9d9d9（浅灰） | 暂缓跟进 |

### 4.2 状态流转规则（STATUS_TRANSITIONS）

```
unassigned  → verified / assigned / invalid
verified    → assigned / invalid
assigned    → contacted / dormant / invalid
contacted   → tracking / bid_preparing / lost / dormant
tracking    → bid_preparing / lost / dormant
bid_preparing → bid_submitted / lost
bid_submitted → won / lost
won         → dormant
lost        → unassigned / dormant
invalid     → unassigned
dormant     → unassigned / invalid
```

### 4.3 分类枚举

| 标签 | Value | 说明 |
|------|-------|------|
| 早期金矿 | `early_gold` | 前期调研阶段的高价值项目 |
| 设备招标 | `bidding` | 已发布招标公告 |
| 施工谈判 | `contractor_negotiation` | 施工方正在谈判阶段 |
| 政策指导 | `policy` | 政策驱动项目 |
| 其他 | `other` | 未分类 |

### 4.4 验证状态枚举

| 标签 | Value |
|------|-------|
| 已验证 | `verified` |
| 待验证 | `pending` |
| 验证失败 | `failed` |
| 待确认 | `needs_confirm` |

---

## 5. API契约

### GET /wande/project/mine/list
- **权限**: `wande:project:mine:list`
- **请求参数** (PageQuery + ProjectMineBo):

| 参数 | 类型 | 说明 |
|------|------|------|
| `pageNum` | int | 页码 |
| `pageSize` | int | 每页数量 |
| `title` | String | 项目名称模糊搜索 |
| `provinceFilter` | String[] | 省份过滤（多选） |
| `stageCategoryFilter` | String[] | 阶段过滤（多选） |
| `verificationStatusFilter` | String | 验证状态过滤 |
| `matchGradeFilter` | String | 匹配等级过滤 |
| `minScore` | Integer | 最低评分 |
| `statusFilter` | String[] | 状态过滤（Tab切换时注入） |
| `orderByColumn` | String | 排序字段（默认 score_total） |
| `isAsc` | String | asc/desc（默认 desc） |

- **返回**: `TableDataInfo<ProjectMineVo>`（rows + total）

### GET /wande/project/mine/{id}
- **权限**: `wande:project:mine:query`
- **返回**: `ProjectMineVo`（基本信息）

### GET /wande/project/mine/{id}/enriched
- **权限**: `wande:project:mine:query`
- **返回**: `ProjectMineEnrichedVo`（基本信息 + tenderData[]）

### GET /wande/project/mine/stats
- **权限**: `wande:project:mine:stats`
- **返回**: `ProjectMineStatVo`（totalCount, aGradeCount, bGradeCount, crawlerStatus）

### GET /wande/project/mine/dashboard
- **权限**: `wande:project:mine:stats`
- **返回**: `MineDashboardVo`（漏斗数据等）

### POST /wande/project/mine
- **权限**: `wande:project:mine:add`
- **Body**: `ProjectMineBo`

### PUT /wande/project/mine
- **权限**: `wande:project:mine:edit`
- **Body**: `ProjectMineBo`

### PUT /wande/project/mine/{id}/status
- **权限**: `wande:project:mine:edit`
- **Body**: `{ status: String }`

### POST /wande/project/mine/matchGrade
- **说明**: 批量重新评估匹配等级
- **Body**: `{ ids: Long[] }`

### POST /wande/project/mine/feedback
- **Body**: `ProjectMineFeedbackBo`（projectId, feedbackType, feedbackReason）

### POST /wande/project/mine/batchStatus
- **Body**: `ProjectMineBatchStatusDto`（ids[], status, reason）

### DELETE /wande/project/mine/{ids}
- **权限**: `wande:project:mine:remove`
- **Path**: ids以逗号分隔

### POST /wande/project/mine/export
- **权限**: `wande:project:mine:export`
- **返回**: Excel文件流

---

## 6. 数据库设计

### 主表: `wdpp_project_mine`（推测名，需确认）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | BIGINT PK | 主键 |
| `title` | VARCHAR(500) | 项目标题 |
| `province` | VARCHAR(50) | 省份 |
| `city` | VARCHAR(100) | 城市 |
| `mine_category` | VARCHAR(50) | 分类枚举 |
| `stage_category` | VARCHAR(100) | 阶段 |
| `match_grade` | VARCHAR(10) | A/B/C |
| `score_total` | INT | 总评分 0-100 |
| `investment_amount` | DECIMAL(15,2) | 投资金额（万元） |
| `wande_estimated_amount` | DECIMAL(15,2) | 万德预估金额（万元） |
| `verification_status` | VARCHAR(50) | 验证状态枚举 |
| `status` | VARCHAR(50) | 11种状态枚举 |
| `source_name` | VARCHAR(200) | 来源名称 |
| `source_url` | TEXT | 信源链接 |
| `assigned_to` | VARCHAR(100) | 分配给（用户名） |
| `match_reason` | TEXT | 匹配理由 |
| `ai_recommendation` | TEXT | AI建议 |
| `feedback_type` | VARCHAR(50) | good_lead / bad_lead |
| `feedback_reason` | VARCHAR(500) | 反馈原因 |
| `discovered_at` | DATETIME | 发现时间（采集时间） |
| `deleted` | TINYINT(1) | 软删除标记 |
| `create_time` | DATETIME | 创建时间 |
| `update_time` | DATETIME | 更新时间 |
| `related_win_xxx` | (待确认) | 关联中标数据字段（#3228曾修复过缺失） |
| `create_dept` | BIGINT | 创建部门（#3228曾修复过缺失） |

### 关联表

| 表名 | 说明 |
|------|------|
| `wdpp_project_counterpart` | 配合单位信息（甲方/设计院等） |
| `wdpp_project_sample` | 样品管理记录 |
| `wdpp_project_task` | 任务看板记录 |
| `wdpp_project_feedback` | 反馈历史记录 |
| `wdpp_project_review` | 项目审核记录 |
| 招标数据表（pipeline侧） | tenderData通过 enriched 接口关联 |

---

## 7. 前端组件清单

| 组件名 | 文件路径 | 依赖 / 说明 |
|--------|----------|-------------|
| 主页面 | `views/wande/project/index.vue` | VxeGrid, useVbenDrawer, a-tabs, a-statistic |
| 详情抽屉 | `views/wande/project/mine-detail-drawer.vue` | ⚠️ 存在#2852 Bug（a-drawer嵌套+visible废弃） |
| 项目卡片 | `views/wande/project/project-card.vue` | 待我确认Tab专用卡片 |
| 反馈按钮 | `views/wande/project/feedback-buttons.vue` | good_lead/bad_lead操作 |
| 样品管理Tab | `views/wande/project/sample-management-tab.vue` | 抽屉内Tab |
| 配合单位Tab | `views/wande/project/counterpart-management-tab.vue` | 抽屉内Tab |
| 任务管理Tab | `views/wande/project/task-management-tab.vue` | 抽屉内Tab |
| 任务看板 | `views/wande/project/task-board.vue` | 三列看板 |
| 任务创建弹窗 | `views/wande/project/task-create-modal.vue` | 创建任务 |
| 任务详情抽屉 | `views/wande/project/task-detail-drawer.vue` | 任务详情 |
| 样品预览弹窗 | `views/wande/project/sample-preview-modal.vue` | 样品图片预览 |
| 样品申请历史 | `views/wande/project/sample-application-history.vue` | 申请历史列表 |
| 库存状态指示器 | `views/wande/project/inventory-status-indicator.vue` | 库存颜色标记 |
| D3颜色选择器 | `views/wande/project/d3-color-selector.vue` | D3参数化设计联动 |
| D3材质选择器 | `views/wande/project/d3-material-selector.vue` | D3参数化设计联动 |
| 黄金窗口工具 | `views/wande/project/golden-window.ts` | isGoldenWindowProject() |
| 数据定义 | `views/wande/project/data.ts` | 列定义/表单Schema/状态枚举/流转规则 |
| 操作记录时间线 | `views/wande/mine/activity-timeline.vue` | 共用组件 |
| 催更新按钮 | `components/nudge/NudgeButton.vue` | 全局共用 |
| API接口 | `api/wande/project.ts` | 所有矿场相关接口 |

---

## 8. H5适配方案

- **当前状态**: 未实现 H5 专用版
- **规划**: Sprint-2 企微审批贯通时一并补充
- **H5路由（规划）**: `/h5/project/mine`
- **组件库**: Vant 4
- **适配重点**: 卡片视图（ProjectCard）天然适合移动端，表格视图降级为纯列表卡片

---

## 9. PageGuide内容（待实现）

- **这是什么**: 全国招投标项目线索库，系统自动采集，商务人员在这里发现商机
- **解决什么问题**: 避免商务错过潜在项目，统一管理从发现→跟进→投标的全链路
- **快速上手**:
  1. 在「待我确认」Tab审核AI推送的项目，点「确认通过」或「垃圾桶」
  2. 对感兴趣的项目点「流转」推进状态（已分配→已联系→跟进中→备标中）
  3. 在详情抽屉的「配合单位」Tab记录甲方、设计院等关键联系人

---

## 10. 已知问题 & 待开发功能

### 已知Bug

| Issue | 优先级 | 描述 | 状态 |
|-------|--------|------|------|
| [#2852](https://github.com/WnadeyaowuOraganization/wande-play/issues/2852) | P0 | Drawer内容泄漏导致表格完全不可用（a-drawer嵌套+`:visible`废弃API） | Open |

### 待开发功能（Sprint-2 矿场增强）

| Issue | 功能 | Sprint |
|-------|------|--------|
| [#3118](https://github.com/WnadeyaowuOraganization/wande-play/issues/3118) | 项目配合单位关系图谱（关系网络Tab） | Sprint-1 |
| [#2255](https://github.com/WnadeyaowuOraganization/wande-play/issues/2255) | 转化漏斗看板页面 | Sprint-1 |
| [#2443](https://github.com/WnadeyaowuOraganization/wande-play/issues/2443) | ICP画像构建→矿场评分模型校准 | Sprint-1 |
| [#2704](https://github.com/WnadeyaowuOraganization/wande-play/issues/2704) | 中标概率评分可视化看板 | Sprint-Backlog |
| [#2700](https://github.com/WnadeyaowuOraganization/wande-play/issues/2700) | 早期项目信号检测 | Sprint-Backlog |
| [#2434](https://github.com/WnadeyaowuOraganization/wande-play/issues/2434) | 信号链自动串联 | Sprint-Backlog |
| [#2442](https://github.com/WnadeyaowuOraganization/wande-play/issues/2442) | Lookalike搜索模式（同类项目跨区域复制） | Sprint-Backlog |

---

## 11. 产品验收清单

- [ ] 访问 `/wande-project/project`，KPI卡片正常显示总项目数/A级/B级/爬虫状态
- [ ] Tab切换正常，各Tab筛选条件正确生效
- [ ] 表格显示9000+条数据，列齐全，操作按钮可用
- [ ] 点击表格行可正常打开右侧900px详情抽屉（#2852修复后）
- [ ] 详情抽屉内7个Tab正常切换，内容不互相污染
- [ ] 切换至「待我确认」Tab展示卡片视图，三个操作按钮功能正常
- [ ] 批量操作：多选→批量标记无效/催更新弹窗正常
- [ ] 「流转」下拉只显示当前状态合法的流转目标
- [ ] 导出功能正常下载Excel
- [ ] 无 `[antd: Drawer] visible is deprecated` 控制台警告（#2852修复后）
- [ ] H5端 `/h5/project/mine` 正常显示（Sprint-2完成后）

---

*本文档基于代码归档生成，对应代码版本 2026-04-09，由Perplexity Computer自动生成。*
*如需更新，请修改 `.github/docs/design/project-mine-详细设计.md` 并同步Issue引用。*
