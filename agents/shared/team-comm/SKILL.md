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

每条消息**必须**包含 `【类型】-【回复标识】`，然后是内容。

类型只有4种，回复标识只有2种：

| 类型 | 回复标识 | 场景 |
|------|---------|------|
| 进度播报 | 【阅即可】 | 开工、阶段完成、PR提交 |
| 方案评审 | 【需回复】 | 技术决策、方案确认 |
| 异常发现 | 【需回复】 | 卡住、报错、依赖问题 |
| 需人工介入 | 【需回复】 | 结论前确认、CI连续失败 |

## 发送示例

编程CC汇报进度：

```bash
MSG="【进度播报】-【阅即可】 [#${ISSUE}] 后端编译通过，进入前端开发"
tmux send-keys -t 'manager-研发经理' "$MSG" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"success\"}" >/dev/null
```

编程CC卡住求助：

```bash
MSG="【异常发现】-【需回复】 [#${ISSUE}] Flyway报Unknown column，卡15分钟"
tmux send-keys -t 'manager-研发经理' "$MSG" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"warning\"}" >/dev/null
```

经理之间沟通：

```bash
MSG="【方案评审】-【需回复】 备选队列已更新，是否立即指派#4014？"
tmux send-keys -t 'manager-研发经理' "$MSG" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"manager-研发经理\",\"message\":\"$MSG\",\"type\":\"info\"}" >/dev/null
```

## 收到消息的规则

- 收到 **【需回复】** → **必须回复**，不能忽略
- 收到 **【阅即可】** → 无需回复
- **每轮巡检开始前**，先检查有无未回复的【需回复】消息，有则先回复

## 红线

1. 禁止发裸消息（必须有【类型】-【回复标识】）
2. 禁止只发tmux不发notify（双通道缺一不可）
3. 禁止忽略【需回复】
