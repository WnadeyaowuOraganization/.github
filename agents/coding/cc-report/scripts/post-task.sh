#!/bin/bash
# post-task.sh — 统一版：编程CC完成后自动评论Issue+创建PR
# 由CI/CD在feature分支push后调用
# 位置: .github/scripts/post-task.sh
set -e

REPO_FULL="${REPO_FULL:-WnadeyaowuOraganization/wande-play}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

log() { echo -e "\033[0;32m>>> $1\033[0m"; }
warn() { echo -e "\033[1;33m>>> $1\033[0m"; }

# Step 1: 提取Issue号
log "Step 1: 提取Issue号..."
ISSUE_NUM=$(git log -1 --pretty=%s | grep -oP '#\K\d+' | head -1)
if [ -z "$ISSUE_NUM" ]; then
    warn "未从commit message中找到Issue号，跳过post-task"
    exit 0
fi
log "Issue: #$ISSUE_NUM, Branch: $BRANCH, Repo: $REPO_FULL"

# Step 2: 提取完成报告
log "Step 2: 提取完成报告..."
# 在monorepo中task.md可能在backend/issues/或frontend/issues/或根issues/
TASK_FILE=""
for dir in "./issues/issue-${ISSUE_NUM}" "./backend/issues/issue-${ISSUE_NUM}" "./frontend/issues/issue-${ISSUE_NUM}" "./pipeline/issues/issue-${ISSUE_NUM}"; do
    if [ -f "$dir/task.md" ]; then
        TASK_FILE="$dir/task.md"
        break
    fi
done

REPORT_FILE="/tmp/post_task_report_${ISSUE_NUM}.md"
if [ -n "$TASK_FILE" ]; then
    log "找到 $TASK_FILE"
    tail -50 "$TASK_FILE" | head -c 4000 > "$REPORT_FILE"
else
    warn "未找到task.md，使用commit message"
    git log -1 --pretty=%B > "$REPORT_FILE"
fi

# Step 3: 评论Issue
log "Step 3: 评论Issue #$ISSUE_NUM..."
gh issue comment "$ISSUE_NUM" --repo "$REPO_FULL" --body-file "$REPORT_FILE" 2>/dev/null || warn "评论失败"

# Step 4: 创建PR
log "Step 4: 创建PR ($BRANCH → dev)..."
EXISTING=$(gh pr list --repo "$REPO_FULL" --head "$BRANCH" --base dev --state open --json number --jq '.[0].number' 2>/dev/null || echo "")
if [ -n "$EXISTING" ]; then
    log "PR #$EXISTING 已存在"
else
    PR_TITLE=$(git log -1 --pretty=%s)
    # 注意：PR merge到dev分支不会自动关闭issue（dev不是默认分支）
    # sync-issue-closed.yml workflow会在issue手动关闭时同步看板状态
    gh pr create --repo "$REPO_FULL" --base dev --head "$BRANCH" \
        --title "$PR_TITLE" \
        --body "关联Issue: Closes #${ISSUE_NUM}

由CI/CD post-task自动创建。测试CC将在下一个周期执行E2E测试。

**注意**: PR merge到dev后，需要手动关闭issue或等待merge到main。" \
        2>/dev/null && log "PR创建成功" || warn "PR创建失败"
fi

rm -f "$REPORT_FILE"

# Step 5: 生成 post-task-summary.json (纯规则版 schema_version=1)
# 用途: 研发经理验收报告改读这里的预消化数据，避免每轮重复 raw gh 倒推
# 存储位置: 优先与 task.md 同级（项目内 issue 目录, 进 git track）
#          fallback: .github/post-task-summaries/ (集中目录, 仅当 task.md 缺失)
log "Step 5: 生成 summary.json..."
if [ -n "$TASK_FILE" ] && [ -f "$TASK_FILE" ]; then
    # 主路径: 跟 task.md 同级
    SUMMARY_FILE="$(dirname "$TASK_FILE")/post-task-summary.json"
    SUMMARY_LOCATION="co-located"
else
    # Fallback: 集中目录
    SUMMARY_DIR="/home/ubuntu/projects/.github/post-task-summaries"
    mkdir -p "$SUMMARY_DIR" 2>/dev/null
    SUMMARY_FILE="$SUMMARY_DIR/issue-${ISSUE_NUM}.json"
    SUMMARY_LOCATION="centralized-fallback"
fi

# 收集硬数据（git 统计）
BASE=$(git merge-base HEAD origin/dev 2>/dev/null || git merge-base HEAD dev 2>/dev/null || echo "HEAD~5")
COMMITS_COUNT=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
DIFF_STAT=$(git diff "$BASE..HEAD" --stat 2>/dev/null | tail -1 | tr -d '\n' || echo "")
FILES_CHANGED=$(echo "$DIFF_STAT" | grep -oP '\d+(?= file)' | head -1 || echo 0)
LINES_ADDED=$(echo "$DIFF_STAT" | grep -oP '\d+(?= insert)' | head -1 || echo 0)
LINES_DELETED=$(echo "$DIFF_STAT" | grep -oP '\d+(?= delet)' | head -1 || echo 0)
COMMIT_TITLES=$(git log "$BASE..HEAD" --pretty=format:'%s' 2>/dev/null | head -10 | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()], ensure_ascii=False))" 2>/dev/null || echo "[]")

