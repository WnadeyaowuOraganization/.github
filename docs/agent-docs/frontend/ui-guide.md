# 万德前端页面开发规范（UI-GUIDE）

> **本文档是编程CC开发前端页面的强制规范。** 每个新建/修改的页面必须遵循本文档要求。
> 违反本文档的代码不允许提交。

---

## §1 核心原则

**所有万德业务页面必须使用框架封装组件，禁止直接使用原生 ant-design-vue 的 Table / Form / Modal 等组件来实现列表页功能。**

| 正确做法 | 错误做法 |
|----------|----------|
| `useVbenVxeGrid` — 框架封装表格 | `Table` from `ant-design-vue` — 原生表格 |
| `VbenFormProps` + `querySchema` — 框架封装表单 | 手写 `ref` + `Input` 组件拼接搜索表单 |
| `useVbenDrawer` — 框架封装抽屉 | `Modal` from `ant-design-vue` — 原生弹窗 |
| `Page` 组件包裹页面 | 裸 `<div>` 包裹页面 |
| `columns` / `querySchema` 定义在独立 `data.ts` | 所有配置内联在 `.vue` 文件中 |
| 模板 `<template>` + 声明式渲染 | `h()` 渲染函数手写 VNode |

---

## §2 标准页面结构

### 2.1 文件组织（必须遵守）

每个列表页模块至少包含以下文件：

```
views/wande/<模块>/
├── index.vue                    # 主页面（列表 + 工具栏）
├── data.ts                      # 表格列定义 + 查询表单 Schema + 抽屉表单 Schema
├── <模块>-detail-drawer.vue     # 详情/编辑抽屉组件
└── __tests__/                   # 组件测试
    └── <模块>.test.ts
```

**禁止**将 `columns`、`querySchema`、`drawerSchema` 等配置内联在 `.vue` 文件中。

### 2.2 标准列表页模板（index.vue）

```vue
<script setup lang="ts">
import { onMounted, ref } from 'vue';

import type { VbenFormProps } from '@vben/common-ui';

import type { VxeGridProps } from '#/adapter/vxe-table';
import type { XxxItem } from '#/api/wande/types';

import { useAccess } from '@vben/access';
import { Page, useVbenDrawer } from '@vben/common-ui';
import { getVxePopupContainer } from '@vben/utils';

import { Modal, Popconfirm, Space, Statistic } from 'ant-design-vue';
import { DownloadOutlined, PlusOutlined } from '@ant-design/icons-vue';

import { useVbenVxeGrid, vxeCheckboxChecked } from '#/adapter/vxe-table';
import { xxxList, xxxRemove, xxxExport, xxxStats } from '#/api/wande/xxx';
import { commonDownloadExcel } from '#/utils/file/download';

import XxxDetailDrawer from './xxx-detail-drawer.vue';
import { columns, querySchema } from './data';

// ==================== 表单配置 ====================
const formOptions: VbenFormProps = {
  commonConfig: {
    labelWidth: 80,
    componentProps: {
      allowClear: true,
    },
  },
  schema: querySchema(),
  wrapperClass: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5',
};

// ==================== 表格配置 ====================
const gridOptions: VxeGridProps = {
  checkboxConfig: {
    highlight: true,
    reserve: true,
  },
  columns,
  height: 'auto',
  keepSource: true,
  pagerConfig: {},
  proxyConfig: {
    ajax: {
      query: async ({ page }, formValues = {}) => {
        return await xxxList({
          pageNum: page.currentPage,
          pageSize: page.pageSize,
          ...formValues,
        });
      },
    },
  },
  rowConfig: {
    keyField: 'id',
  },
  id: 'wande-xxx-index',
  showOverflow: false,
};

// ==================== 初始化 ====================
const [BasicTable, tableApi] = useVbenVxeGrid({
  formOptions,
  gridOptions,
});

const [DetailDrawer, detailDrawerApi] = useVbenDrawer({
  connectedComponent: XxxDetailDrawer,
});

// ==================== 统计数据 ====================
const stats = ref({ total: 0 /* ... */ });

async function loadStats() {
  try {
    const data = await xxxStats();
    stats.value = data || stats.value;
  } catch (error) {
    console.error('加载统计数据失败:', error);
  }
}

onMounted(() => {
  loadStats();
});

// ==================== 操作方法 ====================
function handleAdd() {
  detailDrawerApi.setData({});
  detailDrawerApi.open();
}

async function handleEdit(record: XxxItem) {
  detailDrawerApi.setData({ id: record.id });
  detailDrawerApi.open();
}

async function handleDelete(row: XxxItem) {
  await xxxRemove([row.id]);
  await tableApi.query();
  loadStats();
}

function handleMultiDelete() {
  const rows = tableApi.grid.getCheckboxRecords();
  const ids = rows.map((row: XxxItem) => row.id);
  Modal.confirm({
    title: '提示',
    okType: 'danger',
    content: `确认删除选中的 ${ids.length} 条记录吗？`,
    onOk: async () => {
      await xxxRemove(ids);
      await tableApi.query();
      loadStats();
    },
  });
}

function handleDownloadExcel() {
  commonDownloadExcel(xxxExport, '数据导出', tableApi.formApi.form.values);
}

const { hasAccessByCodes } = useAccess();
</script>

<template>
  <Page :auto-content-height="true">
    <!-- 统计卡片区域 -->
    <div class="stats-cards mb-4">
      <a-card class="stat-card">
        <Statistic title="总数" :value="stats.total" />
      </a-card>
      <!-- 更多统计卡片... -->
    </div>

    <!-- 表格区域（框架封装，包含搜索表单 + 表格 + 分页） -->
    <BasicTable table-title="XXX管理">
      <template #toolbar-tools>
        <Space>
          <a-button
            v-access:code="['wande:xxx:export']"
            @click="handleDownloadExcel"
          >
            <DownloadOutlined /> 导出
          </a-button>
          <a-button
            :disabled="!vxeCheckboxChecked(tableApi)"
            danger
            type="primary"
            v-access:code="['wande:xxx:remove']"
            @click="handleMultiDelete"
          >
            删除
          </a-button>
          <a-button
            v-access:code="['wande:xxx:add']"
            @click="handleAdd"
          >
            <PlusOutlined /> 新增
          </a-button>
        </Space>
      </template>
      <template #action="{ row }">
        <Space>
          <ghost-button
            v-access:code="['wande:xxx:edit']"
            @click.stop="handleEdit(row)"
          >
            编辑
          </ghost-button>
          <Popconfirm
            :get-popup-container="getVxePopupContainer"
            placement="left"
            title="确认删除？"
            @confirm="handleDelete(row)"
          >
            <ghost-button
              danger
              v-access:code="['wande:xxx:remove']"
              @click.stop=""
            >
              删除
            </ghost-button>
          </Popconfirm>
        </Space>
      </template>
    </BasicTable>
    <DetailDrawer @reload="tableApi.query(); loadStats();" />
  </Page>
</template>

<style lang="scss" scoped>
.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.stat-card {
  :deep(.ant-statistic-title) {
    font-size: 14px;
    color: rgba(0, 0, 0, 0.65);
  }
  :deep(.ant-statistic-content) {
    font-size: 24px;
    font-weight: 600;
  }
}
</style>
```

