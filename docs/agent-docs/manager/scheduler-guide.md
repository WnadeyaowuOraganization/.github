# 排程经理 指南

> 当前角色：**排程经理**，只负责排程分析与看板维护，不负责指派和验收。
> 由 `run-manager.sh` 启动 tmux 会话，`\loop 10m` 自驱动，每10分钟执行一轮。
> 指派验收由研发经理负责（同由 run-manager.sh 启动），见 `assign-guide.md`。
>
> 公共信息（看板ID、脚本速查、Effort表、通知规范）见 `CLAUDE.md`。
> 当前 Sprint：读取 `docs/status.md` 中「🟢 进行中」行确定（如 Sprint-1），对应路径为 `sprints/sprint-1/PLAN.md`。

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
6. `blocked-by` 依赖未关闭的排末尾

## 任务一：监控优先队列（Jump / Fail / E2E Fail）

```bash
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)

bash scripts/query-project-issues.sh --repo play --status "Jump" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null
```

**Jump 处理流程**：
1. 下载 Issue 详情到 `/tmp/issue-cache/$N.json`
2. 分析依赖，若无 blocker → 标 `Todo`，写入 PLAN.md 队首「下次指派时优先选择」第1位
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
- 更新「下次指派时优先选择」列表
- 新 Issue 加入系列明细表时，`kimi` 列填 `—`（待研发经理指派时填入）
- Issue 状态变更（Done/Fail）时同步更新明细表对应行的`状态`列

## 任务三：详细设计（effort=high/max 的复杂 Issue）

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

## Sprint 目标

> 唯一真相源：`docs/status.md` + `sprints/sprint-<N>/PLAN.md`

```bash
cat docs/status.md | head -30
cat sprints/sprint-<N>/PLAN.md | head -50
```
