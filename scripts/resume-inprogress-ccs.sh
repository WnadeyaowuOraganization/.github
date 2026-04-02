#!/bin/bash
# 批量恢复In Progress Issue的编程CC

SCRIPT_DIR="/home/ubuntu/projects/.github/scripts"

# 启动CC的函数
start_cc() {
    local repo=$1
    local issue=$2
    local model=$3
    local suffix=$4

    echo "Starting CC for Issue #$issue on $suffix..."
    bash "$SCRIPT_DIR/run-cc.sh" "$repo" "$issue" "$model" "$suffix"
}

# Backend模块 Issues
start_cc "backend" 953 "claude-opus-4-6" "kimi1" &
sleep 2
start_cc "backend" 956 "claude-opus-4-6" "kimi2" &
sleep 2
start_cc "backend" 957 "claude-opus-4-6" "kimi3" &
sleep 2
start_cc "backend" 960 "claude-opus-4-6" "kimi5" &
sleep 2
start_cc "backend" 171 "claude-opus-4-6" "kimi6" &
sleep 2
start_cc "frontend" 1259 "claude-opus-4-6" "kimi7" &
sleep 2
start_cc "backend" 954 "claude-opus-4-6" "kimi8" &
sleep 2
start_cc "backend" 955 "claude-opus-4-6" "kimi9" &

echo "All CCs started. Waiting for initialization..."
sleep 5
tmux list-sessions | grep "cc-"
