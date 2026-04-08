# Sprint-1 完整排程计划

> 最后更新：2026-04-08 06:10 UTC（pg-test 20/20 全部DONE，恢复业务指派；看板状态批量修正）
> 并发上限：**15个CC** | 数据来源：`/tmp/issue-cache/` 批量离线分析
> 排程前：`bash scripts/prefetch-issues.sh <issues>` 预写 dev | Jump状态Issue最优先
> **Jump队列**：已处理 → #2950/#3226/#3237 已标 Todo | **2026-04-07 12:35 批量处理7个BUG Jump**：#3227/#3228/#3229/#3230/#3231/#3232/#3234 — 全部标Todo
> **2026-04-07 16:35 全量依赖分析**：#1806(执行看板P0,用户指示) | 9个Plan→Todo：#1678(#2047解锁)/#2276(#1572解锁)/#1504/#1510/#1511/#1695/#1696/#2116/#2401（依赖已就绪） | #2076/#2589已在Todo

## Tier-1：矿场 / 投标 / 项目中心

> 说明：`启动` = ✅立即/⏳等前置/🚫被阻塞

### 1. 矿场增强系列 [N/23]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置条件 |
|-------|------|------|------|------|---------|
| #2257 | P0 | fullstack | [2/23] 反馈按钮结构化表单 | 运行中 | — |
| #2407 | P0 | pipeline | [3/23] 反馈评分模型校准 | 运行中 | — |
| #1533 | P1 | backend | [4/23] 反馈统计API | ✅ | [1/23]CLOSED |
| #2256 | P0 | frontend | [6/23] 矿场列表状态筛选+流转 | ✅ | [5/23]CLOSED（backend#963即[5/23]已完成） |
| #1532 | P1 | backend | [7/23] 矿场转化漏斗统计API | ✅ | 无明确依赖 |
| #2255 | P1 | frontend | [8/23] 转化漏斗看板页面 | ⏳ | 等#1532[7/23] |
| #1531 | P1 | backend | [9/23] 可赢性评分模型(WinProb) | ✅ | 无明确依赖 |
| #2254 | P1 | frontend | [10/23] 可赢性评分展示+Go/No-Go | ⏳ | 等#1531[9/23] |
| #2406 | P1 | pipeline | [11/23] 信号衰减定时任务 | 运行中(kimi12) | 无明确依赖 |
| #1529 | P1 | backend | [17/23] 企微H5轻量接口 | 运行中(kimi15) | 无明确依赖 |
| #2253 | P1 | frontend | [18/23] 企微H5矿场页面 | ⏳ | 等#1529[17/23] |
| #1528 | P1 | backend | [19/23] 线索来源转化率统计API | ✅ | 无明确依赖 |
| #2252 | P1 | frontend | [20/23] 来源ROI看板 | ⏳ | 等#1528[19/23] |
| #1527 | P1 | backend | [21/23] 甲方历史合作查询接口 | ✅ | 无明确依赖 |
| #2405 | P1 | backend | [22/23] 关系加分逻辑 | ✅ | 无明确依赖 |

> **并行策略**：backend系([1533][1532][1531][1529][1528][1527][2405][2406])无文件冲突，可同时启动多个；frontend等对应backend完成后批量启动

---

### 2. 矿场-Phase2 客户关系系列 [N/16]

| Issue | 优先 | 模块 | 内容 | 启动 | 顺序说明 |
|-------|------|------|------|------|---------|
| #1511 | P1 | backend | [1/16] 客户画像扩展字段 | ✅ | 最小序号，先做 |
| #2403 | P1 | pipeline | [2/16] 企业工商数据采集 | ✅ | pipeline独立 |
| #2242 | P1 | frontend | [3/16] 客户360画像详情页 | ⏳ | 等#1511[1/16]数据 |
| #1510 | P1 | backend | [4/16] 项目-客户角色关联表 | ✅ | DB层，先做 |
| #2402 | P1 | pipeline | [5/16] 项目角色自动识别NLP | ✅ | pipeline独立 |
| #1509 | P1 | backend | [6/16] 关系快照API | ⏳ | 等#1510[4/16]表存在 |
| #2241 | P1 | frontend | [7/16] 项目详情关系地图 | ⏳ | 等#1509[6/16] |
| #1508 | P1 | backend | [8/16] 决策链联系人角色标签 | ⏳ | 等#1510[4/16] |
| #2240 | P1 | frontend | [9/16] 决策链可视化组件 | ⏳ | 等#1508[8/16] |
| #2401 | P1 | pipeline | [10/16] 政策信号采集器 | ✅ | pipeline独立 |
| #1507 | P1 | backend | [11/16] 政策信号关联推送 | ⏳ | 等#2401[10/16] |
| #2239 | P1 | fullstack | [12/16] 政策信号Feed页 | ⏳ | 等#1507[11/16] |
| #1506 | P1 | backend | [13/16] 作战资料包聚合API | ⏳ | 等多个前序完成 |
| #2400 | P1 | pipeline | [14/16] G7e联系人自动提取 | ✅ | pipeline独立 |
| #2238 | P1 | frontend | [15/16] 作战资料包一页纸展示 | ⏳ | 等#1506[13/16] |
| #1505 | P1 | backend | [16/16] 阶段话术模板库 | ✅ | 无依赖 |

> **立即可启动**：#1511, #2403, #1510, #2402, #2401, #2400, #1505（7个，backend+pipeline并行）

---

### 3. 矿场-Phase3 赢率/BI系列 [N/12]

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #1504 | P1 | backend | [1/12] 赢率预测特征工程 | ✅ |
| #2399 | P1 | pipeline | [2/12] 赢率预测模型训练Pipeline | ✅ |
| #2237 | P1 | backend | [4/12] 项目列表赢率列排序 | ✅ | #2399 Done 解锁 |

---

### 4. 矿场-Phase4 NBO/经销商系列 [N/17]

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #1492 | P1 | backend | [14/17] 跟进超时提醒 | ✅ |
| #2228 | P1 | frontend | [13/17] 管理看板-团队活动量 | ✅ |

---

### 5. AI生成 / 投标方案

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2047 | P0 | backend | Phase1: ComfyUI基础设施 | ✅ | 独立 |
| #2046 | P0 | pipeline | Phase4: 投标知识库增强(S3→RAG) | ✅ | 独立，与#2047并行 |
| #2206 | P0 | backend | 投标方案生成引擎 FastAPI+RAG | IP | 独立新服务 |
| #1678 | P1 | backend | 投标方案配图自动生成 | ⏳ | 等#2047 ComfyUI |
| #1788 | P1 | frontend | AI内容生成工作台页面 | ⏳ | 等#2046+#2206 |
| #2045 | P1 | backend | Phase7: 方案配图自动生成 | ⏳ | 等#2047+Phase4 |

---

### 6. 质保售后系列（Java轨）

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2159 | P0 | backend | 创建12张表+Alembic迁移 | ✅ | platform全CLOSED |
| #2107 | P0 | backend | 备件管理API | ✅ | platform#1225 CLOSED |
| #2108 | P0 | backend | 外包维修商管理API | ✅ | platform#1225 CLOSED |
| #2109 | P0 | backend | 售后工单API | ✅ | platform#1225 CLOSED |
| #2110 | P0 | backend | 质保台账API | ✅ | platform#1225 CLOSED |
| #2106 | P0 | backend | 备件消耗关联工单 | ✅ | platform#1227#1230 CLOSED |
| #1724 | P0 | frontend | 设备台账页面 | ⏳ | 等#2110完成 |
| #2372 | P0 | frontend | Phase11-A: 售后工单管理主页面 | ⏳ | 等#2109完成 |
| #2373 | P0 | frontend | Phase9-C: H5客户报修页面 | ⏳ | 等#2109完成 |
| #1740 | P1 | frontend | 备件库存管理页面 | ⏳ | 等#2107完成 |
| #1742 | P1 | frontend | 质保台账管理页面 | ⏳ | 等#2110完成 |
| #1744 | P1 | frontend | 质保台账管理页面(v2) | ⏳ | 等#2110完成 |
| #1746 | P1 | frontend | 售后工单管理主页面 | ⏳ | 等#2109完成 |
| #2104 | P1 | backend | 客户满意度评价API | ✅ | platform全CLOSED |
| #2105 | P1 | backend | 成本核算API | ✅ | platform全CLOSED |

