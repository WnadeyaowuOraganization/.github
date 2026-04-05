# PR 冲突解决 CC 方案

## 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    调度器 (Scheduler CC)                      │
│                  /home/ubuntu/projects/.github               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 检测到 PR 冲突
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              冲突解决 CC (Conflict Resolver)                   │
│               /home/ubuntu/projects/wande-play-ci            │
│                                                              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │ 分析冲突    │ → │ 智能合并    │ → │ 编译测试    │        │
│  │ 分类处理    │   │ 保留功能    │   │ 推送结果    │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│                                                              │
│  并发控制: CI 全局排队 (concurrency.group: pr-e2e-test)       │
└─────────────────────────────────────────────────────────────┘
```

## 工作流程

### 1. 调度器检测冲突
```bash
# cycle-merge.sh 中检测到复杂冲突时
if has_complex_conflicts; then
    bash scripts/trigger-conflict-resolver.sh $PR_NUMBER
fi
```

### 2. 冲突分类规则

| 文件类型 | 处理方式 | 示例 |
|---------|---------|------|
| schema.sql | 自动解决 | 测试数据库结构 |
| pom.xml | 自动解决 | 依赖配置 |
| test/**/*.java | 自动解决 | 测试代码 |
| **/*.java | CC 智能解决 | 业务代码 |
| **/*.ts | CC 智能解决 | 前端代码 |
| rename/delete | CC 智能解决 | 文件重命名/删除 |

### 3. CC Prompt 模板

```markdown
# 任务：解决 PR 合并冲突

## PR 信息
- PR 号: #123
- 标题: [模块] 功能描述
- 分支: feature-xxx -> dev

## 冲突详情
请阅读 `issues/issue-pr-123/conflict.md`

## 解决原则
1. **保留双方功能**: 不要简单地选择一边，要合并两边的逻辑
2. **语义理解**: 理解代码修改的意图，而不是机械合并
3. **编译验证**: 解决后运行 `mvn compile` 确保编译通过
4. **测试验证**: 如果有测试，确保测试通过

## 输出要求
1. 解决所有冲突文件
2. 提交 commit: `fix: resolve merge conflicts for PR #123`
3. 推送到远程分支
4. 报告解决结果
```

### 4. 触发方式

```bash
# 方式 1: 手动触发
bash scripts/trigger-conflict-resolver.sh 1234

# 方式 2: 定时任务自动触发
# cron: */10 * * * *
bash scripts/trigger-conflict-resolver.sh <next_conflicting_pr>

# 方式 3: CI 工作流触发
# 在 .github/workflows/pr-test.yml 中添加
- name: 触发冲突解决 CC
  if: failure()  # 合并失败时
  run: |
    curl -X POST http://localhost:8080/trigger-cc \
      -d '{"pr": "${{ github.event.pull_request.number }}"}'
```

## 目录隔离

```
wande-play-ci/          # 冲突解决 CC 专用目录
├── issues/
│   └── issue-pr-123/
│       ├── conflict.md     # 冲突详情
│       ├── resolved.md     # 解决报告
│       └── .progress       # 进度标记
├── backend/
└── frontend/
```

## 并发控制

利用现有的 CI 全局排队机制：
```yaml
concurrency:
  group: pr-e2e-test        # 与 CI 共享队列
  cancel-in-progress: false # 不取消进行中的任务
```

这确保：
1. 冲突解决 CC 与 CI 测试串行执行
2. 不会出现多个 CC 同时修改同一分支
3. 避免资源竞争

## 监控与回滚

```bash
# 检查冲突解决进度
cat /home/ubuntu/projects/wande-play-ci/issues/issue-pr-123/.progress

# 回滚（如果解决失败）
cd /home/ubuntu/projects/wande-play-ci
git checkout dev
git branch -D conflict-resolve-123
```

## 下一步实施

1. [ ] 创建 `trigger-conflict-resolver.sh` ✓
2. [ ] 修改 `cycle-merge.sh` 集成冲突解决 CC
3. [ ] 测试一个真实 PR 的冲突解决
4. [ ] 添加到定时任务
