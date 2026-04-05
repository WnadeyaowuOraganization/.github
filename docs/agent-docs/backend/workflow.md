# 工作流程

## 任务来源

**所有任务通过 GitHub Issue 下发，由研发经理CC分配。**

调度器已完成：选定Issue → 创建工作目录 `./issues/issue-<N>` → 签出 feature 分支。
你启动时已在 feature 分支上，工作目录已创建。

**第一件事**：
1. `gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments` 读取Issue完整内容
2. 如果 `./issues/issue-<N>/task.md` 已存在，读取后继续（断点恢复）

## TDD三阶段开发流程

### 第一阶段：准备

1. **读取Issue**：`gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments`
2. **创建 task.md**：在 `./issues/issue-<N>/` 下拆解为可执行的 task
3. **需求评估**：
   - A: 可执行 → 继续
   - B: 需确认 → 评论Issue + `bash $HOME_DIR/projects/.github/scripts/update-project-status.sh play <N> "pause"` → 结束
   - C: 不可执行 → 评论 + 标 `status:blocked` → 结束

> 工作目录和 feature 分支由调度器 pre-task 创建，无需手动操作。

### 第二阶段：编码 + 测试

#### Step 0: 查重（创建任何新类之前必须执行）

新建 Entity/Vo/Bo/Mapper/Service/Controller 之前，搜索是否已存在同名类：
```bash
grep -rn "class 类名" --include="*.java" backend/ | grep -v target
```
如果已存在同名类，直接复用或扩展，禁止在新包下重复创建。

#### Step 1: 单元测试先行

1. 分析Issue需要测试的 Service 方法
2. 编写 `src/test/java/` 下的 `XxxServiceTest.java`（继承 `BaseServiceTest`）
3. 运行确认红灯：`mvn test -pl ruoyi-modules/wande-ai -Dtest=XxxServiceTest`

#### Step 2: 编写业务代码

1. Entity → Mapper → Service → Controller
2. 持续运行测试确认绿灯
3. 全量测试无回归：`mvn test -pl ruoyi-modules/wande-ai`

#### Step 3: 编译检查

```bash
mvn clean package -Pprod -Dmaven.test.skip=true
```

⛔ 编译失败必须修复，不管是否与当前Issue相关。

> 注意：不需要运行 deploy-dev.sh 部署到 Dev 环境。PR merge 到 dev 后，CI/CD 会自动构建部署。E2E 测试由 pr-test.yml 在 CI 专用环境执行。

#### 门禁（全部 PASS 才能提交）

| 检查项 | 验证方式 |
|--------|---------|
| 单元测试通过 | `mvn test -pl ruoyi-modules/wande-ai` |
| 编译打包成功 | `mvn clean package -Pprod -Dmaven.test.skip=true` 退出码 0 |
| 新增测试存在 | `src/test/java/` 有本Issue测试 |

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

**完成。** PR 提交后，CI 会自动在专用环境运行 E2E 测试并处理合并。

## Git 分支规范

- **main**: 生产分支
- **dev**: 测试分支，push 触发 CI/CD
- **feature-Issue-<N>**: 从 dev 签出（调度器创建）

**只 push feature 分支**，不要 push dev 或 main。
