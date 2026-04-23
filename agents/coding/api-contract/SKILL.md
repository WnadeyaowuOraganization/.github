---
name: api-contract
description: Maintain YAML API contracts in shared/api-contracts/ as the single source of truth for Wande-Play frontend/backend integration. Enforces contract-first for module:fullstack Issues, 3-way sync (yaml + Java Controller/BO/VO + TS api layer), path/method/auth/permission/field-level typing, and Agent-Teams file isolation rules.
---

# 前后端 API 契约

`shared/api-contracts/*.yaml` 是前后端**唯一接口真相源**。新增 / 修改 / 删除 API → **先改契约，再写代码**。

## 位置

目录结构**与菜单 component 前缀保持一致**（见 `menu-contract` skill「component / perms 前缀对照表」），一级目录即板块：

```
shared/api-contracts/
├── cockpit/                  # 超管驾驶舱      （component: cockpit/）
├── business/
│   ├── tender/               # 商务部 → 招投标   （component: business/tender/）
│   ├── crm/                  # 商务部 → CRM     （component: business/crm/）
│   ├── trade/                # 商务部 → 贸易     （component: business/trade/）
│   └── dealer/               # 商务部 → 经销     （component: business/dealer/）
├── support/                  # 支持中心         （component: support/）
├── admin-center/             # 综合管理中心      （component: admin-center/）
├── install/                  # 安装售后中心      （component: install/）
├── common/                   # 公共板块         （component: common/）
├── resource/                 # 资源中心         （component: resource/）
└── system/                   # 系统管理         （component: system/）
```

一个业务模块一个 yaml（例 `business/tender/project-mine.yaml`），一组相关接口放一起。yaml 路径 = 前端 `views/<component>/` = 后端 `perms` 前缀对应板块，**三处同源**。新增 yaml 前先查 menu-contract 前缀表，板块归属错放 = 后续重构负担。

## 契约文件格式

```yaml
# 模块: project-mine
# 最后更新: 2026-04-14
# 关联Issue: #3458

endpoints:
  - method: GET
    path: /wande/project/mine/list
    description: 分页查询项目矿场列表
    auth: true
    permission: "biz:tender:project-mine:list"
    params:
      - name: pageNum
        in: query
        type: integer
        required: false
      - name: pageSize
        in: query
        type: integer
        required: false
      - name: province
        in: query
        type: string
        required: false
    response:
      code: 200
      data:
        type: PageInfo<ProjectMineVo>
        fields:
          - { name: id, type: Long }
          - { name: title, type: String }
          - { name: evaluationStatus, type: Integer, enum: "0=未评估 1=有效 2=无效" }
          - { name: createTime, type: DateTime }

  - method: PUT
    path: /wande/project/mine/batchEvaluate
    description: 批量标记项目有效/无效
    auth: true
    permission: "biz:tender:project-mine:edit"
    body:
      type: BatchEvaluateBo
      fields:
        - { name: ids, type: "Long[]", required: true }
        - { name: evaluationStatus, type: Integer, required: true, enum: "1=有效 2=无效" }
    response:
      code: 200
      msg: string
      data: null
    sideEffects:
      - 更新 wdpp_project_mine.evaluation_status
      - 写入 wdpp_project_mine_log 操作记录
```

## 契约最低字段（每个 endpoint）

- `method`：GET/POST/PUT/DELETE
- `path`：完整含动态参数 `{paramName}`
- `description`：一句话目的
- `auth`：true/false（大部分 true）
- `permission`：与后端 `@SaCheckPermission` 完全一致
- 参数传递方式：`in: query` / `in: path` / `body`
- 类型定义（字段级）
- 枚举值语义（如 `0=未评估 1=有效`，避免 #3604 类事故）
- `response.code` / `data.type` + `fields`

## 三方同步（改一处 = 改三处）

