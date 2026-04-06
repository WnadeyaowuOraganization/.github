#!/bin/bash
# monitor-issue-2893.sh — 监控 Issue #2893（Claude Office全量迁移-P0）
# crontab: */20 * * * *

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="${HOME_DIR}/cc_scheduler/logs/monitor-2893.log"
REPO="WnadeyaowuOraganization/wande-play"
ISSUE=2893

mkdir -p "$(dirname "$LOGFILE")"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"; }

export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null)
export PATH="${HOME_DIR}/.local/bin:$PATH"

if [ -z "$GH_TOKEN" ]; then
    log "❌ 无法获取 GH_TOKEN，跳过本次检查"
    exit 1
fi

# === 获取 Issue 状态 ===
ISSUE_JSON=$(gh issue view "$ISSUE" --repo "$REPO" \
    --json number,title,state,updatedAt,projectItems,labels 2>/dev/null)

if [ -z "$ISSUE_JSON" ]; then
    log "❌ 无法查询 Issue #$ISSUE"
    exit 1
fi

STATE=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)
PROJECT_STATUS=$(echo "$ISSUE_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
items=d.get('projectItems',[])
print(items[0]['status']['name'] if items and 'status' in items[0] else 'Unknown')
" 2>/dev/null)
UPDATED_AT=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('updatedAt',''))" 2>/dev/null)

# 计算距上次更新的小时数
HOURS_SINCE=$(python3 -c "
from datetime import datetime, timezone
updated = datetime.fromisoformat('${UPDATED_AT}'.replace('Z','+00:00'))
now = datetime.now(timezone.utc)
diff = (now - updated).total_seconds() / 3600
print(f'{diff:.1f}')
" 2>/dev/null || echo "0")

log "Issue #$ISSUE | state=$STATE | project=$PROJECT_STATUS | 距更新=${HOURS_SINCE}h"

# === 如果已完成，静默退出 ===
if [ "$STATE" = "CLOSED" ] || [ "$PROJECT_STATUS" = "Done" ]; then
    log "✅ Issue #$ISSUE 已完成（$PROJECT_STATUS），停止监控"
    # 自动从 crontab 移除本脚本
    (crontab -l 2>/dev/null | grep -v "monitor-issue-2893") | crontab -
    log "✅ 已从 crontab 移除监控任务"
    exit 0
fi

# === 判断告警条件 ===
ALERT_LEVEL=""
ALERT_REASON=""
SUGGEST=""

case "$PROJECT_STATUS" in
    "Todo")
        if python3 -c "exit(0 if float('${HOURS_SINCE}') > 3 else 1)" 2>/dev/null; then
            ALERT_LEVEL="🔴 严重"
            ALERT_REASON="Issue #$ISSUE 已在 Todo 状态超过 ${HOURS_SINCE} 小时，研发经理CC尚未触发"
            SUGGEST="检查研发经理CC是否正常运行：\`tail -f ~/cc_scheduler/manager.log\`\n手动触发命令：\`bash scripts/run-cc.sh --module fullstack --issue 2893 --dir kimi1 --effort high\`"
        fi
        ;;
    "In Progress")
        # 检查是否有PR
        PR_COUNT=$(gh pr list --repo "$REPO" --search "$ISSUE" --state all --json number 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        # 检查CC是否在运行（tmux会话）
        CC_RUNNING=$(tmux list-sessions 2>/dev/null | grep -c "2893" || echo "0")
        # 检查CC日志是否存在且近1小时有更新
        CC_LOG=$(ls -t "${HOME_DIR}/cc_scheduler/logs/"*2893* 2>/dev/null | head -1)
        CC_LOG_FRESH="0"
        if [ -n "$CC_LOG" ]; then
            CC_LOG_AGE=$(python3 -c "
import os,time
mtime=os.path.getmtime('${CC_LOG}')
age=(time.time()-mtime)/3600
print(f'{age:.1f}')
" 2>/dev/null || echo "99")
            python3 -c "exit(0 if float('${CC_LOG_AGE}') < 1 else 1)" 2>/dev/null && CC_LOG_FRESH="1"
        fi

        if [ "$PR_COUNT" = "0" ]; then
            if [ "$CC_RUNNING" = "0" ] && [ "$CC_LOG_FRESH" = "0" ]; then
                # CC未运行且无日志活动 → 严重告警
                ALERT_LEVEL="🔴 严重"
                ALERT_REASON="Issue #$ISSUE 已在 In Progress 超过 ${HOURS_SINCE} 小时，编程CC**未在运行**，且无 PR"
                SUGGEST="研发经理CC未重新触发！请立即执行：\n\`\`\`\nbash scripts/run-cc.sh --module fullstack --issue 2893 --dir kimi1 --effort high\n\`\`\`\n或将状态重置回 Todo：\`bash scripts/update-project-status.sh --repo play --issue 2893 --status \"Todo\"\`"
            elif python3 -c "exit(0 if float('${HOURS_SINCE}') >= 3 else 1)" 2>/dev/null; then
                # CC在运行但超过3小时无PR → 普通警告
                ALERT_LEVEL="🟡 警告"
                ALERT_REASON="Issue #$ISSUE 已在 In Progress 超过 ${HOURS_SINCE} 小时，但尚未产生 PR"
                SUGGEST="检查编程CC是否仍在运行：\`tmux list-sessions | grep 2893\`\n查看日志：\`tmux attach -t cc-app-2893\`"
            fi
        fi
        ;;
    "Fail"|"E2E Fail")
        ALERT_LEVEL="🔴 严重"
        ALERT_REASON="Issue #$ISSUE 状态为 **$PROJECT_STATUS**"
        SUGGEST="清除重试计数：\`rm -f /tmp/cc-retry-app-2893\`\n重新触发：\`bash scripts/run-cc.sh --module fullstack --issue 2893 --dir kimi1 --effort high\`\n更新状态回 Todo：\`bash scripts/update-project-status.sh --repo play --issue 2893 --status \"Todo\"\`"
        ;;
    *)
        log "⚠️ 未知状态：$PROJECT_STATUS，跳过"
        ;;
