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

所有业务Issue统一创建在 wande-play 仓库，通过 module scope 标签区分：

| module标签 | 含义 | 编程CC行为 |
|-----------|------|-----------|
|  | 纯后端 | cd backend/ → 单Agent TDD |
|  | 纯前端 | cd frontend/ → 单Agent TDD |
|  | 纯爬虫/数据采集 | cd pipeline/ → 单Agent |
|  | 前后端联动 | cd 根目录 → Agent Teams 3-Agent并行 |

## 规范文档

> ⚠️ **2026-04-09 重组**：所有 prompt / CC 相关文档已统一迁移到 `agent-docs/`，按角色分门别类。
> 业务仓库引用时**必须使用绝对路径** `~/projects/.github/docs/agent-docs/...` 或 `/home/ubuntu/projects/.github/docs/agent-docs/...`，禁止 `./` 相对路径。

| 文档 | 新位置 |
|------|------|
| 标签规范（原 WANDE_LABEL.md） | `~/projects/.github/docs/agent-docs/manager/wande-label.md` |
| Issue 创建 SOP（原 ISSUE_CREATION_SOP.md） | `~/projects/.github/docs/agent-docs/manager/issue-creation-sop.md` |
| CC 启动 prompt v2.3（10 条硬约束 + 所有共享规范） | `~/projects/.github/docs/agent-docs/share/shared-conventions.md` |
| **agent-docs 完整导航** | `~/projects/.github/docs/agent-docs/README.md` |
| MONOREPO_MIGRATION.md | （历史文档，未迁移） |

## 相关资源

- [wande-play 研发看板 (Project #4)](https://github.com/orgs/WnadeyaowuOraganization/projects/4) — 当前活跃看板
- [万德应用开发看板 (Project #2)](https://github.com/orgs/WnadeyaowuOraganization/projects/2) — 旧看板（历史Issue）
