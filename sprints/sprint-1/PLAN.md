# 新开发环境排程计划

> 新机器：172.31.31.227 | dev分支：全新基线(ruoyi-ai框架 + V2菜单基线)
> 创建日期：2026-04-12 | 状态：执行中
> 并发上限：15个CC | pipeline Issue不在此排程范围

## 排程原则

1. **Tier-0 最先**：菜单基线必须先验证通过，所有后续开发依赖菜单结构
2. **全球项目矿场 Tier-2 优先**：业务最重要，菜单完成后立即启动，单独分配 CC 资源，不与其他模块竞争
3. **有原型/设计文档的优先**：设计文档目录 `docs/design/` 下有完整原型的优先排程
4. **Master Issue 先于子Issue**：先搭框架再填充功能
5. **前端页面优先后端API**：新环境先让页面跑起来，API可用mock数据过渡
6. **CRM系列串行**：CRM-01~13有强数据依赖，按编号顺序执行

---

## Tier-0：环境基线（最高优先，立即执行）

| Issue | 优先 | 模块 | 内容 | 启动 | 说明 |
|-------|------|------|------|------|------|
| #3597 | P0 | backend | 菜单基线Flyway脚本验证 | **立即** | V2脚本已提交，需启动后端验证Flyway执行 |
| #3613 | P0 | fullstack | CRM菜单component/perms前缀整改 | **立即** | CRM菜单 wande/crm→business/crm, crm:→biz:crm:，需读 menu-contracts.md |

> **验收标准**：后端启动成功 + 8大工作区侧边栏正确 + 角色权限正确 + CRM菜单前缀符合规范

---

## Tier-1：RBAC角色主页体系（依赖Tier-0菜单基线）

> 设计文档：`docs/design/rbac-homepage/详细设计.md`
> 每个角色登录后看到自己的Dashboard主页

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3522 | P1 | fullstack | Dashboard Widget配置表 + 动态渲染引擎 | ✅ | #3597 |
| #3517 | P0 | fullstack | 商务主页Dashboard — 8个Widget | ⏳ | #3522 |
| #3518 | P1 | fullstack | 支持中心主页Dashboard — 6个Widget | ⏳ | #3522 |
| #3519 | P1 | fullstack | 项目安装主页Dashboard — 7个Widget | ⏳ | #3522 |
| #3520 | P1 | fullstack | 综合管理主页Dashboard — 6个Widget | ⏳ | #3522 |
| ~~#3521~~ | ~~P1~~ | ~~frontend~~ | ~~Boss耀总Dashboard — 8大板块导航页~~ ✅ CLOSED | ~~Done~~ | #3522 |

> **并行策略**：#3522引擎完成后，#3517~#3521可并行开发（5个CC同时）

---

## Tier-2：全球项目矿场（业务最重要，菜单完成后优先启动）

> 设计文档：`docs/design/全球项目矿场/详细设计.md` + 6个HTML原型
> Master Issue: #3458
> **优先级说明**：用户需求优先，完成菜单基线后立即推进

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3458 | P0 | fullstack | ~~全球项目矿场v3.0 — 基于确认原型的完整改版~~ ✅ PR#3606 merged | ✅ | #3597(菜单基线) |
| ~~#3615~~ | ~~P0~~ | ~~fullstack~~ | ~~#3458验收8项缺陷修复~~ ✅ PR#3616 merged | ~~Done~~ | #3458 |
| ~~#3617~~ | ~~P0~~ | ~~fullstack~~ | ~~#3458第二轮验收8项缺陷修复~~ ✅ Done | ~~Done~~ | #3615 |
| ~~#3625~~ | ~~P0~~ | ~~frontend~~ | ~~#3458第三轮回归：KPI/工具栏/Modal触发 6项页面缺陷~~ ✅ PR#3642 merged 2026-04-14 11:25 | ~~Done~~ | #3617 |
| ~~#3626~~ | ~~P1~~ | ~~frontend~~ | ~~详情抽屉补齐：任务看板Tab + 甲方联系卡置顶~~ ✅ PR #3629 Merged | ~~Done~~ | #3617 |
| ~~#3627~~ | ~~P1~~ | ~~fullstack~~ | ~~新增功能 + 批量操作（标记/导出）完整实现~~ ✅ PR #3628 Merged | ~~Done~~ | #3617 |