> **立即可启动**：#2159、#2107、#2108、#2109、#2110、#2106、#2104、#2105（8个P0/P1，建表完成后APIs全解锁）

---

### 7. 合同管理系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2461 | P0 | backend | 创建合同管理数据表 | ✅ | 无依赖 |
| #2112 | P1 | backend | AI合同风险分析引擎 | ✅ | 无明确依赖 |
| #2111 | P1 | backend | AI条款对比引擎 | ✅ | 无明确依赖 |
| #2113 | P1 | backend | 合同审批流程 | ✅ | platform#1098 CLOSED |
| #2458 | P1 | backend | AI条款对比引擎(Python) | ✅ | 无明确依赖 |
| #2459 | P1 | backend | 合同审批API(Python) | ✅ | 无明确依赖 |
| #1796 | P1 | frontend | 合同审批流程页面 | ✅ | 无明确依赖 |
| #1750 | P1 | frontend | AI条款对比前端 | ⏳ | 等#2111 |
| #1752 | P1 | frontend | 合同审批前端 | ⏳ | 等#2113 |

---

### 8. 提成绩效系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1700 | P0 | backend | 创建提成绩效5张表 | ✅ | platform#1089#1161#1214 全CLOSED |
| #1695 | P1 | backend | 绩效考核API | ✅ | platform#1286#1288 CLOSED |
| #1696 | P1 | backend | 管理费分摊API | ✅ | platform#1286#1288 CLOSED |
| #1722 | P1 | frontend | 管理费分摊+绩效考核页面 | ⏳ | 等#1695+#1696 |
| #1828 | P1 | frontend | 提成规则配置页面 | ✅ | 无明确依赖 |

---

### 9. 代理商工作台系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2116 | P1 | backend | 数据模型+API+统计 | ✅ | platform全CLOSED |
| #2131 | P1 | backend | 数据模型+API+评分引擎 | ✅ | platform全CLOSED |
| #1756 | P1 | frontend | 前端看板+列表视图 | ⏳ | 等#2116 |
| #1766 | P1 | frontend | 前端管线+五阶段看板 | ⏳ | 等#2131 |
| #1726 | P1 | frontend | 代理商管理页面 | ⏳ | 等#2116 |

---

### 10. 项目中心系列 [Phase N/22]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2471 | P0 | backend | Phase13: project_risk_events等6张表 | ✅ | 无blocker |
| #2363 | P0 | frontend | Phase8: 项目中心菜单+列表页 | ✅ | backend#380 CLOSED |
| #2009 | P1 | backend | Phase7: 项目全景API | ✅ | 无依赖 |
| #2012 | P1 | backend | Phase4: 跨部门任务Service | ✅ | 无依赖 |
| #2011 | P1 | backend | Phase5: 设计变更联动 | ✅ | platform#1030 CLOSED |
| #2359 | P1 | backend | Phase12: 菜单权限SQL | ✅ | 无依赖 |
| #240 | P1 | backend | Phase6: 项目费用归集 | 🚫 | 需确认依赖状态 |
| #2362 | P0 | frontend | Phase9: 项目详情全景页 | ⏳ | 等#2363 Phase8 |
| #2361 | P1 | frontend | Phase10: 项目任务面板 | ⏳ | 等#2012 Phase4 |
| #2360 | P1 | frontend | Phase11: 设计变更通知页面 | ⏳ | 等#2011 Phase5 |
| #1994 | P0 | backend | Phase15: 风险事件API | ⏳ | 等#2471 Phase13 |
| #1993 | P1 | backend | Phase16: 健康度评分引擎 | ⏳ | 等#2471+#2009 |
| #1992 | P1 | backend | Phase17: 经验卡片Service | ⏳ | 等#2471+#2011 |
| #1991 | P1 | backend | Phase18: 经验卡片API | ⏳ | 等#1992 |
| #2352 | P0 | frontend | Phase20: 风险台账Tab | ⏳ | 等#1994+#2113(合同) |
| #2351 | P1 | frontend | Phase21: 健康度灯+拦截弹窗 | ⏳ | 等#1993 |
| #2350 | P1 | frontend | Phase22: 经验库页面 | ⏳ | 等#1991 |

---

### 11. 整改工单系列 [Phase N/30]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1634 | P0 | backend | Phase23: DB 4张表+种子数据 | 运行中 | — |
| #1630 | P0 | backend | Phase27: 整改工单API | ✅ | 等#1634完成 |
| #2304 | P0 | frontend | 工艺标准卡管理页面 | ✅ | #1632(Phase25 Service) CLOSED |
| #2301 | P0 | frontend | 工人端H5页面(企微内嵌) | ⏳ | 等#1630 Phase27 |
| #2303 | P0 | frontend | 整改工单列表+看板页面 | ⏳ | 等#1630 Phase27 |
| #2302 | P0 | frontend | 整改工单详情页 | ⏳ | 等#1630 Phase27 |
| #1626 | P1 | backend | 工艺标准卡导入API | ✅ | #1632 CLOSED |
| #1628 | P1 | backend | Phase29: AI视觉审查Service | ⏳ | 等#1630 API完成 |
| #1627 | P1 | backend | Phase30: 风险台账联动 | ⏳ | 等#1628 |
| #2299 | P1 | frontend | 整改统计仪表盘 | ⏳ | 等#2303 |
| #2300 | P1 | frontend | AI审查结果展示 | ⏳ | 等#1628 |

---

### 12. 其他矿场相关

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #1876 | P0 | backend | 商务48小时反馈机制+分级升级 | ✅ |
| #2028 | P1 | backend | 项目信息变更增量同步推送 | ✅ |
| #2096 | P1 | backend | 执行管理整改工单管理API | ✅ |
| #1734 | P1 | backend | 执行管理整改工单跟踪页 | ✅ |
| #2225 | P1 | frontend | 矿场验证[5/5] 信息验证质量仪表盘 | ✅ |
| #2391 | P1 | pipeline | 矿场验证[4/5] L1源头可信度评分 | ✅ |
| #2243 | P1 | frontend | Phase1[13/13] 简报偏好设置页 | ✅ |
| #2438 | P1 | backend | [20/38] 投标人名单提取 | ✅ |
| #2443 | P1 | backend | [14/38] ICP画像构建 | ✅ |
| #1492 | P1 | backend | Phase4[14/17] 跟进超时提醒 | ✅ |
| #2368 | P0 | frontend | 菜单重组[5/8] 综合管理中心板块 | ✅ |
| #1672 | P1 | backend | 商务赋能Phase3[4/13] 直销投标文档API | ✅ |
| #1715 | P1 | frontend | 商务赋能Phase3[10/13] 直销投标文档页面 | ⏳ | 等#1672 |

---

### 13. 企微打通系列 [N/17]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1564 | P0 | backend | [1/17] WecomAppService — access_token管理+消息发送SDK | ✅ | 本系列根节点，独立 |
| #1557 | P0 | backend | [6/17] 企微→平台通讯录同步 — 回调事件+增量+全量对账 | ⏳ | 等#1564 |
| #1554 | P1 | backend | [9/17] H5移动端适配API — JS-SDK签名+jsapi_ticket缓存 | ⏳ | 等#1564 |
| #1610 | P0 | backend | 企微会话存档服务开通（阻塞项） | 🚫 | 人工操作，非开发任务 |
| #1622 | P0 | backend | [3/18] ChannelAdapter — 统一核心+多渠道格式化 | ⏳ | 等前置完成（需确认） |
| #1623 | P0 | backend | [2/18] 统一对话日志表 conversation_log | ⏳ | 等前置完成（需确认） |
| #1625 | P1 | backend | 企微消息模板 — 整改通知/超时预警/验收结果 | ⏳ | 等整改工单Service完成 |

> **并行策略**：#1564 立即启动。#1557、#1554 依赖#1564，#1564完成后并行启动。#1610为人工配置，不指派CC。

---

