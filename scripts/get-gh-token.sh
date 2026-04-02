#!/bin/bash
# get-gh-token.sh — 统一GitHub Token入口（优先GitHub App，独立rate limit）
# 用法: source .../get-gh-token.sh 或 export GH_TOKEN=$(.../get-gh-token.sh)
# 优先级: GitHub App token (独立rate limit 5000) → PAT (共享rate limit)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN_DIR="$SCRIPT_DIR/tokens"

get_gh_token() {
  local cwd="${PWD:-$(pwd)}"

  # e2e目录强制使用wandeyaowu PAT
  if [[ "$cwd" == */e2e* ]]; then
    cat "$TOKEN_DIR/wandeyaowu.pat" 2>/dev/null
    return
  fi

  # 优先GitHub App token（独立rate limit，不受PAT消耗影响）
  if command -v python3 &>/dev/null; then
    local app_token
    app_token=$(python3 "$SCRIPT_DIR/gh-app-token.py" 2>/dev/null)
    if [ -n "$app_token" ] && [ ${#app_token} -gt 10 ]; then
      echo "$app_token"
      return
    fi
  fi

  # Fallback: PAT
  cat "$TOKEN_DIR/weiping.pat" 2>/dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  get_gh_token
else
  export GH_TOKEN=$(get_gh_token)
fi
