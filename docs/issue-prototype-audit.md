# Issue 原型支撑对账报告（v5.1）

> 生成日期: 2026-04-21
> 依据: wande-prototype v5.1 §5.0 三铁律 + §5.6 历史清理 SOP
> 仓库: WnadeyaowuOraganization/wande-play

## 总览

- **Open Issue 总数**: 750
- **含原型/设计引用（合规）**: 91（12%）
  - Master Issue: 14
  - 合规子 Issue: 77
- **不含原型/设计引用**: 659（87%）
  - 可豁免（文档/基建/chore）: 11
  - **需要对账**: 648

## 已有原型目录（16 个）

- `.github/docs/design/all-in-one/`
- `.github/docs/design/crm-商务中心/`
- `.github/docs/design/crm-商务工作台/`
- `.github/docs/design/crm-商机详情页/`
- `.github/docs/design/product-portal/`
- `.github/docs/design/ptc/`
- `.github/docs/design/rbac-homepage/`
- `.github/docs/design/全球项目矿场/`
- `.github/docs/design/审批体系/`
- `.github/docs/design/执行管理/`
- `.github/docs/design/招投标管理/`
- `.github/docs/design/线索商机架构统一/`
- `.github/docs/design/耀总驾驶舱/`
- `.github/docs/design/询盘报价体系/`
- `.github/docs/design/超管驾驶舱/`
- `.github/docs/design/销售记录体系/`

## 14 个 Master Issue

| # | 标题 | 含原型引用 |
|---|------|-----------|
| #4046 | [Master][权限管理] RBAC角色化侧边栏+角色主页 — 多视图架构 5角色Dashboard | ✅ |
| #4045 | [Master][产品门户] 经销商产品展示门户 — 多页架构 目录+详情+备件3页 | ✅ |
| #4043 | [Master][执行管理] 项目执行管理 v2.0 — 多Tab架构 列表页+详情页8Tab | ✅ |
| #4041 | [Master][耀总驾驶舱] 个人业务决策驾驶舱 — 多区块架构 8区块 | ✅ |
| #4024 | [Master][PLM] 产品技术中心 — 多Tab架构 8Tab（零件+BOM+ECO+配置器+技术确认+D3+合规） | ✅ |
| #4023 | [Master][审批体系] 统一审批工作台 — 多Tab架构 8Tab（含动态表单+企微贯通） | ✅ |
| #4022 | [Master][CRM] 商机详情页 — 多Tab架构 10Tab（左摘要+右侧Tab栏） | ✅ |
| #4021 | [Master][CRM] 商务中心 — 10页独立架构（仪表盘+客户+商机+询盘+记录+投标+回款+经销+提成） | ✅ |
| #4020 | [Master][超管驾驶舱] 平台级控制台 — 多Tab架构 18Tab（4大分组） | ✅ |
| #4013 | [Master][CRM] 线索/商机架构统一 — 四入口归并 单页架构 | ✅ |
| #4004 | [Master][业务运营] 销售记录体系 — 记录中心多Tab(4Tab)+老板周报单页 | ✅ |
| #3994 | [Master][矿场] 全球项目矿场 — 10Tab架构（执行6+洞察4） | ✅ |
| #3647 | [招投标] 全链条管理系统 — Sprint-2 Master Issue | ✅ |
| #3622 | [全过程资料管理] Master Issue — 7阶段文件管控+法规门控+三级预警+一键打包（13个子Issue） | ✅ |

## A 档：已有原型需回填引用（43 个）

这些 Issue 的 biz 域对应原型已存在，只需补三重引用块。

