# Sprint-2 排程计划

> 更新时间：2026-05-08（排程经理第1126轮；12个MERGED移入非活跃；补入13个新候选；累计PR #4509-#4525；剩余可用Issue不足时从Plan补位）
> 来源：v5.1 §5.6 全量对账 — 326个已合规Issue一次性排程
> 规则：EXEMPT 33个→Todo / A档128个→按Sprint Todo / C_frozen 165个→保持Plan(needs-prototype)
> Master Issue：#3994已关闭(全子Issue CLOSED)、#4004已关闭(全子Issue CLOSED)

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
> 更新时间：2026-05-08（排程经理第1126轮；12个MERGED清理；补入13个新候选；13个Plan→Todo）
> ⚠️ needs-prototype冻结、Master Issue不出现在本表；指派前请用 `gh issue view #N` 确认标签
> 注意：本表与GitHub Issue编号一致，无需转换

| # | Issue | 优先级 | 模块 | 说明 | 启动 |
|---|-------|--------|------|------|------|
| ~~1~~ | ~~#2528~~ | P2 | backend | 公告板DB建表 — project_announcements（Master #4263 Phase8） | ✅ PR #4535 MERGED 04:35 |
| ~~2~~ | ~~#2529~~ | P2 | backend | 公告板Service — CRUD+@提及解析+企微通知（Master #4263 Phase9） | |
| ~~3~~ | ~~#2531~~ | P2 | frontend | 公告板前端 — 项目详情页公告板Tab（Master #4263 Phase11） | |
| ~~4~~ | ~~#2633~~ | P1 | backend | 数字人DB建表 — brand_avatar/voice_clone（Master #4091） | ✅ PR #4532 MERGED |
| ~~5~~ | ~~#2634~~ | P1 | backend | 数字人CRUD API — 数字分身+声音克隆+视频（Master #4091） | ✅ PR #4533 MERGED |
| ~~6~~ | ~~#2643~~ | P1 | backend | 员工代言内容池 + 分享追踪API（Master #4091 员工代言 [1/2]） | ✅ PR #4534 MERGED |
| ~~7~~ | ~~#2653~~ | P1 | backend | 节日日历DB + 海报模板管理API（Master #4091 内容自动化 [1/5]） | ✅ PR #4536 MERGED |
| ~~8~~ | ~~#2661~~ | P1 | backend | 配色方案导出 + 总部需求表自动生成（色卡配色器 [3/4]） | ✅ PR #4531 MERGED |
| ~~9~~ | ~~#3153~~ | P1 | approval | 自动审批规则引擎 — 预审条件+预清除回退（审批引擎增强 [5/8]） | ✅ PR #4537 OPEN |
| 10 | ~~#3154~~ | P1 | approval | 智能路由引擎 — 并行/串行/混合路径+动态审批人（审批引擎增强 [6/8]） | kimi4 CC工作中 |
| 11 | #2371 | P1 | fullstack | 竞品技术浏览器 — 产品对标/参数查询/CAD下载（Master #4065 Phase7） | |
| 12 | #2691 | P1 | fullstack | 竞品产品对比矩阵（Master #4065 行业信息 [6/10]） | |
| ~~13~~ | ~~#2741~~ | P1 | fullstack | 自定义报告模板与导出（Master #4065 分发 [6/8]） | ✅ PR #4539 MERGED 04:27 |
| ~~14~~ | ~~#2336~~ | P1 | sample | D3样品一键生成页面（样品管理 Phase14 [14/16]） | ✅ PR #4541 MERGED |
| 15 | #2342 | P1 | frontend | 方案模板管理前端 — 模板库浏览+上传+矩阵（方案引擎 [7/22]） | |
| 16 | #2364 | P1 | approval | 菜单权限SQL + 审批中心菜单注册（审批引擎 Phase10 [10/10]） | |
| 17 | #2365 | P1 | approval | SLA规则配置页 + 审批统计看板（审批引擎 Phase9 [9/10]） | |
| 18 | #2332 | P1 | frontend | 采集工具使用指南页（工具中心 [7/10]） | |
| 19 | ~~#2334~~ | P1 | frontend | 设计工具下载页 D3/GH+AI渲染（工具中心 [5/10]） | ✅ PR #4540 OPEN |
| 20 | #2360 | P1 | frontend | 设计变更通知+确认页面（项目中心 Phase11 [11/12]） | |

> ⚠️ 指派前请用 `gh issue view #N --repo WnadeyaowuOraganization/wande-play --json body` 确认依赖已CLOSED再指派

### 非活跃记录（冻结/已指派/阻塞 — 不出现在主表）

| Issue | 原因 | 当前状态 |
|-------|------|---------|
| #2420 / #2422 / #2425 / #2424 / #2165 | ⛔ needs-prototype 冻结 | pause |
| #2476 | ⛔ 非CC任务（需人工验证AI建模结果） | pause |
| #2486 / #2487 | ⛔ 非CC任务（LoRA训练需GPU，m7i CPU-only） | pause |
| #2488 | ⛔ 非CC任务（ComfyUI需GPU+依赖#2486/#2487） | pause |
| #2329 | ⏸️ 实际 pause（非已指派） | pause |
| #2330 | ✅ PR #4507 MERGED | Done |
| #2332 | ✅ PR #4501 MERGED | Done |
| #2333 | ✅ PR #4502 MERGED | Done |
| #2334 | ✅ PR #4499 MERGED | Done |
| #2337 | ✅ PR #4506 MERGED | Done |
| #2338 | ✅ PR #4505 MERGED | Done |
| #2342 | ✅ PR #4500 MERGED | Done |
| #2343 | ✅ PR #4503 MERGED | Done |
| #1887 | ✅ PR #4513 MERGED | Done |
| #1941 | ✅ PR #4512 MERGED | Done |
| #2013 | ✅ PR #4510 MERGED | Done |
| #2034 | ✅ PR #4514 MERGED | Done |
| #2169 | ✅ PR #4076 MERGED | Done |
| #2285 | ✅ PR #4525 MERGED | Done |
| #2286 | 已指派 kimi4 | In Progress |
| #2335 | ✅ PR 已合并 | Done |
| #2336 | ⏳ 依赖后端 Phase 未完成 | Todo（阻塞） |
| #2364 | ✅ PR #4498 MERGED | Done |
| #2370 | ✅ PR #4520 MERGED | Done |
| #2473 | 已指派 kimi6 | In Progress (PR #4504 OPEN) |
| #2533 | ✅ PR #4509 MERGED | Done |
| #2535 | ✅ PR #4515 MERGED | Done |
| #2659 | ✅ PR #4519 MERGED | Done |
| #2666 | ✅ PR #4517 MERGED | Done |
| #2670 | 已指派 kimi1 | In Progress |
| #2744 | ✅ PR #4524 MERGED | Done |
| #2746 | 已指派 kimi6 | In Progress |
| #3162 | ✅ PR #4508 MERGED | Done |
| #3163 | ✅ PR 已合并 | Done |
| #3164 | ✅ PR #4538 MERGED | Done |
| #3181 | kimi3 CC中 | In Progress |
| #2336 | kimi7 CC中 | In Progress |
| #2334 | kimi8 CC中 | In Progress |
| #2115 | kimi1 CC中 | In Progress |
| #3194 | 已指派 kimi3 | In Progress |
| #3209 | ✅ PR #4518 MERGED | Done |
| #3210 | ✅ PR #4522 MERGED | Done |
| #2488 | ✅ PR #4511 MERGED | Done |
| #3132 | ✅ PR #3917+#4508 MERGED | Done |
| #1451 | ⚠️ 需配前端（body 写"前端待创建"） | Done |
| #2259 | ❌ 依赖缺失（backend#929 不存在） | Done |
| #2260 | ❌ 依赖缺失（backend#926-928 不存在） | Done |

