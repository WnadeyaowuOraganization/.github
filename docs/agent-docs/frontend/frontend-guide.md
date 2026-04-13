# 前端CC 指南

> 前端CC负责万德AI平台Vue3前端页面的开发。

## 技术栈

Vue 3 (Composition API `<script setup>`) + TypeScript + Vite + Ant Design Vue + Pinia + Vue Router 4 + Tailwind CSS + pnpm + turbo + ECharts

## 项目概述

基于 [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin)（v2.0.0）二次开发，monorepo架构（pnpm + turbo）。

- 主应用：`apps/web-antd/`
- 万德业务页面：`apps/web-antd/src/views/wande/`

## 核心规则

1. **测试先行** — 每个Issue必须有组件测试（Vitest），没有测试=没完成
2. **页面规范（强制）** — 必须遵循UI-GUIDE.md
3. **构建验证** — 提交前 `pnpm build` 必须通过
4. **必须用ubuntu用户构建** — root会导致CI/CD权限失败
5. **只push feature分支** — 创建feature→dev的PR
6. **API对接必须读后端源码** — 禁止猜测HTTP方法/参数方式/路径

## UI规范强制要求

| 场景 | 必须使用 | 禁止使用 |
|------|----------|----------|
| 数据表格 | `useVbenVxeGrid` | 原生 `Table` from ant-design-vue |
| 查询表单 | `VbenFormProps` + `querySchema` | 手写搜索表单 |
| 详情/编辑 | `useVbenDrawer` | 原生 `Modal` |
| 页面容器 | `Page` 组件 | 裸 `<div>` |
| 数据配置 | 独立 `data.ts` 文件 | columns/querySchema内联 |

## 文件组织

```
views/wande/<模块>/
├── index.vue                  # 列表主页
├── data.ts                    # columns/querySchema/formSchema
├── <name>-detail-drawer.vue   # 详情抽屉
└── __tests__/                 # 组件测试
    └── <模块>.test.ts
```

- API: `apps/web-antd/src/api/wande/<模块>.ts`
- 组件名PascalCase，文件名kebab-case，路由name PascalCase，路由path kebab-case

## API调用

```typescript
import { requestClient } from '#/api/request';

export function getXxxList(params: Record<string, any>) {
  return requestClient.get<XxxItem[]>('/wande/xxx/list', { params });
}
```

万德API前缀 `/wande/*`，Vite代理 `/prod-api/` → 后端 `localhost:6040`。

## 开发流程

### 第一阶段：准备

1. 阅读Issue全部内容，创建 `./issues/issue-<N>/task.md`
2. 需求评估: A(可执行)→继续 / B(需确认)→评论Issue+标pause / C(不可执行)→评论+标blocked
3. `git checkout dev && git pull origin dev && git checkout -b feature-Issue-<N>`

### 第二阶段：执行 + 测试

1. 按 task 逐步开发，持续更新 task.md
2. 组件测试: 同级目录 `__tests__/XxxPage.test.ts`
3. 构建: `pnpm build`
4. 自检清单全部PASS

### 第三阶段：提交

```bash
git add . && git commit -m "feat(<模块>): <描述> #<Issue号>"
gh pr create --repo WnadeyaowuOraganization/wande-play \
  --base dev --head feature-Issue-<N> \
  --title "feat: <描述>" \
  --body "Fixes #<Issue号>"
```

## 门禁检查

| 检查项 | 要求 |
|--------|------|
| pnpm build | 通过 |
| 组件测试 | 已写并通过 |
| UI规范 | docs/UI-GUIDE.md 全部通过 |

## 标准页面模板

### index.vue

