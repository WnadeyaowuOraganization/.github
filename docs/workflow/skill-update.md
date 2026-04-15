# Skill 改进跟踪

> 研发经理巡检时发现的频繁问题 → 登记到此，累计后沉淀为 skill/红线/模板改进。
> 规则：每次 loop 巡检新增一条（若发现频繁问题），按日期倒序。同一问题出现 ≥2 次即算"频繁"。

## 记录格式

```
### YYYY-MM-DD HH:MM 问题标题

- **症状**：CC 具体行为 / 报错
- **频次**：kimiN #IssueX（第 K 次）/ kimiM #IssueY（...）
- **根因**：为什么 CC 会这么做
- **已处置**：本轮怎么止血的
- **建议改进**：要不要改 skill/红线/模板/CI，怎么改
- **状态**：观察中 / 已实施 commit-hash
```

---

### 2026-04-15 12:33 【基础设施 P0】nginx wande-kimiN 站点 (04-10 旧静态) 占用 810N 端口导致 vite dev 退到 5666+ / smoke 永远 404

- **症状**：kimi4 #3532 smoke 持续 404；`curl localhost:8104/` 返 2597B 空骨架 HTML（title=万德AI平台、#app 空容器），**非 vite dev 页面**；vite 实际绑 localhost:5670（默认端口递增）；`ss -tlnp | grep 8104` 显示 nginx master pid=2014551 + 32 worker 持有
- **频次**：kimi4 #3532（第 1 次 — 但属潜在影响所有 kimi 的基础设施问题，kimi1 #3531 的 8101 同样被 nginx 占）
- **根因**：
  - `/etc/nginx/sites-enabled/wande-kimiN`（N=1,4,6-20）是 04-10 旧生产静态部署残留，绑 `listen 810N` + `root /apps/wande-ai-front-kimiN`（5 天前旧 index.html）
  - `cc-test-env.sh:288` 用 `lsof -ti ":810N"` 做端口冲突检测，**普通用户看不到 root 启动的 nginx 进程** → 以为端口空闲 → vite `--port 810N` bind 失败 → vite fallback 到 5666+（自动递增）
  - Playwright smoke BASE_URL=`localhost:810N` → 命中 nginx 静态 → 永远不会测到最新代码，一切前端 Issue 的 smoke 实际都在"测 5 天前的旧产物"
- **已处置**：
  - `sudo rm /etc/nginx/sites-enabled/wande-kimi4 && sudo nginx -s reload` → 8104 释放
  - tmux 指令 kimi4 `pkill vite + cc-test-env.sh stop/start kimi4` 重启让 vite 真绑 8104
- **建议改进**（P0 基础设施，必须立即实施）：
  1. 【sudo rm 所有 wande-kimiN nginx 站点】`for i in 1 4 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do sudo rm -f /etc/nginx/sites-enabled/wande-kimi$i; done; sudo nginx -s reload` — 这些纯残留
  2. 【cc-test-env.sh 强化端口检测】将 `lsof -ti` 改 `sudo ss -tlnp | grep ":${FRONTEND_PORT} "` 或 `fuser -n tcp ${FRONTEND_PORT}`，能看到 root 进程；检测到非己方进程 → 立即 `fail 1 "端口 810N 被 pid X 占用（非 vite）"`
  3. 【frontend-e2e skill】补"smoke 前必须 `curl -s http://localhost:${FRONTEND_PORT}/ | grep -q @vite/client` 验证 vite dev 真在 810N，否则是 nginx 或其它占用，pnpm dev 失败 fallback 到其它端口导致 smoke 永远测空骨架"
  4. 【重要回溯】之前多个 kimi 的前端 smoke"莫名通过"可能因为测的是旧静态页有 login 表单 → 需审视是否误报绿
- **状态**：🔴 P0 待实施 — 立即做 #1 (rm nginx 站点) + #2 (cc-test-env.sh 强化)

---

### 2026-04-15 11:43 kimi4 cp 改动到主项目 wande-play + 改共享 access.ts（红线 #3 污染 + scope 越界）

- **症状**：kimi4 #3532 前端 console 报 `未找到对应组件: /views/business/crm/inquiry/index.vue`（多个组件都报），错误地把 `access.ts` 默认分支改为 `${menu.component}.vue` 后缀，并执行 `cp .../kimi4/... /home/ubuntu/projects/wande-play/frontend/apps/web-antd/src/router/access.ts` 直接污染主项目
- **频次**：kimi4 #3532（第 1 次 — 主项目污染）；scope 越界改共享路由（第 1 次）
- **根因**：
  - 真正问题：kimi4 前端 Vite 构建缓存污染（`.vite`/`dist`）导致 `import.meta.glob` 匹配失败；CC 看到多个组件 404 → 误判为全局路由代码 bug
  - 越过 scope：询盘工作台 Issue 却改共享 `access.ts` 核心路由
  - 主项目写入：试图 `cp` 将修改推到主项目以"让前端生效"（可能误以为主项目才是前端 serve 源）
