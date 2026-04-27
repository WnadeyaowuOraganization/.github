# Sprint-2 排程计划

> 更新时间：2026-04-24 02:50
> 来源：v5.1 §5.6 全量对账 — 326个已合规Issue一次性排程
> 规则：EXEMPT 33个→Todo / A档128个→按Sprint Todo / C_frozen 165个→保持Plan(needs-prototype)
> 并发上限：5个CC
> ⚠️ **备选队列已用尽** — 20个Issue全部完成，需排程经理补充新建议

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
> 更新时间：2026-04-26 23:17（第10轮刷新，前75条全部完成，新建议76-95）
> 排除：needs-prototype 标签、Master Issue、已派/已完成

| 序号 | Issue | 优先级 | 模块 | effort | 说明 | 启动 |
|------|-------|--------|------|--------|------|------|
| 76 | #2704 | P1 | bidding | medium | 中标概率评分可视化看板（已启动过，恢复） | ✅ |
| 77 | #3172 | P1 | backend | medium | 质量管理表单组5模板（已启动过，恢复） | ✅ |
| 78 | #2275 | P1 | dashboard | medium | 驾驶舱首页DORA指标卡片+最近错误滚动条 | ✅ |
| 79 | #2437 | P1 | backend | medium | 推荐行动计划按阶段自动生成 [22/38] | ✅ |
| 80 | #2440 | P1 | backend | medium | 竞品定价数据库 [18/38] | ✅ |
| 81 | #1598 | P1 | budget | medium | 付款申请接入预算关卡 [15/32] | ✅ |
| 82 | #1603 | P1 | budget | medium | 中标服务费自动计算 [9/32] | ✅ |
| 83 | #2439 | P1 | pipeline | medium | T0/T1/T2竞品自动分级+升降级机制 [19/38] | ✅ |
| 84 | #2215 | P1 | biz-enablement | medium | 引导式PPT组装向导 [22/28] | ✅ |
| 85 | #2306 | P1 | design-ai | high | D3 Web设计工作台 — 电池包拖拽+Three.js | ✅ |
| 86 | #2441 | P1 | frontend | medium | 竞品区域热力图 vs 万德区域热力图 [17/38] | ⏳前置#2440 |
| 87 | #2617 | P1 | fullstack | low | Issue创建SOP更新 — PageGuide必填 [4/4] | ✅ |
| 88 | #2585 | P2 | backend | medium | refactor: 合并wande-ai-api模块到wande-ai | ✅ |
| 89 | #1573 | P2 | policy | medium | 制度智能问答API [22/22] | ✅ |
| 90 | #2444 | P2 | backend | medium | keyword_pool新增政策类关键词 [13/38] | ✅ |
| 91 | #2222 | P2 | biz-enablement | medium | 案例搜索（1搜索框+6维筛选）[6/28] | ✅ |
| 92 | #2526 | P2 | frontend | medium | 文档上传+新版本上传弹窗 [6/18] | ✅ |
| 93 | #2288 | P2 | budget | medium | 成本复盘报告页面 [30/32] | ✅ |
| 94 | #3109 | P2 | fullstack | medium | 客户信用额度管理 — 授信+在途应收+超额预警 | ✅ |
| 95 | #2277 | P2 | policy | medium | 条款库管理页面 [21/22] | ✅ |

## 指派历史

