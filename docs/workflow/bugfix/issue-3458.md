# Bugfix: #3458 项目矿场页面无数据 + 缺少Tab切换

## 问题概述

| 项 | 值 |
|----|-----|
| Issue | #3458 |
| 模块 | 项目矿场 (project-mine) |
| 严重度 | P1 — 页面完全无法使用 |
| 发现者 | 手动测试 |
| 修复日期 | 2026-04-13 |

## Bug 1: 列表查询弹窗报错，无数据展示

### 根因

后端 `ProjectMineServiceImpl.selectProjectMineList()` 使用 `new TableDataInfo<>()` 手动构造响应对象，只设置了 `rows` 和 `total`，**缺少 `code` 和 `msg` 字段**。

前端 Vben 的请求拦截器 (`request.ts` L251-280) 默认开启 `isTransformResponse: true`，会检查响应中是否有 `code` 字段：
```js
const hasSuccess = Reflect.has(axiosResponseData, 'code') && code === BUSINESS_SUCCESS_CODE;
```
由于后端响应缺少 `code`，`hasSuccess = false`，拦截器抛出错误并弹出 antd message 提示。

### 修复

```java
// ❌ Before
TableDataInfo<ProjectMineVO> result = new TableDataInfo<>();
result.setRows(list);
result.setTotal(list.size());
return result;

// ✅ After
return TableDataInfo.build(list);
```

`TableDataInfo.build(list)` 内部自动设置 `code=200`, `msg="查询成功"`，符合 RuoYi 框架标准响应格式。

### 关键教训

> **RuoYi 列表接口必须使用 `TableDataInfo.build(list)` 静态方法，禁止手动 `new TableDataInfo<>()`。**

手动构造会遗漏 `code`/`msg`，前端拦截器无法识别为成功响应。

---

## Bug 2: 缺少6个Tab分类切换

### 根因

设计文档要求6个Tab（全部/前期金矿/当前可投/待我确认/休眠无效/垃圾桶），编程CC只实现了列表页面框架，未实现Tab切换功能。

### 修复

前端 `index.vue` 添加：
- `Tabs` + `TabPane` 组件（ant-design-vue）
- `activeTab` 状态 + `tabList` 数据 + `handleTabChange` 回调
- 查询参数增加 `mineCategory` 字段传递给后端

API 类型 `ProjectMineListParams` 增加 `mineCategory?: string` 字段。

---

## Bug 3: crm.ts 静态路由前缀未更新（#3613遗留）

### 根因

\#3613 菜单迁移将 CRM 路由从 `/wande/crm` 迁移到 `/business/crm`，并删除了 `views/wande/crm/` 目录。但静态路由文件 `crm.ts` 中的 `component: () => import('#/views/wande/crm/...')` 未同步更新。

Vite 编译时会解析所有静态 `import()` 路径，找不到已删除的目录导致构建失败。

### 修复

`crm.ts` 中所有 `wande/crm` → `business/crm`（路径和组件导入）。

### 关键教训

> **菜单迁移必须同步检查静态路由文件的 import 路径，即使系统使用动态路由。Vite 会在编译期解析所有静态 import。**

---

## 防错 Prompt（加入编程CC技能或CLAUDE.md）

```
## RuoYi 前后端接口对接规范

### 列表接口响应格式
- 后端列表接口必须返回 `{code: 200, msg: "查询成功", rows: [...], total: N}` 格式
- **必须使用** `TableDataInfo.build(list)` 静态方法构造响应
- **禁止** `new TableDataInfo<>()` 手动构造——会丢失 code/msg 字段
- 前端拦截器依赖 code 字段判断成功，缺失会导致弹窗报错、数据不展示

### 单体接口响应格式
- 使用 `R.ok(data)` 或 `R.fail(msg)` 返回
- 同样禁止手动构造 R 对象

### 菜单迁移检查清单
- [ ] Flyway 迁移脚本更新 sys_menu 表
- [ ] 前端 views 目录迁移
- [ ] 静态路由文件 import 路径同步更新（即使使用动态路由，Vite 仍会解析静态 import）
- [ ] API 文件路径更新
```

---

## 调查：为什么明显的格式错误能通过层层测试

### 测试覆盖现状

| 层级 | project-mine 覆盖 | 说明 |
|------|-------------------|------|
| 后端单元测试 | **零** | 无 `*ProjectMine*Test.java` 文件 |
| 前端单元测试 | **零** | 无 `*.spec.*` 或 `*.test.*` 文件 |
| E2E测试 | **不覆盖** | E2E 仅验证页面是否能打开，不验证 API 响应格式 |
| CI 编译检查 | **只检查语法** | `mvn -Dmaven.test.skip=true`，前端 `pnpm build` 只做类型检查 |
| task.md 自检 | **给假信心** | 编程CC在 task.md 写"已测试通过"，实际只是确认代码能编译 |

### 泄漏路径

```
编程CC写代码 → 编译通过 → task.md写"完成" → CI构建通过 → 部署到测试环境
                                                              ↓
                                                    手动打开页面才发现报错
```

每一层只验证了"代码能编译"，没有任何一层验证"前后端联调是否正常"：

1. **后端编译通过** — `TableDataInfo` 的 setter 是合法的 Java 代码，编译器不会报错
2. **前端编译通过** — TypeScript 类型只声明了 `rows/total`，不包含 `code/msg`（因为 code 由框架层注入）
3. **CI只做 build** — 没有集成测试或冒烟测试
4. **E2E不检查数据** — 只截图看页面渲染，不检查 API 响应体

### 结论

这不是某一层的失职，而是**整个验证链条中完全缺失"前后端联调验证"环节**。建议：

1. **短期**：编程CC的 task.md 模板增加「API联调自检」步骤，要求用 curl 验证接口返回格式
2. **中期**：E2E 增加 API 响应格式断言（检查 code=200 且 rows 非空）
3. **长期**：后端对 `TableDataInfo` 添加编译期/运行时校验，确保 code 字段非空
