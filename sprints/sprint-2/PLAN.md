# Sprint-2 排程计划

> 更新时间：2026-05-13（排程经理第1248轮；Done 1547（#1754已标Done）；In Progress 0；Todo 0；Plan 3；pause 64；Master自动关闭2个）
> 活跃CC：无（kimi1僵尸会话已清理，锁已释放，#1754→Done）
> 新增：PR#54/#23 #55/#11 #56/#10 #57/#21 #58/#20 均已开→dev
> 指派建议表：已清空（#1754已标Done，kimi1已释放）
> 来源：v5.1 §5.6 全量对账 — 326个已合规Issue一次性排程
> 规则：EXEMPT 33个→Todo / A档128个→按Sprint Todo / C_frozen 165个→保持Plan(needs-prototype)
> Master Issue：#3994已关闭、#4004已关闭、#3647已关闭、#4020已关闭、#3622已关闭、#4142已关闭、#4065已关闭、#4097已关闭

## 排程统计

| 分类 | 数量 | 状态 |
|------|------|------|
| EXEMPT（bug/docs/refactor/test） | 33 | → Todo |
| A档（完整原型引用） | 113 | → Todo |
| A_weak（广义原型引用） | 15 | → Todo |
| C_frozen（缺原型冻结） | 165 | 保持Plan，needs-prototype标签 |
| **合计** | **326** | |

## 指派建议（最近20个）

> 排程经理维护，研发经理按此顺序指派。已指派的由研发经理从表中删除。
> 更新时间：2026-05-13（排程经理第1228轮；Todo=1；队列补充中）
> ⚠️ needs-prototype冻结、Master Issue不出现在本表；指派前请用 `gh issue view #N` 确认标签
> 注意：本表与GitHub Issue编号一致，无需转换

| # | Issue | 优先级 | 模块 | 说明 | 启动 |
|---|-------|--------|------|------|------|

