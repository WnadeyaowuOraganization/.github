# Issue 工作流程

> 本文档描述所有编程CC共用的Issue生命周期和三阶段开发流程。

## Issue 生命周期

```
Issue创建 → CI自动关联Project Status=Plan
         → [排程] Plan → Todo
         → [触发CC] Todo → In Progress
         → [编程CC] TDD → 编译检查 → push feature → create PR
         → [CI pr-test.yml] E2E测试 → 通过auto merge+Done / 失败→E2E Fail
```

## 任务来源

**所有任务通过 GitHub Issue 下发，由调度器CC分配。**

调度器已完成：选定Issue → 创建工作目录 `./issues/issue-<N>` → 签出 feature 分支。
你启动时已在 feature 分支上，工作目录已创建。

### 第一件事

1. 读取Issue完整内容：
   ```bash
   gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments
   ```
2. 恢复工作：如果 `./issues/issue-<N>/task.md` 已存在，读取后继续

### Issue读取备用方案

如果 `gh issue view` 失败（token过期/网络问题），按顺序尝试：

1. 重新获取token：
   ```bash
   export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)
   ```
2. 用curl直接调GitHub API：
   ```bash
   curl -s -H "Authorization: token $GH_TOKEN" \
     "https://api.github.com/repos/WnadeyaowuOraganization/wande-play/issues/<N>" | python3 -m json.tool
   ```
3. 获取评论：
   ```bash
   curl -s -H "Authorization: token $GH_TOKEN" \
     "https://api.github.com/repos/WnadeyaowuOraganization/wande-play/issues/<N>/comments" | python3 -m json.tool
   ```

## 三阶段开发流程

### 第一阶段：准备

1. **读取Issue**：`gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments`
2. **创建 task.md**：在 `./issues/issue-<N>/` 下拆解为可执行的task
3. **需求评估**：
   - **A: 可执行** → 继续
   - **B: 需确认** → 评论Issue + 标pause → 结束
   - **C: 不可执行** → 评论 + 标blocked → 结束

需求评估B/C时更新Project看板：
```bash
bash /home/ubuntu/projects/.github/scripts/update-project-status.sh play <N> "pause"
```

> 工作目录和feature分支由调度器pre-task创建，无需手动操作。

### 第二阶段：编码 + 测试

#### 核心规则

1. **测试先行（TDD）** — 理解Issue后第一件事是编写/补充单元测试，再以通过所有单元测试为目标编码
2. **每个Issue必须有对应测试** — 没有测试 = 没完成
3. **编译检查必须通过** — 提交前构建命令必须成功
4. **只push feature分支** — 创建feature→dev的PR

#### 门禁（全部PASS才能提交）

| 检查项 | 验证方式 |
|--------|---------|
| 单元测试通过 | 运行测试命令 |
| 编译/构建成功 | 构建命令退出码0 |
| 新增测试存在 | 测试目录有本Issue测试 |

### 第三阶段：提交

```bash
git add -A
git commit -m "feat(模块): 描述 #<Issue号>"
git push origin feature-Issue-<N>
gh pr create --repo WnadeyaowuOraganization/wande-play \
  --base dev --head feature-Issue-<N> \
  --title "feat(模块): 描述 #<Issue号>" \
  --body "Fixes #<Issue号>"
```

**完成。** PR提交后，CI会自动在专用环境运行E2E测试并处理合并。

## 跨项目依赖

格式：`blocked-by: backend#N` 或 `WnadeyaowuOraganization/<repo>#<N>`

在开始工作前检查依赖Issue是否已关闭。

## CI/CD 流水线

| 流水线 | 触发 | 职责 |
|--------|------|------|
| 编程CC | run-cc.sh | TDD + 编译检查 + push feature + 创建PR |
| pr-test.yml | PR创建/更新 | CI专用环境E2E测试 → 通过auto merge+Done / 失败→E2E Fail |
| build-deploy-dev.yml | dev push | 后端构建部署+前端构建部署+Pipeline同步 |
| e2e_smoke (cron 30min) | crontab | Dev环境健康探活，失败自动创建Issue |
| e2e_top_tier (cron 6h) | crontab | 全量E2E回归，失败创建Issue |
