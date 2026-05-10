# 研发经理工作流

> 当前角色：**研发经理**，负责指派、巡检、恢复和验证。

## 触发方式

执行 `/assign-workflow` 命令启动每轮巡检。

## 每轮巡检执行顺序（强制）

1. **检查未回复消息** — tmux 会话中有 `【需回复】` → 立即回复后再执行巡检
2. **任务一** — 指派（有空闲 kimi 槽位时）← **优先于响应消息**
3. **任务二** — 巡检 CC 进度（attention-only 模式）
4. **任务三** — 恢复异常 CC（SAVED / 超时）
5. **任务四** — 阶段性验证报告（≥3 个新 Done 时触发）
6. **PLAN.md 同步** — 更新当前运行表 + 指派历史表

---

## 任务一：补充席位（指派）

### 触发条件

| 条件 | 说明 |
|------|------|
| kimi 锁文件不存在 | Jenkins `release-cc-lock.sh` 在 PR merged + dev 部署成功后自动删除锁 |

### 正确时机（红线）

⛔ **CC 创建 PR 后，不能立即 kill session / 删锁**
⛔ **必须等 Jenkins pipeline 末尾「释放kimi锁」步骤执行**（即 dev 部署成功）

### 正确的锁释放链路

```
CC 写代码 → gh pr create → CC 自然退出（tmux session 消失）
    ↓ CI 跑完 → dev 部署成功 → PR merged
    ↓ Jenkins 调用 release-cc-lock.sh
→ 锁文件 /home/ubuntu/cc_scheduler/lock/wande-play-kimi{N}.lock 被删除
→ 槽位可指派新 Issue
```

### 执行步骤

```bash
# 1. 检查所有锁文件（判断槽位是否真正空闲）
#    注意：tmux session 消失 ≠ 槽位空闲！锁文件还在说明 CI 还在跑
for kimi in 1 2 3 4 5 6 7 8; do
  if [ -f "/home/ubuntu/cc_scheduler/lock/wande-play-kimi${kimi}.lock" ]; then
    issue=$(grep "^issue=" "/home/ubuntu/cc_scheduler/lock/wande-play-kimi${kimi}.lock" 2>/dev/null | cut -d= -f2)
    echo "kimi$kimi: LOCKED → #$issue"
  else
    echo "kimi$kimi: FREE (can assign)"
  fi
done

# 2. 启动新 CC（只对无锁的 kimi）
#    锁文件由 Jenkins 自动释放，不要手动删除
```

### 补充席位逻辑

- **指派建议表来源**：`sprints/sprint-<N>/PLAN.md` 中的「指派建议」表
- **优先级**：P1 > P2 > P3
- **同一 Issue 不能重复指派**：已在指派建议表划线（~~#N~~）的跳过

```bash
# 指派前必须做防重检查：
# 1. 该 Issue 是否已在某个锁文件里
for lock in /home/ubuntu/cc_scheduler/lock/wande-play-kimi*.lock; do
  if grep -q "^issue=<N>$" "$lock" 2>/dev/null; then
    held_by=$(basename "$lock" .lock | sed 's/wande-play-//')
    echo "Issue #<N> 已被 kimi=$held_by 持有，跳过"
    exit 0
  fi
done

# 2. 是否有重复 tmux 会话（run-cc.sh 可能并发触发）
if tmux ls 2>/dev/null | grep -q "cc-wande-play-kimi.*-<N>"; then
  echo "Issue #<N> 已有 tmux 会话，跳过"
  exit 0
fi

# 3. 指派示例
assignments=(
  "kimi2:2750:backend"
  "kimi6:2665:frontend"
)

for assignment in "${assignments[@]}"; do
  IFS=':' read -r kimi issue module <<< "$assignment"
  bash scripts/update-project-status.sh --repo play --issue "$issue" --status "In Progress"
  bash scripts/run-cc.sh --module "$module" --issue "$issue" --dir "$kimi" --effort medium &
done
wait

# 4. 更新 PLAN.md
#    - 指派建议表：已指派行标记为 ~~#N~~ + 已指派 kimiX
#    - 当前运行表：新增一行
#    - git add + commit + push
```

---

## 任务二：巡检 CC 进度（attention-only 模式）

### Step 1：拉取全场摘要

```bash
bash scripts/cc-check.sh
```

### Step 2：处理 attention CC

```bash
ATTENTION=$(curl -s http://localhost:9872/api/status \
  | jq -c '.agents[] | select(.needs_attention)')

if [ -z "$ATTENTION" ]; then
  echo "✓ 全场自监控中，本轮无需介入"
fi
```

### attention 触发条件

| 条件 | 原因字段 | 处理 |
|------|---------|------|
| `needs_attention: true` | server.py 规则引擎设置 | 查 `attention_reason` 字段 |
| 静默超时 | `静默 N 分钟无新输出` | 唤醒或 kill 重启 |
| 无 PR | `无 PR 已超时` | 注入 `gh pr create` |
| CI failure | `CI 失败` | 注入修复 |
| Fail 终态 | `CC 已放弃` | 标 Fail |

---

## 任务三：恢复异常 CC

```bash
bash scripts/cc-check.sh | grep "SAVED\|超时"
bash scripts/cc-diagnose-stuck.sh

# 重新触发
bash scripts/run-cc.sh --module <原module> --issue <N> --dir <原kimi目录> --effort <原effort>
```

---

## 任务四：阶段性验证报告

触发：自上次报告起累计 ≥3 个新 Done，或连续 2 个相同 Fail 原因。

```bash
bash scripts/query-project-issues.sh --repo play --status "Done" 2>/dev/null
bash scripts/query-project-issues.sh --repo play --status "Fail" 2>/dev/null
bash scripts/cc-check.sh
```

写入 `docs/workflow/新harness验证报告.md`。

---

## 故障兜底

| 现象 | 处理 |
|------|------|
| `gh` 401 | `export GH_TOKEN=$(python3 scripts/gh-app-token.py 2>/dev/null)` |
| `cc-check.sh` 报错 | `git pull` 同步最新版本 |
| tmux send-keys 特殊字符 | 用 `scripts/inject-cc-prompt.sh` |
| CC卡住诊断 | `bash scripts/cc-diagnose-stuck.sh` |

## 辅助 Agent

- `pr-reviewer.md` — AI PR 审查员 subagent
