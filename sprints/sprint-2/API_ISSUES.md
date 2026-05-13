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

## 原始数据文件

- `/tmp/result-batch1.json` — Batch 1 (Dashboard, CRM, DealerPortal, Tender, SampleBox)
- `/tmp/result-batch2.json` — Batch 2 (Outreach, ProjectPlan, Support, BrandCenter, Intelligence)
- `/tmp/result-batch3.json` — Batch 3 (D3Catalog, Execution, Budget, Engine, PlatformTool)
- `/tmp/result-batch4.json` — Batch 4 (BizEnablement, DesignAI, Expense, AdminCenter, Cockpit)
- `/tmp/result-batch5.json` — Batch 5 (H5, VbenAdmin, PPTWizard, Solution, AIFlow)