## 指派历史

| 日期 | kimi | Issue | 模块 | effort | 状态 | 备注 |
|------|------|-------|------|--------|------|------|
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
| 05-06 | kimi1 | #2475 | backend | **high** | In Progress | D3-AI G7e AI建模后端 — Qwen驱动GH脚本生成API |
| 05-06 | kimi2 | #2438 | backend | **high** | In Progress | 投标人名单提取 → 发现同场竞技者 |
| 05-06 | kimi3 | #2436 | pipeline | **high** | In Progress | 财政预算信号采集 → 六层信号源第三层 |
| 05-06 | kimi4 | #2434 | backend | **high** | In Progress | 信号链自动串联 → 同项目不同阶段信号关联 |

**当前4个CC在线运行中（05-06研发经理指派）：**
- kimi1 #2475: D3-AI G7e AI建模后端（backend，**high**，刚启动）
- kimi2 #2438: 投标人名单提取（backend，**high**，刚启动）
- kimi3 #2436: 财政预算信号采集（pipeline，**high**，刚启动）
- kimi4 #2434: 信号链自动串联（backend，**high**，刚启动）
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
| #2132 ✅merged/kimi1 | #4015 | 🔄 Working | 31% | API测试阶段 |
| kimi3 | #2307 | 🔄 Working | 进前端 | T7 Inpaint页面开发 |
| kimi6 | #1920 | ⚠️ Blocked | 等待 | PR #34 merge冲突，CI全绿✅ |


## 新增派遣（2026-04-24 07:08）— 派遣异常修复后的新一轮派遣

| 指派目录 | Issue | 模块 | 优先级 | 说明 | 状态 | 进展 |
|------|-------|------|--------|------|------|------|
| #2132 ✅merged/kimi1 | #1468 | backend | P1 | 安全标准自动合规标注 | ✅ PR #4166 | 21文件+1820行，JUnit 13/13✅，CI运行中 |
| kimi2 | #1469 | backend | P1 | AI文案增强（材质/标准/案例描述自动生成） | 🔄 开发中 | 42% 进度，单测编写中 |
| kimi3 | #1470 | backend | P1 | Playbook规则引擎（场景化内容推荐） | 🔄 开发中 | 28% 进度，基础CRUD中 |
| kimi5 | #1845 | design-ai | P1 | 安全合规检测引擎 — 三标融合规则(EN1176+ASTM+GB) | 🔄 开发中 | 36% 进度，基础CRUD中 |
| kimi6 | #1714 | biz-enablement | P1 | 经销报价单生成页面 — 批量选品+折扣配置+报价单预览 | 🔄 开发中 | 29% 进度，E2E测试调优中 |

### 派遣背景
- 原派遣Issue #4029-4032已全部完成（2026-04-23 21:xx）但CC仍在执行（重复工作）
- 立即停止异常派遣，释放slot
- 选择备选队列P1高优先级Issue进行新派遣
- 预期工作周期：2-3小时

| 04-24 | #2132 ✅merged/kimi1 | #2358 | finance | medium | In Progress | 商机详情页获客成本Tab（备选队列#1指派）|

## 派遣进度（2026-04-24 13:10）— 全部完成，新一轮巡检

### 前轮派遣状态（04-24 07:08）
| kimi | Issue | 模块 | 状态 |
|------|-------|------|------|
| #2132 ✅merged/kimi1 | ~~#1468~~ | backend | ~~Done~~ — PR #4166 merged |
| kimi2 | ~~#1469~~ | backend | ~~Done~~ — PR merged |
| kimi3 | ~~#1470~~ | backend | ~~Done~~ — PR merged |
| kimi5 | ~~#1845~~ | design-ai | ~~Done~~ — PR #4178 merged |
| kimi6 | ~~#1714~~ | biz-enablement | ~~Done~~ — PR #4167 merged |

**状态**：全部5个CC已完成，15/15槽位可用。

