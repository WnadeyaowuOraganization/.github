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
| ~~#3597~~ | ~~P0~~ | ~~backend~~ | ~~菜单基线Flyway脚本验证~~ ✅ CLOSED | ~~Done~~ | V2脚本已提交，需启动后端验证Flyway执行 |
| ~~#3613~~ | ~~P0~~ | ~~fullstack~~ | ~~CRM菜单component/perms前缀整改~~ ✅ CLOSED | ~~Done~~ | CRM菜单 wande/crm→business/crm, crm:→biz:crm: |

> **验收标准**：后端启动成功 + 8大工作区侧边栏正确 + 角色权限正确 + CRM菜单前缀符合规范

---

## Tier-1：RBAC角色主页体系（依赖Tier-0菜单基线）

> 设计文档：`docs/design/rbac-homepage/详细设计.md`
> 每个角色登录后看到自己的Dashboard主页

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| ~~#3522~~ | ~~P1~~ | ~~fullstack~~ | ~~Dashboard Widget配置表 + 动态渲染引擎~~ ✅ CLOSED | ~~Done~~ | #3597 |
| ~~#3517~~ | ~~P0~~ | ~~fullstack~~ | ~~商务主页Dashboard — 8个Widget~~ ✅ CLOSED | ~~Done~~ | #3522 |
| ~~#3518~~ | ~~P1~~ | ~~fullstack~~ | ~~支持中心主页Dashboard — 6个Widget~~ ✅ CLOSED | ~~Done~~ | #3522 |
| ~~#3519~~ | ~~P1~~ | ~~fullstack~~ | ~~项目安装主页Dashboard — 7个Widget~~ ✅ CLOSED | ~~Done~~ | #3522 |
| ~~#3520~~ | ~~P1~~ | ~~fullstack~~ | ~~综合管理主页Dashboard — 6个Widget~~ ✅ CLOSED | ~~Done~~ | #3522 |
| ~~#3521~~ | ~~P1~~ | ~~frontend~~ | ~~Boss耀总Dashboard — 8大板块导航页~~ ✅ CLOSED | ~~Done~~ | #3522 |

> **并行策略**：#3522引擎完成后，#3517~#3521可并行开发（5个CC同时）

---

## Tier-2：全球项目矿场（业务最重要，菜单完成后优先启动）

> 设计文档：`docs/design/全球项目矿场/详细设计.md` + 6个HTML原型
> Master Issue: #3458
> **优先级说明**：用户需求优先，完成菜单基线后立即推进

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| ~~#3458~~ | ~~P0~~ | ~~fullstack~~ | ~~全球项目矿场v3.0 — 基于确认原型的完整改版~~ ✅ PR#3606 merged | ~~Done~~ | #3597(菜单基线) |
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
| ~~#3466~~ | ~~P0~~ | ~~fullstack~~ | ~~超管驾驶舱Master — 框架验证~~ ✅ CLOSED | ~~Done~~ | #3597 |
| ~~#3481~~ | ~~P1~~ | ~~fullstack~~ | ~~实时日志流Tab~~ ✅ CLOSED | ~~Done~~ | #3466验证 |
| ~~#3482~~ | ~~P1~~ | ~~fullstack~~ | ~~FinOps开发运维成本Tab~~ ✅ CLOSED | ~~Done~~ | #3466验证 |
| ~~#3483~~ | ~~P1~~ | ~~fullstack~~ | ~~安全审计Tab~~ ✅ CLOSED | ~~Done~~ | #3466验证 |
| ~~#3484~~ | ~~P1~~ | ~~fullstack~~ | ~~Prompt管理Tab~~ ✅ CLOSED | ~~Done~~ | #3466验证 |

> **并行策略**：#3466验证后，4个Tab可并行开发

---

## Tier-4：CRM商务中心（依赖Tier-0 + Tier-1商务主页）

