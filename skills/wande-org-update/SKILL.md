---
name: wande-org-update
description: 万德AI平台组织级操作系统（v11.0，2026-04-19）。包含LLM调用规范、Issue创建SOP、自动编程SOP、需求一站式交付、代码开发流、CI/CD流水线、Token体系、辅助脚本规范、E2E测试架构、模型透明度等组织级共享规范。
---

# 万德AI平台 — 组织级操作系统 v11.0

> 组织级共享SOP。个人定制请看 `wande-ai` 技能。
>
> **v11.0 核心变更（2026-04-12起）**：G7e停机→m7i.8xlarge接管编程（D78/D84）；DB改MySQL 8.0库名`wande-ai`（D79/D81）；vLLM下线全部走Token Pool Proxy（D81）；dev分支基于ruoyi-ai重建（D80）；Sprint体系重构为8个（D77）；双经理CC架构（D70）；CC prompt skill化（D85a）；后端先于前端派发（D89）。

---

## §1 LLM调用规范（D81 重大变更）

**所有LLM调用经Token Pool Proxy统一出口：`http://localhost:9855`（m7i节点）**

- Proxy内置路由：kimi K2.5优先 → glm-5备选 → xykjy兜底
- Anthropic格式兼容（上游转发kimi/glm/xykjy）
- 冷却策略：1302/429→5h；连续2次→7天；402→30天；401/403→30天
- 配置文件：`.github/scripts/model-switch/keys.json`（不入git），systemd服务`token-pool-proxy`

**Claude Code 环境变量**（所有CC/manager统一）：
```bash
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy
```

**effort=max的例外**：仅max走Claude Max订阅（Sonnet 4.6），其余全部走Proxy（D43）。

**~~G7e本地Qwen3.5-122B~~**：已下线（D84），原"用本地模型"SOP作废。如需本地推理能力需重建GPU节点。

**管理命令**：
```bash
sudo systemctl status token-pool-proxy
curl -s http://localhost:9855/status | python3 -m json.tool
sudo systemctl restart token-pool-proxy  # 修改keys.json后
```

---

## §2 需求→执行一站式交付

**核心原则：吴耀/伟平提出任何需求，Perplexity必须一次性交付到位。**

标准流程：
1. **分析需求** → 30秒内理解核心诉求
2. **推荐最优方案** → 不问"要不要省钱"，直接给最好的
3. **输出执行清单** → 标题/描述/验收标准/优先级(P0~P2)/依赖(blocked-by)/module scope标签/预估
4. **等一个"同意"** → 确认后
5. **一次性创建所有Issue** → 批量创建到 **wande-play** 仓库，标记ready
6. **研发经理CC自动接管** → 按Sprint优先级排程+派发编程CC

**禁止行为**：❌分批讨论 ❌问"你觉得怎样" ❌让用户等后续对话才创建Issue ❌推"省钱vs高端"让用户选 ❌前后端联动拆成两个Issue

---

## §3 Issue创建SOP

详细规范：`.github/docs/ISSUE_CREATION_SOP.md` / 标签：`.github/docs/WANDE_LABEL.md`

### 核心规则

1. **统一创建到 wande-play** 仓库（基础设施相关才去 `.github`；Grasshopper去`wande-gh-plugins`）
2. **Module scope标签（必选）** — 决定编程CC工作目录：

| 标签 | 工作目录 | 模式 |
|------|---------|------|
| `module:backend` | backend/ | 单Agent TDD |
| `module:frontend` | frontend/ | 单Agent TDD |
| `module:pipeline` | pipeline/ | 单Agent |
| `module:fullstack` | 根目录 | Agent Teams（3-Agent并行） |

3. **标签组合（至少4个）**：1个module scope + 1个priority/P0~P3 + 1个type:xxx + 1个status:ready
4. **业务模块（可选，biz:前缀）**：biz:crm / biz:bidding / biz:cockpit / biz:ptc / biz:intelligence-hub / biz:outreach / biz:data-pipeline 等
5. **跨仓库引用**：`WnadeyaowuOraganization/repo#number`；PR自动关闭：`Fixes #number`

