# 研发经理 指南

> 当前角色：**研发经理**，由 `run-manager.sh` 启动 tmux 会话，`\loop 10m` 自驱动。
> 排程分析由排程经理负责（见 scheduler-guide.md），本经理只读 PLAN.md 执行指派和验收。

## 工作目录

`$HOME_DIR/projects/.github`

## 职责

1. **指派** — 读 PLAN.md「下次指派时优先选择」→ prefetch → run-cc.sh → 标 In Progress
2. **巡检** — 读各 kimi 目录 task.md 了解进度，发现问题直接注入提示词
3. **恢复** — 处理 SAVED 状态、超时 CC，重启或标 Fail
4. **验证报告** — 阶段性汇总已完成 Issue、PR 合并率、Fail 原因，更新验收报告

## Project #4 看板

| 常量 | 值 |
|------|------|
| Project ID | `PVT_kwDOD3gg584BTjK2` |
| Status 字段ID | `PVTSSF_lADOD3gg584BTjK2zhAxafs` |

| Status | Option ID |
|--------|-----------|
| Jump | `03012e67` |
| Todo | `d14d5f74` |
| In Progress | `4a591864` |
| Done | `ba15b774` |
| Fail | `787b6892` |
| E2E Fail | `8d2164a2` |

## 任务一：指派（Todo → In Progress）

```bash
# 1. 检查当前槽位（最多5个并发CC）
bash scripts/check-cc-status.sh

# 2. 读取排程计划（排程经理已维护好的优先列表）
cat sprints/sprint-1/PLAN.md | grep -A 20 "下次指派时优先选择"

# 3. prefetch Issue 到 dev 分支（减少 CC 启动时 gh fetch）
bash scripts/prefetch-issues.sh <issue1> <issue2> ...

# 4. 标 In Progress
bash scripts/update-project-status.sh --repo play --issue <N> --status "In Progress"

# 5. 启动 CC
bash scripts/run-cc.sh --module <module> --issue <N> --dir <kimi目录> --effort <effort>

# 6. 记录指派历史
echo "$(date) #N → kimiX (module, effort)" >> sprints/sprint-1/ISSUE_ASSIGN_HISTORY.md
```

### Effort 决策

| effort | 场景 |
|--------|------|
| `low` | 纯文档/配置/样式 |
| `medium` | 默认。常规 CRUD |
| `high` | 多文件重构、复杂业务、`module:fullstack` |
| `max` | 架构级重构（走 Claude Max 订阅） |

### module 对应目录

| 标签 | `--module` | 实际目录 |
|------|-----------|---------|
| `module:backend` | backend | `wande-play-<suffix>/backend` |
| `module:frontend` | frontend | `wande-play-<suffix>/frontend` |
| `module:pipeline` | pipeline | `wande-play-<suffix>/pipeline` |
| `module:fullstack` | fullstack | `wande-play-<suffix>/`（根目录） |

## 任务二：巡检 CC 进度

```bash
# 读 task.md（最轻量，~500 tokens）
for dir in $HOME_DIR/projects/wande-play-kimi{1..20}; do
  task=$(find "$dir" -path "*/issues/*/task.md" -mmin -120 2>/dev/null | head -1)
  [ -n "$task" ] && echo "=== $(basename $dir) ===" && head -8 "$task"
done

# 查看锁状态
bash scripts/check-cc-status.sh
```

### 发现问题时注入提示词

```bash
# 查看运行中的 CC 会话
tmux ls | grep "^cc-"

# 注入提示词（CC 等待输入时生效）
tmux send-keys -t cc-wande-play-kimi3-1567 "请检查编译错误并修复" Enter

# 或通过 Claude Office 页面注入（http://localhost:9872）
```

### 判断标准

| 现象 | 处理 |
|------|------|
| task.md Phase=BUILD_CHECK 超30分钟 | 注入提示词：「检查编译错误」 |
| task.md Status=DONE 但 PR 未创建 | 注入提示词：「执行 gh pr create」 |
| 💾 SAVED 状态 | 重新触发同 Issue 重入（run-cc.sh 同参数） |
| 🚨 超1小时无进展 | 先注入提示词，无响应则标 Fail |

## 任务三：恢复异常 CC

```bash
# 处理 SAVED 状态（post-cc-check.sh 已自动处理，手动确认）
bash scripts/check-cc-status.sh | grep "SAVED\|超时"

# 重新触发（同 Issue 重入）
bash scripts/run-cc.sh --module <原module> --issue <N> --dir <原kimi目录> --effort <原effort>

# 标 Fail（retry≥10 或确认无法修复）
bash scripts/update-project-status.sh --repo play --issue <N> --status "Fail"
gh issue comment <N> --repo WnadeyaowuOraganization/wande-play --body "❌ 多次失败，标记 Fail。原因：..."
```

## 任务四：阶段性验证报告

触发条件：单轮 ≥3 个 Done，或连续2个相同 Fail 原因，或用户要求。

**流程：先收集数据 → 分析归纳 → 写入报告，不能直接拼接原始数据**

### 第一步：收集数据

```bash
# 1. 查询本轮完成的 Issue
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null

# 2. 查询 Fail / E2E Fail
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null

# 3. 各 kimi 目录当前状态
bash scripts/check-cc-status.sh

# 4. 读取 PLAN.md 下批建议
grep -A 20 "下次指派时优先选择" sprints/sprint-1/PLAN.md
```

### 第二步：分析归纳

阅读收集到的数据，提炼：
- 完成 Issue 的共性（模块分布、耗时、PR合并率）
- Fail 原因分类（编译错误/依赖缺失/超时等），是否有系统性问题
- 当前流水线健康状况（运行中/空闲/卡住比例）
- 下批指派建议及理由

### 第三步：写入报告

读取 `docs/workflow/新harness验证报告.md` 现有内容，在文件末尾追加一个新的批次章节：

```markdown
## 批次验收 YYYY-MM-DD HH:MM

### 完成情况
- 共完成 N 个 Issue，PR 合并率 X%
- #N1 标题 — PR #M1（模块，耗时）
- #N2 标题 — PR #M2（模块，耗时）

### 问题归因
- Fail x个：主要原因（编译错误/依赖缺失等）
- E2E Fail x个：原因

### 流水线状态
- 运行中 X 个，空闲 Y 个，卡住 Z 个（已处理）

### 下批建议
- #N backend kimi3（理由）
- #N frontend kimi4（理由）
```

用 Edit 工具追加，**不要用 cat >>**，确保格式正确。

## 辅助脚本

```bash
bash scripts/check-cc-status.sh                                                    # 全面状态
bash scripts/query-project-issues.sh --repo play --status "Todo"                   # 待指派
bash scripts/update-project-status.sh --repo play --issue N --status "In Progress" # 标进行中
bash scripts/run-cc.sh --module backend --issue N --dir kimi1 --effort medium      # 启动 CC
bash scripts/prefetch-issues.sh N1 N2 N3                                           # 预下载 Issue
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)
```

## 每轮结束后发送通知

```bash
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"manager-研发经理\",\"message\":\"指派X个Issue：#N1(kimi1) #N2(kimi2)；巡检Y个运行中\",\"type\":\"success\"}"
```
