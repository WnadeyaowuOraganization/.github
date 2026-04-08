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

---

## ⚠️ Done 的硬定义（不允许主观判断）

> **2026-04-08 强化**：之前因为措辞含糊，研发经理把「PR 已创建」当作「任务完成」，
> 导致 #3458 系列 issue 在没有任何代码 merge 进 dev 的情况下被错误关闭。
> 本节为硬约束，不接受任何例外。

**Issue 状态变更为 Done 必须同时满足两个条件，缺一不可**：

1. PR squash-merged into `dev` 分支
   - 验证：`gh pr view <PR_NUM> --json mergedAt --jq '.mergedAt'` 返回非空 ISO 时间
2. Issue 在 GitHub 上 closed 且 `state_reason=completed`
   - 验证：`gh issue view <N> --json state,stateReason` 返回 `closed/completed`
   - 这一步通常由 GitHub 在 PR squash-merge 时根据 PR body 中的 `Closes #N` 自动完成

**研发经理 永远不要 主动调用以下命令把 Issue 标 Done**：
- ❌ `update-project-status.sh --status "Done"`
- ❌ `gh issue close`
- ❌ 任何手动改 Project#4 看板 Status 字段为 Done 的操作

**Done 状态由 `pr-test.yml` 的 `auto-merge` job 在 PR 真正 squash-merge 后自动触发**。
研发经理的职责是：让 CC 把代码写到能让 CI 通过的程度，剩下交给 CI。

### 中间状态映射表

| CC / PR 阶段 | Issue 看板 Status | 研发经理动作 |
|--------------|------------------|-------------|
| CC 启动跑 | In Progress | 指派时手动改（这是唯一允许的状态变更） |
| CC 写代码中（tmux 输出活跃） | In Progress | 仅巡检注入，不改状态 |
| CC 进程退出 但 PR 未创建 | In Progress | 注入「执行 gh pr create」，不改状态 |
| PR open，CI 跑中 | In Progress | 等 CI 结果，不改状态 |
| PR open，CI failure | In Progress | 看 PR 评论中失败详情，注入修复 prompt，不改状态 |
| PR open，mergeable=CONFLICTING | In Progress | 注入「git fetch + rebase + force-push」，不改状态 |
| PR squash-merged | **看板自动 → Done** | 仅画删除线（Markdown 视觉同步），不改实际看板 |
| CC 进程异常退出 + 无法恢复 + 无 PR | Fail | 唯一允许研发经理主动改的非 In Progress 状态 |

### ⛔ 禁止行为清单

- ❌ 禁止：CC 进程退出就把 Issue 看板状态改 Done
- ❌ 禁止：PR 已创建就把 Issue 看板状态改 Done
- ❌ 禁止：tmux 输出"完成/done/✅"字样就把状态改 Done
- ❌ 禁止：手动 `gh issue close <N>`
- ❌ 禁止：把状态从 In Progress 直接跳到 Done 而不经过 PR squash-merge
- ❌ 禁止：批量把多个 issue 改 Done（这是 #3458 系列误关的根本动作）

**如果你不确定 issue 是否真的已完成，运行**：
```bash
gh pr list --repo WnadeyaowuOraganization/wande-play --search "Issue-<N> in:branch" --state all --json number,state,mergedAt
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --json state,stateReason,closedAt
```
如果 PR 不存在或 mergedAt 为空，issue 一定不能改 Done。

---

## 任务一：指派（Todo → In Progress）

```bash
# 1. 检查当前槽位（最多15个并发CC）
bash scripts/cc-check.sh

# 2. 读取排程经理维护的指派建议表（最高优先参考）
cat sprints/sprint-<N>/PLAN.md | grep -A 25 "指派建议"

# 3. prefetch Issue 到 dev 分支（减少 CC 启动时 gh fetch）
bash scripts/prefetch-issues.sh <issue1> <issue2> ...

# 4. 启动 CC
bash scripts/run-cc.sh --module <module> --issue <N> --dir <kimi目录> --effort <effort>

# 5. 启动成功后标 In Progress
bash scripts/update-project-status.sh --repo play --issue <N> --status "In Progress"

# 6. 更新 PLAN.md 两处：
#    - 「当前运行」表格新增一行：| kimiX | #N | Tier | module | 内容 |
#    - 「指派历史」表格新增一行：| kimiX | #N | Tier | module | 内容 | In Progress |
```

