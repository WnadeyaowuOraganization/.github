---
name: backend-schema
description: Design MySQL tables and write Flyway migration scripts for Wande-Play. Enforces wdpp_ prefix, 7 RuoYi standard columns (tenant_id/create_dept/create_by/update_by/create_time/update_time/del_flag), single-datasource no-@DS, MySQL 8.0 syntax (no MariaDB IF NOT EXISTS DDL extensions), idempotent scripts, and mandatory column comments. Use before writing any Entity/Mapper when the Issue involves a new table or schema change.
---

# 建表 + Flyway 迁移

**任何新表 / 改表必须走 Flyway 增量脚本**，严禁直接编辑 baseline `wande-ai-pg.sql` / `test-base-schema.pg.sql`。

## 文件位置与命名（MUST：Issue号 + 秒级时间戳，禁止手挑数字）

```
backend/ruoyi-admin/src/main/resources/db/migration/V<YYYYMMDDHHMMSS>_<ISSUE>__<desc>.sql
```

- **MUST** 用命令生成时间戳 + 带 Issue 号（Issue 号跨 CC 天然互斥）：

```bash
ISSUE=3532  # 当前 Issue 号
echo "V$(date +%Y%m%d%H%M%S)_${ISSUE}__<desc>.sql"
# 例：V20260415130245_3532__alter_crm_inquiry.sql
```

- **MUST NOT**：手挑"好看整数" HHMMSS（如 002000 / 003000 / 006000）。CC 独立分支 + 并发写文件 → 手挑数字必撞车
- **MUST NOT**：秒值 ≥60（如 `006000` 意思 00:60:00 是非法时间）。真实 `date +%H%M%S` 不可能产生，只有手挑才会出

**历史事故**：
- 2026-04-14：手编 `YYYYMMDD+NNN` 三位序号撞 `V20260414014` 一天 4 份 → `DuplicateMigration` 整批拒绝
- 2026-04-15：22 个 V20260415* 有 4 对撞号（002000×3 / 003000×2 / 006000×2，006000 秒=60 非法）→ Flyway 抛异常，今日 0 条迁移落地，所有 CRM PR 后端 API 500，排程经理手动 rename 止血

**Flyway version 字段** VARCHAR(50)，`YYYYMMDDHHMMSS_ISSUE` 约 19 位完全安全。

描述用下划线小写，动词+对象：`create_xxx` / `add_xxx_field` / `update_xxx_menu`

## wdpp_ 前缀（强制）

业务表必须 `wdpp_` 前缀（万德平台专用），与 RuoYi `sys_` 系统表区分。例：`wdpp_project_mine` / `wdpp_tender_project`。

## 7 列标准（全部新表必须含，缺一不可）

```sql
tenant_id   VARCHAR(20)  DEFAULT '000000'  COMMENT '租户ID',
create_dept BIGINT       DEFAULT NULL      COMMENT '创建部门',
create_by   BIGINT       DEFAULT NULL      COMMENT '创建者',
update_by   BIGINT       DEFAULT NULL      COMMENT '更新者',
create_time DATETIME     DEFAULT NULL      COMMENT '创建时间',
update_time DATETIME     DEFAULT NULL      COMMENT '更新时间',
del_flag    CHAR(1)      DEFAULT '0'       COMMENT '删除标志（0正常 2删除）',
```

原因：`TenantLineInnerInterceptor` 自动拼 `tenant_id` 条件，缺 = `Unknown column`；`BaseEntity` 需要其余 6 列 AutoFill 才生效。

### ❌ 禁止 `created_time` / `updated_time`（带 d）

**时间字段只能是 `create_time` / `update_time`，绝对不能写 `created_time` / `updated_time`。**

- `BaseEntity` 的 `@TableField(fill = FieldFill.INSERT)` 映射的是 `create_time`，写成 `created_time` 会导致 AutoFill 失效，查询时报 `Unknown column 'create_time' in 'field list'`（Mapper SELECT 列表写死了 BaseEntity 字段名）。
- 历史事故：`crm_customer` / `crm_activity_log` / `crm_contract` 等表建表时写了 `created_time`，导致客户管理列表页 `SQLSyntaxErrorException: Unknown column 'create_time'`（2026-04-19）。
- 新表严禁重蹈；旧表发现立即写 Flyway 改名：`ALTER TABLE xxx CHANGE created_time create_time DATETIME ...`。

**字段类型精确对齐**：`create_by` / `update_by` 是 **BIGINT**（Java `Long`），不是 `VARCHAR` / `String`。类型不匹配启动时 MyBatis 报错。