### 14. 销售记录体系 [N/16]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1465 | P0 | backend | [1/9] 销售记录聚合引擎 — 流程事件自动写入activity_logs | ✅ | 独立，系列根节点 |
| #1464 | P1 | backend | [2/9] 里程碑门控配置 — 阶段推进前必填字段校验 | ✅ | 独立建表 |
| #1463 | P1 | backend | [3/9] 智能提醒频率引擎 — 按项目状态差异化更新周期 | ⏳ | 等#1465[1/9] |
| #1461 | P0 | backend | [7/9] 老板Nudge API — 指定项目催更新+企微推送 | ⏳ | 等#1465[1/9] |
| #1459 | P0 | backend | [10/16] 记录中心统一数据模型 — 多维关联查询API | ✅ | 独立数据模型 |
| #1458 | P0 | backend | [12/16] 商务周报提交API — 四区块模板+自动预填+周四提醒 | ⏳ | 等#1459[10/16] |
| #2212 | P0 | frontend | [8/9] 项目详情页看板周报+Nudge时间线 | ⏳ | 等#1461[7/9] |
| #2211 | P0 | backend | [11/16] 记录中心前端 — 四视角切换 | ⏳ | 等#1459[10/16]就绪 |
| #2210 | P0 | frontend | [14/16] 商务周报月报填写页+管理层审阅+企微H5 | ⏳ | 等#1458[12/16] |

> **并行策略**：#1465、#1464、#1459 可三路并行（不同文件）。后续按序解锁下游。

---

### 15. 执行管理系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2156 | P0 | backend | 变更单核心API — CRUD+状态机+三级审批流 | ✅ | 独立 |
| #2124 | P0 | backend | 回款计划与管理API — 分期计划+实际回款+逾期 | ✅ | 独立 |
| #2098 | P0 | backend | 验收核心API — 阶段管理+检查项评分+状态机 | ✅ | 独立 |
| #2467 | P0 | backend | BOM管理API — 多级树形+Excel导入+审核定价 | ✅ | 独立 |
| #2468 | P0 | backend | 图纸管理API — 上传/版本控制/审批/下发工厂 | ✅ | 独立 |
| #2465 | P1 | backend | 生产进度/质检/发货/安装API | ✅ | 独立 |
| #2183 | P1 | backend | 扩展角色权限 — tech_coordinator+install_manager | ✅ | 独立 |
| #2120 | P1 | backend | AI项目进度智能跟踪 — 停滞检测+瓶颈分析+到期提醒 | ✅ | 独立 |
| #2119 | P2 | backend | 经销模式支持 — 阶段配置+经销商结算+门户API | ✅ | 独立 |
| #2086 | P0 | backend | 变更影响联动API — BOM差异+成本+工期 | ⏳ | 等#2156完成 |
| #2095 | P1 | backend | 验收附件管理API — 照片+签字+MinIO | ⏳ | 等#2098完成 |
| #2096 | P1 | backend | 整改工单管理API — 责任人指派+复验流程 | ⏳ | 等#2098完成 |
| #2094 | P2 | backend | 验收模块联动 — 触发质保+回款+BOM对照 | ⏳ | 等#2098+#2124 |
| #2122 | P0 | backend | AI回款风险预警 — 智能分析+企微推送+三级预警 | ⏳ | 等#2124完成 |
| #2384 | P0 | frontend | 流程配置可视化页面 — 阶段拖拽+字段+审批规则 | ✅ | #2074(阶段流程配置引擎API) CLOSED ✅ |
| #2387 | P0 | backend | 利润预估页面+商机详情Tab | 🚫 | blocked，等platform依赖 |
| #2589 | P1 | fullstack | 执行管理45个API前端对接 | ⏳ | 等接口契约#2586就绪 |
| #2093 | P3 | backend | AI增强验收 — 智能检查清单+报告+智能派单 | ✅ | 独立 |
| #2118 | P3 | fullstack | AI BOM智能推荐 — 历史学习+智能匹配+价格估算 | ✅ | 独立 |

> **并行策略**：第一批6路并行：#2156+#2124+#2098+#2467+#2468+#2384（不同文件）。第二批依赖第一批。#2387暂缓。

---

### 16. 回款管理

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2354 | P0 | frontend | [6/8] 回款周报前端 — 商务填报+财务评估+管理层审阅 | ⏳ | 等后端回款周报API就绪（需确认） |

---

### 17. 审批引擎 [N/10]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2026 | P0 | backend | [3/10] 审批引擎核心 — 发起/审批/驳回/撤回/加签+4种审批人规则 | ✅ | 独立（核心引擎） |
| #2366 | P0 | frontend | [8/10] 审批中心页面 — 我的待办/已办/发起 | ⏳ | 等#2026完成 |

---

### 18. D3-材质标注系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1560 | P0 | backend | [1/4] 构件-材料绑定规则Service — 构件类型→默认材料+允许范围 | ✅ | 独立Service层 |
| #1558 | P0 | backend | [2/4] 材质标注API — 单个/批量标注+历史+冲突检测 | ⏳ | 等#1560[1/4]完成 |
| #2271 | P0 | frontend | [1/2] D3 Web材质标注面板 — 构件选中→右侧面板+色块+3D预览 | ⏳ | 等#1558[2/4]完成 |
| #2268 | P1 | backend | [2/2] 批量智能标注 — 同类构件一键统一+标注模板 | ⏳ | 等#1558完成 |
| #2264 | P1 | backend | 知识卡 — 标注时侧边栏知识卡+首次小测验+学习进度 | ⏳ | 等#1558完成 |

> **串行链**：#1560 → #1558 → #2271（前后端串行）；#2268/#2264 等#1558完成后并行。

---

### 19. D3-AI系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2477 | P1 | pipeline | [1/3] ComfyUI渲染Pipeline搭建 — 模型下载+工作流配置 | ✅ | 独立，先做 |
| #2479 | P1 | backend | [3/3] 账号池AI渲染集成 — 多平台API封装+统一调度 | ⏳ | 等#2477[1/3]完成 |
| #2482 | P2 | backend | GH侧AI按钮 — AI建模助手+AI变体生成按钮封装 | ⏳ | 等#2477完成 |

---

### 20. D3-优化系列 [N/10]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2042 | P0 | backend | [3/10] 局部替换+增量重算 — 设计师修改效率核心 | ✅ | 最低序号，独立 |
| #2041 | P1 | backend | [5/10] 场地地形集成 — DEM高程数据与设计联动 | ✅ | 独立 |
| #2040 | P1 | backend | [6/10] 无障碍合规自动检测 — ADA/DDA/GB全标准覆盖 | ✅ | 独立 |
| #2039 | P1 | backend | [7/10] 方案变体管理+版本回溯 — 多版本方案并行 | ✅ | 独立 |
| #2038 | P1 | backend | [8/10] 配色方案系统 — 颜色选择联动BOM材料编号 | ✅ | 独立 |

> **并行策略**：5个Issues不同文件，可全部并行启动。

---

### 21. D3-参数化系列

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2055 | P0 | backend | 扣件管理Web后台 — 扣件CRUD+连接规则维护 | ✅ | 独立 |
| #2065 | P0 | backend | 市场配置预设 — 中/国际/北美/东南亚/欧盟双轨 | ✅ | 独立 |
| #2051 | P1 | frontend | D3-周期5-G: L4安装图自动化 — 基础条件+安装工序 | ✅ | 独立 |
| #2054 | P0 | backend | 产品编码体系重新设计 — 编码规则+生成器 | ⏳ | 需胡总确认编码规则后启动 |
| #2053 | P1 | frontend | GH功能件选择器插件(ComponentPicker) | ⏳ | 等功能件模型库归集完成 |
| #2052 | P1 | backend | 高频功能件参数化改造计划 — 首批10个核心件 | ⏳ | 等功能件模型库确认 |

---

### 22. 采集/竞品Pipeline（Agent基建 [N/7]）

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2452 | P0 | pipeline | [4/38] 竞品中标公告定向采集管线 | ✅ | 独立 |
| #2453 | P0 | backend | [3/38] 历史甲方定向监控清单 | ✅ | 独立 |
| #2446 | P0 | pipeline | [11/38] 政策信号采集管线 — 六层信号源第一层 | ✅ | 独立 |
| #2445 | P0 | pipeline | [12/38] 锁定100个儿童友好+50个体育公园重点城市监控 | ✅ | 独立 |
| #2424 | P0 | pipeline | [3/7] browser_client.py — Browser Agent统一封装 | ✅ | 独立 |
| #2443 | P1 | backend | [14/38] ICP画像构建 → 矿场评分模型校准 | ✅ | 独立分析模块 |
| #2450 | P0 | pipeline | [6/38] 竞品甲方提取 → 万德潜在客户监控清单 | ⏳ | 等#2452[4/38]完成 |
| #2423 | P0 | pipeline | [4/7] agent_base.py — Agent基类 | ⏳ | 等#2424完成 |