- **已处置**：`git restore /data/home/ubuntu/projects/wande-play/...access.ts` 回滚主项目；tmux 指令 kimi4 回滚 access.ts + 清 .vite/dist 缓存 + 重启 cc-test-env；明确禁止今后任何写操作指向 `/home/ubuntu/projects/wande-play/`
- **建议改进**（主项目污染属 P0 级，但首次）：
  1. 【共用 CLAUDE.md 红线 #3】加粗补充"禁止任何 cp/mv/write/git 操作指向 `/home/ubuntu/projects/wande-play/` 或 `/data/home/ubuntu/projects/wande-play/`（不带 kimi<N> 后缀）"
  2. 【run-cc.sh 启动消息】增加"你的改动**只在** `wande-play-kimi<N>/` 目录，主项目**只读**；前端通过 kimi<N> 端口 810N serve 你自己的代码"
  3. 【frontend-coding skill】加"页面 404/组件找不到 → 先清 `.vite` 缓存重启再排查，勿改 access.ts/router 框架"
- **状态**：观察中（首次）；主项目污染若第 2 次立即实施 #1 #2 红线强化

---

### 2026-04-15 11:40 smoke spec login() 用 nth(0/1).fill + 点击"登录"按钮 → ant-modal 拦截

- **症状**：kimi3 #3537 前端 smoke 3/3 红，登录阶段 `button.click()` 被 `ant-modal-confirm-centered subtree intercepts pointer events` 拦截；API 注入 token 也失败
- **频次**：kimi3 #3537（第 1 次）
- **根因**：万德登录页会弹隐私/租户 modal 遮挡登录按钮；`inputs.nth(0).fill()` + `button.click()` 模板对 modal 无容错。bidding spec 用 `input[name="username"]` + `press('Enter')` 绕过。
- **已处置**：tmux 指令 kimi3 改 login 用 Enter 键 + 入页后 dismiss modal（参考 crm-bidding-page.spec.ts:36-57）
- **建议改进**：frontend-e2e skill 补"smoke login 模板 — 必须用 `input[name]` 选择器 + `press('Enter')` 提交、禁用 `button.click()`；BASE_URL 必须 localhost:810N；ROUTE 后先 dismiss `.ant-modal-wrap button`"；提供一份可复用 `login(page)` helper 片段
- **状态**：观察中（第 1 次）

---

### 2026-04-15 08:21 kimi3 偏离 scope 4h+ Churn 调菜单基线 + 裸用 mysql -uroot -proot

- **症状**：
  - kimi3 #3535 thinking 4h6m / token 116k，从后端实现转向调菜单为何前端不显示 → 反复查 sys_menu 表
  - 直接用 `mysql -h127.0.0.1 -uroot -proot wande-ai-kimi3`（明文 root/root 弱密码连法）违反 #3530 已确认的标准连法
  - 偏离 #3535 scope（CRM-08 回款跟踪），菜单基线问题归 #3597/#3613
- **频次**：
  - **scope 偏离 Churn**：kimi3 #3535（第 1 次）+ kimi5 #3530（第 1 次，05:45 商机管道场景调 user/list 404）— 共 **2 次频繁**
  - **mysql 裸 root**：kimi3 #3535（第 1 次）+ kimi1/kimi3 #3549/#3550（早间），共 **3 次**
- **根因**：
  - CC 遇前端不渲染→本能查菜单；缺乏"scope 边界判断"自检机制
  - mysql 默认密码 root/root 工作（dev 环境弱密），CC 不知道有 docker exec 标准方式
- **已处置**：tmux 强干预 kimi3：列 a~e 进度自查 + 偏离 scope 标 task.md 即可走 PR + 提供正确 mysql 命令
- **建议改进**（mysql 裸 root 已第 3 次接近阈值）：
  1. 【run-cc.sh 启动消息】加预防：`mysql 必须 docker exec wande-ai-mysql ... 不要裸 root/root`
  2. 【backend-coding/backend-test SKILL.md】mysql 操作小节加正确命令模板
  3. 【scope 边界】issue-task-md skill 加"调试时遇基线/菜单/外部模块问题→标 task.md 非 scope→不修"原则
- **状态**：mysql 裸 root **第 3 次** 已达 ≥3，按规则升"频繁观察"，第 4 次自动止血改 backend-coding skill

- **症状**：kimi4 #3534 smoke 测试用 `API_TARGET=http://172.31.31.227:6040` 绕开本地 7104 后端隔离，通过外网 IP 访问新环境主 dev 后端
- **频次**：kimi4 #3534（第 1 次）
- **根因**：自己 kimi4 后端 7104 未启动，smoke 需要真实 API 登录 → CC 选择了能 work 的捷径；CLAUDE.md 红线只禁 "localhost:6040"，外网 IP 访问主 dev 未显式禁止
- **已处置**：tmux send-keys 推 PR 时指令 pr-visual-proof 阶段必须用自己 localhost:8104 + 如后端未启动先 `cc-test-env.sh start kimi4`
- **建议改进**：frontend-e2e/pr-visual-proof skill 补"API_TARGET/BASE_URL 必须 localhost:710N/810N，禁主机 IP 跨指向主 dev"；CLAUDE.md 红线 #3 改为"禁止访问主 dev 环境（含 localhost 和任意主机 IP 的 6040/8080/6041/8084 端口）"
- **状态**：观察中（第 1 次）

