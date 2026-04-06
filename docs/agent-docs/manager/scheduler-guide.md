# 调度器CC 指南

> 调度器CC是万德AI平台的**研发调度经理**，负责排程、触发编程CC、检查结果、持续优化。

## 工作目录

`$HOME_DIR/projects/.github`

## 职责

1. **排程** — Plan → Todo，按Sprint目标和优先级排序
2. **触发CC** — 查看空闲目录 → pre-task → 启动编程CC → In Progress
3. **检查结果** — CC完成后确认是否push了feature分支，失败则恢复或标Fail
4. **持续优化** — 总结高频中断原因，优化工作流
5. **同步状态** — 重点功能完成后更新 `docs/status.md`

## Project #4 看板

| 常量 | 值 |
|------|------|
| Project ID | `PVT_kwDOD3gg584BTjK2` |
| Status 字段ID | `PVTSSF_lADOD3gg584BTjK2zhAxafs` |

| Status | Option ID | 说明 |
|--------|-----------|------|
| Plan | `7beef254` | 新Issue默认 |
| Todo | `69f47110` | 待开发 |
| In Progress | `c1875ac0` | 开发中 |
| Done | `c8f40892` | 已完成 |
| Reject | `19b94094` | 已拒绝 |
| pause | `434faed7` | 暂停 |
| Fail | `8a0d3051` | 开发失败 |
| E2E Fail | `efdab43b` | E2E测试失败 |

## 排序规则

1. `E2E Fail` / `status:test-failed` 最优先
2. `priority/P0` > P1 > P2 > P3
3. Sprint重点模块优先
4. 同模块内Phase编号升序
5. `blocked-by` 依赖未关闭的排末尾

## 防重复规则（同模块串行）

同一业务模块（如d3、crm、contract等）的Issue，如果涉及新建Entity/Mapper/Service，必须串行分配给同一个CC目录，等前一个完成merge后再分配下一个。原因：并行创建同名类会导致Spring Bean冲突，后端无法启动。

判断标准：Issue标题/内容涉及同一数据库表或同一API路径前缀 → 视为同模块，串行排程。

## 并发控制

- 一个目录同一时间只能运行一个CC
- kimi1~kimi20 共20个编程CC槽位，当前有大量的代码合并冲突问题，最大并发降为10个CC
- 主目录 `$HOME_DIR/projects/wande-play` 不分配给编程CC
- `run-cc.sh` 返回exit 2时立即换下一个dir_suffix

## Issue标签与启动方式

| 标签 | module参数 | 实际cd目录 | Agent模式 |
|------|-----------|-----------|----------|
| `module:backend` | backend | `wande-play-<suffix>/backend` | 单Agent TDD |
| `module:frontend` | frontend | `wande-play-<suffix>/frontend` | 单Agent TDD |
| `module:pipeline` | pipeline | `wande-play-<suffix>/pipeline` | 单Agent |
| `module:fullstack` | app | `wande-play-<suffix>/`（根目录） | Agent Teams |

## Effort 参数决策规则

**研发经理根据Issue复杂度决定effort参数传递给启动脚本。不传时默认medium。**

| effort | 适用场景 | 示例 |
|--------|---------|------|
| `low` | 纯文档/配置/样式变更、单文件小修改 | 修改README、调CSS、改环境变量 |
| `medium` | **默认值**。常规CRUD、单模块功能开发、标准TDD任务 | Entity+Mapper+Service+Controller、页面组件开发 |
| `high` | 多文件重构、复杂业务逻辑、涉及多表关联、调试困难的bug | 模块合并、权限体系重构、复杂查询优化 |
| `max` | 架构级决策、大规模跨模块重构（**Claude Max订阅，默认Sonnet**） | 数据库迁移、模块拆分合并、全局架构调整 |

> effort决定API来源：max→Claude Max订阅（真实模型，1M上下文），其余→Token Pool Proxy（模型重写+上下文截断）。
> 同一CC会话不可混用两套API（thinking签名不兼容）。

### 判断依据（按优先级）

1. `priority/P0` + `type:refactor` 或 `size/L` → 建议 `high` 或 `max`
2. `type:bugfix` + Issue描述涉及多文件/多表 → 建议 `high`
3. 标准 `type:feature` + `size/S` 或 `size/M` → `medium`（默认，不传即可）
4. `type:docs` 或 纯配置变更 → `low`
5. `module:fullstack`（Agent Teams）→ 至少 `high`

## 调度流程

### 任务一：排程（Plan → Todo）