### 2.3 标准数据配置模板（data.ts）

```typescript
import type { FormSchemaGetter } from '#/adapter/form';
import type { VxeGridProps } from '#/adapter/vxe-table';

import { getPopupContainer } from '@vben/utils';

import type { XxxItem } from '#/api/wande/types';

// ==================== 查询表单 Schema ====================
export const querySchema: FormSchemaGetter = () => [
  {
    component: 'Input',
    componentProps: {
      placeholder: '请输入关键词',
    },
    fieldName: 'keyword',
    label: '关键词',
  },
  {
    component: 'Select',
    componentProps: {
      getPopupContainer,
      options: [
        { label: '选项A', value: 'a' },
        { label: '选项B', value: 'b' },
      ],
      placeholder: '请选择状态',
    },
    fieldName: 'status',
    label: '状态',
  },
  {
    component: 'DatePicker',
    componentProps: {
      getPopupContainer,
      placeholder: '请选择日期',
      showTime: true,
      type: 'datetimerange',
    },
    fieldName: 'dateRange',
    label: '日期范围',
  },
];

// ==================== 表格列定义 ====================
export const columns: VxeGridProps['columns'] = [
  { type: 'checkbox', width: 60 },
  {
    field: 'id',
    title: 'ID',
    width: 80,
  },
  {
    field: 'name',
    title: '名称',
    minWidth: 200,
    showOverflow: true,
  },
  {
    field: 'status',
    title: '状态',
    width: 100,
    // 使用 slots 自定义渲染
    slots: {
      default: ({ row }: { row: XxxItem }) => {
        // 返回渲染内容
      },
    },
  },
  {
    field: 'createTime',
    title: '创建时间',
    width: 160,
  },
  {
    field: 'action',
    fixed: 'right',
    slots: { default: 'action' },
    title: '操作',
    width: 180,
  },
];

// ==================== 抽屉表单 Schema ====================
export const drawerSchema: FormSchemaGetter = () => [
  {
    component: 'Input',
    dependencies: {
      show: () => false,
      triggerFields: [''],
    },
    fieldName: 'id',
    label: '主键',
  },
  {
    component: 'Input',
    fieldName: 'name',
    label: '名称',
    rules: 'required',
  },
  // 更多表单字段...
];
```

---

## §3 组件使用规范

### 3.1 必须使用的框架组件