### biz:project（18 个，候选 Master: #3994，原型: 全球项目矿场/）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #2524 | [项目组织管理-P1] Phase4 [4/18]: 阶段门禁增强 — 阶段切换时检查必交文档清单 | Sprint-Backlog | backend |
| #2526 | [项目组织管理-P0] Phase6 [6/18]: 前端 — 文档上传+新版本上传弹窗 | Sprint-Backlog | frontend |
| #2527 | [项目组织管理-P1] Phase7 [7/18]: 前端 — 版本历史+审批流程面板 | Sprint-Backlog | frontend |
| #2528 | [项目组织管理-P0] Phase8 [8/18]: 数据库 — project_announcements + pro | Sprint-Backlog | backend |
| #2529 | [项目组织管理-P0] Phase9 [9/18]: 公告板Service — CRUD+@提及解析+企微通知+已读统计 | Sprint-Backlog | backend |
| #2530 | [项目组织管理-P0] Phase10 [10/18]: 公告板API — /project-center/{proje | Sprint-Backlog | backend |
| #2531 | [项目组织管理-P0] Phase11 [11/18]: 前端 — 项目详情页·公告板Tab | Sprint-Backlog | frontend |
| #2532 | [项目组织管理-P1] Phase12 [12/18]: 前端 — 已读追踪+公告详情 | Sprint-Backlog | frontend |
| #2533 | [项目组织管理-P1] Phase13 [13/18]: 任务表增强 — project_task增加行动项字段+来源关 | Sprint-Backlog | backend |
| #2534 | [项目组织管理-P1] Phase14 [14/18]: 前端 — 任务面板增加快速行动项区域 | Sprint-Backlog | frontend |
| #2535 | [项目组织管理-P1] Phase15 [15/18]: Gate Review记录表 — project_gate_r | Sprint-Backlog | backend |
| #2536 | [项目组织管理-P1] Phase16 [16/18]: 前端 — 阶段推进确认弹窗增强（门禁检查清单） | Sprint-Backlog | frontend |
| #2537 | [项目组织管理-P2] Phase17 [17/18]: 经验卡片增强 — 关联风险/公告+项目关闭自动触发 | Sprint-Backlog | backend |
| #2539 | [项目组织管理-P2] Phase18 [18/18]: 项目通讯录增强 — 外部干系人+RACI矩阵 | Sprint-Backlog | fullstack |
| #3179 | [项目360看板 1/6] 项目360统一看板页面 — 中标前后共用·阶段自动切换·多Tab聚合 | Sprint-2 | fullstack |
| #3181 | [项目360看板 3/6] 阶段文档注册表 — 每阶段必备文档清单模板+完成度计算 | Sprint-2 | backend |
| #3183 | [项目360看板 5/6] 项目360文档Tab前端 — 对内/对外分组+阶段进度+批量操作 | Sprint-2 | frontend |
| #3184 | [项目360看板 6/6] 文档访问日志+统计 — 谁看了什么文件·下载追踪 | Sprint-2 | backend |

### biz:approval（9 个，候选 Master: #4023，原型: 审批体系/）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #3161 | [企微审批贯通 1/6] 审批流程引擎SDK封装 — 企微「审批流程引擎」API Java SDK | Sprint-2 | backend |
| #3162 | [企微审批贯通 2/6] 审批流程引擎回调处理 — 状态变更实时同步 | Sprint-2 | backend |
| #3163 | [企微审批贯通 3/6] H5审批发起页适配 — 企微内嵌H5审批表单 | Sprint-2 | frontend |
| #3164 | [企微审批贯通 4/6] 审批消息卡片增强 — 企微内一键审批+富文本摘要 | Sprint-2 | backend |
| #3167 | [流程补齐 1/8] 动态表单引擎 JSON Schema — 通用审批表单配置化基础 | Sprint-2 | backend |
| #3170 | [流程补齐 4/8] 人事全生命周期表单组 — 入转调离+考勤+社保 6模板 | Sprint-2 | backend |
| #3171 | [流程补齐 5/8] 行政服务表单组 — 资产/车辆/证照/名片/钥匙 5模板 | Sprint-2 | backend |
| #3172 | [流程补齐 6/8] 质量管理表单组 — 质检/不合格/纠正措施/供应商/客诉 5模板 | Sprint-2 | backend |
| #3173 | [流程补齐 7/8] 印章/运营/国贸表单组 — 用印/仓储/单证 6模板 | Sprint-2 | backend |

