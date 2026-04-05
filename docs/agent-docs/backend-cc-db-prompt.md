# 后端编程 CC 数据库脚本操作指南

## 新增数据库表

### 1. 创建 PostgreSQL 增量脚本

**位置**: `backend/script/sql/update/wande_ai/`
**文件名**: `create-<表名>-issue-XXXX.sql`

```sql
-- 变更说明：创建 XXX 表 - Issue #XXXX
-- 变更日期：2026-04-05
-- 关联 Issue：#XXXX

CREATE TABLE IF NOT EXISTS wdpp_xxx (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);

CREATE INDEX IF NOT EXISTS idx_xxx_name ON wdpp_xxx(name);
COMMENT ON TABLE wdpp_xxx IS 'XXX表';
```

### 2. 创建 H2 测试脚本

**位置**: `backend/ruoyi-modules/wande-ai/src/test/resources/schemas/`
**文件名**: `issue_XXXX.sql`

```sql
-- H2 测试 Schema - Issue #XXXX

CREATE TABLE IF NOT EXISTS wdpp_xxx (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);

CREATE INDEX IF NOT EXISTS idx_xxx_name ON wdpp_xxx(name);
```

### 3. 更新合并顺序

在 `schemas/SCHEMA_ORDER.txt` 末尾添加：
```
issue_XXXX.sql  # Issue #XXXX: 功能描述
```

### 4. 验证

```bash
cd backend && mvn test -pl ruoyi-modules/wande-ai
```

---

## PostgreSQL → H2 语法转换

| PostgreSQL | H2 |
|------------|-----|
| `BIGSERIAL` | `BIGINT AUTO_INCREMENT` |
| `SERIAL` | `INT AUTO_INCREMENT` |
| `TEXT` | `CLOB` |
| `JSONB` | `VARCHAR(4000)` |

---

## 修改现有表

**增量脚本**: `alter-<表名>-issue-XXXX.sql`
**H2脚本**: `_alter_issue_XXXX.sql`

```sql
-- PostgreSQL
ALTER TABLE wdpp_xxx ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
COMMENT ON COLUMN wdpp_xxx.new_field IS '新字段';

-- H2
ALTER TABLE wdpp_xxx ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
```

---

## 禁止

- ❌ 直接编辑 `schema.sql`
- ❌ 修改其他 Issue 的文件
