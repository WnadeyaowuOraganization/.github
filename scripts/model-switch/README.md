# Token Pool Proxy v3 — 多源Key自动切换

## 架构

```
CC进程 (Claude Code)
  │ ANTHROPIC_BASE_URL=http://localhost:9855
  │ ANTHROPIC_API_KEY=dummy
  │
  ▼
Token Pool Proxy (:9855) — 优先级路由
  │
  ├─ 优先1: 智谱直连Key池 → open.bigmodel.cn/api/anthropic
  │   zhipu_max_1 → 1302? → zhipu_max_2 → 1302? → zhipu_max_3
  │   (Anthropic Messages格式，零转换开销)
  │
  ├─ 优先2: 中转站Key池 → newapi.aiopus.org (OpenAI格式)
  │   aiopus_pool → Anthropic↔OpenAI自动格式转换
  │   (按量计费，无5h/周限额)
  │
  └─ 保底: 本地Qwen3.5-122B → localhost:8000 (Anthropic↔OpenAI格式转换)
      (零成本，无限额)
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `token_pool_proxy.py` | 代理主程序 v3 |
| `keys.json` | Key池配置（**不入git**，含敏感Key） |
| `keys.json.example` | Key配置模板（入git） |
| `pool_state.json` | 运行时状态（自动生成，冷却记录） |
| `proxy.log` | 运行日志 |
| `token-pool-proxy.service` | systemd服务文件 |

## 管理命令

```bash
# 查看服务状态
sudo systemctl status token-pool-proxy

# 查看Key池状态(现在包含type字段)
curl -s http://localhost:9855/status | python3 -m json.tool

# 重启（修改keys.json后）
sudo systemctl restart token-pool-proxy

# 查看日志
journalctl -u token-pool-proxy -f
```

## Key类型

### 1. zhipu (智谱直连)
- 使用Anthropic Messages API格式直连 `open.bigmodel.cn`
- 受Coding Plan限额 (1600次/5h, 8000次/周)
- 配置: `type: "anthropic_compat"`, `provider: "zhipu"`, `api_url: "https://open.bigmodel.cn/api/anthropic"`, `api_key: "xxx"`

### 2. anthropic_compat (Anthropic格式中转站)
- 使用Anthropic Messages API格式
- 支持 model_map 映射CC请求的模型名到中转站模型名
- model_map key使用Claude Code内置模型名: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- 配置: `type: "anthropic_compat"`, `api_url: "https://..."`, `api_key: "sk-..."`

### 3. openai_compat (OpenAI格式中转站)
- 使用OpenAI Chat Completions格式
- 代理自动做 Anthropic↔OpenAI 双向转换
- 配置: `type: "openai_compat"`, `api_url: "https://..."`, `api_key: "sk-..."`

## 添加新Key

1. 编辑 `keys.json`
2. 智谱直连: 添加 `type: "anthropic_compat"`, `provider: "zhipu"` 的entry
3. Anthropic格式中转站: 添加 `type: "anthropic_compat"` 的entry，含 `api_url`
4. OpenAI格式中转站: 添加 `type: "openai_compat"` 的entry，含 `api_url`
5. `sudo systemctl restart token-pool-proxy`

## 限额策略

- 智谱Max套餐: 1600次/5h, 8000次/周 → 冷却5h或168h
- 中转站余额不足 → 冷却30天(720h)
- 冷却到期自动恢复
- 所有Key耗尽 → 降级到本地Qwen3.5-122B（零成本，无限额）
