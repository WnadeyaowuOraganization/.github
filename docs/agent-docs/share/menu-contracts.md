
本系统的前端菜单由**后端 `sys_menu` 表**驱动（`wande-ai` 数据库），前端通过 `/system/menu/getRouters` API 动态获取菜单树。**仅创建 Controller/页面/路由是不够的，必须同时在 `sys_menu` 表中注册菜单，否则前端不会显示任何入口。**

#### 何时需要注册菜单

| 场景 | 是否需要注册 sys_menu |
|------|----------------------|
| 新增业务模块（如「供应商管理」） | **必须** — 需要一级目录 + 二级菜单 + 按钮权限 |
| 新增子页面（如「招投标/AI评估」） | **必须** — 需要二级或三级菜单 |
| 新增操作按钮权限（如「导出」「删除」） | **必须** — 需要按钮类型菜单(menu_type=F) |
| 修改已有页面的字段/样式 | 不需要 |
| 纯 API 接口无页面 | 不需要 |

#### 操作步骤

**第 1 步：编写 Flyway 迁移脚本**

在 `backend/ruoyi-admin/src/main/resources/db/migration/` 下创建 Flyway 迁移文件：

文件命名：`V{YYYYMMDD}{序号}__{描述}.sql`（双下划线分隔，序号三位，如 `V20260413001__add_xxx_menu.sql`）

```sql
-- 动态获取当前最大 menu_id，避免 ID 冲突
SET @max_id = (SELECT COALESCE(MAX(menu_id), 0) FROM sys_menu);

-- 一级目录（menu_type=M，仅新模块需要；is_frame=1 表示非外链）
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 1, '模块名称', 0, 10, 'xxx', '', 1, 0, 'M', '0', '0', '', 'icon-name', 'admin', NOW(), 'admin', NOW(), '模块说明');
SET @parent_id = @max_id + 1;

-- 二级菜单（menu_type=C 页面菜单）
-- component 前缀按所属板块确定，见下方"component/perms 前缀对照表"
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 2, '子模块名称', @parent_id, 1, 'path-name', '{prefix}/xxx/index', 1, 0, 'C', '0', '0', '{perms-prefix}:xxx:list', '', 'admin', NOW(), 'admin', NOW(), '');
SET @menu_id = @max_id + 2;

-- 按钮权限（menu_type=F，parent_id 指向所属页面菜单）
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 3, '查询', @menu_id, 1, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:query', '', 'admin', NOW(), 'admin', NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 4, '新增', @menu_id, 2, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:add', '', 'admin', NOW(), 'admin', NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 5, '修改', @menu_id, 3, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:edit', '', 'admin', NOW(), 'admin', NOW(), '');
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (@max_id + 6, '删除', @menu_id, 4, '', '', 1, 0, 'F', '0', '0', '{perms-prefix}:xxx:remove', '', 'admin', NOW(), 'admin', NOW(), '');

-- 角色绑定菜单（role_id=1 为超级管理员，确保新菜单对管理员可见）
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 1);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 2);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 3);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 4);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 5);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) VALUES (1, @max_id + 6);
```

**第 2 步：确定 menu_id**

- 使用 `SET @max_id = (SELECT COALESCE(MAX(menu_id), 0) FROM sys_menu);` 动态获取，避免硬编码 ID 冲突
- 同一迁移脚本内通过 `@max_id + N` 递增分配

**第 3 步：字段说明**

| 字段 | 说明 |
|------|------|
| menu_type | `M`=目录 `C`=菜单页面 `F`=按钮权限 |
| parent_id | 父菜单ID，根据所属业务模块指向对应一级目录 |
| path | 路由路径（kebab-case），如 `supplier-rating` |
| component | 前端组件路径，前缀按板块不同（见下表），对应 `views/` 下的 `.vue` 文件 |
| perms | 权限标识，前缀按板块不同（见下表），必须与 Controller 的 `@SaCheckPermission` 一致 |
| visible | `0`=显示 `1`=隐藏 |
| is_frame | 控制页面打开方式，**固定填 `1`**。外链由 path 是否以 `http(s)://` 开头决定，与此字段无关 |