| 场景 | 必须使用 | 导入路径 |
|------|----------|----------|
| 数据表格（列表页） | `useVbenVxeGrid` | `'#/adapter/vxe-table'` |
| 查询表单 | `VbenFormProps` + `querySchema` | `'@vben/common-ui'` + `'#/adapter/form'` |
| 详情/编辑抽屉 | `useVbenDrawer` | `'@vben/common-ui'` |
| 页面容器 | `Page` | `'@vben/common-ui'` |
| 权限控制 | `useAccess` + `v-access:code` 指令 | `'@vben/access'` |
| 复选框状态检查 | `vxeCheckboxChecked` | `'#/adapter/vxe-table'` |
| 弹出层容器 | `getVxePopupContainer` | `'@vben/utils'` |
| 文件下载 | `commonDownloadExcel` | `'#/utils/file/download'` |

### 3.2 允许直接使用 ant-design-vue 的场景

以下 antd 组件可以直接使用（因为框架未封装或不适合封装）：

| 组件 | 使用场景 |
|------|----------|
| `Statistic` | 统计卡片数值展示 |
| `Card` (a-card) | 统计卡片容器 |
| `Modal.confirm` | 批量删除等确认操作 |
| `Popconfirm` | 单行删除确认 |
| `Space` | 工具栏/操作列布局 |
| `Tag` | 状态标签展示 |
| `Tabs` | 页面内多Tab切换（非列表页） |
| `message` | 操作成功/失败提示 |
| 图标组件 | `@ant-design/icons-vue` 图标 |

### 3.3 禁止使用的模式

| 禁止 | 说明 | 正确替代 |
|------|------|----------|
| `Table` from `ant-design-vue` | 列表页禁止使用原生表格 | `useVbenVxeGrid` |
| `h()` 渲染函数构建 UI | 禁止用 `h()` 手写 VNode（包括表格列、表单、弹窗、任何场景） | 使用 `<template>` 模板 + `slots`，或拆分为 `.vue` 子组件 |
| 手写分页逻辑 | 禁止自己管理 `pageNum`/`pageSize`/`total` | `proxyConfig.ajax` 自动分页 |
| 手写 `loading` 状态 | 禁止 `ref(false)` 手动管理加载状态 | `proxyConfig.ajax` 自动管理 |
| `alert('xxx')` | 禁止使用浏览器原生弹窗 | `message.success()` / `message.error()` |
| 内联 `style="width: 180px"` | 禁止在模板中写内联样式 | 使用 Tailwind CSS 工具类或 `<style scoped>` |
| 直接导入 `ant-design-vue` 的 `Form` | 禁止原生表单组件做查询/编辑表单 | `VbenFormProps` + `schema` 或 `useVbenDrawer` |
| `TableColumns` 类型 | 禁止使用 antd 的表格列类型定义 | `VxeGridProps['columns']` |
| `customRender` | antd Table 的自定义渲染 | VxeGrid 的 `slots` 配置 |

### 3.4 `h()` 渲染函数的彻底禁止

`h()` 是编程CC最容易犯的错误。以下场景全部禁止使用 `h()`：

| 场景 | 禁止的写法 | 正确替代 |
|------|-----------|----------|
| 表格操作列 | `customRender: () => h(Button, ...)` | `slots: { default: 'action' }` + `<template #action>` |
| 表格状态列 | `() => h(Tag, { color: 'green' }, ...)` | `slots: { default: 'status' }` + `<template #status>` |
| 编辑表单/弹窗 | `return () => h(Form, {}, h(FormItem, ...))` | 拆分为独立的 `.vue` 子组件（如 `xxx-form-modal.vue`） |
| 确认弹窗内容 | `content: h(Select, { ... })` | 拆分为子组件，或使用 `useVbenDrawer` |
| Tab内容 | `h(TabPane, {}, h(Table, ...))` | 拆分为独立子组件 `xxx-list.vue` |

**特别说明：** `Modal.confirm({ content: h(Select, ...) })` 这种在确认弹窗中嵌入复杂 UI 的写法，应改为独立的 `.vue` 弹窗组件：

```typescript
// ❌ 禁止：确认弹窗中嵌入 h() 构建的复杂 UI
Modal.confirm({
  content: h(Select, { options: priorityOptions, onChange: (v) => { ... } }),
});

// ✅ 正确：拆分为独立的 .vue 组件
import PriorityModal from './priority-modal.vue';
const [PriorityDialog, dialogApi] = useVbenDrawer({ connectedComponent: PriorityModal });
```

### 3.5 多分区页面布局规范（参考 ruoyi 官方 `graphRAG/index.vue`）

原型图包含多个分区时，**必须**按下列栅格 + Card 模板实现。禁止用自定义 `<div>` + 内联 style 拼布局。

**官方模板**：`frontend/apps/web-antd/src/views/operator/graphRAG/index.vue`（图谱检索测试，三分区左右+全宽嵌套）

