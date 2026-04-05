# 数据库列名规范（新旧表差异）

## BaseEntity 字段映射

后端 `BaseEntity` 字段与数据库列映射：

| Java字段 | 数据库列 | 说明 |
|----------|---------|------|
| `createTime` | `create_time` | 创建时间 |
| `updateTime` | `update_time` | 更新时间 |
| `createBy` | `create_by` | 创建者ID |
| `updateBy` | `update_by` | 更新者ID |
| `createDept` | `create_dept` | 创建部门ID |

## 新旧表差异

| 表类型 | 时间列名 | 兼容性 |
|--------|---------|--------|
| 新规范表（wdpp_开头） | `create_time` / `update_time` | 兼容 |
| 老表（已迁移） | 同时有 `created_at` + `create_time` | 兼容 |
| 老表（未迁移） | 仅 `created_at` / `updated_at` | **不兼容** |

## 新建表规范

1. 必须使用 `create_time` / `update_time` 列名
2. 表名前缀 `wdpp_`
3. 前端开发时注意字段名映射
