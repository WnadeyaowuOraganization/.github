#!/bin/bash
# get-gh-token.sh — 统一GitHub Token入口
# 用法: source .../get-gh-token.sh 或 export GH_TOKEN=$(.../get-gh-token.sh)
# Token从/opt/wande-ai/tokens/读取，不硬编码
# e2e目录→wandeyaowu PAT / 其他→伟平PAT

TOKEN_DIR="/opt/wande-ai/tokens"

get_gh_token() {
  local cwd="${PWD:-$(pwd)}"
  if [[ "$cwd" == */wande-ai-e2e* ]]; then
    cat "$TOKEN_DIR/wandeyaowu.pat" 2>/dev/null
  else
    cat "$TOKEN_DIR/weiping.pat" 2>/dev/null
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  get_gh_token
else
  export GH_TOKEN=$(get_gh_token)
fi
