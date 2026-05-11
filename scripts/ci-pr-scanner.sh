#!/bin/bash
# ci-pr-scanner.sh — 定时扫描 open PR，为需要 CI 的 PR 触发构建
# 由 Jenkins cron 触发，不依赖 GitHub webhook
# 逻辑：遍历 open PR → 对比最新 commit 与最近构建 → 缺失则触发
set +e

REPO="WnadeyaowuOraganization/wande-play"
JENKINS_URL="http://localhost:18080/jenkins"
SCRIPTS_DIR="/data/home/ubuntu/projects/.github/scripts"

# 优先使用缓存 token（由 refresh-gh-token.sh 维护），避免频繁调 GitHub App API 触发 rate limit
if [ -f /tmp/.gh-token.env ]; then
    export GH_TOKEN=$(bash -c 'source /tmp/.gh-token.env && echo $GH_TOKEN' 2>/dev/null)
fi
# 兜底：从 GitHub App 生成新 token
if [ -z "$GH_TOKEN" ]; then
    export GH_TOKEN=$(python3 "$SCRIPTS_DIR/gh-app-token.py" 2>/dev/null)
fi
if [ -z "$GH_TOKEN" ]; then
    echo "[scanner] GH_TOKEN 为空，退出"
    exit 1
fi

echo "=== CI PR Scanner $(date '+%Y-%m-%d %H:%M:%S') ==="

# 获取最后成功的构建信息
LAST_BUILDS=$(curl -sf "$JENKINS_URL/job/wande-play-pr/api/json?tree=builds[number,result,actions[parameters[name,value]]]" 2>/dev/null)

# 获取所有 open PR
OPEN_PRS=$(gh pr list --repo "$REPO" --state open --json number,headRefName,updatedAt --jq '.[] | "\(.number)|\(.headRefName)|\(.updatedAt)"' 2>/dev/null)

if [ -z "$OPEN_PRS" ]; then
    echo "[scanner] 没有 open PR"
    exit 0
fi

echo "[scanner] 发现 $(echo "$OPEN_PRS" | wc -l) 个 open PR"

TRIGGERED=0
SKIPPED=0

# 检查是否有运行中的构建（通过扫描本地 Jenkins build 目录）
# result 文件不存在 = 构建仍在运行
check_running_build() {
    local pr_num="$1"
    local branch="$2"
    local build_dir="/home/ubuntu/.jenkins/jobs/wande-play-pr/builds"

    for log_file in "$build_dir"/*/log; do
        [ -f "$log_file" ] || continue
        build_num=$(basename $(dirname "$log_file"))
        # result 文件不存在 → 构建仍在运行
        if [ ! -f "$build_dir/$build_num/result" ]; then
            # 从日志提取 PR_NUMBER 和 BRANCH
            pr_in_log=$(grep -m1 "PR_NUMBER=" "$log_file" 2>/dev/null | sed 's/.*PR_NUMBER=//' | tr -d ' \n' | cut -c1-20)
            branch_in_log=$(grep -m1 "BRANCH=" "$log_file" 2>/dev/null | sed 's/.*BRANCH=//' | tr -d ' \n' | cut -c1-30)
            if [ "$pr_in_log" = "$pr_num" ] || [ "$branch_in_log" = "$branch" ]; then
                echo "$build_num"
                return 0
            fi
        fi
    done
    return 1
}

# 检查 Jenkins 队列中是否已有该 PR 的待处理项（通过队列 API，无需认证）
check_queue() {
    local pr_num="$1"
    local JENKINS_QUEUE_JSON=$(curl -sf "${JENKINS_URL}/queue/api/json" 2>/dev/null)
    if [ -z "$JENKINS_QUEUE_JSON" ]; then
        return 1  # API 不可用，不阻止触发
    fi
    echo "$JENKINS_QUEUE_JSON" | python3 -c "
import json, sys, re
try:
    d = json.load(sys.stdin)
    for item in d.get('items', []):
        params = item.get('params', '')
        m = re.search(r'PR_NUMBER=([^\s&]+)', params)
        if m and m.group(1) == '$pr_num':
            print(f\"queue_id={item['id']} why={item.get('why','')[:60]}\")
            sys.exit(0)
    sys.exit(1)
except:
    sys.exit(1)
" 2>/dev/null
}

while IFS='|' read -r pr_num branch updated_at; do
    [ -z "$pr_num" ] && continue

    # 检查是否有运行中的构建
    RUNNING_BUILD=$(check_running_build "$pr_num" "$branch")
    if [ -n "$RUNNING_BUILD" ]; then
        echo "  PR #$pr_num ($branch): Build #$RUNNING_BUILD 正在运行，跳过"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # 检查 Jenkins 队列中是否已有该 PR
    QUEUE_ITEM=$(check_queue "$pr_num")
    if [ -n "$QUEUE_ITEM" ]; then
        echo "  PR #$pr_num ($branch): 已在队列 $QUEUE_ITEM，跳过"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # 查找这个 PR 最近的已完成构建
    RECENT_BUILD=$(echo "$LAST_BUILDS" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for b in d.get('builds', []):
    if b.get('result') == 'SUCCESS':
        pr = ''
        br = ''
        for a in b.get('actions', []):
            for p in a.get('parameters', []):
                if p.get('name') == 'PR_NUMBER': pr = p.get('value', '')
                if p.get('name') == 'BRANCH': br = p.get('value', '')
        if pr == '$pr_num' or br == '$branch':
            print(f\"\{b['number']}|SUCCESS\")
            break
" 2>/dev/null)

    if [ -n "$RECENT_BUILD" ]; then
        BUILD_NUM=$(echo "$RECENT_BUILD" | cut -d'|' -f1)
        echo "  PR #$pr_num ($branch): Build #$BUILD_NUM SUCCESS ✅ 跳过"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # 获取 PR 的最新 commit SHA（用于日志）
    PR_SHA=$(gh pr view "$pr_num" --repo "$REPO" --json headRefOid --jq '.headRefOid' 2>/dev/null | cut -c1-12)
    echo "  PR #$pr_num ($branch) SHA=$PR_SHA: 触发 CI"
    bash "$SCRIPTS_DIR/trigger-ci.sh" "$pr_num" "$branch" 2>/dev/null && \
        TRIGGERED=$((TRIGGERED + 1))

done <<< "$OPEN_PRS"

echo "=== 扫描完成: 触发 $TRIGGERED, 跳过 $SKIPPED ==="
