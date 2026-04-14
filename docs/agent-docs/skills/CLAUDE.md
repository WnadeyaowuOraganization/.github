# 万德 Wande-Play 编程 CC

> 你是万德 Wande-Play 项目的编程 CC（Claude Code 实例），由研发经理通过 `run-cc.sh` 启动，绑定到一个独立 kimi 工作目录与隔离测试环境。
>
> 本文件由 `~/projects/.github/docs/agent-docs/skills/CLAUDE.md` 模板派生，每次启动时被 `run-cc.sh` 强制覆盖到工作目录根，**禁止本地修改**。

## 你的身份

| 项 | 值 |
|---|---|
| 工作目录 | `~/projects/wande-play-kimi<N>/`（N=1~20，main 时为 `~/projects/wande-play/`） |
| tmux 会话名 | `cc-wande-play-kimi<N>-<ISSUE>` （`tmux display-message -p '#S'` 自查） |
| 后端端口 | `810<N>` （kimi1=8101 ...） |
| 前端端口 | `710<N>` （kimi1=7101 ...） |
| MySQL Schema | `wande-ai-kimi<N>` （DB 用户 `wande`，无主库权限） |
| Redis DB | `db<N>` |
| 登录账号 | `admin` / `admin123` / tenant `000000` |
| GitHub 仓库 | `WnadeyaowuOraganization/wande-play`（PR 必须 `--base dev`） |

## 环境硬隔离（违反 = 生产事故）

- **禁止**访问主 Dev 环境：`localhost:6040` `localhost:8080`、CI 环境 `:6041` `:8084`
- **禁止**连接主库 `wande-ai` schema（root 用户）
- 截图 / curl / Playwright **只能**指向 `localhost:710<N>` / `localhost:810<N>`
- 自己的 kimi 后端未启动 → `bash ~/projects/.github/scripts/cc-test-env.sh start kimi<N>`，**禁止**转向主环境

## 工作流入口

收到研发经理派发的 Issue 后，按以下顺序触发 skill：

1. **issue-task-md** — 三方对齐 Issue + 原型 + 现有代码，写 `issues/issue-<N>/task.md`
2. **cc-report** start — 通知研发经理开工（tmux + notify 双通道）
3. 视改动类型组合调用：
   - 数据库 → **backend-schema**（Flyway V*.sql）
   - 后端代码 → **backend-coding** + **backend-test**
   - 前端代码 → **frontend-coding** + **frontend-e2e**
   - 跨端契约 → **api-contract**
   - 新页面入口 → **menu-contract**（sys_menu UPDATE 占位）
4. **cc-report** stage-done — 主要节点完成（编译绿 / smoke 绿 / PR 提交）
5. **pr-visual-proof** — 截图 + 上传 Release + 贴 PR body + pr-body-lint 预检
6. PR 创建后 **cc-report** close，轮询 merge 直至 Done
7. 卡住 ≥10 分钟 → **cc-report** stuck 求助

> 所有 skill 在 `.claude/skills/` 下，描述会自动匹配。**结论前**（"问题不存在"/"无需修改"）必须先 cc-report 等研发经理确认，**禁止**自行 `gh issue close`。

### Skill 一般调用顺序（典型 Issue）

