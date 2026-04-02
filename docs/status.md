# 万德AI平台 · 项目状态

> ⏰ 最后更新：2026-04-03 02:30 by Perplexity Computer

---

## 🎯 当前目标

**里程碑**：Sprint-1 核心功能 | **截止**：2026-04-11

### 重点推进
1. [ ] 超管驾驶舱 — 平台系统+开发者协同+安全审计（95个Issue）
2. [ ] 销售记录体系 — 三维驱动+记录中心+周报月报（16个Issue）
3. [ ] D3参数化设计 v2.0 — 电池包+AI集成+Web平台

### 暂不做
- CRM明道云对接（等API Key）

---

## 🏗️ 仓库架构

> **2026-04-02起，backend和front合并为 Monorepo `wande-play`。** 2026-04-03起，data-pipeline 也整合进 wande-play/pipeline。旧仓库保留但不再新增Issue。

| 仓库 | 用途 | 看板 |
|------|------|------|
| [wande-play](https://github.com/WnadeyaowuOraganization/wande-play) | Monorepo：后端(Spring Boot) + 前端(Vue3) + E2E(Playwright) + 数据管线(Python) + 接口契约 | Project#4 |
| [wande-gh-plugins](https://github.com/WnadeyaowuOraganization/wande-gh-plugins) | Grasshopper 参数化插件库 | Project#2 |
| [.github](https://github.com/WnadeyaowuOraganization/.github) | 组织级配置 — 研发经理CC指令/辅助脚本/Sprint记录 | — |

### 已归档（仅追溯）
| 仓库 | 说明 |
|------|------|
| wande-ai-backend | 已合并入 wande-play/backend |
| wande-ai-front | 已合并入 wande-play/frontend |
| wande-data-pipeline | 已合并入 wande-play/pipeline |

### Issue 路由规则

| 类型 | 目标仓库 |
|------|----------|
| Java/Spring Boot 后端 | wande-play（标签 `module:backend`） |
| Vue3/Vben Admin 前端 | wande-play（标签 `module:frontend`） |
| 前后端联动 | wande-play（标签 `module:fullstack`） |
| Python爬虫/采集/G7e采集 | wande-play（标签 `module:pipeline`） |
| Grasshopper插件 | wande-gh-plugins |
| 基础设施/CI/CD/自动编程 | .github |

---

## 📋 重大决策

| # | 日期 | 状态 | 决策 | 背景 | 决策人 |
|---|------|------|------|------|--------|
| D1 | 03-12 | ✅ | main-only 分支策略 | 团队小，dev分支增加合并成本 | 吴耀 |
| D2 | 03-12 | ✅ | async SQLAlchemy（后端Java/Spring Boot，数据管道Python） | 技术栈分离 | 吴耀 |
| D3 | 03-22 | ✅ | 数据管道独立仓库 wande-data-pipeline | 爬虫与业务逻辑分离 | 吴耀 |
| D4 | 03-11 | ✅ | 环境隔离：Lightsail=生产 / G7e=测试 | 生产环境功能上线需审批 | 吴耀 |
| D5 | 03-29 | ✅ | 调度器v2：Plan→Todo→In Progress→Done 全自动 | 替代手动SCHEDULE.md | 吴耀 |
| D6 | 03-27 | ✅ | TDD模式 + E2E测试解耦 | 编程CC先写单元测试再编码；E2E改为定时调度独立触发，不阻塞编程CC | 吴耀 |
| D7 | 04-01 | ✅ | 驾驶舱预算=开发运维预算(FinOps)，业务预算回归module:budget | 边界清晰 | 吴耀 |
| D8 | 04-02 | ✅ | 销售记录三维驱动：流程+项目+时间 | 替代纯手动周报 | 吴耀 |
| D9 | 04-02 | ✅ | Monorepo：backend+front合并为 wande-play | 减少跨仓库协调成本，支持Agent Teams并行开发 | 吴耀 |
| D10 | 04-02 | ✅ | Project#4 (wande-play研发看板) 替代 Project#2 管理play仓库Issue | Monorepo需要独立看板 | 吴耀 |
| D11 | 03-28 | ✅ | PR创建职责固化给编程CC（gh pr create --base dev） | post-task.sh触发不稳定，PR创建回归编程CC第三阶段 | 吴耀 |
| D12 | 04-03 | ✅ | data-pipeline 整合进 wande-play/pipeline | 统一Monorepo管理，减少跨仓库协调 | 吴耀 |

> **规则**：🟡=提议待确认 / ✅=已生效 / ❌=已废弃（保留追溯）
> **决策权**：吴耀有最终决策权

---

## 📊 工作状态

### Project#4 — wande-play 研发看板（2026-04-03）

| 状态 | 数量 |
|------|------|
| 总Issue数 | 387 |
| Open Issue | 654 |

> Project#4 刚从 Project#2 迁移，部分 Issue 的 Status 字段待同步。

**看板地址**: https://github.com/orgs/WnadeyaowuOraganization/projects/4

### Project#2 — 旧看板（2026-04-03，含全部旧仓库）

| 状态 | 数量 |
|------|------|
| Plan | 697 |
| Todo | 128 |
| In Progress | 202 |
| Done | 548 |
| Pause | 1 |
| 总计 | 1576 |

### 最近完成（wande-play 04-02）
- [项目矿场] 新增运营仪表盘页面 #870
- [项目矿场] 矿场运营仪表盘核心指标可视化 #869
- [前端] URL去.html后缀+域名统一 #868
- 万德全部列表页按UI-GUIDE.md规范改造 #860
- [通知中心] 通知中心独立页面+SSE实时推送 #859
- [通知中心] 铃铛通知中心组件 #858
- [菜单重组] 创建「商务部」板块菜单结构 #857
- [Claude Office] Kanban看板面板 #856
- [超管驾驶舱] 运维监控中心+快捷指令终端 #855
- [Claude Office 2.0] 排程Tab三列看板 #854

---

## 📌 需要对方处理

### @吴耀
- 明道云 API Key — 解锁 CRM 对接
- ceshi.tiyouoperation.com 决策确认 — 是否继续使用此域名

### @CC（研发经理）
- Sprint目标以本文件「当前目标」章节为准
- 完成一个重点功能后更新本文件的「工作状态」和「最近完成」
