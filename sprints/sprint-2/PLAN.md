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

## 指派建议（最近20个）

> 更新于 2026-04-20（PLM剩余12个Issue按优先级+依赖顺序完整列出）
> 当前运行5/5：kimi1/#3385 + kimi3/#3394 + kimi4/#3383 + kimi6/#3384 + kimi19/#3388
> 排序规则：P0>P1；后端必须排在配对前端之前；依赖未完成排末尾

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #3386 | P0 | backend | PLM[9/20] ECO审批流集成 — 复用审批引擎+A级三人会签 | ⏳ 等kimi1/#3385 |
| #3387 | P0 | backend | PLM[10/20] ECO执行引擎 — 审批通过→零件版本更新+BOM递增 | ⏳ 等#3386 |
| #3389 | P1 | backend | PLM[12/20] 超级BOM→实例EBOM解析API — 选配结果→具体BOM | ⏳ 等kimi19/#3388 |
| #3392 | P1 | backend | PLM[15/20] 版本化定价引擎API — 价格锚定BOM版本+利润红线校验 | ⏳ 等kimi4/#3383 |
| #3390 | P1 | backend | PLM[13/20] D3参数化→PLM BOM桥接 — D3输出自动创建EBOM | ⏳ 等#3389 |
| #3391 | P1 | backend | PLM[14/20] 产品配置器后端API — 超级BOM规则过滤+输出EBOM+报价 | ⏳ 等#3388+#3389 |
| #3393 | P1 | backend | PLM[16/20] 供应商价格联动 — 报价变动→Part Master+BOM成本重算 | ⏳ 等#3392 |
| #3394 | P1 | frontend | PLM[17/20] 零件主数据管理页面（配对后端#3378已Done） | 🚀 kimi3 进行中 |
| #3395 | P1 | frontend | PLM[18/20] BOM管理与版本对比页面（配对后端#3380/#3381已Done） | ✅ 可立即启动 |
| #3396 | P1 | frontend | PLM[19/20] ECO变更管理页面（配对后端需#3385+#3386） | ⏳ 等#3385+#3386 |
| #3397 | P1 | frontend | PLM[20/20] 产品配置器+报价页面（配对后端需#3391） | ⏳ 等#3391 |

> **并行窗口**（槽空时可同时启动无冲突的组合）：
> - 批次1（当前CC完成后）：#3386 + #3389 + #3392 + #3394 + #3395 可5CC并行
> - 批次2：#3387 + #3390 + #3391 + #3393 + #3396

> ⚠️ 研发经理须等排程经理建议后再指派，不得自行从看板读取issue派发。

## 当前运行