| 日期 | kimi | Issue | 模块 | effort | 状态 | 备注 |
|------|------|-------|------|--------|------|------|
| 04-22 | kimi1 | ~~#3386~~ | PLM | medium | ~~Done~~ | ECO审批流集成 — CLOSED/COMPLETED |
| 04-22 | kimi2 | ~~#3389~~ | PLM | medium | ~~Done~~ | EBOM解析API — CLOSED/COMPLETED |
| 04-22 | kimi3 | ~~#3392~~ | PLM | medium | ~~Done~~ | 版本化定价引擎API — CLOSED/COMPLETED |
| 04-22 | kimi4 | ~~#3631~~ | bidding | high | ~~Done~~ | pipeline表对齐 — CLOSED/COMPLETED |
| 04-22 | kimi5 | ~~#1692~~ | backend | medium | ~~Done~~ | ~~项目成本跟踪API~~ — PR #3844 已于04-19 merged，误派 |
| 04-22 | kimi5 | ~~#2113~~ | backend | medium | ~~Done~~ | 合同审批流程 — CLOSED/COMPLETED |
| 04-22 | kimi1 | ~~#2296~~ | wechat | medium | ~~Done~~ | Cockpit安全审计页面 — CLOSED/COMPLETED |
| 04-22 | kimi5 | #2298 | cockpit | medium | In Progress | AI对话监控面板 |
| 04-22 | kimi2 | ~~#2925~~ | backend | medium | ~~Done~~ | 字段级数据完整度计算引擎 — CLOSED/COMPLETED |
| 04-22 | kimi3 | ~~#2926~~ | backend | medium | ~~Done~~ | 数据质量KPI API — CLOSED/COMPLETED |
| 04-22 | kimi2 | ~~#2944~~ | backend | medium | ~~Done~~ | 7天滚动基线异常检测 — CLOSED/COMPLETED |
| 04-22 | kimi4 | #4033 | crm | medium | In Progress | CRM商机详情-基本信息Tab |
| 04-22 | kimi1 | #4034 | crm | medium | In Progress | CRM商机详情-跟进记录Tab |
| 04-22 | kimi2 | #4035 | crm | medium | In Progress | CRM商机详情-设计单Tab |
| 04-22 | kimi3 | #4036 | crm | medium | In Progress | CRM商机详情-报价Tab |
| 04-22 | kimi1 | #4034 | crm | medium | **Done** | CRM商机详情-跟进记录Tab — PR #4056 merged |
| 04-22 | kimi1 | #4037 | crm | medium | **Done** | CRM商机详情-合同Tab — PR #4064 merged |
| 04-22 | kimi1 | #4042 | crm | medium | **Done** | CRM商机详情-流程监控Tab — PR #4071 merged |
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
| 04-22 | kimi1 | ~~#3150~~ | approval | **max** | ~~Done~~ | 审批流程图渲染API — 补充PR #4072 merged |
| 04-22 | kimi5 | ~~#3169~~ | approval | **max** | ~~Done~~ | 表单模板管理 — PR #4076 merged |
| 04-22 | kimi2 | ~~#2849~~ | cockpit | **max** | ~~Done~~ | Agent效率看板前端 — PR #4074 merged |
| 04-22 | kimi3 | ~~#3648~~ | bidding | **max** | ~~Done~~ | 招投标DB建表 — 补充PR #4073 merged |
| 04-22 | kimi4 | ~~#2851~~ | cockpit | **max** | ~~Done~~ | 验收队列前端 — PR #4075 merged |
| 04-22 | kimi2 | #3149 | approval | **max** | In Progress | 审批进度追踪器组件 |
| 04-22 | kimi3 | #3155 | approval | **max** | In Progress | 流程简化配置页 |
| 04-22 | kimi4 | #3156 | approval | **max** | In Progress | 流程效率分析看板 |
| 04-22 | kimi1 | #3168 | approval | **max** | In Progress | 动态表单渲染器前端 |
| 04-22 | kimi5 | #3151 | approval | **max** | In Progress | 新手引导+流程帮助中心 |
| 04-22 | kimi2 | ~~#3149~~ | approval | **max** | ~~Done~~ | 审批进度追踪器组件 — PR #4077 merged |
| 04-22 | kimi2 | ~~#3174~~ | approval | **max** | ~~Done~~ | 表单模板导入导出+配置向导 — PR #4080 merged |
| 04-22 | kimi4 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — PR #4079 merged |
| 04-22 | kimi1 | ~~#3168~~ | approval | **max** | ~~Done~~ | 动态表单渲染器前端 — PR #4078 merged |
| 04-22 | kimi2 | ~~#4024~~ | plm | **max** | ~~Done~~ | PLM产品技术中心 — PR #4083 merged |
| 04-22 | kimi1 | ~~#4023~~ | approval | **max** | ~~Done~~ | 统一审批工作台 — PR #4082 merged |
| 04-22 | kimi5 | ~~#3151~~ | approval | **max** | ~~Done~~ | 新手引导+流程帮助中心 — PR #4081 merged |
| 04-22 | kimi3 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR #4084 merged |
| 04-22 | kimi4 | ~~#4041~~ | cockpit | **max** | ~~Done~~ | 耀总驾驶舱 — PR #4085 merged |
| 04-22 | kimi2 | ~~#3189~~ | finance | **max** | ~~Done~~ | 甲方表单填写辅助 — PR #4088 merged |
| 04-23 | kimi1 | ~~#2427~~ | pipeline | medium | ~~Done~~ | 环评/规划许可公示采集 — PR #4130 merged |
| 04-23 | kimi2 | ~~#4005~~ | frontend | medium | ~~Done~~ | 整改 记录中心4Tab对齐 — PR #4131 merged |
| 04-23 | kimi3 | ~~#4006~~ | frontend | medium | ~~Done~~ | 整改 老板周报对齐 — PR #4106 merged |
| 04-23 | kimi5 | ~~#3397~~ | frontend | medium | ~~Done~~ | 产品配置器+报价页面 — PR #4083 merged |
| 04-23 | kimi6 | #4037 | crm | medium | In Progress | CRM商机详情-合同Tab |
| 04-23 | kimi3 | ~~#4042~~ | frontend | medium | ~~Done~~ | CRM流程监控Tab — PR #4071 merged，Issue #4042已关闭 |
| 04-23 | kimi5 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR #4084 merged |
| 04-23 | kimi2 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — PR #4079 merged |
| 04-23 | kimi1 | ~~#4018~~ | crm | medium | ~~Done~~ | 整改 crm_opportunity 明道云对齐 — PR #4133 merged |
| 04-23 | kimi1 | #4007 | frontend | medium | In Progress | 整改 项目周报+Nudge联动改造 |
| 04-23 | kimi5 | #4017 | crm | medium | In Progress | 整改 crm_activity_log 明道云对齐 |
| 04-23 | kimi2 | #4019 | crm | medium | In Progress | 整改 crm_customer 明道云补齐 |
| 04-22 | kimi2 | ~~#4008~~ | project | **max** | ~~Done~~ | 记录中心时间线视角增强 — PR #4096 merged |
| 04-22 | kimi4 | ~~#3996~~ | project | **max** | ~~Done~~ | 矿场转化漏斗Tab — PR #4089 merged |
| 04-22 | kimi4 | #4009 | project | **max** | In Progress | 记录中心三视角分组Tab |
| 04-22 | kimi1 | ~~#3184~~ | project360 | **max** | ~~Done~~ | 文档访问日志+统计 — PR #4086 merged |
| 04-22 | kimi3 | ~~#3185~~ | project360 | **max** | ~~Done~~ | 全阶段资料完成度看板 — PR #4087 merged |
| 04-22 | kimi1 | ~~#3997~~ | project | **max** | ~~Done~~ | 矿场复盘洞察Tab — PR #4099 merged |
| 04-22 | kimi3 | ~~#3998~~ | project | **max** | ~~Done~~ | 矿场ROI看板Tab — PR #4092 merged |
| 04-22 | kimi5 | ~~#4014~~ | crm | **max** | ~~Done~~ | CRM线索统一池+评分引擎 — PR #4090 merged |
| 04-22 | kimi5 | ~~#4010~~ | project | **max** | ~~Done~~ | 手动补录记录模态 — PR #4105 merged |
| 04-22 | kimi3 | ~~#4015~~ | crm | **max** | ~~Done~~ | 矿场转商机 readiness检查 — PR #4102 merged |
| 04-22 | kimi4 | ~~#4009~~ | project | **max** | ~~Done~~ | 记录中心三视角分组Tab — PR #4098 merged |
| 04-22 | kimi4 | ~~#2851~~ | cockpit | **max** | ~~Done~~ | 验收队列E2E修复 — PR #4101 merged |
| 04-22 | kimi4 | ~~#2926~~ | backend | **max** | ~~Done~~ | 数据质量KPI API — PR #4053 已于04-21 merged |
| 04-22 | kimi4 | ~~#2944~~ | backend | **max** | ~~Done~~ | 7天滚动基线异常检测 — PR #4055 已于04-21 merged |
| 04-22 | kimi4 | ~~#3149~~ | approval | **max** | ~~Done~~ | 审批进度追踪器组件 — PR#3902+PR#4077 已merged |
| 04-23 | kimi1 | #2427 | bidding | medium | In Progress | 环评/规划许可公示采集 (PR#4130等待CI) |
| 04-23 | kimi2 | #4005 | frontend | medium | In Progress | 整改 记录中心4Tab对齐v1.0原型 (PR#4131 E2E 3/3通过) |
| 04-23 | kimi3 | #4006 | frontend | medium | In Progress | 整改 老板周报对齐v1.0原型 (PR#4132 E2E 11/11通过) |
| 04-23 | kimi5 | #3397 | frontend | medium | In Progress | PLM产品配置器+报价页面 (PR#4128冲突解决中) |
| 04-23 | kimi4 | ~~#3996~~ | project | medium | ~~Done~~ | 矿场-转化漏斗Tab — PR #4127 merged |
| 04-23 | kimi5 | ~~#4014~~ | crm | medium | ~~Done~~ | 线索统一池+评分引擎 — PR #4126 merged |
| 04-23 | kimi1 | ~~#3995~~ | project | medium | ~~Done~~ | 矿场v2.0执行组6Tab对齐 — PR #4122 merged |
| 04-23 | kimi2 | ~~#4018~~ | crm | medium | ~~Done~~ | 明道云商机数据迁移+表结构调整 — PR #4121 merged |
| 04-23 | kimi3 | ~~#4021~~ | crm | medium | ~~Done~~ | CRM商务中心仪表盘实现 — PR #4119 merged |
| 04-23 | kimi1 | ~~#2317~~ | plm | medium | ~~Done~~ | PLM技术确认中心前端 — PR #4117 merged |
| 04-22 | kimi4 | ~~#3150~~ | approval | **max** | ~~Done~~ | 审批流程图渲染API — 已于04-21 merged |
| 04-22 | kimi2 | ~~#4012~~ | project | **max** | ~~Done~~ | 老板周报AI建议Section — PR#4106 merged |
| 04-22 | kimi1 | ~~#2849~~ | cockpit | **max** | ~~Done~~ | Agent效率看板Vitest补测 — PR #4100 merged |
| 04-22 | kimi1 | ~~#2925~~ | backend | **max** | ~~Done~~ | 字段级数据完整度计算引擎 — PR #4052 已于04-21 merged |
| 04-22 | kimi1 | ~~#3155~~ | approval | **max** | ~~Done~~ | 流程简化配置页 — PR#3931+#4084 已merged |
| 04-23 | kimi6 | #4037 | fullstack | medium | In Progress | CRM合同Tab创建+盖章+扫描件上传（备选队列#1指派） |
| 04-22 | kimi1 | ~~#3156~~ | approval | **max** | ~~Done~~ | 流程效率分析看板 — 已merged |
| 04-22 | kimi1 | ~~#3168~~ | approval | **max** | ~~Done~~ | 动态表单渲染器前端 — PR#4078 merged |
| 04-23 | kimi1 | ~~#2078~~ | backend | **max** | ~~Done~~ | 原因诊断API — PR #4103 merged |
| 04-23 | kimi3 | ~~#3545~~ | intelligence-hub | **max** | ~~Done~~ | 前端关系网络Tab — PR #4104 merged |
| 04-23 | kimi1 | ~~#3386~~ | plm | **max** | ~~Done~~ | ECO审批流集成 — PR#4051 已于04-21 merged |
| 04-23 | kimi1 | ~~#3651~~ | bidding | **max** | ~~Done~~ | 投标立项与进度管理 — PR#4112 merged |
| 04-23 | kimi1 | ~~#2317~~ | ptc | **max** | ~~Done~~ | D3 Web技术确认中心前端 — PR#4117 admin-merged ✅|
| 04-23 | kimi1 | ~~#4020~~ | cockpit | **high** | ~~Plan~~ | Master超管驾驶舱18Tab — 导航归类用，禁止CC开发 |
| 04-23 | kimi1 | ~~#4014~~ | crm | medium | ~~Done~~ | 线索统一池+评分引擎 — PR#4126 admin-merged ✅ |
| 04-23 | kimi1 | ~~#3998~~ | project | medium | ~~Done~~ | 矿场-ROI看板Tab — PR#4092 已merged（误派，实际已完成）|
| 04-23 | kimi1 | #2427 | bidding | medium | In Progress | 环评/规划许可公示采集 |
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
| 04-24 | kimi1 | ~~#1921~~ | d3 | medium | ~~Done~~ | D3Plugin.gha SDK降级 — PR #4143 merged，Issue自动关闭 |
| 04-24 | kimi2 | ~~#3151~~ | approval | medium | ~~Done~~ | 新手引导+流程帮助中心 — PR #4140 merged，Issue自动关闭 |
| 04-24 | kimi3 | ~~#2305~~ | design-ai | medium | ~~Done~~ | Three.js漫游录制 — PR #4145 merged，Issue自动关闭 |
| 04-24 | kimi3 | ~~#2307~~ | design-ai | medium | ~~Done~~ | 局部修改模块GUI — PR #4147 merged，Issue自动关闭 |
| 04-24 | kimi3 | #2309 | design-ai | medium | In Progress | 颜色配置器（排程建议#2，03:03派遣）|
| 04-24 | kimi5 | ~~#2310~~ | design-ai | medium | ~~Done~~ | 方案文本生成 — PR #4144 merged，Issue手动关闭 |
| 04-24 | kimi6 | #1920 | d3 | medium | Blocked | wande-gh-plugins重构 — PR #34 merge冲突，CI绿✅ |
| 04-24 | kimi1 | #3648 | bidding | low | In Progress | 招投标-DB建表 |
| 04-24 | kimi3 | #2307 | design-ai | medium | In Progress | 局部修改模块GUI |
| 04-24 | kimi5 | #1875 | bidding | medium | In Progress | 赢/输复盘模板 |
| 04-24 | kimi2 | ~~#3151~~ | approval | medium | ~~Done~~ | 新手引导+流程帮助中心追补 — PR #4140 merged，Issue自动关闭 ✅ |
| 04-24 | kimi1 | #4015 | crm | medium | In Progress | 矿场转商机 readiness检查 |
| 04-24 | kimi2 | #4016 | crm | medium | **等待merge** | 架构蓝图+术语数据字典（PR #4148已提交，E2E 4项全通过✅，等待CI/merge）|
| 04-24 | kimi5 | #4011 | project | medium | In Progress | 记录中心三视角分组Tab |
| 04-24 | kimi1 | ~~#4018~~ | crm | medium | ~~Done~~ | 整改crm_opportunity明道云对齐 + stage体系改造 — PR #4133已更新push，stage改造commit已push，MERGEABLE✅，等待CI/merge |
| 04-24 | kimi1 | #2308 | design-ai | **high** | In Progress | 主题方案灵感库（排程建议#1，03:00派遣，实际复杂度：复杂，15+文件，预计T1-15阶段交付）|
| 04-24 | kimi3 | #2309 | design-ai | medium | **等待merge** | 颜色配置器（排程建议#2，03:03派遣，PR #4149已提交，E2E smoke 4/4绿✅，MERGEABLE✅，等待自动merge）|
| 04-24 | kimi6 | ~~#1920~~ | d3 | medium | ~~Done~~ | wande-gh-plugins重构 — PR #34已于03:04 admin-merged ✅ |
| 04-24 | kimi6 | #3999 | project | **high** | In Progress | 矿场区域品类热力图Tab（排程建议#3，03:06派遣，实际高复杂度，15+文件，分契约→后端→前端→E2E→PR）|
| 04-24 | ~~kimi5~~ | ~~#1926~~ | d3 | medium | ~~Done~~ | D3成果Web预览 — PR #4185 merged 08:57:13，Issue自动关闭 08:58:02 ✅ |
| 04-24 | kimi2 | #3383 | backend | medium | ⏳ 等待close | 竞品定价数据库 — PR #3991已merged，等Issue自动关闭中 |
| 04-24 | kimi3 | #3384 | backend | medium | ⏳ 等待close | BOM Where-Used反查API — PR #4186 merged 08:53:07，等Issue自动关闭中 |
| 04-24 | ~~kimi1~~ | ~~#1906~~ | backend | medium | ~~Done~~ | **DORA指标卡片+最近错误滚动条** — Issue自动关闭 09:34:06 ✅ |
| 04-24 | kimi4 | #1923 | backend | medium | In Progress | 竞品定价数据库（派遣目标序号#2，实际Issue不同，49%进度） |
| 04-24 | **kimi5** | **#2536** | **frontend** | **medium** | **In Progress** | **项目组织管理-阶段推进确认弹窗增强（派遣目标序号#10，17:03派遣，44%进度）** |
| 04-24 | ~~kimi2~~ | ~~#3383~~ | backend | medium | ~~Done~~ | **Issue关闭异常修复** — PR #3991缺closingIssuesReferences，手动gh issue close，已释放 ✅ |
| 04-24 | **kimi2** | **#2527** | **frontend** | **medium** | **In Progress** | **版本历史+审批流程面板（派遣目标序号#7，17:40进度50%）** |
| 04-24 | ~~kimi3~~ | ~~#3384~~ | backend | medium | ~~Done~~ | **BOM Where-Used反查API** — PR #4186已merged，Issue手动关闭，已释放 ✅ |
| 04-24 | **kimi3** | **#2532** | **frontend** | **medium** | **In Progress** | **已读追踪+公告详情（派遣目标序号#8，17:40进度55%）** |
| 04-24 | **kimi1** | **#2534** | **frontend** | **medium** | **派遣开工** | **项目组织管理-任务面板快速行动项（派遣目标序号#9，17:41派遣）** |

