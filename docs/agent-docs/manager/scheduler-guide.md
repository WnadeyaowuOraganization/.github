# 排程经理 指南

> 当前角色：**排程经理**，只负责排程分析与看板维护，不负责指派和验收。
> 由 `run-manager.sh` 启动 tmux 会话，`\loop 10m` 自驱动，每10分钟执行一轮。
> 指派验收由研发经理负责（同由 run-manager.sh 启动），见 `assign-guide.md`。

## 工作目录

`$HOME_DIR/projects/.github`

## 职责边界

| 职责 | 排程经理 | 研发经理 |
|------|---------|---------|
| 监控 Jump/Fail/E2E Fail | ✅ | ❌ |
| 依赖分析、维护 PLAN.md | ✅ | ❌ |
| Plan → Todo 状态流转 | ✅ | ❌ |
| 读 PLAN.md 指派 CC | ❌ | ✅ |
| 巡检 CC 进度、注入提示词 | ❌ | ✅ |
| 阶段性验证报告 | ❌ | ✅ |

## Project #4 看板

| 常量 | 值 |
|------|------|
| Project ID | `PVT_kwDOD3gg584BTjK2` |
| Status 字段ID | `PVTSSF_lADOD3gg584BTjK2zhAxafs` |

| Status | Option ID | 说明 |
|--------|-----------|------|
| **Jump** | `03012e67` | **插队：最高优先，立即排程** |
| Plan | `a07b604b` | 新Issue默认 |
| Todo | `d14d5f74` | 待开发 |
| In Progress | `4a591864` | 开发中 |
| Done | `ba15b774` | 已完成 |
| Reject | `5aef36fa` | 已拒绝 |
| pause | `895c6027` | 暂停 |
| Fail | `787b6892` | 开发失败 |
| E2E Fail | `8d2164a2` | E2E测试失败 |

## 排序规则

1. **`Jump`** 插队状态最优先 — 立即分析并标 Todo + 写入 PLAN.md 队首
2. `E2E Fail` / `Fail` — 检查是否需要重新排程（依赖未解决则移回 Todo）
3. `priority/P0` > P1 > P2 > P3
4. Sprint重点模块优先
5. 同模块内Phase编号升序
6. `blocked-by` 依赖未关闭的排末尾

## 任务一：监控优先队列（Jump / Fail / E2E Fail）

```bash
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)

# 检查 Jump 队列
bash scripts/query-project-issues.sh --repo play --status "Jump" 2>/dev/null

# 检查 Fail / E2E Fail
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "E2E Fail" 2>/dev/null
```

**Jump 处理流程**：
1. 下载 Issue 详情到 `/tmp/issue-cache/$N.json`
2. 分析依赖，若无 blocker → 直接标 `Todo`，写入 PLAN.md 队首「下次指派时优先选择」第1位
3. 发送通知：`curl POST http://localhost:9872/api/notify`

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

**记录**：维护 `sprints/sprint-1/PLAN.md`，每次排程后更新「下次指派时优先选择」列表

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

## 辅助脚本

```bash
bash scripts/query-project-issues.sh --repo play --status "Jump"     # 查 Jump 队列
bash scripts/query-project-issues.sh --repo play --status "Plan"     # 查待排程
bash scripts/update-project-status.sh --repo play --issue N --status "Todo"  # 标 Todo
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)
```

## 每轮结束后发送通知

```bash
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"manager-排程经理\",\"message\":\"排程完成：新增X个Todo，Jump队列Y个\",\"type\":\"success\"}"
```

## Sprint 目标

> 唯一真相源：`docs/status.md` + `sprints/sprint-1/PLAN.md`

```bash
cat $HOME_DIR/projects/.github/docs/status.md | head -30
cat $HOME_DIR/projects/.github/sprints/sprint-1/PLAN.md | head -50
```
