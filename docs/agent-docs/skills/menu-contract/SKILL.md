---
name: menu-contract
description: Register frontend pages in the backend sys_menu table via Flyway UPDATE (never INSERT) for Wande-Play. Enforces the placeholder-menu-first rule (all pages have pre-built placeholder menus that must be UPDATEd with component path), is_frame=1 fixed, component/perms prefix tables per business section (cockpit/business/support/admin-center/install/common/resource/system), and sys_role_menu binding. Mandatory whenever adding a new frontend page.
---

# 菜单契约（sys_menu 注册）

万德前端菜单由后端 `sys_menu` 表驱动，前端通过 `/system/menu/getRouters` 动态获取。**仅创建 Controller + 页面 + 路由不够，必须在 `sys_menu` 登记，否则前端不显示任何入口。**

## 🚨 最高优先级规则：禁 INSERT、只 UPDATE 占位

平台菜单结构已通过 8 个 Issue 统一建好，**所有页面都有对应的占位菜单**（`component` 为空或指向占位组件的记录）。

开发新页面流程：

1. 查 `sys_menu` 找占位记录：

```sql
SELECT menu_id, menu_name, path, component
FROM sys_menu
WHERE menu_name = '<模块名>' OR path = '<kebab-path>';
```

2. 用 Flyway 增量 SQL **UPDATE** 该记录的 `component` 字段：

```sql
-- ✅ 正确：UPDATE 已有占位菜单
UPDATE sys_menu
SET component = 'business/tender/project-mine/index',
    update_by = 'admin',
    update_time = NOW()
WHERE menu_name = '项目挖掘' AND menu_type = 'C';
```

3. 前端**优先替换占位页面**：在 `frontend/apps/web-antd/src/views/` 对应路由目录下查找含 `🚧` 或 `占位` 标识的 `index.vue`，直接替换内容为实际业务组件。没有占位页面再新建文件。

4. **禁止 INSERT 新菜单**：

```sql
-- ❌ 错误：INSERT 新菜单
INSERT INTO sys_menu (...) VALUES (...);
```

例外：若目录树里**确实没有**对应占位（极少见，需先检查「完整菜单目录树」），才可 INSERT，且：

1. **必须**在 `issues/issue-<N>/task.md` + PR body 明文列出「同类先例」（如 `#3484 V20260414014__add_cockpit_xxx_menu.sql`），否则 pr-body-lint / quality-gate 会把无据 INSERT 当违规拦
2. **必须**在派发 Issue 时由研发经理书面确认「走例外 INSERT」
3. `perms` 前缀 **严格**对应所属板块（见「component / perms 前缀对照表」），例如挂在超管驾驶舱下 → `perms = cockpit:xxx:list`，错前缀 = Controller `@SaCheckPermission` 对不上 → 403

## 何时必须操作 sys_menu

| 场景 | 是否需要 |
|------|---------|
| 新业务模块（新"模块名"） | **必须**（一级目录 + 二级菜单 + 按钮权限，但优先 UPDATE 占位）|
| 新子页面（新路由 path） | **必须**（UPDATE 或 INSERT 二/三级菜单） |
| 新操作按钮权限（导出/删除/分配等） | **必须**（menu_type=F） |
| 改已有页面字段/样式 | 不需要 |
| 纯 API 无页面 | 不需要 |

## Flyway 文件命名

```
backend/ruoyi-admin/src/main/resources/db/migration/V<YYYYMMDD><NNN>__<desc>.sql
```

例 `V20260414002__update_project_mine_menu.sql`。同日多脚本序号递增。

## 字段说明

