# 运行环境

## G7e 服务器

```
IP: 3.211.167.122
OS: Ubuntu 22.04
GPU: NVIDIA L4 × 4
```

## 数据库（G7e 本地 PostgreSQL）

```
Host: localhost
Port: 5433
DB:   wande_ai
User: wande
Pass: wande_dev_2026
```

## AI 模型

```
vLLM:    localhost:8000  (Qwen3.5-122B-A10B-FP8)
模型ID:  /model
```

## 搜索引擎

```
SearXNG: localhost:8888  (WebSearch 首选)
Bing:    通过 Claude Code 内置 WebSearch（备用）
```

## Browser Agent

```
端口: 9830
API:  POST /browse, POST /screenshot, GET /health
用途: 需要渲染 JavaScript 的网站采集
```

## 部署路径

```
当前: /opt/agent/（旧散落脚本，逐步迁移中）
目标: /opt/wande-play/pipeline/（本仓库 clone 路径）
```