| 04-26 | #2132 ✅merged/kimi1 | ~~#2704~~ | frontend | medium | ~~Done~~ | 中标概率评分可视化看板 — PR#4248 merged ✅ |
| 04-27 | #2132 ✅merged/kimi1 | ~~#2437~~ | backend | medium | ~~释放→Todo~~ | 推荐行动计划按阶段自动生成 — CC超时释放，需重新指派 |
| 04-26 | kimi2 | ~~#3172~~ | backend | medium | ~~Done~~ | 质量管理表单组5模板 — PR#3911已于04-19 merged，误恢复 |
| 04-27 | kimi2 | ~~#2275~~ | backend | medium | ~~释放→Todo~~ | 驾驶舱DORA指标卡片+最近错误滚动条 — CC超时释放，需重新指派 |
| 04-28 | kimi2 | ~~#1898~~ | backend | **high** | ~~Done~~ | 发货防错系统 — PR #4300 merged |
| 04-28 | kimi2 | ~~#1900~~ | backend | **high** | ~~Done~~ | 采购下料单自动生成 — PR #4303 submitted |
| 04-28 | #2132 ✅merged/kimi1 | ~~#1911~~ | backend | **high** | ~~Done~~ | AI电池包开发助手 — PR #4301 merged |
| 04-28 | #2132 ✅merged/kimi1 | ~~#1933~~ | backend | **P0** | ~~Done~~ | 螺旋滑梯电池包 — PR #4302 merged |
| 04-28 | #2132 ✅merged/kimi1 | #1932 | backend | P0 | In Progress | 秋千/吊环电池包 — 独立件+A型架(Phase2-3/6) |
| 04-28 | kimi4 | #4176 | frontend | P1 | In Progress | 🔧 Quick-Fix 发票页显示（/project-center/execution/invoice） |
| 04-28 | kimi2 | ~~#4201~~ | backend | P1 | ~~Done~~ | 🔧 Quick-Fix 时间线加载失败 — PR #4304 merged |
| 04-28 | kimi2 | ~~#4200~~ | fullstack | P1 | ~~Done~~ | 🔧 Quick-Fix 矿场列表报错 — PR #4306 merged |
| 04-28 | kimi3 | ~~#1930~~ | fullstack | **P0** | ~~Done~~ | 攀爬网/爬梯电池包 — PR #4308 submitted |
| 04-28 | kimi3 | ~~#4173~~ | frontend | P2 | ~~Done~~ | 🔧 Quick-Fix 利润率列表 — PR #4310 merged |
| 04-28 | kimi3 | ~~#1929~~ | frontend | P0 | ~~Done~~ | GH插件.gha安装包 — PR #4312 merged |
| 04-28 | kimi3 | #1850 | design-ai | P1 | In Progress | Agent自学习闭环+效果度量 — 纠正记录/失败模式/模板积累 |
| 04-28 | #2132 ✅merged/kimi1 | ~~#1932~~ | backend | **P0** | ~~Done~~ | 秋千/吊环电池包 — PR #4305 submitted |
| 04-28 | #2132 ✅merged/kimi1 | ~~#4172~~ | backend | P1 | ~~Done~~ | 🔧 Quick-Fix Prompt管理 — PR #4307 submitted |
| 04-28 | #2132 ✅merged/kimi1 | ~~#4175~~ | backend | P2 | ~~Done~~ | 🔧 Quick-Fix issue-board 404 — PR #4313 merged |
| 04-28 | #2132 ✅merged/kimi1 | #1851 | backend | P1 | In Progress | 审核与自动部署流程 — 邵鹏提交→吴耀审核→一键部署 |
| 04-28 | kimi2 | ~~#4174~~ | backend | P2 | ~~Done~~ | 🔧 Quick-Fix GPU监控接口404 — PR #4309 merged |
| 04-28 | kimi2 | #1907 | backend | P0 | In Progress | 滚塑滑桶专项 — φ800模具+分节规则+透明桶+三标准合规 |
| 04-28 | kimi4 | ~~#4176~~ | frontend | P1 | ~~Done~~ | 🔧 Quick-Fix 发票页显示 — PR #4311 merged |
| 04-29 | kimi4 | #1902 | backend | P1 | In Progress | 历史项目结构化索引 — S3生产模型参数提取+设计师搜索 |
| 04-29 | kimi4 | ~~#1902~~ | backend | P1 | ~~Done~~ | 历史项目结构化索引 — PR #4331 merged |
| 04-29 | kimi4 | #1866 | backend | P1 | In Progress | GH AI插件生态补充评估 — Smarthopper+OKIE-5 Ollama本地模型 |
| 04-29 | kimi4 | ~~#1866~~ | backend | P1 | ~~Done~~ | GH AI插件生态补充评估 — PR #4332 merged |
| 04-29 | kimi4 | ~~#4333~~ | frontend | P2 | ~~Done~~ | E2E回归 /business/crm — PR #4335 merged |
| 04-29 | kimi4 | ~~#4334~~ | frontend | P2 | ~~Done~~ | E2E回归 /business/tender/opportunity 404 — PR #4336 merged |
| 04-29 | #2132 ✅merged/kimi1 | ~~#1930~~ | fullstack | P0 | ~~Done~~ | 攀爬网/爬梯电池包 — PR #4308 merged |
| 04-29 | #2132 ✅merged/kimi1 | ~~#2218~~ | frontend | P2 | ~~暂停~~ | 商务赋能标准合规说明导出 — 缺原型，等待补齐 |

