---
name: mcp-tool
description: MCP 工具模块开发规范 — CRUD/市场/日志接口、LOCAL/REMOTE/BUILTIN 类型、权限标识
type: skill
---

# MCP 工具模块

Base URL `/api/mcp`，认证 Bearer Token (SaToken)。接口文档源：
`backend/ruoyi-modules/ruoyi-chat/docs/MCP工具模块接口文档.md`

## 何时使用

| 场景 | 必读 |
|------|------|
| 新增 / 修改 MCP 工具 CRUD 接口 | ✅ |
| 新增 / 修改 MCP 市场（第三方工具源）接口 | ✅ |
| 查询 / 统计工具调用日志 | ✅ |
| 新增 BUILTIN（内置）Java 工具并注册到系统 | ✅ |
| 前端 `/mcp/tool` `/mcp/market` `/mcp/log` 页面联调 | ✅ |

不涉及以上场景 → 走常规 backend-coding / frontend-coding 即可。

## 工具类型三类速查

| type | 含义 | configJson 典型字段 | 执行方 | 典型用途 |
|------|------|--------------------|--------|---------|
| `BUILTIN` | 内置 Java 工具（代码实现） | null / 空 | Java 进程内反射调用 | `ReadFileTool` 等系统自带能力 |
| `LOCAL` | 本地进程 MCP Server（stdio） | `command` / `args` / `env` | 子进程 + stdio 协议 | 本地 CLI/Node/Python 脚本 |
| `REMOTE` | 远程 MCP Server（HTTP/SSE） | `baseUrl` / `headers` / `auth` | HTTP 客户端 | 外部服务 API |

`status`：`0=启用` / `1=禁用`（与 RuoYi 标准一致）。

## 核心接口清单

### 1. 工具 CRUD（权限前缀 `mcp:tool:*`）

| 方法 | 路径 | 权限 | 用途 |
|------|------|------|------|
| GET | `/tool/list` | `mcp:tool:list` | 分页查（name/description/type/status + pageNum/pageSize） |
| GET | `/tool/all` | `mcp:tool:list` | 不分页（keyword/type/status） |
| GET | `/tool/{id}` | `mcp:tool:query` | 详情 |
| POST | `/tool` | `mcp:tool:add` | 新增（name/description/type/status/configJson）|
| PUT | `/tool` | `mcp:tool:edit` | 修改 |
| DELETE | `/tool/{ids}` | `mcp:tool:remove` | 批量删（逗号分隔） |
| PUT | `/tool/{id}/status` | `mcp:tool:edit` | 启停切换（query `status=0/1`）|
| POST | `/tool/{id}/test` | `mcp:tool:query` | 连接测试，回 `{success, message, toolCount, tools[]}` |

### 2. MCP 市场（权限前缀 `mcp:market:*`）

| 方法 | 路径 | 权限 | 用途 |
|------|------|------|------|
| GET | `/market/list` | `mcp:market:list` | 分页查市场 |
| GET | `/market/{marketId}/tools` | `mcp:market:query` | 市场下工具列表（page/size）|
| POST | `/market/{marketId}/refresh` | `mcp:market:edit` | 拉取远端 → 回 `{addedCount, updatedCount}` |
| POST | `/market/tool/{toolId}/load` | `mcp:market:edit` | 单个加载到本地工具表 |
| POST | `/market/tools/batchLoad` | `mcp:market:edit` | 批量加载（body `{toolIds: Long[]}`）|

### 3. 调用日志（复用 `mcp:tool:query`）

| 方法 | 路径 | 权限 | 用途 |
|------|------|------|------|
| GET | `/tool/callLog` | `mcp:tool:query` | 调用日志分页（toolId/sessionId/startDate/endDate）|
| GET | `/tool/{toolId}/metrics` | `mcp:tool:query` | 今日/本周 callCount/successRate/avgDurationMs |

响应体规范：列表必须 `TableDataInfo.build(list)`，单体 `R.ok/fail`（见 backend-coding）。

## 新增 BUILTIN 工具的标准流程