| 端 | 文件 | 要对齐 |
|----|------|-------|
| 契约 | `shared/api-contracts/**/*.yaml` | 路径 / 方法 / 字段 / 枚举 |
| 后端 | `XxxController.java` + `XxxBo.java` + `XxxVo.java` | `@RequestMapping` 路径、`@SaCheckPermission`、BO/VO 字段名 |
| 前端 | `src/api/<板块>/<module>.ts` + `types.ts`（板块路径与 yaml 一致，如 `api/business/tender/project-mine.ts`）| `requestClient.get/post` 路径、入参 TS 类型、出参字段 |

**顺序**：契约 → 后端实现 → 前端调用。反过来（先前端 mock）容易漂移。

## 字段命名规则（三端统一）

| 端 | 命名 |
|----|------|
| Java Entity/BO/VO | `camelCase`（Jackson 自动序列化 JSON 也是 camelCase）|
| 数据库 | `snake_case`（`@TableField` 映射，或依赖 MyBatis-Plus 驼峰自动转）|
| 前端 TS | `camelCase` |
| URL path / query | `camelCase` 历史统一，不改 |
| 枚举值 | **数字 + 语义写在契约 description / enum 字段** |

## 典型字段错位

| 症状 | 根因 |
|------|------|
| 前端发 `data.ids`，后端收到 null | BO 字段拼写不一致或 Jackson 注解漏 `@JsonProperty` |
| 前端渲染空 | 后端 VO 漏字段 / 误加 `@JsonIgnore` |
| 枚举值颠倒（#3604 is_frame 1=否 0=是）| 契约未写清 0/1 语义 |
| 必填字段前端没传 | 契约缺 `required: true` |
| 分页返回空 | 后端用 `new TableDataInfo<>()` 手设，丢 code/msg |

## module:fullstack 强制流程

Issue 带 `module:fullstack` 标签 → 必须走 Agent Teams：

1. 先读 Issue 全部内容，理解完整需求
2. 创建/更新契约 yaml 文件
3. 先 commit 契约：`contract: update xxx api contract for #N`
4. 然后才创建 Agent Team：
   ```
   创建3-Agent团队开发Issue #N:
   - Backend Agent: 在 backend/ 目录按契约实现API
   - Frontend Agent: 在 frontend/ 目录按契约实现页面, API 调用对齐契约
   - Integration Agent: 验证前后端一致性 (只改 e2e/ 和 shared/)
   ```

### 文件隔离（Agent Teams）

- Backend Agent：只改 `backend/`
- Frontend Agent：只改 `frontend/`
- Integration Agent：只改 `e2e/` + `shared/`

违反隔离 = 并行冲突 + rebase 困难。

### 编译门控（全过才 PR）

- 后端：`cd backend && mvn clean compile -Pprod -DskipTests`
- 前端：`cd frontend && pnpm build`
- 契约一致性：`shared/api-contracts/` 每条 path 在两端都有对应实现

## 非 fullstack Issue

module:backend 或 module:frontend 若新增 API 也**建议**同步更新契约（降低后续对接成本）。改已有 API **必须**更新契约。

## 契约 PR 规范

契约单独或与实现一起 PR 皆可。PR body 声明：

```markdown
## 契约变更
- 新增 PUT /wande/project/mine/batchEvaluate
- 字段 evaluationStatus 枚举 1=有效 2=无效

## 对端实现状态
- 后端：本 PR 已实现
- 前端：本 PR 已实现
```

两端之一未实现 → 在依赖 Issue body 声明 `待 #M`，避免集成断链。

## 反模式

- ❌ 前后端各写各的，不更新契约
- ❌ 契约里字段类型写 `any` / `Object`
- ❌ 枚举值只写数字不写含义
- ❌ fullstack Issue 不先提契约就创 Agent Team
- ❌ 改契约不改代码（或反之），后续集成时爆字段错位
- ❌ 契约放 `/tmp` 或代码目录里，不进 `shared/api-contracts/`
