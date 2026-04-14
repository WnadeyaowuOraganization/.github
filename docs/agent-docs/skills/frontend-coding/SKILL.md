---
name: frontend-coding
description: Write Vue 3 + Vben Admin 5.x + Ant Design Vue 4.x + vxe-table frontend code for Wande-Play. Enforces useVbenVxeGrid (no native Table), useVbenDrawer (no native Modal), native ant-Drawer with v-model:open for detail drawers (no connectedComponent wrapper per #3544), Page container, independent data.ts, slot-based rendering (no h() functions), multi-zone Row/Col/Card layout, and request client API layer. Use for any change under frontend/apps/web-antd/src/views/.
---

# 前端编码规范

Vue 3 `<script setup>` + TypeScript + Vite + Vben Admin 5.x + Ant Design Vue 4.x + vxe-table + Tailwind CSS + pnpm。

## 文件组织（每个列表页模块）

```
frontend/apps/web-antd/src/views/<板块>/<模块>/
├── index.vue                   # 列表主页
├── data.ts                     # columns + querySchema + drawerSchema
├── <模块>-detail-drawer.vue    # 详情/编辑纯内容子组件
├── edit-modal.vue              # 新增/修正 Modal (若需要)
└── __tests__/<模块>.test.ts    # 组件测试
```

- API 层：`src/api/wande/<模块>.ts`
- 组件名 PascalCase，文件名 kebab-case，路由 name PascalCase，path kebab-case
- **禁止** columns / querySchema / drawerSchema 内联在 `.vue`

## 组件选型（强制）

| 场景 | 必须用 | 禁止 |
|------|-------|------|
| 列表表格 | `useVbenVxeGrid` | 原生 `Table from ant-design-vue` |
| 查询表单 | `VbenFormProps + querySchema` | 手写 `ref + Input` 拼搜索 |
| 详情抽屉 | **原生 `<Drawer v-model:open>`** 内嵌 | `useVbenDrawer({connectedComponent})` 包装 |
| 页面容器 | `<Page :auto-content-height="true">` | 裸 `<div>` |
| 权限控制 | `v-access:code="['wande:xxx:xx']"` + `useAccess` | 硬编码角色判断 |
| 复选框状态 | `vxeCheckboxChecked(tableApi)` | 手写 `checked.value` |
| 弹出层容器 | `getVxePopupContainer` / `getPopupContainer` | 默认（会被表格滚动裁切）|
| 文件下载 | `commonDownloadExcel` | 手写 `a.href + click` |

## Drawer（#3544 教训）

**首选原生 `<Drawer v-model:open>` 内嵌**，不要用 `useVbenDrawer + connectedComponent`。

```vue
<script setup lang="ts">
import { ref } from 'vue';
import { Drawer } from 'ant-design-vue';

const detailOpen = ref(false);
const detailData = ref<any>(null);

function handleDetail(row: any) {
  detailData.value = row;
  detailOpen.value = true;
}
</script>

<template>
  <Page :auto-content-height="true">
    <BasicTable @row-click="handleDetail" />

    <Drawer v-model:open="detailOpen" title="详情" :width="900"
            :footer-style="{ textAlign: 'right' }">
      <a-tabs>
        <a-tab-pane key="info" tab="基本信息">...</a-tab-pane>
      </a-tabs>
      <template #footer>
        <a-button @click="detailOpen = false">关闭</a-button>
      </template>
    </Drawer>
  </Page>
</template>
```

参考：`frontend/apps/web-antd/src/views/operator/knowledgeBase/index.vue`。

**必用 `v-model:open`**（AntDV 4.x），`:visible` + `@close` 已废弃。

内容复杂需拆分时：父页面 `index.vue` 负责 `<Drawer>` overlay，子组件 `xxx-detail-content.vue` 只是纯 `<div>` + props，不含 overlay 逻辑。

## 标准 index.vue 骨架

```vue
<script setup lang="ts">
import { onMounted, ref } from 'vue';
import type { VbenFormProps } from '@vben/common-ui';
import type { VxeGridProps } from '#/adapter/vxe-table';
import { useAccess } from '@vben/access';
import { Page } from '@vben/common-ui';
import { Modal, Popconfirm, Space, Statistic, Drawer } from 'ant-design-vue';
import { PlusOutlined, DownloadOutlined } from '@ant-design/icons-vue';
import { useVbenVxeGrid, vxeCheckboxChecked } from '#/adapter/vxe-table';
import { getVxePopupContainer } from '@vben/utils';
import { xxxList, xxxRemove, xxxExport, xxxStats } from '#/api/wande/xxx';
import { commonDownloadExcel } from '#/utils/file/download';
import { columns, querySchema } from './data';

const formOptions: VbenFormProps = {
  commonConfig: { labelWidth: 80, componentProps: { allowClear: true } },
  schema: querySchema(),
  wrapperClass: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5',
};
const gridOptions: VxeGridProps = {
  checkboxConfig: { highlight: true, reserve: true },
  columns,
  height: 'auto',
  pagerConfig: {},
  proxyConfig: {
    ajax: {
      query: async ({ page }, formValues = {}) =>
        xxxList({ pageNum: page.currentPage, pageSize: page.pageSize, ...formValues }),
    },
  },
  rowConfig: { keyField: 'id' },
  id: 'wande-xxx-index',
};
const [BasicTable, tableApi] = useVbenVxeGrid({ formOptions, gridOptions });

const stats = ref({ total: 0 });
async function loadStats() {
  try { stats.value = (await xxxStats()) || stats.value; }
  catch (e) { console.error('加载统计失败', e); }
}
onMounted(loadStats);

const { hasAccessByCodes } = useAccess();
</script>
```

## data.ts 骨架

```typescript
import type { FormSchemaGetter } from '#/adapter/form';
import type { VxeGridProps } from '#/adapter/vxe-table';
import { getPopupContainer } from '@vben/utils';

export const querySchema: FormSchemaGetter = () => [
  { component: 'Input', fieldName: 'keyword', label: '关键词',
    componentProps: { placeholder: '请输入', allowClear: true } },
  { component: 'Select', fieldName: 'status', label: '状态',
    componentProps: { getPopupContainer, options: [{label:'A',value:'a'}] } },
];

export const columns: VxeGridProps['columns'] = [
  { type: 'checkbox', width: 60 },
  { field: 'id', title: 'ID', width: 80 },
  { field: 'name', title: '名称', minWidth: 200, showOverflow: true },
  { field: 'status', title: '状态', width: 100, slots: { default: 'status' } },
  { field: 'action', fixed: 'right', slots: { default: 'action' }, title: '操作', width: 200 },
];
```

## slots 返回 VNode（约束 4）

**`slots.default` 函数禁止返回 HTML 字符串**（#3487 事故）。

```ts
// ❌ 错
slots: { default: ({row}) => `<a-tag>${row.label}</a-tag>` }

// ✅ 用 template slot 名
slots: { default: 'colName' }
// index.vue
<template #colName="{row}"><a-tag>{{row.label}}</a-tag></template>

// ✅ 或 h() 函数返回（少用，仅简单场景）
import { h } from 'vue';
slots: { default: ({row}) => h(ATag, { color: 'green' }, () => row.label) }
```

## API 层

```typescript
// src/api/wande/xxx.ts
import { requestClient } from '#/api/request';
import type { PageResult, XxxItem } from './types';

export function xxxList(params: any) {
  return requestClient.get<PageResult<XxxItem>>('/wande/xxx/list', { params });
}
export function xxxAdd(data: any)    { return requestClient.post('/wande/xxx', data); }
export function xxxEdit(data: any)   { return requestClient.put('/wande/xxx', data); }
export function xxxRemove(ids: any[]){ return requestClient.delete(`/wande/xxx/${ids.join(',')}`); }
export function xxxExport(data: any) {
  return requestClient.post('/wande/xxx/export', data, { responseType: 'blob' });
}
```

`/wande/*` 前缀走 Vite 代理到后端 `:6040`。禁止组件里直接 `fetch` / `axios`。

## 多分区页面（Row / Col / Card 模板）

原型图含多个独立内容区块时，必须用 `Row + Col + Card`，不要裸 `<div>`。

```vue
<Page :auto-content-height="true">
  <Row :gutter="16">
    <Col :span="12">
      <Card title="分区 A" size="small">
        <Space direction="vertical" style="width:100%" :size="16">
          <Input v-model:value="xxx" />
          <Button type="primary" block @click="handleA">操作 A</Button>
          <Divider />
          <Alert v-if="resultA" type="success" :message="resultA" />
        </Space>
      </Card>
    </Col>
    <Col :span="12"><Card title="分区 B" size="small">...</Card></Col>
  </Row>

  <Row :gutter="16" style="margin-top:16px">
    <Col :span="24"><Card title="分区 C" size="small">...</Card></Col>
  </Row>
</Page>
```

gutter 固定 16，行间距 `margin-top: 16px`。**禁止** `el-row` / `el-col`（element-plus），只用 ant-design-vue 的 `Row`/`Col`。

## 禁止清单

| 禁止 | 正确替代 |
|------|---------|
| `visible` 属性 | `v-model:open`（AntDV 4.x） |
| 嵌套 Drawer / Modal | 独立组件 + 事件通信 |
| `useVbenDrawer({connectedComponent})` 内 template 最外层是 `<div>` / `<Page>` | 用原生 `<Drawer v-model:open>` 父页面内嵌 |
| 前端路由不配 `sys_menu` | Flyway UPDATE 占位菜单 |
| iframe 自建 Vue 组件 | `sys_menu` path=http URL 配置 |
| `any` 类型 | 明确类型 / `unknown` + 类型断言 |
| 直接编辑 baseline SQL | Flyway 增量脚本 |
| 在 `wande-ai-api` 加业务代码 | 放 `ruoyi-modules/wande-ai` |
| root 跑 mvn | ubuntu 用户 |
| push `dev` / `main` | 只 push `feature-Issue-<N>` |
| `h()` 构建整套编辑表单 / Modal.confirm 嵌 Select | 拆独立 `.vue` 子组件 |
| 原生 `Table` / `TableColumns` | `useVbenVxeGrid` / `VxeGridProps['columns']` |
| 手写分页（`pagination.current` ref）| `proxyConfig.ajax` 自动 |
| 手写 loading 状态 | proxyConfig 自动 |
| `alert('xxx')` | `message.success/error/warning` |
| 内联 `style="width:180px"` | Tailwind 类 / `<style scoped>` |
| 硬编码颜色（`#1890ff`） | CSS 变量 `var(--primary)` / Tailwind |
| 相对路径 `../../../` | `#/` 别名 |

## AntDV 4.x 可直接用的组件

`Statistic / Card / Modal.confirm / Popconfirm / Space / Tag / Tabs / message / Drawer / @ant-design/icons-vue`。

## 国际化

所有用户文案用 `$t('key')` / `t('key')`。硬编码中文 → Lint 报错。

## 构建验证（提交前必过）

```bash
cd frontend && pnpm build       # 必须零错误零新警告
cd frontend && pnpm lint        # 可选，Lint 警告建议修
```

TS 报错禁用 `@ts-ignore` 绕过，除非注释说清原因。

## 标杆参考页面

| 页面 | 路径 | 特点 |
|------|------|------|
| 招投标管理 | `views/wande/tender/index.vue` | 三层布局标准模板 |
| knowledgeBase | `views/operator/knowledgeBase/index.vue` | 原生 Drawer 典型用法（照抄结构，不照抄旧 `:visible`） |
| Cockpit | 多 Tab 各自 useVbenVxeGrid | 拆分标杆 |
