#!/bin/bash
# run-cc-nohup.sh — 后台触发编程CC（不阻塞）
# 用法: run-cc-nohup.sh <repo> <issue_number>
set -e

REPO=$1
ISSUE=$2
LOGDIR=/var/log/coding-cc
mkdir -p $LOGDIR
LOGFILE=$LOGDIR/${REPO}-${ISSUE}.log
PIDFILE=$LOGDIR/${REPO}-${ISSUE}.pid

echo "[$(date)] Starting CC for ${REPO}#${ISSUE}" > $LOGFILE

case "$REPO" in
  backend)  PROJECT_DIR="/home/ubuntu/projects/wande-ai-backend" ;;
  front)    PROJECT_DIR="/home/ubuntu/projects/wande-ai-front" ;;
  pipeline) PROJECT_DIR="/home/ubuntu/projects/wande-data-pipeline" ;;
  *)        echo "Unknown repo: $REPO" >> $LOGFILE; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh")

nohup su - ubuntu -c "export GH_TOKEN=$GH_TOKEN && cd $PROJECT_DIR && claude -p \"拾取并完成 Issue #${ISSUE}\" --output-format text" >> $LOGFILE 2>&1 &
CC_PID=$!
echo $CC_PID > $PIDFILE
echo "[$(date)] CC PID: $CC_PID" >> $LOGFILE
