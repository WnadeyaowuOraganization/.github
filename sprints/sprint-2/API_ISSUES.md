# API Issues Report — Sprint-2 主菜单模块接口健康度检查

> 生成时间: 2026-05-13
> 测试环境: http://localhost:8080
> 测试方式: Playwright headless 浏览器 + API 登录(test/666666)
> 覆盖范围: 25 个主菜单模块页面级 API 监听

## 执行摘要

| 指标 | 数值 |
|------|------|
| 测试模块数 | 25 |
| 检测 API 总数 | 50 |
| 失败 API 数 | **0** |
| 通过率 | **100%** |

## 详细结果

| # | 模块 | 路径 | API 总数 | 失败数 | 状态 |
|---|------|------|---------|--------|------|
| 1 | Dashboard | /dashboard | 2 | 0 | 通过 |
| 2 | CRM | /business/crm | 2 | 0 | 通过 |
| 3 | DealerPortal | /dealer-portal | 2 | 0 | 通过 |
| 4 | Tender | /business/tender | 2 | 0 | 通过 |
| 5 | SampleBox | /wande/sample | 2 | 0 | 通过 |
| 6 | Outreach | /wande/outreach | 2 | 0 | 通过 |
| 7 | ProjectPlan | /wande/project | 2 | 0 | 通过 |
| 8 | Support | /wande/support | 2 | 0 | 通过 |
| 9 | BrandCenter | /wande/brand-center | 2 | 0 | 通过 |
| 10 | Intelligence | /wande/intelligence | 2 | 0 | 通过 |
| 11 | D3Catalog | /d3/catalog | 2 | 0 | 通过 |
| 12 | Execution | /wande/project/execution | 2 | 0 | 通过 |
| 13 | Budget | /wande/budget | 2 | 0 | 通过 |
| 14 | Engine | /wande/engine/proposals | 2 | 0 | 通过 |
| 15 | PlatformTool | /wande/data-management | 2 | 0 | 通过 |
| 16 | BizEnablement | /wande/biz-enablement | 2 | 0 | 通过 |
| 17 | DesignAI | /wande/design/proposal-flow | 2 | 0 | 通过 |
| 18 | Expense | /admin-center/expense | 2 | 0 | 通过 |
| 19 | AdminCenter | /admin-center | 2 | 0 | 通过 |
| 20 | Cockpit | /cockpit | 2 | 0 | 通过 |
| 21 | H5 | /h5 | 2 | 0 | 通过 |
| 22 | VbenAdmin | /vben-admin | 2 | 0 | 通过 |
| 23 | PPTWizard | /resource/ppt-wizard | 2 | 0 | 通过 |
| 24 | Solution | /support/solution/ppt-template-center | 2 | 0 | 通过 |
| 25 | AIFlow | /aiflow | 2 | 0 | 通过 |

## 失败 API 列表

> 本次测试未发现任何失败的 API 调用。

## 测试范围说明

本次测试采用 **页面级导航监听** 模式：
- 每个模块仅测试根路径页面的初始加载
- 监听该页面加载过程中触发的所有  请求
- 记录 status >= 400 或 status === 0 的请求为失败

## 已知局限

1. **检测深度有限**: 每个模块仅触发约 2 个 API，主要是页面框架加载相关的接口（如 `/api/system/user/profile`、`/api/getRouters` 等公共接口）。模块内部的 CRUD 操作（列表查询、新增、编辑、删除）未触发。
2. **未覆盖子菜单**: 仅测试了模块根路径，未深入各子页面（如 CRM 下的客户管理、商机管道等子菜单）。
3. **权限因素**: test 用户权限有限，部分模块可能因权限不足而未加载完整数据。
4. **交互操作未覆盖**: 未模拟点击、搜索、筛选、表单提交等交互操作。

## 建议下一步

如需更深入检测，建议：
- 为每个模块编写专项 Playwright 脚本，模拟真实用户操作流程（登录 -> 进入模块 -> 点击子菜单 -> 执行搜索/新建/编辑）
- 使用 admin 权限账号测试，确保覆盖所有功能接口
- 针对历史 Issue 中标记为高危的模块进行重点回归测试

---

## 附录：商务部(CRM)子页面深度测试（第二轮）

> 时间: 2026-05-13
> 测试方式: Playwright headless + 表单登录(test/666666) + 模拟点击搜索按钮/Tab切换

### 执行摘要

| 指标 | 数值 |
|------|------|
| 测试子页面数 | 35 / 40 |
| 检测 API 总数 | 160 |
| 失败 API 数 | **0** |
| 通过率 | **100%** |

### 详细结果

