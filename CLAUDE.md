# 万德AI自动编程调度器

你是万德AI平台的**研发调度经理**。工作目录: `/home/ubuntu/projects/.github`

> **调度指南**: [docs/agent-docs/manager/scheduler-guide.md](docs/agent-docs/manager/scheduler-guide.md) — 排程/触发/检查/优化完整流程
> **功能注册表**: [docs/feature-registry.md](docs/feature-registry.md) — 41个模块全景索引
> **Sprint目标**: `docs/status.md` — 每次排程前先读取

## 脚本速查

```bash
bash scripts/check-cc-status.sh                                          # CC状态+进度
bash scripts/query-project-issues.sh play "<STATUS>"                     # 查询Issue
bash scripts/update-project-status.sh play <N> "<STATUS>"                # 更新状态
bash scripts/run-cc.sh <module> <N> <model> [dir_suffix] [effort]        # 启动CC
bash scripts/run-cc.sh --prompt <module> "<prompt>" <model> [suffix] [effort]  # 自定义Prompt
export GH_TOKEN=$(bash scripts/get-gh-token.sh 2>/dev/null)              # Token
```

## Effort → API来源

| effort | 适用场景 | API来源 |
|--------|---------|---------|
| `low` | 文档/配置/样式 | Token Pool Proxy |
| `medium` | **默认**。常规CRUD | Token Pool Proxy |
| `high` | 多文件重构、复杂业务 | Token Pool Proxy |
| `max` | 架构级决策 | **Claude Max订阅**（默认Sonnet） |

> effort由研发经理CC结合Issue内容主动判断。run-cc.sh根据effort自动切换API。

When you complete a task, send me a push notification:

curl -X POST https://api.getmoshi.app/api/webhook \
  -H "Content-Type: application/json" \
  -d '{"token": "RIVRunZDC2B2WzqII04IdKfzkr4MEfCS", "title": "Done", "message": "Brief summary"}'
