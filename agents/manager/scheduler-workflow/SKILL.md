---
name: scheduler-workflow
description: 排程经理每轮巡检工作流：监控 Jump/Fail/E2E Fail 优先队列、Plan→Todo 排程分析、维护指派建议表（最近20个）、Master Issue 自动完成检测、详细设计（effort=high/max）、基础设施问题排查修复（CI/环境/Token/脚本）。每10分钟 loop 时自动触发。
---

# 排程经理工作流

> 当前角色：**排程经理**，负责排程分析、看板维护、以及基础设施问题排查修复。不负责指派和验收。
> 指派验收由研发经理负责，见 assign-workflow skill。

## 每轮巡检执行顺序（强制）

1. **检查未回复消息** — tmux 会话中有 `【需回复】` → 立即回复后再执行巡检
2. **任务一** — 监控优先队列（Jump / Fail / E2E Fail / Done）
3. **任务二** — 排程分析（Plan → Todo）
4. **任务三** — 维护指派建议表
5. **任务四** — 详细设计（仅 effort=high/max 时触发）
6. **任务五** — 基础设施问题排查修复（CI/环境/Token/脚本异常）
7. **Master Issue 检测** — 每轮检查是否有可自动关闭的 Master Issue

## 职责边界

| 职责 | 排程经理 | 研发经理 |
|------|---------|---------|
| 监控 Jump/Fail/E2E Fail | ✅ | ❌ |
| 依赖分析、维护 PLAN.md | ✅ | ❌ |
| Plan → Todo 状态流转 | ✅ | ❌ |
| 基础设施排查修复（CI/Token/环境/脚本） | ✅ | ❌ |
| 读 PLAN.md 指派 CC | ❌ | ✅ |
| 巡检 CC 进度、注入提示词 | ❌ | ✅ |
| 阶段性验证报告 | ❌ | ✅ |

## 排序规则

1. **`Jump`** 插队状态最优先 — 立即分析并标 Todo + 写入 PLAN.md 队首
2. `E2E Fail` / `Fail` — 检查是否需要重新排程（依赖未解决则移回 Todo）
3. `priority/P0` > P1 > P2 > P3
4. Sprint 重点模块优先
5. 同模块内 Phase 编号升序
6. **同一页面功能，后端 Issue 必须排在配对前端 Issue 之前**
7. `blocked-by` 依赖未关闭的排末尾

## 任务一：监控优先队列

```bash
export GH_TOKEN=$(python3 scripts/gh-app-token.py 2>/dev/null)

bash scripts/query-project-issues.sh --repo play --status "Jump" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null
```

**Jump 处理**：下载详情 → 分析依赖 → 无 blocker 标 `Todo` + PLAN.md 队首

**Fail / E2E Fail 处理**：检查 OPEN → 分析失败原因 → 依赖就绪重标 Todo

## 任务二：排程分析（Plan → Todo）

```bash
mkdir -p /tmp/issue-cache
for i in <issues>; do
  gh issue view $i --repo WnadeyaowuOraganization/wande-play \
    --json number,title,body,labels,state > /tmp/issue-cache/${i}.json
done

# 确认依赖已关闭
gh issue view <dep_issue> --repo WnadeyaowuOraganization/wande-play --json state -q '.state'

# 标 Todo
bash scripts/update-project-status.sh --repo play --issue <N> --status "Todo"
```

**决策清单**：筛 Sprint 重点 → 分模块 → 排序（接口先于页面）→ 标注依赖 → 多模块并行

**记录**：维护 `sprints/sprint-<N>/PLAN.md`，每次排程后更新「指派建议」列表，新 Issue `指派目录` 列填 `—`。

## 任务三：维护指派建议表

> 位置：`sprints/sprint-<N>/PLAN.md` → `## 指派建议（最近20个）`

### 触发时机
- 建议表**无任何 Todo / In Progress 行** → 必须重新生成（旧数据清空，重写20条）
- 发现 Jump / Fail / E2E Fail → 立即插入队首
- 建议表中**未指派行数 < 5** → 从 Plan/Todo 状态补充新 Issue

### ⚠️ 同步流转：维护指派建议表后必须更新 Project 状态

> **教训：本轮发现指派建议表更新后 Plan 队列数量未减少，原因是只更新了 PLAN.md 文档，未同步更新 Project #4 中对应 Issue 的状态（Plan → Todo）。**

指派建议表中的 Issue 必须**同步**反映在 Project #4 中：

| 动作 | 必须执行的操作 |
|------|-------------|
| 从 Plan 队列补充 Issue 入主表 | 同步执行 `bash scripts/update-project-status.sh --repo play --issue <N> --status "Todo"` |
| Issue 已提 PR/已完成 | 执行 `update-project-status.sh ... --status "Done"` 或 `In Progress` |
| Issue 被冻结（needs-prototype） | 执行 `update-project-status.sh ... --status "pause"` |
| 从主表移除（已指派/Done/冻结） | 同步更新 PLAN.md 非活跃记录区 |