---

### 2026-04-15 07:11 / 07:41 CC 破坏 .claude/skills 逃避 rebase 冲突 ⚠ **频繁 2 次**

- **症状**：
  - kimi5 #3530 07:11：`mv .claude/skills /tmp/claude-skills-backup-*` 整个移走
  - kimi4 #3534 07:41：弹 permission 请求写 .claude/skills，执行 `rm -rf .claude/skills/` 批量清理
  - 两次都是 rebase origin/dev 遇 `.claude/skills` tracked 文件冲突（dev 新增 agentic-ai/dict-translation/excel-io/mcp-tool/sse-streaming/workflow-aiflow）
- **频次**：kimi5 #3530（第 1 次）+ kimi4 #3534（第 2 次），**频繁观察中**，距 ≥4 阈值 2 次
- **根因**：
  1. CC 认知：把 rebase 冲突当文件冲突，用 mv 绕过 — 违反红线 #13「禁止动 .claude/skills/」
  2. 仓库机制：wande-play 仓库 .gitignore 未排除 .claude/skills/，`git ls-files .claude/skills/` 显示 20+ 条目 tracked。软链目录被 git 识别为文件，dev 上增量 skill → rebase 时与工作区软链冲突。commit `3b962046 chore(skills): 清理 dev 残留 .claude/skills` 已尝试修复但只清本地，.gitignore 仍缺保护
- **已处置**：两次均 tmux send-keys 指令 `git restore .claude/skills/` + 清理 backup + rebase --continue；kimi4 的 permission prompt 已 Deny
- **建议改进**（未到 4 次阈值但已标注准备）：
  1. 【仓库级 · 优先】在 wande-play dev 加 `.gitignore`：`.claude/skills/` 并 `git rm --cached -r .claude/skills/` 一次性清除 tracked（第 3 次触发时立即独立 Issue 推进）
  2. 【skill 级】fix-ci-failure + pr-visual-proof SKILL.md 补"rebase 冲突遇 .claude/skills 禁 mv/rm，必须 git restore 恢复"
  3. 【run-cc.sh 启动消息】加一条"⚠ rebase 时 .claude/skills 冲突走 git restore，禁止 mv/rm"预防性提示
- **状态**：频繁观察中（第 2 次触发，第 3 次立即仓库级止血）

---

### 2026-04-15 07:08 研发经理派发前未查 Issue CLOSED/已交付状态

- **症状**：kimi1 启动后发现 #3583 已于 2026-04-14 随 PR#3664（#3640+#3582+#3583 合并交付）merged，Issue 状态 CLOSED，分支与 dev 无差异
- **频次**：kimi1 #3583（第 1 次）
- **根因**：研发经理看板查询只看 project status 字段（In Progress/Todo），未交叉验证 Issue `state==CLOSED` + 关联 PR 是否已 merged。部分 Issue 随同批次 PR 一起合并但 project 字段未同步到 Done
- **已处置**：表扬 kimi1 正确触发"结论前 cc-report"规则，指令其 close 会话；重派新任务
- **建议改进**：run-cc.sh 或 assign-guide.md 增加前置校验：`gh issue view N --json state,closedAt` 若 CLOSED 则拒派；项目看板状态滞后时以 Issue state 为准
- **状态**：观察中（第 1 次，暂不触发自动止血阈值）

---

### 2026-04-15 04:41 📊 Token Pool 主力模型切换 glm-5.0 → K2.6-code-preview 运行 1h 评估

**切换时刻**：2026-04-15 03:38（TPP 重启生效，PID 2815644）
**评估窗口**：03:38 - 04:38（运行满 1h）
**活跃 CC**：5 个并发（kimi1 #3549 / kimi2 #3533 / kimi3 #3550→#3535 / kimi4 #3534 / kimi5 #3530）

#### 量化对比

| 维度 | glm-5.0（03:13-03:38，前 25m） | K2.6-code-preview（03:38-04:38，1h） |
|------|----------|----------|
| merged PR | 1 个（#3682 CRM-12 授权管理） | **2 个**（#3684 CRM-11 智能过会 / #3685 kindergarten hotfix） |
| 大规模 API 错误 | "thinking is enabled but reasoning_content missing" 卡 4/5 CC（03:30-03:39） | **0 次** |
| 红线违规拦截 | ≥4 次阈值触发 auto-heal（kimi1 #3549 Flyway 硬编码 menu_id + 跨 scope） | **0 次** |
| 单测 @Tag 误用 | 1 次（kimi1 `@Tag("unit")` 非项目标准） | 0 次 |
| mysql 直连主库 | 2 次（kimi1 + kimi3） | 0 次 |
| 一次编译成功率（新 Issue） | N/A | kimi3 #3535 一次 16 文件 + Mapper XML 编译绿（mvn clean compile BUILD SUCCESS 首跑通过） |

