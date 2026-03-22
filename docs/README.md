万德AI平台 — 组织级文档中心

本目录存放所有跨仓库的统一规范文档。这是 **Single Source of Truth（唯一真相源）**。
---

## 仓库导航

| 仓库 | 用途 |
|------|------|
| [wande-ai-platform](https://github.com/WnadeyaowuOraganization/wande-ai-platform) | 基础设施 + CI/CD + Issue管理 + 自动编程 |
| [wande-ai-backend](https://github.com/WnadeyaowuOraganization/wande-ai-backend) | 万德AI平台-后端（Spring Boot） |
| [wande-ai-front](https://github.com/WnadeyaowuOraganization/wande-ai-front) | 万德AI平台-前端（Vue3/Vben Admin） |
| [wande-data-pipeline](https://github.com/WnadeyaowuOraganization/wande-data-pipeline) | 数据采集管线 — 项目矿场/招标采集（Python，运行在G7e） |
| [wande-gh-plugins](https://github.com/WnadeyaowuOraganization/wande-gh-plugins) | 万德 Grasshopper 参数化插件库 |

## Issue路由规则

| 类型 | 目标仓库 |
|------|---------|
| Python爬虫/采集脚本/G7e采集相关 | wande-data-pipeline |
| Java/Spring Boot后端代码 | wande-ai-backend |
| Vue3/Vben Admin前端代码 | wande-ai-front |
| 基础设施/CI/CD/自动编程/跨仓库需求 | wande-ai-platform |
| Grasshopper插件 | wande-gh-plugins |

## 规范文档

| 文档 | 说明 | 适用仓库 |
|------|------|---------| 
| [WANDE_LABEL.md](./WANDE_LABEL.md) | 统一标签规范（11维度/65标签） | 全部 |
| [ISSUE_CREATION_SOP.md](./ISSUE_CREATION_SOP.md) | Issue创建SOP — 自动编程需求源 | 全部 |


## 相关资源

- [自动编程看板 (Project #2)](https://github.com/orgs/WnadeyaowuOraganization/projects/2)
- [Sprint看板 (Project #1)](https://github.com/orgs/WnadeyaowuOraganization/projects/1)

