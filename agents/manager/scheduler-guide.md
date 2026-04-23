# 排程经理 指南

> 当前角色：**排程经理**，只负责排程分析与看板维护，不负责指派和验收。
> 由 `run-manager.sh` 启动 tmux 会话，`\loop 10m` 自驱动，每10分钟执行一轮。
> 指派验收由研发经理负责（同由 run-manager.sh 启动），见 `assign-guide.md`。
>
> 公共信息（看板ID、脚本速查、Effort表、通知规范）见 `CLAUDE.md`。
> 当前 Sprint：读取 `docs/status.md` 中「🟢 进行中」行确定（如 Sprint-1），对应路径为 `sprints/sprint-1/PLAN.md`。

## 沟通规范（强制，每轮巡检开始前检查）

**每轮巡检第一步**：检查tmux会话中是否有未回复的`【需回复】`消息，有则**立即回复后再执行巡检**。

- 收到`【需回复】`→ 必须回复确认/决策/反馈，不能忽略
- 收到`【阅即可】`→ 无需回复，继续工作
- 自己发消息 → 必须使用`【类型】-【回复标识】`格式（见根CLAUDE.md §团队内沟通机制）

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
6. **同一页面功能，后端 Issue 必须排在配对前端 Issue 之前** — 后端未 merged 前端只能 mock，造成集成风险
7. `blocked-by` 依赖未关闭的排末尾

## 任务一：监控优先队列（Jump / Fail / E2E Fail / 新 Done）

```bash
export GH_TOKEN=$(python3 scripts/gh-app-token.py 2>/dev/null)

bash scripts/query-project-issues.sh --repo play --status "Jump" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null
# 也查 Done 状态：被动发现 CI 自动改的 Done，同步 Sprint 明细表「状态」列
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null
```

**Jump 处理流程**：
1. 下载 Issue 详情到 `/tmp/issue-cache/$N.json`
2. 分析依赖，若无 blocker → 标 `Todo`，写入 PLAN.md 队首「指派建议」第1位
3. 发送通知

**Fail / E2E Fail 处理流程**：
1. 检查 Issue 是否 OPEN（CLOSED 的跳过）
2. OPEN → 分析失败原因（看标签/评论）→ 若依赖已就绪重新标 Todo，写入 PLAN.md

## 任务二：排程分析（Plan → Todo）

```bash
# 批量下载待分析 Issue
mkdir -p /tmp/issue-cache
for i in 1234 5678; do
  gh issue view $i --repo WnadeyaowuOraganization/wande-play \
    --json number,title,body,labels,state > /tmp/issue-cache/${i}.json
done

# 确认依赖已关闭
gh issue view <dep_issue> --repo WnadeyaowuOraganization/wande-play --json state -q '.state'

# 标 Todo
bash scripts/update-project-status.sh --repo play --issue <N> --status "Todo"
```

**决策清单**：先筛 Sprint 重点 → 分模块 → 排序（接口先于页面）→ 标注依赖 → 多模块并行

**记录**：维护 `sprints/sprint-<N>/PLAN.md`，每次排程后：
- 更新「指派建议」列表
- 新 Issue 加入系列明细表时，`指派目录` 列填 `—`（待研发经理指派时填入）
- Issue 状态变更（Done/Fail）时同步更新明细表对应行的`状态`列

## 任务三：维护指派建议表

> 位置：`sprints/sprint-<N>/PLAN.md` → `# 以下内容由排程经理每次排程后维护` → `## 指派建议（最近20个）`

### 触发时机
- 每轮巡检后，若建议表**无任何 Todo / In Progress 行**（全部 Done/Fail/Reject），必须重新生成建议（旧数据清空，重写20条）
- 发现 Jump / Fail / E2E Fail Issue 时，立即插入建议表**队首**

### 写 PLAN.md 的并发约束
> ⚠️ 研发经理也会写 PLAN.md（「当前运行」+「指派历史」表）。
> 改 PLAN.md 前必须 `git pull`，改完立即 `git add + commit + push`，避免相互覆盖。

### Master Issue 规则

> Master Issue（标题含 `[Master]`）是功能归类导航用的，不是可开发的 Issue。

**排除规则**：
- 指派建议表中**禁止出现 Master Issue**，只推其子Issue
- effort 设为 `—`（不分配CC，不消耗API额度）

**自动完成检测**（每轮巡检执行）：
1. 查找所有 OPEN 的 Master Issue（标题含 `[Master]`）
2. 从 body 中提取子 Issue 编号（`#NNNN` 格式）
3. 检查所有子 Issue 是否全部 CLOSED
4. 全部 CLOSED → 自动关闭 Master Issue + 标 Done

```bash
# Master Issue 自动完成检测脚本
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

### 优先级规则（从高到低）

| 优先级 | 条件 |
|--------|------|
| 🔴 最高 | 看板状态为 **Jump** 的 Issue（无论模块） |
| 🟠 高 | 看板状态为 **E2E Fail** 或 **Fail** 且仍 OPEN、依赖已就绪 |
| 🟡 中 | `priority/P0` Todo，依赖已 CLOSED |
| 🟢 普通 | `priority/P1` Todo，依赖已 CLOSED，按模块并行原则补足20条 |
| ⛔ 排除 | 标题含 `[Master]` 的导航 Issue — **禁止出现在建议表** |

### 建议表格式

```markdown
## 指派建议（最近20个）
| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #2363 | P0 | frontend | 项目中心Phase8 菜单+列表 | ✅ |
```

### 写入规则
- 每次重新建议时**清空旧内容，整体替换**，不追加
- Jump/Fail 插队时在现有表格**首行插入**，不清空其余行
- `启动` 列：无 blocker 填 ✅，有依赖填 ⏳ 并在内容列注明前置

## 任务四：详细设计（effort=high/max 的复杂 Issue）

触发条件：Issue 含 `type:refactor`、`size/L`，或判断需要 effort=high/max 时。

```bash
cat > docs/design/<功能名>-详细设计.md << 'EOF'
# <功能名> 详细设计
## 背景 / 数据模型 / API设计 / 关键流程 / 依赖关系
EOF
git add docs/design/ && git commit -m "docs(design): <功能名>详细设计" && git push origin main
```

## 防重复规则（同模块串行）

同一业务模块涉及新建 Entity/Mapper/Service 的 Issue，在 PLAN.md 中必须串行标注（前一个 CLOSED 后才标下一个 Todo）。

