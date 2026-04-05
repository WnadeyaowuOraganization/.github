# 工作流程

## 任务来源

**所有任务通过 GitHub Issue 下发，由研发经理CC分配。**

调度器已完成：选定Issue → 创建工作目录 `./issues/issue-<N>` → 签出 feature 分支。
你启动时已在 feature 分支上，工作目录已创建。

**第一件事**：
1. `gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments` 读取Issue完整内容
2. 如果 `./issues/issue-<N>/task.md` 已存在，读取后继续（断点恢复）

## 三阶段开发流程

### 第一阶段：准备

1. **读取Issue**：`gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments`
2. **创建 task.md**：在 `./issues/issue-<N>/` 下拆解为可执行的 task
3. **需求评估**：
   - A: 可执行 → 继续
   - B: 需确认 → 评论Issue + `bash /home/ubuntu/projects/.github/scripts/update-project-status.sh play <N> "pause"` → 结束
   - C: 不可执行 → 评论 + 标 `status:blocked` → 结束

> 工作目录和 feature 分支由调度器 pre-task 创建，无需手动操作。

### 第二阶段：编码 + 测试

#### Step 1: 开发

1. 按 task 逐步开发，持续更新 task.md
2. 遵循 [docs/UI-GUIDE.md](UI-GUIDE.md) 规范（必须用 `useVbenVxeGrid`、`useVbenDrawer`、`Page` 组件）
3. API 对接前**必须读后端 Controller 源码**（在 `../backend/ruoyi-modules/wande-ai/src/main/java/org/ruoyi/wande/controller/`），禁止猜测

#### Step 2: 组件测试

为新增/修改的页面写 Vitest 测试：
```bash
# 位置：组件同级 __tests__/XxxPage.test.ts
# 覆盖：渲染 + 关键交互 + API mock
pnpm test -- --run <test-file>
```

#### Step 3: 构建验证

```bash
pnpm build
```

必须用 ubuntu 用户执行。root 会导致权限问题。

#### Step 4: Playwright smoke 测试

为新增页面编写 smoke 测试并本地跑通：

```bash
# 测试文件位置
e2e/tests/front/smoke/<page-name>.spec.ts

# 内容：导航到页面 + 检查无白屏 + 关键元素存在
# 运行
cd /home/ubuntu/projects/wande-play/e2e
npx playwright test tests/front/smoke/<page-name>.spec.ts --reporter=list
```

**`@external` 标签**：如果被测页面会触发调用外部服务（微信API、企微webhook、短信等第三方域名），在 test.describe 上加 `@external` 标签。CI 会自动跳过这类测试。

**`@external` 标签**：如果被测页面会触发调用外部服务（微信API、企微webhook、短信等第三方域名），在 test.describe 上加 `@external` 标签。CI 会自动跳过这类测试。

#### 门禁（全部 PASS 才能提交）

| 检查项 | 验证方式 |
|--------|---------|
| pnpm build 通过 | 构建无报错 |
| 组件测试通过 | Vitest PASS |
| Smoke 测试通过 | Playwright PASS |
| UI 规范 | docs/UI-GUIDE.md §7 全部通过 |

### 第三阶段：提交

```bash
git add -A
git commit -m "feat(模块): 描述 #<Issue号>"
git push origin feature-Issue-<N>
```

**完成。**

## Git 分支规范

- **main**: 生产分支
- **dev**: 测试分支，push 触发 CI/CD
- **feature-Issue-<N>**: 从 dev 签出（调度器创建）

**只 push feature 分支**，不要 push dev 或 main。