### Issue拆分 ATOMIC 法则

Alone（独立） / Tiny（单文件≤150行） / Obvious（写清I/O+算法） / Mapped（import路径明确） / Indexed（标题带[K/N]） / Checked（含一行验证命令）

---

## §4 自动编程SOP

### 三层解耦架构

```
排程经理CC（tmux manager-排程经理，Haiku 4.5，cron 10min保活）
  → 监控Jump/Fail/E2E Fail → 排程分析 → 维护PLAN.md+指派建议表

研发经理CC（tmux manager-研发经理，Sonnet via Claude Max，cron 10min）
  → 读排程经理的指派建议 → run-cc.sh派发空闲CC → 巡检tmux capture-pane
  → 规则引擎筛needs_attention（silent_minutes/PR状态）→ 只对0~3个CC精细处理

编程CC×20（tmux cc-wande-play-kimiN-ISSUE，Proxy via Token Pool）
  → 拾取Issue → 根据module标签决定模式
  → TDD + 编译检查 → push feature → gh pr create --base dev
  → 轮询等待merged或新指令，不主动退出

CI/CD（GitHub Actions self-hosted runner）
  → pr-test.yml: PR触发 → CI环境(:6041/:8084) → 冲突检测 → 编译 → 部署 → Smoke → E2E → auto merge
  → build-deploy-dev.yml: merge到dev → Flyway自动迁移 → 后端/前端部署 → pipeline sync

Smoke探活（cron 30min，零AI）：e2e_smoke.sh → 失败自动创建Issue+E2E Fail
全量回归（cron 6h，AI）：e2e_top_tier.sh → 失败AI智能创建Issue
```

### 双经理CC架构（D70）

**研发经理已拆分**为排程经理+研发经理两个tmux会话，各自guide文件：
- `scheduler-guide.md` — 排程经理专属（Jump/Fail监控、依赖分析、维护PLAN.md和指派建议表）
- `assign-guide.md` — 研发经理专属（派发CC、巡检进度、注入提示词、验收报告）
- 统一启动：`run-manager.sh` 幂等启动两个会话，`\loop 10m`自驱动

### 编程CC TDD工作流

```
第一阶段：准备
  拾取ready Issue → run-cc.sh 预取Issue内容到 issue-source.md
  → 签出 feature 分支（从 dev 拉取）→ 创建 issues/issue-N/task.md
第二阶段：红灯-绿灯-重构
  Step 1 红灯：先写/补充单元测试 → 确认新测试失败
  Step 2 绿灯：编写业务代码让测试通过
  门控：✅全部测试PASS ✅编译PASS ✅新测试存在 → 才允许commit
  框架：backend=JUnit 5 / frontend=Vitest / pipeline=pytest
  （纯文档/配置/样式类自动豁免测试先行）
第三阶段：提交+PR
  commit → push feature → gh pr create --base dev（body含 Fixes #N）
  → 完善task.md → 回写完成报告到Issue评论
```

**D31关键**：编程CC不做deploy/Playwright，只做编译+单测。构建部署由build-deploy-dev.yml在merge到dev后自动完成。

### CC Skill体系（D85a 2026-04-14）

**CC prompt从"内联长prompt"升级为"skill化"**：
- 源路径：`~/projects/.github/docs/agent-docs/skills/` — 20+ skill（issue-task-md / backend-schema / backend-coding / backend-test / frontend-coding / frontend-e2e / api-contract / menu-contract / pr-visual-proof / pr-body-lint / cc-report / fix-ci-failure / flyway-validate / skill-creator 等）
- 分发：run-cc.sh启动时`ln -sfn`软链到`wande-play-kimiN/.claude/skills/`，源一改全kimi生效
- **CLAUDE.md红线 #13**：禁CC动`.claude/skills/`和根`CLAUDE.md`（运行时资产）
- 频繁问题跟踪：`docs/workflow/skill-update.md`，每轮loop≥2次→追加，累积后批量落地

### Effort动态控制（D24）

研发经理按Issue复杂度传effort参数，默认medium：