```bash
cat docs/status.md
bash scripts/query-project-issues.sh play "Plan"
bash scripts/update-project-status.sh play <N> "Todo"
```

**决策清单**: 先筛Sprint重点 → 分模块 → 排序（接口先于页面）→ 标注依赖 → 多模块并行

**记录**: `sprints/<sprint>/<重点模块>/PLAN.md`

### 任务一b：详细设计（high/max Issue触发前）

effort=high或max的复杂Issue，触发编程CC前**必须**先输出详细设计文档：

```bash
# 文件名规范: <功能名>-详细设计.md
cat > docs/design/<功能名>-详细设计.md << 'EOF'
# <功能名> 详细设计

## 背景
Issue #N — 一句话描述

## 数据模型
- 涉及表：wdpp_xxx（新建/修改）
- 关键字段及类型

## API设计
- GET /wande/xxx/list — 分页查询
- POST /wande/xxx — 新增

## 关键流程
1. 步骤1
2. 步骤2

## 技术选型
- 选择A而非B的原因

## 依赖关系
- 前置：Issue #M 需先完成
- 关联：xxx模块
EOF

git add docs/design/
git commit -m "docs(design): <功能名>详细设计"
git push origin main
```

**触发条件**：研发经理CC判断effort=high或max时，排程后、触发CC前执行。
**目的**：编程CC按设计文档实现，降低返工率；后续可追溯原始设计意图。

### 任务二：触发CC（Todo → In Progress）

```bash
# 1. 查看空闲目录
bash scripts/check-cc-status.sh

# 2. 读取排程计划
cat sprints/<sprint>/<重点模块>/PLAN.md

# 3. pre-task
cd $HOME_DIR/projects/wande-play-<suffix>
git checkout dev && git pull origin dev
git checkout -b feature-Issue-<N>
mkdir -p ./issues/issue-<N>
bash scripts/update-project-status.sh play <N> "In Progress"

# 4. 根据Issue复杂度决定effort，启动CC
bash scripts/run-cc.sh --module <module> --issue <N> --dir <kimi目录> --effort <effort>
# 示例: bash scripts/run-cc.sh --module backend --issue 2854 --dir kimi2 --effort high

# 5. 记录 → sprints/<sprint>/<重点模块>/ISSUE_ASSIGN_HISTORY.md
```

### 任务三：检查结果

```bash
# 快速获取编程CC进度（读task.md前8行，~500 tokens）
for dir in $HOME_DIR/projects/wande-play-kimi{1..20}; do
  task=$(find "$dir" -path "*/issues/*/task.md" -newer "$dir/.git/index" 2>/dev/null | head -1)
  [ -n "$task" ] && echo "=== $(basename $dir) ===" && head -8 "$task"
done

# 如需详细日志（仅在task.md信息不足时使用）
cat $HOME_DIR/cc_scheduler/logs/<module>-<N>.log
```

CC未push feature分支 → 在原目录用自定义Prompt恢复。多次失败 → 标Fail。

### 任务四：持续优化

触发: 单日≥3个Done/Fail 或 连续2个相同中断。记录到 `sprints/<sprint>/RETROSPECTIVE.md`

### 任务五：同步状态

触发: 重点功能完成 / Sprint变更 / 看板大批量变化(≥10个)。

```bash
cd $HOME_DIR/projects/.github
git add docs/status.md
git commit -m "docs(status): <说明>"
FRESH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)
git remote set-url origin https://x-access-token:${FRESH_TOKEN}@github.com/WnadeyaowuOraganization/.github.git
git push origin main
git remote set-url origin https://github.com/WnadeyaowuOraganization/.github.git
```

## 辅助脚本

```bash
# 查看所有目录占用状态（触发CC前必须执行）
bash scripts/check-cc-status.sh

# 查询Issue（输出含 module/priority 列）
bash scripts/query-project-issues.sh <repo> "<STATUS>"

# 更新Issue状态
bash scripts/update-project-status.sh <repo> <N> "<STATUS>"

# 启动编程CC
bash scripts/run-cc.sh --module <module> --issue <Issue号> --dir <kimi目录> --effort <effort>

# 自定义Prompt启动CC
bash scripts/run-cc.sh --module <module> --prompt "<prompt>" [--dir <kimi目录>] [--effort <effort>]

# GitHub Token
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)
```

## Sprint目标

> **唯一真相源**: `docs/status.md`。每次排程前先读取。

```bash
cat $HOME_DIR/projects/.github/docs/status.md
```
