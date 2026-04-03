# 测试架构改革方案（草稿）

> 状态：讨论中 | 创建：2026-04-03 | 待确认后实施

## 目标

将测试环节从 AI 驱动改为 CI/CD 驱动，减少模型调用，提高效率。

## 新三层架构

| 层级 | 触发方式 | 范围 | AI参与 |
|------|---------|------|--------|
| 快速验证 | feature push → CI | smoke + 对应模块测试 | 待讨论 |
| 中层测试 | PR 创建/更新 → CI | 按变更模块完整E2E | 仅失败分析 |
| 顶层测试 | cron 6h | 全量回归 | 仅创建Issue |

## feature 分支流水线（整合 post-task.sh）

```
编程CC push feature → CI 触发
  Step 1: 构建验证（pnpm build / mvn compile）
  Step 2: 快速验证（smoke 测试）
  Step 3: 通过 → 自动创建 feature→dev PR
  Step 4: 失败 → commit status 标红
```

## PR 流水线

```
PR 创建/更新 → CI 触发
  Step 1: 按变更模块跑完整 E2E
  Step 2: 通过 → 自动 approve + merge + Issue 标 Done
  Step 3: 失败 → 评论 PR + Issue 标 test-failed + Todo
```

## 待讨论问题

### 1. 快速验证的测试用例来源
- 新功能没有对应测试用例，CI 无法独立完成快速验证
- 方案A: CI触发后由CC补充用例（需自定义prompt，研发经理CC需协调避免目录冲突）
- 方案B: 编程CC在push前就写好playwright测试用例
- 方案C: 新功能跳过快速验证，只跑已有smoke

### 2. 快速验证失败时的修复闭环
- 编程CC push后已结束工作
- 方案A: CI失败后触发新CC会话在同目录修复
- 方案B: 编程CC在push前就确保测试通过（Shift Left彻底化）
- 方案C: 失败后走test-failed流程，研发经理CC重新排程

### 3. 单元测试与Playwright测试的边界
- 编程CC已有TDD（JUnit/Vitest单元测试）
- 如果编程CC也写Playwright测试，与中层E2E用例可能重复
- 需要明确：谁写什么层级的测试

## 变更影响

- post-task.sh 退役，PR创建由CI自动完成
- e2e_mid_tier.sh cron 可能退役（改为PR事件触发）
- 编程CC CLAUDE.md 第三阶段简化
- 测试CC角色收缩为：补充用例 + 分析复杂失败