| 指派目录 | Issue | 模块 | 内容 | 状态 |
|---------|-------|------|------|------|
| kimi1  | #3174 | approval | ~~表单模板导入导出+配置向导(模板迁移+快速配置，流程补齐8/8)~~ | ~~Done(PR#3937 admin-merged)~~ |
| kimi3  | #3179 | project360 | ~~项目360统一看板页面(8Tab骨架+概览+阶段切换+菜单)~~ | ~~Done(PR#3932 admin-merged)~~ |
| kimi4  | #3185 | finance | ~~全阶段资料完成度看板(后端3API+前端看板+7列进度条+法规红点)~~ | ~~Done(PR#3933 admin-merged)~~ |
| kimi4  | #3187 | finance | ~~全阶段文件缺失预警(三级升级推送+企微/站内双通道+阶段门控)~~ | ~~Done(PR#3938 admin-merged)~~ |
| kimi3  | #3191 | finance | ~~甲方资料需求模板库(按甲方积累特殊资料要求+新项目自动继承)~~ | ~~Done(PR#3935 admin-merged)~~ |
| kimi6  | #3189 | finance | ~~甲方表单填写辅助(项目数据关联填充+回款资料模板生成+导出)~~ | ~~Done(PR#3936 admin-merged)~~ |
| kimi19 | #3188 | finance | ~~企业信息库(万德常用信息维护+一键填充到回款表单)~~ | ~~Done(PR#3934 admin-merged)~~ |
| kimi3  | #3183 | project360 | ~~项目360文档Tab前端 — 对内/对外分组+阶段进度+批量操作~~ | ~~Done(PR#3940 admin-merged)~~ |
| kimi1  | #3385 | plm | PLM[8/20] ECO变更申请与影响评估API | 进行中 |
| kimi3  | #3651 | bidding | ~~招投标-C 投标立项与进度管理~~ | ~~Done(PR#3988 admin-merged)~~ |
| kimi3  | #3394 | plm | PLM[17/20] 零件主数据管理页面 | 进行中 |
| kimi4  | #3383 | plm | PLM[6/20] BOM成本Roll-up API + 企微推送 | 进行中 |
| kimi6  | #3384 | plm | PLM[7/20] 零件服务与供应商集成API | 进行中 |
| kimi19 | #3388 | plm | PLM[11/20] 超级BOM规则引擎 | 进行中 |
| kimi19 | #3184 | project360 | ~~文档访问日志+统计(谁看了什么文件·下载追踪)~~ | ~~Done(PR#3941 admin-merged)~~ |
| kimi19 | #1766 | frontend | ~~代理商工作台前端(五阶段管线+看板+列表，Mock模式)~~ | ~~Done(PR#3945 admin-merged)~~ |
| kimi6  | #1687 | approval | ~~企微审批通知+消息推送+逾期提醒~~ | ~~Done(PR#3939 admin-merged)~~ |
| kimi1  | #1717 | finance | ~~报销申请页面+发票上传+借款管理+审批中心~~ | ~~Done(PR#3946 admin-merged)~~ |
| kimi4  | #1722 | perf | ~~管理费分摊+绩效考核页面 — 费用录入+打分+结果看板~~ | ~~Done(PR#3943 admin-merged)~~ |
| kimi6  | #1780 | supply | ~~供应商台账+询价比价+采购跟踪页面(Mock模式骨架)~~ | ~~Done(PR#3942 admin-merged)~~ |
| kimi3  | #2148 | supply | ~~供应商台账后端(台账+询价比价+采购跟踪 API)~~ | ~~Done(PR#3944 admin-merged)~~ |
| kimi3  | #2005 | finance | ~~应付账款数据库+后端完整实现~~ | ~~Done(PR#3948 admin-merged)~~ |
| kimi3  | #2004 | finance | ~~应付账款管理API(付款计划+付款执行+聚合，审批/OCR留桩)~~ | ~~Done(PR#3952 admin-merged)~~ |
| kimi4  | #2003 | finance | ~~经营分析数据聚合API(6维度收入/成本/毛利/现金流/ROI/总览)~~ | ~~Done(PR#3950 admin-merged)~~ |
| kimi6  | #2354 | finance | ~~回款周报前端(商务填报+财务评估+管理层审阅三视图)~~ | ~~Done(PR#3947 admin-merged)~~ |
| kimi6  | #1719 | finance | ~~绩效仪表盘+三级Tab+ECharts趋势分析~~ | ~~Done(PR#3953 admin-merged)~~ |

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
| kimi6  | #3155 | approval | ~~流程简化配置页(跳过规则/自动审批/路由可视化+菜单)~~ | ~~Done(PR#3931 admin-merged)~~ |
| kimi1  | #2016 | approval | ~~企微审批消息卡片(审批结果卡片+H5深度链接配置化)~~ | ~~Done(PR#3928 admin-merged)~~ |
| kimi3  | #2015 | approval | ~~CRM报价单接入审批流(报价提交自动发起审批+JUnit19tests)~~ | ~~Done(PR#3929 admin-merged)~~ |
| kimi19 | #3188 | finance | ~~企业信息库(万德常用信息维护+一键填充到回款表单)~~ | ~~Done(PR#3934 admin-merged)~~ |
| kimi3  | #3191 | finance | ~~甲方资料需求模板库(按甲方积累特殊资料要求+新项目自动继承)~~ | ~~Done(PR#3935 admin-merged)~~ |
| kimi6  | #3189 | finance | ~~甲方表单填写辅助(项目数据关联填充+回款资料模板生成+导出)~~ | ~~Done(PR#3936 admin-merged)~~ |
| kimi1  | #3174 | approval | ~~表单模板导入导出+配置向导(模板迁移+快速配置，流程补齐8/8)~~ | ~~Done(PR#3937 admin-merged)~~ |
| kimi3  | #3183 | project360 | 项目360文档Tab前端(对内/对外分组+阶段进度+批量操作) | 进行中 |
| kimi19 | #3184 | project360 | ~~文档访问日志+统计(谁看了什么文件·下载追踪)~~ | ~~Done(PR#3941 admin-merged)~~ |
| kimi19 | #1766 | frontend | ~~代理商工作台前端(五阶段管线+看板+列表，Mock模式)~~ | ~~Done(PR#3945 admin-merged)~~ |
| kimi6  | #1687 | approval | ~~企微审批通知+消息推送+逾期提醒~~ | ~~Done(PR#3939 admin-merged)~~ |
| kimi4  | #3187 | finance | ~~全阶段文件缺失预警(三级升级推送+企微/站内双通道+阶段门控)~~ | ~~Done(PR#3938 admin-merged)~~ |
| kimi1  | #1717 | finance | ~~报销申请页面+发票上传+借款管理+审批中心~~ | ~~Done(PR#3946 admin-merged)~~ |
| kimi4  | #1722 | perf | ~~管理费分摊+绩效考核页面 — 费用录入+打分+结果看板~~ | ~~Done(PR#3943 admin-merged)~~ |
| kimi6  | #1780 | supply | ~~供应商台账+询价比价+采购跟踪页面(Mock模式骨架)~~ | ~~Done(PR#3942 admin-merged)~~ |
| kimi3  | #2148 | supply | ~~供应商台账后端(台账+询价比价+采购跟踪 API)~~ | ~~Done(PR#3944 admin-merged)~~ |
| kimi3  | #2005 | finance | ~~应付账款数据库+后端完整实现~~ | ~~Done(PR#3948 admin-merged)~~ |
| kimi4  | #2003 | finance | ~~经营分析数据聚合API(6维度收入/成本/毛利/现金流/ROI/总览)~~ | ~~Done(PR#3950 admin-merged)~~ |
| kimi6  | #2354 | finance | ~~回款周报前端(商务填报+财务评估+管理层审阅三视图)~~ | ~~Done(PR#3947 admin-merged)~~ |
| kimi6  | #1719 | finance | ~~绩效仪表盘+三级Tab+ECharts趋势分析~~ | ~~Done(PR#3953 admin-merged)~~ |
| kimi1  | #2006 | finance | ~~应收账款管理API(账龄分析+催收提醒+企微，核心框架)~~ | ~~Done(PR#3951 admin-merged)~~ |
| kimi19 | #1754 | frontend | ~~代理商工作台数据打通(关联项目+中标方标签，Mock模式)~~ | ~~Done(PR#3949 admin-merged)~~ |
| kimi1  | #2356 | finance | ~~经营分析看板页面(收入成本趋势+毛利率排行+现金流图表)~~ | ~~Done(PR#3955 admin-merged)~~ |
| kimi3  | #2000 | finance | ~~财务预警引擎(应收逾期+应付到期+毛利异常+现金流预警)~~ | ~~Done(PR#3956 admin-merged)~~ |
| kimi19 | #2473 | finance | ~~律师催收数据库+API(律师信息+催收案件+进展记录)~~ | ~~Done(PR#3957 admin-merged)~~ |
| kimi4  | #1684 | backend | ~~绩效异常检测+提成试算API+企微智能推送~~ | ~~Done(PR#3958 admin-merged)~~ |
| kimi1  | #2356 | finance | ~~经营分析看板页面 — 收入成本趋势+毛利率排行+现金流图表~~ | ~~Done(PR#3955 admin-merged)~~ |
| kimi3  | #2000 | finance | ~~财务预警引擎 — 应收逾期+应付到期+毛利异常+现金流预警~~ | ~~Done(PR#3956 admin-merged)~~ |
| kimi4  | #1873 | backend | ~~分级超时升级机制(48h→72h→5天)~~ | ~~Done(PR#3954 admin-merged)~~ |
| kimi19 | #2473 | finance | ~~律师催收数据库+API — 律师信息+催收案件+进展记录~~ | ~~Done(PR#3957 admin-merged)~~ |
| kimi4  | #1684 | backend | ~~绩效异常检测+提成试算API+企微智能推送~~ | ~~Done(PR#3958 admin-merged)~~ |
| kimi6  | #2358 | finance | ~~商机详情页获客成本Tab — 关联报销+费用汇总~~ | ~~Done(PR#3959 admin-merged)~~ |
| kimi1  | #1996 | finance | ~~回款周报API — 商务填写+财务评估+管理层审阅全流程~~ | ~~Done(PR#3961 admin-merged)~~ |
| kimi1  | #1702 | backend | ~~设备台账API — 设备管理+二维码+维修履历~~ | ~~Done(PR#3964 admin-merged)~~ |
| kimi3  | #2002 | finance | ~~项目全链路资金闭环报告API — 从获客到净利润一张表~~ | ~~Done(PR#3960 admin-merged)~~ |
| kimi3  | #2014 | backend | ~~数据范围控制引擎 — sys_data_scope+全部/本部门/本人+AOP~~ | ~~Done(PR#3962 admin-merged)~~ |
| kimi3  | #2510 | backend | ~~AI合同关键信息提取引擎 — 回款条件+质保期+特殊条款+我方准备~~ | ~~Done(PR#3968 admin-merged)~~ |
| kimi4  | #2008 | finance | ~~报价成本模型API — BOM+运费+安装+管理费→建议售价~~ | ~~Done(PR#3963 admin-merged)~~ |
| kimi1  | #3180 | backend | ~~文档对内/对外分类 — doc_visibility字段+分类标签体系~~ | ~~Done(PR#3967 admin-merged)~~ |
| kimi4  | #2366 | frontend | ~~审批中心页面 — 待办/已办/发起三Tab+审批操作~~ | ~~Done(PR#3966 admin-merged)~~ |
| kimi19 | #1685 | backend | 项目费用关联API+财务报表导出功能 | 进行中 |
| kimi6  | #2105 | backend | ~~质保成本核算API — 6维度成本+外包结算+客户计费~~ | ~~Done(PR#3965 admin-merged)~~ |
| kimi4  | #3181 | backend | ~~阶段文档注册表 — 每阶段必备文档清单模板+完成度计算~~ | ~~Done(PR#3974 admin-merged)~~ |
| kimi6  | #3149 | frontend | ~~审批进度追踪器组件 — 流程地图+步骤高亮+卡点提示+预估耗时~~ | ~~Done(PR#3902 已于04-19完成)~~ |
| kimi6  | #3183 | frontend | ~~项目360文档Tab前端 — 对内/对外分组+阶段进度+批量操作~~ | ~~Done(PR#3940 已于04-19完成)~~ |
| kimi6  | #3648 | backend | ~~招投标-DB 数据库建表 — 10张表 Flyway迁移~~ | ~~Done(PR#3969 admin-merged)~~ |
| kimi6  | #3649 | fullstack | ~~招投标-A 资质证书管理中心~~ | ~~Done(PR#3972 admin-merged)~~ |
| kimi1  | #3182 | backend | ~~文档自动归集 — 审批/合同/设计附件自动入项目文档库~~ | ~~Done(PR#3973 admin-merged)~~ |
| kimi3  | #3656 | backend | ~~法规文件预置模板 — TSG 71-2023 七阶段38项法定文件种子数据~~ | ~~Done(PR#3971 admin-merged)~~ |
| kimi19 | #1685 | backend | ~~项目费用关联API+财务报表导出功能~~ | ~~Done(PR#3970 admin-merged)~~ |
| kimi19 | #3650 | fullstack | ~~招投标-B 检测报告管理~~ | ~~Done(PR#3981 admin-merged)~~ |
| kimi4  | #3181 | backend | ~~阶段文档注册表 — 每阶段必备文档清单模板+完成度计算~~ | ~~Done(PR#3974 admin-merged)~~ |
| kimi3  | #2468 | backend | ~~图纸管理API — 上传/版本控制/审批/下发工厂~~ | ~~Done(PR#3904 已于04-19完成)~~ |
| kimi6  | #1875 | mine | ~~赢/输复盘模板+系统化采集（矿场主线）~~ | ~~Done(PR#3976 admin-merged)~~ |
| kimi1  | #2086 | backend | ~~变更影响联动API — BOM差异自动计算+成本影响+工期更新~~ | ~~Done(历史PR#2781/#3356已merged，E2E历史遗留无需修复)~~ |
| kimi3  | #2195 | backend | ~~品牌中心多平台数据采集~~ | ~~Done(PR#3975 admin-merged)~~ |
| kimi4  | #3652 | fullstack | ~~招投标-D 投标文件编制工作台~~ | ~~Done(PR#3984 admin-merged)~~ |
| kimi1  | #3377 | backend | ~~PLM子系统数据库初始化 — 7张核心表建表+索引~~ | ~~Done(PR#3977 admin-merged)~~ |
| kimi3  | #3653 | fullstack | ~~招投标-E 报价决策与保证金台账~~ | ~~Done(PR#3980 admin-merged)~~ |
| kimi1  | #3378 | backend | ~~PLM零件主数据CRUD API — 新建/编辑/查询/版本状态机~~ | ~~Done(PR#3979 admin-merged)~~ |
| kimi6  | #2204 | backend | ~~品牌中心数据库建表~~ | ~~Done(PR#3978 admin-merged)~~ |
| kimi6  | #2203 | backend | ~~品牌中心内容CRUD API + 状态流转 + S3文件上传~~ | ~~Done(PR#3982 admin-merged)~~ |
| kimi1  | #3379 | backend | ~~PLM零件编码自动生成引擎 — 四段式编码+唯一性校验~~ | ~~Done(PR#3983 admin-merged)~~ |
| kimi3  | #3651 | bidding | ~~招投标-C 投标立项与进度管理~~ | ~~Done(PR#3988 admin-merged)~~ |
| kimi6  | #3380 | plm | ~~BOM创建与版本管理API (EBOM/MBOM/超级BOM)~~ | ~~Done(PR#3985 admin-merged)~~ |
| kimi19 | #3654 | bidding | ~~招投标-Dashboard 投标总览仪表盘~~ | ~~Done(PR#3986 admin-merged)~~ |
| kimi1  | #3381 | plm | ~~PLM BOM版本对比与回滚API~~ | ~~Done(PR#3987 admin-merged)~~ |
| kimi4  | #3383 | plm | PLM BOM成本Roll-up API | 进行中 |
| kimi6  | #3384 | plm | PLM BOM Where-Used反查API | 进行中 |
| kimi1  | #3385 | plm | PLM ECO变更申请与影响评估API | 进行中 |
| kimi19 | #3388 | plm | PLM[11/20] 超级BOM规则引擎 | 进行中 |
| kimi3  | #3394 | plm | PLM[17/20] 零件主数据管理页面 | 进行中 |
