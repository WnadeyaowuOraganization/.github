#!/bin/bash
# m2-cc-prepare.sh — 为单个 CC 准备独立的 maven repo（tmpfs，与其他 CC 完全隔离）
#
# 设计：
#   1. /dev/shm/m2-base/repository  (tmpfs 共享 base，所有 CC 第一次启动时 cp 一份)
#   2. /dev/shm/m2-cc-<KIMI>/repository  (per-CC 写入区，cp -a base 一份)
#   3. /dev/shm/m2-cc-refcount  (引用计数文件)
#
# 输出（stdout）: 一行 MAVEN_OPTS 字符串供调用方 export 到 tmux
# 调用方：scripts/run-cc.sh
# 用法: bash m2-cc-prepare.sh <KIMI_TAG>
set -e

KIMI_TAG="$1"
if [ -z "$KIMI_TAG" ]; then
    echo "用法: $0 <KIMI_TAG>" >&2
    exit 1
fi

BASE_SRC="/home/ubuntu/.m2/repository"
SHM_BASE="/dev/shm/m2-base/repository"
SHM_CC="/dev/shm/m2-cc-${KIMI_TAG}/repository"
REFCOUNT="/dev/shm/m2-cc-refcount"
LOCKFILE="/dev/shm/m2-cc-prepare.lock"

if [ ! -d "$BASE_SRC" ]; then
    echo "[m2-prepare] ERROR: base 不存在 $BASE_SRC" >&2
    echo "[m2-prepare] 请先运行 docs/workflow/maven-base-rebuild.md 生成 base" >&2
    exit 2
fi

# === 引用计数 + base 加载（互斥）===
exec 9>"$LOCKFILE"
flock 9

# 加载 base 到 tmpfs（第一次）
if [ ! -d "$SHM_BASE" ] || [ -z "$(ls -A "$SHM_BASE" 2>/dev/null)" ]; then
    echo "[m2-prepare] 首次加载 base → $SHM_BASE" >&2
    mkdir -p "$SHM_BASE"
    cp -a "$BASE_SRC/." "$SHM_BASE/"
    SIZE=$(du -sh "$SHM_BASE" 2>/dev/null | awk '{print $1}')
    echo "[m2-prepare] base 加载完成 $SIZE" >&2
fi

# 创建 per-CC 写入区
if [ -d "$SHM_CC" ]; then
    echo "[m2-prepare] 警告: $SHM_CC 已存在，先清理" >&2
    rm -rf "/dev/shm/m2-cc-${KIMI_TAG}"
fi
mkdir -p "$SHM_CC"
cp -a "$SHM_BASE/." "$SHM_CC/"

# refcount +1
CUR=$(cat "$REFCOUNT" 2>/dev/null || echo 0)
NEW=$((CUR + 1))
echo "$NEW" > "$REFCOUNT"
echo "[m2-prepare] kimi=${KIMI_TAG} 准备完成 refcount=${NEW}" >&2

flock -u 9

# stdout: 给调用方使用的 MAVEN_OPTS
echo "-Dmaven.repo.local=${SHM_CC}"