### biz:crm（9 个，候选 Master: #4045 / #4022 / #4021 / #4013，原型: crm-商务中心/ (也可选 crm-商务工作台/ crm-商机详情页/ 询盘报价体系/ 线索商机架构统一/)）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #2806 | [13/25] 回复智能分类+CRM商机自动创建 | Sprint-Backlog | backend |
| #2809 | [16/25] 企微自动标签+客户画像同步CRM | Sprint-Backlog | backend |
| #2816 | [23/25] 线索评分增强：邮件+企微+LinkedIn多渠道信号融合 | Sprint-Backlog | backend |
| #2818 | [25/25] 营销-销售自动移交：评分达标→通知→商机→分配 | Sprint-Backlog | backend |
| #3104 | PI(形式发票)生成+PDF导出 — 国贸专用，从报价一键转PI | - | fullstack |
| #3106 | 发货管理（国贸专用） — 装箱单+报关+海运空运跟踪 | - | fullstack |
| #3107 | 出口单据管理 — CI/PL/BL/CO/FormE自动生成+归档 | - | fullstack |
| #3109 | 客户信用额度管理 — 授信+在途应收+超额预警（经销+国贸通用） | - | fullstack |
| #3111 | 汇率管理+利润自动计算 — 报价锁汇+收款汇率+损益（国贸专用） | - | backend |

### biz:plm（2 个，候选 Master: #4024，原型: ptc/）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #3392 | [PLM][15/20][P1] 版本化定价引擎API — 价格锚定BOM版本 + 利润红线校验(联动D70) + 版本 | - | backend |
| #3393 | [PLM][16/20][P1] 供应商价格联动 — 报价变动自动更新Part Master + BOM成本重算 + 企 | - | backend |

### biz:cockpit（1 个，候选 Master: #4041 / #4020，原型: 超管驾驶舱/ (也可选 耀总驾驶舱/)）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #2615 | [2/4] PageGuide 数据配置文件 — 全页面说明内容 | Sprint-Backlog | frontend |

### biz:ptc（1 个，候选 Master: #4024，原型: ptc/）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #2316 | [产品平台][P0] D3 Web产品目录浏览器前端 — 42品类在线浏览+产品详情 | - | frontend |

### biz:rbac（1 个，候选 Master: #4046，原型: rbac-homepage/）

| # | 标题 | Sprint | Module |
|---|------|--------|--------|
| #1770 | [统一权限管理] 新增权限管理页面 — 用户管理 + 部门管理 + 模块注册 + 操作日志 | Sprint-5 | frontend |

## B 档：需先补原型的业务域（~206 个）

这些 biz 域尚无原型目录，需走完整原型流程后再补 Issue 引用。

| biz 域 | Issue 数 | Sprint 分布 | 对应全景图 | 建议 |
|--------|---------|-------------|-----------|------|
| biz:intelligence-hub | 66 | Sprint-Backlog:66 | #34 商战情报中台 7Phase | 规划7个原型页（对应7Phase） |
| biz:collab | 24 | Sprint-3:14, Sprint-Backlog:5, Sprint-2:2 | #6 协同修改 | 已有后端58个Java，需补前端原型 |
| biz:brand-center | 21 | Sprint-4:10, Sprint-Backlog:6, Sprint-3:5 | #5 品牌中心 Phase1-4 | 规划原型 |
| biz:outreach | 17 | Sprint-Backlog:17 | #36 外展获客 | 规划5Phase原型 |
| biz:data-pipeline | 13 | Sprint-1:13 | #45 S3数据管线 | 已在超管驾驶舱有入口，可能复用 |
| biz:project-plan | 12 | -:12 | #43 项目计划管理 | 需原型 |
| biz:customer-lifecycle | 11 | Sprint-3:11 | #35 客户生命周期 | 6大引擎原型 |
| biz:sample | 11 | Sprint-Backlog:11 | #26 样品管理 | 需原型 |
| biz:h5-mobile | 7 | Sprint-Backlog:7 | H5适配 | 待评估 |
| biz:marketing-automation | 3 | Sprint-Backlog:3 | #36 外展获客子项 | 合并到outreach原型 |
| biz:after-sales | 3 | Sprint-3:3 | #12 质保售后 | 需原型 |
| biz:change | 2 | Sprint-1:1, Sprint-4:1 | #6子项 变更管理 | 归并到审批体系原型 |
| biz:rectification | 1 | Sprint-5:1 | 整改 | 已在原型对账范畴 |
| biz:acceptance | 1 | Sprint-2:1 | 验收 | 需评估 |

## C 档：无 biz 标签的 Issue（424 个）

这批 Issue 连业务归属都没有，建议先按标题关键词分类归域，再进入 A/B 档处理。

### 按关键词自动归类

