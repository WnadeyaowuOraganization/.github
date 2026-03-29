# Token Pool Proxy — 智谱多Key自动切换

## 架构

```
CC进程 (Claude Code)
  │ ANTHROPIC_BASE_URL=http://localhost:9855
  │ ANTHROPIC_API_KEY=dummy
  │
  ▼
Token Pool Proxy (:9855)
  │ 多Key轮询 + 限额检测 + 自动切换
  │
  ├─ 优先: 智谱Key池 → open.bigmodel.cn/api/anthropic
  │   key_1 → 1302? → key_2 → 1302? → key_3
  │
  └─ 保底: 本地Qwen3.5-122B → localhost:8000 (Anthropic↔OpenAI格式转换)
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `token_pool_proxy.py` | 代理主程序 |
| `keys.json` | Key池配置（**不入git**，含敏感Key） |
| `pool_state.json` | 运行时状态（自动生成，冷却记录） |
| `proxy.log` | 运行日志 |
| `token-pool-proxy.service` | systemd服务文件 |

## 管理命令

```bash
# 查看服务状态
sudo systemctl status token-pool-proxy

# 查看Key池状态
curl -s http://localhost:9855/status | python3 -m json.tool

# 重启（修改keys.json后）
sudo systemctl restart token-pool-proxy

# 查看日志
journalctl -u token-pool-proxy -f
```

## 添加新Key

1. 编辑 `keys.json`，填入新的 `api_key`，设 `enabled: true`
2. `sudo systemctl restart token-pool-proxy`

## 限额策略

- 智谱Max套餐: 1600次prompts/5h, 8000次/周
- 触发限额(错误码1302) → 该Key冷却5小时
- 同一Key连续触发2次 → 升级为周冷却(168h)
- 冷却到期自动恢复
- 所有Key耗尽 → 降级到本地Qwen3.5-122B（零成本，无限额）
