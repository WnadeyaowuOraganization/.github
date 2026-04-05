# 后端编程 CC 数据库脚本操作指南

## 强制规则

⚠️ **禁止直接编辑 `schema.sql`** — 所有新表必须放入 `schemas/issue_XXXX.sql`

---

## 新增数据库表

### 步骤 1：创建 H2 测试脚本（必须先做！）

**位置**: `backend/ruoyi-modules/wande-ai/src/test/resources/schemas/`
**文件名**: `issue_XXXX.sql`（XXXX 是 Issue 号）

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
```

### 步骤 2：更新合并顺序

在 `schemas/SCHEMA_ORDER.txt` 末尾添加：
```
issue_XXXX.sql  # Issue #XXXX: 功能描述
```

### 步骤 3：创建 PostgreSQL 增量脚本

**位置**: `backend/script/sql/update/wande_ai/`
**文件名**: `create-<表名>-issue-XXXX.sql`

```sql
-- 变更说明：创建 XXX 表 - Issue #XXXX
-- 变更日期：2026-04-05

CREATE TABLE IF NOT EXISTS wdpp_xxx (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);
```

### 步骤 4：验证

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

H2脚本文件名: `_alter_issue_XXXX.sql`（alter 前缀）

```sql
ALTER TABLE wdpp_xxx ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
```

---

## 检查清单

- [ ] 创建了 `schemas/issue_XXXX.sql`
- [ ] 更新了 `SCHEMA_ORDER.txt`
- [ ] 创建了增量脚本
- [ ] 没有直接编辑 `schema.sql`
