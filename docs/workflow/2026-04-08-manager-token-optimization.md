# 研发经理 Token 优化方案

> **创建时间**:2026-04-08
> **状态**:W1+W2+W3 已落地 / W4~W7 待落地
> **目标**:研发经理日 token 从 ~10M 降到 ~1M(降 89%),同时维持/提升判断质量
> **责任范围**:`scripts/post-task.sh`、`/opt/claude-office/api/server.py`、`docs/agent-docs/manager/assign-guide.md`、`scripts/run-cc.sh`、`pr-test.yml`、`cc-keepalive.sh`、新 cron workflow

## 一、背景

### 现状的浪费点

研发经理由 `run-manager.sh` 启动 tmux 会话,内部 `\loop 10m` 每 10 分钟执行一轮巡检。原 assign-guide.md 任务二写法是:

```bash
bash scripts/cc-check.sh                              # 全场扫
tmux capture-pane -t cc-wande-play-kimi1-1234 -p -S -200   # × N 个活跃 CC
gh pr list ...                                         # 挨个查 PR
```

按 14 个活跃 CC,每个 200 行 capture ≈ 20KB,**单轮输入 ~70k tokens**。每天 6 轮/小时 × 24 小时 ≈ **10M tokens/天**全部花在原始 tmux 噪声上。

更糟的是,这些 capture 大部分内容是 Read/Bash 工具调用回显,真正有判断价值的就是"最后停在什么 tool"、"最近一条 error"、"是否卡住"——研发经理在做**应该被规则引擎做的事**。

### 改造目标

把研发经理从"全场轮询 + 兜底判断"瘦身成:
- **只处理 needs_attention=true 的少数 case**(规则前置过滤)
- **写归纳报告时读 CC 自报 summary**(预消化数据)
- **CC 自监控其 PR/CI 状态**(不依赖研发经理轮询)

## 二、整体架构

```
┌──────────────────────── 现状 ────────────────────────┐
│ 研发经理（每 10 分钟）                                │
│   ├─ cc-check.sh                    全场扫            │
│   ├─ tmux capture-pane × 14         70k tokens 噪声  │
│   ├─ gh pr list × N                 挨个查 PR        │
│   ├─ LLM 判断哪些卡住                重复劳动        │
│   └─ 写 PLAN.md / 注入 / 报告                        │
└─────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────── 目标 ────────────────────────┐
│ 事件 / 后台规则引擎层（无 LLM）                        │
│   ├─ pr-test.yml inject              CI 失败 → CC 自修(已存在) │
│   ├─ cc-keepalive.sh                 SAVED 重试(已存在)        │
│   ├─ server.py needs_attention       规则判定哪些需要介入【W2】│
│   ├─ cc-self-check cron              webhook 丢包兜底【W7】    │
│   └─ post-task.sh summary 生成        CC push 后写 summary     │
│                                       【W1 纯规则版,W5 LLM版】 │
│                                                      │
│ 研发经理（每 10 分钟）                                │
│   ├─ curl /api/status                只看 attention 列表【W3】│
│   ├─ 对这几个 tmux capture + 注入    精准修复                  │
│   ├─ 写 PLAN.md                                              │
│   └─ 写验收报告时读 summary.json     不再读 raw gh 数据【W6】 │
└─────────────────────────────────────────────────────┘
```

## 三、模块拆解

### 模块 1:lock 状态机扩展(W4)

**新状态定义**(向下兼容,只加不删):

```
PLAN          ─ 排程阶段(已存在)
RUNNING       ─ 编码中(已存在)
SAVED         ─ 代码已落盘待 commit(已存在)
NO_CHANGES    ─ 空跑无修改(已存在)
COMMITTING    ─ 新增 - git add + commit 中
PUSHING       ─ 新增 - git push 中
PR_CREATED    ─ 新增 - PR 已建,等 CI 首次跑
PR_VERIFYING  ─ 新增 - CI 已开跑,等结果
PR_FAILING    ─ 新增 - CI 已失败,等 inject 修复
MERGED        ─ 新增 - PR 已 squash-merge(短暂态)
FAIL          ─ 已存在
```

**关键契约**:`state ∈ {PR_CREATED, PR_VERIFYING}` 时 CC 进入**自监控模式**,server 规则引擎 needs_attention 跳过它(除非 silent_minutes 超阈值兜底)。

**改动点**:

| 文件 | 改动 |
|---|---|
| `scripts/run-cc.sh` | 启动时写 `state=RUNNING`(已有) |
| `scripts/post-task.sh` | Step 3 前 `state=COMMITTING`;Step 4 前 `state=PUSHING`;Step 4 后 `state=PR_CREATED` |
| `.github/workflows/pr-test.yml` | `on: workflow_run` started → 写 `state=PR_VERIFYING`;failure → 写 `state=PR_FAILING` 并 inject 修复 prompt |
| `scripts/cc-lock-manager.yml` 处理流程 | merge 后 `state=MERGED` 然后 rm lock |

**实现注意**:
- 写 lock 必须原子(临时文件 + mv),避免 server.py 读到半截
- 加 `inject_count` 字段累计 CI 失败修复次数,超过 3 次升级到研发经理(由 needs_attention 规则消费)

### 模块 2:server.py 扩展(W2 已落地 + W4 联动)

**已落地的字段**(W2):
```json
{
  "silent_minutes": 12.3,           // 距 last_activity 的分钟数
  "pr_summary": {"number": 3499, "merged": false},  // 来自 30s 缓存的 pr_index
  "lock_state": "",                 // W4 落地后才有值
  "needs_attention": false,
  "attention_reason": null
}
```

**当前规则引擎逻辑**(`_compute_attention`,server.py:583-645):

```python
# 1. 兜底:silent > 120min 一律升级
# 2. 已有 PR 未 merged + silent < 30min → 自监控,不打扰
# 3. 无 PR + silent > 30min → 编码卡住
# 4. PR 已 merged → 等 cc-lock-manager 清理,无需介入
# 5. lock_state == FAIL → Fail 终态
```

**W4 落地后扩展**:

```python
# PR_VERIFYING 状态 + silent < 120min → 不打扰(交给 webhook/cron)
# PR_FAILING 状态 + inject_count >= 3 → 升级
# RUNNING 状态 + silent > 30 → 卡住(已有规则)
# PR_VERIFYING 状态 + silent > 120 → CI hung(已有 silent 兜底覆盖)
```

**W4/W5 后还要扩展的字段**:

```json
{
  "last_error": "mvn compile error: BarService.java:45 ...",  // 从 JSONL 提取
  "pr_summary": {                                              // 加几个字段
    "number": 3499,
    "merged": false,
    "mergeable": "CONFLICTING",     // 新增
    "checks_status": "FAILING"      // 新增
  }
}
```

`pr_summary.mergeable` / `checks_status` 通过扩展 `_refresh_project_stats` 的 GraphQL query 一次拉,**共享同一个 30s 缓存,不增加 GitHub API 调用**。

**`last_error` 提取逻辑**:扫 JSONL 尾部 100 行,找最近一条 `tool_result.is_error == true` 的前 200 字符。

### 模块 3:post-task.sh summary 生成(W1 纯规则版已落地 / W5 Haiku 升级版待做)

**W1 已落地**(纯规则版,schema_version=1):

```json
{
  "issue": 1920,
  "branch": "feature-Issue-1920",
  "module": "pipeline",
  "kimi_dir": "kimi1",
  "model": "claude-sonnet-4-6",
  "effort": "medium",
  "pr_number": 3499,
  "duration_minutes": 243,
  "commits": 7,
  "commit_titles": [...],
  "files_changed": 12,
  "lines_added": 340,
  "lines_deleted": 50,
  "diff_stat": "12 files changed, 340 insertions(+), 87 deletions(-)",
  "schema_version": 1,
  "fallback": true,
  "generated_at": "2026-04-08T22:15:00Z"
}
```

**存放位置(2026-04-08 修订)**:

| 路径 | 触发条件 | git 状态 |
|---|---|---|
| **主路径** `$(dirname $TASK_FILE)/post-task-summary.json`(项目 issue 目录,跟 task.md 同级) | TASK_FILE 存在(绝大多数情况) | committed 到 feature 分支,跟 task.md 一起进 PR + dev |
| **Fallback** `/home/ubuntu/projects/.github/post-task-summaries/issue-<N>.json` | TASK_FILE 缺失(极少数 issue 没写 task.md) | 仅在本地 .github 仓,不进 wande-play |

主路径写完后会自动 `git add + commit -m "[skip ci]" + push`,跟 task.md 走一样的生命周期,避免 cc-lock-manager 重置 kimi 目录时被 `git clean` 清掉。`[skip ci]` 标签避免触发额外的 pr-test.yml 运行。

研发经理读取时(W6 任务四改造):

