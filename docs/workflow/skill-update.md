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