| effort | 适用场景 |
|--------|---------|
| `low` | 纯文档/配置/样式 |
| `medium` | 默认。常规CRUD、单模块 |
| `high` | 多文件重构、复杂逻辑、难调bug |
| `max` | 架构级决策、大跨模块重构（走Claude Max Sonnet 4.6） |

### CC启动方式（D45 命名参数）

```bash
# 启动编程CC（run-cc.sh 命名参数）
bash /home/ubuntu/projects/.github/scripts/run-cc.sh \
  --module <backend|frontend|pipeline|app|plugins> \
  --issue <N> \
  --dir <kimi1~kimi20> \
  [--effort <low|medium|high|max>] \
  [--prompt "自定义prompt"]

# 查看CC状态
bash /home/ubuntu/projects/.github/scripts/cc-check.sh
# （原 check-cc-status.sh，D70 改名）

# 保活兜底
# cc-keepalive.sh（原 post-cc-check.sh，D70 改名）由 cron 每5min 巡检
```

**Issue预取机制（D30）**：启动前自动预取到`issue-source.md`，避免kimi截断gh命令导致10分钟空转。

### CC锁完整生命周期（D55）

- **CC不主动退出**：PR创建后轮询等待合并或新指令
- **锁物理迁移（D88类似）**：`.cc-lock`从kimi目录移到`/home/ubuntu/cc_scheduler/lock/<dirname>.lock`，避免git污染
- **锁释放唯一出口**：`release-cc-lock.sh`（kill session + rm lock + checkout dev）
- **双触发路径**：(1) `cc-lock-manager.yml` workflow_run（部署成功释放/失败注入提示）；(2) PR merged 兜底

### 后端先于前端派发（D89 新规）

同一页面功能，**后端Issue必须先merged前端才可派发**，防止前端以mock数据交付。已同步到 scheduler-guide / assign-guide / frontend-coding SKILL。

### Project#4 看板 Status 流转

| 状态 | Option ID | 场景 |
|------|-----------|------|
| Plan | 7beef254 | 自动关联（issue-sync.yml） |
| Todo | 69f47110 | 排程经理排程后待执行 |
| In Progress | c1875ac0 | 编程CC正在处理 |
| Done | c8f40892 | PR merged（Done Guard强制校验 mergedAt，D73） |
| E2E Fail | efdab43b | **三层测试失败统一（D32）**，排程经理最优先 |
| Fail | 8a0d3051 | 执行失败 |

操作统一脚本：
```bash
bash /home/ubuntu/projects/.github/scripts/update-project-status.sh play <N> "<Status>"
# Done Guard: --status Done 强制校验PR mergedAt，失败exit 2
```

### status.md + feature-registry.md 驱动

- **`.github/docs/status.md`** — Sprint目标、重大决策(D1~)、看板状态、基础设施变更的**唯一权威**
- **`.github/docs/feature-registry.md`**（D38）— 42模块·~1200 Issue全景索引，与status.md互补（status记架构/技术决策，registry记功能级策略）

**Sprint管理规范（D29）**：表格化，sprints目录按阶段命名（sprint-1），研发经理直接查status.md表获取sprint名和模块子目录。

```
sprints/sprint-1/
├── 超管驾驶舱/PLAN.md
├── 销售记录体系/PLAN.md
└── D3参数化设计/PLAN.md
```

### Issue 完整生命周期

```
Issue创建 → issue-sync.yml → Project#4 → [Plan]
  ▼ 排程经理依赖分析
[Todo] ← E2E Fail / test-failed 插队首
  ▼ 研发经理 run-cc.sh --module --issue --dir --effort
[In Progress]
  ▼ 编程CC TDD + 编译 → push feature → PR
[PR阶段] pr-test.yml：冲突检测 → 编译 → 部署 → Smoke → E2E → auto merge
  ├─ 通过 → squash merge → [Done] → 触发build-deploy-dev（含Flyway自动迁移）
  └─ 失败 → 评论PR/Issue + test-failed + [E2E Fail] + inject-cc-prompt.sh注入活跃CC修复
  ▼
Smoke探活（cron 30min零AI）/ 全量回归（cron 6h AI） → 失败自动创建Issue+[E2E Fail]
```

