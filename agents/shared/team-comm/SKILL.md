---
name: team-comm
description: 团队沟通规范。所有CC和经理之间的消息必须使用此skill定义的格式。发送消息前、收到消息后、每轮巡检开始时自动触发。Use this skill whenever sending messages to other team members, replying to messages, reporting progress, asking for help, or any inter-agent communication via tmux.
---

# 团队沟通规范

> **所有角色强制遵守**。违反格式 = 消息无效，对方有权不处理。

## 通讯录

| 角色 | tmux 会话名 |
|------|------------|
| 研发经理 | `manager-研发经理` |
| 排程经理 | `manager-排程经理` |
| 编程CC | `cc-wande-play-kimiN-ISSUE` |
| Quick Fix CC | `quick-fix` |

## 消息格式

```
【类型】-【回复标识】 一句话摘要
from: <发送方tmux会话名>
to: <接收方tmux会话名>
=============
详细内容（less is more原则）
```

### 类型 × 回复标识

| 类型 | 回复标识 | 场景 |
|------|---------|------|
| CC-REPORT | 【阅即可】 | 编程CC汇报进度（开工/阶段完成/PR提交） |
| 方案评审 | 【需回复】 | 技术决策、方案确认 |
| 异常发现 | 【需回复】 | 卡住、报错、依赖问题 |
| 需人工介入 | 【需回复】 | 结论前确认、CI连续失败 |
| 进度播报 | 【阅即可】 | 经理之间同步信息 |

## 发送示例

### 编程CC开工汇报

```bash
CONTENT='【CC-REPORT】-【阅即可】 [#'"${ISSUE}"'] 开工：复杂度中等
from: cc-wande-play-kimi'"${KIMI_ID}"'-'"${ISSUE}"'
to: manager-研发经理
=============
对账结论：原型要求5个API，现状已有2个，需新增3个。
预计阶段：Schema → 后端CRUD → 单测 → PR
Blockers：无'

tmux send-keys -t 'manager-研发经理' "$CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d '{"session":"manager-研发经理","message":"【CC-REPORT】-【阅即可】 [#'"${ISSUE}"'] 开工","type":"success"}' >/dev/null
```

### 编程CC卡住求助

```bash
CONTENT='【异常发现】-【需回复】 [#'"${ISSUE}"'] 卡15min：Flyway报错
from: cc-wande-play-kimi'"${KIMI_ID}"'-'"${ISSUE}"'
to: manager-研发经理
=============
错误：Unknown column business_type in field list
已尝试：检查Entity字段映射、查看DB表结构
需要：确认是否需要新增Flyway迁移脚本'

tmux send-keys -t 'manager-研发经理' "$CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d '{"session":"manager-研发经理","message":"【异常发现】-【需回复】 [#'"${ISSUE}"'] Flyway报错卡住","type":"warning"}' >/dev/null
```

### 经理之间沟通

```bash
CONTENT='【方案评审】-【需回复】 备选队列已更新
from: manager-排程经理
to: manager-研发经理
=============
当前2个CC空位，建议指派：
1. #4014 线索统一池+评分(P0)
2. #4018 CRM opportunity整改(P0)
请确认是否立即指派。'

tmux send-keys -t 'manager-研发经理' "$CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d '{"session":"manager-研发经理","message":"【方案评审】-【需回复】 备选队列更新","type":"info"}' >/dev/null
```

## 收到消息的规则

- 收到 **【需回复】** → **必须回复**，格式同上（带from/to/内容）
- 收到 **【阅即可】** → 无需回复
- **每轮巡检开始前**，先检查有无未回复的【需回复】消息，有则先回复

## 红线

1. 禁止发裸消息（必须有【类型】-【回复标识】+ from/to）
2. 禁止只发tmux不发notify（双通道缺一不可）
3. 禁止忽略【需回复】
