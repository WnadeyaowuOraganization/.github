# 研发经理 指南

> 当前角色：**研发经理**，由 `run-manager.sh` 启动 tmux 会话，`\loop 10m` 自驱动。
> 排程分析由排程经理负责（见 scheduler-guide.md），本经理只读 PLAN.md 执行指派和验收。
>
> 公共信息（看板ID、脚本速查、Effort表、通知规范）见 `CLAUDE.md`。
> 当前 Sprint：读取 `docs/status.md` 中「🟢 进行中」行确定（如 Sprint-1），对应路径为 `sprints/sprint-1/PLAN.md`。

## 职责

1. **指派** — 读 PLAN.md「下次指派时优先选择」→ prefetch → run-cc.sh → 标 In Progress
2. **巡检** — 读 tmux 会话实时输出，发现问题直接注入提示词
3. **恢复** — 处理 SAVED 状态、超时 CC，重启或标 Fail
4. **验证报告** — 阶段性汇总已完成 Issue、PR 合并率、Fail 原因，更新验收报告

## 任务一：指派（Todo → In Progress）

```bash
# 1. 检查当前槽位（最多15个并发CC）
bash scripts/cc-check.sh

# 2. 读取排程计划（排程经理已维护好的优先列表）
cat sprints/sprint-<N>/PLAN.md | grep -A 20 "下次指派时优先选择"

# 3. prefetch Issue 到 dev 分支（减少 CC 启动时 gh fetch）
bash scripts/prefetch-issues.sh <issue1> <issue2> ...

# 4. 启动 CC
bash scripts/run-cc.sh --module <module> --issue <N> --dir <kimi目录> --effort <effort>

# 5. 启动成功后标 In Progress
bash scripts/update-project-status.sh --repo play --issue <N> --status "In Progress"

# 6. 更新 PLAN.md：
#    - 「当前运行」表格新增一行：| kimiX | #N | Tier | module | 标题 | 刚启动 |
#    - 「下次指派时优先选择」列表对应行追加：→ kimiX 运行中
```

### module 对应目录

| 标签 | `--module` | 实际目录 |
|------|-----------|---------|
| `module:backend` | backend | `wande-play-<suffix>/backend` |
| `module:frontend` | frontend | `wande-play-<suffix>/frontend` |
| `module:pipeline` | pipeline | `wande-play-<suffix>/pipeline` |
| `module:fullstack` | fullstack | `wande-play-<suffix>/`（根目录） |

## 任务二：巡检 CC 进度

```bash
# 全面锁状态总览
bash scripts/cc-check.sh

# 读取指定会话实时输出（最近200行），判断是否卡住/报错/等待输入
tmux capture-pane -t cc-wande-play-kimi1-1234 -p -S -200
```

### 发现问题时注入提示词

```bash
tmux send-keys -t cc-wande-play-kimi3-1567 "请检查编译错误并修复" Enter
# 或通过 Claude Office 页面注入（http://localhost:9872）
```

### 判断标准

| 现象 | 处理 |
|------|------|
| tmux 输出停滞，最后一条是编译错误 | 注入提示词：「检查编译错误并修复」 |
| tmux 输出显示完成但无 PR 创建动作 | 注入提示词：「执行 gh pr create」 |
| tmux 会话已不存在，锁状态为 SAVED | 重新触发同 Issue 重入（run-cc.sh 同参数） |
| 🚨 tmux 输出超30分钟无新内容 | 先 `tmux kill-session` 再 `run-cc.sh` 同参数重启；重启失败再标 Fail |

## 任务三：恢复异常 CC

```bash
# 处理 SAVED 状态（cc-keepalive.sh 已自动处理，手动确认）
bash scripts/cc-check.sh | grep "SAVED\|超时"

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
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null
bash scripts/cc-check.sh
grep -A 20 "下次指派时优先选择" sprints/sprint-<N>/PLAN.md
```

### 第二步：分析归纳

提炼：完成 Issue 共性（模块分布、PR合并率）、Fail 原因分类、流水线健康状况、下批建议。

### 第三步：写入报告

读取 `docs/workflow/新harness验证报告.md` 现有内容，用 Edit 工具在末尾追加：

```markdown
## 批次验收 YYYY-MM-DD HH:MM

### 完成情况
- 共完成 N 个 Issue，PR 合并率 X%
- #N1 标题 — PR #M1（模块，耗时）

### 问题归因
- Fail x个：主要原因
- E2E Fail x个：原因

### 流水线状态
- 运行中 X 个，空闲 Y 个，卡住 Z 个（已处理）

### 下批建议
- #N backend kimi3（理由）
```
