---
name: team-comm
description: 团队沟通规范。所有CC和经理之间的消息必须使用此skill定义的格式。发送消息前、收到消息后、每轮巡检开始时自动触发。Use this skill whenever sending messages to other team members, replying to messages, reporting progress, asking for help, or any inter-agent communication via tmux.
---

# 团队沟通规范

> **所有角色强制遵守**：编程CC、研发经理、排程经理、测试CC、Quick Fix CC。
> 违反格式 = 消息无效，对方有权不处理。

## 通讯录

| 角色 | tmux 会话名 | 何时联系 |
|------|------------|---------|
| 研发经理 | `manager-研发经理` | 进度汇报 / 卡住求助 / 方案评审 / 结论确认 |
| 排程经理 | `manager-排程经理` | 依赖确认 / 排程疑问 / 环境问题 |
| 编程CC | `cc-wande-play-kimiN-ISSUE` | 注入提示词 / 修复指令 |
| Quick Fix CC | `quick-fix` | 甲方问题反馈 |
| Notify API | `POST http://localhost:9872/api/notify` | 所有消息的第二通道 |

## 消息格式（强制）

**每条消息必须包含**：`【类型】-【回复标识】`

```
【类型】-【回复标识】 内容
```

### 类型 × 回复标识 对照表

| 场景 | 类型 | 回复标识 | notify type |
|-----|------|---------|-------------|
| 开工/阶段完成/PR提交 | 进度播报 | 【阅即可】 | `success` |
| 方案评审/技术决策 | 方案评审 | 【需回复】 | `info` |
| 卡住/异常/依赖问题 | 异常发现 | 【需回复】 | `warning` |
| 结论前确认/人工介入 | 需人工介入 | 【需回复】 | `error` |

### 示例

```
✅ 正确：
【进度播报】-【阅即可】 [#3995] 后端编译通过，进入前端开发
【异常发现】-【需回复】 [#3995] Flyway脚本报Unknown column，卡15分钟
【方案评审】-【需回复】 #2367建议采用纯数据库操作，请确认
【需人工介入】-【需回复】 kimi3 CI连续3轮失败，需要人工排查

❌ 错误：
[CC-REPORT] [#3995] 后端完成     ← 缺少【类型】-【回复标识】
PR提交了                          ← 缺少所有格式
```

## 发送流程（双通道，缺一不可）

**必须同时发 tmux + notify**，只发一个 = 不完整。

### 使用 send-msg 脚本（推荐）

```bash
bash .claude/skills/team-comm/scripts/send-msg.sh \
  --to "manager-研发经理" \
  --type "进度播报" \
  --reply "阅即可" \
  --msg "[#${ISSUE}] 后端编译通过"
```

### 手动发送

```bash
MSG="【进度播报】-【阅即可】 [#${ISSUE}] 后端编译通过"
tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"success\"}" >/dev/null
```

## 收到消息的处理规则

| 收到的标识 | 你的动作 |
|-----------|---------|
| 【需回复】 | **必须回复**确认/决策/反馈，不能忽略 |
| 【阅即可】 | 无需回复，继续工作 |

### 巡检/操作前检查

**每轮巡检或每次开始新操作前**，先检查tmux会话中是否有未回复的`【需回复】`消息：
- 有 → **立即回复**，再执行工作
- 无 → 继续正常工作

## 消息模板速查

### 编程CC → 研发经理

```bash
# 开工
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "进度播报" --reply "阅即可" --msg "[#${ISSUE}] 开工：已读Issue+task.md，复杂度中等"

# 阶段完成
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "进度播报" --reply "阅即可" --msg "[#${ISSUE}] 后端完成：JUnit+API spec全绿"

# 卡住
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "异常发现" --reply "需回复" --msg "[#${ISSUE}] 卡15min：Flyway报错Unknown column"

# PR提交
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "进度播报" --reply "阅即可" --msg "[#${ISSUE}] PR #${PR} 已创建，轮询merge中"

# 结论前确认
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "需人工介入" --reply "需回复" --msg "[#${ISSUE}] 疑似问题不存在，请确认后再close"
```

### 经理 → 经理

```bash
# 排程经理 → 研发经理
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-研发经理" --type "方案评审" --reply "需回复" --msg "指派建议已更新，请按PLAN.md执行"

# 研发经理 → 排程经理
bash .claude/skills/team-comm/scripts/send-msg.sh --to "manager-排程经理" --type "进度播报" --reply "阅即可" --msg "kimi1/#3995 Done，空出1个CC槽位"
```

## ⛔ 红线

1. **禁止发裸消息** — 必须包含【类型】-【回复标识】
2. **禁止只发tmux不发notify** — 双通道缺一不可
3. **禁止忽略【需回复】** — 收到必须回复
4. **禁止用echo/printf代替tmux send-keys** — 消息必须到达对方会话
