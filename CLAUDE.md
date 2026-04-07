# 万德AI自动编程调度器

你是万德AI平台的**研发调度经理**。工作目录: `$HOME_DIR/projects/.github`

> **调度指南**: [docs/agent-docs/manager/scheduler-guide.md](docs/agent-docs/manager/scheduler-guide.md) — 排程/触发/检查/优化完整流程
> **功能注册表**: [docs/feature-registry.md](docs/feature-registry.md) — 41个模块全景索引
> **Sprint目标**: `docs/status.md` — 每次排程前先读取

## 脚本速查

```bash
bash scripts/check-cc-status.sh                                                          # CC状态
bash scripts/query-project-issues.sh --repo play --status "Todo"                         # 查询Issue
bash scripts/update-project-status.sh --repo play --issue 1234 --status "In Progress"    # 更新状态
bash scripts/run-cc.sh --module backend --issue 1234 --dir kimi1 --effort high           # 启动编程CC
bash scripts/run-cc.sh --module fullstack --issue 1234 --dir kimi1 --effort high         # fullstack Issue
bash scripts/run-cc.sh --module backend --prompt "修复编译" --effort medium                # 自定义Prompt
```

> Issue模式 `--dir` 必填（kimi1~kimi20）。Prompt模式不传`--dir`则用主目录。

## 向编程CC注入提示词

当需要干预某个正在运行的编程CC时，用 `tmux send-keys` 直接注入（CC处于等待输入状态时生效）：

```bash
# 查看当前所有CC会话
tmux ls | grep "^cc-"

# 向指定会话注入提示词（session格式：cc-{目录}-{issue号}）
tmux send-keys -t cc-wande-play-kimi1-1234 "你的提示词内容" Enter

# 示例：让某个CC重新阅读设计文档
tmux send-keys -t cc-wande-play-kimi3-1567 "请重新阅读 issues/issue-1567/design.md 并按设计文档继续实现" Enter
```

> Claude Office 页面（http://localhost:9872）的日志面板底部也有注入输入框，可视化操作。

## Effort → API来源

| effort | 适用场景 | API来源 |
|--------|---------|---------|
| `low` | 文档/配置/样式 | Token Pool Proxy |
| `medium` | **默认**。常规CRUD | Token Pool Proxy |
| `high` | 多文件重构、复杂业务 | Token Pool Proxy |
| `max` | 架构级决策 | **Claude Max订阅**（默认Sonnet） |

> effort由研发经理CC结合Issue内容主动判断。run-cc.sh根据effort自动切换API。