> **快速路线**：仅依赖菜单，可独立快速推进，支撑商务部日常运营
> **第三轮回归来源**：Playwright 全量回归脚本 `e2e/tests/front/e2e/project-mine-regression.spec.ts`
>   - 覆盖 14 测试项，对账 `docs/design/全球项目矿场/详细设计.md`
>   - 结论：6 项 BUG（#3625）+ 7 项未开发（#3626 / #3627）

---

## Tier-3：超管驾驶舱增量（依赖Tier-0）

> 设计文档：`docs/design/超管驾驶舱/详细设计.md` + 18个HTML原型
> Master Issue: #3466（已有44个Controller，增量功能）

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3466 | P0 | fullstack | 超管驾驶舱Master — 框架验证 | ✅ | #3597 |
| #3481 | P1 | fullstack | 实时日志流Tab | ⏳ | #3466验证 |
| #3482 | P1 | fullstack | FinOps开发运维成本Tab | ⏳ | #3466验证 |
| #3483 | P1 | fullstack | 安全审计Tab | ⏳ | #3466验证 |
| #3484 | P1 | fullstack | Prompt管理Tab | ⏳ | #3466验证 |

> **并行策略**：#3466验证后，4个Tab可并行开发

---

## Tier-4：CRM商务中心（依赖Tier-0 + Tier-1商务主页）

> 设计文档：`docs/design/crm-商务中心/详细设计.md` + `crm-商务工作台/` + `crm-商机详情页/`
> Master Issue: #3526
> **串行执行**：CRM-01→13按编号顺序，后续模块依赖前序数据表

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3526 | P0 | fullstack | CRM商务中心Master — Sprint-1 总协调 | ✅ | #3597 |
| #3527 | P0 | backend | CRM-DB 数据库基础建表 — Flyway迁移脚本(9张表) | ✅ | #3526 |
| ~~#3528~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-01 商务工作台 — KPI+收件箱+业绩面板~~ ✅ CLOSED | ~~Done~~ | #3527 |
| #3529 | P1 | fullstack | CRM-02 客户管理 — CRUD+三类型+详情页 | ✅ | ~~#3528~~ CLOSED |
| #3530 | P1 | fullstack | CRM-03 商机管道 — 列表+看板+7阶段 | ⏳ | #3529 |
| #3531 | P1 | fullstack | CRM-04 商机详情页 — 10Tab+阶段推进 | ⏳ | #3530 |
| #3532 | P1 | fullstack | CRM-05 询盘工作台 — 5状态+报价+转商机 | ⏳ | #3529 |
| #3533 | P1 | fullstack | CRM-06 记录中心 — 四视角+周报月报 | ⏳ | #3529 |
| #3534 | P1 | fullstack | CRM-07 投标申请 — 审批流+中标结果 | ⏳ | #3530 |
| #3535 | P1 | fullstack | CRM-08 回款跟踪 — 周报+逾期提醒 | ⏳ | #3530 |
| #3536 | P1 | fullstack | CRM-09 经销商管理 — 级别/返点/目标 | ⏳ | #3529 |
| #3537 | P1 | fullstack | CRM-10 我的提成 — KPI+月度明细 | ⏳ | #3528 |
| #3548 | P1 | fullstack | CRM-13 公司通讯录 — 全员联系人+部门树 | ⏳ | #3526 |
| #3549 | P1 | fullstack | CRM-14 责任人变更日志 — 线索/商机/客户变更审计 | ⏳ | #3529 |
| #3550 | P1 | fullstack | CRM-11 智能过会 — 异常驱动+过会视图 | ⏳ | #3530 |
| #3551 | P1 | fullstack | CRM-12 授权管理 — 经销商授权+审批 | ⏳ | #3536 |

> **并行窗口**：#3529完成后可并行 #3530/#3532/#3533/#3536；#3530完成后可并行 #3531/#3534/#3535/#3550

---

## Tier-5：经销商产品展示门户（独立，可与Tier-3/4并行）

