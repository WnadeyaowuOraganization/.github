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

while IFS='|' read -r pr_num branch updated_at; do
    [ -z "$pr_num" ] && continue

    # 查找这个 PR 最近的构建
    RECENT_BUILD=$(echo "$LAST_BUILDS" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for b in d.get('builds', []):
    pr = ''
    br = ''
    for a in b.get('actions', []):
        for p in a.get('parameters', []):
            if p.get('name') == 'PR_NUMBER': pr = p.get('value', '')
            if p.get('name') == 'BRANCH': br = p.get('value', '')
    if pr == '$pr_num' or br == '$branch':
        print(f\"\{b['number']}|\{b.get('result', 'RUNNING')}\")
        break
" 2>/dev/null)

    # 获取 PR 的最新 commit SHA
    PR_SHA=$(gh pr view "$pr_num" --repo "$REPO" --json headRefOid --jq '.headRefOid' 2>/dev/null | cut -c1-12)

    if [ -n "$RECENT_BUILD" ]; then
        BUILD_NUM=$(echo "$RECENT_BUILD" | cut -d'|' -f1)
        BUILD_RESULT=$(echo "$RECENT_BUILD" | cut -d'|' -f2)

        # 检查构建结果
        if [ "$BUILD_RESULT" = "SUCCESS" ] || [ "$BUILD_RESULT" = "null" ]; then
            echo "  PR #$pr_num ($branch): Build #$BUILD_NUM $BUILD_RESULT ✅ 跳过"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        # 构建失败：检查是否有新 commit（说明 CC 已修复）
        BUILD_SHA=$(grep -o "commit.*$branch" /home/ubuntu/.jenkins/jobs/wande-play-pr/builds/$BUILD_NUM/log 2>/dev/null | head -1)
        echo "  PR #$pr_num ($branch): Build #$BUILD_NUM $BUILD_RESULT — 检查是否有新 commit..."
        # 简化：失败的构建一律重新触发（CC 可能已 push 修复）
    fi

    # 触发 CI
    echo "  PR #$pr_num ($branch): 触发 CI"
    bash "$SCRIPTS_DIR/trigger-ci.sh" "$pr_num" "$branch" 2>/dev/null && \
        TRIGGERED=$((TRIGGERED + 1))

done <<< "$OPEN_PRS"

echo "=== 扫描完成: 触发 $TRIGGERED, 跳过 $SKIPPED ==="