> **并行策略**：第一批5路并行：#2452+#2453+#2446+#2445+#2424（独立脚本文件）。

---

### 23. BUG修复

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #1648 | P0 | backend | Collab模块Mapper XML类路径错误导致服务启动失败 | ✅ |
| #2208 | — | backend | 25个Mapper XML映射文件全部缺失 | ✅ |
| #2388 | — | frontend | 12个Vue文件缺少ref导入+任务调度字段不匹配 | ✅ |
| #2585 | P0 | backend | refactor: 合并wande-ai-api到wande-ai，消除42个重复类冲突 | ✅（建议单独串行） |

> **注意**：#2585 重构范围覆盖多模块，建议单独一个kimi目录串行执行，完成后所有kimi目录`git pull`。

---

## Tier-2：超管驾驶舱（Tier-1 P0 全部完成后新槽位才分配）

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #1572 | P0 | backend | 采集管控[3/4] 漏斗API | 运行中 | — |
| #1567 | P0 | backend | 错误分析中心[2/6] 错误采集Service | 运行中 | — |
| #2409 | P0 | pipeline | 采集管控[1/4] wdpp_pipeline_runs表+run_reporter.py | ✅ | 独立 |
| #2408 | P0 | pipeline | 采集管控[2/4] 13脚本接run_reporter | ⏳ | 等#2409完成 |
| #2276 | P0 | frontend | 采集管控[4/4] 管控面板页面 | ⏳ | 等#1572完成 |
| #2076 | P0 | backend | 问题采集API | ✅ | #2079 CLOSED |
| #2081 | P0 | backend | 开发效率统计API | ✅ | 无依赖 |
| #2321 | P0 | frontend | 全局防泄密水印 | ✅ | 独立 |
| #2262 | P0 | frontend | 预算模板[9/12] 科目编码树管理 | ✅ | backend#1545 CLOSED |
| #2261 | P0 | frontend | 预算模板[10/12] 模板库管理 | ✅ | backend#1544 CLOSED |
| #2043 | P0 | pipeline | problem_scanner.py | ⏳ | 等#2076 |
| #2077 | P1 | backend | 问题发现-P1 方案搜索API | ⏳ | 等#2076 |
| #2078 | P1 | backend | 问题发现-P1 原因诊断API | ⏳ | 等#2076 |
| #1872 | P1 | backend | 问题发现-P1 扩展双模式 | ⏳ | 等#2076 |
| #2385 | P1 | frontend | 问题发现-P1 解决方案展示页面 | ⏳ | 等#2076系列 |

---

### 开发模式监控 [N/7]

| Issue | 优先 | 模块 | 内容 | 启动 | 前置 |
|-------|------|------|------|------|------|
| #2845 | P0 | backend | [1/7] CFD数据API — Project#4状态变更历史聚合+WIP实时统计 | ✅ | 独立 |
| #2848 | P0 | backend | [4/7] Agent效率看板API — CC线路实时状态+日产出+PR Merge Rate | ✅ | 独立 |
| #2847 | P0 | pipeline | [3/7] Fail根因强制回写机制 — CC失败时评论根因分类到Issue | ✅ | 独立 |
| #2846 | P1 | frontend | [2/7] CFD前端页面 — 堆叠面积图+WIP告警卡片+流转效率指标 | ⏳ | 等#2845完成 |
| #2849 | P1 | frontend | [5/7] Agent效率看板前端 — 线路状态矩阵+产能趋势+Merge Rate | ⏳ | 等#2848完成 |
| #2851 | P1 | frontend | [7/7] 验收队列前端 — 待办卡片+紧急程度排序+响应时间趋势 | ⏳ | 等[6/7] API完成 |

> **并行策略**：#2845+#2848+#2847 三路并行（不同文件）。Frontend等各自backend完成后并行启动。

---

## Tier-3：Claude Office（Tier-2 完成后）

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #2893 | P0 | fullstack | Claude Office全量迁移至wande-play | ✅（无代码依赖） |

---

# 以下内容由排程经理每次排程后维护

## 指派建议（最近20个）
> 🔄 **更新** 2026-04-08 12:10 UTC | #2359/#2261/#2465 CLOSED(看板待GraphQL额度恢复后修正Done)；#2261 Done解锁#2260；kimi4/7/13即将空闲；⚠️ GraphQL速率限制中(约10分钟重置)

| Issue | 优先 | 模块 | 内容 | 启动 |
|-------|------|------|------|------|
| #2260 | P1 | budget | [预算模板11/12] 项目预算编制增强 — 多维度子项管控（#2261 Done解锁） | ✅ |
| #2361 | P1 | frontend | [项目中心Phase10][10/12] 项目任务面板 — 看板+任务创建分配（#2012 Done解锁） | ✅ |
| #1993 | P1 | backend | [项目中心Phase16][16/22] 健康度评分引擎 — 5维度算法+每日快照（#2471+#2009 Done解锁） | ✅ |
| #2254 | P1 | frontend | [矿场增强][10/23] 可赢性评分展示+Go/No-Go（#1531 Done解锁） | ✅ kimi3 IP |
| #2479 | P1 | backend | [D3-AI][3/3] 账号池AI渲染集成 — 独立 | ✅ |
| #2051 | P1 | frontend | D3-L4安装图自动化 — 独立 | ✅ |
| #1796 | P1 | frontend | [合同管理] 合同审批流程页面 — AI辅助快速审批 | ✅ |
| #1928 | P1 | pipeline | [D3-v2.0][Phase3-1/3] v2.0电池包→图纸输出桥接（#1867 Done解锁） | ✅ |
| #1856 | P1 | backend | [产品平台][P1] 非标件成本系数库 — 开模费/工时费率/设计费率 | ✅ |
| #1858 | P1 | backend | [产品平台][P1] 方案版本对比 — 基线方案 vs 修改版自动对比 | ✅ |
| #1862 | P1 | backend | [产品平台][P1] 标准品报价引擎 — 自动算BOM+实时报价 | ✅ |
| #1505 | P1 | backend | [矿场-Phase2][16/16] 阶段话术模板库 — 按阶段推荐沟通话术 | ✅ |
| #1520 | P1 | backend | [业务运营中心][3/8] CRM操作面板 — 线索分发与客户跟进API | ✅ |
| #1836 | P1 | design-ai | [D3-P1][30/30] 受力计算+基础设计引擎 — 多国标准载荷组合 | ✅ |
| #2252 | P1 | frontend | [矿场增强][20/23] 来源ROI看板 — 各信号源转化率柱状图+质量排名 | ✅ |
| #1525 | P1 | backend | [D3-缺陷修复][P1][3/7] D3 API Gateway统一入口层 — 独立 | ✅ |
| #2119 | P2 | backend | [执行管理] 经销模式支持 — 独立 | ✅ |
| #2093 | P3 | backend | [执行管理] AI增强验收 — 独立 | ✅ |
| #2359 | P1 | backend | [项目中心Phase12] 菜单权限SQL — CLOSED，看板待更新Done | — |
| #2465 | P1 | backend | [执行管理] 生产进度/质检/发货/安装API — CLOSED，看板待更新Done | — |

---

# 以下内容由研发经理每次指派前维护

## 当前运行（15 CC 活跃）

> 更新：2026-04-08 11:58 UTC | #2241✅PR#3434→Done；kimi3→#2254(frontend)，kimi10→#1463(backend) 各新增1槽；满槽15/15

