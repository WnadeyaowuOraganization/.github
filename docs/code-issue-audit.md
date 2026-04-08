# 万德平台 代码↔Issue 全量对账报告

> **审计日期**: 2026-04-09
> **审计范围**: wande-play Monorepo (backend + frontend + pipeline + e2e)
> **基准看板**: Project#4 (1515 Items)
> **执行人**: Perplexity Computer (吴耀数字分身)

---

## 一、代码全貌

| 层 | 总量 | 说明 |
|---|------|------|
| 后端 | **405个Controller** / 5,287个Java文件 | 342个万德业务Controller，覆盖36个业务域 |
| 前端 | **592个Vue文件** | wande/ 310 + dashboard/ 79 + ops-hub/ 14 + h5/ 13 + 其他 176 |
| 管线 | **17个管线目录** / 133个Python文件 | domestic_projects(28py)最多，competitors(27py)次之 |
| E2E | e2e/tests/ | backend/api + front/e2e + front/smoke + pipeline/api + regression |
| 数据库 | SQL迁移脚本 | backend/script/sql/update/ (归档 + 增量) |

---

## 二、Issue全貌 (Project#4)

| 状态 | 数量 | 占比 | 说明 |
|------|------|------|------|
| Plan | 668 | 44% | 规划中，待排程 |
| Done | 465 | 31% | 已完成 |
| (空状态) | 238 | 16% | 手动添加时未设状态，需补设Plan |
| Todo | 113 | 7% | 研发经理已排程 |
| In Progress | 29 | 2% | 编程CC正在处理或排队中 |
| E2E Fail | 2 | <1% | D3结构风险分级 + 前端404 |

### Sprint分布

| Sprint | 数量 | 主题 |
|--------|------|------|
| Sprint-1 | 533 | 基座搭建（驾驶舱+D3+销售记录+询盘） |
| Sprint-2 | 202 | 商务全闭环（矿场+执行+审批+企微） |
| Sprint-3 | 70 | 商战情报 |
| Sprint-4 | 189 | 内容获客+数据 |
| Sprint-5 | 125 | 组织管理 |
| Sprint-6 | 227 | 财务+运营 |
| Sprint-7 | 41 | AI增强+知识 |
| Sprint-8 | 27 | 生态+售后 |
| Backlog | 91 | 待排期 |
| (空) | 10 | 未分配Sprint |

---

## 三、36个业务域 代码↔Issue 对账矩阵

### 核心业务域（代码量大，高优先级）

| # | 业务域 | 后端 | 前端 | 管线 | Issue状态 | 对账结论 |
|---|--------|------|------|------|-----------|----------|
| 1 | D3参数化设计 | 48+8个Controller, 402个Java | 12个Vue | 3个管线目录 | 82个open, S1 | ⚠️ 代码量远大于Issue，大量v1.0代码无Issue |
| 2 | 超管驾驶舱 | 15+13+12+4个Controller | 79+16+23个Vue | — | 95+10个open, S1 | ⚠️ 28个Controller已交付，Issue是增量 |
| 3 | 执行管理 | 10个Controller | 17+7个Vue | — | 57个open, S2 | ⚠️ 代码基础已具备，Issue是Sprint-2增量 |
| 4 | 项目矿场/招投标 | 5+2+3+1个Controller | 10+4+1个Vue | 28+7+1+5=41个py | 45+18个open, S1/2 | ✅ 代码和Issue对齐度较好 |
| 5 | 项目中心 | 4+3+3个Controller | 41+2个Vue | — | 22个open, S6 | ⚠️ 前端41个Vue已大量实现 |
| 6 | 合同管理 | 6个Controller, 81个Java | 13个Vue | — | S2/6 | ⚠️ 核心CRUD已完成，Issue是增量 |
| 7 | CRM/客户 | 3个Controller | 12+5个Vue | 1个py | 6个open, S2 | ⚠️ 代码大于Issue覆盖 |
| 8 | 财务/回款/预算 | 8+3+3+5个Controller, 104个Java | 11+6+5个Vue | — | S6 | ⚠️ 代码基础完整，Issue在远期Sprint |

### 中等业务域

