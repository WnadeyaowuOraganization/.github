# 国内客户采集管线

## 业务背景

从互联网发现与万德业务相关的潜在国内客户（设计院、施工方、经销商、政府采购部门等）。
采集对象是**组织/公司/机构**，而非项目。

## 数据库表（待建）

### wdpp_domestic_leads + wdpp_domestic_lead_activities

详细建表 SQL 见 `migrations/sql/001_wdpp_domestic_leads.sql`（待创建）。

## 管线流程（4步，待开发）

```
Step 1: 采集 (domestic_client_discovery.py)
Step 2: 清洗 (domestic_client_cleaner.py)
Step 3: 验证 (domestic_client_verifier.py)
Step 4: 落库同步 (domestic_client_sync.py)
```

## 数据源优先级

1. **wdpp_tender_data 反推**（最高）— 从招标数据提取 buyer
2. **wdpp_discovered_projects 反推** — 从项目的甲方/施工方提取
3. **行业展会名录** — 体博会、CAAPA等
4. **SearXNG 搜索**