### 关键约束

- SOP是Perplexity↔用户的概念，不要给Claude Code引入
- 项目文件修改都切ubuntu用户
- 编程CC push feature → 创建PR到dev
- **防重复规则（D26）**：同模块Issue串行分配；创建新类前必须查重 `grep -rn "class 类名" --include="*.java" backend/ | grep -v target`
- **Flyway自动迁移**（D80）：写 `backend/ruoyi-modules/wande-ai/src/main/resources/db/migration_{ruoyi_ai,wande_ai}/V<日期>_<序号>__<描述>.sql`，Spring启动自动跑，零手工同步
- **wande-ai-api模块已废弃**（D44）：万德业务功能全部在wande-ai子模块
- **schema.sql禁编辑**（D62）：所有表变更走Flyway

### 已废弃

run-cc-play.sh / round-executor.sh / cc_scheduler.py / run-cc-nohup.sh / post-task.sh / Project#2 / e2e_mid_tier.sh AI模式 / DISABLE_THINKING设置 / ci-env.sh（D45内联pr-test.yml）/ cc-error-parser.py（D49）/ get-gh-token.sh（D74合并进gh-app-token.py）/ cc_manager.sh（D70→run-manager.sh）

---

## §5 代码开发流

### Monorepo 架构（D80 dev分支重建后）

```
wande-play/（Monorepo）
├── CLAUDE.md                    # 公共层：Issue拾取、架构、Agent Teams、契约机制
├── backend/                     # Spring Boot + Flyway + MyBatis Plus
│   ├── ruoyi-modules/wande-ai/  # 万德业务模块（所有业务代码在此，D44）
│   │   └── src/main/resources/db/migration_{ruoyi_ai,wande_ai}/V*.sql
│   └── docs/（agent-docs引用）
├── frontend/                    # Vue 3 + Vben Admin + Vant4(H5)
│   └── views/{business,cockpit,h5}/  # V2菜单基线结构
├── e2e/                         # Playwright tests/{backend,front,pipeline,regression,fixtures}
├── pipeline/                    # Python shared/db.py + shared/llm_client.py
├── shared/api-contracts/        # 接口契约（契约先于实现，D28）
└── .github/workflows/
    ├── issue-sync.yml           # Issue创建自动关Project#4+Close时清理lock/branch
    ├── pr-test.yml              # PR触发：冲突→编译→部署→Smoke→E2E→auto merge
    ├── cc-lock-manager.yml      # workflow_run → 释放cc-lock / 失败注入
    ├── build-deploy-dev.yml     # merge到dev → 后端+前端+pipeline+Flyway自动迁移
    └── build-deploy.yml         # push到main → 生产部署
```

### 双环境架构（D78/D84 架构调整后）

```
         m7i.8xlarge (172.31.31.227 / 54.234.200.59)        Lightsail (47.131.77.9)
         ┌─────────────────────────────────┐                ┌─────────────────────┐
Dev环境   │ kimi1-20: backend 7100+N        │                │                     │
         │          frontend 8100+N        │                │                     │
         │ nginx反代 :8100+N→:7100+N       │                │                     │
         │ CI: :6041(backend) :8084(front) │                │                     │
         │ MySQL 8.0 :3306 (wande-ai库)    │                │ backend/front/...   │
         │ Redis :6380                     │                │ (Docker)            │
         │ Token Pool Proxy :9855          │                │                     │
         │ SearXNG :8888                   │                │                     │
         │ Claude Office :9872             │                │                     │
         │ nginx :8083/cla/ (reverse)      │                │                     │
         ├─────────────────────────────────┤                │                     │
生产CI/CD │ Self-hosted Runner              │ ──部署──→      │                     │
         └─────────────────────────────────┘                └─────────────────────┘
```

**~~G7e~~已停机**（D84），全部负载迁m7i。未来需GPU时按需起g5/g6e节点。

### Perplexity 在自动编程中的职责

