## 任务：解决 PR #2566 合并冲突

### 背景
PR #2566 (Issue #1560) 是"组件-材料绑定规则 Service 层与校验逻辑"，与 dev 分支有冲突。

### 冲突类型
1. **目录迁移冲突**: dev 分支将 `ruoyi-modules-api/wande-ai-api` 迁移到 `ruoyi-modules/wande-ai`
2. **schema.sql 冲突**: H2 测试 schema 有变更
3. **文件删除冲突**: MoldLibrary.java 被删除但 PR 有修改

### 解决步骤

#### 1. 解决目录迁移冲突
PR 新增的文件需要放到迁移后的位置：
- `ruoyi-modules-api/wande-ai-api/src/main/java/org/ruoyi/wande/d3/mapper/ComponentMaterialBindingMapper.java`
  → `ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/d3/mapper/ComponentMaterialBindingMapper.java`

#### 2. 解决 schema.sql 冲突
**重要：使用新的数据库脚本管理方式**

不要直接编辑 `schema.sql`，而是：

1. 在 `backend/ruoyi-modules/wande-ai/src/test/resources/schemas/` 创建文件 `issue_1560.sql`
2. 将 Issue #1560 新增的表定义放入该文件（使用 H2 语法）
3. 更新 `schemas/SCHEMA_ORDER.txt` 添加 `issue_1560.sql`

#### 3. 解决 MoldLibrary.java 冲突
dev 分支已删除此文件，PR 的修改需要移动到新位置：
- 检查 `ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/domain/d3/mold/` 是否已有替代文件
- 如果有，将变更合并过去；如果没有，在正确位置创建

#### 4. H2 语法转换参考
| PostgreSQL | H2 |
|------------|-----|
| `BIGSERIAL` | `BIGINT AUTO_INCREMENT` |
| `TEXT` | `CLOB` |

#### 5. 完成后
```bash
# 验证测试通过
cd backend && mvn test -pl ruoyi-modules/wande-ai

# 推送
git push --force origin feature-1560
```

### 注意事项
- 不要直接编辑 `schema.sql`
- 文件需要放到迁移后的正确位置
- 确保测试通过后再推送
