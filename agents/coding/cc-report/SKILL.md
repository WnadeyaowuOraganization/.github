---
name: cc-report
description: Report progress to manager CCs (研发经理/排程经理) at mandatory phases — start, stage-done, stuck, pre-conclusion, close — via the dual-channel tmux send-keys + HTTP /api/notify protocol. Enforces message format with type/reply markers, session identification, and forbids silent work or self-closing Issues without manager confirmation. Satisfies hard constraint #10 of Wande-Play programming CC prompt.
---

# 阶段性主动汇报（约束 10）

编程 CC **禁止静默工作**。必须在 4 个节点向研发经理主动汇报，通过 **tmux + notify 双通道**同时发送。

## 汇报时机（任一节点触发必发）

| 节点 | 何时 | notify type | 回复标识 |
|------|------|------------|---------|
| **start** | 读完 Issue + 写完 task.md，开始编码前 | `info` | `【阅即可】` |
| **stage-done** | 编译通过 / 单测绿 / PR 提交 / PR merged 等主要节点 | `success` | `【阅即可】` |
| **stuck** | 连续 10 分钟同一问题无进展 | `warning` | `【需回复】` |
| **close** | 提 PR 后发完工报告 | `success` | `【阅即可】` |
| **结论前** | 下"问题不存在 / 无需修改 / 已修复"结论前，**必须先汇报等研发经理确认**，禁止自行 close Issue | `warning` | `【需回复】` |

## 通讯录

| 角色 | tmux 会话名 | 何时联系 |
|------|------------|---------|
| 研发经理 | `manager-研发经理` | 进度 / 卡住 / 方案评审 / 结论确认 |
| 排程经理 | `manager-排程经理` | 依赖确认 / 排程疑问 |
| 自己 | `tmux display-message -p '#S'` 格式 `cc-wande-play-kimiN-ISSUE` | 消息 from 字段 |

## 双通道发送（强制）

每次发消息必须**同时**发 tmux 和 notify API（notify 让人工追溯）：

```bash
MSG="[#${ISSUE}] <一句话现状>"
TYPE=info   # info=进度 / warning=卡住 / success=阶段完成 / error=必须介入

# 1. tmux 发到对方会话（回车符不可省）
tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter

# 2. notify API（强制）
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"$TYPE\"}" >/dev/null
```

缺 notify = 研发经理收不到后台提示 = 被视为违反约束。

## 消息格式

### 标题格式

`【类型】-【回复标识】 一句话摘要`（≤ 50 字）

- **类型**：`方案评审` / `进度播报` / `异常发现` / `需人工介入`
- **回复标识**：
  - `【需回复】` 需要确认 / 决策 / 反馈
  - `【阅即可】` 同步信息，无需回复

### 完整消息模板

```markdown
【类型】-【回复标识】 一句话摘要
from: <你的 tmux 会话名>
to: <接收方 tmux 会话名>
=============
<消息内容，less is more>
```

## 四类汇报模板

### start — 开工

```bash
CONTENT='【进度播报】-【阅即可】 [#'${ISSUE}'] 开工：复杂度中等
from: cc-wande-play-kimi'${N}'-'${ISSUE}'
to: manager-研发经理
=============
对账结论：原型要求 5 张 KPI + 批量操作下拉 4 项，现有代码 KPI 未渲染、下拉 3 项 disabled。
复杂度：中等（前后端都涉及，6 个文件）
预计阶段：后端 Controller → 前端 index.vue → smoke + e2e → PR'

tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"cc-report-'${ISSUE}'","message":"[#'${ISSUE}'] 开工","type":"info"}'
```

### stage-done — 阶段完成

```bash
CONTENT='【进度播报】-【阅即可】 [#'${ISSUE}'] 后端完成：JUnit + Playwright API 全绿
from: cc-wande-play-kimi'${N}'-'${ISSUE}'
to: manager-研发经理
=============
mvn compile ✅
JUnit wande-ai 模块 Tests run:N Failures:0 ✅
Playwright API spec <module>.spec.ts 全绿 ✅
下一步：前端 index.vue'

tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"cc-report-'${ISSUE}'","message":"[#'${ISSUE}'] 后端完成","type":"success"}'
```

### stuck — 卡住求助

```bash
CONTENT='【异常发现】-【需回复】 [#'${ISSUE}'] 卡 15min：Flyway 脚本启动报 Unknown column
from: cc-wande-play-kimi'${N}'-'${ISSUE}'
to: manager-研发经理
=============
问题：启动报 Unknown column tenant_id in wdpp_project_mine
已尝试：
1. 检查 SQL 有 tenant_id 字段 → 有
2. reset-db + 重启 → 同错
3. 看 Flyway 日志 → 脚本 V20260414001 执行成功但表没真正建
可能方向：Flyway schema_history 残留旧版本记录
需要：人工确认是否可以 TRUNCATE flyway_schema_history'

tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"cc-report-'${ISSUE}'","message":"[#'${ISSUE}'] 卡住:Flyway","type":"warning"}'
```

### close — 完工