| # | 业务域 | 后端 | 前端 | 管线 | Issue状态 | 对账结论 |
|---|--------|------|------|------|-----------|----------|
| 9 | 质保/售后 | 2+2+1+1个Controller, 124个Java | 4+5+1个Vue | — | 18+30个open, S8 | ⚠️ 代码先于Issue |
| 10 | 审批流引擎 | 2个Controller, 65个Java | 3个Vue | — | 22个open, S2 | 框架已有，Issue是企微扩展 |
| 11 | 协同修改 | 5个Controller, 58个Java | 无独立目录 | — | 17个open, S1 | ⚠️ 后端完整但前端缺失，需biz:collab标签 |
| 12 | 方案引擎/PPT | 3+2个Controller, 53个Java | 1个Vue | 9个py | 35个open | ⚠️ 后端>前端 |
| 13 | 标准规范 | 4个Controller, 56个Java | 4个Vue | — | 散落在D3/质保 | ⚠️ 无独立Issue标签 |
| 14 | 验收管理 | 5个Controller, 47个Java | h5/acceptance | — | 散落在执行管理 | ⚠️ 需独立biz:acceptance标签 |
| 15 | 整改管理 | 1个Controller, 42个Java | h5/repair | — | 散落在执行管理 | ⚠️ 需独立biz:rectification标签 |
| 16 | 变更管理 | 5个Controller, 35个Java | 无独立目录 | — | 散落在执行管理 | ⚠️ 需独立biz:change标签 |
| 17 | 竞品情报 | 3个Controller | 8个Vue | 27个py | S3 | ✅ 对齐 |
| 18 | 销售记录体系 | 4+1+1个Controller, 22个Java | 3+14个Vue | — | 16个open, S1 | ✅ 新建的，对齐度好 |
| 19 | 品牌中心 | 5个Controller | 5个Vue | — | S4 | ✅ 对齐 |
| 20 | 样品管理 | 2个Controller | 14个Vue | — | 16个open | ✅ 对齐 |
| 21 | 数据采集管线 | 1+1个Controller | 1个Vue | 17目录133个py | 17个open, S1/4 | ✅ Pipeline为主体 |
| 22 | 企微通知/审批 | 3+1+2个Controller | 4+13+9个Vue | — | 6+8个open, S2 | ✅ 对齐 |

### 辅助/小业务域

| # | 业务域 | 后端 | 前端 | 管线 | Issue状态 | 对账结论 |
|---|--------|------|------|------|-----------|----------|
| 23 | AI内容生成/设计 | 7个Controller | 6+2+1个Vue | 15+3个py | 14+36个open, S7 | 代码先行 |
| 24 | 人事管理 | 3+2个Controller, 22个Java | 2+4个Vue | — | 14个open, S5 | 代码先行 |
| 25 | 提成绩效 | 2个Controller, 10个Java | 4+3个Vue | — | S6 | 代码先行 |
| 26 | Claude Office | 含在cockpit | 7个Vue | — | S1迁移中 | 特殊：/opt迁移 |
| 27 | 代理商工作台 | 1个Controller | 4+4个Vue | — | S5 | 代码先行 |
| 28 | Ops Hub/业务运营 | 1个Controller | 14个Vue | — | S8 | 代码先行 |
| 29 | 工具中心 | 2+5个Controller, 37个Java | 1+2+1个Vue | — | S1 | 代码先行 |
| 30 | 报销费控 | 1个Controller | 含在comprehensive | — | S6 | 小模块 |
| 31 | S3知识资产 | 1个Controller, 16个Java | 3个Vue | — | S7 | 小模块 |
| 32 | 政策信号 | 无独立Controller | 1个Vue | 4个py | S4 | Pipeline为主 |
| 33 | 幼儿园发现 | 1个Controller | 2个Vue | 1个py | Backlog | 小模块 |
| 34 | DORA指标 | 1个Controller | 1个Vue | — | S1 | ✅ 对齐 |
| 35 | GPU监控 | 1个Controller | 1+1个Vue | — | S1 | ✅ 对齐 |
| 36 | 素材库/DAM | wande/asset+design | 7+6个Vue | — | 17个open, S4 | 对齐 |

---

## 四、6大对账发现

