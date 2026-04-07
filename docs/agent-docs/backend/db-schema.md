# 数据库设计与变更管理

## 数据库变更管理

开发过程中如果需要新建表或修改表结构，按以下流程操作：

### 第 1 步：创建增量 SQL

在 `script/sql/update/` 下按**目标数据库子目录**创建 SQL 文件：
- 目标数据库为 `wande_ai` → 放入 `script/sql/update/wande_ai/`
- 目标数据库为 `ruoyi_ai` → 放入 `script/sql/update/ruoyi_ai/`
- 命名格式：`YYYY-MM-DD-功能描述.sql`
- 示例：`script/sql/update/wande_ai/2026-03-18-add-supplier-ratings.sql`

文件模板：
```sql
-- 变更说明：添加供应商评级表
-- 变更日期：2026-03-18
-- 关联 Issue：#3

CREATE TABLE IF NOT EXISTS supplier_ratings (
    id BIGSERIAL PRIMARY KEY,
    -- 字段定义...
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**要求**：
- PostgreSQL 语法，使用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等
- 每个文件的头部注释必须包含：变更说明、日期、关联 Issue
- SQL 文件中**不需要**指定 schema 前缀（如 `wande_ai.`），子目录名即目标数据库，CI/CD 会自动连接对应数据库执行
- **CI/CD 自动执行机制**：push 到 main 后，GitHub Actions 会将 `script/sql/update/` 下各子目录的 SQL 文件同步到 Lightsail，由 `run-sql-updates.sh` 脚本按文件名日期顺序执行。已执行过的文件会记录在各数据库的 `sql_migrations_history` 表中自动跳过，保证幂等

### 第 2 步：同步到初始化脚本

将新增的表 DDL 同步追加到 `script/sql/wande-ai-pg.sql`（万德业务表）末尾，保持初始化脚本与增量脚本一致。

> ⚠️ **2026-04-07 起单元测试改用 Docker PostgreSQL，不再需要维护 H2 schema**
>
> 旧流程要求 CC 同时维护 `test/resources/schemas/issue_XXXX.sql`（H2 方言）+ PG 增量脚本，两套同步极易出错且并行写入冲突频繁。
>
> **新流程**：CC 只写一处——`backend/script/sql/update/wande_ai/` 下的 PG 脚本。
>
> 测试启动时 `TestApplication.schemaAutoLoader` 会自动：
> 1. `DROP SCHEMA public CASCADE; CREATE SCHEMA public`
> 2. 加载 `test-base-schema.pg.sql`（dev PG snapshot 冻结快照，含 368 张表）
> 3. 加载 `update/wande_ai/` 下不在 `test-base-applied.txt` 里的脚本（即你新加的）
>
> **禁止编辑**：`test/resources/test-base-schema.pg.sql`、`test/resources/test-base-applied.txt`、`script/sql/wande-ai-pg.sql` 中的旧表定义。
>
> 验证：`cd backend && mvn -pl ruoyi-modules-api/wande-ai-api -am install -DskipTests && mvn -pl ruoyi-modules/wande-ai test`

### 第 3 步：同步 Java 代码

为新表创建对应的 Entity / Mapper / Vo / Bo / Service / Controller，遵循开发规范（详见 [conventions.md](conventions.md)）。

## SQL 脚本说明

| 脚本文件 | 位置 | 用途 |
|---------|------|------|
| `ruoyi-ai.sql` | `script/sql/` | ruoyi-ai 框架 MySQL 版（原始） |
| `ruoyi-ai-pg.sql` | `script/sql/` | ruoyi-ai 框架表 PostgreSQL 版 |
| `wande-ai-pg.sql` | `script/sql/` | 万德业务表 PostgreSQL DDL |

初始化执行顺序：先 `ruoyi-ai-pg.sql`（在 `ruoyi_ai` 库），再执行`script/sql/update/ruoyi`下的菜单更新脚本"*-menu.sql"（在 `ruoyi_ai` 库），最后 `wande-ai-pg.sql`（在 `wande_ai` 库）。

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