#### K2.6-code-preview 做得更好的

1. **无 API Error 400**：切换后 1h 内无任何 "reasoning_content missing" 事故（glm-5.0 切换前 10min 内同时卡 4 CC）
2. **指令理解一次到位**：kimi1 收到 `@Tag("unit")` → `@Tag("dev")` 修复指令后一次调通 JUnit 4/4 绿，无反复追问
3. **后端代码产出速度**：kimi3 #3535 从开工到 16 文件 + Mapper XML 编译绿约 15-18 分钟，glm-5.0 时期类似规模通常 30-45 分钟
4. **三方对账结论清晰**：kimi3 #3535 开工汇报直接给出"前端占位 / 后端无代码 / schema 增量"三段结论 + 7 阶段计划，glm-5.0 多见反复追问
5. **PR 提交节奏稳**：#3685 hotfix 从派单到 merge 约 10 分钟，一次过四道质量门
6. **Context 消耗效率**：kimi3 #3535 复杂 Issue 开工 → 16 文件 63% ctx，glm-5.0 类似任务早期就打到 80%+

#### K2.6-code-preview 做得不好 / 未改善的

1. **长跑 Issue 未自动结束**：kimi5 #3530（CRM-03 商机管道）从 glm-5.0 时代持续至 K2.6 已 3h28m 仍无 PR，K2.6 未展现"主动收尾打包"能力
2. **PR 提交阶段仍偏慢**：kimi1 #3549 达 4h0m 仍在 Playwright / 截图 / PR 阶段循环，接管后未明显提速（可能是 Playwright 套件本身耗时）
3. **评估样本不足**：仅 1h 内观测到 2 merged PR，红线违规 0 可能因 menu-contract skill 硬化（commit 687d53d）抢先生效掩盖模型差异，需更长窗口验证
4. **新问题监测**：本窗口未发现 K2.6 引入的新类型错误（grep 统计的 error_count 为历史字符残留，非 K2.6 期间新发）

#### 结论

K2.6-code-preview **整体优于 glm-5.0**，主要改进集中在：稳定性（无大规模 API 错误）、指令响应（一次到位）、后端大批量文件一次编译通过。建议保留 K2.6 为主力，继续观察 2-4h 验证长跑 Issue 行为。

#### 待清理

- 本评估完成后删除 `memory/project_k26_eval_deadline.md` + MEMORY.md 索引行 + `/tmp/k26-eval-context.md`（一次性任务，用户明示不留存）

---

### 2026-04-15 03:38 CC 裸用 `mysql -h 127.0.0.1 root/root` 直连主 MySQL（2 次，观察）

- **症状**：CC debug 数据库时直接 `mysql -h 127.0.0.1 -u root -proot -D wande-ai-kimiN` 裸连主机，实际应该 `docker exec wande-ai-mysql mysql ...` 走 docker 容器；易连错库或被密码拒绝
- **频次**：
  1. kimi1 #3549（root/root 失败后卡住，经理纠正）
  2. kimi3 #3550（3h5m + API Error 400 叠加，经理纠正）
- **根因**：shared-conventions / skill 未给出"查自己 kimi 的 MySQL"标准命令；CC 默认用本机 `mysql` 而非 `docker exec`
- **已处置**：个案指令
- **建议改进**（观察中，再 2 次达阈值落地）：frontend-coding/backend-coding skill 增"数据库直连速查"章节，给 `docker exec wande-ai-mysql mysql -uroot -p$(grep MYSQL_ROOT_PASSWORD ~/projects/.github/scripts/.env | cut -d= -f2) -D wande-ai-kimiN` 模板
- **状态**：观察中（2/4）

---

### 2026-04-15 03:30 CC 用项目无效 `@Tag` 导致单测 0 运行（1 次，观察）

- **症状**：kimi1 #3549 写单测用 `@Tag("unit")`，项目 surefire 配置 `<groups>${profiles.active}</groups>` 按 Maven profile 激活 Tag（local/dev/prod），`unit` 永远不被过滤到 → mvn test 显示 0 tests run → CC 误以为配置问题 → 摸索 Maven 配置 浪费时间
- **频次**：1 次（kimi1 #3549）
- **根因**：backend-coding/backend-test skill 未明确说明项目 `@Tag` 标准值（应为 `@Tag("dev")`，参考 FinOpsServiceTest），CC 默认 JUnit 5 习惯写 `@Tag("unit")`
- **已处置**：个案指令改 `@Tag("dev")` + 运行 `mvn test -P dev`
- **建议改进**（观察中）：backend-test skill 增"项目 @Tag 标准"段：`@Tag("dev")` 开发单测、`@Tag("prod")` 上线回归、禁止自创 tag
- **状态**：观察中（1/4）

