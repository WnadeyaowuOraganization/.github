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
> **📊 2026-04-14 22:47 #3631 子 Issue 进度**：**#3638 CLOSED ✅**，**#3636 终于派给 kimi5**（连续 12 轮 120 分钟待派后），#3631 全链只剩 #3636 in-progress，完成即 Master 收尾。
> **📊 2026-04-14 23:17 池快照**：#3519 PR#3675 merged 23:01 → kimi2 改派 **#3461 Tier-6 耀总驾驶舱 v1.0** 23:13。活跃：kimi1 #3518 / kimi2 **#3461** / kimi3 #3520 / kimi4 #3529 / kimi5 #3636。池 **5/5 满**。
> **📊 2026-04-15 00:18 池快照**：#3461 PR#3676 merged → kimi2 空闲。活跃 4/5：kimi1 #3518 / kimi3 #3520 / kimi4 #3529 / kimi5 #3636。建议 kimi2 接 **#3548 CRM-13 公司通讯录**（P1 fullstack medium，CRM Tier-4 批次轻量入口）。
> **📊 2026-04-15 00:35 池快照**：**#3518 PR#3677 merged 00:24 / #3520 PR#3678 merged 00:3x** → 研发经理 3 连派 CRM 批次：**kimi1 #3549 / kimi2 #3548 / kimi3 #3550**。活跃 **5/5 满**：kimi1 #3549 / kimi2 #3548 / kimi3 #3550 / kimi4 #3529 / kimi5 #3636。
> **📊 2026-04-15 00:45 池快照**：**#3529 PR#3679 merged 00:41** → kimi4 立即接 **#3551 CRM-12**。池 **5/5 满**：kimi1 #3549 / kimi2 #3548 / kimi3 #3550 / kimi4 **#3551** / kimi5 #3636。CRM Tier-4 批次（#3548/#3549/#3550/#3551）全部就位；#3551 merged 后 CRM-02 子矩阵收尾。
> **📊 2026-04-15 01:00 池快照**：**#3636 PR#3680 merged 00:5x**（kimi5 2h9m 刹车后按规范出脱，Flyway INSERT 合规）→ #3631 矿场 Master 收尾 ✅。kimi5 空闲，建议改派 **#3530 CRM-03 商机管道**（列表+看板双视图，P1 fullstack high）延续 CRM Tier-4 批次。活跃 4/5。
> **📊 2026-04-15 02:10 池快照**：**#3548 PR#3681 merged 02:0x** → kimi2 空闲。活跃 4/5：kimi1 #3549 / kimi3 #3550 / kimi4 #3551 / kimi5 #3530。建议 kimi2 接 **#3533 CRM-06 记录中心**（activity_log 四视角+周月报入口，P1 fullstack medium，独立性好不阻塞其他 CRM）。
> **📊 2026-04-15 03:15 池快照**：**#3551 PR#3682 merged 03:13** → kimi4 空闲。活跃 4/5：kimi1 #3549 / kimi2 #3533 / kimi3 #3550 / kimi5 #3530。建议 kimi4 接 **#3534 CRM-07 报表分析**（或 #3535 CRM-08 设置中心），P1 fullstack high，CRM Tier-4 延续。
> **✅ 2026-04-15 03:17 派发执行**：kimi4 接 **#3534 CRM-07 投标申请** effort=high（源 docs/design/crm-商务中心/07-bidding.html）→ 活跃恢复 5/5。同轮次 auto-heal：≥4 次阈值触发 menu-contract skill 硬化（commit 687d53d）+ 5 CCs tmux 通知 + kimi1 #3549 红线拦截（跨 scope 改已 merged Flyway）。
> **📊 2026-04-15 04:05 池快照**：**#3550 PR#3684 merged 04:02**（kimi3 3h30m 长跑后收尾）→ kimi3 被 bot 派去修 dev CI 红灯（#3636 kindergarten drawer 组件缺失），提 **PR#3685 hotfix** 中。待 PR#3685 merged 后再派发 #3535 或 #3583。活跃 4/5 + kimi3 收尾中。
> **📊 2026-04-15 04:15 池快照**：**PR#3685 hotfix merged 04:12** → kimi3 hotfix 完成并已退出会话。活跃 4/5：kimi1 #3549 / kimi2 #3533 / kimi4 #3534 / kimi5 #3530。kimi3 现可派发 **#3535 CRM-08 设置中心**（P1 fullstack medium，CRM Tier-4 最后一块）。
> **✅ 2026-04-15 04:13 派发执行**：kimi3 接 **#3535 CRM-08 回款跟踪**（周报强制+逾期提醒+连续未填警告，P1 fullstack medium）→ 池 5/5 满。追补 Issue **#3683**（#3550 Tab2/Tab4 统计图表拆分）已登记，待后续派发。
> **📊 2026-04-15 05:55 池快照**：**#3533 PR#3686 merged 05:48**（kimi2 CRM-06 记录中心）→ kimi2 空闲。活跃 4/5：kimi1 #3549 / kimi3 #3535 / kimi4 #3534 / kimi5 #3530。建议 kimi2 接 **#3683**（#3550 Tab2/Tab4 统计图表拆分追补，P1 frontend medium，独立不阻塞）或 #3583 P0 产品详情 3D。
> **⚠️ 2026-04-15 05:45 红线预警**：kimi5 #3530 运行时发现 **crm_customer 表缺 tenant_id 字段**（backend-schema skill 7 列硬约束违反）+ `/api/system/user/list` 404，kimi5 判定"后端问题与前端渲染无关"暂未修。建议研发经理核实是 #3527 漏列复现还是本环境缺失，必要时开 hotfix Issue。
> **📊 2026-04-15 06:35 池快照**：**#3549 PR#3687 merged 06:29**（kimi1 CRM-14 责任人变更日志）→ Issue #3549 仍 OPEN（CC 轮询等 close），kimi1 tmux 会话未退。⚠️ **#3526 CRM Master 被误关**（PR#3687 body 无 Closes 语法但 Issue 被关），排程经理已 **reopen + 恢复 In Progress**（Sprint-1 CRM 仍有 #3530/#3534/#3535 运行+#3683 追补）。活跃 4/5：kimi3 #3535 / kimi4 #3534 / kimi5 #3530 + kimi1 #3549（PR 已 merged 待 close）。建议 kimi2 接 **#3683**（追补），kimi1 close 后接 **#3583 P0 产品详情 3D** 或其他 CRM Tier-5。
> **📊 2026-04-15 06:53 池快照**：**#3549 已 CLOSED** → kimi1 会话退出。活跃 **3/5**（kimi3 #3535 / kimi4 #3534 / kimi5 #3530），kimi1+kimi2 双空闲（2 个空位）。已 notify 研发经理（id 1776236033524）：建议 kimi2 接 **#3683** 追补；kimi1 接 **#3531 CRM-04 商机详情**（P1 fullstack high）/ **#3583 P0 产品详情3D** / **#3585 备件目录** 之一。
> **✅ 2026-04-15 07:04 派发执行**：kimi2 接 **#3683** 追补（#3550 Tab2/Tab4 统计图表拆分，P1 frontend medium）；kimi1 接 **#3583 P0 产品详情 3D**（P0 frontend high）→ 池 5/5 满。同轮次干预：kimi5 #3530 Churn 1h43m 卡在'后端 tenant_id / /system/user/list 404 是否本 scope'已决策（非本 Issue scope，登记 PLAN.md 05:45 红线预警，30min 内必 push PR）；K2.6 评估 commit 3a7e5d8 已提交；清理 kimi3-3550 残留 tmux 会话。
> **⚠ 2026-04-15 07:08 派发纠错**：kimi1 开工后发现 **#3583 实际已随 PR#3664 于 2026-04-14 17:06 merged 交付**（与 #3640+#3582 同批），Issue CLOSED、分支与 dev 无差异。kimi1 正确触发"结论前 cc-report"规则未盲动。研发经理派发前只看 project 看板状态未查 Issue state 是根因（已登记 skill-update.md 07:08）。指令 kimi1 close 会话释放，下一轮 loop 重派稳定 Todo。当前池降为 **4/5**（kimi2/3/4/5 在线）。
> **✅ 2026-04-15 07:10 kimi1 重派**：kimi1 接 **#3531 CRM-04 商机详情页**（左摘要+右10Tab / 阶段自动推进 / 协同催办，fullstack P1 high），blocker #3527 CRM-DB + #3529 CRM-02 客户管理均 CLOSED，无阻塞。清理 kimi1 残留 .cc-lock 后通过 run-cc.sh 启动。池恢复 **5/5** 满。
> **🎉 2026-04-15 07:20 #3530 PR#3689 merged**：kimi5 CRM-03 商机管道（看板+列表双视图、新建商机弹窗）6h17m 交付。含中途红线 #13 干预（mv .claude/skills → git restore 恢复）+ rebase 冲突解决，最终 push 后 CI 绿自动 merge。kimi5 会话退出。
> **✅ 2026-04-15 07:21 kimi5 重派**：kimi5 接 **#3536 CRM-09 经销商管理**（合作级别/返点结算/销售目标跟踪，fullstack P1 high），blocker #3527/#3529 均 CLOSED。池恢复 **5/5** 满。
> **🎉 2026-04-15 07:50 #3534 PR#3690 merged**：kimi4 CRM-07 投标申请（审批流+中标录入）4h33m 交付。含中途红线 #13 触碰干预（rm -rf .claude/skills → git restore 恢复）+ API_TARGET 主机 IP 访问主 dev 红线 #3 告警。CI 全绿自动 merge，kimi4 会话退出。
> **✅ 2026-04-15 07:51 kimi4 重派**：kimi4 接 **#3532 CRM-05 询盘工作台**（5状态Tab/报价/转商机流程，fullstack P1 high），blocker #3527 CRM-DB CLOSED。池恢复 **5/5** 满。
> **🎉 2026-04-15 09:00 #3535 PR#3691 merged**：kimi3 CRM-08 回款跟踪（周报+逾期+警告）4h46m 交付，含偏离 scope 4h+ Churn（菜单基线）强干预 + mysql 裸 root 登记 + 429 TPP K2.6 耗尽 fallback。CI 全绿。
> **✅ 2026-04-15 09:01 kimi3 重派**：kimi3 接 **#3537 CRM-10 我的提成**（个人KPI+月度明细只读，fullstack P1 medium），blocker #3527 CLOSED。池恢复 **5/5** 满。
> **🎉 2026-04-15 09:10 #3536 PR#3692 merged**：kimi5 CRM-09 经销商管理 1h49m 交付（26 files, 2390 insertions），CI 全绿含 CodeRabbit。
> **✅ 2026-04-15 09:11 kimi5 重派**：kimi5 接 **#3580 产品门户 1/10 数据库表创建**（backend P1 medium，Sprint-2 标签但无 blocker，解锁下游 #3584/#3585/#3588）。CRM 主线 Todo 已派完（#3531/#3532/#3537 in progress），product-portal 系列 blocker #3580 先行。池恢复 **5/5** 满。
>
> **🎉 2026-04-15 12:17 双 PR 同批 merged #3695/#3696**：**#3537 CRM-10 我的提成**（kimi3 3h16m 交付，smoke 本地 vben getParentId 基线退化为静态截图+CI 真跑）+ **#3581 产品门户 2/10 展示 API**（kimi5 1h45m 交付 6 endpoints + S3 presigned + L0/L1 权限过滤 + Playwright API 7/7 绿）。CI 全绿自动 merge。kimi3 + kimi5 双会话退出，池降 **3/5**。
> 同轮次干预：
>   1. kimi3 #3537 smoke login ant-modal 拦截 → 退化为 /screenshot 静态 + CI 真跑（登记 skill-update 第 1 次观察中）
>   2. kimi4 #3532 esbuild 编译阻断根因定位 — `src/api/system/user.ts` 影子文件遮蔽完整的 user/index.ts（今早 hotfix #3693 同文件在主项目删过，kimi4 feature 分支未 rebase dev），指令 rm 该文件
>   3. kimi4 首次越界 `cp` 改动到主 wande-play（红线 #3 污染 access.ts）→ 研发经理 git restore 回滚 + 登记 skill-update P0 首次
>   4. pr-body-lint.sh 门 5 bug 修复（commit 586ab3e）：之前循环遍历所有 kimi 目录误报别家 behind，现仅查 caller 自己 pwd
>
> **🚀 2026-04-15 12:17 待派**：kimi3 + kimi5 双空位，活跃 3/5（kimi1 #3531 / kimi2 #3683 / kimi4 #3532）。Todo 队列只有 7 个且 frontend 类 #3585 blocked-by #3584（OPEN ExplodeView 集成），其余为 pipeline 类。**已 ping 排程经理从 Plan 列推新 Todo**。
>
> **🚀 2026-04-15 12:30 补池 4/5**：排程经理建议推 #3587（P1 backend 备件API+询价车，解锁 #3585 前端）。派 **kimi5 #3587**（blocked-by #3580✅/#3581✅ 均 merged，纯后端 CRUD+Flyway；"配前端"精神通过紧跟 #3585 实现）。kimi3 仍空闲等 #3587 merged 或现有 CC 释放解锁前端 Issue。
>
> **🔧 2026-04-15 12:28 kimi4 #3532 根因排查**：smoke 持续 404 非前端代码，而是 **vite dev server 实际绑 localhost:5670**（pid 3807557，kimi4 手动 `cd frontend && pnpm dev` 无 port 参数 → vite 默认 5666 递增到 5670），**8104 被遗留僵尸 LISTEN 占据返空骨架 HTML**。已 tmux 指令 kimi4 执行 `pkill -f vite + cc-test-env.sh stop/start kimi4` 标准重启 + 验证 8104 真绑 vite 再跑 smoke。
>
> **🎉 2026-04-15 12:55 PR #3697 merged**：**#3531 CRM-04 商机详情页 v1.0**（kimi1 5h42m + 两次 compact 超长跑，后端 Opportunity CRUD + 5 Tab + Vo/VO 命名统一）。kimi1 会话正常退出，池降 **3/5**（kimi2 #3683 / kimi4 #3532 / kimi5 #3587）。
>
> **🎉 2026-04-15 13:06 PR #3698 merged**：**#3532 CRM-05 询盘工作台**（kimi4 5h15m，5 状态 Tab + vxe-table + 报价/转商机/关闭弹窗；本地 smoke 因独立库 tenantId 默认填充问题退化为 /screenshot + CI 真跑，参照 #3537 退化方案）。CI 全绿自动 merge。kimi4 会话退出，池降 **2/5**（仅 kimi2 #3683 / kimi5 #3587）。kimi1/3/4 空闲，Todo 队列仍无可派（#3585 blocked-by #3587 kimi5 进行中），**再 ping 排程经理从 Plan 列推新 Todo**。
>
> **🚨 2026-04-15 12:50 排程经理修复 Flyway 撞号 dev c2918ad9**：今日 22 个 V20260415*.sql 中 4 对版本号重复（002000×3 / 003000×2 / 006000×2，006000 秒=60 非法暴露手挑数字），Flyway repair 失败 → 今日 0 条迁移落地 → 所有今日 CRM PR 后端 API 500。排程经理按 git commit 时间 rename 止血（002100/002200/003003/006100）+ DELETE 失败 flyway_schema_history。**blast radius 4 维度全中**。研发经理同步：(1) 广播 kimi2/5（kimi1 已退出/kimi4 已 rebase）`git fetch + rebase origin/dev + UPDATE flyway_schema_history 旧→新版本号`；(2) 更新 `backend-schema` skill 强制 `V{YYYYMMDDHHMMSS}_{Issue号}__{desc}.sql` 命名（Issue 号天然跨 CC 互斥，禁止手挑整数，commit push main）；(3) skill-update.md 登记为"一次即大面积阻塞不走频次阈值"第 2 个执行样本。
>
> **✅ 2026-04-15 10:32 kimi5 重派 #3581**：排程经理筛选 **#3581 产品门户 2/10 产品展示API**（P0 backend status:ready，blocker #3580 已 merged），6 个 Controller endpoint + AWS S3 presigned URL + L0/L1 权限过滤。kimi5 上下文连贯（刚做完产品门户 DB）。池恢复 **5/5** 满。merge 后可解锁 #3584 ExplodeView。
>
> **🎉 2026-04-15 10:22 #3580 PR#3694 merged**：kimi5 产品门户 1/10 数据库表 3 张（product/document/part）纯 DDL 1h10m 交付，CI 全绿，解锁下游 #3585/#3588 的 DB 依赖（#3584 仍阻塞）。kimi5 tmux 会话已关闭，池子降为 **4/5**。已 ping 排程经理从 Plan 列推新 Todo。
>
> **✅ 2026-04-15 10:22 hotfix #3693 部署成功**：run 24448885319 前端构建绿、dev 部署成功，主环境 localhost:8080 返回 200，今日 9 个 CRM PR（#3679/3682/3684/3686/3687/3689/3690/3691/3692）**全部可见**。
>
> **🚨 2026-04-15 10:15 P0 紧急止血 hotfix PR #3693**：用户发现"主环境看不见今日 CRM 合并"。排查发现 **PR #3689（CRM-03 商机管道）新建了 `frontend/apps/web-antd/src/api/system/user.ts`（15 行）与既有 `user/index.ts`（171 行）形成同名文件 vs 目录冲突**，Vite 别名 `#/api/system/user` 优先解析到 user.ts，导致 7 个消费方（dept/user/post/workflow 等）全部 build 失败。**今日 10 次 Dev 部署 CI 全 failed**，9 个 CRM PR（#3679/3682/3684/3686/3687/3689/3690/3691/3692）merged 但未部署。研发经理手动出 hotfix PR #3693（合并导出 + 删 user.ts），绕过 CC 池（紧急止血，无编程 CC 可用）。同步登记 docs/workflow/skill-update.md 等待是否需升级为 frontend-coding 红线。
>
> **🔄 2026-04-15 10:12 TPP 重启**：token-pool-proxy systemd 服务 10:07 restart（配置刷新为 infini:1/kimi:2/volcengine:1），kimi1/kimi2/kimi4/kimi5 之前 API Error 是重启窗口，已通过 tmux send-keys 通知继续推进。
> **♻ 清理**：已 CLOSED 的 #3517/#3481/#3482/#3483/#3484/#3519/#3638/#3582 及历史 #3624/#3630/#3632-#3635/#3637/#3639-#3641/#3640 从指派建议表移除。