```bash
# 主路径(扫所有 kimi dir)
find /home/ubuntu/projects/wande-play* -path '*/issues/issue-*/post-task-summary.json' -newermt "@$LAST_TS" 2>/dev/null

# Fallback(集中目录)
find /home/ubuntu/projects/.github/post-task-summaries -name 'issue-*.json' -newermt "@$LAST_TS" 2>/dev/null

# 合起来送给 jq
{ first_glob; second_glob; } | xargs cat | jq -s '.'
```

**W5 升级**(schema_version=2,加 LLM 软字段):

在 W1 基础上,异步(`&` + `nohup`)调一次 `claude --model claude-haiku-4-5-20251001 --print` 摘要 task.md + commit messages + diff stat,生成 4 个软字段:

```json
{
  ...W1 所有字段...,
  "completed": ["Browser Agent 统一封装", "browse_and_extract 接口"],
  "blockers_hit": ["mvn compile: BarService Bean 名冲突", "schema.sql 重复定义"],
  "fix_summary": "重命名 BarService、补单测、修 vite alias",
  "lessons": "module 内重名 Bean 应在 prefetch 阶段静态扫描",
  "self_assessment": "ok",
  "schema_version": 2,
  "fallback": false
}
```

**LLM 调用细节**:
- 模型:Haiku 4.5(走 Token Pool Proxy)
- 输入:~5k tokens(task.md tail + commit messages + diff stat + schema 模板)
- 输出:~500 tokens
- 成本:~¥0.005/PR × 50 PR/天 = **¥0.25/天**
- 异步:不阻塞 PR 创建
- 失败兜底:写入失败时保留 W1 的纯规则版本

**self_assessment 含义**:
- `ok` — 完整解决,无 workaround
- `partial` — 解决了一部分,还有遗留
- `workaround` — 用绕过/兼容写法解决,根因没修
- `risky` — 修了但不确定边界条件
- `unknown` — LLM 判断不出

**Schema 版本演进**:

| schema_version | 内容 | 落地批次 |
|---|---|---|
| 1 | 纯规则字段(git/lock/diff stat) | W1 |
| 2 | 1 + LLM 软字段(completed/blockers/lessons/assessment) | W5 |
| 3+ | 预留(可能加跨 issue 关联、PR review summary 等) | TBD |

### 模块 4:assign-guide.md 任务二(W3 已落地)+ 任务四(W6 待做)

**W3 已落地**:任务二改写为 attention-only,见 assign-guide.md。

**W6 待做**:任务四(验证报告)从"raw gh 倒推"改为"读 summary 归纳"。

具体改动:

```bash
# Step 1: 拉自上次报告以来的所有 summary
LAST_REPORT_TS=$(grep '## 批次验收' docs/workflow/新harness验证报告.md \
  | tail -1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}')
LAST_TS_EPOCH=$(date -d "$LAST_REPORT_TS" +%s 2>/dev/null || echo 0)

find /home/ubuntu/projects/.github/post-task-summaries -name 'issue-*.json' \
  -newermt "@$LAST_TS_EPOCH" \
  | xargs cat | jq -s '.' > /tmp/latest-summaries.json

# Step 2: 直接归纳(不读 raw gh)
jq '
  group_by(.module)
  | map({
      module: .[0].module,
      count: length,
      avg_duration: ([.[].duration_min] | add / length),
      total_lines_changed: ([.[] | (.lines_added + .lines_deleted)] | add),
      assessments: ([.[].self_assessment] | group_by(.) | map({(.[0]): length}) | add)
    })
' /tmp/latest-summaries.json

# Step 3: 提炼 lessons(去重 + 频次)
jq -r '.[] | .lessons // empty' /tmp/latest-summaries.json | sort | uniq -c | sort -rn
```

研发经理拿到的就是预消化的结构化 JSON 数组,直接写报告即可。

### 模块 5:cc-self-check workflow(W7 兜底)

防 GitHub webhook 丢包,确保 PR_VERIFYING 状态超 2h 的 CC 一定有自检触发。

**新建** `.github/workflows/cc-self-check.yml`:

```yaml
name: CC Self-Check
on:
  schedule:
    - cron: '*/30 * * * *'
  workflow_dispatch:

jobs:
  check:
    runs-on: self-hosted
    steps:
      - name: 找 PR_VERIFYING 超时的 CC,inject 自检 prompt
        run: |
          curl -s http://localhost:9872/api/status \
            | jq -r '.agents[] | select(.lock_state == "PR_VERIFYING" and .silent_minutes > 120) | "\(.issue_number)\t\(.id)"' \
            | while IFS=$'\t' read issue sid; do
                bash scripts/inject-cc-prompt.sh $issue "你的 PR 已超 2h 未变化,请 gh pr checks 自检 + gh pr view 看 conflict + 必要时 rebase 或修复"
              done
```

