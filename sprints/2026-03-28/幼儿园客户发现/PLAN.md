# Sprint 2026-03-28 排程计划 - 幼儿园客户发现功能

## 功能概述
构建深圳幼儿园客户发现系统，从多个招标网站采集幼儿园相关采购信息，提供数据看板和预警功能。

## Issue依赖关系分析

### 正确执行顺序
```
Phase1: #34 [backend] DB表创建 (kindergarten_procurement + dept_budget_items)
    ↓
Phase2: #10 [pipeline] 深圳政府采购网采集器 (In Progress)
    ↓
Phase3: #11 [pipeline] 千里马招标网采集器
    ↓
Phase4: #12 [pipeline] 各区教育局PDF扫描器
    ↓
Phase5: #13 [pipeline] 2026年历史数据回填
    ↓
Phase6: #14 [pipeline] 每日定时监控Cron
    ↓
Phase7a: #37 [backend] 后端API (CRUD + 统计)
    ↓
Phase7b: #24 [front] 前端页面 (看板)
```

## 当前状态异常

| Issue | 状态 | 问题 |
|-------|------|------|
| #34 Phase1 DB表 | In Progress | 已重新启动CC修复 |
| #10 Phase2 采集器 | In Progress | 已重新启动CC修复 |
| #24 Phase7b 前端 | Todo | 过早开始，应等Phase7a完成 |

## 排程决策

### 立即执行（改为Todo，优先处理）

1. **#34 Phase1 DB表创建** [backend]
   - **优先级**: P0（阻塞后续所有Issue）
   - **依赖**: 无
   - **可被并行**: 否（阻塞项）
   - **指派目录**: backend-kimi1
   - **预计完成**: 2小时

2. **#10 Phase2 深圳采集器** [pipeline]
   - **优先级**: P0（阻塞Phase3-6）
   - **依赖**: #34（DB表结构）
   - **可被并行**: 是（与#34并行开发，但需DB结构）
   - **指派目录**: pipeline-glm1
   - **预计完成**: 4小时

### 暂缓执行（保持Plan，等依赖完成）

| Issue | 当前状态 | 决策 | 原因 |
|-------|----------|------|------|
| #11 Phase3 | Todo | 保持Todo | 等#10完成 |
| #12 Phase4 | Todo | 保持Todo | 等#11完成 |
| #13 Phase5 | Todo | 保持Todo | 等#12完成 |
| #14 Phase6 | Todo | 保持Todo | 等#13完成 |
| #37 Phase7a | Todo | 保持Todo | 等#14完成 |
| #24 Phase7b | Todo | 保持Todo | 等#37完成 |

## 执行计划

### 第一步：解除阻塞
1. 将 #34 保持 In Progress
2. 将 #10 保持 In Progress
3. 监控 #34 和 #10 的PR创建情况

### 第二步：按序排程
按依赖顺序逐个将Issue从Plan → Todo，确保不违反依赖关系

## 风险与应对

| 风险 | 影响 | 应对策略 |
|------|------|----------|
| #34 DB表设计变更 | 影响所有后续Issue | 要求编程CC输出设计文档到Issue评论，确认后再开发 |
| #10 采集器被反爬 | Phase3-6无法测试 | 增加代理池和请求频率控制，失败时标记pause |
| #37 API与#24前端并行 | 接口不匹配 | 建议#24暂停，等#37完成后再启动 |

## 完成标准

- [ ] #34 DB表创建完成，SQL脚本已合并到dev
- [ ] #10 深圳采集器完成，能正常采集数据入库
- [ ] #37 后端API完成，提供完整CRUD和统计接口
- [ ] #24 前端看板完成，能正常展示数据
- [ ] E2E中层测试通过（幼儿园客户发现数据流端到端）

---

**排程时间**: 2026-04-01  
**排程经理**: AI Scheduler  
**下次回顾**: #34完成后立即回顾
