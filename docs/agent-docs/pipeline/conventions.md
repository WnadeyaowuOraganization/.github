# 开发规范

## 建表规范（强制）

本仓库所有数据库表必须遵守以下规范，**违反任一条即为不合格**：

### 表名前缀

所有表必须以 `wdpp_` 前缀开头（Wande Data Pipeline 的缩写）。

```
✅ wdpp_discovered_projects
❌ discovered_projects    ← 缺少前缀
```

### 必填时间字段

每张表必须包含 `create_time` + `update_time`：

```sql
CREATE TABLE wdpp_xxx (
    id SERIAL PRIMARY KEY,
    -- ... 业务字段 ...
    create_time TIMESTAMP NOT NULL DEFAULT NOW(),
    update_time TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 已有表清单（已重命名，2026-03-22）

| 旧表名 | 新表名 | 字段变更 |
|--------|--------|----------|
| discovered_projects | **wdpp_discovered_projects** | created_at→create_time, updated_at→update_time |
| tender_data | **wdpp_tender_data** | created_at→create_time, 新增 update_time |
| keyword_pool | **wdpp_keyword_pool** | created_at→create_time, updated_at→update_time |
| search_log | **wdpp_search_log** | 新增 create_time, 新增 update_time |
| province_stats | **wdpp_province_stats** | last_updated→update_time, 新增 create_time |
| config_store | **wdpp_config_store** | updated_at→update_time, 新增 create_time |

### 待建表清单

| 管线 | 表名 |
|------|------|
| 国内客户 | `wdpp_domestic_leads`, `wdpp_domestic_lead_activities` |
| 国际客户 | `wdpp_intl_prospects`, `wdpp_intl_contacts`, `wdpp_intl_scoring_records`, `wdpp_intl_tariff_cache`, `wdpp_intl_outreach_logs`, `wdpp_intl_discovery_runs` |
| 竞争对手 | `wdpp_competitor_companies`, `wdpp_competitor_products`, `wdpp_competitor_product_specs`, `wdpp_competitor_materials`, `wdpp_competitor_cad_assets`, `wdpp_competitor_design_analysis`, `wdpp_competitor_updates` |

## Python 规范

- Python 3.10+
- 数据库: psycopg2 直连（不用 ORM，保持脚本轻量）
- HTTP: requests / httpx
- AI 调用: OpenAI 兼容 API（vLLM）
- 日志: Python logging，输出到 stdout（crontab 重定向到文件）

## 代码模板

### 数据库连接
```python
import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    "host": "localhost",
    "port": 5433,
    "dbname": "wande_ai",
    "user": "wande",
    "password": "wande_dev_2026"
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG)
```

### vLLM 调用
```python
import requests

def call_llm(prompt, temperature=0.3):
    resp = requests.post("http://localhost:8000/v1/chat/completions", json={
        "model": "/model",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
        "max_tokens": 2000
    })
    return resp.json()["choices"][0]["message"]["content"]
```

### SearXNG 搜索
```python
def search(query, num_results=10):
    resp = requests.get("http://localhost:8888/search", params={
        "q": query, "format": "json",
        "engines": "google,bing,duckduckgo", "language": "zh-CN"
    })
    return resp.json().get("results", [])[:num_results]
```

### Browser Agent
```python
def browse(url, task="提取页面主要内容"):
    resp = requests.post("http://localhost:9830/browse", json={
        "url": url, "task": task, "timeout": 30
    })
    return resp.json()
```

## 脚本命名规范

- `*_discovery.py` — 采集（Collect）
- `*_cleaner.py` — 清洗（Clean）
- `*_verifier.py` — 验证（Verify）
- `*_scorer.py` — 评分（Score）
- `*_sync.py` — 落库同步（Persist/Sync）
- `*_enricher.py` — 深挖丰富（Enrich）
- `*_pipeline.sh` — 管线编排

## Git 规范

- 分支: `feature/<pipeline>-<脚本名>` 从 `main` 拉取
- Commit: `feat(domestic_projects): 新增项目去重脚本`
- 直接合并到 `main`（本仓库暂无 dev 分支）
