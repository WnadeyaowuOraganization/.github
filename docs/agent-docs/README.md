# CC Agent Docs 导航

本目录整理了万德AI平台各编程CC的prompt文档，供开发者参考和复用。

## 文档结构

| 文件 | 描述 | 适用场景 |
|------|------|---------|
| [shared-conventions.md](shared-conventions.md) | 共享规范 - Git分支、环境、数据库、通用规则 | 所有CC |
| [issue-workflow.md](issue-workflow.md) | Issue生命周期与三阶段开发流程 | 所有编程CC |
| [scheduler-guide.md](scheduler-guide.md) | 调度器CC - 排程、触发、检查、优化 | 调度器CC |
| [backend-guide.md](backend-guide.md) | 后端CC - Spring Boot TDD开发 | 后端开发 |
| [frontend-guide.md](frontend-guide.md) | 前端CC - Vue3 Vben Admin开发 | 前端开发 |
| [testing-guide.md](e2e/testing-guide.md) | 测试CC - E2E回归测试 | 测试CC |
| [pipeline-guide.md](pipeline-guide.md) | 管线CC - Python数据采集 | 数据采集 |
| [api-contracts.md](api-contracts.md) | API契约规范 - 前后端接口定义 | fullstack Issue |

## CC角色总览

| CC角色 | 工作目录 | 主要职责 |
|--------|---------|---------|
| **调度器CC** | `$HOME_DIR/projects/.github` | 排程、触发编程CC、检查结果、持续优化 |
| **后端CC** | `wande-play-kimi*/backend` | Spring Boot后端TDD开发 |
| **前端CC** | `wande-play-kimi*/frontend` | Vue3前端页面开发 |
| **测试CC** | `wande-play-e2e-top/e2e` | 全量E2E回归测试 |
| **管线CC** | `wande-play-kimi*/pipeline` | Python数据采集管线 |

## 仓库信息

- **组织**: WnadeyaowuOraganization
- **主仓库**: wande-play
- **Project看板**: https://github.com/orgs/WnadeyaowuOraganization/projects/4
- **CI/CD**: GitHub Actions