1. 按§3创建Issue到 wande-play（4标签：module+priority+type+status）
2. 跨项目依赖用 `WnadeyaowuOraganization/repo#number`
3. 前后端联动用 `module:fullstack`，不拆分
4. Issue描述精准，让CC自主分析决策
5. CLAUDE.md/SOP/skill的修改 Perplexity 直接完成，不经Claude Code
6. **`.github`项目改动**：直接在m7i的 `/home/ubuntu/projects/.github/` 上改，ubuntu用户commit+push main

### 变更风险分级

- 🟢 AUTO_MERGE: docs/ tests/ e2e/ frontend/static/ reports/ .github/ *.md *.css
- 🔴 NEED_APPROVAL: Flyway migration/ auth/ security/ backend核心API/ docker/ .env/ config/prod 或 总变更>500行

---

## §6 测试基建与 CI/CD

### 测试金字塔

| 层级 | 触发 | 实现 | AI | 失败处理 |
|------|------|------|-----|---------|
| 单元测试 | 编程CC TDD门控 | JUnit 5 / Vitest / pytest | 无 | CC自行修复 |
| 编译检查 | 编程CC提交前 | mvn package / pnpm build | 无 | CC自行修复 |
| CI E2E | PR创建/更新 | pr-test.yml + e2e-result-handler.py | 无 | 评论+test-failed+E2E Fail |
| Smoke探活 | cron 30min | e2e_smoke.sh + handler | **无** | 自动创Issue+E2E Fail |
| 全量回归 | cron 6h | Claude Code + handler | 有 | AI创Issue+E2E Fail |

### E2E 目录分离

| 目录 | 用途 |
|------|------|
| `wande-play-ci` | pr-test.yml CI专用 |
| `wande-play-e2e-mid` | cron Smoke（脚本非CC） |
| `wande-play-e2e-top` | cron 全量回归（CC驱动） |

### e2e-result-handler.py 统一处理

- **有Issue模式** `--issue 456 --pr 123`：评论+改Label+改Project状态
- **无Issue模式**（不传--issue）：按失败路径判断module → 自动创建新Issue → 标签 → E2E Fail
- **构建失败兜底（D34）**：无Playwright报告时直接评论PR/Issue+test-failed+E2E Fail
- **实时日志拉取（D45）**：`gh api repos/.../actions/jobs/$ID/logs` 抓失败step ERROR行+tail 100

### 单元测试MySQL容器（D79/D81后）

容器名`wande-test-mysql`（原 wande-test-pg 废弃），端口与生产MySQL隔离。
- **基线**：`.test-baseline=338`（CI不允许下降）
- **per-kimi隔离**：`scripts/ensure-test-mysql.sh`每kimi独立DB

### CI/CD 流水线总览

| 流水线 | 触发 | 职责 |
|--------|------|------|
| 编程CC | run-cc.sh | TDD + 编译 + push feature + PR |
| pr-test.yml | PR创建/更新 | CI环境编译门禁+E2E+auto merge / 失败E2E Fail |
| cc-lock-manager.yml | workflow_run | 部署成功释放cc-lock / 失败inject-cc-prompt |
| build-deploy-dev.yml | dev push | 后端+前端+pipeline+**Flyway自动迁移** |
| build-deploy.yml | main push | 生产镜像+Registry+Lightsail部署 |
| issue-sync.yml | Issue opened/closed | 自动加Project#4+关闭时清理lock/branch |
| e2e_smoke.sh | cron 30min | Dev健康探活，零AI |
| e2e_top_tier.sh | cron 6h | 全量回归，AI驱动 |

---

## §7 辅助脚本规范

**统一存放**：`.github/scripts/`（m7i路径：`/home/ubuntu/projects/.github/scripts/`）

### 核心脚本

