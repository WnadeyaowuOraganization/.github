# 数据库设计与变更管理

> **2026-04-08 起改用 Flyway 自动迁移**：Spring Boot 启动时会自动跑 `db/migration_wande_ai/V*.sql` 和 `db/migration_ruoyi_ai/V*.sql`，CC 只需按命名规范创建新文件即可，不再需要手写 bash 脚本或 PR review SQL 执行顺序。

## 新增表/改表（标准流程）

### 第 1 步：在 `db/migration_wande_ai/` 创建 Flyway 增量脚本

**位置**：`backend/ruoyi-modules/wande-ai/src/main/resources/db/migration_wande_ai/`

> ⚠️ **目录归属是死规则，写错位置会导致表建到错误的库里，且很难被发现**：
>
> | 目录 | 仅允许 | 严禁 |
> |------|--------|------|
> | `db/migration_wande_ai/` | **所有业务表**（`wdpp_*`、`competitor_*`、`expense_*` 等所有非框架表）| ❌ 菜单表、字典表、用户角色等框架表 |
> | `db/migration_ruoyi_ai/` | **仅限菜单表更新**（`sys_menu`、`sys_role_menu` 等 ruoyi 框架自带表）| ❌ 任何业务表（`wdpp_*` 严禁出现在此目录） |
>
> **判断规则**：
> - 你的 SQL 在操作 `sys_menu` / `sys_role` / `sys_dict_*` / `sys_user_*` 这种 `sys_` 开头的 ruoyi 框架表 → `migration_ruoyi_ai/`
> - 你的 SQL 在创建/修改任何 `wdpp_*` 或其他业务表 → `migration_wande_ai/`
> - **拿不准就是 `migration_wande_ai/`**（业务表是绝大多数情况）
>
> 写错位置的后果：
> - 业务表写到 `migration_ruoyi_ai/` → 表建到 ruoyi_ai 库，wande_ai 库找不到，dynamic-datasource `@DS("wande")` 注解的所有 Mapper 全部 SQLException
> - 菜单更新写到 `migration_wande_ai/` → 菜单建到 wande_ai 库，前端权限读取 ruoyi_ai 库读不到，菜单消失
>
> **不允许跨库 JOIN**：每个 V*.sql 只能操作一个库的对象，不要在一个 SQL 里同时碰两个库的表。

**Flyway 命名规范（强制）**：`V<日期>_<序号>__<描述>.sql`
- `V20260408_1__add_supplier_ratings_table.sql` ✅
- `V20260408_2__add_invoice_index.sql` ✅
- `V2026-04-08-add-supplier.sql` ❌ 不符合 Flyway 命名

**为什么强制 V 开头**：Flyway 要求前缀 V（versioned migration），版本号要单调递增。两个 CC 同一天写就用 `_1`、`_2` 序号区分。

文件模板：
```sql
-- 变更说明：添加供应商评级表
-- 变更日期：2026-04-08
-- 关联 Issue：#1234

CREATE TABLE IF NOT EXISTS wdpp_supplier_ratings (
    id BIGSERIAL PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    score NUMERIC(3,1) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT,
    deleted INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_wdpp_supplier_ratings_supplier ON wdpp_supplier_ratings(supplier_id);
```

**强制要求**：
- PostgreSQL 语法（`BIGSERIAL`/`TEXT`/`JSONB`/`TIMESTAMP`）
- 必须用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等（Flyway 失败重试时不会报错）
- 头部注释包含变更说明、日期、关联 Issue

### 第 2 步：自动应用，无需任何手动操作

| 环境 | 何时跑 | 谁触发 |
|------|--------|--------|
| **本地 mvn test** | Spring Context 启动时 | `WandeFlywayConfig.@PostConstruct` |
| **dev 部署** | 应用启动时 | 同上 |
| **生产部署** | 应用启动时 | 同上 |
| **新 Docker 部署** | 应用启动时 | 同上 |

**已应用的迁移记录**：每个库的 `flyway_schema_history` 表
- ruoyi_ai 库的 history 表 → `ruoyi_ai.public.flyway_schema_history`
- wande_ai 库的 history 表 → `wande_ai.public.flyway_schema_history`

### 第 3 步：同步 Java 代码

为新表创建对应的 Entity / Mapper / Vo / Bo / Service / Controller，遵循开发规范（详见 [conventions.md](conventions.md)）。

### 第 4 步：本地验证