# 收集硬数据（.cc-lock）— 2026-04-09 lock 路径迁移
# 从 git toplevel 反推 dirname,再用统一路径
GIT_TOP=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_DIR")
KIMI_DIRNAME=$(basename "$GIT_TOP")
LOCK_FILE="/home/ubuntu/cc_scheduler/lock/${KIMI_DIRNAME}.lock"
[ ! -f "$LOCK_FILE" ] && LOCK_FILE=""
LOCK_MODEL=""; LOCK_EFFORT=""; LOCK_MODULE=""; LOCK_DIR=""; LOCK_TS=""
if [ -n "$LOCK_FILE" ]; then
    LOCK_MODEL=$(grep '^model=' "$LOCK_FILE" 2>/dev/null | cut -d= -f2 | tr -d '\r')
    LOCK_EFFORT=$(grep '^effort=' "$LOCK_FILE" 2>/dev/null | cut -d= -f2 | tr -d '\r')
    LOCK_MODULE=$(grep '^module=' "$LOCK_FILE" 2>/dev/null | cut -d= -f2 | tr -d '\r')
    LOCK_DIR=$(grep '^dir=' "$LOCK_FILE" 2>/dev/null | cut -d= -f2 | tr -d '\r')
    LOCK_TS=$(grep '^timestamp=' "$LOCK_FILE" 2>/dev/null | cut -d= -f2 | tr -d '\r')
fi

NOW_TS=$(date +%s)
DURATION_MIN=0
[ -n "$LOCK_TS" ] && [ "$LOCK_TS" -gt 0 ] 2>/dev/null && DURATION_MIN=$(( (NOW_TS - LOCK_TS) / 60 ))

PR_NUM_RAW=$(gh pr list --repo "$REPO_FULL" --head "$BRANCH" --json number --jq '.[0].number // empty' 2>/dev/null || echo "")
PR_NUM_FIELD="null"
[ -n "$PR_NUM_RAW" ] && PR_NUM_FIELD="$PR_NUM_RAW"

# 写 JSON（schema_version=1, fallback=true 标识尚未做 LLM 摘要）
python3 - "$SUMMARY_FILE" "$ISSUE_NUM" "$BRANCH" "$LOCK_MODULE" "$LOCK_DIR" "$LOCK_MODEL" "$LOCK_EFFORT" \
    "$DURATION_MIN" "$COMMITS_COUNT" "$FILES_CHANGED" "$LINES_ADDED" "$LINES_DELETED" "$DIFF_STAT" "$PR_NUM_FIELD" "$COMMIT_TITLES" <<'PYEOF' || warn "summary 写入失败"
import json, sys
from datetime import datetime, timezone

(_, out, issue, branch, module, kdir, model, effort,
 duration, commits, files, added, deleted, diff_stat, pr_num, commit_titles_json) = sys.argv

try:
    titles = json.loads(commit_titles_json) if commit_titles_json else []
except Exception:
    titles = []

summary = {
    "issue": int(issue),
    "branch": branch,
    "module": module or "unknown",
    "kimi_dir": kdir or "unknown",
    "model": model or "unknown",
    "effort": effort or "medium",
    "pr_number": None if pr_num == "null" else int(pr_num),
    "duration_minutes": int(duration),
    "commits": int(commits),
    "commit_titles": titles,
    "files_changed": int(files),
    "lines_added": int(added),
    "lines_deleted": int(deleted),
    "diff_stat": diff_stat,
    "schema_version": 1,
    "fallback": True,  # schema 1 = 纯规则版，未做 LLM 摘要
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(out, "w") as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)
print(f"✓ summary written: {out}")
PYEOF

# 5.1 主路径(co-located): commit + push 让 summary 进 PR 历史
#     用 [skip ci] 避免触发额外的 pr-test.yml run
if [ "$SUMMARY_LOCATION" = "co-located" ] && [ -f "$SUMMARY_FILE" ]; then
    REL_PATH=$(realpath --relative-to="$(git rev-parse --show-toplevel 2>/dev/null || echo .)" "$SUMMARY_FILE" 2>/dev/null || echo "$SUMMARY_FILE")
    if git add "$SUMMARY_FILE" 2>/dev/null && git diff --cached --quiet -- "$SUMMARY_FILE"; then
        log "summary 与 git 中现有版本一致,跳过 commit"
    else
        git commit -m "chore(post-task): summary for issue #${ISSUE_NUM} [skip ci]" -- "$SUMMARY_FILE" 2>/dev/null \
            && git push origin "$BRANCH" 2>/dev/null \
            && log "✓ summary 已 commit + push: $REL_PATH" \
            || warn "summary commit/push 失败 (可能是 push 权限或网络),文件已写入但未上 git"
    fi
fi

log "post-task 完成 ✅"
