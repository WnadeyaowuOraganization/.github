#!/bin/bash
HOME_DIR="${HOME_DIR:-/home/ubuntu}"
# release-cc-lock.sh — 释放外接目录的指派锁
# 用法: release-cc-lock.sh --issue <N>
# 触发: issue-sync.yml Issue关闭时调用

ISSUE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --issue) ISSUE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$ISSUE" ]; then
  echo "用法: $0 --issue <N>"
  exit 1
fi

# 扫描所有kimi目录找到对应的锁
FOUND=false
for dir in ${HOME_DIR}/projects/wande-play-kimi{1..20} ${HOME_DIR}/projects/wande-gh-plugins-kimi{1..20}; do
  [ ! -f "$dir/.cc-lock" ] && continue
  LOCK_ISSUE=$(grep "^issue=" "$dir/.cc-lock" 2>/dev/null | cut -d= -f2)
  if [ "$LOCK_ISSUE" = "$ISSUE" ]; then
    rm -f "$dir/.cc-lock"
    echo "✅ 释放锁: $(basename $dir) → Issue#${ISSUE}"
    FOUND=true
  fi
done

if [ "$FOUND" = "false" ]; then
  echo "未找到Issue#${ISSUE}的锁"
fi