**component / perms 前缀对照表**（按所属板块确定）：

| 板块 | component 前缀 | perms 前缀              | 示例 |
|------|---------------|-----------------------|------|
| 超管驾驶舱 | `cockpit/` | `cockpit:`            | `cockpit/dashboard/index` / `cockpit:dashboard:list` |
| 商务部→招投标 | `business/tender/` | `biz:tender:`         | `business/tender/bid/index` / `biz:tender:bid:list` |
| 商务部→CRM | `business/crm/` | `biz:crm:`            | `business/crm/customer/index` / `biz:crm:customer:list` |
| 支持中心 | `support/` | `support:`            | `support/d3/cases/index` / `support:d3:cases:list` |
| 综合管理中心 | `admin-center/` | `admin:`              | `admin-center/finance/payable/index` / `admin:finance:payable:list` |
| 安装售后中心 | `install/` | `install:`            | `install/budget/templates/index` / `install:budget:templates:list` |
| 公共板块 | `common/` / `portal/` | `common:` / `portal:` | `common/files/index` / `common:files:list` |
| 资源中心 | `resource/` | `resource:`           | `resource/competitor/analysis/index` / `resource:competitor:analysis:list` |
| 系统管理 | `system/` | `system:`             | `system/user/index` / `system:user:list` |

#### 自查清单

新增功能模块提交前，检查以下菜单相关项：

- [ ] 前端页面优先替换 `frontend/apps/web-antd/src/views/` 对应路由目录下的占位页面；如无占位页面，按上方前缀对照表生成标准的path、component、perms，将新菜单补充到下方目录树表格中，index.vue根据component定义的目录存放
- [ ] Flyway 迁移脚本已创建在 `backend/ruoyi-admin/src/main/resources/db/migration/` 下，并填充正确的path、component、perms
- [ ] 文件命名符合 `V{YYYYMMDD}{序号}__{描述}.sql` 格式
- [ ] menu_id 使用 `@max_id` 动态获取，不硬编码
- [ ] component 路径与前端 views 目录下的实际文件路径一致
- [ ] perms 权限标识与 Controller `@SaCheckPermission` 注解一致
- [ ] sys_role_menu 已绑定 role_id=1（超级管理员）

#### 完整菜单目录树表格（权威参考）

> 目录树来源：`docs/design/all-in-one/菜单重组完整规划.md`

新增菜单前先对照下表确定 parent_id 和归属分组：