```bash
CONTENT='【进度播报】-【阅即可】 [#'${ISSUE}'] PR #'${PR}' 已创建，轮询 merge 中
from: cc-wande-play-kimi'${N}'-'${ISSUE}'
to: manager-研发经理
=============
PR: https://github.com/WnadeyaowuOraganization/wande-play/pull/'${PR}'
改动：后端 6 文件 + 前端 4 文件 + Flyway 1 脚本
自测：task.md 全勾 + 4 张截图贴 PR + Playwright smoke 4/4 ✅
门禁：pr-body-lint 通过
等待：CI + auto-merge'

tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"cc-report-'${ISSUE}'","message":"[#'${ISSUE}'] PR #'${PR}' 创建","type":"success"}'
```

#### close 阶段标准轮询模板（强制前台 + sleep infinity）

发完 close 汇报后，**必须**在主线程用下述标准模板等待 merge。**禁止**写后台 `poll-pr-*.sh` 脚本（会让主线程失去状态感知，研发经理 / 排程经理只能手动唤醒；另外 shell hook 会 block `sleep ≥ 5s` 的前台命令，写后台脚本也是在绕过 hook）。

> **🚨 反例（已发生 ×3 次，每次导致研发经理注入失效）：**
> ```bash
> # ❌ 错误：后台脚本 — 主线程退出，CC 进入空闲，经理 tmux send-keys 无人响应
> nohup bash /tmp/poll-pr-123.sh &
> disown
> # 此后 CC 再也收不到 inject-cc-prompt.sh 的 CI 失败注入
> # 经理必须手动 kill 会话、重新分配 kimi 槽位
> ```
> **只有前台 while 循环才能让 CC 保持"可被唤醒"状态。**

```bash
# 前台阻塞式轮询（主线程保持可响应，每次 sleep 180 由 CC 内置允许）
while true; do
  STATE=$(gh pr view --head "feature-Issue-${ISSUE}" \
    --repo WnadeyaowuOraganization/wande-play \
    --json state --jq '.state' 2>/dev/null)
  if [ "$STATE" = "MERGED" ]; then
    echo "✅ PR merged，等待 cc-lock-manager 释放 tmux 会话"
    break
  fi
  if [ "$STATE" = "CLOSED" ]; then
    # PR 被手动关闭（非 merge）→ 立刻 cc-report stuck
    break
  fi
  echo "PR state=${STATE:-unknown}, sleep 180"
  sleep 180   # 3 分钟一次，降低 gh API / tmux 刷新频率
done

# merged 后，不要退出 CC。cc-lock-manager.yml 会自动 kill 本 tmux 会话并释放 .cc-lock
sleep infinity
```

轮询过程中若 CI 红 / 失败 → 会收到 `inject-cc-prompt.sh` 注入的"❌ CI 失败"提示词，此时 `sleep 180` 会被 tmux 输入流打断，**立刻切 `fix-ci-failure` skill**。

### 结论前 — 禁止自行下结论

CC 下"问题不存在 / 无需修改 / 已是最新代码 / Bug 已被其他 PR 修复"等结论**必须先汇报**等确认：

```bash
CONTENT='【需人工介入】-【需回复】 [#'${ISSUE}'] 疑似问题不存在，请确认
from: cc-wande-play-kimi'${N}'-'${ISSUE}'
to: manager-研发经理
=============
调查结果：
- Issue 描述 "批量导出 disabled" 在当前 dev 分支未复现
- 看 git log: commit abc123 已经修过（2 天前 merged）
- 当前代码：v-bind:disabled="!vxeCheckboxChecked" 逻辑正确
建议：可否让我 close？或者需要我做什么验证？'

tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $CONTENT" Enter
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"cc-report-'${ISSUE}'","message":"[#'${ISSUE}'] 请确认结论","type":"warning"}'
```

**禁止**：未收到研发经理确认就 `gh issue close`。

## 与其他 CC 通讯

### 跨 CC 沟通标准流程

```bash
# 1. tmux 发详细内容（回车符不可省）
tmux send-keys -t '<对方会话>' "<完整消息>" Enter

# 2. notify 发摘要（强制）
curl -s -X POST http://localhost:9872/api/notify \
  -H 'Content-Type: application/json' \
  -d '{"session":"<对方会话>","message":"<≤50字 摘要>","type":"<info|success|warning|error>"}'
```

### 会话速查

| 场景 | notify type | 回复标识 |
|-----|-------------|---------|
| 方案评审 | `info` | 【需回复】 |
| 进度播报 | `success` | 【阅即可】 |
| 异常发现 | `warning` | 【需回复】 |
| 需人工介入 | `error` | 【需回复】 |

## 反模式

- ❌ 默默工作 30 分钟 / 1 小时不发任何汇报
- ❌ 只发 tmux 不发 notify（研发经理后台看不到）
- ❌ 只发 notify 不发 tmux（对方当前会话里没内容，回复困难）
- ❌ 卡住超 10 分钟还不汇报，继续瞎试
- ❌ PR 提了不发 close 汇报
- ❌ 自行 `gh issue close` 不等确认
- ❌ 回车符漏写 → tmux 消息没发送（停在输入框）
- ❌ 消息无 `from:` / `to:` 字段 → 人工追溯困难
- ❌ 一次汇报塞 500 字 → `less is more`
- ❌ 写 `/tmp/poll-pr-*.sh` / `nohup ... &` / `disown` 等**后台**轮询脚本（主线程失去状态感知，研发经理无法通过 inject-cc-prompt 唤醒；CI 红也吃不到失败注入）。**只用**本 skill「close 阶段标准轮询模板」（前台 `while` + `sleep 180` + 末尾 `sleep infinity`）
