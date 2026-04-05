#!/bin/bash
# 批量关闭已完成的 Issue
# 这些 Issue 的 PR 已合并，但 Issue 仍标记为 Open

REPO="WnadeyaowuOraganization/wande-play"
SCRIPT_DIR="/home/ubuntu/projects/.github/scripts"

# 已合并 PR 关联的 Issue 列表
ISSUES=(1471 1521 1526 1544 1701 171 1721 1782 1899 1934 2216 2355 2411 2474 2586 2591 2592)

echo "开始批量关闭已完成的 Issue..."
echo "================================"

for ISSUE in "${ISSUES[@]}"; do
    echo ""
    echo "处理 Issue #$ISSUE..."
    
    # 1. 关闭 Issue
    gh issue close $ISSUE --repo $REPO --comment "✅ 已完成并通过 CI 验证，PR 已合并到 dev 分支。" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ Issue #$ISSUE 已关闭"
    else
        echo "  ⚠ Issue #$ISSUE 关闭失败或已是关闭状态"
    fi
    
    # 2. 更新 Project 状态为 Done
    bash $SCRIPT_DIR/update-project-status.sh play $ISSUE "Done" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ Issue #$ISSUE Project 状态已更新为 Done"
    else
        echo "  ⚠ Issue #$ISSUE Project 状态更新失败"
    fi
    
    # 3. 移除 in-progress 标签（如果有）
    gh issue edit $ISSUE --repo $REPO --remove-label "status:in-progress" 2>/dev/null
    
    sleep 1
done

echo ""
echo "================================"
echo "批量处理完成"