**超管驾驶舱**（一级 path: `cockpit`）[仅超管+Boss可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 驾驶舱首页 | `dashboard` | `cockpit/dashboard/index` | `cockpit:dashboard:list` |
| Issue看板 | `issue-board` | `cockpit/issue-board/index` | `cockpit:issue:board:list` |
| 开发者动态 | `dev-activity` | `cockpit/dev-activity/index` | `cockpit:dev:activity:list` |
| 运维监控 | `monitor` | `cockpit/monitor/index` | `cockpit:monitor:list` |
| 企微控制台 | `wecom` | `cockpit/wecom/index` | `cockpit:wecom:list` |
| 工作日志 | `work-log` | `cockpit/work-log/index` | `cockpit:worklog:list` |
| 仪表盘 | `metrics` | `cockpit/metrics/index` | `cockpit:metrics:list` |
| Credit消耗统计 | `credit` | `cockpit/credit/index` | `cockpit:credit:list` |
| Claude Office | `http://...` | [外链] | `cockpit:claude:list` |
| G7e监控 | `g7e` | `cockpit/g7e/index` | `cockpit:g7e:list` |
| 工具详情 | `tools` | `cockpit/tools/index` | `cockpit:tools:list` |

**商务部 → 招投标中心**（一级 path: `business`，二级 path: `tender`）[商务+Boss可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 项目挖掘 | `prospect` | `business/tender/prospect/index` | `biz:tender:prospect:list` |
| 商机管理 | `opportunity` | `business/tender/opportunity/index` | `biz:tender:opportunity:list` |
| 招投标管理 | `bid` | `business/tender/bid/index` | `biz:tender:bid:list` |
| AI评估 | `ai-eval` | `business/tender/ai-eval/index` | `biz:tender:aieval:list` |
| 采集源 | `source` | `business/tender/source/index` | `biz:tender:source:list` |

**商务部 → CRM客户管理**（一级 path: `business`，二级 path: `crm`）

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 商务工作台 | `dashboard` | `business/crm/dashboard/index` | `biz:crm:dashboard:list` |
| 客户管理 | `customer` | `business/crm/customer/index` | `biz:crm:customer:list` |
| 商机管道 | `opportunity` | `business/crm/opportunity/index` | `biz:crm:opportunity:list` |
| 回款跟踪 | `payment` | `business/crm/payment/index` | `biz:crm:payment:list` |
| 经销商管理 | `dealer` | `business/crm/dealer/index` | `biz:crm:dealer:list` |
| 记录中心 | `activity` | `business/crm/activity/index` | `biz:crm:activity:list` |
| 询盘工作台 | `inquiry` | `business/crm/inquiry/index` | `biz:crm:inquiry:list` |
| 投标申请 | `bidding` | `business/crm/bidding/index` | `biz:crm:bidding:list` |
| 我的提成 | `commission` | `business/crm/commission/index` | `biz:crm:commission:list` |

**商务部 → 占位目录**

| 菜单名 | path | component 前缀 | perms 前缀 |
|--------|------|---------------|-----------|
| 国际贸易 | `trade` | `business/trade/` | `biz:trade:` |
| 代理商工作台 | `dealer-portal` | `business/dealer/` | `biz:dealer:` |

**支持中心**（一级 path: `support`）[设计师+支持中心+Boss可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 品牌中心 | `brand` | `support/brand/index` | `support:brand:list` |
| 方案引擎 | `solution` | `support/solution/index` | `support:solution:list` |
| 供应商管理 | `supplier` | `support/supplier/index` | `support:supplier:list` |
| 协同修改 | `collab` | `support/collab/index` | `support:collab:list` |
| D3设计中心→案例管理 | `cases` | `support/d3/cases/index` | `support:d3:cases:list` |
| D3设计中心→参数化设计 | `parametric` | `support/d3/parametric/index` | `support:d3:parametric:list` |
| D3设计中心→组件库 | `components` | `support/d3/components/index` | `support:d3:components:list` |
| D3设计中心→材质库 | `materials` | `support/d3/materials/index` | `support:d3:materials:list` |
| D3设计中心→渲染管理 | `render` | `support/d3/render/index` | `support:d3:render:list` |
| D3设计中心→3D预览 | `preview` | `support/d3/preview/index` | `support:d3:preview:list` |
| D3设计中心→导出管理 | `export` | `support/d3/export/index` | `support:d3:export:list` |
| AI渲染助手→渲染任务 | `tasks` | `support/ai-render/tasks/index` | `support:render:tasks:list` |
| AI渲染助手→渲染模板 | `templates` | `support/ai-render/templates/index` | `support:render:templates:list` |
| 安全管理→安全标准 | `standards` | `support/safety/standards/index` | `support:safety:standards:list` |
| 安全管理→安全检查 | `inspection` | `support/safety/inspection/index` | `support:safety:inspection:list` |
| 安全管理→问题台账 | `issues` | `support/safety/issues/index` | `support:safety:issues:list` |
| 安全管理→整改跟踪 | `rectify` | `support/safety/rectify/index` | `support:safety:rectify:list` |
| 产品参数查询中心 | `product-params` | `support/product-params/index` | `support:product:params:list` |
| 产品管理 | `product-mgmt` | `support/product-mgmt/index` | `support:product:mgmt:list` |
| 设计素材 | `design-assets` | `support/design-assets/index` | `support:design:assets:list` |
| 备品备件 | `spare-parts` | `support/spare-parts/index` | `support:spare:parts:list` |
| 生命周期管理 | `lifecycle` | `support/lifecycle/index` | `support:lifecycle:list` |

**综合管理中心**（一级 path: `admin-center`）[综合管理+Boss可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 人事管理 | `hr` | `admin-center/hr/index` | `admin:hr:list` |
| 提成绩效 | `commission` | `admin-center/commission/index` | `admin:commission:list` |
| 报销费控 | `expense` | `admin-center/expense/index` | `admin:expense:list` |
| 统一权限管理 | `permission` | `admin-center/permission/index` | `admin:permission:list` |
| 财务管理→应付账款 | `payable` | `admin-center/finance/payable/index` | `admin:finance:payable:list` |
| 财务管理→凭证管理 | `voucher` | `admin-center/finance/voucher/index` | `admin:finance:voucher:list` |
| 财务管理→律师催收 | `collection` | `admin-center/finance/collection/index` | `admin:finance:collection:list` |
| 工作流配置→流程定义 | `definition` | `admin-center/workflow/definition/index` | `admin:workflow:def:list` |
| 工作流配置→流程实例 | `instance` | `admin-center/workflow/instance/index` | `admin:workflow:instance:list` |
| 工作流配置→流程表单 | `form` | `admin-center/workflow/form/index` | `admin:workflow:form:list` |
| 政策中心 | `policy` | `admin-center/policy/index` | `admin:policy:list` |

**安装售后中心**（一级 path: `install-service`）[项目安装+Boss可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 执行管理 | `execution` | `install/execution/index` | `install:execution:list` |
| 预算模板库 | `templates` | `install/budget/templates/index` | `install:budget:templates:list` |
| WBS编码维护 | `wbs` | `install/budget/wbs/index` | `install:budget:wbs:list` |
| 保证金配置 | `deposit` | `install/budget/deposit/index` | `install:budget:deposit:list` |
| 质保售后 | `warranty` | `install/warranty/index` | `install:warranty:list` |

**公共板块**（一级 path: `common`）[所有角色可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 产品目录 | `product` | `portal/product/index` | `portal:product:list` |
| 产品详情 [隐藏] | `product/:id` | `portal/product/detail` | `portal:product:query` |
| 备件目录 | `part` | `portal/part/index` | `portal:part:list` |
| 门户产品管理 | `admin/product` | `portal/admin/product/index` | `portal:product:manage` |
| 分类管理 | `admin/category` | `portal/admin/category/index` | `portal:category:list` |
| 合同管理 | `contract` | `common/contract/index` | `common:contract:list` |
| 执行管理 | `execution` | `common/execution/index` | `common:execution:list` |
| 业务审批中心 | `approval` | `common/approval/index` | `common:approval:list` |
| 通知中心 | `notification` | `common/notification/index` | `common:notification:list` |
| 文件管理 | `files` | `common/files/index` | `common:files:list` |
| 项目中心 | `project` | `common/project/index` | `common:project:list` |

**资源中心**（一级 path: `resource`）[仅超管可见，后期开放]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 竞品分析 | `analysis` | `resource/competitor/analysis/index` | `resource:competitor:analysis:list` |
| 竞品告警 | `alert` | `resource/competitor/alert/index` | `resource:competitor:alert:list` |
| 投标记录 | `bid-record` | `resource/competitor/bid-record/index` | `resource:competitor:bid:list` |
| 知识管理 | `manage` | `resource/knowledge/manage/index` | `resource:knowledge:manage:list` |

**系统管理**（一级 path: `system`）[仅超管可见]

| 菜单名 | path | component | perms |
|--------|------|-----------|-------|
| 用户管理 | `user` | `system/user/index` | `system:user:list` |
| 角色管理 | `role` | `system/role/index` | `system:role:list` |
| 菜单管理 | `menu` | `system/menu/index` | `system:menu:list` |
| 部门管理 | `dept` | `system/dept/index` | `system:dept:list` |
| 岗位管理 | `post` | `system/post/index` | `system:post:list` |
| 字典管理 | `dict` | `system/dict/index` | `system:dict:list` |
| 参数设置 | `config` | `system/config/index` | `system:config:list` |
| 通知公告 | `notice` | `system/notice/index` | `system:notice:list` |
| 日志管理 | `log` | [目录] | — |