> 设计文档：`docs/design/product-portal/详细设计.md` + 3个HTML原型
> Master Issue: #3579

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3579 | P1 | fullstack | 产品门户Master — 路由+权限+布局 | ✅ | #3597 |
| #3582 | P0 | frontend | 产品目录页 — 卡片网格+筛选搜索 | ⏳ | #3579 |
| #3583 | P0 | frontend | 产品详情页 — 参数+3D查看器 | ⏳ | #3582 |
| #3585 | P1 | frontend | 备件目录页+爆炸图联动 | ⏳ | #3583 |
| #3588 | P2 | frontend | H5移动端适配 | ⏳ | #3583 |

> **并行策略**：Tier-5与Tier-2/3/4完全独立，可同时启动

---

## Tier-6：耀总驾驶舱（依赖Tier-1 Boss Dashboard）

> 设计文档：`docs/design/耀总驾驶舱/详细设计.md` + 12个HTML原型
> Master Issue: #3461

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #3461 | P1 | fullstack | 耀总驾驶舱v1.0 — 8大区块 | ✅ | ~~#3521(Boss Dashboard)~~ CLOSED |

---

## Pipeline Issue（独立排程，不受新dev环境影响）

| Issue | 内容 | 说明 |
|-------|------|------|
| #1865 | 设计师知识画像与自适应教学 | pipeline独立 |
| #1925 | AI知识库扩充 | pipeline独立 |
| #2417 | 竞品官网经销商网络采集脚本 | pipeline独立 |
| #2419 | 数据库Schema(dealer_candidates) | pipeline独立 |
| #2492 | 欧美竞品产品参数采集 | pipeline独立 |

---

## 时间线估算

```
Week 1 (4/12-4/18):
  Tier-0: #3597 菜单基线验证
  Tier-1: #3522 Widget引擎开发
  Tier-2: #3458 全球项目矿场Master (快速路线，1CC)
  Tier-3: #3466 超管驾驶舱验证
  Tier-5: #3579 产品门户Master

Week 2 (4/19-4/25):
  Tier-1: #3517~#3521 五个角色Dashboard (并行5CC)
  Tier-2: #3458 支持商务运营 ✓
  Tier-3: #3481~#3484 四个驾驶舱Tab (并行4CC)
  Tier-4: #3526 CRM Master + #3527 CRM-DB + #3528 CRM-01
  Tier-5: #3582~#3583 产品目录+详情 (并行2CC)

Week 3 (4/26-5/02):
  Tier-4: #3529~#3536 CRM-02~09 (串行+局部并行)
  Tier-6: #3461 耀总驾驶舱 (1CC)
  Tier-5: #3585 备件目录
  Tier-2: 交付验收 ✓

Week 4 (5/03-5/09):
  Tier-4: #3537~#3551 CRM-10~13 (串行)
  Tier-5: #3588 H5适配
  收尾: 全量E2E测试 + 角色权限验收
```

## CC分配策略

| 阶段 | 活跃CC数 | 分配 |
|------|---------|------|
| Week 1 | 4-5 | Tier-0(1) + Tier-1(1) + **Tier-2(1)矿场优先** + Tier-3(1) + Tier-5(1) |
| Week 2 | 12-13 | Tier-1(5) + Tier-3(4) + Tier-4(1) + Tier-5(2) + Tier-2检验(1) |
| Week 3 | 8-9 | Tier-4(5) + Tier-6(1) + Tier-5(1) + Tier-2交付(1) |
| Week 4 | 4-5 | Tier-4(3) + Tier-5(1) + 收尾(1) |

**全球项目矿场快速路线说明**：
- Week 1: Master 框架搭建（1个Issue，相对简单）
- Week 2: 核心功能完成 + 商务运营支持
- Week 3 末: 交付生产可用版本
- 全过程 1-2 个 CC，不与其他 Tier 竞争资源，快速迭代

---

# 以下内容由排程经理每次排程后维护

## 指派建议（最近20个）

