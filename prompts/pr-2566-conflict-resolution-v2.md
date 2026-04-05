## 任务：解决 PR #2566 合并冲突并添加数据库表

### 背景
PR #2566 (Issue #1560) 是"组件-材料绑定规则 Service 层与校验逻辑"，与 dev 分支有冲突。

### 冲突解决步骤

1. 合并 dev 分支，解决冲突
2. 删除旧位置的文件（已被迁移）

### 数据库脚本（重要！）

**使用新的模块化方式，不要直接编辑 schema.sql**

#### 创建 H2 测试脚本
文件位置：`backend/ruoyi-modules/wande-ai/src/test/resources/schemas/issue_1560.sql`

```sql
-- H2 测试 Schema - Issue #1560
-- 组件-材料绑定规则表

CREATE TABLE IF NOT EXISTS wdpp_component_material_binding (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    component_type VARCHAR(100) NOT NULL,
    default_material_id BIGINT,
    allowed_material_ids CLOB,
    project_id BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);

CREATE TABLE IF NOT EXISTS wdpp_project_material_override (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT NOT NULL,
    component_type VARCHAR(100) NOT NULL,
    material_id BIGINT NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);

CREATE INDEX IF NOT EXISTS idx_component_binding_type ON wdpp_component_material_binding(component_type);
CREATE INDEX IF NOT EXISTS idx_material_override_project ON wdpp_project_material_override(project_id);
```

#### 更新 SCHEMA_ORDER.txt
在 `backend/ruoyoyi-modules/wande-ai/src/test/resources/schemas/SCHEMA_ORDER.txt` 末尾添加：
```
issue_1560.sql  # Issue #1560: 组件-材料绑定规则
```

#### 创建 PostgreSQL 增量脚本
文件位置：`backend/script/sql/update/wande_ai/create-component-material-binding-issue-1560.sql`

### 检查清单

- [ ] 合并 dev 分支，解决冲突
- [ ] 创建 `schemas/issue_1560.sql`（不是直接编辑 schema.sql）
- [ ] 更新 `schemas/SCHEMA_ORDER.txt`
- [ ] 验证 `mvn test -pl ruoyi-modules/wande-ai` 通过
- [ ] `git push --force origin feature-1560`