#### 核心规则

| 元素 | 规则 |
|------|------|
| 最外层（主页面） | `<Page :auto-content-height="true">` — 仅**主页面**用，drawer/modal 内容禁用（见 §3.6） |
| 行容器 | `<Row :gutter="16">` — 24 栅格，gutter 固定 16 |
| 列容器 | `<Col :span="N">` — 左右 1:1 用 `12/12`，左右 1:2 用 `8/16`，全宽用 `24` |
| 分区容器 | 每个分区**必须**用 `<Card title="分区标题" size="small">` 包裹，不得裸 `<div>` + `<h3>` |
| 分区内垂直排列 | `<Space direction="vertical" style="width:100%" :size="16">` |
| 行之间间距 | 第二行起加 `style="margin-top: 16px"`（与 gutter 保持一致） |
| 分区内分段 | 用 `<Divider />`（不加文字）分隔多段内容 |
| 结果展示 | `<Alert type="success" />` + `<Descriptions bordered size="small">` + `<Tag>` + `<Space wrap>` |

#### 模板（三分区：左右 1:1 + 全宽嵌套 1:2）

```vue
<template>
  <Page :auto-content-height="true">
    <div class="xxx-page">
      <!-- 第一行: 左右 1:1 两个分区 -->
      <Row :gutter="16">
        <Col :span="12">
          <Card title="分区 A" size="small">
            <Space direction="vertical" style="width:100%" :size="16">
              <!-- 表单字段 -->
              <div>
                <div style="margin-bottom:8px">字段标签</div>
                <Input v-model:value="xxx" />
              </div>
              <Button type="primary" block @click="handleA">操作 A</Button>
              <Divider />
              <div v-if="resultA"><!-- 结果展示 --></div>
            </Space>
          </Card>
        </Col>
        <Col :span="12">
          <Card title="分区 B" size="small">
            <!-- 同上结构 -->
          </Card>
        </Col>
      </Row>

      <!-- 第二行: 全宽 + 内部嵌套 1:2 -->
      <Row :gutter="16" style="margin-top:16px">
        <Col :span="24">
          <Card title="分区 C" size="small">
            <Row :gutter="16">
              <Col :span="8"><!-- 左列: 输入 --></Col>
              <Col :span="16"><!-- 右列: 结果 --></Col>
            </Row>
          </Card>
        </Col>
      </Row>
    </div>
  </Page>
</template>

<style scoped>
.xxx-page { padding: 16px; }
</style>
```

#### ❌ 禁止的模式

| 反例 | 问题 | 正确替代 |
|------|------|---------|
| 裸 `<div class="section">` 堆叠 | 缺 Card 边框/标题 | `<Card title="..." size="small">` |
| 内联 `style="display:flex;gap:16px"` | 不响应式，栅格混乱 | `<Row :gutter="16"><Col :span="N">` |
| 自定义 `<h3>分区标题</h3>` | 样式不统一 | `<Card title="分区标题">` |
| 用 `<hr />` 或 `<div class="divider">` | 非 antd 组件 | `<Divider />` |
| `Row` 之间用 `<br>` 或 `margin-bottom` | 不一致 | `style="margin-top: 16px"` |
| 混用 `el-row` / `el-col`（element-plus）| 组件库错位 | 只用 `ant-design-vue` 的 `Row`/`Col` |

#### 原型图多分区对照

当设计文档/原型图显示**多个独立内容区块**时（如 #3458 矿场 v3.0 详情的「甲方联系卡 + 真实性论证 Tab + 研判分析 Tab + 信源链接 Tab + 配合单位 Tab + 任务看板 Tab + 操作记录 Tab」），**必须**：

1. 先判断属于哪种结构：
   - **平级多分区** → `Row` + 多个 `Col` + 每个 `Card`
   - **分 Tab 切换** → `<a-tabs>` + `<a-tab-pane>`，每个 tab-pane 内部仍按本规范
   - **主+辅分区** → `Row :gutter="16"` + `Col :span="16"` 主 + `Col :span="8"` 辅
2. 每个分区**必须用 `<Card>` 包裹**，不得直接写内容到 template
3. 间距全部用 `gutter="16"` + `margin-top: 16px`，禁止自定义数值

### 3.6 Drawer 抽屉实现规范（防 #3544 事故）

**Drawer 首选方案：ant-design-vue 原生 `<Drawer>` 内嵌**，不用 `useVbenDrawer + connectedComponent` 复杂机制。

#### ✅ 权威参考（实测可用）

**`frontend/apps/web-antd/src/views/operator/knowledgeBase/index.vue`**（用户确认 `/operate/knowledgeBase` 「创建知识库」抽屉在 Dev 工作正常）