| 指派目录 | Issue | Tier | 模块 | 内容 | 进度 |
|------|-------|------|------|------|------|
| kimi1 | #1920 | P0 | pipeline | [D3-v2.0][P0] wande-gh-plugins仓库重构 | 运行中 |
| kimi2 | #1626 | T1 | backend | [整改工单-P1] 工艺标准卡导入API | 运行中 |
| kimi3 | #2254 | T1 | frontend | [矿场增强][10/23] 可赢性评分展示+Go/No-Go | 启动中 |
| kimi4 | #2261 | T2 | frontend | [预算模板P0] 模板库管理页面 | 运行中 |
| kimi5 | #2241→Done | — | — | — | ✅PR#3434 |
| kimi6 | #2120 | T1 | backend | [执行管理] AI项目进度智能跟踪 | 运行中 |
| kimi7 | #2465 | T1 | backend | [执行管理] 生产进度/质检/发货/安装API | 运行中 |
| kimi8 | #2237 | T1 | backend | [矿场-Phase3][4/12] 项目列表赢率列排序 | 运行中 |
| kimi9 | #1464 | T1 | backend | [销售记录体系][2/9] 里程碑门控配置 | 运行中 |
| kimi10 | #1463 | T1 | backend | [销售记录体系][3/9] 智能提醒频率引擎 | 启动中 |
| kimi11 | #2240 | T1 | frontend | [矿场-Phase2][9/16] 决策链可视化组件 | 运行中 |
| kimi12 | #1828 | T1 | frontend | [提成绩效] 提成规则配置页面 | 运行中 |
| kimi13 | #2359 | T1 | backend | [项目中心Phase12] 菜单权限SQL | 运行中 |
| kimi14 | #2011 | T1 | backend | [项目中心Phase5] 设计变更联动 | 运行中 |
| kimi15 | #2255 | T1 | frontend | [矿场增强][8/23] 转化漏斗看板页面 | 运行中 |

---

## 指派历史（完成后划线）

> 研发经理维护。指派时新增行，完成后在内容列加删除线。