> Week 1 Master全部完成。Week 2 排程：bug修复(kimi1/2) + Tier-1五角色Dashboard(kimi3-7) + Tier-3四Tab(kimi8-11) + Tier-5产品目录(kimi12) + CRM/耀总接力。
> 依赖变化：#3521(Boss Dashboard)已CLOSED → #3461(耀总)解锁；#3528(CRM-01)已CLOSED → #3529/#3537解锁。
> ⚠️ kimi7原锁定#3521已CLOSED，建议释放改派#3529或#3461。
> **🔥 2026-04-13 新增 #3624 矿场接入 Phase1 (P0)**：wdpp_discovered_projects 建表 + pymysql安装 + ProjectMineServiceImpl去mock。建议 kimi1 优先启动（high effort），接入真数据后矿场页面才脱离mock。
> **✅ 2026-04-14 G7e 数据已抢救**：`legacy-pg` Docker (localhost:15432, pw=legacy) 保留 449 张表全量零错误；MySQL `wande_ai_legacy` (3306) 载入 92-98%。#3624 数据源就绪，可立即启动。
> **♻ 2026-04-14 刷新**：#3617 已CLOSED，移除；kimi2 空出可接下一任务。
> **🔥 2026-04-14 新增 #3630 (P0)**：wdpp_project_mine 字段与 ggzy_collector 对齐（ALTER+uk_source_url+9列），阻塞 #3624 真数据落地。建议 kimi2 优先启动（medium effort），纯后端实体/VO/Mapper 同步。
> **📋 2026-04-14 新增 Master #3631 (P1，Plan 状态)**：pipeline ↔ 后端表对齐全景规划（19张表，Phase1~5），规划性 Issue 不直接开发。
> **🔥 2026-04-14 拆子完成**：#3631 子 Issue #3632-#3640 全部 Todo 化 + #3641 管线健康度 Tab 前端配对。矿场数据闭环优先级最高。
> **📐 2026-04-14 原型对账**：指派建议表已标注对应的 `docs/design/` 原型路径 — 研发经理派发 CC 前必须让 CC 先读取对应原型+详细设计，验收必须附平台截图。
> **🛠 2026-04-14 排程经理预置 V20260414003~V013 已建好 11 张/组孤岛表**（commit `88b50f18`，flyway_schema_history 已对齐 rank 7-17）：CC 派发后**禁止再写 Flyway 建表 SQL**，直接做 Entity/VO/DTO/Mapper/Service/Controller/前端。各 Issue 评论已附「确定指令清单」（API 路径 + 验收 + 配对前端），无 CC 评估空间。
> **🛠 2026-04-14 #3637/#3640 决策已锁定**（取代评论中的"评估"段）：#3637 只用 5 张核心竞品表，runs/company_status/errors/design_analysis/updates 不建；#3640 pipeline 写 wdpp_products → 门户前端**直接读** wdpp_products（V20260414012 已加门户展示字段），wdpp_product_portal_* 保留供运营手动维护。
> **✅ 2026-04-14 矿场页面 30 条 seed 已注入** wdpp_project_mine（覆盖 6 Tab：early_gold/bidding/needs_confirm/dormant/invalid + assigned/contacted/tracking/bid_preparing 各 mine_status），脚本 `scripts/seed/project_mine_seed.sql` 可重复刷。
> **🔥🔥 2026-04-14 20:07 用户最高优先级指令**：**优先完成 #3631 矿场接入 Master 的剩余子 Issue**，其他 Tier 全部让路。
> **📊 2026-04-14 21:27 #3631 子 Issue 进度**：#3637 PR#3672 merged ✅（kimi1 释放）；#3638 kimi16 In Progress；#3641/#3639 先前已 merged。**⚠️ #3636 连续 5 轮（50 分钟）待补派**（空位 kimi8/kimi9/kimi17，幼儿园采购专题 smoke 2/3 过可续）。#3481 kimi8 已 CLOSED。
> **♻ 清理**：已 CLOSED 的 #3624/#3630/#3632/#3633/#3634/#3635/#3637/#3639/#3640 + #3641(PR merged) 从指派建议表移除（明细表仍保留追踪）。