## 多租户排除

若该表不需要租户隔离（如全局字典），在 `backend/ruoyi-admin/src/main/resources/application.yml` 的 `tenant.excludes` 列表追加表名。

## 单库（无 @DS）

Wande-Play 后端已统一**单数据源**。**严禁** `@DS("slave")` / `@DS("wande")` / `@DS("master")` 注解。所有表在主库，Mapper 直接默认连接。历史代码若有 `@DS` 直接删除。

## MySQL 8.0 语法（禁止 MariaDB 扩展）

```sql
-- ❌ MariaDB 专有，MySQL 8.0 报错
ALTER TABLE xxx ADD KEY IF NOT EXISTS idx_name (col);
ALTER TABLE xxx ADD COLUMN IF NOT EXISTS col_name VARCHAR(255);

-- ✅ 标准 MySQL 8.0
ALTER TABLE xxx ADD INDEX idx_name (col);
CREATE INDEX IF NOT EXISTS idx_name ON xxx(col);  -- MySQL 8.0.29+
```

其他陷阱：

| 错 | 对 |
|----|----|
| PostgreSQL `SERIAL` | `BIGINT AUTO_INCREMENT PRIMARY KEY` |
| `boolean` | `TINYINT(1)` |
| `jsonb` | `JSON` |
| `x::type` cast | `CAST(x AS type)` |
| 字段名撞保留字 | 反引号包裹 \`order\` |

## 幂等脚本（加字段模板）

```sql
SET @dbname = DATABASE();
SET @tbl    = 'wdpp_xxx';
SET @col    = 'new_field';
SET @sql = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE table_schema=@dbname AND table_name=@tbl AND column_name=@col) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tbl, ' ADD COLUMN ', @col,
         ' VARCHAR(100) DEFAULT NULL COMMENT "说明";')
));
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
```

## 字段注释（强制，避免 #3604 类事故）

每个字段必须带中文 `COMMENT`，枚举值语义**写全**：

```sql
is_frame  TINYINT DEFAULT 1 COMMENT 'iframe嵌入：1=否(非外链内嵌) 0=是(外链新窗口)',
evaluation_status TINYINT DEFAULT 0 COMMENT '评估：0=未评估 1=有效 2=无效',
del_flag CHAR(1) DEFAULT '0' COMMENT '删除标志（0正常 2删除）',
```

## 建表骨架

```sql
CREATE TABLE IF NOT EXISTS wdpp_xxx (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
  title VARCHAR(255) NOT NULL COMMENT '标题',
  -- 业务字段 ...
  tenant_id   VARCHAR(20)  DEFAULT '000000'  COMMENT '租户ID',
  create_dept BIGINT       DEFAULT NULL      COMMENT '创建部门',
  create_by   BIGINT       DEFAULT NULL      COMMENT '创建者',
  update_by   BIGINT       DEFAULT NULL      COMMENT '更新者',
  create_time DATETIME     DEFAULT NULL      COMMENT '创建时间',
  update_time DATETIME     DEFAULT NULL      COMMENT '更新时间',
  del_flag    CHAR(1)      DEFAULT '0'       COMMENT '删除标志',
  KEY idx_tenant (tenant_id),
  KEY idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='XX 业务表';
```

## 菜单注册（若新模块）

建业务表同时若需新页面入口，**UPDATE 现有 sys_menu 占位记录**（禁 INSERT 新菜单），具体见 menu-contract skill。

## 提交前校验

```bash
# 1. 在 kimi 独立 DB 试跑
cd /data/home/ubuntu/projects/wande-play-kimiN
bash e2e/scripts/reset-db.sh       # 重置 kimiN 独立 DB
bash e2e/scripts/start-backend.sh  # Flyway 启动时自动执行
tail -f logs/sys-info.log | grep -i flyway  # 看 "Successfully applied" 即通过

# 2. 或手动 validate
cd backend && mvn flyway:validate
```

失败 → 改脚本 → reset-db 重跑。**不要带错脚本推进到 Java 代码。**

## 反模式

- ❌ 字段无 COMMENT
- ❌ `@DS` 注解（单库已取消）
- ❌ 漏 7 列中任何一列
- ❌ 手编 NNN 三位序号（必须 `date +%Y%m%d%H%M%S` 生成）
- ❌ MariaDB `IF NOT EXISTS` DDL 扩展
- ❌ 直接编辑 baseline SQL 文件
- ❌ create_by / update_by 写成 VARCHAR
- ❌ 表名无 wdpp_ 前缀