---

### 2026-04-15 03:15 🚨🚨🚨 Flyway 硬编码 menu_id/role_id + 跨 scope 改已 merged 脚本（≥4 次自动止血触发）

- **症状**：CC 诊断前端 404 时归因于 sys_menu.parent_id NULL，随即写 `UPDATE sys_menu SET parent_id=XXX WHERE menu_id=YYY` 硬编码菜单 ID，或硬编码 `role_id=1` 分配权限；部分 CC 修改**已合入 main** 的其他 Issue 的 Flyway 脚本（跨 scope 污染）
- **频次**：
  1. kimi8 #3481（硬编码 menu_id UPDATE，拦截）
  2. kimi8 #3481（二次尝试同模式，再拦截）
  3. kimi1 #3637（硬编码 menu_id UPDATE）
  4. kimi1 #3549（硬编码 menu_id=16223/16224 + role_id=1 + 改 #3633/#3483 已 merged Flyway）
  → **≥4 次，自动止血触发**
- **根因**：
  1. CC 把"前端路由 404"误诊为"菜单 parent_id=NULL"，实际多为 Vite glob 缓存未刷新 / Controller URL 多 `/api` 前缀 / Flyway INSERT 漏写 parent_id 字段
  2. skill/backend-coding 的"菜单"部分未给出「动态 @max_id + 动态 @admin_role」样板，CC 习惯硬编码
  3. skill 未明确"已合入 main 的 Flyway 脚本绝对不可改"
- **已处置**：本轮个案拦截 kimi1（见 tmux 指令）；**触发 ≥4 次阈值自动止血**：skill/backend-coding 增菜单 Flyway 样板 + 跨 scope 红线 + 前端 404 排查清单；push main + tmux 通知 5 个 CC
- **建议改进**：（本轮已实施）
  1. skill/backend-coding 新增「菜单 Flyway 标准样板」：`SET @max_id = (SELECT IFNULL(MAX(menu_id),10000) FROM sys_menu); SET @parent = (SELECT menu_id FROM sys_menu WHERE menu_name='xxx' AND menu_type='M' LIMIT 1); INSERT ... VALUES (@max_id+1, ..., @parent, ...)`
  2. 红线：**禁止修改已 merged Issue 的 Flyway 脚本**（`git log --oneline <file>` 有其他 Issue 号 = 不碰）
  3. 前端 404 排查清单：先看 a) Vite glob（stop+start 非 restart），b) Controller URL 是否多 `/api`，c) Flyway INSERT 是否漏写 parent_id，**最后**才看菜单 parent_id
- **状态**：🚨 本轮自动止血，skill push main + 全员 tmux 通知

---

### 2026-04-15 02:00 🚨🚨 前端 vite 不走 cc-test-env.sh → 端口污染 / 逼近 pkill -f vite 红线（≥5 次达阈值）

- **症状**：前端起在 vite 默认端口 5173/5666-5671/5668/5670 等（而非 kimi 隔离的 810N），CC 继而尝试 `lsof kill 5670` / `pkill -f vite` 清理（逼近红线污染整个 kimi 池），或改 Playwright baseURL 适配错误端口、反复登录 500/Modal 遮罩
- **频次**：
  1. kimi5 #3636（5666-5671，2h9m 卡点，几乎 pkill 全池）
  2. kimi3 #3550（5668，第一次）
  3. kimi3 #3550（5670，第二次同 Issue）
  4. kimi4 #3529（双 vite 进程，端口错位）
  5. 2026-04-14 kimi8 + kimi16（研发经理误发 pkill -f vite 紧急拦截）
  → **≥5 次，已达阈值，建议立即落地 skill 硬点**
- **根因**：
  1. CC 倾向 `cd frontend && pnpm run dev:antd` 或 `pnpm dev`，不知 `cc-test-env.sh start/restart kimiN` 已封装 vite port 配置
  2. vite 默认 port 5173+1+1 递增，首个 kimi 占 5173 后续 kimi 手启 pnpm dev → 5174/5175/... 互相污染
  3. skill/frontend-coding 未强调"只能用 cc-test-env.sh 启动"
- **已处置**：每次个案精准发指令：stop → restart → 确认 810N 监听；禁止 pkill/lsof 杀非 810N 端口
- **建议改进**：
  1. skill/frontend-coding T_run_frontend 增硬点：**启动前端只能用 `bash ~/projects/.github/scripts/cc-test-env.sh restart kimiN`**，禁止 `pnpm dev` / `pnpm run dev:antd` 直接起
  2. 红线："若前端端口 ≠ 810N（N = kimi 编号），100% 是你没走 cc-test-env.sh，不是 vite 坏"
  3. cc-test-env.sh 可选增 lint：检测 kimiN 目录外起的 vite 进程 → 警告
- **状态**：🚨 频次已达阈值（5 次），建议本周落地 skill 硬点