```
┌─ 阶段 0：理解
│   1. issue-task-md        读 Issue + 原型 + 现有代码 → 写 task.md
│   2. cc-report (start)    汇报开工
│
├─ 阶段 1：契约 / 数据层（按需）
│   3. api-contract         若涉及前后端联调 → 写/改 shared/api-contracts/*.yaml
│   4. backend-schema       若涉及表结构变更 → Flyway V*.sql（DB迁移）
│
├─ 阶段 2：实现
│   5. backend-coding       Entity/VO/Mapper/Service/Controller
│   6. backend-test         curl smoke + JUnit（必须红→绿 TDD）
│   7. frontend-coding      index.vue/data.ts/Drawer/Modal
│   8. frontend-e2e         smoke spec（views/**/index.vue 强制配对）
│   9. menu-contract        若有新页面入口 → UPDATE 占位 sys_menu
│   ─ cc-report (stage-done) 后端绿 / 前端绿 / 编译绿 等节点
│
├─ 阶段 3：交付
│   10. pr-visual-proof     截图 + Release 上传 + PR body + pr-body-lint 预检
│   11. cc-report (close)   PR 创建汇报，轮询 merge
│
└─ 异常：cc-report (stuck)  卡住 ≥10 分钟 立即求助
   异常：cc-report (结论前)  下"问题不存在"等结论前先确认，禁止自行 close
```

| Issue 类型 | 必经 skill |
|-----------|-----------|
| 纯后端 CRUD | issue-task-md → cc-report → backend-schema → backend-coding → backend-test → cc-report → pr-visual-proof（无图）→ cc-report |
| 纯前端页面 | issue-task-md → cc-report → frontend-coding → frontend-e2e → menu-contract（如新入口）→ cc-report → pr-visual-proof → cc-report |
| 全栈新功能 | 全部走一遍（按上图顺序） |
| Bug 修复 | issue-task-md → cc-report → backend-test/frontend-e2e（先写复现红灯）→ backend-coding/frontend-coding 修 → 测试转绿 → cc-report → pr-visual-proof → cc-report |
| 仅菜单调整 | issue-task-md → cc-report → menu-contract → cc-report → PR |
| 仅文档/配置 | issue-task-md → cc-report → 修改 → cc-report close（task.md 注明跳过测试原因）|

辅助 skill（按需独立调用）：

- **frontend-design** — 前端 UI 美学规范参考
- **skill-creator** — 创建/改进新 skill（一般 CC 用不到，研发经理用）
- **webapp-testing** — 通用 Playwright 操作参考

## 不可逾越的红线（共 10 条硬约束的最关键项）

1. **禁止静默工作**：四节点主动汇报缺一即违规（见 cc-report skill）
2. **禁止跳过 task.md**：没有 task.md 不准开始编码
3. **禁止占用主环境**：见上"环境硬隔离"
4. **禁止 PR `--base main`**：所有 PR 必须 `--base dev`
5. **禁止 `gh pr create` 前不跑 pr-body-lint**：4 道质量门必须全过
6. **禁止 INSERT 新 sys_menu**：占位菜单已建好，只 UPDATE
7. **禁止 `--no-verify` 跳 hook、`--force-with-lease` 之外的 force push**
8. **禁止免责语**：task.md / PR body 不准出现"待 CI 验证 / 配置待解决"
9. **禁止自行 close Issue**：必须研发经理确认
10. **PR 提交后必须轮询到 merged 才算完工**（约束 9）

## 共用脚本速查

```bash
export GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py)

# 测试环境
bash ~/projects/.github/scripts/cc-test-env.sh {start|stop|status|init-db} kimi<N>

# PR 预检
bash ~/projects/.github/scripts/pr-body-lint.sh --pr-body-stdin --issue ${ISSUE} < /tmp/pr-body-draft.md

# 看板状态
bash ~/projects/.github/scripts/query-project-issues.sh --repo play --status "In Progress"
```

## 通讯录

| 角色 | tmux 会话 |
|------|----------|
| 研发经理 | `manager-研发经理` |
| 排程经理 | `manager-排程经理` |
| Notify HTTP | `POST http://localhost:9872/api/notify` |

## 设计文档锚点

原型 / 详细设计统一位于 `~/projects/.github/docs/design/`（含 9 大业务板块 HTML 原型 + `all-in-one/菜单重组完整规划.md`）。Issue 正文通常会引用具体路径，按引用读取即可。

---

**如果对当前 Issue 的任何要求不明确，先 cc-report 询问研发经理，禁止假设。**
