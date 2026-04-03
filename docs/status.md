# 万德AI平台 · 项目状态

> ⏰ 最后更新：2026-04-03 21:24 by Perplexity Computer

---

## 🎯 Sprint 计划

| Sprint | 状态 | 开始 | 截止 | 重点功能模块 |
|--------|------|------|------|-------------|
| Sprint-1 | 🟢 进行中 | 2026-03-28 | 2026-04-11 | 超管驾驶舱、销售记录体系、D3参数化设计 |
| Sprint-2 | ⏳ 待启动 | 2026-04-12 | — | 执行管理、CRM、数据迁移、品牌中心 |

### Sprint-1 重点模块

| 模块 | Issue数 | 说明 | sprints子目录 |
|------|---------|------|--------------|
| 超管驾驶舱 | 95 | 平台系统+开发者协同+安全审计 | `sprints/sprint-1/超管驾驶舱/` |
| 销售记录体系 | 16 | 三维驱动+记录中心+周报月报 | `sprints/sprint-1/销售记录体系/` |
| D3参数化设计 | — | 电池包+AI集成+Web平台 | `sprints/sprint-1/D3参数化设计/` |

### Sprint-2 预览（76个Issue，已去重清理）

| 模块 | Issue数 | 说明 | sprints子目录 |
|------|---------|------|--------------|
| 执行管理 | 57 | 数据库建表→CRUD→图纸/BOM/采购/生产/安装/验收/变更→利润/成本/回款→AI预警→EVM | `sprints/sprint-2/执行管理/` |
| CRM | 6 | 跟进记录+商机管理+经销体系+报价引擎 | `sprints/sprint-2/CRM/` |
| 数据迁移 | 5 | 明道云→执行管理迁移 | `sprints/sprint-2/数据迁移/` |
| 品牌中心 | 3 | 多平台数据采集+竞品监测 | `sprints/sprint-2/品牌中心/` |
| 其他 | 5 | 质保/协同/代理商/提成 | `sprints/sprint-2/其他/` |

### 暂不做
- CRM明道云对接（等API Key）

---

## 🏗️ 仓库架构

> **2026-04-02起，backend和front合并为 Monorepo `wande-play`。** 2026-04-03起，data-pipeline 也整合进 wande-play/pipeline。旧仓库保留但不再新增Issue。