| 脚本 | 用途 |
|------|------|
| `run-cc.sh` | 统一CC启动（命名参数+Issue预取+内置pre-task） |
| `run-manager.sh` | 双经理启动（排程+研发，tmux幂等，Haiku/Sonnet） |
| `cc-check.sh` | CC状态检查（原check-cc-status.sh） |
| `cc-keepalive.sh` | cron 5min巡检保活（原post-cc-check.sh） |
| `inject-cc-prompt.sh` | 注入提示词到活跃CC（paste-buffer+sleep 0.5+Enter） |
| `release-cc-lock.sh` | 锁释放唯一出口 |
| `refresh-gh-token.sh` | GH App token刷新（cron 45min） |
| `update-project-status.sh` | Project Status更新（含Done Guard） |
| `query-project-issues.sh` | 查询Project Issues（module/priority列） |
| `e2e_smoke.sh` | 中层Smoke探活（cron 30min，零AI） |
| `e2e_top_tier.sh` | 顶层全量回归（cron 6h） |
| `e2e-result-handler.py` | E2E结果统一处理 |
| `m2-cc-prepare.sh` / `m2-cc-cleanup.sh` | Maven repo per-CC隔离（D82后仅必要时） |
| `gh-app-token.py` | GitHub App token生成（已合并get-gh-token.sh逻辑，D74） |
| `cycle-merge.sh` | 智能冲突分类+合并辅助 |
| `analyze-conflict-type.sh` | 冲突类型分类 |
| `backfill-project-issues.sh` | 回补未关联Project的Issue |

---

## §8 Token体系

### GitHub Token 三种身份

| 身份 | 类型 | 用途 |
|------|------|------|
| **GitHub App token** | wande-auto-code-agent[bot] | **主力**。git push + API，自动45min刷新（refresh-gh-token.sh，D74） |
| wandeyaowu PAT | User Token | e2e目录专用（审批+合并PR） |
| 伟平 PAT | User Token | 兜底（App token失败时） |

逻辑在 `gh-app-token.py`：
- e2e目录 → wandeyaowu PAT
- 默认 → GitHub App token（GraphQL>100 或 -1重试）
- 兜底 → 伟平PAT

### Claude Code 环境

统一 `.bashrc`：
```bash
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy
```

`settings.json` 只保留：
```json
{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}
```

Thinking模式由`--effort`参数动态控制（D24）。

---

## §9 模型透明度

每次回复末尾附：

```
---
🧠 模型: Perplexity默认 | 子代理: 无 | 工具: 无
```

字段：
- 模型: `Perplexity默认`
- 子代理: `无` / `Claude Opus` / `Sonnet` / `Gemini` / `GPT-5` 等
- 工具: 高消耗时标注 `search_web×N` / `browser_task` / `wide_research(N个)`

~~G7e字段废弃~~（D84停机后）。

---

## 附录：v10→v11 变更摘要（2026-04-12~04-19）

| 变更项 | v10.0 (04-04) | v11.0 (04-19) |
|--------|-------------|---------------|
| 开发节点 | G7e（3.211.167.122） | **m7i.8xlarge（172.31.31.227），G7e停机（D84）** |
| DB | PostgreSQL（5433） | **MySQL 8.0（:3306 库`wande-ai`，D79/D81）** |
| Schema管理 | SCHEMA_ORDER.txt bash | **Flyway自动迁移（D80）** |
| LLM调用 | vLLM 122B + Proxy混合 | **统一Token Pool Proxy :9855，122B下线（D81/D84）** |
| 经理CC | 单研发经理 | **排程+研发双经理（D70 run-manager.sh）** |
| CC prompt | 内联长prompt | **skill化20+ skill（D85a软链分发）** |
| Sprint体系 | 5+Backlog | **8个Sprint（D77 能用→能赚钱→能决策...）** |
| 脚本改名 | check-cc-status.sh/post-cc-check.sh | **cc-check.sh/cc-keepalive.sh（D70）** |
| 锁管理 | kimi目录内 | **`/home/ubuntu/cc_scheduler/lock/`（D88类）+ release-cc-lock.sh唯一出口（D55）** |
| 派发约束 | 无 | **后端先于前端merged才可派发（D89）** |
| ci-env.sh | 独立脚本 | **内联pr-test.yml（D45）** |
| wande-ai-api | 独立模块 | **已废弃，合并入wande-ai（D44）** |
| Claude Office | 自定义Vue组件 | **systemd+nginx+SSE实时通知+iframe嵌入（D45/D58/D82）** |