**当前5个CC在线运行中（17:16:56更新 — 派遣链恢复）：**
- kimi1 #1906: 58%进度（DORA指标卡片+错误滚动条，backend，持续工作中）
- ~~kimi2 #3383~~ → **kimi2 #2527**: 0%进度（版本历史+审批流程面板，frontend，刚启动）✅ 序号#7
- ~~kimi3 #3384~~ → **kimi3 #2532**: 0%进度（已读追踪+公告详情，frontend，刚启动）✅ 序号#8
- kimi4 #1923: 62%进度（竞品定价数据库，backend，持续工作中）
- kimi5 #2536: 44%进度（项目组织管理-阶段推进弹窗增强，frontend，持续工作中）

**最近完成（本轮巡检新增）**:
- ~~kimi5 #1926~~ → PR #4185 merged 08:57:13 → Issue自动关闭 08:58:02 ✅
- ~~kimi3 #3384~~ → PR #4186 merged 08:53:07 → 等待自动关闭
- ~~kimi2 #3383~~ → PR #3991已merged → 等待自动关闭

**下一批派遣计划**（kimi2/3释放后）:
1. kimi2释放 → 派遣 #2527（序号#7，版本历史+审批流程面板，frontend）
2. kimi3释放 → 派遣 #2532（序号#8，已读追踪+公告详情，frontend）
3. 暂停 #2441（序号#6需要#2440先完成，目前#2440未派遣）

