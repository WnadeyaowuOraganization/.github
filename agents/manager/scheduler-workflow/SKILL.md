---
name: scheduler-workflow
description: 排程经理每轮巡检工作流：监控 Jump/Fail/E2E Fail 优先队列、Plan→Todo 排程分析、维护指派建议表（最近20个）、Master Issue 自动完成检测、详细设计（effort=high/max）。每10分钟 loop 时自动触发。
---

# 排程经理工作流

> 当前角色：**排程经理**，只负责排程分析与看板维护，不负责指派和验收。
> 指派验收由研发经理负责，见 assign-workflow skill。

## 每轮巡检执行顺序（强制）

1. **检查未回复消息** — tmux 会话中有 `【需回复】` → 立即回复后再执行巡检
2. **任务一** — 监控优先队列（Jump / Fail / E2E Fail / Done）
3. **任务二** — 排程分析（Plan → Todo）
4. **任务三** — 维护指派建议表
5. **任务四** — 详细设计（仅 effort=high/max 时触发）
6. **Master Issue 检测** — 每轮检查是否有可自动关闭的 Master Issue

## 职责边界

| 职责 | 排程经理 | 研发经理 |
|------|---------|---------|
| 监控 Jump/Fail/E2E Fail | ✅ | ❌ |
| 依赖分析、维护 PLAN.md | ✅ | ❌ |
| Plan → Todo 状态流转 | ✅ | ❌ |
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

## 防重复规则

同一业务模块涉及新建 Entity/Mapper/Service 的 Issue，在 PLAN.md 中必须串行标注（前一个 CLOSED 后才标下一个 Todo）。

## 当前 Sprint 确认

```bash
cat docs/status.md | head -150
# 找到「🟢 进行中」行确定 Sprint 编号
cat sprints/sprint-<N>/PLAN.md | head -50
```