> ⚠️ 修正：Master Issue (#4065/#4091/#4198) 是导航型 parent 引用，非真正依赖。子 Issue 的非 Master 依赖已全部 CLOSED。

> ⚠️ 指派前请用 `gh issue view #N --repo WnadeyaowuOraganization/wande-play --json body` 确认依赖已CLOSED再指派

### 非活跃记录（冻结/已指派/阻塞/PR中 — 不出现在主表）

| Issue | 原因 | 当前状态 |
|-------|------|---------|
| #2420 / #2422 / #2425 / #2424 / #2165 | ⛔ needs-prototype 冻结 | pause |
| #1766 | ⛔ needs-prototype（原型文件不存在） | pause |
| ~~#1754~~ | ✅ PR#3949已于04-19 merged | ~~Done~~ |
| #2496 | ✅ CLOSED（竞品情报T3级30家补充采集） | Done |
| #2396 | ✅ CLOSED（国际信息源适配器-北美） | Done |
| #2226 | ✅ CLOSED（竞品采集发布流程v2） | Done |
| #2227 | ✅ CLOSED（跨境资格评估UI） | Done |
| #1911 | ✅ CLOSED（D3-AI电池包开发助手）PR#4801 | Done |
| #2393 | ✅ CLOSED（矿场Phase5买家意图信号采集） | Done |
| #23 | ✅ CLOSED（D3缺陷修复-Redis缓存层）PR#36 | Done |
| #18 | ✅ CLOSED（D3生产链路-弧长/曲线标注增强）PR#37 | Done |
| #19 | ✅ CLOSED（D3生产链路-曲面面板分割电池包）PR#38 | Done |
| #17 | ✅ CLOSED（D3生产链路-2D板材排料电池包）PR#39 | Done |
| #11 | ✅ CLOSED（D3_Structure结构模块）PR#55 merged | Done |
| #9 | ✅ CLOSED（D3_Core共享模块）PR#40 | Done |
| #7 | ✅ CLOSED（一键标注出图组件）PR#49 | Done |
| #20 | ✅ CLOSED（D3图纸分级输出系统）PR#58 merged | Done |
| #10 | ✅ CLOSED（D3_Safety安全区域模块）PR#56 merged | Done |
| #2 | ✅ CLOSED（DfMA制造可行性检测引擎）PR#41 | Done |
| #3 | ✅ CLOSED（几何审计脚本）PR#43 | Done |
| #25 | ✅ CLOSED（端到端测试套件）PR#42 | Done |
| #4 | ✅ CLOSED（钢管下料优化）PR#45 | Done |
| #5 | ✅ CLOSED（CNC/DXF分层导出）PR#44 | Done |
| #24 | ✅ CLOSED（GH纯参数传递模式改造）PR#46 | Done |
| #21 | ✅ CLOSED（D3_SkinPreview表皮效果预览）PR#57 merged | Done |
| #6 | ✅ CLOSED（STEP零件批量导出）PR#48 | Done |
| #23 | ✅ CLOSED（D3计算结果Redis缓存层）PR#54 merged | Done |
| #2065 | ✅ CLOSED（D3市场配置预设） | Done |
| #2343 | ✅ CLOSED（竞对分析-自动分类） | Done |
| #2487 | ✅ CLOSED（设计模型训练LoRA-B） | Done |
| #2486 | ✅ CLOSED（设计模型训练LoRA-A） | Done |
| #2476 | ✅ CLOSED（AI建模助手试点验证） | Done |
| #4761 | ✅ CLOSED（CRM跟进记录AI摘要） | Done |
| #4763 | ✅ CLOSED（CRM客户评分模型） | Done |
| #4765 | ✅ CLOSED（CRM经销商关系分析） | Done |
| #4763 | ✅ CLOSED（CRM客户评分模型） | Done |
| #4765 | ✅ CLOSED（CRM经销商关系分析） | Done |
| #2017 | ✅ CLOSED（明道云权限模式提取） | Done |
| #2516 | ✅ CLOSED（合同要点卡片） | Done |
| #2655 | ⏳ 依赖 #2648（仍在 Plan，未完成） | Todo（阻塞） |
| #2118 / #2142 / #2143 | 队列靠后（P3，当前优先P1/P2） | Todo |
| #4608 | ⛔ 需 Windows 物理机手动验证 | Todo（阻塞） |
| #4493 | ⛔ 需 G7e 环境（实际模型下载与验证） | Todo（阻塞） |

## 指派历史

| 日期 | kimi | Issue | 模块 | effort | 状态 | 备注 |
|------|------|-------|------|--------|------|------|
| 05-13 | kimi1 | ~~#1754~~ | frontend | medium | ~~Done~~ | 代理商工作台前端数据打通 — **PR#3949已于04-19 merged，误派（僵尸会话已清理）** |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3386~~ | PLM | medium | ~~Done~~ | ECO审批流集成 — CLOSED/COMPLETED |
| 04-22 | kimi2 | ~~#3389~~ | PLM | medium | ~~Done~~ | EBOM解析API — CLOSED/COMPLETED |
| 04-22 | kimi3 | ~~#3392~~ | PLM | medium | ~~Done~~ | 版本化定价引擎API — CLOSED/COMPLETED |
| 04-22 | kimi4 | ~~#3631~~ | bidding | high | ~~Done~~ | pipeline表对齐 — CLOSED/COMPLETED |
| 04-22 | kimi5 | ~~#1692~~ | backend | medium | ~~Done~~ | ~~项目成本跟踪API~~ — PR #3844 已于04-19 merged，误派 |
| 04-22 | kimi5 | ~~#2113~~ | backend | medium | ~~Done~~ | 合同审批流程 — CLOSED/COMPLETED |
| 04-22 | #2132 ✅merged/kimi1 | ~~#2296~~ | wechat | medium | ~~Done~~ | Cockpit安全审计页面 — CLOSED/COMPLETED |
| 04-22 | kimi5 | #2298 | cockpit | medium | In Progress | AI对话监控面板 |
| 04-22 | kimi2 | ~~#2925~~ | backend | medium | ~~Done~~ | 字段级数据完整度计算引擎 — CLOSED/COMPLETED |
| 04-22 | kimi3 | ~~#2926~~ | backend | medium | ~~Done~~ | 数据质量KPI API — CLOSED/COMPLETED |
| 04-22 | kimi2 | ~~#2944~~ | backend | medium | ~~Done~~ | 7天滚动基线异常检测 — CLOSED/COMPLETED |
| 04-22 | kimi4 | #4033 | crm | medium | In Progress | CRM商机详情-基本信息Tab |
| 04-22 | #2132 ✅merged/kimi1 | #4034 | crm | medium | In Progress | CRM商机详情-跟进记录Tab |
| 04-22 | kimi2 | #4035 | crm | medium | In Progress | CRM商机详情-设计单Tab |
| 04-22 | kimi3 | #4036 | crm | medium | In Progress | CRM商机详情-报价Tab |
| 04-22 | #2132 ✅merged/kimi1 | #4034 | crm | medium | **Done** | CRM商机详情-跟进记录Tab — PR #4056 merged |
| 04-22 | #2132 ✅merged/kimi1 | #4037 | crm | medium | **Done** | CRM商机详情-合同Tab — PR #4064 merged |
| 04-22 | #2132 ✅merged/kimi1 | #4042 | crm | medium | **Done** | CRM商机详情-流程监控Tab — PR #4071 merged |
| 04-22 | kimi2 | #4035 | crm | medium | **Done** | CRM商机详情-设计单Tab — PR #4057 merged |
| 04-22 | kimi2 | #4038 | crm | medium | **Done** | CRM商机详情-回款Tab — PR #4067 merged |
| 04-22 | kimi2 | #2849 | cockpit | medium | In Progress | Agent效率看板前端 |
| 04-22 | kimi3 | #4036 | crm | medium | **Done** | CRM商机详情-报价Tab — PR #4058 merged |
| 04-22 | kimi3 | #4039 | crm | medium | **Done** | CRM商机详情-投标HZTab — PR #4066 merged |
| 04-22 | kimi3 | #4040 | crm | medium | **Done** | CRM商机详情-资料Tab — PR #4070 merged |
| 04-22 | kimi3 | #3648 | bidding | low | In Progress | 招投标DB建表 |
| 04-22 | kimi4 | #4033 | crm | medium | **Done** | CRM商机详情-基本信息Tab — PR #4062 merged |
| 04-22 | kimi4 | #4044 | crm | medium | **Done** | CRM商机详情-变更日志Tab — PR #4068 merged |
| 04-22 | kimi4 | #2851 | cockpit | medium | In Progress | 验收队列前端 |
| 04-22 | kimi5 | #2298 | cockpit | medium | **Done** | AI对话监控面板 — PR #4069 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3150~~ | approval | **max** | ~~Done~~ | 审批流程图渲染API — 补充PR #4072 merged |
| 04-22 | kimi5 | ~~#3169~~ | approval | **max** | ~~Done~~ | 表单模板管理 — PR #4076 merged |
| 04-22 | kimi2 | ~~#2849~~ | cockpit | **max** | ~~Done~~ | Agent效率看板前端 — PR #4074 merged |
| 04-22 | kimi3 | ~~#3648~~ | bidding | **max** | ~~Done~~ | 招投标DB建表 — 补充PR #4073 merged |
| 04-22 | kimi4 | ~~#2851~~ | cockpit | **max** | ~~Done~~ | 验收队列前端 — PR #4075 merged |
| 04-22 | kimi2 | #3149 | approval | **max** | In Progress | 审批进度追踪器组件 |
| 04-22 | kimi3 | #3155 | approval | **max** | In Progress | 流程简化配置页 |
| 04-22 | kimi4 | #3156 | approval | **max** | In Progress | 流程效率分析看板 |
| 04-22 | #2132 ✅merged/kimi1 | #3168 | approval | **max** | In Progress | 动态表单渲染器前端 |
| 04-22 | kimi5 | #3151 | approval | **max** | In Progress | 新手引导+流程帮助中心 |
| 04-22 | kimi2 | ~~#3149~~ | approval | **max** | ~~Done~~ | 审批进度追踪器组件 — PR #4077 merged |
| 04-22 | kimi2 | ~~#3174~~ | approval | **max** | ~~Done~~ | 表单模板导入导出+配置向导 — PR #4080 merged |
| 04-22 | kimi4 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — PR #4079 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3168~~ | approval | **max** | ~~Done~~ | 动态表单渲染器前端 — PR #4078 merged |
| 04-22 | kimi2 | ~~#4024~~ | plm | **max** | ~~Done~~ | PLM产品技术中心 — PR #4083 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#4023~~ | approval | **max** | ~~Done~~ | 统一审批工作台 — PR #4082 merged |
| 04-22 | kimi5 | ~~#3151~~ | approval | **max** | ~~Done~~ | 新手引导+流程帮助中心 — PR #4081 merged |
| 04-22 | kimi3 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR #4084 merged |
| 04-22 | kimi4 | ~~#4041~~ | cockpit | **max** | ~~Done~~ | 耀总驾驶舱 — PR #4085 merged |
| 04-22 | kimi2 | ~~#3189~~ | finance | **max** | ~~Done~~ | 甲方表单填写辅助 — PR #4088 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#2427~~ | pipeline | medium | ~~Done~~ | 环评/规划许可公示采集 — PR #4130 merged |
| 04-23 | kimi2 | ~~#4005~~ | frontend | medium | ~~Done~~ | 整改 记录中心4Tab对齐 — PR #4131 merged |
| 04-23 | kimi3 | ~~#4006~~ | frontend | medium | ~~Done~~ | 整改 老板周报对齐 — PR #4106 merged |
| 04-23 | kimi5 | ~~#3397~~ | frontend | medium | ~~Done~~ | 产品配置器+报价页面 — PR #4083 merged |
| 04-23 | kimi6 | #4037 | crm | medium | In Progress | CRM商机详情-合同Tab |
| 04-23 | kimi3 | ~~#4042~~ | frontend | medium | ~~Done~~ | CRM流程监控Tab — PR #4071 merged，Issue #4042已关闭 |
| 04-23 | kimi5 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR #4084 merged |
| 04-23 | kimi2 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — PR #4079 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#4018~~ | crm | medium | ~~Done~~ | 整改 crm_opportunity 明道云对齐 — PR #4133 merged |
| 04-23 | #2132 ✅merged/kimi1 | #4007 | frontend | medium | In Progress | 整改 项目周报+Nudge联动改造 |
| 04-23 | kimi5 | #4017 | crm | medium | In Progress | 整改 crm_activity_log 明道云对齐 |
| 04-23 | kimi2 | #4019 | crm | medium | In Progress | 整改 crm_customer 明道云补齐 |
| 04-22 | kimi2 | ~~#4008~~ | project | **max** | ~~Done~~ | 记录中心时间线视角增强 — PR #4096 merged |
| 04-22 | kimi4 | ~~#3996~~ | project | **max** | ~~Done~~ | 矿场转化漏斗Tab — PR #4089 merged |
| 04-22 | kimi4 | #4009 | project | **max** | In Progress | 记录中心三视角分组Tab |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3184~~ | project360 | **max** | ~~Done~~ | 文档访问日志+统计 — PR #4086 merged |
| 04-22 | kimi3 | ~~#3185~~ | project360 | **max** | ~~Done~~ | 全阶段资料完成度看板 — PR #4087 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3997~~ | project | **max** | ~~Done~~ | 矿场复盘洞察Tab — PR #4099 merged |
| 04-22 | kimi3 | ~~#3998~~ | project | **max** | ~~Done~~ | 矿场ROI看板Tab — PR #4092 merged |
| 04-22 | kimi5 | ~~#4014~~ | crm | **max** | ~~Done~~ | CRM线索统一池+评分引擎 — PR #4090 merged |
| 04-22 | kimi5 | ~~#4010~~ | project | **max** | ~~Done~~ | 手动补录记录模态 — PR #4105 merged |
| 04-22 | kimi3 | ~~#4015~~ | crm | **max** | ~~Done~~ | 矿场转商机 readiness检查 — PR #4102 merged |
| 04-22 | kimi4 | ~~#4009~~ | project | **max** | ~~Done~~ | 记录中心三视角分组Tab — PR #4098 merged |
| 04-22 | kimi4 | ~~#2851~~ | cockpit | **max** | ~~Done~~ | 验收队列E2E修复 — PR #4101 merged |
| 04-22 | kimi4 | ~~#2926~~ | backend | **max** | ~~Done~~ | 数据质量KPI API — PR #4053 已于04-21 merged |
| 04-22 | kimi4 | ~~#2944~~ | backend | **max** | ~~Done~~ | 7天滚动基线异常检测 — PR #4055 已于04-21 merged |
| 04-22 | kimi4 | ~~#3149~~ | approval | **max** | ~~Done~~ | 审批进度追踪器组件 — PR#3902+PR#4077 已merged |
| 04-23 | #2132 ✅merged/kimi1 | #2427 | bidding | medium | In Progress | 环评/规划许可公示采集 (PR#4130等待CI) |
| 04-23 | kimi2 | #4005 | frontend | medium | In Progress | 整改 记录中心4Tab对齐v1.0原型 (PR#4131 E2E 3/3通过) |
| 04-23 | kimi3 | #4006 | frontend | medium | In Progress | 整改 老板周报对齐v1.0原型 (PR#4132 E2E 11/11通过) |
| 04-23 | kimi5 | #3397 | frontend | medium | In Progress | PLM产品配置器+报价页面 (PR#4128冲突解决中) |
| 04-23 | kimi4 | ~~#3996~~ | project | medium | ~~Done~~ | 矿场-转化漏斗Tab — PR #4127 merged |
| 04-23 | kimi5 | ~~#4014~~ | crm | medium | ~~Done~~ | 线索统一池+评分引擎 — PR #4126 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#3995~~ | project | medium | ~~Done~~ | 矿场v2.0执行组6Tab对齐 — PR #4122 merged |
| 04-23 | kimi2 | ~~#4018~~ | crm | medium | ~~Done~~ | 明道云商机数据迁移+表结构调整 — PR #4121 merged |
| 04-23 | kimi3 | ~~#4021~~ | crm | medium | ~~Done~~ | CRM商务中心仪表盘实现 — PR #4119 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#2317~~ | plm | medium | ~~Done~~ | PLM技术确认中心前端 — PR #4117 merged |
| 04-22 | kimi4 | ~~#3150~~ | approval | **max** | ~~Done~~ | 审批流程图渲染API — 已于04-21 merged |
| 04-22 | kimi2 | ~~#4012~~ | project | **max** | ~~Done~~ | 老板周报AI建议Section — PR#4106 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#2849~~ | cockpit | **max** | ~~Done~~ | Agent效率看板Vitest补测 — PR #4100 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#2925~~ | backend | **max** | ~~Done~~ | 字段级数据完整度计算引擎 — PR #4052 已于04-21 merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR#3931+#4084 已merged |
| 04-23 | kimi6 | #4037 | fullstack | medium | In Progress | CRM合同Tab创建+盖章+扫描件上传（备选队列#1指派） |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — 已merged |
| 04-22 | #2132 ✅merged/kimi1 | ~~#3168~~ | approval | **max** | ~~Done~~ | 动态表单渲染器前端 — PR#4078 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#2078~~ | backend | **max** | ~~Done~~ | 原因诊断API — PR #4103 merged |
| 04-23 | kimi3 | ~~#3545~~ | intelligence-hub | **max** | ~~Done~~ | 前端关系网络Tab — PR #4104 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#3386~~ | plm | **max** | ~~Done~~ | ECO审批流集成 — PR#4051 已于04-21 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#3651~~ | bidding | **max** | ~~Done~~ | 投标立项与进度管理 — PR#4112 merged |
| 04-23 | #2132 ✅merged/kimi1 | ~~#2317~~ | ptc | **max** | ~~Done~~ | D3 Web技术确认中心前端 — PR#4117 admin-merged ✅|
| 04-23 | #2132 ✅merged/kimi1 | ~~#4020~~ | cockpit | **high** | ~~Plan~~ | Master超管驾驶舱18Tab — 导航归类用，禁止CC开发 |
| 04-23 | #2132 ✅merged/kimi1 | ~~#4014~~ | crm | medium | ~~Done~~ | 线索统一池+评分引擎 — PR#4126 admin-merged ✅ |
| 04-23 | #2132 ✅merged/kimi1 | ~~#3998~~ | project | medium | ~~Done~~ | 矿场-ROI看板Tab — PR#4092 已merged（误派，实际已完成）|
| 04-23 | #2132 ✅merged/kimi1 | #2427 | bidding | medium | In Progress | 环评/规划许可公示采集 |
| 04-23 | kimi3 | ~~#3389~~ | plm | **max** | ~~Done~~ | EBOM解析API — PR#4107 merged |
| 04-23 | kimi5 | ~~#3392~~ | plm | **max** | ~~Done~~ | 版本化定价引擎API — PR已于04-21 merged(CLOSED) |
| 04-23 | kimi3 | ~~#3390~~ | plm | **max** | ~~Done~~ | D3参数化→PLM BOM桥接 — PR#4111 merged（@SaCheckPermission已修复）|
| 04-23 | kimi3 | ~~#3557~~ | e2e | **max** | ~~Done~~ | E2E回归：前端登录会话失效修复 — PR#4115 merged |
| 04-23 | kimi3 | ~~#4022~~ | crm | **max** | ~~Done~~ | Master CRM商机详情页骨架 — PR#4118 merged |
| 04-24 | kimi3 | ~~#4042~~ | frontend | medium | ~~Done~~ | CRM流程监控Tab — PR #4071 merged，Issue #4042已关闭 |
| 04-24 | kimi3 | #2198 | brand | medium | In Progress | 品牌中心-视频号自动化发布 |
| 04-24 | kimi5 | ~~#4017~~ | crm | medium | ~~Done~~ | crm_activity_log明道云迁移 — PR #4134 merged |
| 04-24 | kimi5 | #2310 | design-ai | medium | In Progress | 方案文本模块-分Section编辑器 |
| 04-24 | kimi2 | ~~#4019~~ | crm | medium | ~~Done~~ | crm_customer明道云补齐迁移 — PR #4135 merged |
| 04-24 | kimi2 | #2428 | bidding | medium | In Progress | 人大代表建议/政协提案采集 |
| 04-24 | kimi6 | ~~#4037~~ | app | medium | ~~Done~~ | 合同Tab创建+盖章+扫描件上传 — PR #4136 merged |
| 04-24 | kimi6 | #2429 | bidding | medium | In Progress | 行业展会参展商名录采集 |
| 04-24 | kimi2 | ~~#2428~~ | bidding | medium | ~~Done~~ | 人大代表建议/政协提案采集 — PR #4137 merged |
| 04-24 | kimi2 | #3151 | approval | medium | In Progress | 新手引导+流程帮助中心 |
| 04-23 | kimi3 | ~~#4013~~ | crm | **high** | ~~Plan~~ | Master CRM线索/商机统一 — 导航归类用，禁止CC开发 |
| 04-23 | kimi3 | #3651 | bidding | medium | ~~Done~~ | 投标立项与进度管理 — PR#4112 已merged |
| 04-23 | kimi3 | ~~#3995~~ | project | medium | ~~Done~~ | 矿场v2.0原型 — PR#4122 admin-merged ✅ |
| 04-23 | kimi3 | ~~#3997~~ | project | medium | ~~Done~~ | 矿场-复盘洞察Tab — PR#4099 已merged ✅ |
| 04-23 | kimi3 | #4006 | frontend | medium | In Progress | 老板周报对齐v1.0原型 |
| 04-23 | kimi5 | ~~#3391~~ | plm | **max** | ~~Done~~ | 产品配置器后端API — PR#4110 merged |
| 04-23 | kimi5 | #3397 | plm | **high** | In Progress | PLM产品配置器+报价页面（前端，降为high）— PR#4113 submitted(CI Playwright✅)|
| 04-23 | kimi4 | ~~#1875~~ | bidding | **max** | ~~Done~~ | 赢/输复盘模板 — PR#3976 已于04-20 merged |
| 04-23 | kimi4 | ~~#3174~~ | approval | **max** | ~~Done~~ | 表单模板导入导出+配置向导 — PR#3937+#4080 已merged |
| 04-23 | kimi4 | ~~#3377~~ | plm | **max** | ~~Done~~ | PLM子系统数据库初始化 — 已merged/CLOSED |
| 04-23 | kimi4 | ~~#3378~~ | plm | **max** | ~~Done~~ | 零件主数据CRUD API — PR#3979 已于04-20 merged |
| 04-23 | kimi2 | ~~#4012~~ | project | **max** | ~~Done~~ | 老板周报AI建议Section — PR#4106 merged |
| 04-23 | kimi2 | ~~#4033~~ | crm | **max** | ~~Done~~ | CRM商机详情-基本信息Tab — PR#4062 已于04-22 merged |
| 04-23 | kimi2 | ~~#3387~~ | plm | **max** | ~~Done~~ | ECO执行引擎 — PR#4109 merged（@SaCheckPermission已修复）|
| 04-23 | kimi2 | ~~#3396~~ | plm | **max** | ~~Done~~ | PLM ECO变更管理页面 — PR#4114 merged |
| 04-23 | kimi2 | ~~#4021~~ | crm | **high** | ~~Plan~~ | Master CRM商务中心 — 导航归类用，禁止CC开发 |
| 04-23 | kimi2 | ~~#3150~~ | backend | medium | ~~Done~~ | 审批流程图渲染API — 已于04-21 merged/CLOSED |
| 04-23 | kimi2 | ~~#3996~~ | project | medium | ~~Done~~ | 矿场转化漏斗Tab — PR#4127 admin-merged ✅ |
| 04-23 | kimi2 | #4005 | frontend | medium | In Progress | 记录中心4Tab对齐v1.0原型 |
| 04-23 | kimi4 | ~~#4034~~ | crm | **max** | ~~Done~~ | CRM商机详情-跟进记录Tab — PR#4056+PR#4108 merged（N+1已知技术债，单商机场景可控）|
| 04-23 | kimi4 | ~~#3394~~ | plm | **max** | ~~Done~~ | PLM零件主数据管理页面 — PR#3990 已于04-20 merged |
| 04-23 | kimi4 | ~~#3395~~ | plm | **max** | ~~Done~~ | PLM BOM管理与版本对比页面 — PR#4116 merged |
| 04-23 | kimi4 | ~~#1832~~ | pipeline | medium | ~~Done~~ | Pipeline CI质量门禁+测试框架 — PR#4120 merged |
| 04-23 | kimi4 | #1875 | bidding | medium | In Progress | 赢/输复盘模板（新派）|
| 04-24 | #2132 ✅merged/kimi1 | ~~#1921~~ | d3 | medium | ~~Done~~ | D3Plugin.gha SDK降级 — PR #4143 merged，Issue自动关闭 |
| 04-24 | kimi2 | ~~#3151~~ | approval | medium | ~~Done~~ | 新手引导+流程帮助中心 — PR #4140 merged，Issue自动关闭 |
| 04-24 | kimi3 | ~~#2305~~ | design-ai | medium | ~~Done~~ | Three.js漫游录制 — PR #4145 merged，Issue自动关闭 |
| 04-24 | kimi3 | ~~#2307~~ | design-ai | medium | ~~Done~~ | 局部修改模块GUI — PR #4147 merged，Issue自动关闭 |
| 04-24 | kimi3 | #2309 | design-ai | medium | In Progress | 颜色配置器（排程建议#2，03:03派遣）|
| 04-24 | kimi5 | ~~#2310~~ | design-ai | medium | ~~Done~~ | 方案文本生成 — PR #4144 merged，Issue手动关闭 |
| 04-24 | kimi6 | #1920 | d3 | medium | Blocked | wande-gh-plugins重构 — PR #34 merge冲突，CI绿✅ |
| 04-24 | #2132 ✅merged/kimi1 | #3648 | bidding | low | In Progress | 招投标-DB建表 |
| 04-24 | kimi3 | #2307 | design-ai | medium | In Progress | 局部修改模块GUI |
| 04-24 | kimi5 | #1875 | bidding | medium | In Progress | 赢/输复盘模板 |
| 04-24 | kimi2 | ~~#3151~~ | approval | medium | ~~Done~~ | 新手引导+流程帮助中心追补 — PR #4140 merged，Issue自动关闭 ✅ |
| 04-24 | #2132 ✅merged/kimi1 | #4015 | crm | medium | In Progress | 矿场转商机 readiness检查 |
| 04-24 | kimi2 | #4016 | crm | medium | **等待merge** | 架构蓝图+术语数据字典（PR #4148已提交，E2E 4项全通过✅，等待CI/merge）|
| 04-24 | kimi5 | #4011 | project | medium | In Progress | 记录中心三视角分组Tab |
| 04-24 | #2132 ✅merged/kimi1 | ~~#4018~~ | crm | medium | ~~Done~~ | 整改crm_opportunity明道云对齐 + stage体系改造 — PR #4133已更新push，stage改造commit已push，MERGEABLE✅，等待CI/merge |
| 04-24 | #2132 ✅merged/kimi1 | #2308 | design-ai | **high** | In Progress | 主题方案灵感库（排程建议#1，03:00派遣，实际复杂度：复杂，15+文件，预计T1-15阶段交付）|
| 04-24 | kimi3 | #2309 | design-ai | medium | **等待merge** | 颜色配置器（排程建议#2，03:03派遣，PR #4149已提交，E2E smoke 4/4绿✅，MERGEABLE✅，等待自动merge）|
| 04-24 | kimi6 | ~~#1920~~ | d3 | medium | ~~Done~~ | wande-gh-plugins重构 — PR #34已于03:04 admin-merged ✅ |
| 04-24 | kimi6 | #3999 | project | **high** | In Progress | 矿场区域品类热力图Tab（排程建议#3，03:06派遣，实际高复杂度，15+文件，分契约→后端→前端→E2E→PR）|
| 04-24 | ~~kimi5~~ | ~~#1926~~ | d3 | medium | ~~Done~~ | D3成果Web预览 — PR #4185 merged 08:57:13，Issue自动关闭 08:58:02 ✅ |
| 04-24 | kimi2 | #3383 | backend | medium | ⏳ 等待close | 竞品定价数据库 — PR #3991已merged，等Issue自动关闭中 |
| 04-24 | kimi3 | #3384 | backend | medium | ⏳ 等待close | BOM Where-Used反查API — PR #4186 merged 08:53:07，等Issue自动关闭中 |
| 04-24 | ~~#2132 ✅merged/kimi1~~ | ~~#1906~~ | backend | medium | ~~Done~~ | **DORA指标卡片+最近错误滚动条** — Issue自动关闭 09:34:06 ✅ |
| 04-24 | kimi4 | #1923 | backend | medium | In Progress | 竞品定价数据库（派遣目标序号#2，实际Issue不同，49%进度） |
| 04-24 | **kimi5** | **#2536** | **frontend** | **medium** | **In Progress** | **项目组织管理-阶段推进确认弹窗增强（派遣目标序号#10，17:03派遣，44%进度）** |
| 04-24 | ~~kimi2~~ | ~~#3383~~ | backend | medium | ~~Done~~ | **Issue关闭异常修复** — PR #3991缺closingIssuesReferences，手动gh issue close，已释放 ✅ |
| 04-24 | **kimi2** | **#2527** | **frontend** | **medium** | **In Progress** | **版本历史+审批流程面板（派遣目标序号#7，17:40进度50%）** |
| 04-24 | ~~kimi3~~ | ~~#3384~~ | backend | medium | ~~Done~~ | **BOM Where-Used反查API** — PR #4186已merged，Issue手动关闭，已释放 ✅ |
| 04-24 | **kimi3** | **#2532** | **frontend** | **medium** | **In Progress** | **已读追踪+公告详情（派遣目标序号#8，17:40进度55%）** |
| 04-24 | **#2132 ✅merged/kimi1** | **#2534** | **frontend** | **medium** | **派遣开工** | **项目组织管理-任务面板快速行动项（派遣目标序号#9，17:41派遣）** |
| 05-04 | kimi2 | #1880 | asset-library | medium | **Done** | 素材库-中标状态变更时自动更新素材权限 — **PR #4445 MERGED** ✅ |
| 05-04 | kimi2 | #1488 | backend | medium | **Done** | 国际项目统一数据模型（wdpp_bid_projects表region/required_cert/language） — **PR #4444 MERGED** ✅ |
| 05-04 | #2132 ✅merged/kimi1 | #1818 | brand | medium | **Done** | 平台定制发布 — 多平台标题/标签/封面微调 — **PR #4440 MERGED** ✅ |
| 05-04 | kimi2 | #1551 | wecom | medium | **Done** | 企微待办API对接 — **PR #4446 MERGED** ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#1881~~ | asset-library | medium | **Done** | 素材下载 + 批量下载 + 分享链接 — **PR #4448 MERGED** ✅ |
| 05-04 | kimi4 | ~~#1963~~ | backend | P2 | **Done** | Rhino插件对接API — D3/Rhino渲染效果图自动注入素材库 — **PR #4425 MERGED** ✅ |
| 05-04 | kimi4 | ~~#1878~~ | asset-library | medium | **Done** | 素材统计接口 — **PR #4447 MERGED** ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#2201~~ | brand | P1 | **Done** | 品牌中心4级角色权限系统 — **PR #4412 MERGED** ✅ |
| 05-04 | kimi5 | ~~#1674~~ | biz-enablement | medium | **Done** | 产品参数查询中心API — 搜索/筛选/详情/资料包下载 — **PR #4449 MERGED** ✅ |
| 05-04 | kimi5 | ~~#1539~~ | budget | P2 | **Done** | 历史基准自动积累 — 项目关闭时自动更新成本基准库 — **PR #4451 MERGED** ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#1615~~ | chat | P1 | **Done** | 按群分角色AI配置-多角色模板系统 — **PR #4453 MERGED** ✅ |
| 05-12 | kimi2 | ~~#4720~~ | fullstack | medium | **Done** | 客户分级自动评定与管理 — PR#4770 MERGED ✅ |
| 05-12 | kimi1 | ~~#4767~~ | fullstack | medium | ~~Done~~ | 客户推荐关系与奖励管理 — PR#4786 merged |
| 05-12 | kimi2 | ~~#1911~~ | backend | P0 | ~~异常~~ | ~~D3-AI·AI电池包开发助手 — CC误杀，已重新指派~~ |
| 05-13 | kimi1 | #1911 | backend | P0 | In Progress | D3-AI·AI电池包开发助手 — 重新指派（G7e不可达则代码先行） |
| 05-12 | kimi3 | ~~#4771~~ | fullstack | medium | ~~Done~~ | 客户数据质量评分与管理 — CLOSED/COMPLETED |
| 05-12 | kimi4 | ~~#4769~~ | fullstack | medium | ~~Done~~ | 客户合同续约管理与到期预警 — CLOSED/COMPLETED |
| 05-12 | kimi5 | ~~#4772~~ | fullstack | medium | ~~Done~~ | 客户价值分层与RFM模型管理 — PR#4775 merged |
| 05-12 | kimi6 | ~~#4773~~ | fullstack | medium | ~~Done~~ | 客户健康度追踪与预警 — PR#4779 merged |
| 05-12 | kimi7 | ~~#4768~~ | fullstack | medium | ~~Done~~ | 客户投诉登记与处理跟踪 — PR#4774 merged |
| 05-12 | kimi8 | ~~#4766~~ | fullstack | medium | ~~Done~~ | 客户社交媒体互动记录管理 — PR#4777 merged |
| 05-13 | glm1 | ~~#18~~ | gh-plugins | medium | ~~Done~~ | D3生产链路-弧长/曲线标注增强 — **PR#37 MERGED** ✅ |
| 05-13 | glm2 | ~~#19~~ | gh-plugins | medium | ~~Done~~ | D3生产链路-曲面面板分割电池包 — **PR#38 MERGED** ✅ |
| 05-13 | glm3 | #20 | gh-plugins | medium | In Progress | D3生产链路-图纸分级输出系统（P1） |
| 05-13 | glm4 | ~~#23~~ | gh-plugins | medium | ~~Done~~ | D3缺陷修复-Redis缓存层 — **PR#36 MERGED** ✅ |
| 05-13 | glm4 | ~~#17~~ | gh-plugins | medium | ~~Done~~ | D3生产链路-2D板材排料电池包 — **PR#39 MERGED** ✅ |
| 05-13 | glm4 | ~~#2~~ | gh-plugins | medium | ~~Done~~ | DfMA制造可行性检测引擎 — **PR#41 MERGED** ✅ |
| 05-13 | kimi1 | ~~#1911~~ | backend | P0 | ~~Done~~ | D3-AI·AI电池包开发助手 — **PR#4801 MERGED** ✅（Jenkins部署失败需关注） |
| 05-13 | kimi1 | ~~#25~~ | gh-plugins | P1 | ~~Done~~ | D3电池包端到端测试套件 — **PR#42 MERGED** ✅ |
| 05-13 | glm4 | ~~#3~~ | gh-plugins | P1 | ~~Done~~ | D3几何审计脚本 — **PR#43 MERGED** ✅ |
| 05-13 | kimi1 | ~~#4~~ | gh-plugins | P1 | ~~Done~~ | D3钢管下料优化（1D Nesting）— **PR#45 MERGED** ✅ |
| 05-13 | glm4 | ~~#5~~ | gh-plugins | P1 | ~~Done~~ | D3 CNC/激光切割文件输出 — **PR#44 MERGED** ✅ |
| 05-13 | kimi1 | ~~#24~~ | gh-plugins | P2 | ~~Done~~ | GH端纯参数传递模式改造 — **PR#46 MERGED** ✅ |
| 05-13 | glm1 | ~~#9~~ | gh-plugins | P0 | ~~Done~~ | D3_Core共享模块 — **PR#40 MERGED** ✅ |
| 05-13 | kimi1 | ~~#6~~ | gh-plugins | P1 | ~~Done~~ | D3 STEP零件批量导出 — **PR#48 MERGED** ✅ |
| 05-13 | glm1 | ~~#7~~ | gh-plugins | P1 | ~~Done~~ | D3一键标注出图组件 — **PR#49 MERGED** ✅ |
| 05-13 | kimi1 | ~~#8~~ | gh-plugins | P1 | ~~Done~~ | D3一键BOM+报价引擎 — **PR#50 MERGED** ✅ |
| 05-13 | kimi1 | ~~#13~~ | gh-plugins | P1 | ~~Done~~ | D3_Visual模块 — **PR#51 MERGED** ✅ |
| 05-13 | kimi1 | ~~#12~~ | gh-plugins | P1 | ~~Done~~ | D3文档输出模块 — **PR#52 MERGED** ✅ |
| 05-13 | kimi1 | ~~#25~~ | gh-plugins | P1 | ~~Done~~ | D3电池包端到端测试 — **PR#53 MERGED** ✅ |

**当前5个CC在线运行中（05-13研发经理指派）：**
- glm1 #11: D3_Structure模块（gh-plugins，P1，编码中）
- glm2 #10: D3_Safety安全区域（gh-plugins，P0，PR准备中 62%）
- glm3 #20: D3生产链路-图纸分级输出系统（gh-plugins，P1，39%）
- glm4 #21: D3生产链路-表皮效果预览（gh-plugins，P2，30%）
- kimi1 #23: D3缺陷修复-Redis缓存层（gh-plugins，P1，刚启动）

**最近完成（本轮巡检新增）**:
- ~~kimi2 #4720~~ → PR#4770 MERGED（研发经理手动rebase解决crm.ts冲突）✅
- Master #3647 → 所有子Issue CLOSED，自动关闭 ✅
- Master #4020 → 所有子Issue CLOSED，自动关闭 ✅
- 22个 needs-prototype Plan Issue → 批量移入 pause ✅

---


> **可执行Issue清单归档**：原161个Issue中159个已完成（CLOSED），7个仍在OPEN：#1466/#2218/#2223/#4013/#4021/#4043/#4046。已完成信息已汇总至指派历史表。
> Plan 队列已被 needs-prototype 严重阻塞（~37/45 Issue 冻结，已批量移入pause）。新 Issue 需从 Master Issue 拆分创建。
