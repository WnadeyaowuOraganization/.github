# Issue #2367 菜单重组验证清单

## 一、前置验证（实施前）

### 1. 备份数据表（必须）
```bash
# 备份sys_menu和sys_role_menu表
pg_dump -h <host> -U <user> -d ruoyi_ai -t sys_menu -t sys_role_menu > /tmp/menu_backup_$(date +%Y%m%d).sql
```

### 2. 确认现有菜单数据
```sql
-- 查询运营管理及其子菜单
SELECT menu_id, menu_name, parent_id, order_num, visible, path
FROM sys_menu
WHERE menu_id = 1775500307898949634  -- 运营管理
   OR parent_id = 1775500307898949634;

-- 查询竞品情报一级菜单及其子菜单
SELECT menu_id, menu_name, parent_id, order_num, visible, path
FROM sys_menu
WHERE menu_name = '竞品情报' AND parent_id = 0
   OR parent_id IN (SELECT menu_id FROM sys_menu WHERE menu_name = '竞品情报' AND parent_id = 0);

-- 查询知识管理菜单
SELECT menu_id, menu_name, parent_id, order_num, visible, path
FROM sys_menu
WHERE menu_name = '知识管理';
```

---

## 二、实施验证（执行Flyway后）

### 1. 验证菜单结构

#### 验证资源中心创建成功
```sql
SELECT menu_id, menu_name, parent_id, order_num, visible, status
FROM sys_menu
WHERE menu_id = 21007;
```
**预期结果**：
- menu_id = 21007
- menu_name = '资源中心'
- parent_id = 0
- order_num = 7
- visible = '0'（显示）

#### 验证竞品情报迁移成功
```sql
-- 验证新二级目录创建
SELECT menu_id, menu_name, parent_id, order_num, visible
FROM sys_menu
WHERE menu_id = 21008;

-- 验证子菜单已迁移
SELECT menu_id, menu_name, parent_id, visible
FROM sys_menu
WHERE parent_id = 21008;

-- 验证旧一级菜单已隐藏
SELECT menu_id, menu_name, parent_id, visible
FROM sys_menu
WHERE menu_name = '竞品情报' AND parent_id = 0;
```
**预期结果**：
- 新二级目录（21008）存在且parent_id=21007
- 旧竞品情报的所有子菜单parent_id=21008
- 旧一级菜单visible='1'（隐藏）

#### 验证产品知识库目录创建成功
```sql
SELECT menu_id, menu_name, parent_id, order_num, visible
FROM sys_menu
WHERE menu_id = 21009;
```
**预期结果**：
- menu_id = 21009
- parent_id = 21007（资源中心下）
- order_num = 2

#### 验证知识管理迁移成功
```sql
SELECT menu_id, menu_name, parent_id, visible
FROM sys_menu
WHERE menu_name = '知识管理';
```
**预期结果**：
- parent_id = 21009（产品知识库）

#### 验证运营管理已隐藏
```sql
SELECT menu_id, menu_name, parent_id, visible
FROM sys_menu
WHERE menu_id = 1775500307898949634;
```
**预期结果**：
- visible = '1'（隐藏）

---

### 2. 验证权限授权

```sql
-- 验证新菜单已授权给超管
SELECT rm.role_id, m.menu_id, m.menu_name
FROM sys_role_menu rm
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE rm.role_id = 1
  AND m.menu_id IN (21007, 21008, 21009)
ORDER BY m.menu_id;
```
**预期结果**：返回3条记录（21007, 21008, 21009）

---

### 3. 验证菜单树完整性

```sql
-- 查看完整的菜单树（仅显示可见的一级菜单）
SELECT
    m1.menu_name AS 一级菜单,
    m1.order_num AS 一级排序,
    m2.menu_name AS 二级菜单,
    m2.order_num AS 二级排序,
    m3.menu_name AS 三级菜单,
    m3.order_num AS 三级排序
FROM sys_menu m1
LEFT JOIN sys_menu m2 ON m2.parent_id = m1.menu_id AND m2.visible = '0'
LEFT JOIN sys_menu m3 ON m3.parent_id = m2.menu_id AND m3.visible = '0'
WHERE m1.parent_id = 0
  AND m1.visible = '0'
  AND m1.menu_type = 'M'
ORDER BY m1.order_num, m2.order_num, m3.order_num;
```