| 位置 | 行号 | 作用 |
|------|------|------|
| `import { Drawer } from 'ant-design-vue';` | L13 | 原生 Drawer 组件 |
| `const drawerVisible = ref(false);` | L90 | 本地 state 控制 open/close |
| `drawerVisible.value = true;` | L155 | 打开抽屉 |
| `<Drawer :visible :width :footer-style>` | L333-339 | template 内嵌 drawer |
| `drawerVisible.value = false;` | L228 | 关闭抽屉 |

#### 模板骨架（照抄即可）

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
  <Page>
    <!-- 主列表 -->
    <BasicTable @row-click="handleDetail" />

    <!-- ✅ 原生 Drawer,直接内嵌在 index.vue 的同一 template -->
    <Drawer
      v-model:open="detailOpen"
      title="项目详情"
      :width="900"
      :footer-style="{ textAlign: 'right' }"
    >
      <!-- drawer 内容:Tab / 表单 / 表格等 -->
      <a-tabs>
        <a-tab-pane key="info" tab="基本信息">...</a-tab-pane>
        <a-tab-pane key="partner" tab="配合单位">...</a-tab-pane>
      </a-tabs>

      <template #footer>
        <a-button style="margin-right: 8px" @click="detailOpen = false">关闭</a-button>
      </template>
    </Drawer>
  </Page>
</template>
```

> **AntDV 4.x 注意**：新代码用 `v-model:open="detailOpen"`，不要用旧的 `:visible` + `@close`（ui-guide §1 绝对禁止清单）。knowledgeBase 的 `:visible` 是旧代码保留，**不要照抄 visible**，**只照抄结构**。

#### ❌ 禁止的 3 种写法

**反模式 1（#3544 事故）**：把 drawer 内容拆成独立 `.vue` 文件，然后用 `useVbenDrawer({ connectedComponent })` 连接，但子组件 template 最外层是 `<div>` 或 `<Page>`

```vue
<!-- ❌ xxx-detail-drawer.vue -->
<template>
  <div>  <!-- 或 <Page> 都会被 inline 渲染到主页面,不是 overlay -->
    <a-tabs>...</a-tabs>
  </div>
</template>
```

**反模式 2**：用 `:visible` + `@close`（AntDV 4.x 已废弃）

```vue
<!-- ❌ -->
<Drawer :visible="open" @close="open = false">...</Drawer>
<!-- ✅ -->
<Drawer v-model:open="open">...</Drawer>
```

**反模式 3**：Drawer 嵌套 Drawer（shared-conventions.md 绝对禁止清单）

#### 拆子组件的正确姿势

drawer 内容复杂需要拆分时：
1. **父页面 `index.vue`** 负责 drawer overlay（`<Drawer v-model:open>`）
2. **子组件 `xxx-detail-content.vue`** 只是**纯内容组件**（`<div>` + props 接收数据）
3. 父页面在 `<Drawer>` slot 里引用子组件：`<Drawer><XxxDetailContent :data="detailData" /></Drawer>`

这样 drawer overlay 机制 100% 由 `<Drawer>` 原生提供，子组件不涉及任何 overlay 逻辑。

#### 检测规则

本规则已纳入 `pr-reviewer.md` P0.6 审查清单：
- 发现 `connectedComponent: XxxDrawer` + XxxDrawer 文件 template 最外层不是 `<a-drawer>`/`<BasicDrawer>` → block merge
- 建议直接重构为原生 `<Drawer v-model:open>` + 纯内容子组件，参考 `operator/knowledgeBase/index.vue`

---

## §4 三层页面布局

所有列表页遵循统一的三层布局：

```
┌──────────────────────────────────────────┐
│  统计卡片区（Statistic Cards）             │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 总数  │ │ 进行中│ │ 已完成│ │ 异常  │    │
│  │ 128  │ │  45  │ │  80  │ │  3   │    │
│  └──────┘ └──────┘ └──────┘ └──────┘    │
├──────────────────────────────────────────┤
│  查询表单区（由 formOptions 自动生成）      │
│  [关键词____] [状态 ▼] [日期范围____] [搜索]│
├──────────────────────────────────────────┤
│  工具栏（toolbar-tools slot）             │
│  [导出] [删除] [新增]                      │
├──────────────────────────────────────────┤
│  数据表格（useVbenVxeGrid 自动渲染）        │
│  ┌────┬────────┬──────┬────────┬──────┐  │
│  │ ☐  │ 名称    │ 状态  │ 创建时间 │ 操作 │  │
│  ├────┼────────┼──────┼────────┼──────┤  │
│  │ ☐  │ xxx    │ 进行中│ 2026-.. │ 编辑 │  │
│  └────┴────────┴──────┴────────┴──────┘  │
├──────────────────────────────────────────┤
│  分页器（pagerConfig 自动生成）             │
│  < 1 2 3 ... 10 >  每页 10 条             │
└──────────────────────────────────────────┘
```

### 统计卡片区规范

- 使用 CSS Grid 自适应布局：`grid-template-columns: repeat(auto-fit, minmax(200px, 1fr))`
- 间距：`gap: 16px`，与下方表格间距：`margin-bottom: 16px`
- 每张卡片使用 `a-card` + `Statistic` 组件
- 卡片数量建议 3-6 个，展示该模块核心指标

---

## §5 样式规范

### 5.1 设计令牌（Design Tokens）

框架已定义 CSS 变量体系，所有页面必须使用，禁止自定义硬编码颜色值：

| 用途 | CSS 变量 | 值 |
|------|---------|-----|
| 主题色 | `--primary` | `212 100% 45%` (蓝色) |
| 成功色 | `--success` | `144 57% 58%` (绿色) |
| 警告色 | `--warning` | `42 84% 61%` (橙色) |
| 危险色 | `--destructive` | `359 100% 65%` (红色) |
| 页面背景 | `--background-deep` | `216 20% 95%` (浅灰) |
| 卡片背景 | `--card` | `0 0% 100%` (白色) |
| 文字主色 | `--foreground` | `210 6% 21%` (深灰) |
| 边框色 | `--border` | `240 6% 90%` (浅灰线) |

### 5.2 Tailwind CSS 优先

- 间距、字号、颜色等样式优先使用 Tailwind CSS 工具类
- 仅在 Tailwind 无法实现时才写 `<style scoped>`
- `<style scoped>` 中使用 `lang="scss"` 语法
- 使用 `:deep()` 穿透 antd 组件样式

### 5.3 响应式布局

- 查询表单使用 `wrapperClass: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5'` 实现自适应
- 统计卡片使用 CSS Grid `auto-fit` 自适应
- 表格设置 `height: 'auto'`，配合 `Page :auto-content-height="true"` 自动撑满