| # | 子页面 | 路径 | API 总数 | 失败数 | 状态 |
|---|--------|------|---------|--------|------|
| 1 | Dashboard | /business/crm/dashboard | 5 | 0 | 通过 |
| 2 | Customer | /business/crm/customer | 4 | 0 | 通过 |
| 3 | Pipeline | /business/crm/pipeline | 5 | 0 | 通过 |
| 4 | Inquiry | /business/crm/inquiry | 5 | 0 | 通过 |
| 5 | Activity | /business/crm/activity | 5 | 0 | 通过 |
| 6 | ChangeLog | /business/crm/change-log | 4 | 0 | 通过 |
| 7 | Bidding | /business/crm/bidding | 5 | 0 | 通过 |
| 8 | BiddingTabs | /business/crm/bidding-tabs | 9 | 0 | 通过 |
| 9 | Payment | /business/crm/payment | 6 | 0 | 通过 |
| 10 | PaymentPlan | /business/crm/payment-plan | 5 | 0 | 通过 |
| 11 | Dealer | /business/crm/dealer | 3 | 0 | 通过 |
| 12 | DealerQuote | /business/crm/dealer-quote | 6 | 0 | 通过 |
| 13 | CommissionDashboard | /business/crm/commission-dashboard | 5 | 0 | 通过 |
| 14 | Commission | /business/crm/commission | 5 | 0 | 通过 |
| 15 | Authorization | /business/crm/authorization | 4 | 0 | 通过 |
| 16 | Meeting | /business/crm/meeting | 5 | 0 | 通过 |
| 17 | Followup | /business/crm/followup | 4 | 0 | 通过 |
| 18 | TeamHeatmap | /business/crm/team-heatmap | 4 | 0 | 通过 |
| 19 | Architecture | /business/crm/architecture | 4 | 0 | 通过 |
| 20 | Leads | /business/crm/leads | 4 | 0 | 通过 |
| 21 | LeadsScoring | /business/crm/leads/scoring | 5 | 0 | 通过 |
| 22 | Terminology | /business/crm/terminology | 6 | 0 | 通过 |
| 23 | IntlCustomer | /business/crm/intl-customer | 4 | 0 | 通过 |
| 24 | SalesFunnel | /business/crm/sales-funnel | 4 | 0 | 通过 |
| 25 | FollowTask | /business/crm/follow-task | 5 | 0 | 通过 |
| 26 | AssignRule | /business/crm/assign-rule | 4 | 0 | 通过 |
| 27 | AssignLog | /business/crm/assign-log | 4 | 0 | 通过 |
| 28 | AssignStats | /business/crm/assign-stats | 4 | 0 | 通过 |
| 29 | ExportCenter | /business/crm/export-center | 4 | 0 | 通过 |
| 30 | ReportCenter | /business/crm/report-center | 4 | 0 | 通过 |
| 31 | LoyaltyPoints | /wande/crm/loyalty/points | 3 | 0 | 通过 |
| 32 | LoyaltyLeaderboard | /wande/crm/loyalty/leaderboard | 4 | 0 | 通过 |
| 33 | LoyaltyStats | /wande/crm/loyalty/stats | 4 | 0 | 通过 |
| 34 | LeaderboardTeam | /wande/crm/leaderboard-team | 4 | 0 | 通过 |
| 35 | Competition | /wande/crm/competition | 4 | 0 | 通过 |

### 未测试页面

以下 5 个页面未测试（已取消）：
- ContactImport (`/business/crm/contact-import`)
- CustomerGrade (`/business/crm/customer-grade`)
- CustomerValueTier (`/business/crm/customer-value-tier`)
- Leaderboard (`/wande/crm/leaderboard`)
- LoyaltyPlans (`/wande/crm/loyalty/plans`)

### 失败 API 列表

> 本次深度测试未发现任何失败的 API 调用。

---

## 原始数据文件

### 第一轮（主菜单模块）
- `/tmp/result-batch1.json` — Batch 1 (Dashboard, CRM, DealerPortal, Tender, SampleBox)
- `/tmp/result-batch2.json` — Batch 2 (Outreach, ProjectPlan, Support, BrandCenter, Intelligence)
- `/tmp/result-batch3.json` — Batch 3 (D3Catalog, Execution, Budget, Engine, PlatformTool)
- `/tmp/result-batch4.json` — Batch 4 (BizEnablement, DesignAI, Expense, AdminCenter, Cockpit)
- `/tmp/result-batch5.json` — Batch 5 (H5, VbenAdmin, PPTWizard, Solution, AIFlow)

### 第二轮（CRM子页面深度测试）
- `/tmp/crm-result-batch1.json` — CRM Batch 1 (Dashboard, Customer, Pipeline, Inquiry, Activity)
- `/tmp/crm-result-batch2.json` — CRM Batch 2 (ChangeLog, Bidding, BiddingTabs, Payment, PaymentPlan)
- `/tmp/crm-result-batch3.json` — CRM Batch 3 (Dealer, DealerQuote, CommissionDashboard, Commission, Authorization)
- `/tmp/crm-result-batch4.json` — CRM Batch 4 (Meeting, Followup, TeamHeatmap, Architecture, Leads)
- `/tmp/crm-result-batch5.json` — CRM Batch 5 (LeadsScoring, Terminology, IntlCustomer, SalesFunnel, FollowTask)
- `/tmp/crm-result-batch6.json` — CRM Batch 6 (AssignRule, AssignLog, AssignStats, ExportCenter, ReportCenter)
- `/tmp/crm-result-batch8.json` — CRM Batch 8 (LoyaltyPoints, LoyaltyLeaderboard, LoyaltyStats, LeaderboardTeam, Competition)
