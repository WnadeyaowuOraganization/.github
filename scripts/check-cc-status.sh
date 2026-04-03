#!/bin/bash
# check-cc-status.sh — 检查所有CC工作目录的占用状态
# 输出格式供研发经理CC直接解析，用于指派决策
#
# 用法: check-cc-status.sh
# 输出: 每行一个目录的状态（空闲/占用+Issue号+模块）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGDIR=/home/ubuntu/cc_scheduler/logs

# ── 收集所有 "claude -p" 主进程的 cwd ──
declare -A DIR_PID DIR_ISSUE DIR_MODULE

while IFS= read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    [ -z "$pid" ] && continue
    cwd=$(readlink /proc/$pid/cwd 2>/dev/null)
    [ -z "$cwd" ] && continue
    
    # 提取 Issue 号
    issue=$(ps -o args= -p $pid 2>/dev/null | grep -oP "Issue #\K\d+")
    
    # 提取 module（从 cwd 末尾判断）
    dir_base=$(basename "$cwd")
    case "$dir_base" in
        backend)  module="backend" ;;
        frontend) module="frontend" ;;
        pipeline) module="pipeline" ;;
        *)        module="app" ;;
    esac
    
    # 用 BASE_DIR（去掉子目录）作为 key
    case "$cwd" in
        */backend|*/frontend|*/pipeline)
            base_dir=$(dirname "$cwd")
            ;;
        *)
            base_dir="$cwd"
            ;;
    esac
    
    DIR_PID["$base_dir"]=$pid
    DIR_ISSUE["$base_dir"]=${issue:-"?"}
    DIR_MODULE["$base_dir"]=$module
done < <(ps -u ubuntu -o pid,args 2>/dev/null | grep "claude -p" | grep -v grep | awk '{print $1}')

# ── 输出表头 ──
echo "## CC工作目录状态 — $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "| 目录 | 状态 | Issue | 模块 | PID |"
echo "|------|------|-------|------|-----|"

# ── 逐个检查 wande-play kimi1~kimi20 ──
busy=0
free=0
free_list=""

for i in $(seq 1 20); do
    dir="/home/ubuntu/projects/wande-play-kimi${i}"
    if [ ! -d "$dir" ]; then
        echo "| kimi${i} | ❌ 不存在 | - | - | - |"
        continue
    fi
    
    if [ -n "${DIR_PID[$dir]}" ]; then
        echo "| kimi${i} | 🔵 占用 | #${DIR_ISSUE[$dir]} | ${DIR_MODULE[$dir]} | ${DIR_PID[$dir]} |"
        busy=$((busy + 1))
    else
        echo "| kimi${i} | 🟢 空闲 | - | - | - |"
        free=$((free + 1))
        free_list="${free_list}kimi${i} "
    fi
done

# ── 检查 gh-plugins 目录 ──
echo ""
echo "### 其他目录"
echo "| 目录 | 状态 | Issue | 模块 | PID |"
echo "|------|------|-------|------|-----|"

for dir in /home/ubuntu/projects/wande-gh-plugins /home/ubuntu/projects/wande-gh-plugins-glm1; do
    name=$(basename "$dir")
    if [ ! -d "$dir" ]; then
        continue
    fi
    if [ -n "${DIR_PID[$dir]}" ]; then
        echo "| $name | 🔵 占用 | #${DIR_ISSUE[$dir]} | ${DIR_MODULE[$dir]} | ${DIR_PID[$dir]} |"
    else
        echo "| $name | 🟢 空闲 | - | - | - |"
    fi
done

# ── E2E 目录 ──
for dir in /home/ubuntu/projects/wande-play-e2e-mid /home/ubuntu/projects/wande-play-e2e-top; do
    name=$(basename "$dir")
    if [ -n "${DIR_PID[$dir]}" ]; then
        echo "| $name | 🔵 占用 | #${DIR_ISSUE[$dir]} | ${DIR_MODULE[$dir]} | ${DIR_PID[$dir]} |"
    else
        echo "| $name | 🟢 空闲 | - | - | - |"
    fi
done

# ── 汇总 ──
echo ""
echo "### 汇总"
echo "- 占用: ${busy}/20"
echo "- 空闲: ${free}/20"
echo "- 可用目录: ${free_list:-无}"
