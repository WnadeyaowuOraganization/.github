# 国际客户采集管线

## 业务背景

发现海外客户（经销商/设计建造商），为国际贸易团队提供高价值客户线索。
集团国际贸易体量4000万，体游1000万。

## 数据库表（6张，待建）

wdpp_intl_prospects / wdpp_intl_contacts / wdpp_intl_scoring_records / wdpp_intl_tariff_cache / wdpp_intl_outreach_logs / wdpp_intl_discovery_runs

详细建表 SQL 见 `migrations/sql/002_intl_tables.sql`（待创建）。

## 管线流程（5步，待开发）

```
Step 1: 采集 (intl_client_discovery.py)
Step 2: 清洗 (intl_client_cleaner.py)
Step 3: 验证 (intl_client_verifier.py) — 通过 Browser Agent(9830) 访问官网
Step 4: 评分 (intl_client_scorer.py) — 8维度100分制
Step 5: 落库同步 (intl_client_sync.py)
```

## 深挖动作

- `intl_client_enricher.py` — 官网深度抓取 + AI结构化
- `intl_email_generator.py` — AI生成个性化 Cold Email
- `intl_tariff_updater.py` — 关税数据更新