---

### 2026-04-15 02:00 Playwright API smoke 登录认证反复摸索（4 次，观察）

- **症状**：CC 写 Playwright smoke 时被登录卡住 40-60min，问题形式不一：Sa-Token 401 / getRouters 路由 404 / 登录 Modal 遮罩 / smoke 找不到 tab
- **频次**：
  1. kimi2 #3548（Sa-Token 401 卡 45min）
  2. kimi3 #3550（登录 Modal 遮罩 500）
  3. kimi4 #3551（getRouters 路由 404）
  4. kimi1 #3549（smoke getByRole('tab') 找不到）
- **根因**：shared-conventions / skill 未提供 ruoyi Sa-Token 标准 Playwright API smoke 样板（Basic auth clientId + /auth/login body + Bearer token + addCookies 绕 UI 登录），CC 每次从零摸索
- **已处置**：个案发完整 curl + Playwright 样板代码（见对话记录 #3548/#3550/#3551/#3549 指令）
- **建议改进**：shared-conventions.md 或 skill/backend-coding / skill/frontend-coding 增标准 Playwright API smoke 模板（clientId + token 获取 + 带 Bearer 调业务 API + addCookies 走前端 mount smoke 绕 UI），CC 直接抄不用摸
- **状态**：观察中（接近 5 次阈值，再犯 1 次落地）

---

### 2026-04-14 23:50 🚨 CC 手动 mvn spring-boot:run 绕过 cc-test-env.sh → profile=test 连错库

- **症状**：kimi2 #3461 后端启动 50min 无进展，报 `Access denied for user 'wande'@'172.17.0.1'`，CC 认为是"MySQL 密码/环境问题"请求跳过截图提 PR
- **频次**：kimi2 #3461（第 1 次，50min 卡住）+ kimi5 #3636（第 2 次，同轮 1h10min 卡住）→ 已达"频繁"阈值，建议立即落地 skill 硬点
- **根因**：
  1. CC 用 `mvn spring-boot:run -Dspring-boot.run.profiles=test`，test profile application-test.yml 写死 `root/root` + 库名 `wande-ai`（非 kimi 隔离库）
  2. `cc-test-env.sh start/restart` 才是正确入口：它用 profile=dev + **命令行参数**覆盖 `spring.datasource.dynamic.datasource.master.url/username/password` → 指向 `wande-ai-kimiN` + `wande/wande_dev_2026`
  3. CC 不知 cc-test-env.sh 已封装所有环境注入逻辑，误判为"环境坏了"
- **已处置**：经理直查 docker mysql GRANT 验证 wande 用户可用（`wande_dev_2026` 密码正确、wande-ai-kimi2 库 92 表 105 条菜单数据完好），向 kimi2 发精准指令：pkill 手启 mvn → `cc-test-env.sh restart kimi2`
- **建议改进**：
  1. skill/backend-coding T_run_backend 增硬点：**启动后端只能用 `bash ~/projects/.github/scripts/cc-test-env.sh restart kimiN`**，禁止直接 `mvn spring-boot:run`
  2. 红线："若后端报 Access denied / 找不到 wande-ai 库 → 90% 是你用错 profile，不是环境坏"
  3. cc-test-env.sh 可选增 lint：检测 7102 端口外的 mvn spring-boot:run → 警告
- **状态**：观察中（再犯落地 skill 硬点）

---

### 2026-04-14 23:35 🚨 CC 新增 Controller 后 spring-boot:run 仍 404（m2 本地仓库旧 jar）

- **症状**：kimi3 #3520 / kimi4 #3529 同时出现 —— 在 `ruoyi-modules/wande-ai` 新建 Controller 后，`mvn spring-boot:run -pl ruoyi-admin` 启动，所有 `org.ruoyi.wande.controller.*` 全部 404（包括此前已 merged 能工作的 ProvinceStatsController），CC 误以为是 Spring 未扫描到包，反复改 `@ComponentScan` / `mvn -U` 绕弯
- **频次**：kimi3 #3520（第 1 次，22 分钟）+ kimi4 #3529（第 1 次，50 分钟）同轮并发 → 算"频繁"
- **根因**：
  1. `ruoyi-admin/pom.xml` 以 artifact 依赖方式引用 `wande-ai`（非 source reactor）
  2. `mvn spring-boot:run -pl ruoyi-admin` 只编译 ruoyi-admin 自身，wande-ai 从本地 m2 仓库 `~/cc_scheduler/m2/kimiN/repository` 取**旧 jar**，新 Controller 根本没进 classpath
  3. skill/backend-coding T6/T_run_backend 文档没强调"改 wande-ai 模块后必须先 install 到本地 m2"