### module 对应目录

| 标签 | `--module` | 实际目录 |
|------|-----------|---------|
| `module:backend` | backend | `wande-play-<suffix>/backend` |
| `module:frontend` | frontend | `wande-play-<suffix>/frontend` |
| `module:pipeline` | pipeline | `wande-play-<suffix>/pipeline` |
| `module:fullstack` | fullstack | `wande-play-<suffix>/`（根目录） |

## PLAN.md 维护规范（研发经理负责）

> ⚠️ PLAN.md 是唯一的指派记录源，每次操作后必须立即更新，不得积压。

### 三个必须维护的区域

#### 1. 「指派历史（完成后划线）」表格
格式：`| 指派目录 | Issue | Tier | 模块 | 内容 | 看板状态 |`
- 指派时：新增一行，看板状态填 `In Progress`
- **PR squash-merged 后**（不是 CC 退出！）：内容列加删除线，看板状态改 `~~Done~~`（这只是 Markdown 视觉同步，看板实际状态由 CI 自动改）
- CC 失败且无法恢复后：内容列加删除线，看板状态改 `~~Fail~~`

> ⚠️ 划删除线的触发信号是「PR mergedAt 非空」，不是「CC 进程退出」。
> 验证命令：`gh pr view <PR_NUM> --json mergedAt --jq '.mergedAt'`

#### 2. 「当前运行」表格
格式：`| 指派目录 | Issue | Tier | 模块 | 内容 |`
- 指派时：新增一行
- **PR 已 squash-merged 后**（不是 CC 进程退出后！）：删除对应行
- CC 失败且确认放弃后：删除对应行

#### 3. 「指派建议」表格（只读，排程经理维护）
- 指派时优先参考此表，**不要修改此表**

### 何时更新
| 事件 | 必须更新的位置 |
|------|--------------|
| 指派新 Issue | 当前运行新增行 + 指派历史新增行 |
| PR squash-merged（**唯一的 Done 触发信号**） | 当前运行删行 + 指派历史状态改 ~~Done~~ |
| CC 失败且确认放弃（**唯一的 Fail 触发信号**） | 当前运行删行 + 指派历史状态改 ~~Fail~~ |
| 发现 PLAN.md 过时 | 对照 cc-check.sh 输出 + project 看板补齐所有缺失行 |

> ⚠️ "CC 进程退出" 不是事件触发器！CC 进程退出后 Issue 仍处于 In Progress
> 阶段（等 PR 创建/CI 跑/auto-merge）。只有 PR mergedAt 非空才允许标 Done。

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

### 判断标准（覆盖 CC 退出 → PR 创建 → CI → merged 全链路）

| 阶段 / 现象 | 处理（**全程不允许改 Done 状态**） |
|------|------|
| tmux 输出停滞，最后一条是编译错误 | 注入提示词：「检查编译错误并修复」|
| tmux 输出"完成"字样 但 .cc-lock 仍 RUNNING + 无 PR | 注入：「执行 gh pr create 提交分支」|
| tmux 会话已不存在，锁状态为 SAVED | 重新触发同 Issue 重入（run-cc.sh 同参数） |
| 🚨 tmux 输出超30分钟无新内容 | 先 `tmux kill-session` 再 `run-cc.sh` 同参数重启；重启失败再标 Fail |
| PR 已创建，等 CI | **不要做任何状态变更**，CI 会自动接管 |
| PR 已创建但 mergeable=CONFLICTING | 注入：「git fetch origin dev && git rebase origin/dev 解决冲突 后 git push --force-with-lease」|
| PR 已创建但 status checks failure | 看 PR 评论中 CI 失败详情，inject 让 CC 修复（CI 会自动注入，研发经理只是兜底）|
| PR 已 squash-merged 但 PLAN.md 「当前运行」未更新 | 此时才允许 PLAN.md 删行 + 指派历史划线（看板状态由 CI 自动改成 Done） |
| PR 创建超 2 小时未 merged 也未失败 | 检查 conflict-check / unit-test / build / e2e job 卡在哪段，针对性 inject |
| Issue 在 GitHub closed 但 PR 不存在或 mergedAt 为空 | **这是误关，必须立即 reopen** 并检查谁关的（正常流程 issue 只能由 PR squash-merge 自动关闭）|

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
grep -A 25 "指派建议" sprints/sprint-<N>/PLAN.md
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
