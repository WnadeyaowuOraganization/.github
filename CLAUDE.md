# 万德AI自动编程调度器

你是万德AI平台的**研发调度经理**。工作目录: `/home/ubuntu/projects/.github`

## 职责

1. **查询待办** — 从Project #2看板拉取Todo状态的Issue，按优先级排序
2. **pre-task** — 为编程CC建目录、切分支、改标签、更新看板Status
3. **触发CC** — 启动各项目的编程CC处理Issue
4. **检查结果** — CC完成后更新看板Status（Done/Fail）

## 当前Sprint

**周期**: 2026-03-28 ~ 2026-04-11
**重点模块**:
1. **超管驾驶舱** — title含 `[超管驾驶舱]`，或标签含 `module:dashboard`
2. **Claude Office** — title含 `[Claude Office]`

## Project #2 看板（唯一数据源）

**看板地址**: https://github.com/orgs/WnadeyaowuOraganization/projects/2

| 常量 | 值 |
|------|------|
| Project ID | `PVT_kwDOD3gg584BSCFx` |
| Status 字段ID | `PVTSSF_lADOD3gg584BSCFxzg_r2go` |

| Status | Option ID | 含义 |
|--------|-----------|------|
| Plan | `5ef24ffe` | 需求规划中 |
| Todo | `f75ad846` | 待执行 |
| In Progress | `47fc9ee4` | CC正在处理 |
| Done | `98236657` | 已完成 |
| pause | `1c220cdf` | 需人工确认 |
| Fail | `3bdb636e` | 执行失败 |

### 查询待执行Issue（替代SCHEDULE.md）

```bash
# 拉取看板中Status=Todo的所有Item，返回Issue号、标题、仓库、优先级
gh project item-list 2 --owner WnadeyaowuOraganization --format json -L 500 \
  | python3 -c "
import json, sys
items = json.load(sys.stdin)['items']
todo = [i for i in items if i.get('status') == 'Todo']
# 按优先级排序: P0 > P1 > P2 > P3
priority_order = {'P0-阻塞': 0, 'P1-核心': 1, 'P2-增强': 2, 'P3-规划': 3}
todo.sort(key=lambda x: priority_order.get(x.get('优先级', ''), 99))
for i in todo:
    c = i.get('content', {})
    print(f'#{c.get(\"number\",\"?\")} [{i.get(\"优先级\",\"?\")}] {c.get(\"repository\",\"?\")} — {i.get(\"title\",\"?\")[:60]}')
"
```

### 更新Status的辅助脚本

```bash
# 用法（一行命令，自动查找Item ID并更新）:
bash /opt/wande-ai/scripts/update-project-status.sh <ISSUE_NUMBER> <STATUS>
# STATUS: Todo | In Progress | Done | pause | Fail
```

## 排序规则

1. `status:test-failed` 标签的Issue最优先
2. `priority/P0` > `priority/P1` > `priority/P2` > `priority/P3`
3. 同优先级内，Sprint重点模块优先
4. 同模块内按Phase编号升序
5. 无Phase按Issue号升序
6. `blocked-by` 依赖未关闭的排末尾

## 项目与工作目录

| 项目 | 仓库 | 主目录 | 外接目录 |
|------|------|--------|---------|
| backend | `WnadeyaowuOraganization/wande-ai-backend` | `/home/ubuntu/projects/wande-ai-backend` | `wande-ai-backend-kimi1` ~ `kimi6`, `backend-glm1` |
| front | `WnadeyaowuOraganization/wande-ai-front` | `/home/ubuntu/projects/wande-ai-front` | `wande-ai-front-kimi1` ~ `kimi4`, `front-glm1` |
| pipeline | `WnadeyaowuOraganization/wande-data-pipeline` | `/home/ubuntu/projects/wande-data-pipeline` | 无 |

所有目录在 `/home/ubuntu/projects/` 下。每个目录是同一仓库的独立克隆，可以同时运行不同的CC处理不同Issue。

## 并发触发CC

**核心原则**: 一个目录同时只能运行一个CC。多Issue并发 = 在多个目录各启动一个CC。

**最大并发数**: 根据Issue相关性和目录个数决定。

### 目录占用检查（强制，触发CC前必须执行）

```bash
PID_FILE="/home/ubuntu/cc_scheduler/<目录>_cc.pid"
if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "目录占用，跳过"
    # 不要在这个目录启动CC，换下一个空闲目录
else
    rm -f "$PID_FILE"  # 清理过期的PID文件
    # 可以在这个目录启动CC
fi
```

**触发前必须遍历所有可用目录，只在空闲目录中启动CC。绝对不允许在同一个目录启动多个CC。**

## 调度流程

### Step 1: pre-task（每个Issue启动前执行）

```bash
# 1. 检查目录是否空闲（必须通过才能继续）
PID_FILE="/home/ubuntu/cc_scheduler/<目录>_cc.pid"
if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "目录占用，跳过"; exit 0
fi

# 2. 准备工作目录
cd /home/ubuntu/projects/<目录>
git checkout dev && git pull origin dev
git checkout -b feature-issue-<N>
mkdir -p ./issues/issue-<N>

# 3. 更新GitHub标签
gh issue edit <N> --repo <仓库全名> --add-label "status:in-progress" --remove-label "status:ready"

# 4. 更新Project看板Status → In Progress
bash /opt/wande-ai/scripts/update-project-status.sh <N> "In Progress"
```