---

## 可执行Issue清单（161个，按Sprint分组）

### Sprint-1 (22个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #2296 | P1 | wechat | [15/18][P1] Cockpit安全审计页面 — 合规状态+审计日志+敏感词管理 | EXEMPT | | Todo |
| #2298 | P1 |  | [4/18][P0] Cockpit AI对话监控面板 — 全渠道对话数据可视化 | A | | Todo |
| #2849 | P1 | cockpit | [开发模式监控-P1][5/7] Agent效率看板前端 — 线路状态矩阵+产能趋势+Me | A | | Todo |
| #2851 | P1 | cockpit | [开发模式监控-P1][7/7] 验收队列前端 — 我的待办卡片+紧急程度排序+响应时间趋 | A | | Todo |
| #2925 | P1 |  | [采集管控-P0][L3-1/3] 字段级数据完整度计算引擎 — 关键字段填充率+趋势+阈 | A | | Todo |
| #2926 | P1 |  | [采集管控-P0][L3-2/3] 数据质量KPI API — 6维度质量指标查询+趋势+ | A | | Todo |
| #2944 | P1 |  | [采集管控-P0][L4-1/2] 7天滚动基线异常检测 — 数据量/通过率偏离自动告警+ | A | | Todo |
| #4033 | P1 | crm | [CRM][#4022-1][P1] 基本信息 — 商机完整字段展示+编辑态+AI预填+矿 | A | | Todo |
| #4034 | P1 | crm | [CRM][#4022-2][P1] 跟进记录 — 时间线日志+新增跟进弹窗+自动记录混排 | A | | Todo |
| #4035 | P1 | crm | [CRM][#4022-3][P1] 设计单 — D3跨模块联动+下设计单+状态列表 | A | | Todo |
| #4036 | P1 | crm | [CRM][#4022-4][P1] 报价 — 报价单CRUD+审批流提交+状态流转 | A | | Todo |
| #4037 | P1 | crm | [CRM][#4022-5][P1] 合同 — Sprint-1基础合同创建+盖章状态+扫 | A | | Todo |
| #4038 | P1 | crm | [CRM][#4022-6][P1] 回款 — 五节点计划+收款记录+逾期预警 | A | | Todo |
| #4039 | P1 | crm | [CRM][#4022-7][P1] 投标HZ — 投标申请+标书上传+企微审批触发 | A | | Todo |
| #4040 | P1 | crm | [CRM][#4022-8][P1] 资料 — S3附件上传下载+分类筛选+presign | A | | Todo |
| #4042 | P1 | crm | [CRM][#4022-9][P1] 流程监控 — 审批流聚合视图+逾期标红+催办限频 | A | | Todo |
| #4044 | P1 | crm | [CRM][#4022-10][P1] 变更日志 — AOP自动捕获字段变更+阶段推进标注 | A | | Todo |
| #1920 | P2 |  | [D3-v2.0][P0] wande-gh-plugins仓库重构 — COMPAS c | EXEMPT | | Todo |
| #1921 | P2 |  | [D3-v2.0][P0][紧急] D3Plugin.gha SDK版本降级 — 兼容Rh | EXEMPT | | Todo |
| #4020 | P2 | cockpit | [Master][超管驾驶舱] 平台级控制台 — 多Tab架构 18Tab（4大分组） | A_weak | | Todo |
| #4021 | P2 | crm | [Master][CRM] 商务中心 — 10页独立架构（仪表盘+客户+商机+询盘+记录+ | A_weak | | Todo |
| #4022 | P2 | crm | [Master][CRM] 商机详情页 — 多Tab架构 10Tab（左摘要+右侧Tab栏 | A_weak | | Todo |