| 目录 | Issue | 优先 | 模块 | 内容 | 原型/设计参考 | effort |
|------|-------|------|------|------|--------------|--------|
| kimi5 | **#3580** | P1 | backend | **[运行中]** 产品门户 1/10 数据库表创建（product_portal_product/document/part）Sprint-2 但无 blocker，09:11 启动，#3536 PR#3692 merged 09:10 后派发，解锁下游 #3584/#3585/#3588 | `docs/design/product-portal/详细设计.md` | medium |
| kimi1 | **#3531** | P1 | fullstack | **[运行中]** Tier-4 CRM-04 商机详情页（左摘要+右10Tab，阶段自动推进）07:10 启动，blocker #3527/#3529 均 CLOSED | `docs/design/crm-商务中心/04-opportunity-detail.html` | high |
| kimi2 | **#3683** | P1 | frontend | **[运行中]** #3550 Tab2/Tab4 统计图表拆分追补（07:04 启动，#3533 PR#3686 merged 05:48 后派发） | `docs/design/crm-商务中心/详细设计.md` | medium |
| kimi3 | **#3537** | P1 | fullstack | **[运行中]** Tier-4 CRM-10 我的提成 个人KPI+月度明细（只读，09:01 启动，#3535 PR#3691 merged 09:00 后派发） | `docs/design/crm-商务中心/详细设计.md §13` | medium |
| kimi4 | **#3532** | P1 | fullstack | **[运行中]** Tier-4 CRM-05 询盘工作台 5状态Tab+报价+转商机（07:51 启动，#3534 PR#3690 merged 07:50 后派发） | `docs/design/crm-商务中心/05-inquiry.html` | high |
| — | #3583 #3585 #3588 | P0/P1/P2 | frontend | Tier-5: 产品详情页（3D）/备件目录/H5 适配（#3582 已随 PR#3664 合并） | `docs/design/product-portal/02-detail.html` 等 | medium |

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
| kimi1 | ~~#3637~~ | P1 | fullstack | ~~矿场Phase4 F: 竞品关系网络可视化~~ PR#3672✅merged 2026-04-14 21:19 | ~~Done~~ |
| kimi9 | ~~#3482~~ | P1 | fullstack | ~~超管驾驶舱·FinOps开发运维成本看板~~ PR#3669✅merged 2026-04-14 21:04 | ~~Done~~ |
| kimi8 | ~~#3481~~ | P1 | fullstack | ~~超管驾驶舱·实时日志流Tab~~ PR#3673✅merged 2026-04-14 22:35 | ~~Done~~ |
| kimi16 | ~~#3638~~ | P1 | fullstack | ~~矿场Phase4 D: D3组件库 CRUD~~ PR#3674✅merged 2026-04-14 22:39 | ~~Done~~ |
| kimi1 | #3518 | P1 | fullstack | Tier-1: 支持中心主页Dashboard — 6个Widget | 22:42 |
| kimi2 | #3519 | P1 | fullstack | Tier-1: 项目安装主页Dashboard — 7个Widget | 22:42 |
| kimi3 | #3520 | P1 | fullstack | Tier-1: 综合管理主页Dashboard — 6个Widget | 22:42 |
| kimi4 | ~~#3582~~ | P0 | frontend | ~~Tier-5: 产品目录页前端~~ 已由 PR#3664 覆盖，kimi4 巡检确认空转→立即改派 #3529 | ~~Done~~ |
| kimi5 | ~~#3636~~ | P1 | fullstack | ~~矿场Phase4 E: 幼儿园采购+预算项目专题页~~ PR#3680✅merged 2026-04-15 00:5x | ~~Done~~ |
| kimi4 | #3529 | P1 | fullstack | Tier-4: CRM-02 客户管理 — CRUD+三类型+详情页五Tab | 22:48 |
| kimi2 | ~~#3519~~ | P1 | fullstack | ~~Tier-1: 项目安装主页Dashboard — 7 Widget~~ PR#3675✅merged 2026-04-14 23:01 | ~~Done~~ |
| kimi2 | #3461 | P0 | fullstack | Tier-6: 耀总驾驶舱v1.0 — 8大区块（矿场运营+团队+项目+财务+待办+复盘+市场+趋势） | 23:13 |
| kimi2 | ~~#3461~~ | P0 | fullstack | ~~Tier-6: 耀总驾驶舱v1.0~~ PR#3676✅merged 2026-04-15 00:18 | ~~Done~~ |
| kimi3 | ~~#3520~~ | P1 | fullstack | ~~Tier-1: 综合管理主页Dashboard — 6 Widget~~ PR#3678✅merged 2026-04-15 00:3x | ~~Done~~ |
| kimi1 | ~~#3518~~ | P1 | fullstack | ~~Tier-1: 支持中心主页Dashboard — 6 Widget~~ PR#3677✅merged 2026-04-15 00:24 | ~~Done~~ |
| kimi4 | ~~#3529~~ | P1 | fullstack | ~~Tier-4: CRM-02 客户管理 CRUD+三类型+详情五Tab~~ PR#3679✅merged 2026-04-15 00:41 | ~~Done~~ |
| kimi1 | ~~#3549~~ | P1 | fullstack | ~~Tier-4 CRM-14 责任人变更日志 — 审计追踪~~ PR#3687✅merged 2026-04-15 06:29 (+hotfix PR#3688 06:49 补 pnpm-lock) | ~~Done~~ |
| kimi2 | ~~#3548~~ | P1 | fullstack | ~~Tier-4 CRM-13 公司通讯录 — 全员联系人+部门树~~ PR#3681✅merged 2026-04-15 02:04 | ~~Done~~ |
| kimi2 | ~~#3533~~ | P1 | fullstack | ~~Tier-4 CRM-06 记录中心 — activity_log 四视角+周月报~~ PR#3686✅merged 2026-04-15 05:48 | ~~Done~~ |
| kimi3 | ~~#3550~~ | P1 | fullstack | ~~Tier-4 CRM-11 智能过会管理 — 异常驱动+三层节奏~~ PR#3684✅merged 2026-04-15 04:02 (Tab2/Tab4 拆至追补 #3683) | ~~Done~~ |
| kimi4 | ~~#3551~~ | P1 | fullstack | ~~Tier-4 CRM-12 授权管理 — 经销商授权+保证金+审批流~~ PR#3682✅merged 2026-04-15 03:13 | ~~Done~~ |
| kimi5 | ~~#3530~~ | P1 | fullstack | ~~Tier-4 CRM-03 商机管道 — 列表+看板双视图/7阶段/15种来源~~ PR#3689✅merged 2026-04-15 07:20 (含红线 #13 mv .claude/skills 干预 + rebase 冲突) | ~~Done~~ |
| kimi1 | ~~#3583~~ | P0 | frontend | ~~Tier-5 产品详情页 3D~~ 派发后 kimi1 发现已随 PR#3664 于 04-14 17:06 交付（cc-report 未盲动）→ 07:08 改派 #3531 | ~~Done（改派）~~ |
| kimi1 | ~~#3531~~ | P1 | fullstack | ~~Tier-4 CRM-04 商机详情页 v1.0（左摘要+右10Tab/阶段自动推进/协同催办）~~ PR#3697✅merged 2026-04-15 12:55 (5h42m) | ~~Done~~ |
| kimi5 | ~~#3536~~ | P1 | fullstack | ~~Tier-4 CRM-09 经销商管理（合作级别/返点/销售目标）~~ PR#3692✅merged 2026-04-15 09:06 (1h49m, 26 files) | ~~Done~~ |
| kimi4 | ~~#3534~~ | P1 | fullstack | ~~Tier-4 CRM-07 投标申请（审批流+中标录入）~~ PR#3690✅merged 2026-04-15 07:46 (4h33m, 含红线 #13 rm -rf + 红线 #3 主机 IP) | ~~Done~~ |
| kimi3 | ~~#3535~~ | P1 | fullstack | ~~Tier-4 CRM-08 回款跟踪（周报+逾期+警告）~~ PR#3691✅merged 2026-04-15 08:56 (4h46m, 含 4h+ Churn scope 强干预) | ~~Done~~ |
| kimi5 | ~~#3580~~ | P1 | backend | ~~产品门户 1/10 数据库表创建（product/document/part 3 表 DDL）~~ PR#3694✅merged 2026-04-15 10:19 (1h10m) | ~~Done~~ |
| kimi3 | ~~#3537~~ | P1 | fullstack | ~~Tier-4 CRM-10 我的提成（个人 KPI + 月度明细只读）~~ PR#3695✅merged 2026-04-15 12:16 (3h16m, smoke 退化为 /screenshot + CI 真跑) | ~~Done~~ |
| kimi5 | ~~#3581~~ | P0 | backend | ~~产品门户 2/10 产品展示 API（6 endpoints + S3 presigned + L0/L1 权限过滤）~~ PR#3696✅merged 2026-04-15 12:19 (1h45m, Playwright API 7/7 绿) | ~~Done~~ |
| kimi4 | ~~#3532~~ | P1 | fullstack | ~~Tier-4 CRM-05 询盘工作台（5 状态 Tab + 报价 + 转商机 + vxe-table）~~ PR#3698✅merged 2026-04-15 13:06 (5h15m, smoke 退化为 /screenshot + CI 真跑) | ~~Done~~ |
| kimi2 | ~~#3683~~ | P1 | frontend | ~~#3550 追补：Tab2 过会视图 + Tab4 月度 Pipeline 图表拆分~~ PR#3699✅merged 2026-04-15 21:44 CST (中途 #3683 被 PR#3684 bot 误关已 reopen + 后端 chat_model 缺列退化为静态截图 + gh pr create upstream 缺失修复) | ~~Done~~ |
| kimi5 | ~~#3587~~ | P1 | backend | ~~产品门户 8/10 备件 API + 询价购物车（纯后端 CRUD+Flyway）~~ PR#3700✅merged 2026-04-15 22:05 CST (~9h35m，含 JUnit 18/0 + Playwright API spec + 中途 token pool thinking 兼容兜底) | ~~Done~~ |
| kimi1 | ~~#3538~~ | P2 | backend | ~~CRM-CRON 回款周报逾期检测定时任务（每周五 9:00 标记未填合同 + 企微通知，CRM Master #3526 最后 1 个子 Issue，收尾 Sprint-1 CRM）~~ PR#3703✅merged 2026-04-15 14:36 | ~~Done~~ |
| kimi2 | ~~#3701~~ | 🔥P0 | fullstack | ~~CRM 11 子页白屏修复（`src/api/crm/opportunity.ts` 补 3 export: createOpportunity/getOpportunityKanban/advanceOpportunityStage + 11 `/views/business/crm/**/index.vue` 恢复 `<Page>` 容器，/business/tender/mining 同根因）~~ PR#3704✅merged 2026-04-15 15:07 | ~~Done~~ |
| kimi3 | #3584 | P0 | frontend | 产品门户 5/10 ExplodeView 集成 + G7e Docker 部署 + STEP 批量处理 Pipeline | 22:06 启动，blocker #3580/#3581 均 CLOSED |
| kimi4 | #3586 | P1 | fullstack | 产品门户 7/10 资料下载 S3 presigned URL 分级 | 22:06 启动，blocker #3580/#3581 均 CLOSED，22:08 cc-report 中等复杂度 |
| kimi5 | ~~#1697~~ | P2 | backend | ~~报销费控 7 张表 schema 建表（纯 Flyway，Sprint-4 预研）~~ PR#3702✅merged 2026-04-15 22:18 CST (~8m 惊人效率) | ~~Done~~ |
| kimi5 | #1693 | P2 | backend | 报销费控 报销单+借款 CRUD API（依赖 #1697 7 表已 land） | 22:25 启动，Issue body 含 @DS 多数据源注解需忽略（单库架构），排程经理预估 2.5-3h |

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