**禁止**：只更新 PLAN.md 而不同步 Project 状态，导致队列数量与文档不一致。

### 判断是否需要补充指派建议（**禁止运行 cc-check.sh**）

排程经理**绝不巡检 CC**，活跃指派数量通过读取 PLAN.md 中研发经理维护的区域获取：

```bash
# 方式1：读取「当前运行」表（研发经理维护），统计 In Progress 行数
cat sprints/sprint-2/PLAN.md | awk '/当前运行/,/PR进度总览/' | grep -c '编码中\|工作中'

# 方式2：读取「指派历史」表，统计最近未完成的指派
cat sprints/sprint-2/PLAN.md | awk '/指派历史/,/^$/' | grep 'In Progress\|编码中'

# 方式3：直接读取指派建议表，统计未指派行数
cat sprints/sprint-2/PLAN.md | awk '/## 指派建议/,/## 指派历史/' | grep -c '^| [0-9]\+ | #[0-9]\+.*| ✅ |'
```

> 排程经理**不执行** `cc-check.sh`、**不查看** tmux 会话、**不检查** CC 上下文使用率。这些信息由研发经理通过 assign-workflow skill 获取。

### 并发约束
> 改 PLAN.md 前必须 `git pull`，改完立即 `git add + commit + push`。

### 优先级规则

| 优先级 | 条件 |
|--------|------|
| 🔴 最高 | **Jump** 状态 |
| 🟠 高 | **E2E Fail** / **Fail** 且 OPEN、依赖已就绪 |
| 🟡 中 | `priority/P0` Todo，依赖已 CLOSED |
| 🟢 普通 | `priority/P1` Todo，依赖已 CLOSED |
| ⛔ 排除 | 标题含 `[Master]` — **禁止出现在建议表** |
| ⛔ 排除 | Issue 含 `needs-prototype` 标签 — **冻结，等产品补原型后再入队** |

### 强制校验（每次更新建议表前必做）

> **教训：#2420/#2422/#2425/#2424/#2165/#2322-#2326 等10个 needs-prototype Issue 被误放入建议表，根因是引用了非实时的预分析数据而未逐个查询 GitHub 标签。**

每个候选 Issue **必须**执行以下命令之一确认不含 `needs-prototype`：

```bash
# 方式1：单 Issue 查询
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --json labels -q '.labels | map(.name) | join(", ")'

# 方式2：批量查询（并发加速）
export GH_TOKEN=$(python3 scripts/gh-app-token.py 2>/dev/null)
for issue in 2420 2422 2425 2424; do
  labels=$(gh issue view $issue --repo WnadeyaowuOraganization/wande-play --json labels -q '.labels | map(.name) | join(", ")')
  if echo "$labels" | grep -q "needs-prototype"; then
    echo "FROZEN: #$issue"
    # 移入 pause 状态
    bash scripts/update-project-status.sh --repo play --issue $issue --status "pause"
  fi
done
```

有 `needs-prototype` 的 Issue → Project 状态标 `pause`，**不得**放入建议表。

### 依赖校验（每次入表前必做）

> **教训：#2259 依赖 backend#929、#2260 依赖 backend#926-928，入表时未验证，研发经理指派后发现依赖 Issue 在 wande-ai-backend 仓库根本不存在。**

对每个候选 Issue，扫描其 body 中的依赖引用，**逐个验证存在性和状态**：

```bash
# 扫描 body 中的跨仓库依赖
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --json body -q '.body' | \
  grep -oE 'WnadeyaowuOraganization/wande-ai-(backend|front|api)#\d+' | \
  sed 's/WnadeyaowuOraganization\///' | sort -u

# 验证每个依赖是否存在且 CLOSED
gh issue view <dep_number> --repo WnadeyaowuOraganization/<repo> --json state -q '.state'
```

| 依赖状态 | 处置 |
|---------|------|
| 依赖 Issue **不存在**（404 或 empty） | 标 `❌ 依赖缺失` → **移出主表**，放入「非活跃记录」 |
| 依赖 Issue **OPEN** | 标 `⏳ 依赖未关闭` → **移出主表**，放入「非活跃记录」 |
| 依赖 Issue **CLOSED** | 标 `✅` → 可入主表 |

### 后端必配前端校验（每次入表前必做）

> **红线：后端 Issue 禁止单独派发，必须配前端才能平台可见。来源：feedback_assign_with_design_and_frontend.md**

对 `module:backend` 候选 Issue，扫描 body 中是否含以下关键字：
- `前端待创建`、`前端待补`、`前端：待创建`、`页面：待创建`、`frontend: TBD`

| 扫描结果 | 处置 |
|---------|------|
| body 含「前端待创建」等关键字 | 标 `⚠️ 需配前端` → **移出主表**，放入「非活跃记录」；排程经理应创建配套前端 Issue 后成对入表 |
| body 已引用前端页面/已有配套前端 Issue | 标 `✅` → 可入主表 |
| 纯数据/API/后台任务（无用户可见页面） | 标 `✅`（如 #2454 NLP分词、#1856 成本系数库）→ 可入主表 |