```bash
# 编译 + 跑相关测试
cd backend
mvn -pl ruoyi-modules-api/wande-ai-api -am install -DskipTests -q
mvn -pl ruoyi-modules/wande-ai test -Dtest='YourServiceTest'
```

测试启动时 Flyway 会自动跑你的 V*.sql 到测试 PG 容器（`wande_test_kimi<N>`）。

---

## ⛔ 禁止行为

1. **禁止编辑 `backend/script/sql/wande-ai-pg.sql`**（baseline 快照，由超管定期重新冻结）
2. **禁止编辑 `backend/script/sql/ruoyi-ai-pg.sql`**（同上）
3. **禁止编辑 `db/migration_*/V1__baseline_2026_04_08.sql`**（baseline V1）
4. **禁止把 SQL 写到 `backend/script/sql/update/wande_ai/`**（已废弃，归档目录）
5. **禁止用旧的 `YYYY-MM-DD-xxx.sql` 命名**（不符合 Flyway，不会被加载）
6. **禁止已合并的迁移脚本被修改**（Flyway checksum 验证会失败）—— 如果发现 V*.sql 写错了，写一个新的 V*.sql 修复，不要直接改老文件

---

## SQL 脚本说明

| 脚本文件 | 位置 | 用途 |
|---------|------|------|
| `ruoyi-ai-pg.sql` | `backend/script/sql/` | ruoyi 框架库 baseline (62 张表) |
| `wande-ai-pg.sql` | `backend/script/sql/` | 万德业务库 baseline (408 张表) |
| `db/migration_ruoyi_ai/V*.sql` | `backend/ruoyi-modules/wande-ai/src/main/resources/` | ruoyi_ai 库的 Flyway 迁移脚本 |
| `db/migration_wande_ai/V*.sql` | 同上 | wande_ai 库的 Flyway 迁移脚本 |
| `_archive_2026-04-08/` | `backend/script/sql/update/{ruoyi_ai,wande_ai}/` | 历史 bash 脚本归档（不再执行）|

### 初始化机制

- **新部署**：Flyway 启动时跑 V1（含 baseline 408+62 张表）+ V2、V3...
- **已有库**（dev/prod 当前状态）：Flyway 启动时自动 baseline 到 V1（不执行 V1），跳过后跑 V2+
- **测试库**：每次 Spring Context 启动 → `schemaAutoLoader` Bean drop schema → Flyway 跑全部 V*.sql

## 菜单与权限注册

详见：[WANDE_MENU.md](../WANDE_MENU.md)

## 数据库列名规范（新旧表差异）

### BaseEntity 字段映射

后端 `BaseEntity` 定义了以下公共字段，MyBatis Plus 自动驼峰转下划线映射：

| Java字段 | 映射到数据库列 | 说明 |
|----------|-------------|------|
| `createTime` | `create_time` | 创建时间（自动填充） |
| `updateTime` | `update_time` | 更新时间（自动填充） |
| `createBy` | `create_by` | 创建者ID |
| `updateBy` | `update_by` | 更新者ID |
| `createDept` | `create_dept` | 创建部门ID |

所有万德业务 Entity 都继承 `BaseEntity`，因此**数据库表必须有 `create_time` / `update_time` 列**才能正常工作。

### 新旧表列名差异

| 表类型 | 示例 | 时间列名 | 是否兼容BaseEntity |
|--------|------|---------|------------------|
| **新规范表（wdpp_开头）** | wdpp_tender_data, wdpp_discovered_projects | `create_time` / `update_time` | 兼容 |
| **老表（已迁移/混合）** | competitors, competitor_alerts, competitor_bids | 同时有 `created_at` + `create_time` | 兼容（有冗余列） |
| **老表（未迁移）** | wecom_conversation_logs, task_queue, work_logs, clients, follow_ups 等 | 仅 `created_at` / `updated_at` | **不兼容 — 查询报错** |

### 新建/修改表的强制规范

1. **新建表必须使用 `create_time` / `update_time` / `create_by` / `update_by` / `create_dept`**（与 BaseEntity 一致）
2. **表名前缀用 `wdpp_`**（万德平台专用，与 ruoyi 框架表区分）
3. **老表如果 Entity 继承了 BaseEntity，必须通过增量 SQL 添加 `create_time` / `update_time` 列**（或在 Entity 中用 `@TableField(exist = false)` 忽略 BaseEntity 的时间字段，并自行用 `@TableField("created_at")` 映射）
4. **迁移老表时**：建议创建增量 SQL，添加 `create_time` / `update_time` / `create_by` / `update_by` 列，并从 `created_at` / `updated_at` 回填数据
