# PR 冲突处理工作流优化建议

## 问题
当前调度器直接执行 `git checkout --theirs` 解决冲突，存在风险：
1. 可能丢失 PR 作者的代码
2. 没有智能分析冲突语义
3. 复杂冲突无法自动处理

## 建议的工作流

### 方案 A：触发编程 CC 处理复杂冲突

```
检测到 PR 冲突
    ↓
判断冲突类型
    ↓
├── 简单冲突（schema.sql、测试文件）
│   └── 自动解决：使用 dev 版本
│
└── 复杂冲突（业务代码、rename/delete）
    └── 触发编程 CC：
        1. 分析冲突文件
        2. 理解双方修改意图
        3. 智能合并或标记问题
```

### 方案 B：分类处理策略

| 冲突类型 | 处理方式 |
|---------|---------|
| schema.sql | 自动解决（使用 dev 版本） |
| 测试文件 | 自动解决 |
| 配置文件 pom.xml | 自动解决 |
| 业务代码 .java/.ts | 触发编程 CC |
| rename/delete 冲突 | 触发编程 CC 或标记 Fail |

### 方案 C：新增脚本 `scripts/resolve-pr-with-cc.sh`

```bash
#!/bin/bash
# resolve-pr-with-cc.sh — 使用编程 CC 解决 PR 冲突
# 用法: bash scripts/resolve-pr-with-cc.sh <pr_number> <dir_suffix>

PR_NUMBER=$1
DIR_SUFFIX=$2

# 1. Checkout 分支到外挂目录
# 2. 尝试 rebase
# 3. 如果有冲突，分析冲突文件类型
# 4. 简单冲突自动解决
# 5. 复杂冲突触发编程 CC：
#    bash scripts/run-cc-with-prompt.sh <module> "解决 PR #$PR_NUMBER 的合并冲突" <model> <suffix>
```

## 编程 CC 处理冲突的 Prompt 示例

```markdown
## 任务
PR #123 与 dev 分支存在合并冲突，请解决。

## 冲突文件
- backend/.../SomeService.java

## 冲突内容
<<<<<<< HEAD (dev)
// dev 分支的代码
=======
// PR 分支的代码
>>>>>>> feature-xxx

## 要求
1. 理解双方修改的意图
2. 合并两边的逻辑，不要丢失任何功能
3. 确保代码编译通过
4. 提交并推送
```

## 实施步骤

1. [ ] 创建 `scripts/analyze-conflict-type.sh` 分析冲突类型
2. [ ] 修改 `cycle-merge.sh` 根据冲突类型选择处理方式
3. [ ] 创建 `resolve-pr-with-cc.sh` 脚本
4. [ ] 定义需要 CC 处理的文件模式列表
