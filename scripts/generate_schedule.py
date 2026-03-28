#!/usr/bin/env python3
"""生成排程清单 SCHEDULE.md"""
import json
import re
import subprocess
import sys

def get_issues(repo):
    """获取指定仓库的 ready 状态 Issue"""
    cmd = [
        'gh', 'issue', 'list',
        '--repo', repo,
        '--state', 'open',
        '--label', 'status:ready',
        '--json', 'number,title,labels',
        '-L', '500'
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error fetching issues from {repo}: {result.stderr}", file=sys.stderr)
        return []
    return json.loads(result.stdout)

def get_priority(labels):
    """获取优先级值，越小越优先"""
    label_names = [l['name'] for l in labels]
    # status:test-failed 最优先
    if 'status:test-failed' in label_names:
        return (0, 0, 0, 0)
    # P0 > P1 > P2 > P3
    for i, p in enumerate(['P0', 'P1', 'P2', 'P3', 'priority/P0', 'priority/P1', 'priority/P2', 'priority/P3']):
        if p in label_names:
            return (1, i, 0, 0)
    return (2, 0, 0, 0)  # 无优先级标签

def extract_phase(title):
    """从标题提取 Phase 编号"""
    # 匹配 Phase 或 Phase 后面的数字
    match = re.search(r'Phase[^\d]*(\d+)', title, re.IGNORECASE)
    if match:
        return int(match.group(1))
    return 999  # 无 Phase 的排后面

def get_priority_sort_key(issue):
    """生成排序 key"""
    priority = get_priority(issue['labels'])
    phase = extract_phase(issue['title'])
    number = issue['number']
    # (是否有 test-failed, 优先级等级，Phase 编号，Issue 号)
    return (priority[0], priority[1], phase, number)

def format_priority(labels):
    """格式化优先级显示"""
    label_names = [l['name'] for l in labels]
    for p in ['P0', 'P1', 'P2', 'P3', 'priority/P0', 'priority/P1', 'priority/P2', 'priority/P3']:
        if p in label_names:
            return p.replace('priority/', '')
    return 'P3'  # 默认

def main():
    repos = {
        'backend': 'WnadeyaowuOraganization/wande-ai-backend',
        'front': 'WnadeyaowuOraganization/wande-ai-front',
        'pipeline': 'WnadeyaowuOraganization/wande-data-pipeline'
    }

    # 获取所有 Issue
    all_issues = {}
    for project, repo in repos.items():
        issues = get_issues(repo)
        # 排序
        issues.sort(key=get_priority_sort_key)
        all_issues[project] = issues

    # 生成 SCHEDULE.md
    lines = []
    lines.append("# 自动编程排程清单")
    lines.append("")
    lines.append("> 由调度器自主维护，每次执行后自动更新状态。")
    lines.append("> 人工可通过修改本文件调整优先级和执行顺序。")
    lines.append("")
    lines.append("## 概览")
    lines.append("")
    lines.append("| 项目 | 待执行 | 执行中 | 已完成 | 失败 | 需人工 |")
    lines.append("|------|--------|--------|--------|------|--------|")

    # 统计数字（从 Issue 数量计算）
    counts = {}
    for project in ['backend', 'front', 'pipeline']:
        count = len(all_issues[project])
        counts[project] = {'pending': count, 'in_progress': 0, 'completed': 0, 'failed': 0, 'manual': 0}
        lines.append(f"| {project} | {count} | 0 | 0 | 0 | 0 |")

    total = sum(c['pending'] for c in counts.values())
    lines.append(f"| **合计** | **{total}** | **0** | **0** | **0** | **0** |")
    lines.append("")

    from datetime import datetime
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines.append(f"最后更新：{now} CST")
    lines.append("")

    for project in ['backend', 'front', 'pipeline']:
        lines.append(f"## {project}")
        lines.append("")
        lines.append("### 执行队列")
        lines.append("")
        lines.append("| 序号 | Issue | 标题 | 优先级 | 状态 |")
        lines.append("|------|-------|------|--------|------|")

        for i, issue in enumerate(all_issues[project], 1):
            number = issue['number']
            title = issue['title'][:50] + "..." if len(issue['title']) > 50 else issue['title']
            priority = format_priority(issue['labels'])
            lines.append(f"| {i} | #{number} | {title} | {priority} | 待执行 |")

        lines.append("")
        lines.append("### 已完成 (0)")
        lines.append("")
        lines.append("<details>")
        lines.append("<summary>展开查看</summary>")
        lines.append("")
        lines.append("由调度器自动填充")
        lines.append("")
        lines.append("</details>")
        lines.append("")

    lines.append("## 需人工确认")
    lines.append("")
    lines.append("| 项目 | Issue | 说明 |")
    lines.append("|------|-------|------|")
    lines.append("| backend | 待调度器填充 | — |")
    lines.append("| front | 待调度器填充 | — |")
    lines.append("| pipeline | 待调度器填充 | — |")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## 格式说明")
    lines.append("")
    lines.append("- 调度器通过 GitHub API 读取本文件，解析 `执行队列` 表格中的 Issue 号和状态")
    lines.append("- **手动调整优先级**：直接编辑表格行的顺序或状态字段")
    lines.append("- **暂停某个 Issue**：将状态改为 `暂停`")
    lines.append("- **状态值**：`待执行` / `执行中` / `已完成` / `失败` / `需人工` / `暂停`")
    lines.append("- 调度器每次执行后自动 commit + push 更新状态")
    lines.append("")

    # 写入文件
    with open('docs/SCHEDULE.md', 'w') as f:
        f.write('\n'.join(lines))

    print("SCHEDULE.md 已生成")

if __name__ == '__main__':
    main()
