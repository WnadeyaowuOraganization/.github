# Ant Design Vue 4.x 约束清单

## 废弃属性映射（MUST 遵守）

| 组件 | 废弃属性 | 正确属性 | 版本 |
|------|----------|----------|------|
| Drawer | visible | open | 4.0+ |
| Modal | visible | open | 4.0+ |
| Dropdown | visible | open | 4.0+ |
| Tooltip | visible | open | 4.0+ |
| Popover | visible | open | 4.0+ |
| Popconfirm | visible | open | 4.0+ |

## 组件使用约束

### Drawer
- 使用 `open` 控制显示，不用 `visible`
- 关闭回调使用 `@close`，不用 `@afterVisibleChange`
- 禁止 Drawer 嵌套 Drawer，使用事件通信：

```vue
<!-- 正确：独立 Drawer 组件 -->
<DetailDrawer :open="showDetail" @close="showDetail = false" />
<EditDrawer :open="showEdit" @close="showEdit = false" />

<!-- 错误：嵌套 Drawer -->
<a-drawer :open="show">
  <a-drawer :open="showInner">...</a-drawer>
</a-drawer>
```

### 验证方式
运行 `pnpm lint` 会自动检查。控制台出现 `[antd: xxx] yyy is deprecated` 说明使用了废弃 API。
