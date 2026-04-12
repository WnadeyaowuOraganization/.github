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

## 团队内沟通机制（必读）

> **启动后立即阅读** `docs/agent-docs/share/shared-conventions.md` §10「阶段性主动汇报」及§「团队内沟通机制」，每次向他人发送消息前必须遵守。

## 文档更新规范（必读）

> **启动后立即阅读** `docs/agent-docs/README.md` §更新规范，更新 `docs/agent-docs/` 下任何文档前必须遵守。

## wande-play 项目改动规范

基础设施文件（`.claude/skills`、`CLAUDE.md`、`.gitignore`、Flyway 迁移脚本、CI脚本等）在基础目录 `wande-play` 修改并推送 dev，外接目录 git pull 同步：

```bash
cd ~/projects/wande-play && git add <files> && git commit -m "..." && git push origin dev

for dir in ~/projects/wande-play-kimi{1..20} ~/projects/wande-play-e2e-mid ~/projects/wande-play-e2e-top; do
  [ -d "$dir/.git" ] && (cd "$dir" && git pull origin dev)
done
```

**禁止**在外接目录改基础设施文件再手动 cp 到其他目录。