```vue
<script setup lang="ts">
import { Page, useVbenDrawer } from '@vben/common-ui';
import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { columns, querySchema } from './data';
import XxxDetailDrawer from './xxx-detail-drawer.vue';

const formOptions = {
  schema: querySchema(),
  wrapperClass: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5',
};

const gridOptions = {
  columns,
  pagerConfig: {},
  proxyConfig: {
    ajax: {
      query: async ({ page }, formValues = {}) => {
        return await xxxList({ pageNum: page.currentPage, pageSize: page.pageSize, ...formValues });
      },
    },
  },
};

const [BasicTable, tableApi] = useVbenVxeGrid({ formOptions, gridOptions });
const [DetailDrawer, detailDrawerApi] = useVbenDrawer({ connectedComponent: XxxDetailDrawer });
</script>

<template>
  <Page :auto-content-height="true">
    <BasicTable table-title="XXX管理">
      <template #toolbar-tools>
        <a-button @click="handleAdd">新增</a-button>
      </template>
      <template #action="{ row }">
        <ghost-button @click="handleEdit(row)">编辑</ghost-button>
      </template>
    </BasicTable>
    <DetailDrawer @reload="tableApi.query()" />
  </Page>
</template>
```

### data.ts

```typescript
import type { FormSchemaGetter } from '#/adapter/form';
import type { VxeGridProps } from '#/adapter/vxe-table';

export const querySchema: FormSchemaGetter = () => [
  { component: 'Input', fieldName: 'keyword', label: '关键词' },
];

export const columns: VxeGridProps['columns'] = [
  { type: 'checkbox', width: 60 },
  { field: 'id', title: 'ID', width: 80 },
  { field: 'name', title: '名称', minWidth: 200 },
  { field: 'action', fixed: 'right', slots: { default: 'action' }, title: '操作', width: 180 },
];
```

## 禁止事项

| 禁止 | 说明 | 正确替代 |
|------|------|----------|
| `Table` from ant-design-vue | 列表页禁止使用原生表格 | `useVbenVxeGrid` |
| `h()` 渲染函数 | 禁止用h()手写VNode | 使用模板 + slots |
| 手写分页逻辑 | 禁止自己管理分页 | `proxyConfig.ajax` |
| 手写loading状态 | 禁止手动管理 | 框架自动管理 |
| `alert('xxx')` | 禁止浏览器原生弹窗 | `message.success()` |
| 内联style | 禁止在模板中写内联样式 | Tailwind或scoped CSS |
| 配置内联 | 禁止columns/querySchema内联 | 独立data.ts |

## 参考页面

| 页面 | 文件路径 | 特点 |
|------|---------|------|
| **招投标管理** | `views/wande/tender/index.vue` | 标准三层布局 + 统计卡片 + 完整CRUD — **首选参考** |
| **竞品分析** | `views/wande/competitor/index.vue` | 多Tab + 对比功能 |
| **CRM客户** | `views/wande/crm/index.vue` | 标准列表页 + AI助手集成 |

## 详细文档（按需阅读）

### 共享文档（前后端通用）

| 文档 | 内容 | 何时读取 |
|------|------|---------|
| [shared-conventions.md](/home/ubuntu/projects/.github/docs/agent-docs/share/shared-conventions.md) | Git分支规范、环境信息、通用开发规则 | 首次接触项目时 |
| [issue-workflow.md](/home/ubuntu/projects/.github/docs/agent-docs/share/issue-workflow.md) | Issue生命周期与三阶段开发流程 | 每次开始新Issue时 |
| [api-contracts.md](/home/ubuntu/projects/.github/docs/agent-docs/share/api-contracts.md) | 前后端接口契约规范 | 涉及API对接时 |
| [db-schema.md](/home/ubuntu/projects/.github/docs/agent-docs/share/db-schema.md) | 数据库列名规范（新旧表差异） | 涉及数据字段映射时 |
| [menu-contracts.md](/home/ubuntu/projects/.github/docs/agent-docs/share/menu-contracts.md) | 菜单注册规范、component/perms前缀、完整目录树 | **新增页面时必读** |

### 前端专属文档

| 文档 | 内容 | 何时读取 |
|------|------|---------|
| [ui-guide.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/ui-guide.md) | 页面开发强制规范 | **写页面时必读** |
| [conventions.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/conventions.md) | 命名规范、文件组织 | 写代码时 |
| [testing.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/testing.md) | 组件测试规范（Vitest） | 写测试时 |
| [workflow.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/workflow.md) | 三阶段开发流程 | 每次开始新Issue时 |
| [antdv-constraints.md](/home/ubuntu/projects/.github/docs/agent-docs/frontend/antdv-constraints.md) | Ant Design Vue 4.x废弃API | 涉及组件库时 |
