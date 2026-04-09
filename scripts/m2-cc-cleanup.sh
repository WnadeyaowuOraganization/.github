#!/bin/bash
# m2-cc-cleanup.sh — CC 退出时回收独立 maven repo
#
# 调用方：scripts/release-cc-lock.sh / cc-keepalive.sh
# 用法: bash m2-cc-cleanup.sh <KIMI_TAG>
#
# 行为：
#   1. rm -rf /dev/shm/m2-cc-<KIMI>/  (释放该 CC 的 ~600MB 内存)
#   2. refcount -1
#   3. 若 refcount=0，再 rm -rf /dev/shm/m2-base/  (释放共享 base ~600MB)
set -e

KIMI_TAG="$1"
if [ -z "$KIMI_TAG" ]; then
    echo "用法: $0 <KIMI_TAG>" >&2
    exit 1
fi

SHM_CC_DIR="/dev/shm/m2-cc-${KIMI_TAG}"
SHM_BASE_DIR="/dev/shm/m2-base"
REFCOUNT="/dev/shm/m2-cc-refcount"
LOCKFILE="/dev/shm/m2-cc-prepare.lock"

exec 9>"$LOCKFILE"
flock 9

if [ -d "$SHM_CC_DIR" ]; then
    rm -rf "$SHM_CC_DIR"
    echo "[m2-cleanup] 已释放 $SHM_CC_DIR" >&2
else
    echo "[m2-cleanup] $SHM_CC_DIR 不存在，跳过" >&2
fi

# refcount -1
CUR=$(cat "$REFCOUNT" 2>/dev/null || echo 0)
NEW=$((CUR - 1))
[ $NEW -lt 0 ] && NEW=0
echo "$NEW" > "$REFCOUNT"
echo "[m2-cleanup] kimi=${KIMI_TAG} 释放完成 refcount=${NEW}" >&2

# 全部 CC 都退了 → 释放 base
if [ "$NEW" -eq 0 ]; then
    if [ -d "$SHM_BASE_DIR" ]; then
        rm -rf "$SHM_BASE_DIR"
        rm -f "$REFCOUNT"
        echo "[m2-cleanup] 所有 CC 已退出，释放共享 base" >&2
    fi
fi

flock -u 9