> 目标：让 Java 侧新增一个类就能在 `/mcp/tool` 页面可见、可调用、可查日志。

1. **实现工具类**：在 MCP 工具扫描包下写 `XxxTool implements McpBuiltinTool`（接口名按现有实现对齐，如 `ReadFileTool` 同包），返回 JSON-Schema `inputSchema` + `execute(JsonNode) → JsonNode`。
2. **注册 Bean**：`@Component` + 确保落在主类 ComponentScan 范围（否则见 backend-coding ComponentScan 段）。
3. **注册表同步**：系统启动扫描 BUILTIN 实现类 → 落库 `wdpp_mcp_tool`（`type='BUILTIN'`, `status='0'`, `config_json=null`）。若项目用"手工 INSERT"，在 Flyway 脚本里加一行；若自动扫描，确认扫描器能拾起。
4. **权限菜单**：`mcp:tool:*` 已在 sys_menu 占位，无需新增权限标识。
5. **冒烟**：
   ```bash
   curl -H "Authorization: Bearer $TOKEN" http://localhost:710N/api/mcp/tool/all?type=BUILTIN
   curl -X POST -H "Authorization: Bearer $TOKEN" http://localhost:710N/api/mcp/tool/{id}/test
   ```
   `/test` 返回 `success=true` 即通过。
6. **日志验证**：触发一次调用后查 `/tool/{toolId}/metrics`，`today.callCount ≥ 1`。

LOCAL / REMOTE 不走代码路径，只写 `configJson`（通过 `POST /tool` 录入），无需步骤 1~3。

## 表结构要点

| 表 | 关键列 | 说明 |
|----|-------|------|
| `wdpp_mcp_tool` | `id / name / description / type / status / config_json / tenant_id` | `config_json` 用 `String` 存，Service 层 `ObjectMapper` 反序列化 |
| `wdpp_mcp_market` | `id / name / description / base_url / status` | 一个市场 = 一个远端工具源 |
| `wdpp_mcp_market_tool` | `id / market_id / name / schema_json / loaded` | 市场抓取到的工具清单，`loaded=1` 表示已加载到 `wdpp_mcp_tool` |
| `wdpp_mcp_call_log` | `id / tool_id / session_id / duration_ms / success / error_msg / create_time` | 每次调用一行，`metrics` 接口聚合此表 |

字段 camelCase 出参、snake_case 入库，`tenant_id` 由 `TenantLineInnerInterceptor` 自动注入，**Service 不要手 set**。

## 契约三方同步

本模块 Base URL `/api/mcp`（注意：**不**是 `/wande/*`）。契约放 `shared/api-contracts/chat/mcp-tool.yaml`（或同目录统一文件），三端对齐规则见 api-contract skill。

- `configJson` 在契约中显式标 `type: String`（非 Object），避免前端误当对象
- 枚举：`type: LOCAL|REMOTE|BUILTIN`；`status: 0=启用 1=禁用`（务必写含义，避免 #3604 类事故）

## 红线

- ❌ 在 `mcp:tool:*` 外自造权限前缀（前端菜单按此前缀鉴权）
- ❌ `configJson` 用 `Map<String,Object>` 直接返出 — 统一 `String`，需要解析时 Service 层做
- ❌ BUILTIN 工具的 `configJson` 写非空 — BUILTIN 无配置，违反会被测试连接接口打穿
- ❌ 手动 INSERT `sys_menu` 新菜单项 — 只能 UPDATE 占位（见 menu-contract）
- ❌ `/tool/{id}/test` 不返 `success` 字段 — 前端按该字段显示红/绿点
- ❌ 删除 `wdpp_mcp_tool` 行时不级联处理 `wdpp_mcp_call_log`（视需求软删或保留日志）
- ❌ 日志接口查询不加日期索引 — 全表扫会拖垮（`create_time` + `tool_id` 复合索引）
- ❌ 市场 `refresh` 同步阻塞主线程 — 远端慢时前端等超时；用异步或分页拉取
- ❌ `@DS("xxx")` — 单库架构无多数据源
