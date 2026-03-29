#!/bin/bash
# gh-wrapper.sh — 设置GH_TOKEN后执行gh命令
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")
exec gh "$@"