**触发频率**:每 30 分钟一次,只 inject 真正卡住的 CC。

**风险**:✓ 低 — 是兜底层,失败也只是退化到原研发经理介入

## 四、落地批次与依赖

```
W0(已完成) Done Guard + 排程经理切 Haiku
   │
   ├──────────┐
   ▼          ▼
W1(已完成)   W2(已完成)
post-task    server.py
summary      needs_attention
纯规则版     规则引擎
   │          │
   │          ▼
   │       W3(已完成)
   │       assign-guide
   │       任务二改造
   │       attention-only
   │
   ▼
W4(待做) lock 状态机扩展
   │
   ▼
W7(待做) cc-self-check cron 兜底

W1 ─→ W5(待做) Haiku 摘要升级
              │
              ▼
           W6(待做) assign-guide
                    任务四改造
                    读 summary
```

## 五、Token 节省预估

| 项目 | 现状/天 | W3 后/天 | W6 后/天 |
|---|---|---|---|
| 巡检 tmux capture | 10M | 1.5M | 1.5M |
| gh pr/issue 重复查询 | 1.5M | 0.5M | 0.5M |
| 验收报告(任务四) | 0.5M | 0.5M | 0.1M |
| **研发经理总计** | **12M** | **2.5M** | **2.1M** |
| post-task Haiku(W5) | 0 | 0 | 0.1M |
| **全场总计** | **12M** | **2.5M** | **2.2M** |

**降幅**:
- W3 后:研发经理 **降 79%**
- W6 后:全场 **降 82%**

## 六、风险与回滚

| 风险 | 严重度 | 缓解 | 回滚 |
|---|---|---|---|
| W2 规则误判漏诊 | 中 | silent_minutes > 120 兜底 + W7 cron 兜底 | 改 `_compute_attention` 阈值或回退到旧 prompt |
| W1 summary 写入失败 | 低 | python 异常捕获,失败 warn 不阻塞 PR | 删 Step 5 段 |
| W4 lock state 写入失败 | 中 | 原子写(临时文件 + mv);失败时旧消费者按 RUNNING 处理 | git revert hook 改动 |
| W5 Haiku schema 漂移 | 低 | json.loads 校验,失败 fall back W1 | schema_version 字段标记,下游兼容 |
| W7 cron 误判扫到不该 inject 的 | 低 | 只对 silent > 120 + 明确 PR_VERIFYING 状态 | 删 workflow |

## 七、验证方式

### W1 验证

```bash
# 触发一次 post-task(等下一个 PR 创建完成)
ls -lt /home/ubuntu/projects/.github/post-task-summaries/ | head
cat /home/ubuntu/projects/.github/post-task-summaries/issue-XXXX.json | jq .
```

### W2 / W3 验证

```bash
# 看 attention 列表分布(应该是少数)
curl -s http://localhost:9872/api/status \
  | jq '[.agents[] | {needs_attention, attention_reason}] | group_by(.needs_attention) | map({key: .[0].needs_attention, count: length})'

# 看研发经理 prompt 实际拉取的内容(对比改造前的 70k tokens)
# 通过 office 看板 manager 卡片观察 token 流量
```

### W4 验证

```bash
# 各 lock state 分布(2026-04-09 lock 路径迁移到 cc_scheduler/lock/)
for f in /home/ubuntu/cc_scheduler/lock/wande-play*.lock; do
  grep '^state=' "$f"
done | sort | uniq -c
```

### W5 验证

```bash
# 升级到 schema_version=2 后
jq 'select(.schema_version == 2) | {issue, lessons, blockers_hit, self_assessment}' \
  /home/ubuntu/projects/.github/post-task-summaries/issue-*.json
```

## 八、监控与告警

落地后建议在 `office.js` 加一个 manager 卡片,展示:
- 当前 needs_attention 数量(理想 0~3)
- 24h 内研发经理实际触发巡检次数
- summary.json 文件计数(累计 + 24h 增量)

供超管快速判断改造是否健康。

## 九、关联文件

- `scripts/post-task.sh` — W1
- `scripts/run-cc.sh` — W4
- `scripts/cc-keepalive.sh` — W4
- `scripts/inject-cc-prompt.sh` — W3 / W7 调用方
- `/opt/claude-office/api/server.py` — W2
- `docs/agent-docs/manager/assign-guide.md` — W3 / W6
- `.github/workflows/pr-test.yml` — W4
- `.github/workflows/cc-self-check.yml` — W7(待新建)
- `post-task-summaries/issue-<N>.json` — W1 / W5 输出
