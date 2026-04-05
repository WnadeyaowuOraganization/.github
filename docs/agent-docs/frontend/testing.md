# 测试规范

> **测试先行，代码后写。** 理解 Issue 需求后，第一件事是编写或补充组件测试。以通过所有测试为目标进行编码。没有通过测试 = 不允许提交。

## TDD 工作流

```
1. 读懂 Issue 需求 → 确定需要测试的组件和交互
2. 编写组件测试（此时测试应该失败，因为组件还没写）
3. 编写页面/组件代码让测试逐个变绿
4. 全量测试通过 → 提交
```

**每个 Issue 必须有对应测试。没有测试 = 没完成。**

## 组件测试

### 编写规范

- 文件位置：组件同级目录下 `__tests__/XxxPage.test.ts`
- 最少覆盖：组件渲染、关键交互、API调用mock
- 运行：`pnpm test -- --run <test-file>`

### 不同场景的测试策略

| Issue 类型 | 测试要求 |
|-----------|---------|
| 新增页面/组件 | 创建 `__tests__/XxxPage.test.ts`，覆盖渲染+交互+API |
| 修改已有页面 | 在已有 Test 中补充新增交互的测试用例 |
| Bug 修复 | 编写能复现 Bug 的回归测试（先确认测试失败，修复后变绿） |
| 纯配置/路由变更 | 可跳过组件测试（在 task.md 中说明原因） |

## Smoke E2E

确认 E2E 项目中有对应的页面加载测试：
- 查看 `$HOME_DIR/projects/wande-ai-e2e/tests/smoke/` 是否有本页面的测试文件
- 如果没有，创建 `tests/smoke/<page-name>.spec.ts`（导航到页面 + 检查无白屏）
- 运行：`cd $HOME_DIR/projects/wande-ai-e2e && npx playwright test tests/smoke/<page>.spec.ts`

## Shift-left 质量检查

合并到dev前必须全部通过：
- 构建通过：`pnpm build`
- 组件测试通过：`pnpm test -- --run`
- Smoke E2E（如果前端在运行）：`cd $HOME_DIR/projects/wande-ai-e2e && npx playwright test tests/smoke/pages-load.spec.ts --reporter=list`

## 自检清单

**全部PASS才能进入提交阶段：**

| 检查项 | 命令 | 状态 |
|--------|------|------|
| 组件测试已写 | 检查有新增/修改的测试文件 | PASS |
| 组件测试全部通过 | `pnpm test -- --run` | PASS |
| pnpm build 构建通过 | `pnpm build` | PASS |
| Smoke E2E页面加载通过（如前端在运行） | E2E pages-load.spec.ts | PASS |
| 无TypeScript类型错误 | 检查构建输出 | PASS |