> 设计文档：`docs/design/crm-商务中心/详细设计.md` + `crm-商务工作台/` + `crm-商机详情页/`
> Master Issue: #3526
> **串行执行**：CRM-01→13按编号顺序，后续模块依赖前序数据表

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| ~~#3526~~ | ~~P0~~ | ~~fullstack~~ | ~~CRM商务中心Master — Sprint-1 总协调~~ ✅ CLOSED | ~~Done~~ | #3597 |
| ~~#3527~~ | ~~P0~~ | ~~backend~~ | ~~CRM-DB 数据库基础建表 — Flyway迁移脚本(9张表)~~ ✅ CLOSED | ~~Done~~ | #3526 |
| ~~#3528~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-01 商务工作台 — KPI+收件箱+业绩面板~~ ✅ CLOSED | ~~Done~~ | #3527 |
| ~~#3529~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-02 客户管理 — CRUD+三类型+详情页~~ ✅ CLOSED | ~~Done~~ | #3528 |
| ~~#3530~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-03 商机管道 — 列表+看板+7阶段~~ ✅ CLOSED | ~~Done~~ | #3529 |
| ~~#3531~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-04 商机详情页 — 10Tab+阶段推进~~ ✅ CLOSED | ~~Done~~ | #3530 |
| ~~#3532~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-05 询盘工作台 — 5状态+报价+转商机~~ ✅ CLOSED | ~~Done~~ | #3529 |
| ~~#3533~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-06 记录中心 — 四视角+周报月报~~ ✅ CLOSED | ~~Done~~ | #3529 |
| ~~#3534~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-07 投标申请 — 审批流+中标结果~~ ✅ CLOSED | ~~Done~~ | #3530 |
| ~~#3535~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-08 回款跟踪 — 周报+逾期提醒~~ ✅ CLOSED | ~~Done~~ | #3530 |
| ~~#3536~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-09 经销商管理 — 级别/返点/目标~~ ✅ CLOSED | ~~Done~~ | #3529 |
| ~~#3537~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-10 我的提成 — KPI+月度明细~~ ✅ CLOSED | ~~Done~~ | #3528 |
| ~~#3548~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-13 公司通讯录 — 全员联系人+部门树~~ ✅ CLOSED | ~~Done~~ | #3526 |
| ~~#3549~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-14 责任人变更日志 — 线索/商机/客户变更审计~~ ✅ CLOSED | ~~Done~~ | #3529 |
| ~~#3550~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-11 智能过会 — 异常驱动+过会视图~~ ✅ CLOSED | ~~Done~~ | #3530 |
| ~~#3551~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-12 授权管理 — 经销商授权+审批~~ ✅ CLOSED | ~~Done~~ | #3536 |

> **并行窗口**：#3529完成后可并行 #3530/#3532/#3533/#3536；#3530完成后可并行 #3531/#3534/#3535/#3550

---

## Tier-5：经销商产品展示门户（独立，可与Tier-3/4并行）

> 设计文档：`docs/design/product-portal/详细设计.md` + 3个HTML原型
> Master Issue: #3579

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| ~~#3579~~ | ~~P1~~ | ~~fullstack~~ | ~~产品门户Master — 路由+权限+布局~~ ✅ CLOSED | ~~Done~~ | #3597 |
| ~~#3582~~ | ~~P0~~ | ~~frontend~~ | ~~产品目录页 — 卡片网格+筛选搜索~~ ✅ CLOSED | ~~Done~~ | #3579 |
| ~~#3583~~ | ~~P0~~ | ~~frontend~~ | ~~产品详情页 — 参数+3D查看器~~ ✅ CLOSED | ~~Done~~ | #3582 |
| #3584 | P0 | fullstack | ExplodeView集成+G7e Docker部署+STEP批量处理Pipeline | 🔄 In Progress | #3583 |
| ~~#3587~~ | ~~P1~~ | ~~backend~~ | ~~备件API + 询价购物车 CRUD~~ ✅ CLOSED | ~~Done~~ | #3579 |
| #3585 | P1 | frontend | 备件目录页+爆炸图联动 | ⏳ blocked-by #3584 | #3584 |
| #3586 | P1 | fullstack | 资料下载S3 presigned URL分级 | 🔄 In Progress | #3579 |
| #3588 | P2 | frontend | H5移动端适配 | ⏳ blocked-by #3584 | #3584 |

> **并行策略**：Tier-5与Tier-2/3/4完全独立，可同时启动

---

## Tier-6：耀总驾驶舱（依赖Tier-1 Boss Dashboard）