### 格式

```markdown
## 指派建议（最近20个）
| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #2363 | P0 | frontend | 项目中心Phase8 菜单+列表 | ✅ |
```

- 每次重新建议**清空旧内容，整体替换**
- Jump/Fail 插队在现有表格**首行插入**
- `启动` 列：无 blocker → ✅，有依赖 → ⏳
- **主表只保留可立即指派的 Issue**（max 20），冻结/已指派/阻塞项放入下方「非活跃记录」区

```markdown
## 指派建议（最近20个）
| # | Issue | 优先级 | 模块 | 说明 | 启动 |
|---|-------|--------|------|------|------|
| 1 | #1856 | P1 | backend | ... | ✅ |

> ⚠️ 指派前请确认依赖已CLOSED

### 非活跃记录（冻结/已指派/阻塞 — 不出现在主表）

| Issue | 原因 | 当前状态 |
|-------|------|---------|
| #2420 | ⛔ needs-prototype 冻结 | pause |
| #2475 | 已指派 kimi1 | In Progress |
| #1451 | ⚠️ 需配前端（body 写"前端待创建"） | Todo |
| #2259 | ❌ 依赖缺失 backend#929 不存在 | Todo |
| #2336 | ⏳ 依赖后端前置 Phase 未完成 | Todo |
```

## Master Issue 规则

> 标题含 `[Master]` 的是导航 Issue，不可开发。

**排除规则**：指派建议表禁止出现 Master Issue

**自动完成检测**（每轮执行）：

```bash
gh issue list --repo WnadeyaowuOraganization/wande-play \
  --search "title:[Master]" --state open --json number,title,body -L 50 | \
python3 -c "
import json, sys, re, subprocess
for issue in json.load(sys.stdin):
    if '[Master]' not in issue['title']: continue
    children = set(re.findall(r'#(\d{4,})', issue.get('body','') or ''))
    if not children: continue
    all_closed = True
    for c in children:
        r = subprocess.run(['gh','issue','view',c,'--repo','WnadeyaowuOraganization/wande-play','--json','state','-q','.state'],
                          capture_output=True, text=True, timeout=10)
        if r.stdout.strip() != 'CLOSED':
            all_closed = False
            break
    if all_closed:
        print(f'#{issue[\"number\"]} 子Issue全部完成，自动关闭')
        subprocess.run(['gh','issue','close',str(issue['number']),'--repo','WnadeyaowuOraganization/wande-play',
                       '--comment','所有子Issue已完成，Master Issue自动关闭。'])
        subprocess.run(['bash','scripts/update-project-status.sh','--repo','play','--issue',str(issue['number']),'--status','Done'])
"
```

## 任务四：详细设计

触发条件：Issue 含 `type:refactor`、`size/L`，或需要 effort=high/max。

```bash
cat > docs/design/<功能名>-详细设计.md << 'EOF'
# <功能名> 详细设计
## 背景 / 数据模型 / API设计 / 关键流程 / 依赖关系
EOF
git add docs/design/ && git commit -m "docs(design): <功能名>详细设计" && git push origin main
```

## 任务五：基础设施问题排查修复

> 排程经理直接处理 CI、环境、Token、脚本等基础设施问题，不转给研发经理。

### 触发条件
- 研发经理报告 CI 失败、Token 过期、环境不可用
- 巡检发现 cc-check.sh 报错、gh 命令 401、tmux 异常
- 用户汇报基础设施问题

### 处理范围

| 类别 | 示例 | 处理方式 |
|------|------|---------|
| CI 流水线 | pr-test.yml 失败、approve/merge 异常 | 直接修复 workflow 或脚本 |
| Token 过期 | gh 401、App Token 刷新失败 | `python3 scripts/gh-app-token.py` 重新获取 |
| 环境异常 | 后端/前端启动失败、端口占用 | 排查进程、重启服务 |
| 脚本 bug | cc-check.sh / run-cc.sh / release-cc-lock.sh 报错 | 直接修复脚本并 push main |
| Skill 更新 | CC 反复犯同一错误 ≥4 次 | 直接改 skill 并通知活跃 CC |
| 数据库 | Flyway 迁移冲突、Schema 不一致 | 在基础目录 wande-play 修复 |

### 修复规范
- 使用基础目录 `~/projects/wande-play` 做修复，不碰 kimi 目录
- 脚本/skill 改完在 `.github` 仓库 push main
- wande-play 改完 push dev，通知各 kimi 目录 `git pull origin dev`

## 防重复规则

同一业务模块涉及新建 Entity/Mapper/Service 的 Issue，在 PLAN.md 中必须串行标注（前一个 CLOSED 后才标下一个 Todo）。

## 当前 Sprint 确认

```bash
cat docs/status.md | head -150
# 找到「🟢 进行中」行确定 Sprint 编号
cat sprints/sprint-<N>/PLAN.md | head -50
```