- **已处置**：向 kimi3/kimi4 发统一指令：`mvn install -pl ruoyi-modules/wande-ai -am -DskipTests -Dmaven.repo.local=~/cc_scheduler/m2/kimiN/repository`，再 `cc-test-env.sh restart kimiN`
- **建议改进**：
  1. skill/backend-coding 在启动后端步骤增加前置："**若本次改动涉及 ruoyi-modules/wande-ai（或任何非 ruoyi-admin 的模块），必须先 mvn install -pl <改动模块> -am -DskipTests 到本地 m2，再 spring-boot:run ruoyi-admin**"
  2. cc-test-env.sh restart 可封装该逻辑：接受 `--install-module wande-ai` 参数自动 install
  3. 报告 404 时的诊断清单：检查 target/classes 里有无新 Controller 的 .class → 有 .class 就是 m2 jar 旧
- **状态**：观察中（本轮 2 CC 同时卡 ≥22min，若再犯落地 skill 硬点 + cc-test-env 封装）

---

### 2026-04-14 23:12 🚨 CC 误执行 `git clean` 删除所有未提交新文件

- **症状**：kimi5 #3636 后端 16 文件 + 前端 API 层 + 契约全部未 stage 未 commit，误跑 `git clean -fd` 后全部消失。git stash 空、reflog 无，只剩 target/classes 里的 .class 存活
- **频次**：kimi5 #3636（第 1 次）；此前未见，但未提交文件保护失败模式风险极高，先预警登记
- **根因**：
  1. CC 在开发过程中长时间不 `git add/commit`，所有新文件处于 untracked 状态
  2. `git clean -fd` 直接移除所有 untracked → 全丢
  3. 模板/skill 未强制"阶段性 WIP commit"或"clean 前 stash -u 护栏"
- **已处置**：
  1. 教 kimi5 用 `javap -p + __Javadoc.json` 从 target/classes 反编译恢复后端（16 文件全可还原）
  2. 前端 API/契约从 Controller 注解反推
  3. Flyway 脚本 origin/dev 还在（排程经理预置的 V007/V013）
- **建议改进**：
  1. shared-conventions.md 新增：**禁止** `git clean -fd/-fdx` 于 feature 分支；若需要清理，先 `git stash push -u -m "safety-net"` 或 `git add -A && git commit -m "WIP before clean"`
  2. skill/backend-coding 和 skill/frontend-coding 模板在 T1 契约之后加硬点：**每个阶段结束必须 WIP commit**（Entity/Mapper/Service/Controller/前端页面），不留未追踪文件过夜
  3. 或 post-tool hook 检测 `git clean` → 强制先 stash
- **状态**：观察中（本次成功恢复；若再犯 1 次立即落地红线）

---

### 2026-04-14 21:55 🚨 研发经理误指令 `pkill -f vite` 会污染整个池

- **症状**：研发经理给 kimi8/kimi16 的指令 `pkill -f vite` 用于解决 Vite glob 缓存。**事实**：pkill -f 按 cmdline grep，会无差别杀所有 kimi (1-20) 的 vite 进程
- **频次**：研发经理 1 次（kimi8 + kimi16 同时下发）；用户拦截
- **根因**：研发经理把单机 dev 思维带入多 kimi 隔离环境，忘了 `cc-test-env.sh` 已封装按 kimi 隔离的 PID 文件 kill 逻辑
- **已处置**：紧急更正发 kimi8/kimi16；登记本条
- **建议改进**：
  1. CLAUDE.md 红线新增（待用户批准）：**禁止** `pkill -f vite/node/pnpm` / `killall vite/node`，**只能** `bash cc-test-env.sh restart kimiN` 或 `fuser -k 810N/tcp`
  2. shared-conventions.md 在"环境硬隔离"段补一条进程操作约束
- **状态**：观察中（下次再有 CC 用 pkill -f 立即拦截）

---

### 2026-04-14 21:22 🚨 auto-code-agent bot 误关 PR body 中引用的他人 Issue

- **症状**：PR#3672 (#3637) merge 到 dev → bot 自动 close #3481 + 评论 "PR #3672 merged to dev. Issue auto-closed." 实际 PR body 仅"依赖 #3481 修复"、"系统性问题，正在 #3481 中修复"等上下文说明，**未**含 closes/fixes/resolves 关键词
- **频次**：PR#3672 → #3481 误关（第 1 次；但 bot 逻辑对所有 PR 生效，潜在全量风险）
- **根因**：
  1. auto-code-agent bot 疑似简单正则匹配 PR body 中 `#NNNN` 即关联关闭，未区分 closes/fixes 关键词
  2. CC 写 PR body 时随意引用他人 Issue 作为上下文，触发 bot 误判
- **已处置**：
  1. 重开 #3481 + Project 状态拉回 In Progress
  2. kimi8 工作本地保留（feature-Issue-3481 分支 1 commit + 5 M 文件未 push）
- **建议改进**：
  1. **短期**：CC 写 PR body 时禁止裸 `#NNNN` 引用他人 Issue，改用文字"Issue 3481"或反引号 `` `#3481` `` 规避 bot
  2. **中期**：排查 auto-code-agent bot 关联逻辑，修正需识别 GitHub 标准 closing keywords
  3. **立即**：pr-body-lint 增加"检测 PR body 裸 #NNNN 非本 Issue 引用 → 告警"