---

## §6 特殊页面类型

### 6.1 仪表盘 / Dashboard 页面

仪表盘类页面（如 `dashboard/index.vue`）不是标准列表页，但仍需遵循：

- 使用 `Page` 组件包裹
- ECharts 图表使用 `import * as echarts from 'echarts'`
- 统计卡片布局与列表页一致
- 如果内嵌了数据表格，仍然使用 `useVbenVxeGrid`

### 6.2 看板 / Kanban 页面

看板类页面（如 `task-board.vue`）布局特殊，允许不使用 `useVbenVxeGrid`，但需要：

- 使用 `Page` 组件包裹
- 组件 Props 使用 `defineProps` / `defineEmits` 规范定义
- 使用 Tailwind CSS 做卡片布局

### 6.3 多 Tab 页面

如果一个模块包含多个功能 Tab（如 Cockpit 的配置管理/新闻管理/用户反馈），**每个 Tab 中的列表仍然使用 `useVbenVxeGrid`**，不允许因为在 Tab 里就降级为原生 Table。

推荐做法：每个 Tab 拆分为独立的子组件，各自使用 `useVbenVxeGrid`：

```
views/wande/cockpit/
├── index.vue                    # 主页面（Tabs 容器）
├── config-list.vue              # 配置管理 Tab（useVbenVxeGrid）
├── news-list.vue                # 新闻管理 Tab（useVbenVxeGrid）
├── feedback-list.vue            # 用户反馈 Tab
├── config-data.ts               # 配置管理 columns + querySchema
├── news-data.ts                 # 新闻管理 columns + querySchema
└── feedback-data.ts             # 用户反馈 columns + querySchema
```

**重要：拆分后，index.vue 必须彻底清除原生组件残留。** `index.vue` 只应该包含 Tab 容器和子组件引用，禁止在 index.vue 中保留任何 `Table` 导入、`h()` 渲染函数或手写分页逻辑。如果某个 Tab 内容是非列表（如 GPU 监控图表、统计面板），也应拆分为独立子组件。

### 6.4 产品卡片式列表页（卡片 + 表格双模式）

如 `product-center/index.vue` 这类支持卡片视图/表格视图切换的页面：

- **表格视图**必须使用 `useVbenVxeGrid` + `proxyConfig.ajax`
- **卡片视图**允许自定义布局，但**分页逻辑必须与表格视图统一**：
  - 不允许卡片视图写一套独立的手写分页，必须复用 `useVbenVxeGrid` 的 `tableApi` 的分页状态
  - 卡片视图的数据源应来自 `tableApi.grid.getData()` 而不是另一个独立的 `ref`
  - ECharts 图表部分保留不动

```typescript
// ✅ 正确方法：卡片视图复用 VxeGrid 的数据
<template v-if="viewMode === 'card'">
  <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
    <ProductCard v-for="item in tableApi.grid.getData()" :key="item.id" :data="item" />
  </div>
</template>
<template v-else>
  <BasicTable table-title="产品列表" />
</template>

// ❌ 错误方法：卡片视图独立维护一套分页逻辑
const pagination = ref({ current: 1, pageSize: 12, total: 0 }); // 禁止
```

