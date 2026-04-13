# 数据库设计与变更管理

> **数据库**：MySQL 8.0，单库 `wande-ai`
> **迁移工具**：Flyway 11.x，由 `WandeFlywayConfig` 在应用启动时自动执行
> **基线版本**：`20260413002`（此版本及之前的脚本不会被执行）

## 新增表/改表（标准流程）

### 第 1 步：创建 Flyway 增量脚本

**位置**：`backend/ruoyi-admin/src/main/resources/db/migration/`

**命名规范（强制）**：`V{YYYYMMDD}{NNN}__{描述}.sql`
- `V20260414001__add_supplier_ratings.sql` ✅
- `V20260414002__update_crm_indexes.sql` ✅
- `V2026-04-14-add-supplier.sql` ❌ 不符合 Flyway 命名

**版本号说明**：`YYYYMMDD` 日期 + `NNN` 三位序号（001起），同一天多个脚本递增序号。

**文件模板**：
```sql
-- 变更说明：添加供应商评级表
-- 关联 Issue：#1234

CREATE TABLE IF NOT EXISTS wdpp_supplier_ratings (
    id          BIGINT       NOT NULL COMMENT '主键ID',
    supplier_id BIGINT       NOT NULL COMMENT '供应商ID',
    score       DECIMAL(3,1) NOT NULL COMMENT '评分',
    tenant_id   VARCHAR(20)  DEFAULT '000000' COMMENT '租户ID',
    create_dept BIGINT       DEFAULT NULL     COMMENT '创建部门',
    create_by   BIGINT       DEFAULT NULL     COMMENT '创建者',
    update_by   BIGINT       DEFAULT NULL     COMMENT '更新者',
    create_time DATETIME     DEFAULT NULL     COMMENT '创建时间',
    update_time DATETIME     DEFAULT NULL     COMMENT '更新时间',
    del_flag    CHAR(1)      DEFAULT '0'      COMMENT '删除标志（0正常 2删除）',
    PRIMARY KEY (id),
    KEY idx_supplier_id (supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商评级';
```

**强制要求**：
- MySQL 8.0 语法（`BIGINT`/`VARCHAR`/`DATETIME`/`DECIMAL`）
- 幂等性：`CREATE TABLE IF NOT EXISTS`，`INSERT ... ON DUPLICATE KEY UPDATE`，`INSERT IGNORE`
- **表名前缀 `wdpp_`**（万德业务表统一前缀，与 ruoyi 框架 `sys_` 表区分）
- 新表必须包含 7 个标准列（tenant_id/create_dept/create_by/update_by/create_time/update_time/del_flag），详见 [share/db-schema.md](../share/db-schema.md)
- 头部注释包含变更说明、关联 Issue

### 第 2 步：自动应用

应用启动时 `WandeFlywayConfig`（`@EventListener(ApplicationReadyEvent.class)`）自动执行：
1. 从 `DynamicRoutingDataSource` 获取 master 数据源
2. `flyway.repair()` 修复之前失败的记录
3. 检查并执行 pending 脚本
4. 迁移失败不阻塞应用启动（仅打印错误日志）

**已应用记录**：`wande-ai` 库的 `flyway_schema_history` 表

**禁用 Flyway**：编程CC的kimi环境通过 `--spring.flyway.enabled=false` 禁用

### 第 3 步：同步 Java 代码

为新表创建 Entity / Mapper / Vo / Bo / Service / Controller，遵循 [conventions.md](conventions.md)。

### 第 4 步：本地验证

```bash
# 编译
cd backend && mvn clean package -Pprod -Dmaven.test.skip=true
```

---

## 禁止行为

1. **禁止编辑** `V1__baseline_wande_ai.sql`（baseline 快照）
2. **禁止修改已合并的迁移脚本**（Flyway checksum 验证会失败）—— 写错了用新 V*.sql 修复
3. **禁止在脚本中使用 `${...}` 占位符语法**（Flyway 会当作占位符解析，已通过 `placeholderReplacement(false)` 全局禁用，但仍应避免）
4. **禁止用旧的 `YYYY-MM-DD-xxx.sql` 命名**（不符合 Flyway，不会被加载）

---

## 多租户注意事项

`TenantLineInnerInterceptor` 自动对所有 SQL 注入 `tenant_id = '000000'` 条件。

- 新表必须有 `tenant_id` 列，否则报 `Unknown column 'tenant_id'`
- 不需要多租户过滤的表，在 `application.yml` → `tenant.excludes` 中排除
- `flyway_schema_history` 已排除

---

## 菜单与权限注册

详见 shared-conventions.md §菜单 perms 规范。

## 列名规范

详见 [share/db-schema.md](../share/db-schema.md)。