| 建议biz | Issue数 | 说明 |
|---------|---------|------|
| biz:crm | 57 | → A档 回填引用 |
| biz:project | 54 | → A档 回填引用 |
| biz:design-ai | 39 | → B档 先补原型 |
| biz:d3-parametric | 38 | → B档 先补原型 |
| biz:approval | 31 | → A档 回填引用 |
| biz:brand-center | 31 | → B档 先补原型 |
| biz:wechat | 18 | → B档 先补原型 |
| biz:budget | 11 | → B档 先补原型 |
| biz:rbac | 11 | → A档 回填引用 |
| biz:knowledge | 10 | → B档 先补原型 |
| biz:test | 5 | → B档 先补原型 |
| biz:plm | 4 | → A档 回填引用 |
| biz:sample | 4 | → B档 先补原型 |
| biz:mobile | 3 | → B档 先补原型 |
| biz:auth | 3 | → B档 先补原型 |
| **无法自动分类** | 96 | 需人工审阅标题 |

### 无法自动分类的 Issue 样本（前30）

| # | 标题 | Sprint |
|---|------|--------|
| #1573 | [22/22] 制度智能问答API | Sprint-Backlog |
| #1594 | [19/32] 借款逾期提醒+工资扣除预警 | Sprint-Backlog |
| #1597 | [16/32] 员工借款额度校验Service | Sprint-Backlog |
| #1599 | [14/32] 采购比价强制校验 | Sprint-Backlog |
| #1611 | [17/18][P2] 消息线程化与兴趣匹配 — 话题追踪+主动提醒 | Sprint-Backlog |
| #1612 | [16/18][P2] 业务场景自动分类引擎 — 群聊智能识别 | Sprint-Backlog |
| #1613 | [14/18][P1] 数据安全分级与访问控制 — L1/L2/L3三级防护 | Sprint-Backlog |
| #1614 | [13/18][P1] PII自动脱敏服务 — 隐私保护引擎 | Sprint-Backlog |
| #1616 | [10/18][P1] 每日群聊摘要服务 — 定时+即时双模式 | Sprint-Backlog |
| #1617 | [9/18][P1] 群聊上下文双层隔离 — 群共享+个人私有分离 | Sprint-Backlog |
| #1618 | [8/18][P1] @触发与关键词路由 — 群聊精准响应机制 | Sprint-Backlog |
| #1619 | [7/18][P0] 群信息同步与群成员管理 — 群聊AI配置基础 | Sprint-Backlog |
| #1680 | [AI 生成] 新增体育设施风格 LoRA 训练 | Sprint-3 |
| #1682 | [AI 生成] 新增图像生成 API 服务 | Sprint-3 |
| #1698 | [提成绩效] 新增提成计算引擎 API — 阶梯计算 + 绩效系数 + 批量计算 | Sprint-4 |
| #1702 | [质保售后] 新增设备台账 API — 设备管理 + 二维码 + 维修履历 | Sprint-5 |
| #1719 | [提成绩效] 新增绩效仪表盘 + 三级看板 + 趋势分析 | Sprint-4 |
| #1722 | [提成绩效] 新增管理费分摊 + 绩效考核页面 — 费用录入 + 打分 + 结果看板 | Sprint-4 |
| #1738 | [质保] 新增售后数据大盘页面 — KPI 看板 + 7 个图表 | Sprint-5 |
| #1766 | [代理商工作台] 前端管理页面 — 五阶段管线 + 看板 + 列表 | Sprint-5 |
| #1768 | [AI 中枢] Web 聊天气泡 — 右下角悬浮窗+Markdown 渲染 + 对话历史 | Sprint-Backlog |
| #1794 | [导航] 启用方案设计入口 + 新增图图功能导航 | Sprint-3 |
| #1834 | [设计模块-P1][33/35] AI环境自动填充 — 白模/实景→AI补树木/建筑/道路/人物/天空 | Sprint-3 |
| #1835 | [设计模块-P1][32/35] 环境模板库 — 10+预制场景(城市公园/社区/学校等)+一键套用 | Sprint-3 |
| #1849 | [设计模块-P0][1/30] 意图路由API — 用户输入→自动分发到对应设计子模块 | Sprint-3 |
| #1873 | [P1][27/38] 分级超时升级机制（48h→72h→5天） | Sprint-Backlog |
| #1875 | [P1][16/38] 赢/输复盘模板 + 系统化采集 | Sprint-2 |
| #1944 | [工具中心-P0][4/10] 种子数据：4个工具初始化入库 | Sprint-Backlog |
| #2000 | [资金闭环-P2] Phase6 [16/17]: 财务预警引擎 — 应收逾期+应付到期+毛利异常+现金流预警 | Sprint-4 |
| #2003 | [资金闭环-P1] Phase5 [12/17]: 经营分析数据聚合API — 收入/成本/毛利/现金流多维分析 | Sprint-4 |

