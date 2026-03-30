#!/bin/bash
# e2e_mid_tier.sh — 中层E2E测试（每15分钟，PR驱动）
# crontab: */15 * * * *
#
# 操作:
#   tmux attach -t e2e-mid          查看实时输出
#   tmux list-sessions              列出所有会话
#   Ctrl+B D                        脱离（测试继续运行）

LOCK_FILE="/home/ubuntu/cc_scheduler/e2e_mid.lock"
E2E_DIR="/home/ubuntu/projects/wande-ai-e2e"
SESSION="e2e-mid"

# 防止并发
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

# 如果tmux会话已存在，跳过
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exit 0
fi

export GH_TOKEN=$(bash /home/ubuntu/projects/.github/scripts/get-gh-token.sh)
export PATH="/home/ubuntu/.local/bin:$PATH"
export HOME="/home/ubuntu"

echo $$ > "$LOCK_FILE"

# 写入临时启动脚本，避免tmux内变量展开问题
TMP_SCRIPT="/tmp/e2e_mid_run_$$.sh"
cat > "$TMP_SCRIPT" <<INNEREOF
#!/bin/bash
export GH_TOKEN="$GH_TOKEN"
export ANTHROPIC_BASE_URL=http://localhost:9855
export PATH="/home/ubuntu/.local/bin:\$PATH"
export HOME="/home/ubuntu"
cd "$E2E_DIR"
echo [\$(date)] 中层E2E测试启动
claude -p '执行中层测试' --model glm-5.1 2>&1
EXIT_CODE=\$?
echo [\$(date)] 中层E2E结束 exit=\$EXIT_CODE
rm -f "$LOCK_FILE"
sleep 1
tmux kill-session -t "$SESSION"
INNEREOF
chmod +x "$TMP_SCRIPT"

tmux new-session -d -s "$SESSION" "bash $TMP_SCRIPT"

echo "✓ 中层E2E已在tmux会话 '$SESSION' 中启动"
echo "  查看: tmux attach -t $SESSION"