esac

# === 发送告警评论 ===
if [ -n "$ALERT_LEVEL" ]; then
    log "⚠️ 触发告警：$ALERT_LEVEL — $ALERT_REASON"

    # 检查最近2小时内是否已发过告警（避免重复）
    RECENT_ALERT=$(gh issue view "$ISSUE" --repo "$REPO" --comments --json comments 2>/dev/null | \
        python3 -c "
import sys,json
from datetime import datetime,timezone
d=json.load(sys.stdin)
now=datetime.now(timezone.utc)
comments=d.get('comments',[])
recent=[c for c in comments if '自动监控告警' in c.get('body','') and
        (now-datetime.fromisoformat(c['createdAt'].replace('Z','+00:00'))).total_seconds()<7200]
print('yes' if recent else 'no')
" 2>/dev/null || echo "no")

    if [ "$RECENT_ALERT" = "yes" ]; then
        log "已在2小时内发过告警，跳过重复评论"
        exit 0
    fi

    BODY="## 🤖 自动监控告警 — $(date '+%Y-%m-%d %H:%M UTC')

**告警级别**: $ALERT_LEVEL
**当前状态**: $PROJECT_STATUS
**问题描述**: $ALERT_REASON

### 检查结果
- Issue 状态: $STATE
- Project#4 状态: $PROJECT_STATUS
- 距上次更新: ${HOURS_SINCE} 小时

### 建议操作
$SUGGEST

---
*此告警由 G7e 本地监控脚本自动生成（每20分钟检查一次）*"

    gh issue comment "$ISSUE" --repo "$REPO" --body "$BODY" 2>/dev/null && \
        log "✅ 告警评论已发送到 Issue #$ISSUE" || \
        log "❌ 发送评论失败"
else
    log "✅ 状态正常（$PROJECT_STATUS），无需告警"
fi
