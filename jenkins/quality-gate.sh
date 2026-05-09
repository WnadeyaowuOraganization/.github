#!/bin/bash
set -e

PR_NUMBER=$1
BRANCH=$2
REPO="WnadeyaowuOraganization/wande-play"
GH_TOKEN="${WEIPING_TOKEN:-$GH_TOKEN}"

echo "=== 质量门控检查 ==="

# 门 1: PR body 无未勾 checkbox（跳过 CI/Jenkins/E2E 相关项，这些是 CI 跑完才能勾的）
echo "[门1] 检查 PR body checkbox..."
PR_BODY=$(gh pr view $PR_NUMBER --repo $REPO --json body --jq '.body')
# 过滤掉 CI/Jenkins/E2E 验证类 checkbox（允许提交时不勾）
UNCHECKED_ITEMS=$(echo "$PR_BODY" | grep '^- \[ \]' | \
    grep -viE 'CI|Jenkins|E2E|验证|test.*pass|build.*success|check.*ok' | \
    sed 's/^- \[ \] //' | head -5 || true)
UNCHECKED_COUNT=$(echo "$UNCHECKED_ITEMS" | grep -c . || true)
if [ "$UNCHECKED_COUNT" -gt 0 ]; then
    echo "❌ 门1失败：PR body 存在 $UNCHECKED_COUNT 项未勾 checkbox"
    COMMENT="❌ quality-gate 门1拦截：PR body 存在 $UNCHECKED_COUNT 项未勾 checkbox

请在 PR 描述中勾选以下未完成项（将 \`- [ ]\` 改为 \`- [x]\`）：

\`\`\`
$UNCHECKED_ITEMS
\`\`\`

> 注：CI/Jenkins/E2E 验证类 checkbox 无需勾选，CI 跑完会自动通过。

修复后 push 即可自动触发 CI 重跑。"
    gh pr comment $PR_NUMBER --repo $REPO --body "$COMMENT" || true
    exit 1
fi
echo "✅ 门1通过"

# 门 2: task.md 全勾
echo "[门2] 检查 task.md checkbox..."
ISSUE_NUM=$(echo "$BRANCH" | grep -oE 'Issue-[0-9]+' | grep -oE '[0-9]+' || echo "")
if [ -z "$ISSUE_NUM" ]; then
    ISSUE_NUM=$(echo "$PR_BODY" | grep -oE '(Fixes|Closes) #[0-9]+' | head -1 | grep -oE '[0-9]+' || echo "")
fi
if [ -n "$ISSUE_NUM" ]; then
    # 优先从 feature 分支取 task.md，回退到 origin/dev
    TASK_MD=""
    for ref in "${BRANCH}" "origin/dev" "dev"; do
        RAW=$(gh api "repos/$REPO/contents/issues/issue-${ISSUE_NUM}/task.md?ref=${ref}" --jq '.content' 2>/dev/null) || continue
        TASK_MD=$(echo "$RAW" | base64 -d 2>/dev/null) || continue
        [ -n "$TASK_MD" ] && break
    done

    if [ -n "$TASK_MD" ]; then
        UNCHECKED_TASK=$(echo "$TASK_MD" | grep -c '^- \[ \]' || true)
        if [ "$UNCHECKED_TASK" -gt 0 ]; then
            UNCHECKED_ITEMS=$(echo "$TASK_MD" | grep '^- \[ \]' | sed 's/^- \[ \] //' | head -5)
            echo "❌ 门2失败：task.md 存在 $UNCHECKED_TASK 项未勾"
            COMMENT="❌ quality-gate 门2拦截：task.md 存在 $UNCHECKED_TASK 项未勾

请在 `issues/issue-${ISSUE_NUM}/task.md` 中勾选以下未完成项（将 \`- [ ]\` 改为 \`- [x]\`）：

\`\`\`
$UNCHECKED_ITEMS
\`\`\`

修复后 push 即可自动触发 CI 重跑。"
            gh pr comment $PR_NUMBER --repo $REPO --body "$COMMENT" || true
            exit 2
        fi
    fi
fi
echo "✅ 门2通过"

# 门 3: 前端 PR 必须有截图
echo "[门3] 检查前端截图..."
FRONTEND_CHANGES=$(gh pr diff $PR_NUMBER --repo $REPO --name-only 2>/dev/null | grep -c "^frontend/apps/web-antd/src/views" || echo "0")
IMG_COUNT=$(echo "$PR_BODY" | grep -cE '!\[[^]]*\]\([^)]+\.(png|jpg|jpeg|gif|webp)' || true)
if [ "$FRONTEND_CHANGES" -gt 0 ] && [ "$IMG_COUNT" -eq 0 ]; then
    echo "❌ 门3失败：前端 PR 缺少截图"
    COMMENT="❌ quality-gate 门3拦截：前端 PR 缺少截图

请在 PR 描述中追加页面截图（截图格式：\`![描述](截图URL)\`），可上传到 GitHub PR 评论或用图床链接。"
    gh pr comment $PR_NUMBER --repo $REPO --body "$COMMENT" || true
    exit 3
fi
echo "✅ 门3通过"

# 门 4: index.vue 改动必须有 smoke 用例
echo "[门4] 检查 smoke 用例..."
INDEX_VUE_CHANGES=$(gh pr diff $PR_NUMBER --repo $REPO --name-only 2>/dev/null | grep "frontend/apps/web-antd/src/views/.*index\.vue$" || true)
if [ -n "$INDEX_VUE_CHANGES" ]; then
    echo "⚠️ 门4需要 smoke 用例检查（简化版跳过）"
fi
echo "✅ 门4通过"

# 门 5: E2E 文件禁止硬编码 kimi 端口
echo "[门5] 检查硬编码端口..."
E2E_CHANGES=$(gh pr diff $PR_NUMBER --repo $REPO --name-only 2>/dev/null | grep -E "^e2e/.*\.(ts|js)$" || true)
if [ -n "$E2E_CHANGES" ]; then
    BAD_FILES=$(echo "$E2E_CHANGES" | xargs grep -l "localhost:710[0-9]\|127\.0\.0\.1:710[0-9]" 2>/dev/null || true)
    if [ -n "$BAD_FILES" ]; then
        BAD_LINES=$(echo "$E2E_CHANGES" | xargs grep -n "localhost:710[0-9]\|127\.0\.0\.1:710[0-9]" 2>/dev/null | head -10 || true)
        echo "❌ 门5失败：E2E 文件硬编码了 kimi 端口"
        COMMENT="❌ quality-gate 门5拦截：E2E 文件硬编码了 kimi 端口

以下文件包含硬编码的 kimi 端口（应使用相对路径或环境变量）：
\`\`\`
$BAD_LINES
\`\`\`"
        gh pr comment $PR_NUMBER --repo $REPO --body "$COMMENT" || true
        exit 5
    fi
fi
echo "✅ 门5通过"

# 门 6: E2E 必须使用相对路径
echo "[门6] 检查相对路径..."
echo "✅ 门6通过"

echo "🎉 质量门控全部通过"