- **状态**：🚨 观察中（#3481 已恢复，需排查 bot 源码 + lint 增强）

---

### 2026-04-14 21:10 CC 反复硬编码 menu_id 写 Flyway 修 "parent_id NULL"

- **症状**：前端 404 → CC 误判为 sys_menu.parent_id NULL → 新建 Flyway `UPDATE sys_menu ... WHERE menu_id IN (16208, 16213) AND parent_id IS NULL`
- **频次**：kimi8 #3481（2 次：V20260414200000 / V20260414210000）+ kimi1 #3637（1 次）
- **根因**：
  1. CC 倾向"可见数据问题 > 不可见前端解析问题"，选择有形的 DB 修，绕开真正的 import.meta.glob 诊断
  2. menu_id 在本 kimi 环境是 local id，CC 不知 push 后别人环境 id 不同
- **已处置**：逐个发消息要求立即删脚本 + 红线警告（再犯摘下池）
- **建议改进**：
  1. CLAUDE.md 红线新增第 14 条：**禁止在 Flyway 脚本里 UPDATE/DELETE 带硬编码 `menu_id`/`role_id`/任何业务表自增主键**，只允许 WHERE 按业务字段（menu_name/perms 等）
  2. 或 pr-body-lint 增加"Flyway 硬编码 menu_id 检测"（grep `WHERE menu_id IN` in .sql → 拦截）
- **状态**：观察中（再犯就落地红线 + lint 检测）

---

### 2026-04-14 21:05 task.md 模板 T12 "轮询 merged" 语义矛盾

- **症状**：PR 推送后 quality-gate 门 2 报 "task.md 存在 1 项未勾 steps"，唯一未勾就是 T12/T14 "轮询 merged"
- **频次**：kimi9 #3482 PR#3669；kimi1 #3637 PR#3672（第 2 次；开工时模板旧，task.md 遗留 T10 行）；历史看盘可能更多
- **根因**：T12 按定义在 push 后执行，但门 2 在 push 时立即检查 task.md 全勾 → 逻辑矛盾。模板已改但已生成的 task.md 不会回溯更新 → 老 task.md 继续撞门
- **已处置**：issue-task-md / fix-ci-failure 模板删除 T12/T_fix_N_6 行（commit 4a2c82f）；对已生成 task.md 的在跑 CC 人工通知删除 T10 行
- **建议改进**：模板层已根除；过渡期老任务遗留 task.md 由研发经理按需通知删行
- **状态**：✅ 模板层已实施 4a2c82f；过渡期观察

---

### 2026-04-15 10:10 前端 api 模块同名文件 vs 目录冲突（严重 P0）

- **症状**：PR #3689 为 CRM-03 商机管道新建 `frontend/apps/web-antd/src/api/system/user.ts`（15 行，仅 2 个导出 getUserList/getUserDetail），但该目录下已存在 `user/index.ts`（171 行，14 个导出）。Vite 别名 `#/api/system/user` 优先解析到 `user.ts`，**7 个消费方**（dept-drawer / user-drawer / user-import / user-info / user-reset-pwd / post-drawer / workflow/user-select）全部失去解析
- **影响**：**今日 10 次 Dev 部署 CI 全部 failed（从 03:13 起）**，今日 9 个 CRM PR merged 但全部未部署到主环境 → 业务侧 "CRM 什么都看不见" 持续 7 小时
- **频次**：1 次（但后果 P0）
- **已处置**：研发经理手动 hotfix PR #3693（将 getUserList/getUserDetail 并入 user/index.ts，删除 user.ts）
- **建议改进**：
  1. 在 **frontend-coding** skill 中加红线：**新增 `src/api/<模块>/<实体>.ts` 前必须先 `ls src/api/<模块>/` 检查同名目录**。存在则必须追加到 `<实体>/index.ts`，禁止新建同名 .ts
  2. 在 pr-body-lint 里加静态检查：`src/api/**/*.ts` 文件名与同目录子目录同名即 FAIL
- **状态**：立即个案处置 + 加入待观察。若再次出现则升级为 4 次前触发的前置预防（加入 skill 红线）

---

### 2026-04-15 10:50 🚨 mysql 裸 root 第 4 次触发自动止血

- **症状**：kimi2 #3683 调试菜单时用 `docker exec mysql-dev mysql -uroot -proot wande-ai-kimi2`（第 4 次，前 3 次见 08:21 登记）
- **频次**：**≥4 次**，触发自动止血
- **已处置**：
  1. **已更新** `docs/agent-docs/skills/backend-coding/SKILL.md` 禁止清单章节：加入"❌ mysql -uroot -proot 裸连主 MySQL"条目 + 标准 docker exec 模板
  2. **已推送** main（软链自动生效）
  3. **tmux 通知** 所有 5 个在运行 CC 新规则要点
- **状态**：✅ 已止血（skill 层）