### 6.5 静态展示页（无API分页的配置/信息页）

如 `data-collection/index.vue` 这类页面，数据源是前端静态定义的信息展示（采集脚本状态、时间线等）：

- **仍然使用 `Page` 组件包裹**
- 如果包含表格展示（即使是静态数据），仍应使用 `useVbenVxeGrid`，将静态数据通过 `data` 属性传入：

```typescript
// ✅ 静态数据也用 useVbenVxeGrid
const gridOptions: VxeGridProps = {
  columns,
  data: staticScriptList, // 直接传入静态数据，不用 proxyConfig
  height: 'auto',
};

// ❌ 禁止使用原生 Table
<Table :columns="scriptColumns" :data-source="scripts" />
```

- 描述性信息可用 `Descriptions`、时间线可用 `Timeline`、状态可用 `Badge`/`Tag` — 这些非表格组件允许直接使用 antd
- 静态数据应提取到 `data.ts` 中导出，不应内联在 `.vue` 文件中

---

## §7 代码审查清单

编程CC在提交代码前，必须逐项检查以下清单。**任何一项不通过则不允许提交。**

### 7.1 组件使用检查

| 检查项 | 合格标准 |
|--------|----------|
| 列表页是否使用 `useVbenVxeGrid`？ | 必须使用，禁止原生 `Table` |
| 查询表单是否使用 `VbenFormProps` + `querySchema`？ | 必须使用，禁止手写表单 |
| 详情/编辑是否使用 `useVbenDrawer`？ | 必须使用，禁止原生 `Modal` |
| 页面是否用 `Page` 组件包裹？ | 必须使用 |
| 是否有独立的 `data.ts` 文件？ | 必须有，`columns` 和 `querySchema` 不能内联 |

### 7.2 样式检查

| 检查项 | 合格标准 |
|--------|----------|
| 是否使用了硬编码颜色值？ | 禁止，使用 CSS 变量或 Tailwind |
| 是否使用了 `alert()`？ | 禁止，使用 `message.success/error()` |
| 是否使用了内联 `style=""`？ | 尽量避免，使用 Tailwind 或 scoped CSS |
| 统计卡片布局是否一致？ | 使用 CSS Grid auto-fit 模式 |

### 7.3 代码模式检查

| 检查项 | 合格标准 |
|--------|----------|
| 是否使用了 `h()` 渲染函数？ | 禁止，使用模板 + slots |
| 是否手写了分页逻辑？ | 禁止，使用 `proxyConfig.ajax` |
| 是否手写了 `loading` 状态管理？ | 禁止，框架自动管理 |
| 权限控制是否使用 `v-access:code`？ | 必须使用 |
| API 导入路径是否来自 `#/api/wande/`？ | 必须使用项目别名路径 |

---

## §8 参考页面

### 8.1 标杆页面（必读）

开发新页面时，**首先阅读 `system/user/index.vue` 和 `system/user/data.tsx`** 作为基准模板。

| 页面 | 文件路径 | 特点 |
|------|---------|------|
| **用户管理** | `views/system/user/index.vue` | 三层布局 + 完整 CRUD — **RuoYi 框架首选参考** |

### 8.2 改造后的良好示例（2026-04-01 Issue #408 验收）

以下页面经过规范改造后符合要求：

| 页面 | 特点 | 备注 |
|------|------|------|
| **Cockpit 管控台** | 多 Tab 拆分子组件 `config-list.vue` / `news-list.vue`，各自 useVbenVxeGrid | 多 Tab拆分的标杆 |
| **Credit Usage** | useVbenVxeGrid + data.ts + Page | 标准列表页改造 |
| **Worklog 工作日志** | useVbenVxeGrid + data.ts + 抽屉组件 | 含详情抽屉的改造示例 |
| **Wecom 企微管理** | 多 Tab 拆分 `rule-list.vue` / `history-list.vue`，各自 useVbenVxeGrid | 多 Tab + 弹窗表单 |
| **Dev 开发进度** | useVbenVxeGrid + data.ts + Page | 标准改造 |

### 8.3 待进一步改造的页面（2026-04-02 验收发现）

以下页面虽已改造但仍有残留问题：

| 页面 | 残留问题 | 修复要求 |
|------|-----------|----------|
| **Monitor 系统监控** | index.vue 仍导入原生 `Table` / `TableColumns`，仍有 5 处 `h()` 和手写分页 | 将 GPU进程表和告警规则表拆分为子组件，全部用 useVbenVxeGrid |
| **Task 任务管理** | index.vue 仍有 6 处 `h()`（用于 Modal.confirm 内嵌 Select） | 将优先级修改弹窗拆分为独立 .vue 组件 |
| **Margin Config 利润配置** | index.vue 仍有 15 处 `h()`（用于构建编辑表单） | 将编辑表单拆分为独立的 `margin-form.vue` 子组件 |
| **Product Center 产品中心** | 卡片视图维护了独立的手写分页逻辑（18处分页相关代码） | 卡片视图应复用 tableApi 数据，参见 §6.4 |
| **Data Collection 数据采集** | 未改造，仍使用原生 `Table`，无 data.ts | 静态数据也应用 useVbenVxeGrid，参见 §6.5 |