| 目录 | Issue | 优先 | 模块 | 内容 | 原型/设计参考 | effort |
|------|-------|------|------|------|--------------|--------|
| — | **#3636** | **🔥P0** | **fullstack** | **[#3631 子][连续5轮待派] Phase4 E: 幼儿园采购+预算项目专题页（V007/V013 表已建；smoke 2/3 过可续；kimi8/9/17 任一可接）** | `docs/design/全球项目矿场/01-all.html`（套布局） | medium |
| kimi12 | #3517 | P0 | fullstack | Tier-1: 商务主页Dashboard — 8个Widget | `docs/design/rbac-homepage/详细设计.md` | high |
| — | #3518 #3519 #3520 | P1 | fullstack | Tier-1: 支持/安装/综管主页Dashboard | `docs/design/rbac-homepage/详细设计.md` | high |
| — | #3529 | P1 | fullstack | Tier-4: CRM-02 客户管理 | `docs/design/crm-商务中心/详细设计.md` | high |
| — | #3481 #3482 #3483 #3484 | P1 | fullstack | Tier-3: 超管驾驶舱 实时日志/FinOps/安全审计/Prompt Tab | `docs/design/超管驾驶舱/06/07/15/16-*.html` | high |

## 指派历史（完成后划线）

> 研发经理维护。指派时新增行，完成后在内容列加删除线。

| 指派目录 | Issue | Tier | 模块 | 内容 | 看板状态 |
|---------|-------|------|------|------|---------|
| kimi1 | ~~#3598~~ | P0 | frontend | ~~替换登录页左上角名称为 Wande AI Admin~~ PR#3599✅merged 2026-04-12 18:37 | ~~Done~~ |
| kimi1 | ~~#3600~~ | P0 | frontend | ~~替换登录页底部版权信息为 Copyright © 2026 Wande AI~~ PR#3601✅merged 2026-04-12 19:31 | ~~Done~~ |
| kimi1 | ~~#3602~~ | P0 | backend | ~~超管驾驶舱：Claude Office菜单地址改为公网IP + 取消外链~~ PR#3603✅merged 2026-04-12 20:48 | ~~Done~~ |
| kimi1 | ~~#3604~~ | bug | backend | ~~fix: Claude Office菜单is_frame值修正（应为1=否）~~ PR#3605✅merged 2026-04-12 21:23 | ~~Done~~ |
| kimi1 | ~~#3458~~ | P0 | fullstack | ~~Tier-2: 全球项目矿场v3.0 — 新环境重做~~ PR#3606✅merged 2026-04-12 22:38 | ~~Done~~ |
| kimi2 | ~~#3522~~ | P1 | fullstack | ~~Tier-1: Dashboard Widget配置表+动态渲染引擎~~ PR#3609✅merged 2026-04-12 21:58 | ~~Done~~ |
| kimi3 | ~~#3466~~ | P0 | fullstack | ~~Tier-3: 超管驾驶舱Master — 框架验证~~ PR#3607✅merged 2026-04-12 21:54 | ~~Done~~ |
| kimi4 | ~~#3526~~ | P1 | fullstack | ~~Tier-4: CRM商务中心Master — Sprint-1总协调~~ PR#3610✅merged 2026-04-12 22:44 | ~~Done~~ |
| kimi5 | ~~#3527~~ | P0 | backend | ~~Tier-4: CRM-DB 数据库基础建表(9张表)~~ PR#3612✅merged 2026-04-12 23:39 | ~~Done~~ |
| kimi6 | ~~#3579~~ | P1 | fullstack | ~~Tier-5: 产品门户Master — 路由+权限+布局~~ PR#3608✅merged 2026-04-12 23:04 | ~~Done~~ |
| kimi1 | ~~#3613~~ | P0 | fullstack | ~~Tier-0: CRM菜单component/perms前缀整改~~ | Done（排程经理确认） |
| kimi1 | ~~#3615~~ | P0-bug | fullstack | ~~Tier-2: 全球项目矿场 #3458 验收8项缺陷修复~~ PR#3616✅merged 2026-04-13 05:36 | ~~Done~~ |
| kimi2 | ~~#3617~~ | P0-bug | fullstack | ~~Tier-2: 全球项目矿场v3 第二轮验收缺陷（8项）~~ PR#3623✅merged 2026-04-13 13:40 | ~~Done~~ |
| kimi1 | ~~#3618~~ | P0-bug | fullstack | ~~bug: 建表缺RuoYi标准列 + CRM Controller未注册~~ PR#3620✅merged 2026-04-13 08:57 | ~~Done~~ |
| kimi1 | ~~#3619~~ | P0-bug | backend | ~~bug: Portal产品表缺model3d_file/model3d_render列~~ PR#3621✅merged 2026-04-13 10:33 | ~~Done~~ |
| kimi15 | ~~#3632~~ | P0 | fullstack | ~~矿场Phase2 A: 3张老矿场表迁移 wdpp_project_mine~~ PR#3655✅merged 2026-04-14 15:48 | ~~Done~~ |
| kimi7 | ~~#3635~~ | P1 | fullstack | ~~管线健康度 Tab 后端（替换 CLOSED #3521）~~ PR#3658✅merged 2026-04-14 16:07 | ~~Done~~ |
| kimi11 | ~~#3484~~ | P1 | fullstack | ~~超管驾驶舱·Prompt 管理 Tab~~ PR#3661✅merged 2026-04-14 16:33 | ~~Done~~ |
| kimi14 | ~~#3634~~ | P1 | fullstack | ~~矿场Phase3 C: 省份热力图 API + 前端真数据~~ PR#3663✅merged 2026-04-14 16:47 | ~~Done~~ |
| kimi12 | ~~#3640 + #3582 + #3583~~ | P1 | fullstack | ~~Phase4 I: 产品目录/详情真数据接入~~ PR#3664✅merged 2026-04-14 17:06 | ~~Done~~ |
| kimi3 | ~~#3517~~ | P0 | fullstack | ~~Tier-1: 商务主页Dashboard 8 个 Widget~~ PR#3665✅merged 2026-04-14 17:13 | ~~Done~~ |
| kimi13 | ~~#3633~~ | P1 | fullstack | ~~矿场Phase3 B 关键词池 CRUD + 配置页~~ PR#3666✅merged 2026-04-14 18:06 | ~~Done~~ |
| kimi4 | ~~#3641~~ | P1 | frontend | ~~超管驾驶舱·管线健康度 Tab 前端~~ PR#3667✅merged 2026-04-14 18:06 | ~~Done~~ |
| kimi10 | ~~#3483~~ | P0 | fullstack | ~~超管驾驶舱·安全审计Tab~~ PR#3668✅merged 2026-04-14 18:58 | ~~Done~~ |
| kimi17 | ~~#3639~~ | 🔥P0 | backend | ~~矿场Phase4 H: wdpp_s3_asset_index 后端API~~ PR#3671✅merged 2026-04-14 20:5x | ~~Done~~ |

