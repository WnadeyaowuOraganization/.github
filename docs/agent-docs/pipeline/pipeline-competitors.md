# 竞争对手采集管线

## 业务背景

系统性采集欧美前50家游乐设施公司的全维度技术资料，为D3参数化设计、投标决策提供竞品对标数据。

## 数据库表（7张，待建）

wdpp_competitor_companies / wdpp_competitor_products / wdpp_competitor_product_specs / wdpp_competitor_materials / wdpp_competitor_cad_assets / wdpp_competitor_design_analysis / wdpp_competitor_updates

**T1级6家**: KOMPAN, Landscape Structures, PlayCore, PlayPower, HAGS, Proludic
**T2级14家**: Lappset, Berliner, Playworld, Eibe, Wicksteed 等

## 管线流程（5步，待开发）

```
Step 1: 采集 (competitor_discovery.py) — Browser Agent 访问官网
Step 2: 清洗 (competitor_cleaner.py) — 统一单位/分类
Step 3: 验证 (competitor_verifier.py) — 交叉验证
Step 4: AI结构化 (competitor_analyzer.py) — vLLM 提取设计哲学
Step 5: 落库同步 (competitor_sync.py)
```

## 采集优先级

1. **T1级（6家）** — 全维度深度采集
2. **T2级（14家）** — 核心产品参数+设计理念
3. **T3级（30家）** — 基础公司信息+产品列表
