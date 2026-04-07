#!/bin/bash
# gh-wrapper.sh — 设置GH_TOKEN后执行gh命令
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py")
exec gh "$@"