## 当前运行（2026-04-14 11:55 刷新）

> 11 个僵尸锁经 cc-keepalive 自动恢复（kimi3-12 复用旧 issue id 重启），#3521 已 CLOSED 已停 + 改派 #3635。
> 新派：kimi1 #3624（矿场Phase1 P0），kimi7 #3635（管线健康 P1）。
> kimi20 #3630 是 skill 化机制冒烟验证 + 矿场Phase2，运行中 25%。

| 指派目录 | Issue | Tier | 模块 | 内容 | 启动 |
|---------|-------|------|------|------|------|
| ~~kimi1~~ | ~~**#3624**~~ | P0 | app | ~~矿场Phase1: ggzy_collector+Java去mock~~ ✅ PR#3644 merged 13:31 | ~~11:55~~ |
| kimi1 | **#3637** | P1 | app | 矿场Phase4 F: wdpp_competitor_* 5张表→#3118关系网络 | 13:35 |
| kimi3 | #3517 | P0 | app | 商务主页Dashboard 8Widget（恢复） | 旧锁11:54 |
| kimi4 | #3518 | P1 | app | 支持中心主页Dashboard（恢复） | 旧锁11:54 |
| kimi5 | #3519 | P1 | app | 项目安装主页Dashboard（恢复） | 旧锁11:54 |
| kimi6 | #3520 | P1 | app | 综合管理主页Dashboard（恢复） | 旧锁11:54 |
| kimi7 | **#3635** | P1 | app | 管线健康度Tab（替换已CLOSED #3521） | 11:55 |
| kimi8 | #3481 | P1 | app | 实时日志流Tab（恢复） | 旧锁11:54 |
| kimi9 | #3482 | P1 | app | FinOps Tab（恢复） | 旧锁11:54 |
| kimi10 | #3483 | P1 | app | 安全审计Tab（恢复） | 旧锁11:54 |
| kimi11 | #3484 | P1 | app | Prompt管理Tab（恢复） | 旧锁11:54 |
| kimi12 | #3582 | P0 | app | 产品目录页（恢复） | 旧锁11:54 |
| ~~kimi20~~ | ~~**#3630**~~ | P0 | backend | ~~矿场Phase2字段对齐~~ ✅ PR#3643 merged 12:06 | ~~11:46~~ |
| kimi13 | **#3633** | P1 | app | 矿场Phase3 B: 关键词池 CRUD + 超管采集配置页 | 12:04 |
| kimi14 | **#3634** | P1 | app | 矿场Phase3 C: 省份热力图 API + 前端真数据 | 12:04 |
| kimi15 | **#3632** | P0 | app | 矿场Phase2 A: 3张老矿场表迁移 wdpp_project_mine | 12:13 |
| kimi16 | **#3636** | P1 | app | 矿场Phase4 E: 幼儿园采购+预算项目专题页 | 12:13 |