**预期结果**：应该看到资源中心在第7位，包含竞品情报和产品知识库两个子目录。

---

## 三、UI层验证（手动）

### 1. 登录超管账号

### 2. 检查侧边栏显示
- [ ] 资源中心显示在正确位置（排序第7位）
- [ ] 资源中心可展开
- [ ] 资源中心→竞品情报可展开，包含原有的子菜单
- [ ] 资源中心→产品知识库可展开，包含知识管理菜单
- [ ] 旧竞品情报一级菜单已不在侧边栏显示
- [ ] 运营管理一级菜单已不在侧边栏显示

### 3. 验证页面可访问
- [ ] 点击竞品分析，页面正常加载
- [ ] 点击竞品告警，页面正常加载
- [ ] 点击投标记录，页面正常加载
- [ ] 点击知识管理，页面正常加载

---

## 四、API层验证

```bash
# 调用getRouters接口，验证返回的菜单树结构
curl -X GET "http://localhost:8080/system/menu/getRouters" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" | jq '.data[] | select(.name == "资源中心")'
```

**预期响应**：
```json
{
  "name": "资源中心",
  "path": "resource-center",
  "orderNum": 7,
  "children": [
    {
      "name": "竞品情报",
      "path": "competitor-intelligence",
      "children": [...]
    },
    {
      "name": "产品知识库",
      "path": "product-knowledge",
      "children": [
        {
          "name": "知识管理",
          "path": "knowledgeBase"
        }
      ]
    }
  ]
}
```

---

## 五、回滚方案

如果发现问题，执行以下SQL回滚：

```sql
-- 1. 恢复旧菜单可见性
UPDATE sys_menu SET visible = '0'
WHERE menu_name = '竞品情报' AND parent_id = 0;

UPDATE sys_menu SET visible = '0'
WHERE menu_id = 1775500307898949634;  -- 运营管理

-- 2. 恢复子菜单父ID
-- 需要根据实际情况查询旧的parent_id并更新
-- 示例：假设竞品情报的旧menu_id为20300
UPDATE sys_menu SET parent_id = <旧menu_id>
WHERE parent_id = 21008;

UPDATE sys_menu SET parent_id = 1775500307898949634
WHERE menu_name = '知识管理';

-- 3. 删除新建菜单和授权
DELETE FROM sys_role_menu WHERE menu_id IN (21007, 21008, 21009);
DELETE FROM sys_menu WHERE menu_id IN (21007, 21008, 21009);
```

---

## 六、注意事项

1. **Flyway自动执行**：Spring Boot启动时会自动执行这5个Flyway脚本，无需手动操作。

2. **幂等性**：所有SQL都使用了 `ON CONFLICT DO NOTHING`，可以安全重复执行。

3. **前序Issue依赖**：Issue #2367是菜单重组系列第8个任务，建议确认前7个Issue已完成。

4. **测试环境先行**：建议先在dev环境验证，确认无误后再应用到生产环境。

5. **Flyway checksum**：一旦Flyway脚本被执行，不能再修改文件内容，否则checksum验证会失败。如需修改，请创建新的V*.sql文件。

---

## 七、验收标准

- ✅ 资源中心一级菜单显示在正确位置（第7位）
- ✅ 资源中心包含竞品情报和产品知识库两个子目录
- ✅ 竞品情报的子菜单（竞品分析、竞品告警、投标记录）可正常访问
- ✅ 知识管理在产品知识库下可正常访问
- ✅ 旧竞品情报一级菜单已隐藏
- ✅ 运营管理一级菜单已隐藏
- ✅ 所有菜单权限正确授权给超管
- ✅ 无数据库错误或警告
