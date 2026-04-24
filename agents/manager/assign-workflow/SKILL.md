---
name: assign-workflow
description: 研发经理每轮巡检工作流：指派 CC（Todo→In Progress）、attention-only 巡检 CC 进度、恢复异常 CC、阶段性验证报告、PLAN.md 维护。每10分钟 loop 时自动触发。
---

# 研发经理工作流

> 当前角色：**研发经理**，负责指派、巡检、恢复和验证。
> 排程分析由排程经理负责，见 scheduler-workflow skill。

## 每轮巡检执行顺序（强制）

1. **检查未回复消息** — tmux 会话中有 `【需回复】` → 立即回复后再执行巡检
2. **任务一** — 指派（有空闲 kimi 槽位时）
3. **任务二** — 巡检 CC 进度（attention-only 模式）
4. **任务三** — 恢复异常 CC（SAVED / 超时）
5. **任务四** — 阶段性验证报告（≥3 个新 Done 时触发）
6. **PLAN.md 同步** — 更新当前运行表 + 指派历史表

## ⚠️ Done 的硬定义（红线）

Issue → Done 必须**同时满足**，缺一不可：

1. `gh pr view <PR> --json mergedAt --jq '.mergedAt'` 返回非空时间
2. `gh issue view <N> --json state,stateReason` 返回 `closed/completed`

Done 由 `pr-test.yml` 自动触发。研发经理 ⛔ **永远不要**主动执行：
- `update-project-status.sh --status "Done"`
- `gh issue close`
- 任何手动改看板为 Done 的操作

### 状态对照表

| 阶段 | 看板状态 | 研发经理动作 |
|------|---------|-------------|
| 指派启动 CC | Todo → In Progress | 手动改（**唯一主动变更**） |
| CC 写代码中 | In Progress | 仅巡检注入，不改状态 |
| CC 退出无 PR | In Progress | 注入「执行 gh pr create」 |
| PR open + CI 跑中 | In Progress | 等 CI，不改状态 |
| PR + CI failure | In Progress | 看失败详情，注入 CC 修复 |
| PR + CONFLICTING | In Progress | 注入 rebase 命令 |
| PR squash-merged | **自动 → Done** | 仅 PLAN.md 划删除线 |
| CC 异常无法恢复 | Fail | **唯一允许的失败终态变更** |

### ⛔ Done 禁止操作

- CC 进程退出就改 Done
- PR 已创建就改 Done
- tmux 输出 "完成/done/✅" 就改 Done
- 手动 `gh issue close`
- In Progress 直接跳 Done
- 批量把多个 issue 改 Done

### Done Guard（硬隔离）

`update-project-status.sh --status "Done"` 内置硬校验：必须存在引用该 issue 且 `mergedAt` 非空的 PR，否则 **exit 2** 拒绝执行。

### 拿不准时

```bash
gh pr list --repo WnadeyaowuOraganization/wande-play --search "Issue-<N> in:branch" --state all --json number,state,mergedAt
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --json state,stateReason,closedAt
```

## 任务一：指派（Todo → In Progress）

```bash
# 1. 检查槽位（最多15个并发CC）
bash scripts/cc-check.sh

# 2. 读排程经理的指派建议表
cat sprints/sprint-<N>/PLAN.md | grep -A 25 "指派建议"

# 3. 前端 Issue 指派前确认配对后端 PR 已 merged

# 4. prefetch Issue
bash scripts/prefetch-issues.sh <issue1> <issue2> ...

# 5. 启动 CC
bash scripts/run-cc.sh --module <module> --issue <N> --dir <kimi目录> --effort <effort>

# 6. 标 In Progress
bash scripts/update-project-status.sh --repo play --issue <N> --status "In Progress"

# 7. 更新 PLAN.md：当前运行 + 指派历史 各新增一行
```

### module 对应

| 标签 | `--module` | 实际目录 |
|------|-----------|---------|
| `module:backend` | backend | `wande-play-<suffix>/backend` |
| `module:frontend` | frontend | `wande-play-<suffix>/frontend` |
| `module:pipeline` | pipeline | `wande-play-<suffix>/pipeline` |
| `module:fullstack` | fullstack | `wande-play-<suffix>/`（根目录） |

## 任务二：巡检 CC 进度（attention-only 模式）

> 不再 tmux capture-pane 全场扫描。改用 server.py 规则引擎预筛，只对 `needs_attention=true` 精细介入。

### Step 1：拉取全场摘要