### Sprint-2 (18个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #3648 | P0 | bidding | [招投标-DB] 数据库建表 — 10张表 Flyway迁移 | A_weak | | Todo |
| #1832 | P1 |  | [测试基建-P0] Pipeline仓库CI质量门禁+采集脚本测试框架+CLAUDE.md | EXEMPT | | Todo |
| #1875 | P1 | bidding | [P1][16/38] 赢/输复盘模板 + 系统化采集 | A | | Todo |
| #3149 | P1 |  | [审批引擎增强] 审批进度追踪器组件 — 流程地图+当前步骤高亮+卡点提示+预估耗时 [1 | A | | Todo |
| #3150 | P1 |  | [审批引擎增强] 审批流程图渲染API — 模板→实例DAG+节点状态+耗时统计 [2/8 | A | | Todo |
| #3155 | P1 |  | [审批引擎增强] 流程简化配置页 — 跳过规则/自动审批/路由规则可视化配置 [7/8] | A | | Todo |
| #3156 | P1 |  | [审批引擎增强] 流程效率分析看板 — 节点耗时/驳回率/瓶颈定位+优化建议 [8/8] | A | | Todo |
| #3168 | P1 | approval | [流程补齐 2/8] 动态表单渲染器前端 — JSON Schema→Vue3组件自动渲染 | A | | Todo |
| #3169 | P1 | approval | [流程补齐 3/8] 表单模板管理 — 模板CRUD+分类+启用/停用+审批流绑定 | A | | Todo |
| #3651 | P1 | bidding | [招投标-C] 投标立项与进度管理 | A_weak | | Todo |
| #2427 | P2 | bidding | [P2][38/38] 环评/规划许可公示采集 — 六层信号源第四层 | A | | Todo |
| #2428 | P2 | bidding | [P2][37/38] 人大代表建议/政协提案采集（最早期信号） | A | | Todo |
| #2429 | P2 | bidding | [P2][34/38] 行业展会参展商名录定期采集 | A | | Todo |
| #3151 | P2 |  | [审批引擎增强] 新手引导+流程帮助中心 — Tooltip引导+流程说明+常见问题 [3 | A | | Todo |
| #3174 | P2 | approval | [流程补齐 8/8] 表单模板导入导出+配置向导 — 模板迁移+快速配置 | A | | Todo |
| #4023 | P2 | approval | [Master][审批体系] 统一审批工作台 — 多Tab架构 8Tab（含动态表单+企微 | A_weak | | Todo |
| #4024 | P2 | plm | [Master][PLM] 产品技术中心 — 多Tab架构 8Tab（零件+BOM+ECO | A_weak | | Todo |
| #4041 | P2 | cockpit | [Master][耀总驾驶舱] 个人业务决策驾驶舱 — 多区块架构 8区块 | A_weak | | Todo |

### Sprint-3 (37个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #4014 | P0 | crm | [CRM][#4013-1][P0] 线索统一池 + 评分引擎 — leads表+评分规则 | A | | Todo |
| #4018 | P0 | crm | [整改][CRM] crm_opportunity — 明道云 xsfx 主+副本 6,3 | EXEMPT | | Todo |
| #2198 | P1 |  | [品牌中心] 视频号自动化发布 — social-auto-upload 部署 | EXEMPT | | Todo |
| #2310 | P1 | design-ai | [设计模块-P1][8/30] 方案文本模块 — 分Section编辑器+AI辅助(独立可 | A | | Todo |
| #3995 | P1 | project | [整改][矿场] 全球项目矿场 — 按 v2.0 原型调整 | EXEMPT | | Todo |
| #3996 | P1 | project | [矿场][#3994-1][P1] 转化漏斗Tab — 5阶段漏斗+阶段下钻 | A | | Todo |
| #3997 | P1 | project | [矿场][#3994-4][P1] 复盘洞察Tab — 失败原因Top10+胜率趋势+AI | A | | Todo |
| #3998 | P1 | project | [矿场][#3994-2][P1] ROI看板Tab — 来源渠道ROI+获客成本趋势 | A | | Todo |
| #4005 | P1 |  | [整改][记录中心] 4Tab架构按v1.0原型对齐 | EXEMPT | | Todo |
| #4006 | P1 |  | [整改][老板周报] 单页按v1.0原型对齐 | EXEMPT | | Todo |
| #4007 | P1 |  | [整改][项目周报+Nudge] 联动改造 | EXEMPT | | Todo |
| #4008 | P1 | project | [记录中心][#4004-1][P1] 时间线视角增强 | A | | Todo |
| #4009 | P1 | project | [记录中心][#4004-2][P1] 三视角分组Tab | A | | Todo |
| #4010 | P1 | project | [记录中心][#4004-3][P1] 手动补录记录模态 | A | | Todo |
| #4012 | P1 | project | [老板周报][#4004-5][P1] AI建议Section | A | | Todo |
| #4015 | P1 | crm | [整改][CRM][#4013-2][P1] 矿场转商机 readiness 检查 — 三 | EXEMPT | | Todo |
| #4017 | P1 | crm | [整改][CRM] crm_activity_log — 明道云 gjjl 65 万条销售 | EXEMPT | | Todo |
| #4019 | P1 | crm | [整改][CRM] crm_customer — 按明道云 kehu 补齐 4,528 行 | EXEMPT | | Todo |
| #2305 | P2 | design-ai | [设计模块-P2][35/35] Three.js漫游录制 — 摄像机路径设定→实时录制→ | A | | Todo |
| #2307 | P2 | design-ai | [设计模块-P2][16/30] 局部修改模块GUI — 圈选区域+描述修改+Inpain | A | | Todo |
| #2308 | P2 | design-ai | [设计模块-P2][13/30] 主题方案灵感库 — 20+主题模板+AI变体生成 | A | | Todo |
| #2309 | P2 | design-ai | [设计模块-P2][12/30] 颜色配置器 — 选产品选色Three.js实时3D预览 | A | | Todo |
| #3999 | P2 | project | [矿场][#3994-3][P2] 区域品类热力图Tab — 二维矩阵+空白市场识别 | A | | Todo |
| #4011 | P2 | project | [记录中心][#4004-4][P2] 多实体关联数据模型 | A | | Todo |
| #4016 | P2 | crm | [CRM][#4013-3][P2] 架构蓝图只读页 + 术语数据字典 — 全平台术语统一 | A_weak | | Todo |
| #4025 | P2 | cockpit | [整改][超管驾驶舱][#4020-1] 总览仪表盘 — 按新原型对齐 | EXEMPT | | Todo |
| #4026 | P2 | cockpit | [整改][超管驾驶舱][#4020-2] Claude Office — 按新原型对齐 | EXEMPT | | Todo |
| #4027 | P2 | cockpit | [整改][超管驾驶舱][#4020-3] Token Pool 管理 — 按新原型对齐 | EXEMPT | | Todo |
| #4028 | P2 | cockpit | [整改][超管驾驶舱][#4020-5] 定时任务管理 — 按新原型对齐 | EXEMPT | | Todo |
| #4029 | P2 | cockpit | [整改][超管驾驶舱][#4020-8] GPU 资源监控 — 按新原型对齐 | EXEMPT | | Todo |
| #4030 | P2 | cockpit | [整改][超管驾驶舱][#4020-9] 外部工具管理 — 按新原型对齐 | EXEMPT | | Todo |
| #4031 | P2 | cockpit | [整改][超管驾驶舱][#4020-10] 确认中心 — 按新原型对齐 | EXEMPT | | Todo |
| #4032 | P2 | cockpit | [整改][超管驾驶舱][#4020-11] Issue 看板 — 按新原型对齐 | EXEMPT | | Todo |
| #4013 | P2 | crm | [Master][CRM] 线索/商机架构统一 — 四入口归并 单页架构 | A_weak | | Todo |
| #4043 | P2 | project | [Master][执行管理] 项目执行管理 v2.0 — 多Tab架构 列表页+详情页8T | A_weak | | Todo |
| #4045 | P2 | ptc | [Master][产品门户] 经销商产品展示门户 — 多页架构 目录+详情+备件3页 | A_weak | | Todo |
| #4046 | P2 | rbac | [Master][权限管理] RBAC角色化侧边栏+角色主页 — 多视图架构 5角色Das | A_weak | | Todo |