> 池：14 / 15（kimi20 已释放，13 活跃 + 2 新派 = 14）。空闲 kimi2/17/18/19。
> 🎉 **skill化机制首个完整闭环**：kimi20 #3630 走完 issue-task-md→cc-report start→backend-coding→backend-test→cc-report stage-done→pr-visual-proof→cc-report close 全流程，PR #3643 已 merged。
> 多 CC 触发 sys_menu 占位疑问（#3482/#3483/#3484/#3520），统一按 menu-contract 例外条款放行 INSERT。

### 📍 2026-04-14 17:30 当前池快照（15→5 规模化后的实际活跃）

> Token Pool 耗尽 kimi1/2 → 21-22:00 前仅恢复 kimi3-16 中已有 WIP 的目录。池目标 5 活跃。

| 指派目录 | Issue | 优先级 | 模块 | 内容 | 阶段 |
|---------|-------|-------|------|------|------|
| ~~kimi13~~ | #3633 | P1 | fullstack | 矿场Phase3 B 关键词池 CRUD + 配置页 | ✅ PR #3666 merged，会话已释放 |
| ~~kimi4~~ | **#3641** | P1 | frontend | 超管驾驶舱·管线健康度 Tab 前端 | ✅ PR #3667 merged 2026-04-14T18:06:14Z |
| ~~kimi10~~ | #3483 | P0 | fullstack | 超管驾驶舱·安全审计Tab | ✅ PR #3668 merged 2026-04-14T18:58，会话已释放 |
| kimi8 | #3481 | P1 | fullstack | 实时日志流 Tab（CC/CI/API 集中查看）| Playwright smoke 调试中（log-stream spec 运行中）|
| kimi9 | #3482 | P1 | fullstack | FinOps 开发运维成本 Tab | PR 已创建，轮询 merge 中 |
| kimi16 | #3636 | P1 | fullstack | 矿场Phase4 E 幼儿园采购+预算专题 | smoke 2/3 过；getRouters 缺招投标中心父菜单（visible/status 或 role_menu 父链）调试中 |

> **2026-04-14 18:10 槽位释放 + 补池**：PR #3666 / #3667 先后 merged → kimi13/4 释放 → 补 kimi10 接 #3483 完成 PR #3668。
> **2026-04-14 19:55 当前活跃**：kimi8 (#3481)、kimi9 (#3482)、kimi16 (#3636) 共 3；kimi1/2 token 耗尽冷却至 2026-04-15。Flyway 链路 V185402~185405 / V190339~343 已由研发经理+排程经理联手封堵连环失败。
> **2026-04-14 20:5x 池快照刷新**：kimi17 #3639 PR#3671 merged → 释放；池 4/5（kimi1 #3637 + kimi8 #3481 + kimi9 #3482 + kimi16 #3638）。kimi17 可空位补派。
> **2026-04-14 21:25 池快照刷新**：kimi9 #3482 PR#3669 merged 21:04 + kimi1 #3637 PR#3672 merged 21:19 → 两会话释放。🚨 **事故**：bot 误关 #3481（PR#3672 body 裸引用触发），已 reopen + 回 In Progress；kimi8 session 已无但工作保留（feature-Issue-3481 + commit 6010d810 + 5 M 文件）。当前池 **1/5**（仅 kimi16 #3638 活跃）。补派需用户决策 kimi8 恢复方案（详见 docs/workflow/skill-update.md 2026-04-14 21:22 条目）。
