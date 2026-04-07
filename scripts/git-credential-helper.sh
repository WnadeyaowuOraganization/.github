#!/bin/bash
# git-credential-helper.sh — Git credential helper（使用伟平PAT）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN=$(python3 "$SCRIPT_DIR/gh-app-token.py")
if [ -z "$TOKEN" ]; then exit 1; fi
echo "protocol=https"
echo "host=github.com"
echo "username=x-access-token"
echo "password=$TOKEN"
