# 万德AI平台 — 组织级文档中心

本目录存放所有跨仓库的统一规范文档。这是 **Single Source of Truth（唯一真相源）**。

---

## 仓库导航

| 仓库 | 用途 |
|------|------|
| [wande-play](https://github.com/WnadeyaowuOraganization/wande-play) | **Monorepo主仓库** — 后端(backend/) + 前端(frontend/) + E2E测试(e2e/) + 数据采集(pipeline/) |
| [wande-gh-plugins](https://github.com/WnadeyaowuOraganization/wande-gh-plugins) | Grasshopper 参数化插件库 |
| [.github](https://github.com/WnadeyaowuOraganization/.github) | 组织级规范文档 + 辅助脚本 + 研发经理CC |

### 已归档仓库

| 仓库 | 说明 |
|------|------|
| wande-ai-backend | 已合并到 wande-play/backend/ |
| wande-ai-front | 已合并到 wande-play/frontend/ |
| wande-ai-e2e | 已合并到 wande-play/e2e/ |
| wande-data-pipeline | 已合并到 wande-play/pipeline/ |
| wande-ai-platform | 已归档，历史Issue参考 |

## Issue路由规则（Monorepo版）

所有业务Issue统一创建在  仓库，通过 module scope 标签区分：

| module标签 | 含义 | 编程CC行为 |
|-----------|------|-----------|
|  | 纯后端 | cd backend/ → 单Agent TDD |
|  | 纯前端 | cd frontend/ → 单Agent TDD |
|  | 纯爬虫/数据采集 | cd pipeline/ → 单Agent |
|  | 前后端联动 | cd 根目录 → Agent Teams 3-Agent并行 |

## 规范文档

| 文档 | 说明 |
|------|------|
| [WANDE_LABEL.md](./WANDE_LABEL.md) | 统一标签规范 v2.0（module scope + 业务模块 + 优先级等） |
| [ISSUE_CREATION_SOP.md](./ISSUE_CREATION_SOP.md) | Issue创建SOP v2.0 — Monorepo版 |
| [MONOREPO_MIGRATION.md](./MONOREPO_MIGRATION.md) | wande-play Monorepo迁移方案 |

## 相关资源

- [wande-play 研发看板 (Project #4)](https://github.com/orgs/WnadeyaowuOraganization/projects/4) — 当前活跃看板
- [万德应用开发看板 (Project #2)](https://github.com/orgs/WnadeyaowuOraganization/projects/2) — 旧看板（历史Issue）
