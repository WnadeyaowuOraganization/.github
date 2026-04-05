# 开发规范

## 页面组件

- 页面组件统一放在 `apps/web-antd/src/views/<模块>/` 下
- 每个模块一个目录，主入口文件为 `index.vue`
- 子页面/抽屉/弹窗等组件放在同一目录下，命名使用 `kebab-case`（如 `tender-detail-drawer.vue`）
- 组件内部命名使用 **PascalCase**（如 `<TenderDetailDrawer />`）

## API 调用

- API 封装文件放在 `apps/web-antd/src/api/<模块>/` 下
- 万德业务 API 统一放在 `apps/web-antd/src/api/wande/` 下
- 使用项目已有的 `requestClient` 工具进行 HTTP 请求
- 接口返回类型使用 TypeScript 接口/类型定义

```typescript
import { requestClient } from '#/api/request';

export interface TenderItem {
  id: number;
  title: string;
}

export function getTenderList(params: Record<string, any>) {
  return requestClient.get<TenderItem[]>('/wande/tender/list', { params });
}
```

### API 对接验证规则（必须遵守）

- 新增或修改 API 调用前，**必须**先读取对应的后端 Controller 源码确认：
  1. **HTTP 方法**：GET / POST / PUT / DELETE
  2. **参数传递方式**：`@PathVariable` vs `@RequestParam` vs `@RequestBody`
  3. **实际路径**：包括动态路径段的格式
- 后端 Controller 源码位置：`ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/controller/`
- **禁止**凭推断或"合理猜测"编写 API 调用路径和方法

## 路由模块

- 路由模块文件：`apps/web-antd/src/router/routes/modules/wande.ts`
- 路由 `name` 使用 **PascalCase**，路径使用 **kebab-case**
- 需要权限控制的路由在 `meta` 中配置 `authority`

## 状态管理

- 使用 **Pinia**，命名规范：`use<模块>Store`
- 优先使用组件级本地状态（`ref/reactive`），只有跨组件共享数据才放 Pinia

## 命名规范汇总

| 类型 | 命名规范 | 示例 |
|------|----------|------|
| 组件名（内部引用） | PascalCase | `<TenderDetailDrawer />` |
| 文件名（vue/ts） | kebab-case 或 camelCase | `tender-detail-drawer.vue` |
| 路由 name | PascalCase | `WandeTender` |
| 路由 path | kebab-case | `/wande/tender` |
| API 函数 | camelCase | `getTenderList` |
| Store | camelCase + use 前缀 | `useWandeStore` |
| 类型/接口 | PascalCase | `TenderItem` |

## 菜单显示机制（重要）

本项目的侧边栏菜单**不是**由前端路由文件静态决定的，而是由**后端 `sys_menu` 表**动态驱动。

**加载流程**：
1. 用户登录后，前端调用 `/system/menu/getRouters` 获取菜单树
2. 后端根据用户角色查询 `sys_menu` + `sys_role_menu` 表
3. 前端将后端返回的菜单转换为 Vue Router 路由（见 `src/router/access.ts` 的 `backMenuToVbenMenu`）

**前端开发新页面完整清单**：
1. 在 `views/wande/` 下创建页面组件
2. 在 `api/wande/` 下创建对应的 API 调用
3. **通知后端**创建 `sys_menu` 增量 SQL — 这一步决定菜单是否显示
4. 确保 `component` 字段值与 `views/` 下的实际路径匹配

## 后端接口前缀

| 模块 | 接口前缀 |
|------|----------|
| 招投标管理 | `/wande/tender/*` |
| 项目挖掘 | `/wande/project/*` |
| 商机管理 | `/wande/opportunity/*` |
| CRM 客户 | `/wande/crm/*` |
| 竞品分析 | `/wande/competitor/*` |
| 企微管理 | `/wande/wecom/*` |
| 仪表盘 | `/wande/dashboard/*` |