### Sprint-4 (3个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #1714 | P1 | biz-enablement | [商务赋能-P1] Phase4 [11/13]: 经销报价单生成页面 — 批量选品+折扣 | A | | Todo |
| #2358 | P2 |  | [资金闭环-P0] Phase2 [5/17]: 商机详情页获客成本Tab — 关联报销+ | A | | Todo |
| #2430 | P2 | intelligence-hub | [P2][33/38] 竞品合同到期预测 → 重新招标机会 | A | | Todo |

### Sprint-Backlog (48个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #1468 | P1 | biz-enablement | [商务赋能知识中台][24/28] 安全标准自动合规标注 | A | | Todo |
| #1469 | P1 | biz-enablement | [商务赋能知识中台][23/28] AI文案增强（材质/标准/案例描述自动生成） | A | | Todo |
| #1470 | P1 | biz-enablement | [商务赋能知识中台][21/28] Playbook规则引擎（场景化内容推荐） | A | | Todo |
| #1594 | P1 | budget | [19/32] 借款逾期提醒+工资扣除预警 | A | | Todo |
| #1599 | P1 | budget | [14/32] 采购比价强制校验 | A | | Todo |
| #1613 | P1 | wechat | [14/18][P1] 数据安全分级与访问控制 — L1/L2/L3三级防护 | EXEMPT | | Todo |
| #1614 | P1 | wechat | [13/18][P1] PII自动脱敏服务 — 隐私保护引擎 | EXEMPT | | Todo |
| #1873 | P1 | bidding | [P1][27/38] 分级超时升级机制（48h→72h→5天） | A | | Todo |
| #2215 | P1 | biz-enablement | [商务赋能知识中台][22/28] 引导式PPT组装向导 | A | | Todo |
| #2275 | P1 |  | [错误分析中心-P1][5/6] 驾驶舱首页DORA指标卡片+最近错误滚动条 | A | | Todo |
| #2437 | P1 | bidding | [P1][22/38] 推荐行动计划按阶段自动生成 | A | | Todo |
| #2439 | P1 | intelligence-hub | [P1][19/38] T0/T1/T2竞品自动分级 + 升降级机制 | A | | Todo |
| #2440 | P1 | intelligence-hub | [P1][18/38] 竞品定价数据库 | A | | Todo |
| #2441 | P1 | intelligence-hub | [P1][17/38] 竞品区域热力图 vs 万德区域热力图 | A | | Todo |
| #2527 | P1 | project | [项目组织管理-P1] Phase7 [7/18]: 前端 — 版本历史+审批流程面板 | A | | Todo |
| #2532 | P1 | project | [项目组织管理-P1] Phase12 [12/18]: 前端 — 已读追踪+公告详情 | A | | Todo |
| #2534 | P1 | project | [项目组织管理-P1] Phase14 [14/18]: 前端 — 任务面板增加快速行动项 | A | | Todo |
| #2536 | P1 | project | [项目组织管理-P1] Phase16 [16/18]: 前端 — 阶段推进确认弹窗增强（ | A | | Todo |
| #2617 | P1 |  | [4/4] Issue创建SOP更新 — PageGuide纳入前端Issue模板必填 | EXEMPT | | Todo |
| #1466 | P2 | biz-enablement | [商务赋能知识中台][27/28] 案例相似度推荐 | A | | Todo |
| #1498 | P2 |  | [矿场-Phase4][4/17] 经销商项目情报推送 — 覆盖区域内新匹配项目 | A | | Todo |
| #1573 | P2 | policy | [22/22] 制度智能问答API | A | | Todo |
| #1870 | P2 | intelligence-hub | [P2][31/38] 客户关系图谱（甲方/设计院/代理机构关系网络） | A | | Todo |
| #2217 | P2 | biz-enablement | [商务赋能知识中台][18/28] 设备维护档案页面 | A | | Todo |
| #2218 | P2 | biz-enablement | [商务赋能知识中台][15/28] 标准合规说明导出 | A | | Todo |
| #2219 | P2 | biz-enablement | [商务赋能知识中台][14/28] 标准库管理页面 | A | | Todo |
| #2220 | P2 | biz-enablement | [商务赋能知识中台][10/28] 材质参数一键导出 | A | | Todo |
| #2221 | P2 | biz-enablement | [商务赋能知识中台][9/28] 材质知识库管理页面 | A | | Todo |
| #2222 | P2 | biz-enablement | [商务赋能知识中台][6/28] 案例搜索（1搜索框+6维筛选） | A | | Todo |
| #2223 | P2 | biz-enablement | [商务赋能知识中台][5/28] 照片上传+批量导入 | A | | Todo |
| #2277 | P2 | policy | [21/22] 条款库管理页面 | A | | Todo |
| #2278 | P2 | policy | [20/22] AI制度起草向导页面 | A | | Todo |
| #2288 | P2 | budget | [30/32] 成本复盘报告页面 | A | | Todo |
| #2293 | P2 | budget | [7/32] 保证金台账页面 | A | | Todo |
| #2319 | P2 | intelligence-hub | [P2][35/38] 商务反馈增加"客户提及竞品"字段 | A | | Todo |
| #2389 | P2 | biz-enablement | [商务赋能知识中台][28/28] 季度照片采集提醒+任务推送 | A | | Todo |
| #2390 | P2 | biz-enablement | [商务赋能知识中台][26/28] 照片AI自动标签（CLIP模型） | A | | Todo |
| #2432 | P2 | intelligence-hub | [P2][29/38] 竞品空白区域发现 | A | | Todo |
| #2444 | P2 | bidding | [P0][13/38] keyword_pool新增政策类关键词 | A | | Todo |
| #2445 | P2 | bidding | [P0][12/38] 锁定100个儿童友好城市+50个体育公园重点城市定向监控 | A | | Todo |
| #2447 | P2 | intelligence-hub | [P0][9/38] 商务作战资源包自动生成（概况卡+干系人+经验+行动建议） | A | | Todo |
| #2526 | P2 | project | [项目组织管理-P0] Phase6 [6/18]: 前端 — 文档上传+新版本上传弹窗 | A | | Todo |
| #2537 | P2 | project | [项目组织管理-P2] Phase17 [17/18]: 经验卡片增强 — 关联风险/公告 | A | | Todo |
| #2539 | P2 | project | [项目组织管理-P2] Phase18 [18/18]: 项目通讯录增强 — 外部干系人+ | EXEMPT | | Todo |
| #2585 | P2 | tech-debt | refactor: 合并 wande-ai-api 模块到 wande-ai，消除42个重 | EXEMPT | | Todo |
| #2632 | P2 | h5-mobile | [P0][H5基座 8/8] CLAUDE.md 更新 — H5移动端开发规范 | EXEMPT | | Todo |
| #2639 | P2 | brand-center | [品牌中心·数字人] [7/7] 文档 — 数字人+声音克隆平台选型对比评估 | EXEMPT | | Todo |
| #1487 | P3 |  | [矿场-Phase5][5/10] 跨境客户资格评估 — 8维度评估表+评级计算 | A | | Todo |