### 发现1：代码远超Issue —— "代码先行"模式

465个Done Issue只是冰山一角。代码库中5,287个Java文件 + 592个Vue文件中，大量代码在Issue体系建立前（Monorepo迁移前）就已存在。这些代码从未有对应Issue，属于**合法的历史代码**。

**影响**: D3(402个Java)、超管驾驶舱(44个Controller+118个Vue)、合同(81个Java)、财务(104个Java)、审批(65个Java) 等核心模块的基础代码均无Issue对应。

### 发现2：1个异常PR

| PR | Issue | 状态 | 处理 |
|----|-------|------|------|
| PR#3435 (模板库管理页面) | #2261 (CLOSED) | PR还Open | 应关闭PR |

### 发现3：87个过期分支

- 78个 `feature-Issue-*` 分支对应Issue已关闭
- 5个旧格式 `feature/` 分支中4个已过期
- 4个已merge PR分支未删除
- **建议**: 批量清理 + 开启仓库 auto-delete head branches

### 发现4：29个In Progress中21个无代码

研发经理CC排程后标记In Progress，但编程CC还在排队。**正常现象**，如长期不动则排程有问题。

### 发现5：238个Issue无看板状态

上次批量添加230个Issue到Project#4时未自动设置状态。**需补设Plan**。

### 发现6：4个业务域无独立Issue标签（已治理）

| 代码业务域 | 代码量 | 散落位置 | 新增标签 | 治理动作 |
|-----------|--------|----------|---------|---------|
| 验收管理 (acceptance) | 47个Java + 5个Controller | 执行管理Issue中 | `biz:acceptance` | 扫描归档 |
| 变更管理 (change) | 35个Java + 5个Controller | 执行管理Issue中 | `biz:change` | 扫描归档 |
| 整改管理 (rectification) | 42个Java + 1个Controller | 执行管理Issue中 | `biz:rectification` | 扫描归档 |
| 协同修改 (collab) | 58个Java + 5个Controller | 散落无归属 | `biz:collab` | 扫描归档 |

---

## 五、后端业务域路由汇总（按Controller数量排序）

