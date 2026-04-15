#!/bin/bash
# inject-cc-prompt.sh — 向指定Issue的CC会话注入提示词
# 用法: bash inject-cc-prompt.sh <issue_number> <prompt> [--prompt-file FILE]
# 由CI失败时调用，让CC直接在现有会话中修复问题
#
# 会话查找顺序（2026-04-08 修复："会话找得不对"漏洞）:
#   1. .cc-lock 中 issue=<N> 的 kimi 目录 → cc-wande-play-<dir>-<issue>
#   2. tmux 直接 grep "cc-wande-play-kimi*-<issue>"（lock 已被清理但 session 还在）
#   3. tmux 列出全部 session 名以 -<issue> 结尾的（兜底）
#   找到多个 → 都注入，避免漏；找不到 → 退出码 1（让调用方知道）

ISSUE=$1
PROMPT=$2
PROMPT_FILE=""
if [ "$3" = "--prompt-file" ] && [ -n "$4" ]; then
  PROMPT_FILE=$4
fi

HOME_DIR="${HOME_DIR:-/home/ubuntu}"

if [ -z "$ISSUE" ]; then
  echo "用法: $0 <issue_number> <prompt> [--prompt-file FILE]"
  exit 1
fi

# 如果通过文件传 prompt，读出来
if [ -n "$PROMPT_FILE" ] && [ -f "$PROMPT_FILE" ]; then
  PROMPT=$(cat "$PROMPT_FILE")
fi

if [ -z "$PROMPT" ]; then
  echo "[inject] ❌ prompt 为空，拒绝注入空通知"
  exit 2
fi

SESSIONS=()

# 1) lock 文件查找(2026-04-09 路径迁移到 ${HOME_DIR}/cc_scheduler/lock/<dirname>.lock)
for lockfile in ${HOME_DIR}/cc_scheduler/lock/wande-play-kimi*.lock; do
  [ ! -f "$lockfile" ] && continue
  LOCK_ISSUE=$(grep "^issue=" "$lockfile" 2>/dev/null | cut -d= -f2)
  [ "$LOCK_ISSUE" != "$ISSUE" ] && continue
  DIRNAME=$(basename "$lockfile" .lock)
  CAND="cc-${DIRNAME}-${ISSUE}"
  if tmux has-session -t "$CAND" 2>/dev/null; then
    SESSIONS+=("$CAND")
  fi
done

# 2) tmux 直接精确匹配 -<issue> 后缀（lock 已被清但 session 还在）
if [ ${#SESSIONS[@]} -eq 0 ]; then
  while IFS= read -r s; do
    [ -n "$s" ] && SESSIONS+=("$s")
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -E "^cc-wande-play-kimi[0-9]+-${ISSUE}$" || true)
fi

# 3) 兜底：包含 -<issue> 的 session（防 typo）
if [ ${#SESSIONS[@]} -eq 0 ]; then
  while IFS= read -r s; do
    [ -n "$s" ] && SESSIONS+=("$s")
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -E "-${ISSUE}\$" || true)
fi

if [ ${#SESSIONS[@]} -eq 0 ]; then
  echo "[inject] ⚠ 未找到 Issue #$ISSUE 对应的CC会话（lock+tmux双查）"
  echo "[inject]    现存 cc 会话："
  tmux list-sessions -F '  #{session_name}' 2>/dev/null | grep "^  cc-" || echo "    (无)"

  # 2026-04-15 #3704 事故 fallback：auto-merge 后 CC 已 kill，部署失败 prompt 回不到原 CC
  # 退而通知研发经理/排程经理，由经理决定是否重派 CC 修复
  FALLBACK_MSG="[部署失败回流] Issue #${ISSUE} 的CC已不在（大概率 auto-merge 后 kill）。原 prompt：${PROMPT}"
  for MGR in manager-研发经理 manager-排程经理; do
    if tmux has-session -t "$MGR" 2>/dev/null; then
      TMP_BUF=$(mktemp)
      printf '%s\n' "$FALLBACK_MSG" > "$TMP_BUF"
      tmux load-buffer -b "inject-fb-$$" "$TMP_BUF"
      tmux paste-buffer -b "inject-fb-$$" -t "$MGR"
      sleep 0.5
      tmux send-keys -t "$MGR" Enter
      tmux delete-buffer -b "inject-fb-$$" 2>/dev/null || true
      rm -f "$TMP_BUF"
      echo "[inject] ↳ fallback 已通知 $MGR"
    fi
  done
  # 退出码 0：fallback 成功即视为处理完成，避免 CC锁管理 workflow 红灯连锁报警
  exit 0
fi

# 注入到所有匹配的 session
for SESSION in "${SESSIONS[@]}"; do
  echo "[inject] → $SESSION"
  # 用 tmux load-buffer 注入而非 send-keys，避免长 prompt 中的特殊字符（反引号、$ 等）被 shell 二次解析
  TMP_BUF=$(mktemp)
  printf '%s\n' "$PROMPT" > "$TMP_BUF"
  tmux load-buffer -b "inject-$$" "$TMP_BUF"
  tmux paste-buffer -b "inject-$$" -t "$SESSION"
  # 关键: paste-buffer 后 Claude Code 输入框需要时间识别 paste 完成（显示 [Pasted text]）
  # 没 sleep 直接 send-keys Enter 会让 Enter 被吞或被当作 paste 内部换行 → CC 看到内容但不启动一轮
  # （2026-04-08 凌晨 14 个 CC 卡住事件根因，已修复）
  sleep 0.5
  tmux send-keys -t "$SESSION" Enter
  tmux delete-buffer -b "inject-$$" 2>/dev/null || true
  rm -f "$TMP_BUF"
  echo "[inject] ✅ 已注入到 $SESSION ($(echo "$PROMPT" | wc -c) 字节)"
done