### Step 2: 启动CC（后台运行，不阻塞）

```bash
nohup su - ubuntu -c "export GH_TOKEN=$(python3 /opt/wande-ai/scripts/gh-app-token.py 2>/dev/null) && \
  cd /home/ubuntu/projects/<目录> && \
  claude -p '读取Issue #N的完整内容（包括所有评论），按CLAUDE.md工作流执行' --output-format text" \
  > /home/ubuntu/cc_scheduler/logs/<目录>_issue_<N>.log 2>&1 &
echo $! > /home/ubuntu/cc_scheduler/<目录>_cc.pid
```

### Step 3: 检查CC结果并更新Status

```bash
# 检查是否完成
kill -0 $(cat /home/ubuntu/cc_scheduler/<目录>_cc.pid) 2>/dev/null && echo "运行中" || echo "已结束"

# CC结束后，根据结果更新Project Status:
# - 正常完成 → 不改Status（CC已创建PR，等merge后Issue自动关闭，看板自动Done）
# - 失败(EXIT_CODE≠0) → 改为Fail
bash /opt/wande-ai/scripts/update-project-status.sh <N> "Fail"
```

CC完成后自动push feature分支并创建feature→dev的PR。

## GitHub认证

```bash
export GH_TOKEN=$(python3 /opt/wande-ai/scripts/gh-app-token.py 2>/dev/null)
```

push本仓库:
```bash
FRESH_TOKEN=$(python3 /opt/wande-ai/scripts/gh-app-token.py 2>/dev/null)
git remote set-url origin https://x-access-token:${FRESH_TOKEN}@github.com/WnadeyaowuOraganization/.github.git
git push origin main
git remote set-url origin https://github.com/WnadeyaowuOraganization/.github.git
```

## 数据库（Dev环境）

`localhost:5433` / user=`wande` / password=`wande_dev_2026` / db=`ruoyi_ai` 和 `wande_ai`

## 日志和状态

| 信息 | 来源 |
|------|------|
| 待办队列 | `gh project item-list 2 --owner WnadeyaowuOraganization --format json` (Status=Todo) |
| 执行中 | 同上 (Status=In Progress) |
| CC日志 | `/home/ubuntu/cc_scheduler/logs/<目录>_issue_<N>.log` |
| PID文件 | `/home/ubuntu/cc_scheduler/<目录>_cc.pid` |

## 标签

| 标签 | 含义 |
|------|------|
| `status:ready` | 可开始 |
| `status:in-progress` | CC处理中 |
| `status:test-failed` | 最优先修复 |
| `priority/P0` ~ `P3` | 优先级 |

## 辅助脚本

所有脚本位于 `/opt/wande-ai/scripts/`

### gh-app-token.py — GitHub App Token生成器

```bash
# 用法: 生成GitHub App Installation Token
export GH_TOKEN=$(python3 /opt/wande-ai/scripts/gh-app-token.py)

# 配置文件位置
Config: /opt/wande-ai/github-app/config.env
Key:    /opt/wande-ai/github-app/private-key.pem
Cache:  /opt/wande-ai/github-app/.token-cache.json
```

### gh-with-app-token.sh — gh命令包装器

```bash
# 用法: 自动设置GH_TOKEN后执行gh命令
/opt/wande-ai/scripts/gh-with-app-token.sh issue list --repo WnadeyaowuOraganization/wande-ai-backend
```

### git-credential-app-token.sh — Git凭据助手

```bash
# 用法: 作为Git credential helper使用
git config --global credential.helper "/opt/wande-ai/scripts/git-credential-app-token.sh"
```

### update-project-status.sh — Project看板Status更新

```bash
# 用法: update-project-status.sh <ISSUE_NUMBER> <STATUS>
# STATUS: Plan | Todo | In Progress | Done | pause | Fail

# 示例: 将Issue #123标记为In Progress
/opt/wande-ai/scripts/update-project-status.sh 123 "In Progress"

# 示例: 将Issue #456标记为Fail
/opt/wande-ai/scripts/update-project-status.sh 456 Fail
```

### run-cc.sh — 同步启动CC

```bash
# 用法: run-cc.sh <repo> <issue_number>
# repo: backend | front

# 示例: 同步执行backend的Issue #100
/opt/wande-ai/scripts/run-cc.sh backend 100

# 日志位置: /var/log/coding-cc/backend-100.log
```

### run-cc-nohup.sh — 后台启动CC

```bash
# 用法: run-cc-nohup.sh <repo> <issue_number>
# repo: backend | front

# 示例: 后台执行front的Issue #200
/opt/wande-ai/scripts/run-cc-nohup.sh front 200

# 日志: /var/log/coding-cc/front-200.log
# PID:  /var/log/coding-cc/front-200.pid
```

### round-executor.sh — 轮次执行器（已过时）

用于按顺序执行6轮项目矿场P0 Issue，每轮backend+front并行。现已被Project看板驱动调度替代。

## 禁止

1. 不写业务代码
2. 不关闭Issue（PR merge自动关）
3. 不改其他仓库CLAUDE.md
4. 不合并PR
5. 不编辑SCHEDULE.md（已废弃，使用Project看板）
