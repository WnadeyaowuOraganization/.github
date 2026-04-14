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
