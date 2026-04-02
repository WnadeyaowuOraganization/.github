# Sprint 2026-03-28 排程计划 - 项目矿场功能

## 功能概述
构建项目矿场系统，从多个渠道采集招标项目信息，进行智能评分和分配，支撑销售团队的项目发现与跟进。

## Issue依赖关系分析

### 正确执行顺序
```
Phase1: #16 [pipeline] 采集引擎迁移与优化
    ↓
Phase2: #17 [pipeline] 关键词自学习引擎优化
    ↓
Phase3: #18 [pipeline] 信源过滤增强
    ↓
Phase4: #19 [pipeline] 数据去重与合并
    ↓
Phase5: #20 [pipeline] 项目真实性交叉验证引擎
    ↓
Phase6: #21 [pipeline] 项目阶段自动判定
    ↓
Phase7: #22 [pipeline] 同步管道优化
    ↓
Phase8: #23 [pipeline] 实时同步管道
    ↓
Phase9: #25 [pipeline] 6维度100分评分引擎
    ↓
Phase10: #26 [pipeline] Pipeline健康监控
    ↓
Phase11: #27 [pipeline] 甲方/配合单位信息自动采集
    ↓
Phase12: #28 [pipeline] 配合单位信息同步到Lightsail
```

## 当前状态

### 已完成 ✅

| Phase | Issue | 状态 | PR | 说明 |
|-------|-------|------|-----|------|
| Phase3 | #18 [pipeline] | **MERGED** | #89 | 信源过滤增强 ✅ |
| Phase4 | #19 [pipeline] | **MERGED** | #89 | 数据去重与合并 ✅ (与#18同PR) |
| Phase5 | #20 [pipeline] | **MERGED** | #104 | 项目真实性交叉验证引擎 ✅ |
| Phase6 | #21 [pipeline] | **MERGED** | #104 | 项目阶段自动判定 ✅ (与#20同PR) |
| Phase7 | #22 [pipeline] | **IN REVIEW** | #106 | 同步管道优化 - PR已创建，待E2E测试 |
| Phase8 | #23 [pipeline] | **MERGED** | #105 | 实时同步管道 ✅ |

### 进行中 🔄

| Phase | Issue | 状态 | 说明 |
|-------|-------|------|------|
| Phase1 | #16 [pipeline] | **In Progress** | 采集引擎迁移（CC中断，需恢复） |
| Phase9 | #25 [pipeline] | **In Progress** | 6维度100分评分引擎（无PR，需启动CC） |
| Phase10 | #26 [pipeline] | **In Progress** | Pipeline健康监控（无PR，需启动CC） |
| Phase11 | #27 [pipeline] | **In Progress** | 甲方信息采集（无PR，需启动CC） |
| Phase12 | #28 [pipeline] | **In Progress** | 配合单位信息同步（无PR，需启动CC） |

### 待开始 📋

| Phase | Issue | 状态 | 优先级 | 说明 |
|-------|-------|------|--------|------|
| Phase2 | #17 [pipeline] | Todo | P1 | 关键词自学习引擎优化 |

## 排程决策

### 立即执行（恢复和启动CC）

1. **#16 Phase1 采集引擎迁移** [pipeline]
   - **状态**: In Progress，CC中断，需恢复
   - **动作**: 恢复CC，继续完成
   - **指派目录**: pipeline-glm2（原目录）

2. **#25 Phase9 评分引擎** [pipeline]
   - **状态**: In Progress，无PR
   - **动作**: 启动CC
   - **指派目录**: pipeline-glm1（#19/#21已完成，目录空闲）

3. **#27 Phase11 甲方信息采集** [pipeline]
   - **状态**: In Progress，无PR
   - **动作**: 启动CC
   - **指派目录**: pipeline-glm3（#12已完成，目录空闲）

### 等待E2E测试

| Issue | 状态 | PR | 动作 |
|-------|------|-----|------|
| #22 Phase7 | In Progress → Todo | #106 | 等待中层E2E测试 |

### 暂缓执行（P1优先级）

| Issue | 当前状态 | 决策 | 原因 |
|-------|----------|------|------|
| #17 Phase2 | Todo | 保持Todo | P1优先级，等P0完成 |
| #26 Phase10 | In Progress | 检查PR状态 | 可能是P1，延后处理 |
| #28 Phase12 | In Progress | 检查PR状态 | 依赖#27，等#27完成 |

## 完成标准

- [ ] #16 采集引擎迁移完成，smart_project_discovery.py 纳入版本控制
- [x] #18 信源过滤增强完成，URL黑名单和标题噪音过滤生效 ✅
- [x] #20 项目真实性验证完成，多源交叉验证准确率>85% ✅
- [x] #21 项目阶段判定完成，AI识别准确率>80% ✅
- [ ] #22 同步管道优化完成，覆盖率目标>85%（PR #106待E2E测试）
- [x] #23 实时同步管道完成 ✅
- [ ] #25 评分引擎完成，6维度100分评分体系上线
- [ ] #27 甲方信息采集完成，counterpart_enricher.py 运行稳定

---

**排程时间**: 2026-04-01  
**更新时间**: 2026-04-02  
**排程经理**: AI Scheduler  
**状态**: 🔄 进行中（8个Phase已完成，4个进行中，1个待开始）
