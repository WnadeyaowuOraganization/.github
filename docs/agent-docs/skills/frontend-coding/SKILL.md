---
name: frontend-coding
description: Write Vue 3 + Vben Admin 5.x + Ant Design Vue 4.x + vxe-table frontend code for Wande-Play. Enforces useVbenVxeGrid (no native Table), useVbenDrawer (no native Modal), native ant-Drawer with v-model:open for detail drawers (no connectedComponent wrapper per #3544), Page container, independent data.ts, slot-based rendering (no h() functions), multi-zone Row/Col/Card layout, and request client API layer. Use for any change under frontend/apps/web-antd/src/views/.
---

# 前端编码规范

> **⛔ MUST NOT（Issue title/label 含 `frontend` 时）**：
> - **禁止**创建 Flyway SQL 脚本
> - **禁止**创建 Entity / Mapper / Service / Controller / XML 任何后端类
> - **禁止**创建或修改 `api-contract/*.yaml`
> - **禁止**用 mock 数据替代后端 API — 排程保证前端派发前后端已 merged，直接对接真实接口
>
> 后端配对 Issue 由另一个 CC 负责；前端 CC 不拥有后端代码的所有权。（4次违规后加入红线：#3719/3711/3717/3723 均有此倾向）

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
| `useVbenForm` 里写 `layout: 'vertical'` | 省略 layout 字段（默认水平，label 与 input 同行，与系统管理风格一致） |
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
| 新建 `src/api/<seg>.ts` 与已有 `src/api/<seg>/` 目录同名（影子文件） | 向 `<seg>/index.ts` 追加导出，或改 `<seg>/<sub>.ts` |
| 新建 `src/views/<seg>.vue` 与已有 `src/views/<seg>/` 目录同名 | 同上，改 `<seg>/<sub>.vue` |

### 🚨 影子文件红线（2026-04-15 事故）

新建任何 `<name>.ts` / `<name>.vue` 前 **必须先** `ls $(dirname)/` 确认不存在同名 `<name>/` 目录。违反会触发 Vite alias 优先解析到文件而覆盖目录 index，导致原目录全部导出失效。典型症状：`"xxx" is not exported by "src/api/.../<name>.ts"`。

事故案例：#3689 新建 15 行 `api/system/user.ts` 覆盖 171 行 `api/system/user/index.ts` → 阻塞 10 次 dev 部署 + 9 个 CRM PR 不可见。修复：`PR #3693` 合并导出到目录 + 删除影子文件。

白名单（已知上游残留、勿动）：`src/views/system/dict/data.vue`（ele 版本占位）。

### 🚨 API 层函数命名对齐红线（2026-04-15 第 2 次事故）

新文件 import 后端 API 时 **必须先** `grep -r "export.*${functionName}" src/api/` 确认后端约定的函数名。**禁止**自创 `createX/updateX/deleteX` 新名，必须严格按后端现有导出名对齐。

同日事故案例：#3704 (CRM 商机详情) kimi2 新建前端 API import 后，漏查后端约定，自创 `createOpportunity` 而后端实际导出 `crmOpportunityAdd` → dev 前端构建挂 rollup 报错。修复：`PR #3705` 改 import 名。

**本周累计 2 次命名冲突**（#3693 user.ts 文件名 + #3704 函数名），已升级为强制红线。

工作流：
1. 后端 controller 改动后，参考 `docs/design/<模块>/` 设计文档或 Issue body 中的 "API 路径" 确认约定名
2. 前端新建 `.ts` 时，先 `grep "export.*" src/api/<模块>/` 扫已有导出
3. 新增的导出必须与约定名**完全一致**，不得增删前缀/后缀

## AntDV 4.x 可直接用的组件

`Statistic / Card / Modal.confirm / Popconfirm / Space / Tag / Tabs / message / Drawer / @ant-design/icons-vue`。

## 国际化

所有用户文案用 `$t('key')` / `t('key')`。硬编码中文 → Lint 报错。

新增路由模块时，**必须**同步向 `src/locales/langs/zh-CN/page.json` 添加对应键组；否则 `$t('page.xxx.yyy')` 找不到翻译，页签直接显示 key 字符串（`page.xxx.yyy`）。

## 启动前端（硬点，违反=刹车）

**只能**用 cc-test-env.sh 启动/重启前端 dev server：

```bash
# 只重启前端（后端+DB 保留，省 token/资源，默认使用）
bash ~/projects/.github/scripts/cc-test-env.sh restart-frontend kimiN
# 极少数情况（新建 views/<模块>/ 目录触发 vite glob 缓存失效）才需前后端全重启：
# bash ~/projects/.github/scripts/cc-test-env.sh restart kimiN   # ← 会删库重建，慎用
bash ~/projects/.github/scripts/cc-test-env.sh wait kimiN         # 等后端就绪（仅需验 API 时用）
```

**禁止**：
- `cd frontend && pnpm dev` / `pnpm run dev:antd` —— vite 会占 5173/5174/5175... 污染其他 kimi 池子，并导致你 Playwright baseURL 错位
- `pkill -f vite` / `killall vite` —— pkill -f 无差别杀所有 kimi 的 vite
- `lsof -ti :56xx | xargs kill` —— 5666-5671/5173-5179 不是任何 kimi 的规范端口，乱杀会误伤其他 kimi

你的前端端口是 **810N**（kimi1=8101, kimi2=8102, ..., kimi5=8105）。若 `curl localhost:810N` 无响应：
1. `bash cc-test-env.sh restart-frontend kimiN`（只重启前端，后端+DB 保留）
2. 仍无响应看 `tail -100 /apps/wande-ai-frontend-kimiN/logs/frontend.log`
3. **禁止**改 vite.config 端口适配错误端口

## 构建验证（提交前必过）

```bash
# 1. 先 rebase，合并其他 CC 的最新改动（必须，防止 duplicate declaration）
git fetch origin dev && git rebase origin/dev
# 有冲突解决后继续；解不了就 git rebase --abort 然后 push，让 CI 兜底

# 1a. ⚠️ MUST: rebase 后立即扫 TS 文件中的破损 JSDoc（4次事故：2026-04-16 #1576 policy.ts）
#     rebase 冲突合并会静默丢失 `}` 和 `/**`，导致 TS Syntax error 但本地不报（已缓存）
python3 -c "
import sys, os
for root, dirs, files in os.walk('frontend/apps/web-antd/src/api'):
    for f in files:
        if not f.endswith('.ts'): continue
        path=os.path.join(root,f)
        lines=open(path).readlines()
        for i,line in enumerate(lines,1):
            s=line.lstrip()
            if s.startswith('* ') and not s.startswith('*/'):
                found=any(lines[j].strip().startswith('/**') for j in range(max(0,i-4),i-1))
                if not found:
                    print(f'{path}:{i}: 孤立 * —— 可能缺少 }}, 和 /**')