| 字段 | 取值 |
|------|------|
| `menu_type` | `M`=目录 `C`=菜单页面 `F`=按钮权限 |
| `parent_id` | 父菜单 `menu_id`，按所属业务板块指向对应一级目录 |
| `path` | 路由（kebab-case），如 `project-mine` |
| `component` | 前端组件路径，前缀按板块不同（见下表），对应 `views/` 下 `.vue` |
| `perms` | 权限标识，前缀按板块不同，必须与 Controller `@SaCheckPermission` 完全一致 |
| `visible` | `0`=显示 `1`=隐藏 |
| `is_frame` | **固定填 `1`**。外链由 `path` 是否以 `http(s)://` 开头决定，与此字段无关（历史 #3604 事故的重点：`is_frame` 语义 1=否非外链/0=是外链，易误读）|
| `is_cache` | `0`=不缓存 `1`=缓存 |
| `status` | `0`=正常 `1`=停用 |
| `icon` | 图标名（仅目录 / 菜单需要，按钮 F 留空）|

## component / perms 前缀对照表（按所属板块）

| 板块 | 一级 path | component 前缀 | perms 前缀 |
|------|----------|---------------|-----------|
| 超管驾驶舱 | `cockpit` | `cockpit/` | `cockpit:` |
| 商务部 → 招投标 | `business` | `business/tender/` | `biz:tender:` |
| 商务部 → CRM | `business` | `business/crm/` | `biz:crm:` |
| 商务部 → 其他 | `business` | `business/trade/` / `business/dealer/` | `biz:trade:` / `biz:dealer:` |
| 支持中心 | `support` | `support/` | `support:` |
| 综合管理中心 | `admin-center` | `admin-center/` | `admin:` |
| 安装售后中心 | `install-service` | `install/` | `install:` |
| 公共板块 | `common` | `common/` / `portal/` | `common:` / `portal:` |
| 资源中心 | `resource` | `resource/` | `resource:` |
| 系统管理 | `system` | `system/` | `system:` |

### 示例

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 项目挖掘 | `project-mine` | `business/tender/project-mine/index` | `biz:tender:project-mine:list` |
| 客户管理 | `customer` | `business/crm/customer/index` | `biz:crm:customer:list` |
| 竞品分析 | `analysis` | `resource/competitor/analysis/index` | `resource:competitor:analysis:list` |
| 用户管理 | `user` | `system/user/index` | `system:user:list` |

## perms 必须 `:list` 结尾（页面菜单）

页面级（menu_type=C）的 `perms` 必须以 `:list` 结尾（#3604 修订后规范）。按钮类（F）用 `:query` / `:add` / `:edit` / `:remove` / `:export`。

## 完整建菜单 Flyway 模板（真要 INSERT 时）

仅当目录树里**确实没有占位**时使用。优先 UPDATE。

```sql
-- 动态获取最大 menu_id 避免硬编码冲突
SET @max_id = (SELECT COALESCE(MAX(menu_id), 0) FROM sys_menu);

-- 一级目录（menu_type=M，仅新模块需要）
INSERT INTO sys_menu
  (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache,
   menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES
  (@max_id + 1, '模块名称', 0, 10, 'xxx', '', 1, 0,
   'M', '0', '0', '', 'icon-name', 'admin', NOW(), 'admin', NOW(), '模块说明');
SET @parent_id = @max_id + 1;

-- 二级菜单（menu_type=C）
INSERT INTO sys_menu
  (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache,
   menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES
  (@max_id + 2, '子模块名', @parent_id, 1, 'path-name', '{prefix}/xxx/index', 1, 0,
   'C', '0', '0', '{perms-prefix}:xxx:list', '', 'admin', NOW(), 'admin', NOW(), '');
SET @menu_id = @max_id + 2;

-- 按钮权限（menu_type=F）
INSERT INTO sys_menu VALUES
  (@max_id + 3, '查询', @menu_id, 1, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:query', '', 'admin', NOW(), 'admin', NOW(), ''),
  (@max_id + 4, '新增', @menu_id, 2, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:add', '', 'admin', NOW(), 'admin', NOW(), ''),
  (@max_id + 5, '修改', @menu_id, 3, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:edit', '', 'admin', NOW(), 'admin', NOW(), ''),
  (@max_id + 6, '删除', @menu_id, 4, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:remove', '', 'admin', NOW(), 'admin', NOW(), ''),
  (@max_id + 7, '导出', @menu_id, 5, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:export', '', 'admin', NOW(), 'admin', NOW(), '');

-- 角色绑定（role_id=1 超管，新菜单必对管理员可见）
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES
  (1, @max_id + 1), (1, @max_id + 2), (1, @max_id + 3),
  (1, @max_id + 4), (1, @max_id + 5), (1, @max_id + 6), (1, @max_id + 7);
```