### NoSprint (33个)

| Issue | 优先级 | 模块 | 标题 | 类型 | 指派 | 状态 |
|-------|--------|------|------|------|------|------|
| #3545 | P0 | intelligence-hub | [P0追补][#3118-fix] 前端关系网络 Tab 页面（ECharts 配合单位图 | A | | Todo |
| #1845 | P1 |  | [设计模块-P1][10/30] 安全合规检测引擎 — 三标融合规则(EN1176+AST | A | | Todo |
| #2078 | P1 |  | [问题发现-P1] 原因诊断API — AI分析根因+关联Issue | A | | Todo |
| #2306 | P1 | ptc | [设计模块-P1][31] D3 Web设计工作台 — 电池包拖拽+连接点+Three.j | A | | Todo |
| #2317 | P1 | ptc | [产品平台][P0] D3 Web技术确认中心前端 — 胡总在线确认参数页面 | A | | Todo |
| #3377 | P1 | plm | [PLM][1/20][P0] PLM子系统数据库初始化 — 7张核心表建表+索引 | A | | Todo |
| #3378 | P1 | plm | [PLM][2/20][P0] 零件主数据CRUD API — 新建/编辑/查询/版本状态 | A | | Todo |
| #3383 | P1 | plm | [PLM][6/20][P0] BOM成本自动Roll-up API — 多层级递归成本汇 | A | | Todo |
| #3384 | P1 | plm | [PLM][7/20][P0] BOM Where-Used反查API — 零件被哪些BO | A | | Todo |
| #3385 | P1 | plm | [PLM][8/20][P0] ECO变更申请与影响评估API — A/B/C分级路由 + | A | | Todo |
| #3386 | P1 | approval | [PLM][9/20][P0] ECO审批流集成 — 复用审批引擎 + A级三人会签 +  | A | | Todo |
| #3387 | P1 | plm | [PLM][10/20][P0] ECO执行引擎 — 审批通过自动执行零件版本更新+BOM | A | | Todo |
| #3388 | P1 | plm | [PLM][11/20][P1] 超级BOM规则引擎 — N选1/数量型/参数化三种规则  | A | | Todo |
| #3389 | P1 | plm | [PLM][12/20][P1] 超级BOM→实例EBOM解析API — 选配结果→具体B | A | | Todo |
| #3390 | P1 | plm | [PLM][13/20][P1] D3参数化→PLM BOM桥接 — D3输出自动创建EB | A | | Todo |
| #3391 | P1 | plm | [PLM][14/20][P1] 产品配置器后端API — 销售自助选配 + 超级BOM规 | A | | Todo |
| #3394 | P1 | plm | [PLM][17/20][P1] 零件主数据管理页面 | A | | Todo |
| #3395 | P1 | plm | [PLM][18/20][P1] BOM管理与版本对比页面 | A | | Todo |
| #3396 | P1 | plm | [PLM][19/20][P1] ECO变更管理页面 | A | | Todo |
| #3397 | P1 | plm | [PLM][20/20][P1] 产品配置器+报价页面 | A | | Todo |
| #3557 | P1 |  | 🟡 [E2E回归] 前端E2E测试登录会话失效 - 大量页面重定向到登录页 | EXEMPT | | Todo |
| #3106 | P2 | crm | 发货管理（国贸专用） — 装箱单+报关+海运空运跟踪 | A | | Todo |
| #3107 | P2 | crm | 出口单据管理 — CI/PL/BL/CO/FormE自动生成+归档 | EXEMPT | | Todo |
| #3109 | P2 | crm | 客户信用额度管理 — 授信+在途应收+超额预警（经销+国贸通用） | A | | Todo |
| #3111 | P2 | crm | 汇率管理+利润自动计算 — 报价锁汇+收款汇率+损益（国贸专用） | A | | Todo |
| #3558 | P2 |  | 🟡 [E2E回归] API请求超时 - 24个测试失败 | EXEMPT | | Todo |
| #1906 | P2 | ptc | [D3-Web][P0] 技术标准管理中心 — 胡总统一维护+全局生效+变更审核+历史追溯 | A | | Todo |
| #1923 | P2 |  | [D3-v2.0][P1][Phase4-3/4] AI合规报告自动生成 — EN/GB/ | A | | Todo |
| #1926 | P2 | ptc | [D3-v2.0][P1][Phase3-3/3] D3成果Web预览 — 3D模型+BO | A | | Todo |
| #3562 | P2 | tech-debt | [#2239-fix] 详情弹窗追补 | EXEMPT | | Todo |
| #3886 | P2 |  | [测试] 代码质量 Hook 体系完整路径验证 — pre-commit / pre-pu | EXEMPT | | Todo |
| #3994 | P2 | project | [Master][矿场] 全球项目矿场 — 10Tab架构（执行6+洞察4） | A_weak | | Todo |
| #4004 | P2 | project | [Master][业务运营] 销售记录体系 — 记录中心多Tab(4Tab)+老板周报单页 | A_weak | | Todo |


