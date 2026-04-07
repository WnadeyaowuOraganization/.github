#!/bin/bash
# check-jump-fail.sh — 每10分钟检查 Jump / Fail / E2E Fail 状态的新 Issue
#                      有新 Issue 时发送通知并写入排程优先队列
#
# 用法: bash check-jump-fail.sh
# cron: */10 * * * * /bin/bash /home/ubuntu/projects/.github/scripts/check-jump-fail.sh

HOME_DIR="${HOME_DIR:-/home/ubuntu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${HOME_DIR}/cc_scheduler/jump-fail-state.json"
LOG_FILE="${HOME_DIR}/cc_scheduler/logs/check-jump-fail.log"

export GH_TOKEN=$("$SCRIPT_DIR/get-gh-token.sh" 2>/dev/null || echo "$GH_TOKEN")

mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="

# 初始化状态文件
if [ ! -f "$STATE_FILE" ]; then
  echo '{"jump":[],"fail":[],"e2e_fail":[]}' > "$STATE_FILE"
fi

# 查询 Jump / Fail / E2E Fail 状态的 Issue
RESULT=$(gh api graphql --paginate -f query='
query($endCursor: String) {
  organization(login: "WnadeyaowuOraganization") {
    projectV2(number: 4) {
      items(first: 50, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          content { ... on Issue { number title state } }
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}' 2>/dev/null | python3 -c "
import json, sys

pages = []
for line in sys.stdin:
  line = line.strip()
  if line:
    try:
      pages.append(json.loads(line))
    except:
      pass

result = {'jump': [], 'fail': [], 'e2e_fail': []}
for page in pages:
  nodes = page.get('data', {}).get('organization', {}).get('projectV2', {}).get('items', {}).get('nodes', [])
  for n in nodes:
    content = n.get('content', {})
    num = content.get('number')
    title = content.get('title', '')[:60]
    state = content.get('state', '')
    if not num or state == 'CLOSED':
      continue
    status = ''
    for fv in n.get('fieldValues', {}).get('nodes', []):
      if fv.get('field', {}).get('name') == 'Status':
        status = fv.get('name', '')
    if status == 'Jump':
      result['jump'].append({'n': num, 't': title})
    elif status == 'Fail':
      result['fail'].append({'n': num, 't': title})
    elif status == 'E2E Fail':
      result['e2e_fail'].append({'n': num, 't': title})

print(json.dumps(result))
" 2>/dev/null)

if [ -z "$RESULT" ]; then
  echo "查询失败，跳过"
  exit 0
fi

# 读取上次状态
PREV=$(cat "$STATE_FILE" 2>/dev/null || echo '{"jump":[],"fail":[],"e2e_fail":[]}')

# 检查新增 Issue
python3 << PYEOF
import json, subprocess, sys

result = json.loads('''$RESULT''')
prev = json.loads('''$PREV''')

def get_nums(lst):
    return set(item['n'] for item in lst)

new_jump = [i for i in result['jump'] if i['n'] not in get_nums(prev.get('jump', []))]
new_fail = [i for i in result['fail'] if i['n'] not in get_nums(prev.get('fail', []))]
new_e2e_fail = [i for i in result['e2e_fail'] if i['n'] not in get_nums(prev.get('e2e_fail', []))]

# 发送通知
def notify(message, mtype='warning'):
    session = subprocess.run(['tmux', 'display-message', '-p', '#S'], capture_output=True, text=True).stdout.strip() or 'manager'
    subprocess.run(['curl', '-s', '-X', 'POST', 'http://localhost:9872/api/notify',
        '-H', 'Content-Type: application/json',
        '-d', json.dumps({'session': session, 'message': message, 'type': mtype})],
        capture_output=True)

notify_parts = []
if new_jump:
    nums = ' '.join(f'#{i["n"]}' for i in new_jump)
    notify_parts.append(f'Jump新增 {len(new_jump)} 个: {nums}')
    print(f'[Jump新增] {nums}')
if new_fail:
    nums = ' '.join(f'#{i["n"]}' for i in new_fail)
    notify_parts.append(f'Fail新增 {len(new_fail)} 个: {nums}')
    print(f'[Fail新增] {nums}')
if new_e2e_fail:
    nums = ' '.join(f'#{i["n"]}' for i in new_e2e_fail)
    notify_parts.append(f'E2EFail新增 {len(new_e2e_fail)} 个: {nums}')
    print(f'[E2EFail新增] {nums}')

if notify_parts:
    msg = '优先排程提醒：' + '，'.join(notify_parts)
    notify(msg, 'error')

# 统计
total_jump = len(result['jump'])
total_fail = len(result['fail'])
total_e2e = len(result['e2e_fail'])
print(f'当前: Jump={total_jump}, Fail={total_fail}, E2EFail={total_e2e}')

if total_jump > 0:
    jump_list = ', '.join(f'#{i["n"]}({i["t"][:20]})' for i in result['jump'])
    print(f'Jump队列: {jump_list}')
PYEOF

# 更新状态文件
echo "$RESULT" > "$STATE_FILE"

echo "=== 完成 ==="
