
本系统的前端菜单由**后端 `sys_menu` 表**驱动（`ruoyi_ai` 数据库），前端通过 `/system/menu/getRouters` API 动态获取菜单树。**仅创建 Controller/页面/路由是不够的，必须同时在 `sys_menu` 表中注册菜单，否则前端不会显示任何入口。**

#### 何时需要注册菜单

| 场景 | 是否需要注册 sys_menu |
|------|----------------------|
| 新增业务模块（如「供应商管理」） | **必须** — 需要一级目录 + 二级菜单 + 按钮权限 |
| 新增子页面（如「招投标/AI评估」） | **必须** — 需要二级或三级菜单 |
| 新增操作按钮权限（如「导出」「删除」） | **必须** — 需要按钮类型菜单(menu_type=F) |
| 修改已有页面的字段/样式 | 不需要 |
| 纯 API 接口无页面 | 不需要 |

#### 操作步骤

**第 1 步：编写增量 SQL**

在 `script/sql/update/ruoyi_ai/` 下创建增量 SQL 文件（注意：`sys_menu` 在 `ruoyi_ai` 库，不是 `wande_ai` 库）：

文件命名：`YYYY-MM-DD-add-xxx-menu.sql`

```sql
-- 变更说明：新增xxx模块菜单与权限
-- 变更日期：YYYY-MM-DD
-- 关联 Issue：#N

-- 二级菜单（menu_type=C 页面菜单）
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query_param, is_frame, is_cache, menu_type, visible, status, perms, icon, create_dept, create_by, create_time, update_by, update_time, remark)
VALUES (2XXXX, '模块名称', 20X00, N, 'path-name', 'wande/xxx/index', '', 1, 0, 'C', '0', '0', 'wande:xxx:list', 'ri:icon-name', 103, 1, NOW(), 1, NOW(), '模块说明');

-- 按钮权限（menu_type=F 按钮，parent_id 指向所属页面菜单）
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query_param, is_frame, is_cache, menu_type, visible, status, perms, icon, create_dept, create_by, create_time, update_by, update_time, remark)
VALUES (2XXX1, '查询', 2XXXX, 1, '', '', '', 1, 0, 'F', '0', '0', 'wande:xxx:query', '', 103, 1, NOW(), 1, NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query_param, is_frame, is_cache, menu_type, visible, status, perms, icon, create_dept, create_by, create_time, update_by, update_time, remark)
VALUES (2XXX2, '新增', 2XXXX, 2, '', '', '', 1, 0, 'F', '0', '0', 'wande:xxx:add', '', 103, 1, NOW(), 1, NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query_param, is_frame, is_cache, menu_type, visible, status, perms, icon, create_dept, create_by, create_time, update_by, update_time, remark)
VALUES (2XXX3, '修改', 2XXXX, 3, '', '', '', 1, 0, 'F', '0', '0', 'wande:xxx:edit', '', 103, 1, NOW(), 1, NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query_param, is_frame, is_cache, menu_type, visible, status, perms, icon, create_dept, create_by, create_time, update_by, update_time, remark)
VALUES (2XXX4, '删除', 2XXXX, 4, '', '', '', 1, 0, 'F', '0', '0', 'wande:xxx:remove', '', 103, 1, NOW(), 1, NOW(), '');

-- 角色绑定菜单（role_id=1 为超级管理员，确保新菜单对管理员可见）
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 2XXXX) ON CONFLICT DO NOTHING;
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 2XXX1) ON CONFLICT DO NOTHING;
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 2XXX2) ON CONFLICT DO NOTHING;
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 2XXX3) ON CONFLICT DO NOTHING;
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (1, 2XXX4) ON CONFLICT DO NOTHING;
```

**第 2 步：确定 menu_id**

- 万德业务菜单 ID 范围：**20000+**
- 一级目录（已存在）：
    - `20000` CRM客户管理 / `20100` 项目矿场 / `20200` 招投标中心
    - `20300` 竞品情报 / `20400` 运营工具 / `20500` 研发管控
- 查询已分配 ID：`SELECT MAX(menu_id) FROM sys_menu WHERE menu_id >= 20000;`（当前最大 20540）
- 新增时从已分配的最大 ID 之后递增，同一一级目录下的菜单 ID 保持连续

**第 3 步：字段说明**

| 字段 | 说明 |
|------|------|
| menu_type | `M`=目录 `C`=菜单页面 `F`=按钮权限 |
| parent_id | 父菜单ID，根据所属业务模块指向对应一级目录（如 `20500` 研发管控） |
| path | 路由路径（kebab-case），如 `supplier-rating` |
| component | 前端组件路径，如 `wande/supplier-rating/index`（对应 views/wande/supplier-rating/index.vue） |
| perms | 权限标识，格式 `wande:模块:操作`，必须与 Controller 的 `@SaCheckPermission` 一致 |
| visible | `0`=显示 `1`=隐藏 |
| is_frame | `1`=非外链 `0`=外链 |

#### 自查清单

新增功能模块提交前，检查以下菜单相关项：

- [ ] 增量 SQL 文件已创建在 `script/sql/update/ruoyi_ai/` 下（注意是 ruoyi_ai 不是 wande_ai）
- [ ] menu_id 使用 20000+ 体系，不与已有 ID 冲突（查询：`SELECT MAX(menu_id) FROM sys_menu WHERE menu_id >= 20000;`）
- [ ] component 路径与前端 views 目录下的实际文件路径一致
- [ ] perms 权限标识与 Controller `@SaCheckPermission` 注解一致
- [ ] sys_role_menu 已绑定 role_id=1（超级管理员）