| 04-29 | #2132 ✅merged/kimi1 | ~~#1955~~ | backend | P1 | ~~Done~~ | 方案引擎AI文案知识增强 — PR #4339 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#2035~~ | hr | P1 | ~~Done~~ | 人事管理数据库建表 — PR #4372 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#1975~~ | backend | P1 | ~~Done~~ | PPT模板解析引擎 — PR #4374 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#1966~~ | backend | P1 | ~~Done~~ | PPT样式一致性检查+一键修复 — PR #4375 merged |
| 04-30 | kimi5 | ~~#3212~~ | fullstack | P1 | ~~Done~~ | 设备级进度追踪(BOM×工艺步骤) — PR #4366 merged |
| 04-30 | kimi2 | ~~#4093~~ | fullstack | P1 | ~~Done~~ | Quick-Fix /profit-alert — PR #4371 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#1957~~ | frontend | P1 | ~~Done~~ | 方案引擎PPT插件 — PR #4341 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#1968~~ | backend | P1 | ~~Done~~ | PPT一键套模板 — PR #4378 merged |
| 04-30 | kimi5 | ~~#1958~~ | backend | P1 | ~~Done~~ | PPT图片美化工具 — PR #4379 merged |
| 04-30 | kimi2 | ~~#2032~~ | backend | P1 | ~~Done~~ | 色卡材料Controller API — PR #4382 merged |
| 04-30 | #2132 ✅merged/kimi1 | ~~#1967~~ | frontend | P1 | ~~Done~~ | PPT素材智能推荐+一键插入 — PR #4381 merged |
| 04-30 | kimi5 | ~~#2390~~ | biz-enablement | P2 | ~~Done~~ | 照片AI自动标签(CLIP) — PR #4384 merged |
| 04-30 | kimi5 | ~~#2389~~ | biz-enablement | P2 | ~~Done~~ | 季度照片采集提醒+任务推送 — PR #4383 merged |
| 04-30 | kimi5 | ~~#2278~~ | policy | P2 | ~~Done~~ | AI制度起草向导页面 Phase20 — PR #4385 merged |
| 04-30 | kimi5 | ~~#2585~~ | backend | P2 | ~~Done~~ | 合并wande-ai-api到wande-ai消除42个重复类 — PR #4387 merged，Issue自动关闭 |
| 04-30 | #2132 ✅merged/kimi1 | ~~#2220~~ | biz-enablement | P2 | ~~Done~~ | 材质参数一键导出（Word/PDF）— PR #4386 merged，Issue自动关闭 |
| 04-30 | kimi2 | ~~#3208~~ | backend | P1 | ~~Done~~ | 总控预算增强[1/10] — budget_zone表+BudgetItem增加zone_id — PR #4392 merged |
| 05-01 | kimi2 | ~~#3188~~ | fullstack | P1 | ~~Done~~ | 回款资料[4/7] 企业信息库 — PR #4393 merged，Issue自动关闭 |
| 05-01 | #2132 ✅merged/kimi1 | ~~#2737~~ | backend | P1 | ~~Done~~ | 商战情报中台·分发[2/8] 企微交互式查询指令 — PR #4394 merged，Issue自动关闭 |
| 05-01 | #2132 ✅merged/kimi1 | ~~#1978~~ | backend | P1 | ~~Done~~ | 方案引擎DB设计 — 方案模板引擎3张表 — PR #4395 merged，Issue自动关闭 |
| 05-01 | #2132 ✅merged/kimi1 | ~~#1974~~ | pipeline | P1 | ~~Done~~ | 方案引擎DB设计 — 素材库3张表 — PR #4396 merged，Issue自动关闭 |
| 05-01 | #2132 ✅merged/kimi1 | ~~#1959~~ | backend | P1 | ~~Done~~ | PPT插件：文字美化工具 — 文字特效+数字突出+标题样式 — PR #4400 merged，Issue已关闭 |
| 05-01 | kimi2 | ~~#1960~~ | backend | P1 | ~~Done~~ | PPT插件AI排版工具箱 — 7个功能点 — PR #4401 merged |
| 05-01 | kimi3 | ~~#2738~~ | backend | P1 | ~~Done~~ | 商战情报中台·分发[3/8] 邮件订阅与定时报告 — PR #4390 merged，Issue自动关闭 |
| 05-01 | kimi3 | ~~#1969~~ | backend | P1 | ~~Done~~ | 方案引擎COM Add-in核心 — PR #4397 merged，Issue自动关闭 |
| 05-01 | kimi2 | ~~#1961~~ | backend | P1 | ~~Done~~ | 方案引擎AI排版引擎后端API — PR #4398 merged，Issue自动关闭 |
| 04-30 | kimi2 | ~~#1966~~ | backend | P1 | ~~Done~~ | PPT插件样式一致性检查+一键修复 — PR #4375 merged，Issue自动关闭 |
| 05-01 | kimi3 | ~~#1965~~ | backend | P2 | ~~Done~~ | 方案引擎PowerPoint加载项集成测试 — PR #4399 merged，Issue自动关闭 |
| 05-01 | kimi3 | ~~#1970~~ | backend | P0 | ~~Done~~ | PPT插件后端API — auth/模板/素材/生成/替换 6个接口 — PR #4402 merged |
| 05-01 | kimi5 | #3570 | frontend | P1 | In Progress | 关系网络Tab组件测试与截图验证（#3545-followup） |
| 04-30 | #2132 ✅merged/kimi1 | ~~#4094~~ | frontend | P2 | ~~关闭~~ | 菜单配置指向不存在的组件 — 历史提交9b0612b96已修复，Issue直接关闭 |
| 04-30 | #2132 ✅merged/kimi1 | ~~#4060~~ | fullstack | P2 | ~~Done~~ | Quick-Fix — finops成本看板mock数据+Controller缺/api前缀 — PR #4389 merged |
| 04-30 | kimi3 | ~~#4095~~ | fullstack | P1 | ~~Done~~ | Quick-Fix /contacts通讯录 — PR #4370 merged |
| 04-30 | kimi3 | ~~#3185~~ | frontend | P0 | ~~Done~~ | 全过程资料[1/13] 全阶段资料完成度看板 — PR#4087已于04-22合并，Issue确认关闭 |
| 05-01 | kimi3 | ~~#2162~~ | backend | medium | **Done** | AI文案生成 — 区位分析/设计理念/活动策划 — PR #4404 merged |
| 05-01 | kimi2 | ~~#2141~~ | backend | P1 | **Done** | 素材批量迁移工具 — S3/NAS/PPT拆页+AI自动打标签 — PR #4405 merged，Issue手动关闭 |
| 05-01 | #2132 ✅merged/kimi1 | ~~#1973~~ | pipeline | P1 | **Done** | 素材自动分类+AI标签引擎 — S3设计文件批量处理 — PR #4403 merged，Issue自动关闭 |
| 05-01 | kimi5 | ~~#3570~~ | frontend | P1 | **Done** | 关系网络Tab组件测试与截图验证 — PR #4388 手动merged（E2E队列阻塞100+min），Issue手动关闭 |
| 05-01 | kimi4 | ~~#4124~~ | fullstack | P1 | **Done** | 国贸专属页 — 壳架构+5Tab容器+菜单入口 — PR #4376 merged（10:02 UTC），Issue #4124 CLOSED |
| 05-01 | kimi2 | ~~#2126~~ | fullstack | P1 | **Done** | 经销商发现种子数据+方法论后端 — PR #4407 merged（12:41 UTC），Issue #2126 CLOSED |
| 05-01 | #2132 ✅merged/kimi1 | ~~#2163~~ | backend | P1 | **Done** | 素材库API+RBAC权限管理 — PR #4408 MERGED（16:19 UTC），Issue #2163 CLOSED |
| 05-01 | kimi2 | ~~#2199~~ | backend | P1 | **Done** | LinkedIn API发布集成 — PR #4411 MERGED（15:42 UTC），Issue #2199 CLOSED |
| 05-01 | kimi3 | ~~#2031~~ | backend | P1 | **Done** | 色卡材料审批流程（#2032已CLOSED） — PR #4406 MERGED，Issue #2031 CLOSED |
| 05-01 | kimi4 | ~~#2037~~ | backend | P1 | **Done** | D3-翻新模式（改造/翻新模式） — PR #4409 MERGED（13:59:15 UTC） |
| 05-01 | kimi2 | ~~#2316~~ | frontend | P1 | **Done** | D3 Web产品目录浏览器 — PR #4414 MERGED（18:10 UTC），Issue #2316 CLOSED |
| 05-01 | kimi4 | #2201 | backend | P1 | In Progress | 角色权限系统 — 4级角色 — PR #4412 MERGEABLE（CI等待中） |
| 05-01 | kimi5 | #2045 | backend | P1 | In Progress | AI生成Phase7方案配图自动生成 — PR #4410 MERGEABLE（冲突已解决） |
| 05-01 | kimi3 | ~~#2312~~ | frontend | P1 | **Done** | 完整方案流程Step1 — PR #4413 MERGED（19:12 UTC），Issue #2312 CLOSED |
| 05-02 | kimi3 | ~~#1760~~ | frontend | P2 | **Done** | 经销模式前端适配 — 项目详情+经销商结算对账 — PR #4418 MERGED（11:36 UTC） |
| 05-02 | kimi2 | ~~#1682~~ | backend | P2 | **Done** | 新增图像生成API服务 — PR #4417 MERGED（19:49 UTC），Issue #1682 转 Done |
| 05-02 | kimi5 | ~~#2045~~ | backend | P1 | **Done** | AI生成Phase7方案配图自动生成 — PR #4410 MERGED（20:32 UTC），Issue #2045 转 Done |
| 05-02 | kimi5 | ~~#2044~~ | backend | P2 | **Done** | 竞品情报数据库表创建 — PR #4420 MERGED（22:52 UTC），Issue #2044 转 Done |
| 05-02 | kimi2 | ~~#1826~~ | brand | P2 | **Done** | 新增导航入口+内容管理列表页 — PR #4419 MERGED（23:23 UTC），Issue #1826 转 Done |
| 05-02 | kimi4 | ~~#2051~~ | frontend | P1 | **Done** | D3 L4安装图自动化 — PR #4416 MERGED（00:49 UTC），quality-gate checkbox拦截已修复，Issue #2051 转 Done |
| 05-02 | kimi4 | ~~#1730~~ | frontend | — | — | #1730切换→#1689（新Issue分配） |
| 05-02 | kimi4 | ~~#1689~~ | backend | — | — | #1689切换→#1679（新Issue分配） |
| 05-02 | kimi2 | ~~#1784~~ | backend | — | — | #1784切换→#1665（新Issue分配） |
| 05-02 | kimi4 | ~~#1679~~ | backend | — | — | #1679切换→#1659（新Issue分配） |
| 05-02 | kimi2 | ~~#1665~~ | backend | — | — | #1665切换→#1485（新Issue分配） |
| 05-02 | kimi4 | ~~#1659~~ | backend | — | — | #1659切换→#1495（新Issue分配） |
| 05-02 | #2132 ✅merged/kimi1 | ~~#1496~~ | backend | P2 | **Done** | NBO行动推荐生成 — Today's Top 3行动 — PR #4431 MERGED（12:23 UTC） |
| 05-02 | kimi2 | ~~#1497~~ | backend | P2 | **Done** | NBO评分引擎 — 项目适配度×意图×赢率综合评分 — PR #4434 MERGED ✅ |
| 05-02 | kimi3 | ~~#1538~~ | budget | P2 | **Done** | D3造价回填接口 — D3设计完成后自动写入设备科目预算 — PR #4432 MERGED ✅ |
| 05-02 | kimi5 | ~~#1590~~ | budget | P2 | **Done** | 项目成本复盘报告自动生成 — PR #4428 MERGED ✅ |
| 05-04 | kimi3 | ~~#1539~~ | budget | P2 | **Done** | 历史基准自动积累 — PR #4451 MERGED ✅ |
| 05-04 | kimi2 | ~~#1963~~ | backend | P2 | **Done** | Rhino插件对接API — PR #4425 MERGED ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#2201~~ | brand | P1 | **Done** | 品牌中心角色权限系统 — PR #4412 MERGED ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#1818~~ | brand | P2 | **Done** | 平台定制发布 — PR #4440 MERGED ✅ |
| 05-04 | kimi4 | ~~#1880~~ | asset-library | P2 | **Done** | 素材库-中标状态变更 — PR #4445 MERGED ✅ |
| 05-04 | kimi2 | ~~#1486~~ | mine | P3 | **Done** | 采购联盟资格追踪 — PR #4443 MERGED ✅ |
| 05-03 | kimi3 | ~~#1635~~ | design-ai | P2 | **Done** | AI图生视频 — PR #4442 MERGED ✅ |
| 05-03 | kimi3 | ~~#1824~~ | brand | P2 | **Done** | 内容创作/编辑页面 — PR #4439 MERGED ✅ |
| 05-03 | kimi2 | ~~#1601~~ | budget | P2 | **Done** | 报销申请接入预算关卡 — PR #4438 MERGED ✅ |
| 05-03 | kimi2 | ~~#1597~~ | budget | P2 | **Done** | 员工借款额度校验 — PR #4437 MERGED ✅ |
| 05-04 | kimi2 | ~~#1551~~ | wecom | P2 | **Done** | 企微待办API对接 — PR #4446 MERGED ✅ |
| 05-04 | kimi5 | ~~#1674~~ | biz-enablement | P2 | **Done** | 产品参数查询中心API — PR #4449 MERGED ✅ |
| 05-04 | kimi4 | ~~#1878~~ | asset-library | P1 | **Done** | 素材统计接口 — PR #4447 MERGED ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#1881~~ | asset-library | P1 | **Done** | 素材下载 — PR #4448 MERGED ✅ |
| 05-04 | #2132 ✅merged/kimi1 | ~~#1615~~ | chat | P1 | **Done** | 按群分角色AI配置 — PR #4453 MERGED ✅ |
| 05-05 | #2132 ✅merged/kimi1 | ~~#1611~~ | chat | P2 | **Done** | 消息线程化与兴趣匹配 — PR #4455 MERGED ✅ |
| 05-05 | kimi2 | ~~#1882~~ | frontend | P2 | **Done** | 素材库-列表查询+筛选+权限 — PR #4450 MERGED ✅ |
| 05-05 | #2132 ✅merged/kimi1 | ~~#1843~~ | design-ai | P2 | **Done** | 招标规范文本自动生成 — PR #4456 MERGED ✅ |
| 05-05 | kimi2 | ~~#1612~~ | chat | P2 | **Done** | 业务场景自动分类引擎 — PR #4457 MERGED ✅ |
| 05-05 | kimi2 | ~~#2072~~ | hr | P2 | **Done** | Phase7 培训管理后端补充 — PR #4462 MERGED ✅ |
| 05-05 | kimi4 | #2021 | approval | P2 | In Progress | 报销费控模块接入审批流 |
| 05-05 | kimi5 | #1686 | backend | P2 | In Progress | 报销费控新增项目费用关联 |
| 05-05 | kimi3 | ~~#1616~~ | chat | P1 | ~~Done~~ | 每日群聊摘要 — PR #4454 MERGED ✅ |
| 05-06 | kimi3 | #2340 | backend | **high** | In Progress | 方案引擎方案工作台 |
| 05-06 | kimi2 | ~~#2073~~ | hr | P2 | ~~Done~~ | 人事管理菜单+权限SQL — PR #4463 MERGED ✅ |
| 05-06 | kimi2 | ~~#1698~~ | backend | **high** | ~~Done~~ | 提成绩效计算引擎 — PR #4467 OPEN，CI queued |
| 05-06 | kimi4 | ~~#2021~~ | approval | P2 | ~~Done~~ | 报销费控模块接入审批流 — PR #4464 MERGED ✅ |
| 05-06 | #2132 ✅merged/kimi1 | ~~#2132~~ | backend | P1 | ~~Done~~ | RBAC权限系统 — PR #4469 OPEN，CI queued |
| 05-06 | kimi5 | #2100 | backend | P2 | In Progress | AI工单智能分派 |
| 05-06 | kimi4 | #1838 | backend | medium | In Progress | 批量方案变体生成（重建修复） |
| 05-06 | kimi2 | ~~#1842~~ | backend | P2 | ~~Done~~ | 产品资源开放体系 — PR #4470 MERGED ✅ |
| 05-06 | kimi2 | #2144 | brand | P2 | In Progress | AI辅助翻译 |
| 05-06 | kimi3 | ~~#2340~~ | backend | P1 | ~~Done~~ | 方案引擎方案工作台 — PR #4466 MERGED ✅ |
| 05-06 | kimi3 | ~~#2133~~ | backend | P1 | ~~Done~~ | 企微OA能力扩展 — CLOSED（Redis冲突修复，99测全绿） |
| 05-06 | kimi3 | ~~#2200~~ | brand | P1 | ~~Done~~ | MediaX SDK部署 — CLOSED |
| 05-06 | kimi5 | ~~#2100~~ | backend | P2 | ~~Done~~ | AI工单智能分派 — PR #4471 MERGED ✅ |
| 05-06 | kimi5 | ~~#2166~~ | backend | P1 | ~~Done~~ | AI图生图API — CLOSED |
| 05-06 | kimi5 | ~~#2426~~ | pipeline | P1 | ~~Done~~ | vLLM统一调用封装 — CLOSED |
| 05-06 | kimi4 | ~~#1838~~ | backend | P2 | ~~Done~~ | 批量方案变体生成 — CLOSED |
| 05-06 | kimi3 | ~~#2101~~ | backend | P1 | ~~Done~~ | AI预测性维护 — CLOSED |
| 05-06 | #2132 ✅merged/kimi1 | ~~#2132~~ | backend | P1 | ~~Done~~ | RBAC权限系统 — PR #4469 MERGED ✅ |
| 05-06 | kimi2 | ~~#2144~~ | brand | P2 | ~~Done~~ | AI辅助翻译 — PR #4474 MERGED ✅ |
| 05-06 | kimi4 | ~~#2147~~ | pipeline | P2 | ~~Done~~ | G7e工具链部署 — PR #4479 MERGED ✅ |
| 05-06 | kimi3 | ~~#2442~~ | backend | P1 | ~~Done~~ | Lookalike搜索 — PR #4481 MERGED ✅ |
| 05-08 | kimi3 | ~~#2516~~ | frontend | medium | ~~Done~~ | 项目详情页「合同要点」卡片 — PR #4496 MERGED ✅ |
| 05-08 | kimi1 | #2342 | frontend | medium | In Progress | 方案引擎 方案模板管理前端 — 模板库浏览+上传+行业×阶段矩阵 |
| 05-08 | kimi4 | ~~#2332~~ | pipeline | medium | ~~Done~~ | 工具中心 数据管理→采集工具使用指南页 — PR #4501 MERGED ✅ |
| 05-08 | kimi5 | ~~#2334~~ | fullstack | medium | ~~Done~~ | 设计工具下载页（D3/GH+AI渲染） — PR #4499 MERGED ✅ |
| 05-08 | kimi6 | ~~#2364~~ | backend | medium | ~~Done~~ | 审批引擎Phase10菜单权限SQL — PR #4498 MERGED ✅ |
| 05-08 | kimi1 | ~~#2343~~ | frontend | medium | ~~Done~~ | S3资产浏览器前端 — PR #4503 MERGED ✅ |
| 05-08 | kimi3 | #2333 | fullstack | medium | In Progress | PPT插件下载页 — 方案中心 |
| 05-08 | kimi4 | #2337 | frontend | medium | In Progress | 样品申请单+制作工单页面 |
| 05-08 | kimi5 | #2338 | frontend | medium | In Progress | 样品箱管理页面 — 卡位可视化布局 |
| 05-08 | kimi6 | #2473 | backend | medium | In Progress | 律师催收数据库+API — 律师信息+催收案件+进展记录 |
| 05-08 | kimi1 | ~~#2342~~ | frontend | medium | ~~Done~~ | 方案模板管理前端 — PR #4500 MERGED ✅ |
| 05-08 | kimi1 | #2330 | backend | medium | In Progress | PPT插件文生图面板 — PR #4507 OPEN |
| 05-08 | kimi2 | ~~#3162~~ | backend | medium | ~~Done~~ | 企微审批回调核心逻辑 — PR #4508 MERGED ✅ |
| 05-09 | kimi2 | #3153 | backend | medium | In Progress | 自动审批规则引擎 — 预审条件+预清除回退（依赖#2026 CLOSED） |
| 05-09 | kimi1 | #3164 | backend | medium | In Progress | 企微审批消息卡片增强 — 一键审批+富文本摘要 |
| 05-09 | kimi3 | #3181 | backend | medium | In Progress | 阶段文档注册表 — 文档清单模板+完成度计算 |
### 当前运行（05-06 10:04）
| kimi | Issue | 模块 | 优先级 | 内容 | PR状态 |
|------|-------|------|--------|------|--------|
| ~~#2132 ✅merged/kimi1~~ | ~~#1496~~ | ~~backend~~ | ~~P2~~ | ~~NBO行动推荐生成~~ | ~~✅ PR#4431 MERGED~~ |
| ~~kimi2~~ | ~~#1601~~ | ~~budget~~ | ~~P2~~ | ~~报销申请接入预算关卡~~ | ~~✅ PR#4438 MERGED~~ |
| ~~kimi3~~ | ~~#1824~~ | ~~brand~~ | ~~P2~~ | ~~内容创作/编辑页面~~ | ~~✅ PR#4439 MERGED~~ |
| ~~#2132 ✅merged/kimi1~~ | ~~#1818~~ | ~~brand~~ | ~~P2~~ | ~~平台定制发布~~ | ~~✅ PR#4440 MERGED~~ |
| ~~kimi2~~ | ~~#1486~~ | ~~mine~~ | ~~P3~~ | ~~采购联盟资格追踪~~ | ~~✅ PR#4443 MERGED~~ |
| ~~kimi3~~ | ~~#1635~~ | ~~design-ai~~ | ~~P2~~ | ~~AI图生视频~~ | ~~✅ PR#4442 MERGED~~ |
| ~~kimi4~~ | ~~#1539~~ | ~~budget~~ | ~~P2~~ | ~~历史基准自动积累~~ | ~~✅ PR#4451 MERGED~~ |
| ~~kimi5~~ | ~~#1590~~ | ~~budget~~ | ~~P2~~ | ~~项目成本复盘报告~~ | ~~✅ PR#4428 MERGED~~ |
| ~~#2132 ✅merged/kimi1~~ | ~~#1611~~ | ~~chat~~ | ~~P2~~ | ~~消息线程化与兴趣匹配~~ | ~~✅ PR#4455 MERGED~~ |
| ~~#2132 ✅merged/kimi1~~ | ~~#1843~~ | ~~design-ai~~ | ~~P2~~ | ~~招标规范文本自动生成~~ | ~~✅ PR#4456 MERGED~~ |
| ~~#2132 ✅merged/kimi1~~ | ~~#2132~~ | ~~backend~~ | ~~P1~~ | ~~RBAC权限系统~~ | ~~✅ PR#4469 MERGED~~ |
| ~~kimi2~~ | ~~#2144~~ | ~~brand~~ | ~~P2~~ | ~~AI辅助翻译~~ | ~~✅ PR#4474 MERGED~~ |
| ~~kimi3~~ | ~~#2200~~ | ~~brand~~ | ~~P1~~ | ~~MediaX SDK部署~~ | ~~✅ CLOSED~~ |
| ~~kimi3~~ | ~~#2101~~ | ~~backend~~ | ~~P1~~ | ~~AI预测性维护~~ | ~~✅ CLOSED~~ |
| ~~kimi3~~ | ~~#2165~~ | ~~backend~~ | ~~P1~~ | ~~Qwen2.5-VL部署~~ | ~~⏸️ pause（GPU环境不可达）~~ |
| ~~kimi3~~ | ~~#2442~~ | ~~backend~~ | ~~P1~~ | ~~Lookalike搜索~~ | ~~✅ PR#4481 MERGED~~ |
| ~~kimi4~~ | ~~#1838~~ | ~~backend~~ | ~~P2~~ | ~~批量方案变体生成~~ | ~~✅ CLOSED~~ |
| ~~kimi4~~ | ~~#2147~~ | ~~pipeline~~ | ~~P2~~ | ~~G7e工具链部署~~ | ~~✅ PR#4479 MERGED~~ |
| ~~kimi5~~ | ~~#2382~~ | ~~frontend~~ | ~~P1~~ | ~~前端培训计划+课程库页面~~ | ~~✅ PR#4478 MERGED~~ |
| ~~kimi1~~ | ~~#2339~~ | ~~frontend~~ | ~~P1~~ | ~~合同要点卡片（部分T1）~~ | ~~✅ PR #4488 MERGED~~ |
| ~~kimi1~~ | ~~#2342~~ | ~~frontend~~ | ~~P1~~ | ~~方案模板管理前端~~ | ~~✅ PR #4500 MERGED~~ |
| ~~kimi3~~ | ~~#2516~~ | ~~frontend~~ | ~~P1~~ | ~~项目详情页合同要点卡片~~ | ~~✅ PR #4496 MERGED~~ |
| ~~kimi4~~ | ~~#2332~~ | ~~pipeline~~ | ~~P1~~ | ~~数据管理采集工具指南页~~ | ~~✅ PR #4501 MERGED~~ |
| ~~kimi5~~ | ~~#2334~~ | ~~fullstack~~ | ~~P1~~ | ~~设计工具下载页（D3/GH+AI渲染）~~ | ~~✅ PR #4499 MERGED~~ |
| ~~kimi6~~ | ~~#2364~~ | ~~backend~~ | ~~P1~~ | ~~审批引擎Phase10菜单权限SQL~~ | ~~✅ PR #4498 MERGED~~ |
| ~~kimi1~~ | ~~#2343~~ | ~~frontend~~ | ~~P1~~ | ~~S3资产浏览器前端~~ | ~~✅ PR #4503 MERGED~~ |
| ~~kimi3~~ | ~~#2333~~ | ~~fullstack~~ | ~~P1~~ | ~~PPT插件下载页~~ | ~~✅ PR #4502 MERGED~~ |
| ~~kimi4~~ | ~~#2337~~ | ~~frontend~~ | ~~P1~~ | ~~样品申请单页面~~ | ~~✅ PR #4506 MERGED~~ |
| ~~kimi5~~ | ~~#2338~~ | ~~frontend~~ | ~~P1~~ | ~~样品箱管理页面~~ | ~~✅ PR #4505 MERGED~~ |
| kimi6 | ~~#2473~~ | ~~backend~~ | ~~P1~~ | ~~律师催收数据库+API~~ | ~~✅ PR #4504 MERGED~~ |
| kimi6 | ~~#2741~~ | ~~fullstack~~ | ~~P1~~ | ~~自定义报告模板与导出~~ | ~~✅ PR #4539 MERGED 04:27~~ |
| kimi1 | #2115 | backend | P2 | G7e采集自动化 — 中标数据→AI判定→评分入库 | CC工作中 |
| kimi7 | ~~#2653~~ | backend | P1 | 节日日历DB+海报模板管理API | ~~✅ PR #4536 MERGED~~ |
| kimi8 | ~~#2661~~ | backend | P1 | 配色方案导出+总部需求表 | ~~✅ PR #4531 MERGED~~ |
| kimi7 | ~~#2336~~ | ~~frontend~~ | ~~P1~~ | ~~D3样品一键生成页面~~ | ~~✅ PR #4541 MERGED~~ |
| kimi8 | #2334 | backend | P1 | 设计工具下载页 D3/GH+AI渲染 | CC工作中 |
| kimi3 | #3181 | backend | P1 | 阶段文档注册表 | CC工作中 |
| ~~kimi3~~ | ~~#2643~~ | ~~backend~~ | ~~P1~~ | ~~员工代言内容池+分享追踪API~~ | ~~✅ PR #4534 MERGED~~ |
| 05-09 | kimi3 | ~~#2643~~ | backend | medium | ~~Done~~ | 员工代言内容池API — PR #4534 MERGED ✅ |
| 05-09 | kimi1 | ~~#3164~~ | backend | medium | ~~Done~~ | 企微审批消息卡片增强 — PR #4538 MERGED ✅ |
| 05-09 | kimi7 | ~~#2336~~ | frontend | medium | ~~Done~~ | D3样品一键生成页面 — PR #4541 MERGED ✅ |
| 05-09 | kimi7 | ~~#2653~~ | backend | medium | ~~Done~~ | 节日日历DB+海报模板管理API — PR #4536 MERGED ✅ |
| 05-09 | kimi8 | ~~#2661~~ | backend | medium | ~~Done~~ | 配色方案导出+总部需求表 — PR #4531 MERGED ✅ |
| 05-09 | kimi2 | ~~#3153~~ | approval | medium | ~~Done~~ | 自动审批规则引擎 — PR #4537 MERGED ✅ |
| 05-09 | kimi6 | ~~#2741~~ | fullstack | medium | ~~Done~~ | 自定义报告模板与导出 — PR #4539 MERGED ✅ |
| 05-09 | — | ~~#2528~~ | backend | P2 | ~~Done~~ | 公告板DB建表 Phase8 — PR #4535 MERGED ✅ |
| 05-09 | kimi8 | #2334 | backend | medium | In Progress | 设计工具下载页 D3/GH+AI渲染 |
| 05-09 | kimi1 | #2115 | backend | medium | In Progress | G7e采集自动化 — 中标数据→AI判定→评分入库 |
| ~~kimi2~~ | ~~#3132~~ | ~~backend~~ | ~~P1~~ | ~~审批抄送功能~~ | ~~✅ PR #3917+PR #4508 MERGED~~ |
| ~~kimi1~~ | ~~#2330~~ | ~~backend~~ | ~~P1~~ | ~~PPT插件文生图面板~~ | ~~✅ PR #4507 MERGED~~ |