| 仓库 | 用途 | 看板 |
|------|------|------|
| [wande-play](https://github.com/WnadeyaowuOraganization/wande-play) | Monorepo：后端(Spring Boot) + 前端(Vue3) + E2E(Playwright) + 数据管线(Python) + 接口契约 | Project#4 |
| [wande-gh-plugins](https://github.com/WnadeyaowuOraganization/wande-gh-plugins) | Grasshopper 参数化插件库 | Project#4 |
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
| D13 | 04-03 | ✅ | Sprint-2执行管理变更→合同联动(#2085)提升为P0 | 行业最佳实践：变更金额直接影响合同回款，是核心功能 | 吴耀 |
| D14 | 04-03 | ✅ | Sprint-2新增EVM挣值管理简化版(#2506, module:fullstack) | 行业标配，SPI/CPI实时计算+项目健康度评分，适合万德长周期项目 | 吴耀 |
| D15 | 04-03 | ✅ | Sprint-2去重：关闭#2184-#2188，保留#2464-#2468 | 5组完全重复Issue清理 | 吴耀 |
| D16 | 04-03 | ✅ | E2E测试独立工作目录：wande-play-e2e-mid / wande-play-e2e-top | 中层/顶层E2E各自完整wande-play克隆，互不干扰，也不影响编程CC | 伟平 |
| D17 | 04-03 | ✅ | 排程计划按重点模块分子目录 | sprints/日期/超管驾驶舱/PLAN.md，支持多模块并行排程 | 伟平 |
| D18 | 04-03 | ✅ | query-project-issues.sh 输出增加 module/priority 列 | 研发经理CC排程时可直接按标签分类，识别fullstack触发Agent Teams | 伟平 |
| D19 | 04-03 | ✅ | 首个fullstack Issue #1440（D3技术确认中心）用于测试Agent Teams | 合并#443+#1166，验证研发经理CC对module:fullstack的排程和触发 | 伟平 |
| D20 | 04-03 | ✅ | Claude Office新增CC实时日志显示 | 点击agent/研发经理卡片打开终端风格日志面板，3秒自动刷新 | 伟平 |
| D21 | 04-03 | ✅ | Project#2废弃，wande-gh-plugins迁移到Project#4 | 统一看板管理，Project#2仅保留历史追溯 | 伟平 |
| D22 | 04-03 | ✅ | 测试架构改革：编程CC接管构建部署，CI仅负责PR E2E和pipeline同步 | build-deploy-dev.yml剥离构建部署job，编程CC在feature分支完成TDD→build→deploy→smoke→PR全流程；CI pr-test.yml负责E2E自动merge/fail；cron 2h/6h兜底回归 | 伟平 |
| D23 | 04-04 | ✅ | 根CLAUDE.md增加Issue拾取指引+清理主目录引用 | 编程CC收到非标准prompt时不知道怎么获取Issue内容（gh issue view失败后无备用方案）。根CLAUDE.md新增「Issue拾取」章节：唯一正确方式(gh issue view)+三级备用方案(token重获→curl REST API→curl评论API)+非标准prompt说明。同时修正Project看板链接(#2→#4)和辅助脚本路径，删除主目录引用 | 伟平 |
| D24 | 04-04 | ✅ | Thinking模式改为effort参数动态控制，由研发经理CC按Issue复杂度决策 | 原方案：settings.json全局DISABLE_THINKING=1一刀切关闭。新方案：移除所有settings.json中的DISABLE_THINKING，三个启动脚本(run-cc.sh/run-cc-with-prompt.sh/run-cc-play.sh)新增第5个参数[effort]，不传时默认medium。研发经理CC根据Issue标签决策：docs/config→low，常规CRUD→medium，多文件重构/复杂bug→high，架构级重构/fullstack→high或max | 伟平 |
| D25 | 04-04 | ✅ | pr-test.yml独立目录+全局排队 | PR E2E使用wande-play-ci专用目录，concurrency全局排队避免并发互踩，与cron e2e-mid/e2e-top目录隔离 | 伟平 |
| D26 | 04-04 | ✅ | CI编译门禁+编程CC防重复类规范 | pr-test.yml新增mvn compile步骤；编程CC创建新类前必须查重；包路径唯一映射规则；研发经理CC同模块Issue串行排程 | 伟平 |
| D27 | 04-04 | ✅ | 合并wande-ai-api到wande-ai（#2585 P0） | PR #2593 已创建：删除wande-ai-api模块，迁移1000+类到wande-ai，清理17个内部重复+15个跨模块重复，编译打包通过 | 伟平 |
| D28 | 04-04 | 🟡 | 接口契约目录启用（#2586 P0） | shared/api-contracts/作为前后端唯一真相源，扫描现有API初始化契约文件；契约先行规则写入CLAUDE.md | 伟平 |
| D29 | 04-04 | ✅ | Sprint管理规范化：表格化+按阶段命名 | status.md Sprint计划改为表格（阶段/状态/时间/重点模块/子目录路径）；sprints目录按阶段命名(sprint-1)而非日期；研发经理CC直接查表获取sprint名和模块子目录 | 伟平 |
| D30 | 04-04 | ✅ | 统一run-cc.sh为唯一CC启动脚本+Issue预取机制 | 合并run-cc-play.sh到run-cc.sh，启动前自动预取Issue内容到issue-source.md，编程CC从本地文件读取（解决kimi模型截断gh命令导致10分钟空转的问题，降至6秒）；删除round-executor.sh，修复cc-error-parser.py旧路径 | 伟平 |
| D30 | 04-04 | ✅ | 统一run-cc.sh为唯一CC启动脚本+Issue预取机制 | 合并run-cc-play.sh到run-cc.sh，启动前自动预取Issue内容到issue-source.md，编程CC从本地文件读取（解决kimi模型截断gh命令导致10分钟空转的问题，降至6秒）；删除round-executor.sh，修复cc-error-parser.py旧路径 | 伟平 |

| D30 | 04-04 | ✅ | CI测试环境隔离+pr-test.yml全面优化 | pr-test与dev环境竞态：1)新增CI专用环境(:6041/:8084)与dev(:6040/:8083)端口隔离，数据库共用 2)全局排队保证CI无并发冲突 3)去重复编译步骤 4)修复Issue号提取bug(PR body特殊字符致shell exit 127) 5)失败评论改为含用例名+错误摘要+日志链接 6)失败信息同时评论到Issue 7)新增ci-env.sh+nginx:8084 8)CLAUDE.md双环境说明 | 伟平 |
| D30 | 04-04 | ✅ | CI测试环境隔离+pr-test.yml全面优化 | pr-test与dev环境竞态：1)新增CI专用环境(:6041/:8084)与dev(:6040/:8083)端口隔离，数据库共用 2)全局排队保证CI无并发冲突 3)去重复编译步骤 4)修复Issue号提取bug(PR body特殊字符致shell exit 127) 5)失败评论改为含用例名+错误摘要+日志链接 6)失败信息同时评论到Issue 7)新增ci-env.sh+nginx:8084 8)CLAUDE.md双环境说明 | 伟平 |
> **规则**：🟡=提议待确认 / ✅=已生效 / ❌=已废弃（保留追溯）
> **决策权**：吴耀有最终决策权

