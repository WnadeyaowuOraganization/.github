# Sprint-1 排程计划

> 最后更新：2026-04-07
> Sprint 目标：矿场增强P0/P1 → 超管驾驶舱P0 → Claude Office迁移P0
> 并发上限：**5个CC**

## 现状快照（2026-04-07）

| 状态 | 数量 |
|------|------|
| 运行中 (CC活跃) | 5 |
| 优先队列 (待启动) | 14 |
| Done已关闭 | 10（本轮清理） |

**当前运行（5/5）**

| kimi | Issue | 模块 | 内容 |
|------|-------|------|------|
| kimi1 | #2409 | backend | 超管驾驶舱·采集管控 Phase0-1/4 建表 |
| kimi15 | #1886 | backend | 素材库 Entity+Mapper |
| kimi16 | #1609 | backend | 预算管控数据模型 7张表 |
| kimi17 | #1475 | backend | 商务赋能知识中台·标准产品合规矩阵 |
| kimi19 | #1567 | dashboard | 错误分析中心·错误采集Service+查询API |

---

## 优先队列（槽位空出后按序启动）

### Tier-1：矿场/投标（最高优先）

| 顺序 | Issue | 模块 | 优先级 | 内容 | effort |
|------|-------|------|--------|------|--------|
| 1 | #2257 | backend | P0 | 矿场增强·反馈按钮结构化表单 | medium |
| 2 | #2407 | backend | P0 | 矿场增强·反馈驱动评分模型校准 | medium |
| 3 | #2256 | frontend | P0 | 矿场增强·矿场列表状态筛选+流转 | medium |
| 4 | #2206 | backend | P0 | 投标方案生成引擎 API+RAG | high |
| 5 | #2046 | pipeline | P0 | 投标方案知识库增强——历史方案入库 | medium |
| 6 | #2028 | backend | P1 | 项目矿场·增量同步推送 | medium |

### Tier-2：超管驾驶舱

| 顺序 | Issue | 模块 | 优先级 | 内容 | effort |
|------|-------|------|--------|------|--------|
| 7 | #1572 | backend | P0 | 采集管控·管线数据漏斗API | medium |
| 8 | #2076 | backend | P0 | 问题发现·问题采集API | medium |
| 9 | #2043 | pipeline | P0 | 问题发现·problem_scanner.py | medium |
| 10 | #2081 | backend | P0 | 超管驾驶舱·开发效率统计API | medium |
| 11 | #2261 | frontend | P0 | 预算模板增强·模板库管理页面（超管） | medium |
| 12 | #2262 | frontend | P0 | 预算模板增强·科目编码树管理页面（超管） | medium |
| 13 | #2276 | frontend | P0 | 采集管控·采集管线管控面板 | medium |

### Tier-3：Claude Office迁移

| 顺序 | Issue | 模块 | 优先级 | 内容 | effort |
|------|-------|------|--------|------|--------|
| 14 | #2893 | fullstack | P0 | Claude Office全量迁移至wande-play | high |

---

## 排程规则

1. **并发上限 5个**，排程前先 `bash scripts/check-cc-status.sh` 确认槽位
2. Tier-1 全部完成前不启动 Tier-2；Tier-2 全部完成前不启动 Tier-3
3. 同 Tier 内按顺序号依次填满空槽
4. `test-failed` 标签的 Issue 插队到当前 Tier 最前
5. backend Issue 先于依赖它的 frontend Issue 启动
