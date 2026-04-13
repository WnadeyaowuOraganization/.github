# 数据库列名规范

## BaseEntity 字段映射

后端 `BaseEntity` 字段与数据库列映射（MyBatis-Plus 自动驼峰转下划线）：

| Java字段 | 数据库列 | 类型 | 说明 |
|----------|---------|------|------|
| `createTime` | `create_time` | `DATETIME` | 创建时间（自动填充） |
| `updateTime` | `update_time` | `DATETIME` | 更新时间（自动填充） |
| `createBy` | `create_by` | `BIGINT` | 创建者ID |
| `updateBy` | `update_by` | `BIGINT` | 更新者ID |
| `createDept` | `create_dept` | `BIGINT` | 创建部门ID |

## 新建表强制列

所有新表必须包含以下列，缺一不可：

```sql
tenant_id   VARCHAR(20)  DEFAULT '000000'  COMMENT '租户ID',
create_dept BIGINT       DEFAULT NULL      COMMENT '创建部门',
create_by   BIGINT       DEFAULT NULL      COMMENT '创建者',
update_by   BIGINT       DEFAULT NULL      COMMENT '更新者',
create_time DATETIME     DEFAULT NULL      COMMENT '创建时间',
update_time DATETIME     DEFAULT NULL      COMMENT '更新时间',
del_flag    CHAR(1)      DEFAULT '0'       COMMENT '删除标志（0正常 2删除）',
```

**为什么**：`TenantLineInnerInterceptor` 自动注入 `tenant_id` 条件，缺列报 `Unknown column`。`BaseEntity` 需要其余6列。

## 新旧表差异

| 表类型 | 时间列名 | 兼容性 |
|--------|---------|--------|
| 新规范表 | `create_time` / `update_time` | 兼容 |
| 老表（已迁移） | 同时有 `created_at` + `create_time` | 兼容 |
| 老表（未迁移） | 仅 `created_at` / `updated_at` | **不兼容** |

## 新建表规范

1. **表名前缀 `wdpp_`**（万德平台专用，与 ruoyi 框架 `sys_` 表区分）
2. 必须包含上述7个强制列
3. 使用 MySQL 8.0 语法
4. 前端开发时注意字段名映射（Java驼峰 → DB下划线）
5. 需排除多租户的表，在 `application.yml` 的 `tenant.excludes` 中添加