## 处置建议（执行路线）

### 阶段一：立即执行（本次会话）
- [x] Skill 升级到 v5.1，新增 §5.6 历史清理 SOP
- [x] 生成本对账报告
- [ ] 创建 `needs-prototype` 标签
- [ ] A 档 43 个 Issue 批量回填三重引用（按 biz 分批）

### 阶段二：分 biz 域清理（后续会话）
按业务域逐个清理，顺序建议按 Sprint 优先级：
- **Sprint-1 里的无原型 Issue（51 个）**：最紧急，先处理
  - biz:data-pipeline（13）：S3 管线原型
  - biz:approval / biz:change（审批+变更 10+4）：审批体系已有原型，部分可回填
  - 其他 Sprint-1 无 biz 标签的 41 个：人工归域
- **Sprint-2/3 的 Issue**：按业务域出原型后批量转规范
- **Sprint-Backlog 的 246 个**：全部加 `needs-prototype` 冻结，避免误捡

### 阶段三：防再次发生
- wande-org skill 新增 Issue 创建预检：必须含三重引用字段
- GitHub Actions 每日扫描，无引用的 Issue 自动打 `needs-prototype` 标签并评论

## 附录 A：对账数据文件
- 原始 Issue 清单: `open_issues.json`（750 条）
- 已分类数据: `issues_classified.json`
- 无原型引用清单: `issues_no_proto.json`（642 条）
---

## 执行进度更新（2026-04-21 23:50）

### ✅ 已完成

**A 档（41 个）**：
- 34 个回填三重引用（18 project→执行管理§2.x / 9 approval / 5 crm / 1 product-portal / 2 ptc）
- 6 个 REJECT 改分域：4 #2806/2809/2816/2818 去 biz:crm + 加 needs-prototype / 1 #2615 去 biz:cockpit / 1 #1770 保留 biz:rbac + 加 needs-prototype
- 1 个跳过（#3161 已有引用）

**C 档（41/415 处理）**：
| biz 域 | 处置数 | 动作 |
|--------|--------|------|
| mobile | 3 | close as not planned（已废弃移动端方案） |
| auth | 3 | close as not planned（重复/过时） |
| test | 5 | close as not planned（测试基建豁免 needs-prototype，已登记 skill §5.6）|
| sample | 4 | 加 biz:sample + needs-prototype（等待样品管理原型）|
| plm | 3 | 改标 biz:budget + 加 needs-prototype |
| #2118 | 1 | 回填到执行管理原型 |
| rbac | 11 | 精确分域（3 asset-library + 1 sample + 4 rbac + 2 hr + 1 #1615 wechat）|
| knowledge | 10 | close as not planned（知识库模块已废弃重构）|

**新建标签**: `needs-prototype` #fbca04 / `biz:budget` #5319e7 / `biz:asset-library` #5319e7 / `biz:wechat` #1d76db

**产出**：
- wande-prototype skill v5.0→v5.1 新增 §5.6 历史清理 SOP
- `.github/docs/status.md` 新增 D92 决策
- `.github/docs/issue-prototype-audit.md`（本文件）

### ⏳ 剩余待处理

**C 档剩余 374 个**（按 biz 域）：
| biz 域 | Issue 数 | 初步策略 |
|--------|---------|---------|
| crm | 57 | 最大域，需区分国贸/直销，有原型可回填多数 |
| project | 54 | 多数可回填到执行管理/矿场原型 |
| design-ai | 39 | 设计AI原型未建 → 多数 needs-prototype |
| d3-parametric | 38 | D3业务线，原型未建 → needs-prototype |
| approval | 31 | 审批原型已建，多数可回填 §2.x |
| brand-center | 31 | 原型未建 → needs-prototype |
| wechat | 18 | 企微集成，分域到具体场景 |
| budget | 8 | D71预算未建原型 → needs-prototype |
| uncategorized | 96 | 无法自动分类，需逐个判断 |

**B 档 424 个**：无 biz 标签 Issue，需按标题关键词归域后再分 A/B/C 档。