```bash
curl -s http://localhost:9872/api/status | jq '.agents[] | {
  id, issue_number, module, status,
  silent_minutes, lock_state,
  pr_summary, needs_attention, attention_reason,
  estimated_progress, progress_source
}'

ATTENTION=$(curl -s http://localhost:9872/api/status \
  | jq -c '.agents[] | select(.needs_attention)')

if [ -z "$ATTENTION" ]; then
  echo "✓ 全场自监控中，本轮无需介入"
fi
```

### Step 2：处理 attention CC

```bash
echo "$ATTENTION" | jq -c '.' | while read agent; do
  ID=$(echo "$agent" | jq -r '.id')
  ISSUE=$(echo "$agent" | jq -r '.issue_number')
  REASON=$(echo "$agent" | jq -r '.attention_reason')

  case "$REASON" in
    *"静默"*) tmux capture-pane -t "$ID" -p -S -100 | tail -50 ;;
    *"无 PR"*) bash scripts/inject-cc-prompt.sh $ISSUE "请确认进度，如已完成请 push + gh pr create" ;;
    *"Fail 终态"*) bash scripts/update-project-status.sh --repo play --issue $ISSUE --status "Fail" ;;
  esac
done
```

### Step 3：检查最近 merged PR（PLAN.md 同步用）

```bash
gh pr list --repo WnadeyaowuOraganization/wande-play --state merged \
  --search "merged:>$(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
  --json number,title,mergedAt,headRefName \
  --jq '.[] | "\(.number)\t\(.headRefName)\t\(.mergedAt)"'
```

### 巡检判断标准

| 现象 | 处理（**全程不允许改 Done**） |
|------|------|
| 编译错误停滞 | 注入「检查编译错误并修复」 |
| 输出"完成"但无 PR | 注入「执行 gh pr create」 |
| 会话不存在 + SAVED | 重新 run-cc.sh 同参数重入 |
| 超30分钟无输出 | kill-session → run-cc.sh 重启 |
| PR 等 CI | **不做任何变更** |
| PR CONFLICTING | 注入 rebase 命令 |
| PR CI failure | 看失败详情，注入修复 |
| PR merged 但 PLAN.md 未更新 | 删行 + 划线（看板由 CI 自动改） |
| PR 超2小时未 merged | 检查卡在哪个 CI job |
| Issue closed 但 PR 不存在 | **误关，立即 reopen** |

## 任务三：恢复异常 CC

```bash
bash scripts/cc-check.sh | grep "SAVED\|超时"

# 重新触发
bash scripts/run-cc.sh --module <原module> --issue <N> --dir <原kimi目录> --effort <原effort>

# cc-keepalive.sh 自动重试 ≤10 次后自动标 Fail，研发经理通常不主动操作
```

## 任务四：阶段性验证报告

触发：自上次报告起累计 ≥3 个新 Done，或连续 2 个相同 Fail 原因。

```bash
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/cc-check.sh
```

写入 `docs/workflow/新harness验证报告.md`，格式：

```markdown
## 批次验收 YYYY-MM-DD HH:MM

### 完成情况
### 问题归因
### 流水线状态
### 下批建议
```

## PLAN.md 维护规范

### 写权限分工

| 区域 | 维护方 |
|------|-------|
| 「指派建议」表 | **排程经理** 写，研发经理只读 |
| Sprint 明细表 `状态` 列 | **排程经理** 写 |
| 「当前运行」表 | **研发经理** 写 |
| 「指派历史」表 | **研发经理** 写 |

### 何时更新

| 事件 | 更新位置 |
|------|---------|
| 指派新 Issue | 当前运行 + 指派历史 各新增行 |
| PR squash-merged | 当前运行删行 + 指派历史 ~~Done~~ |
| CC 失败放弃 | 当前运行删行 + 指派历史 ~~Fail~~ |

> ⚠️ "CC 进程退出" **不是**事件触发器！只有 PR mergedAt 非空才允许标 Done。

### 并发约束

改 PLAN.md 前必须 `git pull`，改完立即 `git add + commit + push`。

## 故障兜底

| 现象 | 处理 |
|------|------|
| `gh` 401 | `export GH_TOKEN=$(python3 scripts/gh-app-token.py wandeyaowu)` |
| `cc-check.sh` 报错 | `git pull` 同步最新版本 |
| `tmux send-keys` 特殊字符 | 用 `scripts/inject-cc-prompt.sh` |

## 辅助 Agent

- `pr-reviewer.md` — AI PR 审查员 subagent

## 当前 Sprint 确认

```bash
cat docs/status.md | head -150
cat sprints/sprint-<N>/PLAN.md | head -50
```