### 📍 2026-04-15 23:10 当前池快照（3/15 活跃）

**kimi1 + kimi2 已释放**（#3538 merged 14:36，#3701 merged 15:07）。**池子降为 3/15**，可派 12 位。

| 指派目录 | Issue | 优先级 | 模块 | 内容 | 阶段 |
|---------|-------|-------|------|------|------|
| ~~kimi2~~ | ~~#3701~~ | 🔥P0 | fullstack | ~~CRM 11 子页白屏修复~~ PR#3704 merged 15:07 | ~~Done~~ |
| kimi3 | #3584 | P0 | frontend | 产品门户 5/10 ExplodeView 集成 + G7e Docker 部署 + STEP Pipeline | Forging 中（1h 7m，还有 31m 40s），34% 进度，正常 |
| kimi4 | #3586 | P1 | fullstack | 产品门户 7/10 资料下载 S3 presigned URL 分级 | 22:06 启动，49% 进度中 |
| kimi5 | #1693 | P2 | backend | 报销费控 报销单+借款 CRUD API（依赖 #1697 7 表 merged） | 22:25 启动 |

> **巡检处置**：
> - kimi3 #3584 正在思考（Forging），长时间无输出但进度正常，无需介入
> - e2e-top 56min 无新输出，已注入"继续全量回归"指令（需观察是否接受）
> - **建议派发**：kimi1/kimi2 空位，但 #3585/#3588 均 blocked-by #3584，待其 merged；pipeline Issue 独立排程

