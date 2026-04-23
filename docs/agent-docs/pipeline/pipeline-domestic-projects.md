# 国内项目采集管线

## 业务背景

从全网发现与万德业务（体育器材/儿童游乐设备）相关的项目机会。
项目分五大类：早期金矿、设备招标、施工方谈判、政策指导、其他。

## 数据库表

### wdpp_discovered_projects（项目主表，已有 7,695 条）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 主键 |
| title | TEXT NOT NULL | 项目标题 |
| location / province / city | TEXT | 地理信息 |
| investment_amount | NUMERIC(14,2) | 投资金额 |
| stage_category | VARCHAR(20) | 归一化阶段 |
| source_url | TEXT | 信源链接 |
| score_total | INT | 总评分 |
| match_grade | VARCHAR(1) | AI匹配等级：A/B/C |
| verification_status | VARCHAR(20) | pending/verified/failed/needs_confirm |
| synced_to_lightsail / synced_at | BOOL/TIMESTAMP | 同步标记 |
| create_time / update_time | TIMESTAMP | 时间戳 |

**唯一约束**: (title, source_url)

### wdpp_tender_data（招标原始数据，15,265 条）
### wdpp_keyword_pool（关键词池，1,290 条）
### wdpp_search_log / wdpp_province_stats（辅助表）

## 管线流程（7步）

```
Step 1: 采集 (smart_project_discovery.py) — 每2h
Step 2: 分类 (source_classifier.py)
Step 3: 去重 (project_dedup.py)
Step 4: 验证 (project_verifier.py) — 每2h
Step 5: 竞标信息 (battle_info_generator.py)
Step 6: 评分 (match_grade_calculator.py)
Step 7: 同步 (project_mine_sync.py)
```

**编排脚本**: `deploy/g7e/project_mine_pipeline.sh`

**辅助管线**: keyword_learner.py / project_activity_monitor.py / tender_crawler_v3.py

## 深挖动作

- `project_enricher.py` — 信息丰富
- `phase3_enricher.py` — Phase3追加采集
- `reclassify_unknown.py` — 重分类
- `reverify_robust.py` — 强化复验

## 五分类体系

| 分类 | stage_category | 行动 |
|------|----------------|------|
| 早期金矿 | early_gold | 找合作单位+联系人→销售提前介入 |
| 设备招标 | bidding | 找招标详情+截止时间→准备投标 |
| 施工方谈判 | contractor_negotiation | 找施工方→对接 |
| 政策指导 | policy | 跟踪区域和时间 |
| 其他 | other | 低优先级 |

## 数据筛选规则

1. 运维/保养/物业类 → 降低评分但保留
2. 已中标/过期招标 → 不推送
3. 广告/文章/产品页 → 移除
4. 必须与万德业务明确相关
5. 已知竞对: 永浪集团、北京奥康达、浙江巧巧、广东童年之家、凯奇集团、奇特乐、永利兴