---

## 📊 工作状态

### Project#4 — wande-play 研发看板（2026-04-03 19:35）

| 状态 | 数量 |
|------|------|
| Plan | 722 |
| Todo | 288 |
| In Progress | 27 |
| 总Items | 1037 |
| Open Issue | 1070 |

**看板地址**: https://github.com/orgs/WnadeyaowuOraganization/projects/4

### Project#2 — 已废弃

> 2026-04-03 起 Project#2 不再使用。所有活跃 Issue 已迁移到 Project#4，wande-gh-plugins 的 22 个 Issue 也已迁移。Project#2 仅保留历史数据供追溯。

### 最近完成（wande-play 04-03）
- [后端重构] 合并 wande-ai-api 到 wande-ai，消除42个重复类冲突 #2585 → PR #2593
- [接口契约] 初始化 shared/api-contracts 目录与规范文档 #2586
- [项目矿场] 新增运营仪表盘页面 #870
- [项目矿场] 矿场运营仪表盘核心指标可视化 #869
- [前端] URL去.html后缀+域名统一 #868

### Sprint-2 调整记录（04-03）
- 关闭5个重复Issue：#2184→#2464, #2185→#2465, #2186→#2466, #2187→#2467, #2188→#2468
- #2085 变更→合同联动优先级 P1→P0
- 新增 #2506 EVM挣值管理简化版（module:fullstack, Sprint-2）
- Sprint-2 当前：76个有效Issue（81 - 5重复）

### 基础设施变更（04-03）
- E2E测试目录：wande-ai-e2e → wande-play-e2e-mid（中层）/ wande-play-e2e-top（顶层）
- 316个Issue批量关联到Project#4（之前仅在Project#2）
- 研发经理CC排程改为按重点模块分子目录（超管驾驶舱/销售记录体系/D3参数化/其他）
- query-project-issues.sh输出增加module/priority/labels列
- Claude Office新增CC实时日志显示（/api/logs端点 + 终端风格面板）
- 首个fullstack Issue #1440 创建（合并#443+#1166），用于Agent Teams测试
- Project#2废弃，wande-gh-plugins 22个Issue迁移到Project#4
- 测试架构改革落地：编程CC接管构建部署，build-deploy-dev.yml仅保留pipeline sync，新增pr-test.yml自动E2E+merge/fail
- D31决策（04-04）：编程CC职责简化 — 去掉deploy-dev.sh和Playwright步骤，只保留编译检查+单元测试；build-deploy-dev.yml补全后端/前端自动构建部署（merge到dev后触发）
- CC prompt全面优化：研发经理(425→160行)、backend(45→28)、frontend(617→119)、E2E(263→80)

---

## 📌 需要对方处理

### @伟平 待讨论
- **dev分支后端无法启动（P0）** — 已通过 #2585 / PR #2593 合并 wande-ai-api 到 wande-ai，清理 42 个重复类冲突，编译打包通过。待 pr-test.yml E2E 验证后 merge。

### @伟平 待讨论

### @吴耀
- 明道云 API Key — 解锁 CRM 对接
- ceshi.tiyouoperation.com 决策确认 — 是否继续使用此域名

### @CC（研发经理）
- Sprint目标以本文件「当前目标」章节为准
- 完成一个重点功能后更新本文件的「工作状态」和「最近完成」
