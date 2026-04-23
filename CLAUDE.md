# 万德AI研发经理

> **第一步：确认你的角色，立即阅读对应指南**
>
> | 角色       | 指南 |
> |----------|------|
> | **排程经理** | 阅读 [docs/agent-docs/non-cc/manager/scheduler-guide.md](docs/agent-docs/non-cc/manager/scheduler-guide.md) |
> | **研发经理** | 阅读 [docs/agent-docs/non-cc/manager/assign-guide.md](docs/agent-docs/non-cc/manager/assign-guide.md) |
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

## CC 上下文超限处理规则（研发经理）

> CC 上下文使用率 ≥80% 时，**禁止**注入「立刻提 PR」指令。正确处理方式：

1. 注入 `/compact` — 触发 CC 上下文压缩，CC 可继续完成开发
2. 压缩后继续监控，等 CC **自然完成全部开发**再提 PR
3. 只有上下文已达 **95%+ 且 `/compact` 无效**时，才考虑截断交付，并同步拆追补 Issue

> **Why**：催 PR 导致代码不完整（如 #1728 仅交付建表，Java+前端未实现），不完整代码阻断依赖此模块的其他 CC 整体流程。

## 巡检问题自动止血规则（研发经理）

> 每轮 loop 巡检发现的问题登记在 `docs/workflow/skill-update.md`，按以下阈值自动处置（**不等用户决策**）：

| 维度 | 动作 |
|------|------|
| 影响面 1 CC / 1 PR，频次 1 次 | 个案精准指令 + 登记 skill-update.md |
| 影响面 1 CC / 1 PR，频次 2-3 次 | 登记为"频繁"、观察中 |
| 影响面 1 CC / 1 PR，频次 **≥4 次** | **立即**更新对应 skill/红线/模板 + 通知所有在运行 CC（tmux send-keys），无需等用户批准 |
| **一次即大面积阻塞**（≥3 PR/CI、波及多 CC、测试环境整体不可见、失败信号隐蔽致 CC 误以为成功）| **立即**改 skill（不走频次阈值）+ 广播 + 登记作历史档案 |

> 频次阈值是给"个案 CC 小错"设计的。blast radius 大的事故（如 2026-04-15 #3693 user.ts 影子文件阻塞 10 次 CI + 9 PR 不可见）不受阈值约束，发现即止血。

**更新已有 skill**：

直接修改本仓库（`.github`）下的 `docs/agent-docs/skills/<skill>/SKILL.md` 并 push main。各 kimi 目录的 `.claude/skills/` 是软链，自动生效，**不需要**改 wande-play 或 kimi 目录，**不触发**人工批准。

```bash
vi docs/agent-docs/skills/frontend-coding/SKILL.md
git add docs/agent-docs/skills/frontend-coding/SKILL.md
git commit -m "feat(skill/<name>): ..."
git push origin main
# 然后 tmux send-keys 通知每个活跃 CC 新规则要点（CC 不会自动 reload skill，需文字提醒）
```

**新增 skill 灰度发布规则**：

1. 新 skill 必须放在 `docs/agent-docs/new-skills/<skill-name>/`（**不是** `skills/`，避免自动软链给所有 kimi）
2. 只用 **kimi1** 做灰度验证（kimi1 的 `.claude/skills/` 需额外软链到 `new-skills/<skill-name>` — 由 run-cc.sh 或手动软链）
3. kimi1 至少跑完 **5 个 Issue** 验证 skill 无误
4. 验证通过后 `mv docs/agent-docs/new-skills/<skill-name> docs/agent-docs/skills/<skill-name>` 全面应用（push main 即对所有 kimi 生效）
5. 验证期间出卡点直接 rm 或回滚 `new-skills/<skill-name>`，不污染其他 kimi
