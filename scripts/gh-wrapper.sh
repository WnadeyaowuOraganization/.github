#!/bin/bash
# gh-wrapper.sh — 设置GH_TOKEN后执行gh命令
# 使用场景：gh-wrapper.sh issue list （快速包装 gh 命令）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GH_TOKEN已由caller设置，或自动获取
[ -n "$GH_TOKEN" ] || export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py")
exec gh "$@"