| 路由前缀 | Controller数 | 业务域 |
|----------|-------------|--------|
| wande/d3/* | 48 | D3参数化设计 |
| wande/cockpit/* | 15 | 超管驾驶舱 |
| api/v1/* | 14 | 通用API（验收/执行/佣金等） |
| api/dashboard/* | 13 | 驾驶舱API |
| wande/dashboard/* | 12 | 驾驶舱管理 |
| wande/execution/* | 10 | 执行管理 |
| wande/finance/* | 8 | 财务体系 |
| api/d3/* | 8 | D3 API |
| api/design/* | 7 | 设计AI |
| wande/contract/* | 6 | 合同管理 |
| wande/mine/* | 5 | 项目矿场 |
| wande/change/* | 5 | 变更管理 |
| wande/brand/* | 5 | 品牌中心 |
| monitor/ext-tool/* | 5 | 工具中心 |
| api/intl/* | 5 | 国际贸易 |
| api/collab/* | 5 | 协同修改 |
| wande/standard/* | 4 | 标准规范 |
| wande/sales-tracking-config/* | 4 | 销售记录 |
| wande/problem/* | 4 | 问题发现 |
| system/dashboard/* | 4 | 系统驾驶舱 |
| project-center/* | 4 | 项目中心 |

---

## 六、前端页面分布（按Vue文件数排序）

| 目录 | Vue文件数 | 业务域 |
|------|----------|--------|
| wande/project | 41 | 项目中心 |
| wande/dashboard | 23 | 驾驶舱视图 |
| wande/execution | 17 | 执行管理 |
| wande/cockpit | 16 | 超管驾驶舱 |
| wande/sample | 14 | 样品管理 |
| wande/contract | 13 | 合同管理 |
| wande/crm | 12 | CRM |
| wande/d3 | 12 | D3参数化 |
| wande/finance | 11 | 财务 |
| wande/mine | 10 | 项目矿场 |
| wande/competitor | 8 | 竞品情报 |
| wande/claude-office | 7 | Claude Office |
| wande/asset | 7 | 素材库 |
| wande/budget | 6 | 预算 |
| wande/design-asset | 6 | 设计资产 |
| ops-hub/ | 14 | 业务运营中心 |
| dashboard/ | 79 | 驾驶舱(旧路由) |
| h5/ | 13 | 移动端 |

---

## 七、Pipeline管线分布

| 管线目录 | Python文件数 | 业务域 |
|----------|-------------|--------|
| domestic_projects | 28 | 国内招标项目采集 |
| competitors | 27 | 竞品数据采集 |
| comfyui_rendering | 15 | AI图片渲染 |
| shared | 13 | 共享工具库 |
| proposal_import | 9 | 方案导入 |
| shenzhen_govt | 7 | 深圳政府项目 |
| d3_knowledge | 7 | D3知识库 |
| d3_component_library | 6 | D3组件库 |
| win_rate_prediction | 5 | 赢率预测 |
| d3_product_catalog | 4 | D3产品目录 |
| policy_signals | 4 | 政策信号 |
| design_ai | 3 | 设计AI |
| products | 2 | 产品数据 |
| domestic_clients | 1 | 国内客户 |
| tender | 1 | 招标通用 |
| kindergarten_discovery | 1 | 幼儿园发现 |
| international_clients | 0 | 国际客户（空目录） |

---

## 八、待执行清理项

| 优先级 | 项目 | 状态 |
|--------|------|------|
| P0 | 关闭 PR#3435 | 待执行 |
| P1 | 批量删除87个过期分支 | 待执行 |
| P1 | 238个空状态Issue补设Plan | 待rate limit恢复 |
| P1 | 开启仓库 auto-delete head branches | 待执行 |
| P2 | 4个biz:标签创建+归档 | 本次执行 |

---

*本文档为Sprint规划基准文档，后续Sprint结束时更新对账数据。*

---

## 九、超管驾驶舱 原型↔代码↔Issue 三方对账（2026-04-09）

### 背景

超管驾驶舱是代码量最大的模块（80个Vue + 44个Controller + 128个已完成Issue），但Issue散落严重、biz:cockpit标签覆盖不全、存在过度开发风险。本次基于已确认原型做三方对账，将47个待判断Issue精简到20个。

### 原型确认范围

**原型位置**: `.github/docs/design/耀总驾驶舱/prototype.html`（超管驾驶舱部分）
**Master Issue**: #3466

原型确认的功能分为两类：

| 类别 | 内容 | 代码状态 |
|------|------|---------|
| 已有Tab（代码已实现） | Agent效率、CC错误日志、Token Pool、部署记录、远程命令、审批队列、验收监控、告警规则、企微消息、模块健康、网关子账户、CFD、开发者活动、问题发现、反馈管理、定时任务、Issue看板、确认中心、Claude Office | 80个Vue + 44个Controller |
| 4个新增Tab | #3481实时日志流、#3482 FinOps成本看板、#3483安全审计、#3484 Prompt管理 | 待开发 |

### 决策过程

47个待判断Issue逐一与原型+代码交叉比对，按三个维度分类：

1. **原型中有这个功能吗？** → 没有则关闭
2. **属于超管驾驶舱还是其他业务域？** → 其他域则修正标签
3. **代码已实现还是纯增量？** → 已实现的Issue关注Bug修复，非功能扩展

### 关闭的22个Issue（not planned）

| Issue | 标题 | 关闭原因 |
|-------|------|---------|
| #3166 | 企微审批效率分析 | 属于审批流引擎(biz:approval) |
| #3165 | 审批双端同步看板 | 属于审批流引擎(biz:approval) |
| #3125 | 管线异常企微告警 | 属于数据管线运维，非驾驶舱页面 |
| #3123 | pipeline.sh权限修复 | 纯运维bug，非驾驶舱功能 |
| #2947 | 区域覆盖度地图页面 | 原型中无地图组件，过度开发 |
| #2946 | 数据质量KPI仪表盘页面 | 与#2926重叠，P1前端等后端完成再做 |
| #2945 | Schema漂移检测 | 纯pipeline后端，非驾驶舱页面 |
| #2943 | 区域覆盖度热力图API | 与#2947配对关闭 |
| #2735 | 情报中台总览卡片 | 属于商战情报中台(biz:intelligence-hub) |
| #2682 | 情报中台API网关 | 属于商战情报中台(biz:intelligence-hub) |
| #2680 | 统一通知中心基座 | 属于商战情报中台(biz:intelligence-hub) |
| #2667 | 库存同步定时任务 | 属于样品管理(biz:sample)，误关联 |
| #2267 | 企微通知中心状态 | 属于企微集成(biz:wecom) |
| #1578 | 制度复审提醒 | 属于人事制度管理，误关联 |
| #2297 | 群聊管理页面 | 原型中无此功能 |
| #1623 | 统一对话日志表 | 纯后端数据模型，无驾驶舱页面关联 |
| #2314 | 设计模块入口页 | 属于设计AI(biz:design-ai) |
| #1525 | D3 API Gateway | 属于D3参数化 |
| #1868 | AR安装指导POC | P2实验性，远期 |
| #2036 | root_cause_analyzer脚本 | G7e运维脚本，非驾驶舱页面 |
| #2164 | 图图迁移ComfyUI | P3，v43.0已确认不属于驾驶舱 |
| #2174 | OCR文档支持 | 属于知识库模块 |

### 标签修正（8个Issue）

| Issue | 修正动作 |
|-------|---------|
| #2247 CRM操作面板 | 移除biz:cockpit，保留biz:ops-hub |
| #2492 欧美竞品采集 | 移除biz:cockpit，属于D3参数化 |
| #2028 矿场增量同步 | 移除biz:cockpit，属于项目矿场 |
| #1770 统一权限管理 | 新建biz:rbac标签并添加 |
| #2078 原因诊断API | 保留biz:cockpit（问题发现属于驾驶舱业务板块） |
| #2317 D3确认中心 | 确认无biz:cockpit |
| #1773/#1772/#2138 协同修改 | 确认无biz:cockpit，已有biz:collab |

### 清理后最终格局（20个open Issue）

| 分类 | Issue | 优先级 | Sprint建议 |
|------|-------|--------|-----------|
| **Bug修复** | #3469 MyBatis别名冲突 | P0 | 立即 |
| | #3470 驾驶舱API 404 | P1 | 立即 |
| | #3471 反馈API 404 | P1 | 立即 |
| **4个新Tab** | #3481 实时日志流 | P0 | Sprint-1 |
| | #3482 FinOps成本看板 | P0 | Sprint-1 |
| | #3483 安全审计 | P0 | Sprint-1 |
| | #3484 Prompt管理 | P0 | Sprint-1 |
| **数据管线增强** | #3300 管线监控Dashboard | P0 | Sprint-1 |
| | #3301 加密文件管理 | P0 | Sprint-1 |
| | #3302 管线错误告警 | P0 | Sprint-1 |
| | #3303 管线状态API | P0 | Sprint-1 |
| | #3304 驾驶舱管线Tab | P0 | Sprint-1 |
| | #2925 字段完整度引擎 | P0 | Sprint-1 |
| | #2926 数据质量KPI API | P0 | Sprint-1 |
| | #2944 异常检测引擎 | P0 | Sprint-1 |
| **开发者协同** | #2849 Agent效率看板前端 | P1 | Sprint-1 |
| | #2851 验收队列前端 | P1 | Sprint-1 |
| | #2275 DORA指标卡片 | P1 | Sprint-2 |
| **其他** | #2893 Claude Office迁移 | P0 | Sprint-1 |
| | #2296 安全审计页面 | P1 | Sprint-1 |
| | #2298 AI对话监控面板 | P0 | Sprint-1 |

### 最佳实践参考

本次清理遵循 [Callibrity Platform Engineering](https://www.callibrity.com/articles/common-pitfalls-of-internal-developer-platforms-and-how-to-avoid-them) 的核心建议：
- **避免"工具工厂"陷阱**: 用原型画线，原型有的做，没有的不做
- **先稳定再扩展**: 3个Bug优先修，让已有80个Vue先跑通
- **度量驱动**: DORA指标(#2275)纳入Sprint-2，建立成功度量基线
- **增量交付**: 4个新Tab聚焦Sprint-1，不铺更多功能
