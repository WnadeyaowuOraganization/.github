# Sprint-2 排程计划：商务全闭环

> 创建日期：2026-04-18 | 状态：待启动
> 主题：矿场发现→投标→签约→执行→审批→回款（能赚钱）
> 并发上限：15个CC | 基于 Sprint-1 已交付基座
> 前置条件：Sprint-1 全部 Done（2026-04-16 完成），明道云历史商机 4,418 条已导入矿场

## 排程原则

1. **Tier-A 矿场增强最先**：Sprint-1 已交付矿场 v3.0 + CRM，历史数据已导入，增强功能直接可用
2. **后端先于前端**：数据模型/API 先行，前端配对跟进
3. **Tier-A 和 Tier-B 可并行**：矿场是"发现项目"，执行管理是"交付项目"，无依赖
4. **合同回款串行**：数据库→API→前端，有强依赖链
5. **同模块 Entity/Mapper/Service 的 Issue 串行**：避免 Flyway/Bean 冲突

---

## Tier-A：矿场增强（最优先，延续 Sprint-1 矿场主线）

> Sprint-1 已交付：矿场 v3.0 页面(#3458) + 3轮缺陷修复 + 省份热力图 + 关键词池 + 竞品网络 + 幼儿园专题 + 转化漏斗API + 赢率评分
> 明道云历史数据：4,418 条商机 → wdpp_project_mine，含负责人分配记录

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3631 | P1 | bidding | pipeline↔后端表对齐全景规划（19张表统一接入路径） | ✅ | 无 |
| #2028 | P1 | backend | 矿场项目信息增量同步推送 — 持续更新业务员信息 | ✅ | 无 |
| #2243 | P1 | backend | 简报偏好设置页 — 配置关注区域/项目类型/通知时间 | ✅ | 无 |
| #2238 | P1 | frontend | 作战资料包一页纸展示 — 项目详情页新 Tab | ✅ | #3458 |
| #1874 | P1 | backend | 前期项目分阶段跟进提醒 + 自动升级/降级 | ✅ | 无 |
| #1523 | P2 | bidding | 区域品类矩阵统计 API — 省份×产品品类交叉统计 | ✅ | 无 |
| #2404 | P2 | bidding | 复盘数据驱动评分迭代 — 赢/输/流标→评分模型调整 | ✅ | 无 |
| #2398 | P2 | mine | 竞品中标记录采集 — 从中标公示识别竞争对手 | ✅ | 无 |

> **并行策略**：#3631/#2028/#2243/#1874 可4CC并行，均无交叉依赖

---

## Tier-B：执行管理增强（中标后项目交付，与 Tier-A 并行）

> Sprint-1 已交付：执行管理 v2.0 全部 22 个 Issue（三模式阶段/合同/交付/BOM/变更/回款/文档/售后）
> Tier-B 是在 v2.0 基础上做增强

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3193 | P1 | backend | 项目主计划数据模型 — project_master_plan + plan_milestone | ✅ | 无 |
| #1692 | P1 | backend | 项目成本跟踪 API — 自动汇总+手动补充+偏差分析 | ✅ | 无 |
| #2097 | P1 | backend | 验收检查项模板管理 — 按设备类型+批量导入 | ✅ | 无 |
| #1830 | P1 | backend | 利润风险预警中心+仪表盘+项目详情预警 | ⏳ | #1692 |
| #1790 | P1 | frontend | 变更影响分析面板+审批操作+全局变更看板 | ✅ | 无 |
| #1808 | P1 | frontend | 采购/生产/安装/文档/历史 Tab 页面 | ✅ | 无 |
| #1728 | P1 | execution | 施工安全管理页面 — 交底/日志/隐患/事故/培训/证书 | ✅ | 无 |
| #1762 | P1 | execution | 安装管理移动端 — 三种安装模式+电子签名 | ⏳ | H5基座 |

> **并行策略**：#3193/#1692/#2097/#1790/#1808/#1728 可6CC并行；#1830 等 #1692

---

## Tier-C：合同+回款（商务闭环资金链）

> Sprint-1 已交付：CRM-07 投标申请 + CRM-08 回款跟踪 + 执行管理 Tab3 合同与交付 + Tab6 回款
> Tier-C 做合同管理独立模块 + 回款资料管理

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3108 | P2 | backend | 合同数据表国贸+经销字段扩展 | ✅ | 无 |
| #2113 | P1 | backend | 合同审批流程 — 待审批列表+审批记录+企微通知 | ✅ | 无 |
| #1750 | P1 | frontend | AI 条款对比前端 — 左右分栏+差异高亮 | ✅ | 无 |
| #1752 | P1 | frontend | 合同审批前端 — 待审批列表+审批页面+AI风险报告 | ⏳ | #2113 |
| #2023 | P1 | approval | 合同管理模块接入审批流 — 盖章/签署自动发起 | ⏳ | #2113 |
| #1999 | P2 | finance | 阶段凭证数据库 — project_stage_documents | ✅ | 无 |
| #1998 | P2 | finance | 阶段凭证管理 API — 上传+完整度检查+催收联动 | ⏳ | #1999 |
| #1997 | P2 | finance | 回款周报数据库+引擎 | ✅ | 无 |
| #1996 | P2 | finance | 回款周报 API — 商务填写+评估+审阅全流程 | ⏳ | #1997 |

> **串行约束**：合同审批 #2113→#1752→#2023；回款凭证 #1999→#1998；回款周报 #1997→#1996
> **并行窗口**：#3108/#2113/#1750/#1999/#1997 可5CC并行

---

## Tier-D：项目中心（项目全景+风险台账+经验库）

> feature-registry 标注 Sprint-6，但基础页面可提前到 Sprint-2
> Sprint-1 已交付部分：#240 项目费用归集

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2520 | P2 | backend | 项目文档中心数据库 — project_documents | ✅ | 无 |
| #2523 | P2 | backend | 文档中心 API — CRUD+分类+权限 | ⏳ | #2520 |
| #2351 | P1 | project | 项目列表健康度灯+阶段切换拦截弹窗 | ✅ | 无 |
| #2352 | P2 | project | 风险台账 Tab 前端 — 风险列表+录入+处置+附件 | ✅ | 无 |
| #1627 | P1 | project | 风险台账联动 — 严重整改自动升级为 risk_event | ⏳ | #2352 |
| #2299 | P1 | project | 整改统计仪表盘 — 闭环率/平均时长/问题分布 | ✅ | 无 |
| #2300 | P1 | project | AI审查结果展示 — 照片标注叠加层+标准对比 | ✅ | 无 |
| #1991 | P1 | project | 经验卡片 API — CRUD | ✅ | 无 |
| #1992 | P1 | project | 经验卡片 Service — AI生成+双审+标签+企微通知 | ⏳ | #1991 |
| #2350 | P1 | project | 经验库页面 — 卡片列表+详情+审阅+标签云 | ⏳ | #1991 |

> **并行策略**：#2520/#2351/#2352/#2299/#2300/#1991 可6CC并行

---

## Tier-E：CRM增强+商务赋能（Sprint-1 CRM基座上增强）

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1896 | P1 | crm | 客户情报 Phase1: business_opportunities 增强 | ✅ | 无 |
| #2258 | P1 | crm | 商机/项目下设计单前端 — 一键弹窗+自动填充 | ✅ | 无 |
| #3103 | P2 | fullstack | 报价单生成+PDF导出 — 三线差异化模板 | ✅ | 无 |
| #3105 | P2 | fullstack | 订单跟踪看板 — PI确认到发货全流程可视化 | ✅ | 无 |
| #1672 | P1 | biz-enablement | 直销投标文档生成 API | ✅ | 无 |
| #1715 | P1 | biz-enablement | 直销投标文档生成页面 — 选品→预览→导出 | ⏳ | #1672 |

---

## 时间线估算

```
Week 1 (4/19-4/25):
  Tier-A: #3631+#2028+#2243+#2238 矿场增强4CC并行
  Tier-B: #3193+#1692+#2097 执行增强3CC并行
  Tier-C: #3108+#2113+#1999+#1997 合同回款基础4CC并行
  ≈ 11CC

Week 2 (4/26-5/02):
  Tier-A: #1874+#1523+#2404+#2398 矿场增强续
  Tier-B: #1830+#1790+#1808+#1728 执行增强续
  Tier-C: #1750+#1752+#1998+#1996 合同回款前端
  Tier-D: #2520+#2351+#2352 项目中心启动
  ≈ 13CC

Week 3 (5/03-5/09):
  Tier-C: #2023 合同审批对接
  Tier-D: #2523+#1627+#2299+#2300+#1991 项目中心核心
  Tier-E: #1896+#2258+#3103 CRM增强
  ≈ 10CC

Week 4 (5/10-5/16):
  Tier-D: #1992+#2350 经验库
  Tier-E: #3105+#1672+#1715 商务赋能
  Tier-B: #1762 安装移动端
  收尾: 全量E2E测试 + 商务部验收
  ≈ 6CC
```

## CC分配策略

| 阶段 | 活跃CC数 | 分配 |
|------|---------|------|
| Week 1 | 11 | Tier-A(4) + Tier-B(3) + Tier-C(4) |
| Week 2 | 13 | Tier-A(4) + Tier-B(4) + Tier-C(4) + Tier-D(1) |
| Week 3 | 10 | Tier-C(1) + Tier-D(5) + Tier-E(3) + 补位(1) |
| Week 4 | 6 | Tier-D(2) + Tier-E(3) + 收尾(1) |

---

# 以下内容由排程经理每次排程后维护

## 指派建议（下一批）

> 更新于 2026-04-19（本批）。当前有效运行 kimi1/#2234 + kimi3/#2231等CI + kimi4/#1502（空槽 2 个：kimi6/kimi19）。
> Sprint-2 主干 issue 已基本完成；审批体系 6 个 issue 全部被阻塞（#3167/#2027/#2270/#3161 仍 OPEN）。
> 以下均已确认无未满足前置，可立即派出。

| 建议kimi | Issue | 优先 | 模块 | 内容 | 备注 |
|---------|-------|------|------|------|------|
| kimi1  | #2102 | P2 | backend | 质保售后触发二次商机 — 维修发现需求+满意度复购 | status:ready，无强前置 |
| kimi3  | #1892 | P1 | crm/backend | 客户情报P3 经销商信息提交模板+自动校验 | status:test-passed，无强前置 |

> ⚠️ 审批体系 #3169/#3174/#3168 待 #3167(动态表单引擎) 完成后解锁；#3150/#3149 待 **#2027**（kimi3 In Progress）完成后解锁。
> ⚠️ #1728-后端/前端（施工安全6模块追补）待研发经理拆 Issue 后派出。

## 当前运行

| 指派目录 | Issue | 模块 | 内容 | 状态 |
|---------|-------|------|------|------|
| kimi1  | #3174 | approval | 表单模板导入导出+配置向导 — 模板迁移+快速配置 [流程补齐8/8] | 已派 |
| kimi3  | #3179 | project360 | 项目360统一看板页面 — 中标前后共用·阶段自动切换·多Tab聚合 [1/6] | 已派 |
| kimi4  | #3185 | finance | 全阶段资料完成度看板 — 全项目×全阶段文件完整度+法规缺失预警 [1/13] | 已派 |
| kimi6  | #3155 | approval | 流程简化配置页 — 跳过/自动审批/路由规则可视化配置（#3152+#3153+#3154解锁） | 进行中(后端done→前端开发中) |
| kimi19 | #3188 | finance | 企业信息库 — 万德常用信息维护+一键填充到回款表单 [4/7] | 已派 |

## 指派历史（完成后划线）

> 研发经理维护。指派时新增行，完成后在内容列加删除线。

| 指派目录 | Issue | Tier | 模块 | 内容 | 看板状态 |
|---------|-------|------|------|------|---------|
| kimi1 | #3631 | Tier-A | bidding | ~~pipeline↔后端表对齐全景规划~~ | ~~Done~~ |
| kimi2 | #2028 | Tier-A | backend | ~~矿场项目信息增量同步推送~~ | ~~Done~~ |
| kimi3 | #2243 | Tier-A | backend | ~~简报偏好设置页~~ | ~~Done~~ |
| kimi4 | #3193 | Tier-B | backend | ~~项目主计划数据模型~~ | ~~Done~~ |
| kimi5 | #1692 | Tier-B | backend | ~~项目成本跟踪API~~ | ~~Done~~ |
| kimi6 | #2238 | Tier-A | frontend | ~~作战资料包一页纸展示~~ | ~~Done~~ |
| kimi7 | #2097 | Tier-B | backend | ~~验收检查项模板管理~~ | ~~Done~~ |
| kimi8 | #3108 | Tier-C | backend | ~~合同数据表扩展~~ | ~~Done~~ |
| kimi9 | #2113 | Tier-C | backend | ~~合同审批流程~~ | ~~Done~~ |
| kimi10 | #1999 | Tier-C | finance | ~~阶段凭证数据库~~ | ~~Done~~ |
| kimi11 | #1997 | Tier-C | finance | ~~回款周报数据库+引擎~~ | ~~Done~~ |
| kimi1 | #2258 | Tier-E | frontend | ~~商机/项目下设计单前端~~ | ~~Done~~ |
| kimi2 | #1874 | Tier-A | backend | ~~前期项目分阶段跟进提醒~~ | ~~Done~~ |
| kimi3 | #1991 | Tier-D | backend | ~~经验卡片API~~ | ~~Done~~ |
| kimi2 | #2404 | Tier-A | backend | ~~复盘数据驱动评分迭代~~ | ~~Done~~ |
| kimi4 | #2299 | Tier-D | backend | ~~整改统计仪表盘~~ | ~~Done~~ |
| kimi3 | #1992 | Tier-D | backend | ~~经验卡片Service(AI生成+双审+标签)~~ | ~~Done~~ |
| kimi6 | #2350 | Tier-D | frontend | ~~经验库页面(卡片列表+详情+审阅)~~ | ~~Done~~ |
| kimi6 | #1808 | Tier-B | frontend | ~~采购/生产/安装/文档/历史 Tab 页面~~ | ~~Done~~ |
| kimi6 | #1896 | Tier-E | crm | ~~客户情报Phase1: business_opportunities增强~~ | ~~Done~~ |
| kimi6 | #1672 | Tier-E | biz | ~~直销投标文档生成API~~ | ~~Done~~ |
| kimi2 | #1750 | Tier-C | frontend | ~~AI条款对比前端(左右分栏+差异高亮)~~ | ~~Done~~ |
| kimi2 | #1728 | Tier-B | execution | ~~施工安全管理页面(仅建表+契约+菜单，Java+前端追补)~~ | ~~Done(部分)~~ |
| kimi2 | #1998 | Tier-C | finance | ~~阶段凭证管理API(上传+完整度检查+催收联动)~~ | ~~PR#3870~~ |
| kimi2 | #1728-后端 | Tier-B | execution | (待拆Issue)施工安全6模块Java实现 | ⏳ 待派 |
| kimi2 | #1728-前端 | Tier-B | execution | (待拆Issue)施工安全6模块前端页面 | ⏳ 待派 |
| kimi2 | #2520 | Tier-D | project | ~~项目文档中心数据库(project_documents+versions)~~ | ~~Done(PR#3874)~~ |
| kimi2 | #2522+#2523 | Tier-D | project | ~~文档中心Service+API(合并实现)~~ | ~~Done(PR#3876)~~ |
| kimi4 | #1501 | Phase3 | mine | ~~区域市场BI数据模型(area_market_stats表)~~ | ~~Done(PR#3878)~~ |
| kimi4 | #1752 | Tier-C | frontend | ~~合同审批前端(待审批列表+审批页面)~~ | ~~Done~~ |
| kimi4 | #2023 | Tier-C | approval | ~~合同管理接入审批流(盖章/签署自动发起)~~ | ~~Done~~ |
| kimi4 | #1523 | Tier-A | bidding | ~~区域品类矩阵统计API(省份×产品品类交叉)~~ | ~~Done(PR#3871)~~ |
| kimi4 | #2300 | Tier-D | project | ~~AI审查结果展示(照片标注叠加层+标准对比)~~ | ~~PR#3875~~ |
| kimi1 | #3105 | Tier-E | fullstack | ~~订单跟踪看板(PI确认→发货全流程)~~ | ~~Done(仅建表)~~ |
| kimi20 | #3859 | infra | fullstack | ~~CC测试环境一键就绪验证~~ | ~~Done~~ |
| kimi1 | #1830 | Tier-B | backend | ~~利润风险预警中心+仪表盘+项目详情预警~~ | ~~Done~~ |
| kimi1 | #2352 | Tier-D | project | ~~风险台账Tab前端(风险列表+录入+处置+附件)~~ | ~~Done(PR#3873)~~ |
| kimi1 | #1627 | Tier-D | project | ~~风险台账联动(严重整改自动升级risk_event)~~ | ~~Done(PR#3877)~~ |
| kimi19 | #2351 | Tier-D | project | ~~项目列表健康度灯+阶段切换拦截弹窗~~ | ~~Done~~ |
| kimi19 | #2398 | Tier-A | mine | ~~竞品中标记录采集(后端+前端)~~ | ~~Done(PR#3884)~~ |
| kimi3 | #1790 | Tier-B | frontend | ~~变更影响分析面板+审批操作+全局变更看板~~ | ~~Done~~ |
| kimi3 | #3103 | Tier-E | biz | ~~報價單生成+PDF導出(三線差異化模板)~~ | ~~Done(PR#3879)~~ |
| kimi6 | #1715 | Tier-E | biz | ~~直销投标文档生成页面(选品→预览→导出)~~ | ~~Done(PR#3881)~~ |
| kimi6 | #2232 | Phase4 | mine | ~~移动端胜率卡片(竖版卡片+3秒决策)~~ | ~~Done(PR#3885)~~ |
| kimi19 | #2398 | Tier-A | mine | ~~竞品中标记录采集(后端+前端)~~ | ~~Done(PR#3884)~~ |
| kimi3  | #1499 | Phase4 | mine | ~~经销商数据模型(dealer表+覆盖区域+绩效指标)~~ | ~~Done(PR#3882)~~ |
| kimi1  | #1500 | Phase3 | mine | ~~竞品规格份额统计(spec_share_stats表+品牌提及率对比)~~ | ~~Done(PR#3880)~~ |
| kimi3  | #1499 | Phase4 | mine | ~~经销商数据模型(dealer表+覆盖区域+绩效指标)~~ | ~~Done(PR#3882)~~ |
| kimi4  | #2397 | Phase3 | mine | ~~区域市场数据定时刷新(每周日聚合+企微通知)~~ | ~~Done(PR#3883)~~ |
| kimi1  | #2234 | Phase3 | mine | ~~竞品份额变化预警(连续2季度上升触发告警+站内通知)~~ | ~~Done(PR#3890)~~ |
| kimi4  | #1502 | Phase3 | mine | ~~竞品活跃度统计视图(按竞品×区域×项目类型汇总)~~ | ~~Done(PR#3892)~~ |
| kimi6  | #2236 | Phase3 | mine | ~~竞品追踪分析页(热力图+趋势+排行榜)~~ | ~~Done(PR#3887)~~ |
| kimi19 | #2233 | Phase4 | mine | ~~移动端响应式优化(项目列表/详情/跟进页适配手机)~~ | ~~Done(PR#3888)~~ |
| kimi3  | #2231 | Phase4 | mine | ~~经销商绩效仪表盘(跟进数/成交数/管道金额)~~ | ~~Done(PR#3889)~~ |
| kimi20 | #3886 | infra  | test | hook体系验证+wdpp_project_mine复合索引 | In Progress |
| kimi6  | #2103 | warranty | backend | ~~质保到期续保营销+自动推送+CRM商机~~ | ~~Done(PR#3891)~~ |
| kimi1  | #2102 | warranty | backend | ~~质保售后触发二次商机(维修需求+满意度复购)~~ | ~~Done(PR#3894)~~ |
| kimi3  | #1892 | crm | backend | ~~客户情报P3经销商信息提交模板+自动校验~~ | ~~Done(PR#3895)~~ |
| kimi19 | #2327 | crm | frontend | ~~客户情报P4菜单注册+权限配置~~ | ~~Done(PR#3893)~~ |
| kimi6  | #1891 | crm | backend | ~~客户情报P3后端(BO/VO/Mapper/Service+测试)~~ | ~~Done(PR#3896)~~ |
| kimi3  | #2027 | approval | ~~审批引擎P0 Phase2 Entity+Service CRUD~~ | ~~Done(PR#3898 admin-merged)~~ |
| kimi19 | #2328 | crm | ~~客户情报P4商机详情页信息质量面板~~ | ~~Done(PR#3897 admin-merged)~~ |
| kimi1  | #2329 | crm | ~~客户情报P4客户详情页情报卡Tab~~ | ~~Done(PR#3899 admin-merged)~~ |
| kimi3  | #3150 | approval | 审批流程图渲染API（#2027+#2026均CLOSED，前置满足） | 已派 |
| kimi1  | #3149 | approval | 审批进度追踪器组件（frontend，#3150配对） | 已派 |
| kimi19 | #3167 | approval | 动态表单引擎JSON Schema（B1/8，解锁B2-B8） | 已派 |
| kimi4  | #2119 | execution | ~~经销模式支持(阶段配置+经销商结算+门户API)~~ | ~~Done(PR#3900 admin-merged)~~ |
| kimi19 | #3167 | approval | ~~动态表单引擎JSON Schema(B1/8，解锁B2-B8)~~ | ~~Done(PR#3901 admin-merged)~~ |
| kimi6  | #2468 | execution | ~~图纸管理API(上传/版本控制/审批/下发工厂)~~ | ~~Done(PR#3904 admin-merged)~~ |
| kimi6  | #2024 | approval | AI预检服务（提交前质量/价格/规则检查，Phase5） | 已派 |
| kimi6  | #2024 | approval | ~~AI预检服务(提交前质量/价格/规则检查)~~ | ~~Done(PR#3907 admin-merged)~~ |
| kimi4  | #3169 | approval | ~~表单模板管理(CRUD+分类+启停+审批流绑定，全栈)~~ | ~~Done(PR#3908 admin-merged)~~ |
| kimi19 | #3170 | form | ~~人事全生命周期表单组(入转调离+考勤+社保6模板)~~ | ~~Done(PR#3909 admin-merged)~~ |
| kimi1  | #3171 | form | ~~行政服务表单组(资产/车辆/证照/名片/钥匙5模板)~~ | ~~Done(PR#3910 admin-merged)~~ |
| kimi19 | #2025 | approval | ~~SLA超时检测+企微催办通知~~ | ~~Done(PR#3905 admin-merged)~~ |
| kimi1  | #3168 | approval | ~~动态表单渲染器前端(JSON Schema→Vue3组件自动渲染)~~ | ~~Done(PR#3906 admin-merged)~~ |
| kimi19 | #2270 | wecom | ~~H5工作台入口页(企微内嵌H5+JS-SDK初始化)~~ | ~~Done(PR#3914 admin-merged)~~ |
| kimi1  | #3149 | approval | ~~审批进度追踪器组件(流程地图+步骤高亮+卡点提示)~~ | ~~Done(PR#3902 admin-merged)~~ |
| kimi3  | #3150 | approval | ~~审批流程图渲染API(模板→实例DAG+节点状态+耗时)~~ | ~~Done(PR#3903 admin-merged)~~ |
| kimi1  | #3161 | wecom | ~~企微审批贯通SDK封装(4核心API+错误码映射+Token刷新)~~ | ~~Done(PR#3913 admin-merged)~~ |
| kimi4  | #3173 | form | ~~印章/运营/国贸表单组(用印/仓储/单证6模板，流程补齐7/8)~~ | ~~Done(PR#3912 admin-merged)~~ |
| kimi6  | #3172 | form | ~~质量管理表单组(质检/不合格/纠正措施/供应商/客诉5模板)~~ | ~~Done(PR#3911 admin-merged)~~ |
| kimi4  | #3132 | approval | ~~审批抄送功能(wf_cc_record表+Service+Controller+企微通知)~~ | ~~Done(PR#3917 admin-merged)~~ |
| kimi4  | #3152 | approval | ~~条件跳过引擎(数据模型+规则评估+API+评估框架集成)~~ | ~~Done(PR#3921 admin-merged)~~ |
| kimi3  | #2365 | approval | ~~SLA规则配置页+审批统计看板(CRUD接口+前端+E2E 4passed)~~ | ~~Done(PR#3922 admin-merged)~~ |
| kimi4  | #3156 | approval | ~~流程效率分析看板(节点耗时/驳回率/瓶颈+AI建议，13后端+9前端)~~ | ~~Done(PR#3927 admin-merged)~~ |
| kimi3  | #3151 | approval | 新手引导+流程帮助中心 — Tooltip引导+流程说明+常见问题 | 已派 |
| kimi19 | #3163 | wecom | ~~企微审批贯通3/6 H5审批发起页(WfTemplateController+initiate.vue+草稿)~~ | ~~Done(PR#3918 admin-merged)~~ |
| kimi6  | #3164 | wecom | ~~企微审批贯通4/6 审批消息卡片增强(WecomCardBuilder+卡片发送+回调)~~ | ~~Done(PR#3919 admin-merged)~~ |
| kimi1  | #3162 | wecom | ~~企微审批贯通2/6 审批流程引擎回调处理(Controller+Service+Processor+幂等+重试)~~ | ~~Done(PR#3920 admin-merged)~~ |
| kimi6  | #3153 | approval | ~~自动审批规则引擎(预审条件+预清除回退+零人工路径)~~ | ~~Done(PR#3926 admin-merged)~~ |
| kimi19 | #2266 | wecom | ~~H5审批操作页(approval-detail.vue+taskId字段+ProgressNodeVO)~~ | ~~Done(PR#3923 admin-merged)~~ |
| kimi1  | #3154 | approval | ~~智能路由引擎(并行/串行/条件路由+动态审批人+部门专家匹配)~~ | ~~Done(PR#3924 admin-merged)~~ |
| kimi19 | #3134 | approval | ~~设计变更分级审批(三级变更模板+自动路由+后端核心T1-T5)~~ | ~~Done(PR#3930 admin-merged)~~ |
| kimi3  | #3151 | approval | ~~新手引导+流程帮助中心(Tooltip+FAQ+OnboardingGuide+FlowFinder+HelpCenter)~~ | ~~Done(PR#3925 admin-merged)~~ |
| kimi6  | #3153 | approval | ~~自动审批规则引擎(预审条件+预清除回退+零人工路径+JUnit+Playwright)~~ | ~~Done(PR#3926 admin-merged)~~ |
| kimi6  | #3155 | approval | 流程简化配置页 — 跳过/自动审批/路由规则可视化配置 | 已派 |
| kimi1  | #2016 | approval | ~~企微审批消息卡片(审批结果卡片+H5深度链接配置化)~~ | ~~Done(PR#3928 admin-merged)~~ |
| kimi3  | #2015 | approval | ~~CRM报价单接入审批流(报价提交自动发起审批+JUnit19tests)~~ | ~~Done(PR#3929 admin-merged)~~ |