| 指派目录 | Issue | Tier | 模块 | 内容 | 看板状态 |
|---------|-------|------|------|------|---------|
| — | ~~#1533~~ | — | backend | ~~矿场反馈统计API~~ | ~~Done~~ |
| — | ~~#2046~~ | — | pipeline | ~~AI生成Phase4 投标知识库增强~~ | ~~Done~~ |
| kimi16 | ~~#1876~~ | — | backend | ~~商务48小时反馈机制+分级升级~~ | ~~Done~~ |
| kimi1 | ~~#1700~~ | — | backend | ~~提成绩效5张表~~ | ~~Done~~ |
| kimi15 | ~~#2159~~ | — | backend | ~~质保售后12张表建表~~ | ~~Done~~ |
| kimi11 | ~~#2409~~ | — | pipeline | ~~采集管控[1/4] wdpp_pipeline_runs表~~ | ~~Done~~ |
| kimi16 | ~~#1532~~ | — | backend | ~~矿场增强[7/23] 转化漏斗统计API~~ | ~~Done~~ |
| kimi19 | ~~#2362~~ | — | frontend | ~~项目中心Phase9 详情全景页~~ | ~~Done~~ |
| kimi11 | ~~#1994~~ | — | backend | ~~项目中心Phase15 风险事件API~~ | ~~Done~~ |
| kimi16 | ~~#2461~~ | T1 | backend | ~~合同管理建表~~ | ~~Done~~ |
| kimi2 | ~~#1903~~ | T1 | backend | ~~D3钢架自动选型规则~~ PR#3245 | ~~Done~~ |
| kimi3 | ~~#1531~~ | T1 | backend | ~~可赢性评分模型(WinProb)~~ PR#3240 | ~~Done~~ |
| kimi4 | ~~#1532~~ | T1 | backend | ~~矿场转化漏斗统计API~~ PR#3233 | ~~Done~~ |
| kimi7 | ~~#1459~~ | T1 | backend | ~~记录中心统一数据模型~~ PR#3235 | ~~Done~~ |
| kimi10 | ~~#1898~~ | T1 | backend | ~~D3发货防错系统~~ PR#3239 | ~~Done~~ |
| kimi11 | ~~#1527~~ | T1 | backend | ~~甲方历史合作查询接口~~ PR#3238 | ~~Done~~ |
| kimi13 | ~~#1853~~ | T1 | pipeline | ~~D3-Agent三层记忆系统~~ PR#3241 | ~~Done~~ |
| kimi14 | ~~#1854~~ | T1 | pipeline | ~~D3-Agent LangGraph框架~~ PR#3243✅merged | ~~Done~~ |
| kimi15 | ~~#1528~~ | T1 | backend | ~~线索来源转化率统计API~~ PR#3236 | ~~Done~~ |
| kimi17 | ~~#1630~~ | T1 | backend | ~~整改工单Phase27 API~~ | ~~Done~~ |
| kimi4 | ~~#2256~~ | T1 | frontend | ~~矿场增强[6/23] 列表状态筛选+流转~~ | ~~Done~~ |
| kimi17 | ~~#2107~~ | T1 | backend | ~~质保售后 备件管理API~~ | ~~Fail~~ |
| kimi5 | ~~#2110~~ | T1 | backend | ~~质保售后 质保台账API~~ PR#3207✅merged | ~~Done~~ |
| kimi6 | ~~#2106~~ | T1 | backend | ~~质保售后 备件消耗关联工单~~ PR#3206✅merged | ~~Done~~ |
| kimi11 | ~~#2471~~ | T1 | backend | ~~项目中心Phase13 6张表~~ PR#3141✅merged | ~~Done~~ |
| kimi13 | ~~#2047~~ | T1 | backend | ~~AI投标Phase1 ComfyUI基础设施~~ PR#3143✅merged | ~~Done~~ |
| kimi7 | ~~#2363~~ | T1 | frontend | ~~项目中心Phase8 菜单+列表~~ PR#3135✅merged | ~~Done~~ |
| kimi9 | ~~#1705~~ | T1 | backend | ~~CRM跟进记录CRUD API~~ PR#2563✅merged | ~~Done~~ |
| kimi1 | #2950 | T2 | fullstack | 侧边栏分组重构+RBAC | In Progress |
| kimi3 | ~~#2108~~ | T1 | backend | ~~质保售后 外包维修商管理API~~ PR#3247✅merged | ~~Done~~ |
| kimi7 | ~~#3229~~ | BUG | backend | ~~🔴 P0 Fat JAR依赖冲突~~ PR#3250✅merged | ~~Done~~ |
| kimi9 | ~~#3228~~ | BUG | backend | ~~🔴 P0 DB Schema缺失字段~~ PR#3248✅merged | ~~Done~~ |
| kimi10 | ~~#2109~~ | T1 | backend | ~~质保售后 售后工单API~~ PR#3204✅merged | ~~Done~~ |
| kimi17 | ~~#2368~~ | T1 | frontend | ~~菜单重组[5/8] 综合管理中心板块~~ PR#3251✅merged | ~~Done~~ |
| kimi8 | ~~#1465~~ | T1 | backend | ~~销售记录聚合引擎~~ PR#3258 | ~~Done~~ |
| kimi12 | #1852 | T1 | pipeline | D3-Agent知识库构建 | In Progress |
| kimi5 | ~~#3227~~ | BUG | backend | ~~🔴 P0 后端进程守护~~ PR#3265 | ~~Done~~ |
| kimi5 | ~~#1458~~ | T1 | backend | ~~销售记录体系 商务周报提交API（Issue CLOSED）~~ | ~~Done~~ |
| kimi6 | ~~#3230~~ | BUG | backend | ~~🟠 P1 后端API路由缺失~~ PR#3255✅merged | ~~Done~~ |
| kimi6 | ~~#1564~~ | T1 | backend | ~~企微打通[1/17] WecomAppService根节点~~ PR#3260 | ~~Done~~ |
| kimi11 | ~~#3231~~ | BUG | backend | ~~🟠 P1 CompetitorBidBo NPE~~ PR#3252 | ~~Done~~ |
| kimi11 | #1560 | T1 | backend | D3材质标注[1/4] 构件-材料绑定规则Service | In Progress |
| kimi2 | #3234 | BUG | fullstack | 🟠 P1 Dashboard数据全0 | In Progress |
| kimi4 | ~~#3226~~ | BUG | fullstack | ~~🔴 P0 Claude Office今日工作状态面板~~ PR#3257 | ~~Done~~ |
| kimi16 | ~~#3232~~ | BUG | frontend | ~~🟡 P2 前端路由404+UI渲染异常~~ | ~~Done~~ |
| kimi9 | ~~#2156~~ | T1 | backend | ~~执行管理 变更单核心API~~ PR#3262 | ~~Done~~ |
| kimi13 | ~~#2124~~ | T1 | backend | ~~执行管理 回款计划与管理API~~ PR#3256 | ~~Done~~ |
| kimi1 | #2950 | T2 | fullstack | 侧边栏分组重构+RBAC | In Progress |
| kimi3 | ~~#2098~~ | T1 | backend | ~~执行管理 验收核心API~~ | ~~Done~~ |
| kimi7 | ~~#2467~~ | T1 | backend | ~~执行管理 BOM管理API~~ PR#3271 | ~~Done~~ |
| kimi10 | ~~#2468~~ | T1 | backend | ~~执行管理 图纸管理API~~ PR#3261 | ~~Done~~ |
| kimi16 | #2026 | T1 | backend | 审批引擎核心[3/10] 发起/审批/驳回 | In Progress |
| kimi17 | ~~#1705~~ | T1 | backend | ~~CRM跟进记录CRUD API~~ PR#3280 | ~~Done~~ |
| kimi4 | #2055 | T1 | backend | D3参数化 扣件管理Web后台 | In Progress |
| kimi8 | ~~#2042~~ | T1 | backend | ~~D3优化[3/10] 局部替换+增量重算~~ PR#3269 | ~~Done~~ |
| kimi13 | ~~#1724~~ | T1 | frontend | ~~质保售后 设备台账页面~~（Issue已CLOSED，PR#3268为重复，待关闭） | ~~取消~~ |
| kimi13 | #2373 | T1 | frontend | 质保售后 H5客户报修页面 P0 | In Progress |
| kimi3 | #2086 | T1 | backend | 🟠 E2E Fail 变更影响联动API | In Progress |
| kimi6 | ~~#2065~~ | T1 | backend | ~~D3市场配置预设（5个市场）~~ PR#3270 | ~~Done~~ |
| kimi7 | ~~#2467~~ | T1 | backend | ~~执行管理 BOM管理API（重启）~~ PR#3271 | ~~Done~~ |
| kimi9 | #2446 | T1 | pipeline | 政策信号采集管线[11/38] | In Progress |
| kimi10 | #2452 | T1 | pipeline | 竞品中标公告定向采集管线[4/38] | In Progress |
| kimi14 | #1557 | T1 | backend | 企微打通[6/17] 通讯录同步 | In Progress |
| kimi9 | ~~#2446~~ | T1 | pipeline | ~~政策信号采集管线[11/38]~~ | ~~Done~~ |
| kimi11 | ~~#1560~~ | T1 | backend | ~~D3材质标注[1/4] 构件-材料绑定规则Service~~ PR#3264 | ~~Done~~ |
| kimi9 | #2408 | T1 | pipeline | 采集管控[2/4] 13脚本接run_reporter | In Progress |
| kimi11 | #2095 | T1 | backend | 执行管理 验收附件管理API | In Progress |
| kimi6 | ~~#1630~~ | T1 | backend | ~~整改工单Phase27 API P0（PR已合并）~~ | ~~Done~~ |
| kimi7 | #2041 | T1 | backend | D3优化[5/10] 场地地形集成 | In Progress |
| kimi8 | #2040 | T1 | backend | D3优化[6/10] 无障碍合规自动检测 | In Progress |
| kimi4 | ~~#2055~~ | T1 | backend | ~~D3参数化 扣件管理Web后台~~ PR#3274 | ~~Done~~ |
| kimi13 | ~~#2373~~ | T1 | frontend | ~~质保售后 H5客户报修页面 P0~~ PR#3272 | ~~Done~~ |
| kimi14 | ~~#1557~~ | T1 | backend | ~~企微打通[6/17] 通讯录同步~~ PR#3273 | ~~Done~~ |
| kimi4 | #2372 | T1 | frontend | 质保售后 售后工单管理主页面 P0 | In Progress |
| kimi13 | #2453 | T1 | pipeline | 历史甲方定向监控清单[3/38] P0 | In Progress |
| kimi14 | #2039 | T1 | backend | D3优化[7/10] 方案变体管理+版本回溯 | In Progress |
| kimi9 | ~~#2408~~ | T1 | pipeline | ~~采集管控[2/4] 13脚本接run_reporter~~ PR#3276 | ~~Done~~ |
| kimi10 | ~~#2452~~ | T1 | pipeline | ~~竞品中标公告定向采集管线[4/38]~~ PR#3275✅merged | ~~Done~~ |
| kimi9 | #2450 | T1 | pipeline | 竞品甲方提取[6/38] P0 | In Progress |
| kimi10 | #2424 | T1 | pipeline | browser_client.py Agent基建[3/7] P0 | In Progress |
| kimi1 | ~~#2950~~ | T2 | fullstack | ~~侧边栏分组重构+RBAC~~ PR#3215✅merged | ~~Done~~ |
| kimi12 | ~~#1852~~ | T1 | pipeline | ~~D3-Agent知识库构建~~ PR#3249 | ~~Done~~ |
| kimi1 | #1554 | T1 | backend | 企微打通[9/17] H5 JS-SDK签名 | In Progress |
| kimi12 | #1740 | T1 | frontend | 质保 备件库存管理页面 P1 | In Progress |
| kimi5 | #2845 | T2 | backend | 开发模式监控[1/7] CFD数据API | In Progress |
| kimi6 | #2848 | T2 | backend | 开发模式监控[4/7] Agent效率看板API | In Progress |
| kimi17 | ~~#2847~~ | T2 | pipeline | ~~开发模式监控[3/7] Fail根因强制回写~~ PR#3283✅merged | ~~Done~~ |
| kimi2 | ~~#3234~~ | BUG | fullstack | ~~Dashboard数据全0~~ PR#3254✅merged | ~~Done~~ |
| kimi13 | ~~#2453~~ | T1 | pipeline | ~~历史甲方定向监控清单[3/38]~~ PR#3281✅merged | ~~Done~~ |
| kimi2 | ~~#2846~~ | T2 | backend | ~~开发模式监控[2/7] CFD甘特图数据API~~ PR#3285✅merged | ~~Done~~ |
| kimi1 | ~~#1554~~ | T1 | backend | ~~企微打通[9/17] H5 JS-SDK签名~~ PR#3286✅merged | ~~Done~~ |
| kimi14 | ~~#2039~~ | T1 | backend | ~~D3优化[7/10] 方案变体管理+版本回溯~~ PR#3287 | ~~Done~~ |
| kimi1 | #2076 | T2 | backend | 🔴 问题发现采集API | In Progress |
| kimi2 | #2276 | T2 | frontend | 采集管控[4/4] 管控面板 | In Progress |
| kimi14 | #1555 | T1 | backend | 企微打通[10/17]（#1554解锁） | In Progress |
| kimi9 | ~~#2450~~ | T1 | pipeline | ~~竞品甲方提取[6/38]~~ PR#3282✅merged | ~~Done~~ |
| kimi11 | ~~#2095~~ | T1 | backend | ~~验收附件管理API~~ PR#3284(外部推送) | ~~Done~~ |
| kimi9 | #2851 | T2 | backend | 开发模式监控[7/7] 告警规则配置API | In Progress |
| kimi11 | #2893 | T3 | fullstack | Claude Office全量迁移至wande-play | In Progress |
| kimi13 | #2477 | T1 | pipeline | D3-AI ComfyUI渲染Pipeline[1/3] | In Progress |
| kimi17 | ~~#1806~~ | T1 | frontend | ~~🔴 执行项目总看板（用户优先）~~ PR#3289 | ~~Done~~ |
| kimi9 | ~~#2851~~ | T2 | backend | ~~开发监控[7/7] 告警规则配置API~~ PR#3288 | ~~Done~~ |
| kimi9 | ~~#2039~~ | T1 | backend | ~~D3优化[7/10] 方案变体管理（重派）~~ MERGED 2026-04-07 19:05 | ~~Done~~ |
| kimi7 | ~~#2038~~ | T1 | backend | ~~D3优化[8/10] 配色方案系统~~ PR#3310 | ~~Done~~ |
| kimi10 | ~~#2445~~ | T1 | pipeline | ~~锁定100儿童友好城市监控~~ PR#3305 | ~~Done~~ |
| kimi12 | ~~#1740~~ | T1 | frontend | ~~质保 备件库存管理页面~~ PR#3311 | ~~Done~~ |
| kimi7 | #1678 | T1 | backend | AI投标配图自动生成 | In Progress |
| kimi10 | #2589 | T1 | fullstack | 执行管理45个API前端对接 | In Progress |
| kimi12 | #2423 | T1 | pipeline | Agent基类[4/7] | In Progress |
| kimi17 | #1806 | T1 | frontend | 🔴 执行项目总看板（重启） | In Progress |
| kimi5 | ~~#2845~~ | T2 | backend | ~~开发模式监控[1/7] CFD数据API~~ PR#3314 | ~~Done~~ |
| kimi14 | ~~#1555~~ | T1 | backend | ~~企微打通[10/17] 审批引擎模板卡片集成~~ PR#3313 | ~~Done~~ |
| kimi5 | #1510 | T1 | backend | 矿场Phase2[4/16] 客户角色关联表 | In Progress |
| kimi14 | #1511 | T1 | backend | 矿场Phase2[1/16] 客户画像扩展字段 | In Progress |
| kimi8 | #1863 | T2 | frontend | D3产品平台 Web产品目录浏览器 | In Progress |
| kimi1 | #1855 | T2 | fullstack | [D3-Agent][1/7] G7e安装CadQuery+rhino3dm参数化建模 | In Progress |
| kimi12 | #2406 | T1 | pipeline | 矿场增强[11/23] 信号衰减定时任务 | In Progress |
| kimi15 | #1529 | T1 | backend | 矿场增强[17/23] 企微H5轻量接口 | In Progress |
| kimi5 | #1864 | T2 | pipeline | [产品平台][P0] 2026产品目录数据结构化入库 | In Progress |
| kimi4 | ~~#2372~~ | T1 | frontend | ~~质保售后 售后工单管理主页面 P0~~ PR#3325✅merged | ~~Done~~ |
| kimi7 | ~~#1678~~ | T1 | backend | ~~AI投标配图自动生成~~ | ~~Done~~ |
| kimi1 | ~~#1855~~ | T2 | fullstack | ~~[D3-Agent][1/7] G7e安装CadQuery+rhino3dm参数化建模环境~~ PR#3331✅merged | ~~Done~~ |
| kimi3 | ~~#2086~~ | T1 | backend | ~~变更影响联动API - BOM差异+成本利润联动~~ PR#3356✅merged | ~~Done~~ |
| kimi1 | ~~#3335~~ | tech | backend | ~~[mvn test欠债] D3设计与参数化~~ | ~~Done~~ |
| kimi2 | ~~#3345~~ | tech | backend | ~~[mvn test欠债] 问题反馈与通知~~ | ~~Done~~ |
| kimi3 | ~~#3336~~ | tech | backend | ~~[mvn test欠债] 项目执行与看板~~ | ~~Done~~ |
| kimi4 | ~~#3337~~ | tech | backend | ~~[mvn test欠债] 预算资金与佣金~~ | ~~Done~~ |
| kimi5 | ~~#3346~~ | tech | backend | ~~[mvn test欠债] 销售跟踪与CRM~~ | ~~Done~~ |
| kimi6 | ~~#3348~~ | tech | backend | ~~[mvn test欠债] 文案与审批~~ | ~~Done~~ |
| kimi7 | ~~#3338~~ | tech | backend | ~~[mvn test欠债] Token池与运营~~ PR#3357✅merged | ~~Done~~ |
| kimi8 | ~~#3344~~ | tech | backend | ~~[mvn test欠债] 方案与报价~~ | ~~Done~~ |
| kimi9 | ~~#3339~~ | tech | backend | ~~[mvn test欠债] 整改与质保~~ | ~~Done~~ |
| kimi10 | ~~#3349~~ | tech | backend | ~~[mvn test欠债] 设备生命周期~~ | ~~Done~~ |
| kimi11 | ~~#3347~~ | tech | backend | ~~[mvn test欠债] 数字资产与S3~~ | ~~Done~~ |
| kimi12 | ~~#3350~~ | tech | backend | ~~[mvn test欠债] 备件与采购~~ | ~~Done~~ |
| kimi13 | ~~#3351~~ | tech | backend | ~~[mvn test欠债] 财务收款与合同~~ | ~~Done~~ |
| kimi14 | ~~#3340~~ | tech | backend | ~~[mvn test欠债] 驾驶舱与运维~~ | ~~Done~~ |
| kimi15 | ~~#3352~~ | tech | backend | ~~[mvn test欠债] 工单与派单~~ | ~~Done~~ |
| kimi16 | ~~#3353~~ | tech | backend | ~~[mvn test欠债] 照片AI识别~~ | ~~Done~~ |
| kimi17 | ~~#3354~~ | tech | backend | ~~[mvn test欠债] 验收与交付~~ | ~~Done~~ |
| kimi18 | ~~#3341~~ | tech | backend | ~~[mvn test欠债] 聊天会话与记忆~~ | ~~Done~~ |
| kimi19 | ~~#3342~~ | tech | backend | ~~[mvn test欠债] 企微集成与权限~~ | ~~Done~~ |
| kimi20 | ~~#3343~~ | tech | backend | ~~[mvn test欠债] 标准库与材质~~ | ~~Done~~ |
| kimi6 | #1504 | T1 | backend | [矿场-Phase3][1/12] 赢率预测特征工程 | In Progress |
| kimi7 | ~~#1529~~ | T1 | backend | ~~[矿场增强][17/23] 企微H5轻量接口~~ PR#3329 | ~~Done~~ |
| kimi8 | #2401 | T1 | pipeline | [矿场-Phase2][10/16] 政策信号采集器 | In Progress |
| kimi1 | ~~#2081~~ | T2 | backend | ~~[超管驾驶舱P0] 开发效率统计API~~ PR#3403 | ~~Done~~ |
| kimi2 | #2321 | T1 | frontend | [P0] 全局防泄密水印 | In Progress |
| kimi3 | ~~#2262~~ | T2 | frontend | ~~[预算模板P0] 科目编码树管理页面~~ PR#2575✅merged | ~~Done~~ |
| kimi4 | #2261 | T2 | frontend | [预算模板P0] 模板库管理页面 | In Progress |
| kimi5 | #2405 | T1 | backend | [矿场增强][22/23] 关系加分逻辑 | In Progress |
| kimi9 | #2403 | T1 | pipeline | [矿场-Phase2][2/16] 企业工商数据采集 | In Progress |
| kimi10 | ~~#2402~~ | T1 | pipeline | ~~[矿场-Phase2][5/16] 项目角色自动识别NLP~~ PR#3404 | ~~Done~~ |
| kimi11 | ~~#2400~~ | T1 | pipeline | ~~[矿场-Phase2][14/16] G7e联系人自动提取~~ | ~~Done~~ |
| kimi11 | ~~#2131~~ | T1 | backend | ~~[代理商工作台] 数据模型+API+评分引擎~~ PR#3405 | ~~Done~~ |
| kimi12 | ~~#2043~~ | T2 | pipeline | ~~[问题发现P0] problem_scanner.py多源采集~~ PR#3406 | ~~Done~~ |
| kimi13 | #2116 | T1 | backend | [代理商工作台] 数据模型+API+统计 | In Progress |
| kimi14 | ~~#1695~~ | T1 | backend | ~~[提成绩效] 绩效考核API~~ PR#3408 | ~~Done~~ |
| kimi7 | #2078 | T1 | backend | [问题发现-P1] 原因诊断API | In Progress |
| kimi15 | #1696 | T1 | backend | [提成绩效] 管理费分摊API | In Progress |
| kimi2 | ~~#2321~~ | T1 | frontend | ~~[P0] 全局防泄密水印~~ PR#3402 | ~~Done~~ |
| kimi5 | ~~#2405~~ | T1 | backend | ~~[矿场增强][22/23] 关系加分逻辑~~ PR#3401 | ~~Done~~ |
| kimi2 | #1492 | T1 | backend | [矿场-Phase4][14/17] 跟进超时提醒 | In Progress |
| kimi5 | ~~#2077~~ | T2 | backend | ~~[问题发现-P1] 方案搜索API~~ PR#3407✅merged | ~~Done~~ |
| kimi5 | ~~#2385~~ | T2 | frontend | ~~[问题发现-P1] 解决方案展示+待办管理页面~~ PR#3410✅merged | ~~Done~~ |
| kimi3 | ~~#1509~~ | T1 | backend | ~~[矿场-Phase2][6/16] 关系快照API~~ PR#3409✅merged | ~~Done~~ |
| kimi1 | #2399 | T1 | pipeline | [矿场-Phase3][2/12] 赢率预测模型训练Pipeline | In Progress |
| kimi10 | #2242 | T1 | frontend | [矿场-Phase2][3/16] 客户360画像详情页 | In Progress |
| kimi11 | #2112 | T1 | backend | [合同管理] AI合同风险分析引擎 | In Progress |
| kimi12 | #2111 | T1 | backend | [合同管理] AI条款对比引擎 | In Progress |
| kimi3 | #2253 | T1 | frontend | [矿场增强][18/23] 企微H5矿场页面 | In Progress |
| kimi5 | #2241 | T1 | frontend | [矿场-Phase2][7/16] 项目详情关系地图 | In Progress |
| kimi14 | #1872 | T1 | backend | [问题发现-P1] 扩展双模式 | In Progress |
| kimi13 | ~~#2116~~ | T1 | backend | ~~[代理商工作台] 数据模型+API+统计~~ PR#3411 | ~~Done~~ |
| kimi10 | ~~#2242~~ | T1 | frontend | ~~[矿场-Phase2][3/16] 客户360画像详情页~~ PR#3412 | ~~Done~~ |
| kimi4 | #2261 | T2 | frontend | [预算模板P0] 模板库管理页面（已重启） | In Progress |
| kimi9 | #2403 | T1 | pipeline | [矿场-Phase2][2/16] 企业工商数据采集（已重启） | In Progress |
| kimi13 | #1766 | T1 | frontend | [代理商工作台] 前端管线+五阶段看板 | In Progress |
| kimi10 | #2228 | T1 | frontend | [矿场-Phase4][13/17] 管理看板-团队活动量 | In Progress |
| kimi12 | ~~#2111~~ | T1 | backend | ~~[合同管理] AI条款对比引擎~~ PR#3413 | ~~Done~~ |
| kimi15 | ~~#1696~~ | T1 | backend | ~~[提成绩效] 管理费分摊API~~ PR#3414 | ~~Done~~ |
| kimi12 | #1756 | T1 | frontend | [代理商工作台] 前端看板+列表视图 | In Progress |
| kimi15 | #1726 | T1 | frontend | [代理商工作台] 代理商管理页面 | In Progress |
| kimi8 | ~~#2401~~ | T1 | pipeline | ~~[矿场-Phase2][10/16] 政策信号采集器~~ PR#3376 等E2E | ~~Done~~ |
| kimi8 | #1508 | T1 | backend | [矿场-Phase2][8/16] 决策链联系人角色标签 | In Progress |
| kimi11 | ~~#2112~~ | T1 | backend | ~~[合同管理] AI合同风险分析引擎~~ PR#3415 | ~~Done~~ |
| kimi14 | ~~#1872~~ | T1 | backend | ~~[问题发现-P1] 扩展双模式~~ PR#3416 | ~~Done~~ |
| kimi11 | #2009 | T1 | backend | [项目中心Phase7] 项目全景API | In Progress |
| kimi14 | #2012 | T1 | backend | [项目中心Phase4] 跨部门任务Service | In Progress |
| kimi2 | ~~#1492~~ | T1 | backend | ~~[矿场-Phase4][14/17] 跟进超时提醒~~ PR#3419 | ~~Done~~ |
| kimi7 | ~~#2078~~ | T1 | backend | ~~[问题发现-P1] 原因诊断API~~ PR#3417 | ~~Done~~ |
| kimi6 | ~~#1504~~ | T1 | backend | ~~[矿场-Phase3][1/12] 赢率预测特征工程~~ PR#3399✅merged | ~~Done~~ |
| kimi4 | #2261 | T2 | frontend | [预算模板P0] 模板库管理页面（重启） | In Progress |
| kimi2 | #1863 | P0 | frontend | [产品平台][P0] D3 Web产品目录浏览器 | In Progress |
| kimi6 | #1867 | P0 | pipeline | [D3-v2.0][P0] D3 AI知识体系构建 | In Progress |
| kimi7 | #2465 | T1 | backend | [执行管理] 生产进度/质检/发货/安装API | In Progress |
| kimi15 | ~~#1726~~ | T1 | frontend | ~~[代理商工作台] 代理商管理页面~~ PR#3420 | ~~Done~~ |
| kimi15 | #2183 | T1 | backend | [执行管理] 扩展角色权限 tech_coordinator+install_manager | In Progress |
| kimi9 | ~~#2403~~ | T1 | pipeline | ~~[矿场-Phase2][2/16] 企业工商数据采集~~ PR#3421 | ~~Done~~ |
| kimi2 | ~~#1863~~ | P0 | frontend | ~~[产品平台][P0] D3 Web产品目录浏览器~~ PR#3326✅merged | ~~Done~~ |
| kimi2 | #1626 | T1 | backend | [整改工单-P1] 工艺标准卡导入API | In Progress |
| kimi9 | #1464 | T1 | backend | [销售记录体系][2/9] 里程碑门控配置 | In Progress |
| kimi12 | ~~#1756~~ | T1 | frontend | ~~[代理商工作台] 前端看板+列表视图~~ PR#3424 | ~~Done~~ |
| kimi13 | ~~#1766~~ | T1 | frontend | ~~[代理商工作台] 前端管线+五阶段看板~~ PR#3423 | ~~Done~~ |
| kimi8 | ~~#1508~~ | T1 | backend | ~~[矿场-Phase2][8/16] 决策链联系人角色标签~~ PR#3426 | ~~Done~~ |
| kimi8 | #2237 | T1 | backend | [矿场-Phase3][4/12] 项目列表赢率列排序 | In Progress |
| kimi12 | #1828 | T1 | frontend | [提成绩效] 提成规则配置页面 | In Progress |
| kimi13 | #2359 | T1 | backend | [项目中心Phase12] 菜单权限SQL | In Progress |
| kimi6 | ~~#1867~~ | P0 | pipeline | ~~[D3-v2.0][P0] D3 AI知识体系构建~~ PR#3428 | ~~Done~~ |
| kimi14 | ~~#2012~~ | T1 | backend | ~~[项目中心Phase4] 跨部门任务Service~~ PR#3429 | ~~Done~~ |
| kimi3 | #2253 | T1 | frontend | [矿场增强][18/23] 企微H5矿场页面（重启） | In Progress |
| kimi7 | #2465 | T1 | backend | [执行管理] 生产进度/质检/发货/安装API（重启） | In Progress |
| kimi6 | #2120 | T1 | backend | [执行管理] AI项目进度智能跟踪 | In Progress |
| kimi14 | #2011 | T1 | backend | [项目中心Phase5] 设计变更联动 | In Progress |
| kimi1 | ~~#2399~~ | T1 | pipeline | ~~[矿场-Phase3][2/12] 赢率预测模型训练Pipeline~~ PR#3433 | ~~Done~~ |
| kimi11 | ~~#2009~~ | T1 | backend | ~~[项目中心Phase7] 项目全景API~~ PR#3432 | ~~Done~~ |
| kimi15 | ~~#2183~~ | T1 | backend | ~~[执行管理] 扩展角色权限~~ PR#3431 | ~~Done~~ |
| kimi3 | ~~#2253~~ | T1 | frontend | ~~[矿场增强][18/23] 企微H5矿场页面~~ PR#3427✅merged | ~~Done~~ |
| kimi1 | #1920 | P0 | pipeline | [D3-v2.0][P0] wande-gh-plugins仓库重构 | In Progress |
| kimi11 | #2240 | T1 | frontend | [矿场-Phase2][9/16] 决策链可视化组件 | In Progress |
| kimi15 | #2255 | T1 | frontend | [矿场增强][8/23] 转化漏斗看板页面 | In Progress |
| kimi5 | ~~#2241~~ | T1 | frontend | ~~[矿场-Phase2][7/16] 项目详情关系地图~~ PR#3434 | ~~Done~~ |
| kimi3 | #2254 | T1 | frontend | [矿场增强][10/23] 可赢性评分展示+Go/No-Go | In Progress |
| kimi10 | #1463 | T1 | backend | [销售记录体系][3/9] 智能提醒频率引擎 | In Progress |
