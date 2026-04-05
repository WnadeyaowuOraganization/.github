# 测试规范

> **测试先行，代码后写。** 理解 Issue 需求后，第一件事是编写或补充单元测试。以通过所有单元测试为目标进行编码。没有通过单元测试 = 不允许提交。

## TDD 工作流

```
1. 读懂 Issue 需求 → 确定需要测试的方法和场景
2. 编写单元测试（此时测试应该编译通过但运行失败）
3. 编写业务代码让测试逐个变绿
4. 全量测试通过 → 提交
```

**每个 Issue 必须有对应测试。没有测试 = 没完成。**

## 单元测试

### 编写规范

- 文件位置：`src/test/java/` 对应包下
- 命名：`XxxServiceTest.java`
- 继承：`BaseServiceTest`（自动配置 H2 内存数据库 + @Transactional 回滚）
- 最少覆盖：创建、查询、更新、删除（针对 Service 层核心方法）
- 参考模板：`src/test/java/org/ruoyi/wande/controller/TenderDataControllerTest.java`
- 工具类：`TestDatabaseHelper` 可用于手动数据清理

### 不同场景的测试策略

| Issue 类型 | 测试要求 |
|-----------|---------|
| 新增 Service/功能 | 创建 `XxxServiceTest.java`，覆盖核心CRUD方法 |
| 修改已有 Service | 在已有 Test 中补充新增/变更方法的测试用例 |
| Bug 修复 | 编写能复现 Bug 的回归测试（先确认测试失败，修复后变绿） |
| Controller 新增 | 创建 `XxxControllerTest.java`，覆盖核心端点 |
| 纯配置/文档变更 | 可跳过单元测试（在 task.md 中说明原因） |

### 运行命令

```bash
# 运行单个测试类
mvn test -pl ruoyi-modules/wande-ai -Dtest=XxxServiceTest

# 运行 wande-ai 模块全量测试
mvn test -pl ruoyi-modules/wande-ai

# 运行全项目测试
mvn test
```

## API 集成测试

确认E2E项目中有对应的API测试：
- 查看 `$HOME_DIR/projects/wande-ai-e2e/tests/api/` 是否有本模块的测试文件
- 如果没有，创建 `tests/api/<module-name>.spec.ts` 基本测试（health + list接口）
- 运行：`cd $HOME_DIR/projects/wande-ai-e2e && npx playwright test tests/api/<module>.spec.ts`

## Shift-left 质量检查

合并到dev前必须全部通过：
- 编译通过：`mvn clean compile -Pprod -DskipTests`
- 单元测试通过：`mvn test -pl ruoyi-modules/wande-ai`
- API Smoke测试（如果后端在运行）：`cd $HOME_DIR/projects/wande-ai-e2e && npx playwright test tests/api/health.spec.ts --reporter=list`
- 如果Smoke测试失败，检查是否是本次代码引入的问题，修复后再合并
- **CI自动执行**：push到dev时ci-test.yml会自动跑编译+Smoke，失败会在GitHub Actions标红

## 自检清单

**全部PASS才能进入提交阶段：**

| 检查项 | 命令 | 状态 |
|--------|------|------|
| 单元测试已写 | 检查 `src/test/java/` 下有新增/修改的测试文件 | PASS |
| 单元测试全部通过 | `mvn test -pl ruoyi-modules/wande-ai` | PASS |
| mvn clean compile 编译通过 | `mvn clean compile -Pprod -DskipTests` | PASS |
| API Smoke测试通过（如后端在运行） | E2E health.spec.ts | PASS |
| 无新增编译警告 | 检查编译输出 | PASS |