> 设计文档：`docs/design/耀总驾驶舱/详细设计.md` + 12个HTML原型
> Master Issue: #3461

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| ~~#3461~~ | ~~P1~~ | ~~fullstack~~ | ~~耀总驾驶舱v1.0 — 8大区块~~ ✅ CLOSED | ~~Done~~ | ~~#3521(Boss Dashboard)~~ CLOSED |

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

| 目录 | Issue | 优先 | 模块 | 内容 | 原型/设计参考 | effort |
|------|-------|------|------|------|--------------|--------|
| ~~kimi5~~ | ~~#3580~~ | ~~P1~~ | ~~backend~~ | ~~产品门户 1/10 数据库表创建~~ PR#3694✅ | — | ~~medium~~ |
| ~~kimi1~~ | ~~#3531~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-04 商机详情页 v1.0~~ PR#3697✅ | — | ~~high~~ |
| ~~kimi2~~ | ~~#3683~~ | ~~P1~~ | ~~frontend~~ | ~~#3550 Tab2/Tab4 图表拆分追补~~ PR#3699✅ | — | ~~medium~~ |
| ~~kimi3~~ | ~~#3537~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-10 我的提成~~ PR#3695✅ | — | ~~medium~~ |
| ~~kimi4~~ | ~~#3532~~ | ~~P1~~ | ~~fullstack~~ | ~~CRM-05 询盘工作台~~ PR#3698✅ | — | ~~high~~ |
| kimi1 | **#3706** | P0 | backend | **[运行中]** 执行管理 [1/22] 执行项目实体+CRUD+列表API+统计API，00:27启动 | `docs/design/execution-mgmt/详细设计.md` | medium |
| kimi5 | **#3707** | P0 | backend | **[运行中]** 执行管理 [2/22] 阶段配置API（直销12/经销8/国贸10阶段），00:27启动 | `docs/design/execution-mgmt/详细设计.md` | medium |
| kimi2 | **#3708** | P0 | frontend | **[运行中]** 执行管理 [3/22] 列表页 KPI卡片+筛选+表格（mock优先），00:27启动 | `docs/design/execution-mgmt/详细设计.md` | medium |
| kimi3 | **#3584** | P0 | frontend | **[运行中]** 产品门户 [5/10] ExplodeView集成+G7e Docker+STEP批量处理，22:06启动 | `docs/design/product-portal/02-detail.html` | high |
| kimi4 | **#3586** | P1 | fullstack | **[运行中]** 产品门户 [7/10] 资料下载S3 presigned URL分级，22:06启动 | `docs/design/product-portal/详细设计.md` | medium |
| ~~kimi3~~ | ~~#3585~~ | ~~P1~~ | ~~frontend~~ | ~~产品门户 [6/10] 备件目录页+爆炸图联动~~ #3584 PR#3733 merged后00:58启动 | `docs/design/product-portal/06-parts.html` | ~~medium~~ |
| — | **#3709** | P0 | frontend | 执行管理 [4/22] 详情页框架8-Tab容器+路由 ⏳ #3708合并后派 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3715+#3718 | P0 | backend+frontend | 执行管理 [10+13/22] 回款计划API+Tab6回款前端（mock配对）⏳ #3706合并后批量派 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3716+#3719 | P0 | backend+frontend | 执行管理 [11+14/22] 文档中心API+Tab7文档+360看板（mock配对）⏳ #3706合并后批量派 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3713+#3714+#3717 | P0 | backend+frontend | 执行管理 [8+9+12/22] 合同API+交付节点API+Tab3合同与交付 ⏳ #3706合并后批量派 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3720+#3721+#3723 | P0 | backend+frontend | 执行管理 [15+16+18/22] BOM树+工艺路线+Tab4甘特图 ⏳ #3706合并后批量派 | `docs/design/execution-mgmt/详细设计.md` | high |
| — | #3710+#3711 | P0 | frontend | 执行管理 [5+6/22] Tab1概览+Tab2阶段进度 ⏳ #3709+#3706+#3707全合并后 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3712 | P0 | fullstack | 执行管理 [7/22] 阶段推进+审批引擎D66对接 ⏳ #3707+#3711合并后 | `docs/design/execution-mgmt/详细设计.md` | high |
| — | #3722+#3724 | P0 | backend+frontend | 执行管理 [17+19/22] 变更管理API+Tab5变更 ⏳ #3706+#3712合并后 | `docs/design/execution-mgmt/详细设计.md` | medium |
| — | #3725+#3726+#3727 | P0 | backend+frontend | 执行管理 [20+21+22/22] 验收+质保API+Tab8售后质保 ⏳ Wave4末尾 | `docs/design/execution-mgmt/详细设计.md` | medium |

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
| ~~kimi3~~ | ~~#3584~~ | P0 | frontend | ~~产品门户 5/10 ExplodeView 集成 + G7e Docker 部署 + STEP 批量处理 Pipeline~~ PR#3733✅merged 2026-04-15 16:54 | ~~Done~~ |
| ~~kimi4~~ | ~~#3586~~ | P1 | fullstack | ~~产品门户 7/10 资料下载 S3 presigned URL 分级~~ PR#3735✅merged 2026-04-15 17:12 | ~~Done~~ |
| kimi5 | ~~#1697~~ | P2 | backend | ~~报销费控 7 张表 schema 建表（纯 Flyway，Sprint-4 预研）~~ PR#3702✅merged 2026-04-15 22:18 CST (~8m 惊人效率) | ~~Done~~ |
| ~~kimi5~~ | ~~#1693~~ | P2 | backend | ~~报销费控 报销单+借款 CRUD API（依赖 #1697 7 表已 land，Issue body 含 @DS 需忽略单库架构）~~ PR#3730✅merged 2026-04-15 16:05 | ~~Done~~ |
| kimi1 | ~~#3728~~ | 🔥P0 | frontend | ~~CRM 13子页白屏回归验证 — #3701+#3705修复后复查，kimi1独立环境重现+修复+Playwright smoke~~ PR#3729✅merged 2026-04-16 00:01 | ~~Done~~ |
| ~~kimi2~~ | ~~#2419~~ | P0 | backend | ~~pipeline DB Schema — wdpp_dealer_candidates + wdpp_intl_buyer_candidates~~ PR#3731✅merged 2026-04-16 00:14 | ~~Done~~ |
| ~~kimi1~~ | ~~#3706~~ | P0 | backend | ~~执行管理v2.0 [1/22] 执行项目实体+CRUD+列表API+统计API~~ PR#3736✅merged 2026-04-15 17:16 | ~~Done~~ |
| ~~kimi5~~ | ~~#3707~~ | P0 | backend | ~~执行管理v2.0 [2/22] 阶段配置+阶段进度API（三种业务模式：直销12/经销8/国贸10阶段）~~ PR#3737✅merged 2026-04-15 17:19 | ~~Done~~ |
| ~~kimi1~~ | ~~#3715~~ | P0 | backend | ~~执行管理v2.0 [10/22] 回款计划+Checklist+催收API~~ PR#3740✅merged 2026-04-16 02:12 | ~~Done~~ |
| ~~kimi5~~ | ~~#3718~~ | P0 | frontend | ~~执行管理v2.0 [13/22] Tab6 回款前端（mock配对）~~ PR#3739✅merged 2026-04-15 17:41 | ~~Done~~ |
| ~~kimi2~~ | ~~#3708~~ | P0 | frontend | ~~执行管理v2.0 [3/22] 前端列表页（KPI卡片+筛选+项目表格），mock数据先行~~ PR#3734✅merged 2026-04-15 17:06 | ~~Done~~ |
| ~~kimi3~~ | ~~#3585~~ | P1 | frontend | ~~产品门户 6/10 备件目录页+爆炸图联动（PartCatalog.vue）~~ PR#3741✅merged 2026-04-16 02:25 | ~~Done~~ |
| ~~kimi2~~ | ~~#3709~~ | P0 | frontend | ~~执行管理v2.0 [4/22] 详情页框架 8-Tab容器+路由~~ PR#3738✅merged 2026-04-15 17:35 | ~~Done~~ |
| ~~kimi4~~ | ~~#3716~~ | P0 | backend | ~~执行管理v2.0 [11/22] 文档中心API（文档上传+分类+权限）~~ PR#3746✅merged 2026-04-16 03:07 | ~~Done~~ |
| ~~kimi2~~ | ~~#3710~~ | P0 | frontend | ~~执行管理v2.0 [5/22] Tab1项目概览（横向流程图+基础信息+指标）~~ PR#3742✅merged 2026-04-16 02:19 | ~~Done~~ |
| ~~kimi5~~ | ~~#3711~~ | P0 | frontend | ~~执行管理v2.0 [6/22] Tab2阶段进度（垂直时间线+里程碑+推进按钮）~~ PR#3744✅merged 2026-04-16 02:47 | ~~Done~~ |
| ~~kimi5~~ | ~~#3714~~ | ~~P0~~ | ~~backend~~ | ~~执行管理v2.0 [9/22] 交付节点API（里程碑+发货批次），配对#3717前端~~ PR#3751✅merged 2026-04-16 04:22 | ~~Done~~ |
| ~~kimi5~~ | ~~#3588~~ | ~~P2~~ | ~~frontend~~ | ~~产品门户 [9/10] H5移动端适配（产品目录/详情/备件三页）~~ PR#3753✅merged | ~~Done~~ |
| ~~kimi5~~ | ~~#1925~~ | P0 | pipeline | ~~[D3-v2.0] AI知识库扩充（产品参数/安全标准/安装规范/历史项目）~~ PR#3758✅merged | ~~Done~~ |
| ~~kimi5~~ | ~~#1865~~ | P1 | pipeline | ~~[D3-AI] 设计师知识画像与自适应教学（ITS学员模型）~~ PR#3765✅merged | ~~Done~~ |
| ~~kimi5~~ | ~~#1467~~ | P1 | backend | ~~[商务赋能知识中台][25/28] 安装说明自动生成~~ PR#3772✅merged 2026-04-16T00:36:10Z | ~~Done~~ |
| ~~kimi1~~ | ~~#3719~~ | P0 | frontend | ~~执行管理v2.0 [14/22] Tab7文档中心（360看板+分类树+文档列表）~~ PR#3743✅merged 2026-04-16 03:10 | ~~Done~~ |
| ~~kimi1~~ | ~~#3723~~ | ~~P0~~ | ~~frontend~~ | ~~执行管理v2.0 [18/22] Tab4甘特图+BOM预览（前端），mock配对#3720/#3721~~ PR#3749✅merged 2026-04-16 04:02 | ~~Done~~ |
| ~~kimi1~~ | ~~#3724~~ | ~~P1~~ | ~~frontend~~ | ~~执行管理v2.0 [19/22] Tab5变更管理（KPI+列表+详情），mock配对#3722~~ PR#3752✅merged 2026-04-16 04:23 | ~~Done~~ |
| ~~kimi1~~ | ~~#3552~~ | ~~P0~~ | ~~backend~~ | ~~[矿场修复] 6个管线脚本表名不兼容修复（Python脚本wdpp_前缀）~~ PR#3755✅merged 2026-04-16 04:48 | ~~Done~~ |
| ~~kimi1~~ | ~~#3117~~ | P1 | fullstack | ~~[经销商发现] 经销商-甲方客户关系图谱（可视化关联关系）~~ PR#3759✅merged | ~~Done~~ |
| ~~kimi1~~ | ~~#3726~~ | P2 | backend | ~~执行管理v2.0 [21/22] 质保+售后工单+设备档案API~~ PR#3769✅merged（SaCheckPermission import hotfix dev 直推修复） | ~~Done~~ |
| ~~kimi2~~ | ~~#3717~~ | ~~P0~~ | ~~frontend~~ | ~~执行管理v2.0 [12/22] Tab3合同与交付（合同状态+交付节点+发货跟踪）~~ PR#3747✅merged 2026-04-16 03:18 | ~~Done~~ |
| ~~kimi2~~ | ~~#3721~~ | ~~P0~~ | ~~backend~~ | ~~执行管理v2.0 [16/22] 工艺路线+设备进度矩阵API~~ PR#3754✅merged 2026-04-16 04:41 | ~~Done~~ |
| ~~kimi2~~ | ~~#3133~~ | P0 | backend | ~~[审批引擎] 审批节点回退增强（回退到指定节点+直达模式）~~ PR#3756✅merged | ~~Done~~ |
| ~~kimi2~~ | ~~#2417~~ | P1 | pipeline | ~~[经销商发现-2/4] 竞品官网经销商网络采集脚本~~ PR#3760✅merged | ~~Done~~ |
| ~~kimi2~~ | ~~#1736~~ | P1 | frontend | ~~执行管理 验收列表+阶段配置+发起验收页面（配对#3725）~~ PR#3766✅merged 23:09 | ~~Done~~ |
| ~~kimi2~~ | ~~#1732~~ | P1 | frontend | ~~[执行管理] 变更管理Tab前端（对接#3722真实API）~~ PR#3771✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#3713~~ | P0 | backend | ~~执行管理v2.0 [8/22] 合同信息API（关联crm_contract）~~ PR#3745✅merged 2026-04-16 02:54 | ~~Done~~ |
| ~~kimi3~~ | ~~#3712~~ | ~~P0~~ | ~~fullstack~~ | ~~执行管理v2.0 [7/22] 阶段推进+审批引擎D66对接~~ PR#3748✅merged 2026-04-16 04:08 | ~~Done~~ |
| ~~kimi3~~ | ~~#3722~~ | P1 | backend | ~~执行管理v2.0 [17/22] 变更管理API（记录+影响分析+审批）~~ PR#3757✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#2492~~ | P1 | pipeline | ~~[D3参数化] 欧美竞品产品参数采集(KOMPAN/HAGS/Playcraft)~~ PR#3761✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#2700~~ | P1 | pipeline | ~~[商战情报中台] 早期项目信号检测~~ PR#3763✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#2701~~ | P1 | pipeline | ~~[商战情报中台] 买家行为画像·甲方偏好分析~~ PR#3770✅merged 2026-04-16T00:21 | ~~Done~~ |
| ~~kimi4~~ | ~~#3716~~ | P0 | backend | ~~执行管理v2.0 [11/22] 文档中心API~~ PR#3746✅merged 2026-04-16 03:07 | ~~Done~~ |
| ~~kimi4~~ | ~~#3720~~ | ~~P0~~ | ~~backend~~ | ~~执行管理v2.0 [15/22] BOM树API（BOM结构+工序路线，高复杂度）~~ PR#3750✅merged 2026-04-16 04:14 | ~~Done~~ |
| ~~kimi4~~ | ~~#3725~~ | P0 | backend | ~~执行管理v2.0 [20/22] 验收管理API（5级验收+检查项）~~ PR#3762✅merged | ~~Done~~ |
| ~~kimi4~~ | ~~#3727~~ | P2 | frontend | ~~执行管理v2.0 [22/22] Tab8 售后质保前端~~ PR#3764✅merged | ~~Done~~ |
| ~~kimi4~~ | ~~#1531~~ | P1 | backend | ~~[矿场增强] 可赢性评分模型(Win Probability) — 4维度综合赢率计算~~ PR#3767✅merged 23:19 | ~~Done~~ |
| ~~kimi4~~ | ~~#1532~~ | P1 | backend | ~~[矿场增强] 矿场转化漏斗统计API~~ | PR#3768✅merged 00:58 | ~~Done~~ |
| ~~kimi1~~ | ~~#240~~ | P1 | fullstack | ~~[项目中心-P1] Phase6 [6/12]: 项目费用归集~~ | PR#3775✅merged | ~~Done~~ |
| ~~kimi2~~ | ~~#1524~~ | P1 | backend | ~~[D3-缺陷修复][P1][6/7] ComponentDependencyGraph DAG构建逻辑补全~~ | PR#3774✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#1586~~ | P1 | backend | ~~[制度管理][1/22] 数据模型 — 6张表Flyway~~ | PR#3773✅merged 00:51 | ~~Done~~ |
| ~~kimi5~~ | ~~#1585~~ | P1 | backend | ~~[制度管理][2/22] 制度分类树CRUD API~~ | PR#3776✅merged 01:44 | ~~Done~~ |
| kimi5 | #1582 | P1 | backend | [制度管理][5/22] 制度审批流API | curl验证✅（tenant_id修复）→ JUnit + Playwright API中 |
| ~~kimi1~~ | ~~#1522~~ | P1 | backend | ~~[方案引擎×D3][P1] 选型桥接JSON接口~~ | PR#3777✅merged 01:56 | ~~Done~~ |
| ~~kimi1~~ | ~~#1581~~ | P1 | backend | ~~[制度管理][9/22] 制度发布+员工签收API~~ | PR#3780✅merged 02:41 | ~~Done~~ |
| ~~kimi1~~ | ~~#2282~~ | P1 | frontend | ~~[制度管理][8/22] 制度富文本编辑器~~ | PR#3782✅merged（hotfix import修复 0441473e）|
| ~~kimi1~~ | ~~#1577~~ | P1 | backend | ~~[制度管理][15/22] 制度废止+归档API~~ | PR#3784✅merged | ~~Done~~ |
| ~~kimi1~~ | ~~#1579~~ | P1 | backend | ~~[制度管理][11/22] 签收记录导出（举证包PDF）~~ | PR#3787✅merged 2026-04-16T04:32（经理手动解冲突×3 rebase）| ~~Done~~ |
| ~~kimi2~~ | ~~#1584~~ | P1 | backend | ~~[制度管理][3/22] 制度文档CRUD API~~ | PR#3778✅merged 02:10 | ~~Done~~ |
| ~~kimi2~~ | ~~#2284~~ | P1 | frontend | ~~[制度管理][6/22] 制度管理中心页面（综管端）~~ | PR#3781✅merged 02:35（⚠️Bean冲突hotfix 9b7bf0de已推dev）| ~~Done~~ |
| ~~kimi2~~ | ~~#2281~~ | P1 | frontend | ~~[制度管理][12/22] 员工制度查阅+签收页面~~ | PR#3785✅merged 2026-04-16T04:10（经理手动解冲突policy.ts rebase）| ~~Done~~ |
| kimi2 | #1593 | P1 | backend | [预算][21/32] 预算执行率自动计算+分级预警 | 11:53启动 |
| ~~kimi3~~ | ~~#1583~~ | P1 | backend | ~~[制度管理][4/22] 制度版本控制API~~ | PR#3779✅merged | ~~Done~~ |
| ~~kimi3~~ | ~~#2283~~ | P1 | frontend | ~~[制度管理][7/22] 制度详情+版本历史页面~~ | PR#3783✅merged 03:46 | ~~Done~~ |
| ~~kimi3~~ | ~~#2280~~ | P1 | fullstack | ~~[制度管理][13/22] 签收统计面板~~ | PR#3786✅merged 2026-04-16T04:29（经理手动解冲突×2 rebase）| ~~Done~~ |
| ~~kimi4~~ | ~~#1542~~ | P1 | budget | ~~[预算模板增强 4/12] 项目级科目增删（含补建4张依赖表）~~ | PR#3788✅merged 2026-04-16T04:49 | ~~Done~~ |
| ~~kimi2~~ | ~~#1593~~ | P1 | backend | ~~[预算][21/32] 预算执行率自动计算+分级预警~~ | PR#3789✅merged 2026-04-16T05:34 | ~~Done~~ |
| kimi1 | #1574+#2277 | P2 | fullstack | [制度管理][19+21/22] 条款库CRUD后端+条款库管理页面 | 12:41启动 → import修复✅ Playwright中（mvn install修复注入） |
| kimi2 | #1588+#1589 | P1 | fullstack | [预算][28+27/32] 金蝶凭证格式导出+历史成本基准查询 | 13:41启动 |
| ~~kimi3~~ | ~~#1576+#2278~~ | P2 | fullstack | ~~[制度管理][17+20/22] AI模板库+AI起草向导~~ | PR#3790✅merged（hotfix×3: layout/policy.ts×2 止血）| ~~Done~~ |
| kimi3 | #1575+#1625 | P2/P1 | backend | [制度管理][18/22] AI制度生成API + [整改] 企微消息模板 | 13:58启动 |
| kimi4 | #1587+#2287 | P1 | fullstack | [预算][31+?/32] 预算管控参数配置API+前端页面 | mvn install注入→BudgetConfigController加载中 |
| kimi5 | #1582 | P1 | backend | [制度管理][5/22] 制度审批流API（warm-flow） | warm-flow FlwTaskServiceImpl.ignore修复注入中 |