## 本轮巡检进度（04-24 02:40）

| kimi | Issue | 状态 | 进度 | 备注 |
|------|-------|------|------|------|
| kimi5 | #4011 | 🔄 Working | 31% | T1-T2 Flyway完成，纯后端最快完成预期 |
| kimi2 | #4016 | 🔄 Working | 33% | T1 Backend开发中 |
| kimi1 | #4015 | 🔄 Working | 31% | API测试阶段 |
| kimi3 | #2307 | 🔄 Working | 进前端 | T7 Inpaint页面开发 |
| kimi6 | #1920 | ⚠️ Blocked | 等待 | PR #34 merge冲突，CI全绿✅ |


## 新增派遣（2026-04-24 07:08）— 派遣异常修复后的新一轮派遣

| 指派目录 | Issue | 模块 | 优先级 | 说明 | 状态 | 进展 |
|------|-------|------|--------|------|------|------|
| kimi1 | #1468 | backend | P1 | 安全标准自动合规标注 | ✅ PR #4166 | 21文件+1820行，JUnit 13/13✅，CI运行中 |
| kimi2 | #1469 | backend | P1 | AI文案增强（材质/标准/案例描述自动生成） | 🔄 开发中 | 42% 进度，单测编写中 |
| kimi3 | #1470 | backend | P1 | Playbook规则引擎（场景化内容推荐） | 🔄 开发中 | 28% 进度，基础CRUD中 |
| kimi5 | #1845 | design-ai | P1 | 安全合规检测引擎 — 三标融合规则(EN1176+ASTM+GB) | 🔄 开发中 | 36% 进度，基础CRUD中 |
| kimi6 | #1714 | biz-enablement | P1 | 经销报价单生成页面 — 批量选品+折扣配置+报价单预览 | 🔄 开发中 | 29% 进度，E2E测试调优中 |

### 派遣背景
- 原派遣Issue #4029-4032已全部完成（2026-04-23 21:xx）但CC仍在执行（重复工作）
- 立即停止异常派遣，释放slot
- 选择备选队列P1高优先级Issue进行新派遣
- 预期工作周期：2-3小时

| 04-24 | kimi1 | #2358 | finance | medium | In Progress | 商机详情页获客成本Tab（备选队列#1指派）|

## 派遣进度（2026-04-24 13:10）— 全部完成，新一轮巡检

### 前轮派遣状态（04-24 07:08）
| kimi | Issue | 模块 | 状态 |
|------|-------|------|------|
| kimi1 | ~~#1468~~ | backend | ~~Done~~ — PR #4166 merged |
| kimi2 | ~~#1469~~ | backend | ~~Done~~ — PR merged |
| kimi3 | ~~#1470~~ | backend | ~~Done~~ — PR merged |
| kimi5 | ~~#1845~~ | design-ai | ~~Done~~ — PR #4178 merged |
| kimi6 | ~~#1714~~ | biz-enablement | ~~Done~~ — PR #4167 merged |

**状态**：全部5个CC已完成，15/15槽位可用。

| 04-26 | kimi1 | ~~#2704~~ | frontend | medium | ~~Done~~ | 中标概率评分可视化看板 — PR#4248 merged ✅ |
| 04-27 | kimi1 | ~~#2437~~ | backend | medium | ~~释放→Todo~~ | 推荐行动计划按阶段自动生成 — CC超时释放，需重新指派 |
| 04-26 | kimi2 | ~~#3172~~ | backend | medium | ~~Done~~ | 质量管理表单组5模板 — PR#3911已于04-19 merged，误恢复 |
| 04-27 | kimi2 | ~~#2275~~ | backend | medium | ~~释放→Todo~~ | 驾驶舱DORA指标卡片+最近错误滚动条 — CC超时释放，需重新指派 |

### 当前运行（04-27 12:57）
| kimi | Issue | 模块 | 优先级 | 内容 | PR状态 |
|------|-------|------|--------|------|--------|
| kimi1 | #2441 | frontend | P1 | 竞品区域热力图vs万德区域热力图（建议#86） | 编码中 |
| kimi2 | #2306 | fullstack | P1 | D3 Web设计工作台（建议#85） | 编码中 |

**2/2 并发在线。**

### PR进度总览（04-26 22:05）
| kimi | Issue | PR | 状态 | 备注 |
|------|-------|----|----|------|
| ~~kimi5~~ | ~~#1450~~ | #4239 | ✅ merged | 10:02:34 UTC |
| ~~kimi3~~ | ~~#1452~~ | #4240 | ✅ merged | 10:11:30 UTC |
| ~~kimi2~~ | ~~#2756~~ | #4241 | ✅ merged | 11:39:30 UTC |
| ~~kimi7~~ | ~~#2271~~ | #4242 | ✅ merged | 12:31:50 UTC |
| ~~kimi4~~ | ~~#2264~~ | #4243 | ✅ merged | 12:40:45 UTC |
| ~~kimi1~~ | ~~#2265~~ | #4244 | ✅ merged | 13:52:23 UTC |
| ~~kimi5~~ | ~~#2268~~ | #4245 | ✅ merged | 14:01:36 UTC |
| ~~kimi6~~ | ~~#2712~~ | #4247 | ✅ merged | 15:02:44 UTC |
| ~~kimi1~~ | ~~#2704~~ | #4248 | ✅ merged | 16:11:30 UTC |
| ~~kimi2~~ | ~~#3172~~ | #3911 | ✅ merged | 04-19误恢复，确认Done |
| ~~kimi1~~ | ~~#2437~~ | #4249 | ✅ merged | 02:11:49 UTC |
| ~~kimi2~~ | ~~#2275~~ | #4250 | ✅ merged | 02:44:37 UTC |
| ~~kimi1~~ | ~~#2440~~ | #4251 | ✅ merged | 03:48:01 UTC |
| ~~kimi2~~ | ~~#1598~~ | #4252 | ✅ merged | 04:00:18 UTC |
| ~~kimi2~~ | ~~#2439~~ | #4253 | ✅ merged | 04:43:25 UTC |
| ~~kimi1~~ | ~~#1603~~ | #4254 | ✅ merged | 04:55:43 UTC |