### PR进度总览（04-26 22:05）
| kimi | Issue | PR | 状态 | 备注 |
|------|-------|----|----|------|
| ~~kimi5~~ | ~~#1450~~ | #4239 | ✅ merged | 10:02:34 UTC |
| ~~kimi3~~ | ~~#1452~~ | #4240 | ✅ merged | 10:11:30 UTC |
| ~~kimi2~~ | ~~#2756~~ | #4241 | ✅ merged | 11:39:30 UTC |
| ~~kimi7~~ | ~~#2271~~ | #4242 | ✅ merged | 12:31:50 UTC |
| ~~kimi4~~ | ~~#2264~~ | #4243 | ✅ merged | 12:40:45 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2265~~ | #4244 | ✅ merged | 13:52:23 UTC |
| ~~kimi5~~ | ~~#2268~~ | #4245 | ✅ merged | 14:01:36 UTC |
| ~~kimi6~~ | ~~#2712~~ | #4247 | ✅ merged | 15:02:44 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2704~~ | #4248 | ✅ merged | 16:11:30 UTC |
| ~~kimi2~~ | ~~#3172~~ | #3911 | ✅ merged | 04-19误恢复，确认Done |
| ~~#2132 ✅merged/kimi1~~ | ~~#2437~~ | #4249 | ✅ merged | 02:11:49 UTC |
| ~~kimi2~~ | ~~#2275~~ | #4250 | ✅ merged | 02:44:37 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2440~~ | #4251 | ✅ merged | 03:48:01 UTC |
| ~~kimi2~~ | ~~#1598~~ | #4252 | ✅ merged | 04:00:18 UTC |
| ~~kimi2~~ | ~~#2439~~ | #4253 | ✅ merged | 04:43:25 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#1603~~ | #4254 | ✅ merged | 04:55:43 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2441~~ | #4255 | ✅ merged | 05:24:50 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2617~~ | #4256 | ✅ merged | 05:48:17 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2444~~ | #4258 | ✅ merged | 手动关闭Issue |
| ~~kimi2~~ | ~~#2306~~ | #4257 | ✅ merged | 06:13:19 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2526~~ | #4259 | ✅ merged | 06:33:53 UTC |
| ~~kimi2~~ | ~~#3109~~ | #4260 | ✅ merged | 07:53:25 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2215~~ | #4261 | ✅ merged | 08:17:48 UTC |
| ~~kimi2~~ | ~~#1498~~ | #4265 | ✅ merged | 09:20:15 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2445~~ | #4266 | ✅ merged | 09:36:28 UTC |
| ~~kimi2~~ | ~~#2319~~ | #4267 | ✅ merged | 11:00:07 UTC |
| ~~kimi2~~ | ~~#2539~~ | #4268 | ✅ merged | 12:46:37 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2293~~ | #4269 | ✅ merged | 13:03:37 UTC |
| ~~kimi2~~ | ~~#3106~~ | #4270 | ✅ merged | 13:56:59 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#3107~~ | #4271 | ✅ merged | 14:30:11 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2639~~ | #4272 | ✅ merged | 14:50:12 UTC |
| ~~kimi2~~ | ~~#3111~~ | #4273 | ✅ merged | 15:16:56 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#2639~~ | #4272 | ✅ merged | 14:50:12 UTC |
| ~~kimi2~~ | ~~#2316~~ | #4414 | ✅ merged | 18:10:10 UTC |
| ~~kimi3~~ | ~~#2312~~ | #4413 | ✅ merged | 19:12:42 UTC |
| ~~kimi2~~ | ~~#1682~~ | #4417 | ✅ merged | 19:49:28 UTC |
| ~~kimi5~~ | ~~#2045~~ | #4410 | ✅ merged | 20:32:02 UTC |
| ~~kimi5~~ | ~~#2044~~ | #4420 | ✅ merged | 22:52:19 UTC |
| ~~kimi2~~ | ~~#1826~~ | #4419 | ✅ merged | 23:23:04 UTC |
| ~~kimi4~~ | ~~#2051~~ | #4416 | ✅ merged | 00:49:00 UTC，checkbox质量门拦截已修复 |
| ~~kimi5~~ | ~~#1948~~ | #4421 | ✅ merged | 03:21:53 UTC |
| ~~#2132 ✅merged/kimi1~~ | ~~#1490~~ | #4415 | ✅ merged | 03:29:17 UTC |
| — | #1495 | #4422 | ✅ merged | 05:08:49 UTC |
| — | #1485 | #4423 | ✅ merged | 05:37:00 UTC |
| — | #1964 | #4424 | ✅ merged | 05:41:30 UTC |
| kimi4 | #1539 | #4427 | 🔍 REVIEW_REQUIRED | kimi4 新指派后提PR，06:55:50 UTC |
| — | #1826 | #4426 | 🔍 REVIEW_REQUIRED | 05:26:38 UTC，Vue JSX 插件修复构建 |
| — | #1963 | #4425 | 🔍 REVIEW_REQUIRED | 04:10:56 UTC |
| #2132 ✅merged/kimi1 | #1496 | #4431 | 🔍 REVIEW_REQUIRED | 08:15:00 UTC，NBO行动推荐生成 |
