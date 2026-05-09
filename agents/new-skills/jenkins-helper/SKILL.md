---
name: jenkins-helper
description: 编程CC专用Jenkins CI操作工具箱。封装构建触发、状态轮询、日志提取、结果判断，提供可直接复制的 bash 函数和调用示例。CC 不应直接拼接 curl Jenkins 命令，应使用本 skill 提供的标准化函数。
---

# Jenkins CI 操作工具箱

> **⚠️ GitHub Actions 已废弃**。所有 CI 操作必须通过 Jenkins，禁止使用 `gh run list/view/rerun`。

## 常量（全局）

```bash
JENKINS_URL="http://54.234.200.59:18080"
JENKINS_JOB="wande-play-pr"
JENKINS_CONSOLE="${JENKINS_URL}/jenkins/job/${JENKINS_JOB}"
GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py 2>/dev/null)
REPO="WnadeyaowuOraganization/wande-play"
```

## 1. 手动触发构建

### 场景：webhook 延迟或未触发时

```bash
# 触发 PR 构建（PR 刚创建或 push 后 webhook 未响应）
trigger_jenkins() {
  local pr_num=$1
  local branch=$2  # feature-Issue-XXX
  curl -s -X POST "${JENKINS_URL}/jenkins/generic-webhook-trigger/invoke?token=wande-play-pr" \
    -H "Content-Type: application/json" \
    -d "{\"pull_request\":{\"number\":${pr_num},\"head\":{\"ref\":\"${branch}\"}},\"action\":\"synchronize\"}"
  echo "触发完成"
}
```

**调用示例**：
```bash
trigger_jenkins 4529 "feature-Issue-2746"
```

### 场景：PR 分支已不存在（合并后分支被删除）

**不要**手动触发。此时分支不存在是因为 PR 已合并，Jenkins 会自动跳过构建（或 Build 结束后自动 exit 0）。无需任何操作。

## 2. 轮询构建状态

### 场景：提交 PR 后等待 CI 结果

```bash
# 轮询直到构建完成（前台阻塞，不可用后台 & / nohup / disown）
poll_jenkins() {
  local max_wait=${1:-600}  # 默认 10 分钟超时
  local elapsed=0
  local interval=20

  echo "⏳ 轮询 Jenkins（超时 ${max_wait}s）..."
  while [ $elapsed -lt $max_wait ]; do
    local build_info=$(curl -sf "${JENKINS_CONSOLE}/lastBuild/api/json?tree=number,result,building" 2>/dev/null)
    local building=$(echo "$build_info" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('building',True))" 2>/dev/null)
    local result=$(echo "$build_info" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result') or 'RUNNING')" 2>/dev/null)
    local bnum=$(echo "$build_info" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('number',''))" 2>/dev/null)

    echo "[$(date '+%H:%M:%S')] Build #${bnum} building=$building result=$result"

    if [ "$building" = "False" ]; then
      if [ "$result" = "SUCCESS" ]; then
        echo "✅ CI 通过，Jenkins 将自动 squash-merge"
        return 0
      else
        echo "❌ CI 失败（result=$result），切换 fix-ci-failure"
        return 1
      fi
    fi

    sleep $interval
    elapsed=$((elapsed + interval))
  done

  echo "⏰ 超时（${max_wait}s）"
  return 2
}
```

**调用示例**：
```bash
poll_jenkins 600  # 等 10 分钟
```

## 3. 获取构建日志

### 场景：CI 失败后定位根因

```bash
# 获取构建失败原因（自动提取关键错误行）
get_jenkins_error() {
  local build_num=${1:-lastBuild}
  local console_url="${JENKINS_CONSOLE}/${build_num}/consoleText"

  echo "📋 获取 Build #${build_num} 日志: ${console_url}"
  echo "--- 关键错误 ---"

  curl -sf "${console_url}" 2>/dev/null | \
    grep -v '^\[Pipeline\]' | \
    grep -v '^$' | \
    grep -E 'ERROR|FAIL|❌|失败|exit code [1-9]|Tests run.*Errors|Failed:|^      at ' | \
    head -30
}
```

**调用示例**：
```bash
get_jenkins_error 101
# 或
get_jenkins_error lastBuild
```

### 获取完整日志（调试用）

```bash
curl -sf "${JENKINS_CONSOLE}/lastBuild/consoleText" 2>/dev/null | less
```

## 4. 判断构建结果

### 判断当前构建是否属于自己的 PR

```bash
# 检查 lastBuild 是否是当前 Issue 对应的 PR
is_my_pr_build() {
  local issue_num=$1
  local build_info=$(curl -sf "${JENKINS_CONSOLE}/lastBuild/api/json?tree=number,result,building,actions[parameters[name,value]]" 2>/dev/null)
  local build_pr=$(echo "$build_info" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for a in d.get('actions',[]):
    for p in a.get('parameters',[]):
        if p.get('name')=='PR_NUMBER': print(p.get('value',''))
" 2>/dev/null)

  if [ -n "$build_pr" ] && [ "$build_pr" = "$issue_num" ]; then
    return 0  # 是我的 PR
  else
    echo "⚠️ Build 是其他 PR(#${build_pr})，等待..."
    return 1
  fi
}
```

## 5. 完整流程示例

### 提 PR 后等待合并

```bash
# 1. PR 已创建，触发 Jenkins（如 webhook 未自动触发）
trigger_jenkins 4529 "feature-Issue-2746"

# 2. 立即轮询 CI 结果
poll_jenkins 600

# 3. 如果失败，获取错误日志
if [ $? -ne 0 ]; then
  get_jenkins_error lastBuild
  # 然后切换到 fix-ci-failure skill
fi
```

### push 后重新触发 CI

```bash
# push 后 webhook 延迟未触发，手动触发
trigger_jenkins 4529 "feature-Issue-2746"
poll_jenkins 300
```

## 常见错误识别

| 错误关键词 | 含义 | 处理 |
|-----------|------|------|
| `❌ 门1失败` | PR body 有未勾 checkbox | 修改 PR 描述，将 \`- [ ]\` 改为 \`- [x]\` 后 push |
| `❌ 门2失败` | task.md 有未勾 checkbox | 修改 `issues/issue-N/task.md`，将 \`- [ ]\` 改为 \`- [x]\` 后 push |
| `❌ 门3失败` | 前端 PR 缺少截图 | 在 PR body 追加截图（\`![描述](url)\`）后 push |
| `❌ 门5失败` | E2E 文件硬编码 kimi 端口 | 改用相对路径/环境变量后 push |
| `mvn compile` 失败 | 后端编译错误 | 本地 `mvn compile` 复现 |
| `pnpm build:prod` 失败 | 前端构建错误 | 本地 `pnpm build` 复现 |
| `mvn test` 红 | 单元测试失败 | 本地跑测试 |
| `git fetch` exit 128 | 分支不存在 | PR 可能已合并，无需操作 |
| `groovy.*unexpected` | Jenkinsfile 语法错误 | 通知研发经理 |

## 反模式

- ❌ `gh run list` / `gh run view` — GitHub Actions 命令，已废弃
- ❌ 用 `curl ... | grep ...` 直接拼 shell 变量 — 改用 python3 json 解析
- ❌ 后台轮询 `curl ... &` / `nohup` / `disown` — CC 会失去状态感知，无法响应 inject-cc-prompt
- ❌ 分支不存在时反复重试触发 — 说明 PR 已合并，分支被自动删除，无需操作
- ❌ 拿到日志直接复制粘贴不动脑子 — 提取关键错误行，判断是否是质量门拦截（可自己修）还是代码问题（fix-ci-failure）
