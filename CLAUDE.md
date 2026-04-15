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

## 编程CC测试能力（公共）

每个编程CC拥有独立的前后端环境（独立端口、独立数据库），可以：
- 启动后端服务并用 curl 验证 API
- 启动前端 dev server 并用 **Playwright** 连接自己独立环境的端口进行图形化测试
- 使用 `/screenshot` skill 截图验证页面渲染

评估编程CC的自测计划时，**不要否定其图形化测试能力**，应鼓励CC充分利用 Playwright + 截图进行前端功能验证。

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

## 巡检问题自动止血规则（研发经理）

> 每轮 loop 巡检发现的问题登记在 `docs/workflow/skill-update.md`，按以下阈值自动处置（**不等用户决策**）：

| 频次 | 动作 |
|------|------|
| 1 次 | 个案精准指令 + 登记 skill-update.md |
| 2-3 次 | 登记为"频繁"、观察中 |
| **≥4 次** | **立即**更新对应 skill/红线/模板 + 通知所有在运行 CC（tmux send-keys 推送新规则），无需等用户批准 |

**新增 skill 灰度发布规则**：

若需新建 skill（而非改已有 skill），必须：
1. 先只在**一个** kimi 目录启用该 skill（软链或单目录 cp）
2. 该 kimi 至少跑完 **5 个 Issue** 验证 skill 无误
3. 验证通过后才能全面开放（软链到 wande-play 基础目录，所有 kimi 自动同步）
4. 验证期间若 skill 引起卡点或误判，立即回滚单 kimi 的软链，不污染全池

**同步到在运行 CC 的方式**：
```bash
for dir in ~/projects/wande-play-kimi{1..20}; do
  [ -d "$dir/.git" ] && (cd "$dir" && git pull origin dev)
done
# 然后 tmux send-keys 到每个活跃 CC 通知新规则/新 skill 路径
```