"
# 有输出 = 有破损，必须手动补 }} + /** 再提交

# 2. 若改动了共享文件（如 src/api/wande/execution.ts），快速检查重名符号
grep -n "^export\|^const \|^function \|^interface \|^type " \
  frontend/apps/web-antd/src/api/wande/execution.ts | awk -F: '{print $NF}' | sort | uniq -d

# 3. 构建（必须零错误）
cd frontend && pnpm build:antd   # ⚠️ 用 build:antd 而非 pnpm build（后者走 turbo 可能缓存跳过）
cd frontend && pnpm lint        # 可选，Lint 警告建议修
```

> **MUST NOT**：`pnpm build` 前不 rebase 直接提交 PR —— 多 CC 并行修改 `execution.ts` 等共享文件时会产生重复声明，导致 CI build 失败（2026-04-16 #3711 stageConfig重名 + #3719 DocCategoryVO缺闭括号，同一根因两次）。

## 新增路由模块（父级路由 component 用法）

**parent route component 必须用 `BasicLayout`**，禁止直接 import layouts 路径：

```typescript
// ✅ 正确
import { BasicLayout } from '#/layouts';
import type { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    path: '/admin-center',
    name: 'AdminCenter',
    component: BasicLayout,  // ← BasicLayout，不是动态 import
    children: [...]
  }
];

// ❌ 错误（路径不存在，Rollup 构建报 "failed to resolve import"）
component: () => import('#/layouts/default/index.vue'),
component: () => import('#/layouts/basic/index.vue'),
```

`BasicLayout`、`AuthPageLayout`、`IFrameView` 三个 layout 均从 `#/layouts`（`src/layouts/index.ts`）导出。

TS 报错禁用 `@ts-ignore` 绕过，除非注释说清原因。

## 标杆参考页面

| 页面 | 路径 | 特点 |
|------|------|------|
| 用户管理 | `views/system/user/index.vue` | 三层布局 + 完整 CRUD — RuoYi 框架首选参考 |
| 知识库-文档 | `views/knowledge/info/index.vue` | 原生 Drawer 典型用法（照抄结构，不照抄旧 `:visible`） |