## 外链菜单（iframe 嵌入 / 新窗口）

**禁止**为外部链接创建自定义 iframe Vue 组件。直接用 `sys_menu` 配置：

```sql
-- 内嵌 iframe（页面框架内打开）
UPDATE sys_menu
SET path = 'http://172.31.0.5:3000/dashboard',   -- 外链 URL 作为 path
    component = '',                               -- 无前端组件
    is_frame = 1,                                 -- 固定 1（is_frame 字段 1=否/非外链的语义，此处对内嵌也填 1）
    menu_type = 'C'
WHERE menu_name = 'Grafana监控';

-- 新窗口打开：同上但前端菜单会根据 path 以 http 开头自动处理
```

**is_frame 语义重申（#3604 事故）**：

| 值 | 语义 |
|---|------|
| `1` | 否（非外链 = 内嵌方式打开）— **所有菜单固定填 1** |
| `0` | 是（外链，新窗口）— 几乎不用，由 path 是否 http:// 自动决定 |

不要被字段名误导填 0。

## 自查清单

- [ ] 先查 `sys_menu` 是否有占位记录，有则 **UPDATE**
- [ ] Flyway 文件名符合 `V<YYYYMMDD><NNN>__<desc>.sql`
- [ ] `menu_id` 用 `@max_id + N` 动态获取不硬编码
- [ ] `component` 前缀与所在板块一致（对照表）
- [ ] `perms` 与 Controller `@SaCheckPermission` 完全一致
- [ ] `perms` 页面级 `:list` 结尾
- [ ] `is_frame` 填 `1`
- [ ] `sys_role_menu` 绑定 `role_id=1`（超管可见）
- [ ] 前端 `views/<component 对应目录>/index.vue` 实际存在
- [ ] 启动后访问前端，左侧菜单出现新入口

## 完整菜单目录树（权威参考）

来源：`~/projects/.github/docs/design/all-in-one/菜单重组完整规划.md`。新增前先对照该文件确认所属板块和占位情况。主要一级板块：

- **超管驾驶舱** `cockpit` — 驾驶舱首页/Issue看板/开发者动态/运维监控/企微控制台/工作日志/仪表盘/Credit消耗/Claude Office/G7e监控/工具详情
- **商务部 → 招投标** `business/tender` — 项目挖掘/商机管理/招投标管理/AI评估/采集源
- **商务部 → CRM** `business/crm` — 商务工作台/客户/商机/回款/经销商/记录/询盘/投标/我的提成
- **支持中心** `support` — 品牌/方案/供应商/协同/D3设计/AI渲染/安全管理/产品参数/产品/素材/备件/生命周期
- **综合管理中心** `admin-center` — 人事/提成/报销/权限/财务/工作流/政策
- **安装售后中心** `install-service` — 执行/预算模板/WBS/保证金/质保
- **公共板块** `common` / `portal` — 产品目录/合同/执行/审批/通知/文件/项目
- **资源中心** `resource` — 竞品分析/告警/投标记录/知识管理
- **系统管理** `system` — 用户/角色/菜单/部门/岗位/字典/参数/通知/日志

## 反模式

- ❌ INSERT 新菜单而不查占位
- ❌ 硬编码 `menu_id` 数值
- ❌ `component` 前缀与所在板块不一致
- ❌ `perms` 与 Controller `@SaCheckPermission` 不一致
- ❌ 漏 `sys_role_menu` 绑定 → 超管看不到菜单
- ❌ `is_frame` 填 0 误理解为内嵌
- ❌ 为外链写自定义 iframe Vue 组件
- ❌ 前端 views 下实际没有 component 指向的文件
