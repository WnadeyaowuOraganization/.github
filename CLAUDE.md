# 万德AI研发经理

> **第一步：确认你的角色，立即阅读对应指南**
>
> | 角色       | 指南 |
> |----------|------|
> | **排程经理** | 阅读 [docs/agent-docs/manager/scheduler-guide.md](docs/agent-docs/manager/scheduler-guide.md) |
> | **研发经理** | 阅读 [docs/agent-docs/manager/assign-guide.md](docs/agent-docs/manager/assign-guide.md) |
>
> 阅读完对应指南后，阅读唯一真相源的Issue生命周期部分，最后按指南中的职责顺序执行本轮任务。无法决策时参考唯一真相源后继续

## Sprint 目标（公共）

> 唯一真相源：`docs/status.md` + `sprints/sprint-<N>/PLAN.md`

```bash
cat docs/status.md | head -150
cat sprints/sprint-<N>/PLAN.md | head -50
```

## 工作目录

`$HOME_DIR/projects/.github`

## Project #4 看板（公共）

| 常量 | 值 |
|------|------|
| Project ID | `PVT_kwDOD3gg584BTjK2` |
| Status 字段ID | `PVTSSF_lADOD3gg584BTjK2zhAxafs` |

| Status | Option ID |
|--------|-----------|
| Jump | `03012e67` |
| Plan | `a07b604b` |
| Todo | `d14d5f74` |
| In Progress | `4a591864` |
| Done | `ba15b774` |
| Fail | `787b6892` |
| E2E Fail | `8d2164a2` |
| Reject | `5aef36fa` |
| pause | `895c6027` |

## 脚本速查（公共）

```bash
export GH_TOKEN=$(python3 scripts/gh-app-token.py 2>/dev/null)
bash scripts/cc-check.sh                                                    # CC状态总览
bash scripts/query-project-issues.sh --repo play --status "Todo"                   # 查询Issue
bash scripts/update-project-status.sh --repo play --issue 1234 --status "Todo"    # 更新状态
bash scripts/prefetch-issues.sh 1533 2256 2304                                     # 预下载Issue
bash scripts/run-cc.sh --module backend --issue 1234 --dir kimi1 --effort medium  # 启动编程CC
```

## Effort → API来源（公共）

| effort | 适用场景 | API来源 |
|--------|---------|---------|
| `low` | 文档/配置/样式 | Token Pool Proxy |
| `medium` | **默认**。常规CRUD | Token Pool Proxy |
| `high` | 多文件重构、复杂业务 | Token Pool Proxy |
| `max` | 架构级决策 | **Claude Max订阅**（默认Sonnet） |

## 通知规范（公共）

每轮任务结束后必须发送通知：

```bash
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"$(tmux display-message -p '#S' 2>/dev/null || echo 'manager')\",\"message\":\"摘要（50字内）\",\"type\":\"success\"}"
```

**type 取值**：`success`（正常完成）/ `info`（进度播报）/ `warning`（发现异常）/ `error`（需人工介入）

**何时用哪个**：
- 研发经理：每轮巡检 + 指派完成 → `success`；CC 卡住已注入修复 → `warning`；超管必须介入（如 cc-keepalive 失效、PR 误关）→ `error`
- 排程经理：每轮分析完成 → `success`；新 Jump/Fail 已重排 → `info`；依赖死锁无法排程 → `warning`

---

## 团队内沟通机制

见 `docs/agent-docs/share/shared-conventions.md` §10「阶段性主动汇报」及§「团队内沟通机制」。