---

## §9 常见错误及修正

### 错误1：使用原生 `Table` 组件

```typescript
// ❌ 错误
import { Table } from 'ant-design-vue';
const columns: TableColumns = [...];
<Table :columns="columns" :data-source="listData" :pagination="pagination" />

// ✅ 正确
import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { columns, querySchema } from './data';
const [BasicTable, tableApi] = useVbenVxeGrid({ formOptions, gridOptions });
<BasicTable table-title="XXX管理" />
```

### 错误2：手写分页逻辑

```typescript
// ❌ 错误
const pagination = ref<PageQuery>({ pageNum: 1, pageSize: 10, total: 0 });
function handleTableChange(p: any) {
  pagination.value.pageNum = p.current || 1;
  fetchList();
}

// ✅ 正确 — proxyConfig.ajax 自动处理分页
const gridOptions: VxeGridProps = {
  pagerConfig: {},
  proxyConfig: {
    ajax: {
      query: async ({ page }, formValues = {}) => {
        return await xxxList({
          pageNum: page.currentPage,
          pageSize: page.pageSize,
          ...formValues,
        });
      },
    },
  },
};
```

### 错误3：使用 `h()` 渲染函数

```typescript
// ❌ 错误
{
  title: '操作',
  customRender: ({ record }) =>
    h(Popconfirm, { title: '确定删除？', onConfirm: () => handleDelete(record.id) },
      { default: () => h(Button, { type: 'link', danger: true }, { default: () => '删除' }) }
    ),
}

// ✅ 正确 — 使用 template slot
// data.ts 中：
{ field: 'action', fixed: 'right', slots: { default: 'action' }, title: '操作', width: 180 }

// index.vue 模板中：
<template #action="{ row }">
  <Popconfirm title="确认删除？" @confirm="handleDelete(row)">
    <ghost-button danger>删除</ghost-button>
  </Popconfirm>
</template>
```

### 错误4：使用浏览器原生弹窗

```typescript
// ❌ 错误
alert('删除成功');

// ✅ 正确
import { message } from 'ant-design-vue';
message.success('删除成功');
```

### 错误5：配置内联在 .vue 中

```typescript
// ❌ 错误 — 在 index.vue 中直接定义
const configColumns: TableColumns = [
  { title: 'ID', dataIndex: 'id', width: 80 },
  { title: '名称', dataIndex: 'name', width: 150 },
  // ...
];

// ✅ 正确 — 在 data.ts 中定义并导出
// data.ts
export const columns: VxeGridProps['columns'] = [
  { field: 'id', title: 'ID', width: 80 },
  { field: 'name', title: '名称', minWidth: 150 },
  // ...
];

// index.vue
import { columns, querySchema } from './data';
```

### 错误6：多 Tab 页面拆分不彻底

```typescript
// ❌ 错误 — 子组件用了 useVbenVxeGrid，但 index.vue 中仍残留原生 Table
import type { TabsProps, TableColumns } from 'ant-design-vue';  // 残留
import { Table, Tag, Button } from 'ant-design-vue';  // 残留
const processColumns: TableColumns = [...]  // 残留

// ✅ 正确 — index.vue 只保留 Tab 容器，所有列表全部在子组件中
import ConfigList from './config-list.vue';
import NewsList from './news-list.vue';
import ProcessList from './process-list.vue';
// index.vue 中不应导入任何 Table/TableColumns
```

### 错误7：用 `h()` 构建编辑表单

```typescript
// ❌ 错误 — 用 h() 构建完整的编辑表单
return () => h('div', { class: 'p-4' }, [
  h(Form, { layout: 'vertical' }, [
    h(FormItem, { label: '名称' }, h(Input, { value: form.name })),
    h(FormItem, { label: '数量' }, h(InputNumber, { value: form.count })),
    h(Button, { type: 'primary', onClick: handleSubmit }, '保存'),
  ]),
]);

// ✅ 正确 — 拆分为独立的 .vue 子组件
// margin-form.vue
<template>
  <div class="p-4">
    <a-form layout="vertical">
      <a-form-item label="名称">
        <a-input v-model:value="form.name" />
      </a-form-item>
      <a-form-item label="数量">
        <a-input-number v-model:value="form.count" />
      </a-form-item>
      <a-button type="primary" @click="handleSubmit">保存</a-button>
    </a-form>
  </div>
</template>
```