> **2026-04-14 18:10 槽位释放 + 补池**：PR #3666 / #3667 先后 merged → kimi13/4 释放 → 补 kimi10 接 #3483 完成 PR #3668。
> **2026-04-14 19:55 当前活跃**：kimi8 (#3481)、kimi9 (#3482)、kimi16 (#3636) 共 3；kimi1/2 token 耗尽冷却至 2026-04-15。Flyway 链路 V185402~185405 / V190339~343 已由研发经理+排程经理联手封堵连环失败。
> **2026-04-14 20:5x 池快照刷新**：kimi17 #3639 PR#3671 merged → 释放；池 4/5（kimi1 #3637 + kimi8 #3481 + kimi9 #3482 + kimi16 #3638）。kimi17 可空位补派。
> **2026-04-14 21:25 池快照刷新**：kimi9 #3482 PR#3669 merged 21:04 + kimi1 #3637 PR#3672 merged 21:19 → 两会话释放。🚨 **事故**：bot 误关 #3481（PR#3672 body 裸引用触发），已 reopen + 回 In Progress；kimi8 session 已无但工作保留（feature-Issue-3481 + commit 6010d810 + 5 M 文件）。当前池 **1/5**（仅 kimi16 #3638 活跃）。补派需用户决策 kimi8 恢复方案（详见 docs/workflow/skill-update.md 2026-04-14 21:22 条目）。
