#!/usr/bin/env python3
"""
按Sprint规则重新排程所有Issue
排序规则:
1. Sprint重点模块排最前面（超管驾驶舱、Claude Office）
2. status:test-failed 次优先
3. priority/P0 > P1 > P2 > P3
4. 同模块内按Phase编号升序
5. 无Phase按Issue号升序
"""

import json
import re
from datetime import datetime
from pathlib import Path

# Sprint重点模块关键词
SPRINT_FOCUS = ['超管驾驶舱', 'Claude Office']

def get_priority(labels):
    """从labels提取优先级，返回数字（越小越优先）"""
    for label in labels:
        name = label.get('name', '')
        if 'priority/P0' in name:
            return 0
        elif 'priority/P1' in name:
            return 1
        elif 'priority/P2' in name:
            return 2
        elif 'priority/P3' in name:
            return 3
    return 4  # 无优先级标签的放最后

def is_test_failed(labels):
    """检查是否有status:test-failed标签"""
    for label in labels:
        if 'status:test-failed' in label.get('name', ''):
            return True
    return False

def is_in_progress(labels):
    """检查是否有status:in-progress标签"""
    for label in labels:
        if 'status:in-progress' in label.get('name', ''):
            return True
    return False

def is_completed(labels):
    """检查是否已完成"""
    for label in labels:
        name = label.get('name', '')
        if 'status:completed' in name or 'status:done' in name:
            return True
    return False

def is_sprint_focus(title):
    """检查是否是Sprint重点模块"""
    for keyword in SPRINT_FOCUS:
        if keyword in title:
            return True
    return False

def extract_phase_number(title):
    """从标题提取Phase编号"""
    match = re.search(r'Phase\s*(\d+)', title, re.IGNORECASE)
    if match:
        return int(match.group(1))
    match = re.search(r'\[(\d+)/\d+\]', title)
    if match:
        return int(match.group(1))
    return 999

def get_status(labels):
    """获取Issue状态"""
    for label in labels:
        name = label.get('name', '')
        if 'status:in-progress' in name:
            return '执行中'
        elif 'status:test-failed' in name:
            return '失败'
        elif 'status:completed' in name or 'status:done' in name:
            return '已完成'
        elif 'status:ready' in name:
            return '待执行'
    return '待执行'

def sort_issues(issues):
    """按规则排序Issues - Sprint重点模块排最前面"""
    def sort_key(issue):
        title = issue.get('title', '')
        labels = issue.get('labels', [])
        number = issue.get('number', 0)
        # Sprint重点模块排最前面（0），其他排后面（1）
        sprint_focus = 0 if is_sprint_focus(title) else 1
        # test-failed次优先
        test_failed = 0 if is_test_failed(labels) else 1
        priority = get_priority(labels)
        phase = extract_phase_number(title)
        return (sprint_focus, test_failed, priority, phase, number)
    return sorted(issues, key=sort_key)

def format_priority(labels):
    """格式化优先级显示"""
    for label in labels:
        name = label.get('name', '')
        if 'priority/P0' in name:
            return 'P0'
        elif 'priority/P1' in name:
            return 'P1'
        elif 'priority/P2' in name:
            return 'P2'
        elif 'priority/P3' in name:
            return 'P3'
    return '-'

def main():
    home = Path.home()
    backend_issues = json.loads((home / 'backend_issues.json').read_text())
    front_issues = json.loads((home / 'front_issues.json').read_text())
    pipeline_issues = json.loads((home / 'pipeline_issues.json').read_text())

    backend_sorted = sort_issues(backend_issues)
    front_sorted = sort_issues(front_issues)
    pipeline_sorted = sort_issues(pipeline_issues)

    def count_stats(issues):
        stats = {'total': len(issues), 'P0': 0, 'P1': 0, 'P2': 0, 'P3': 0, 'pending': 0}
        for issue in issues:
            labels = issue.get('labels', [])
            status = get_status(labels)
            if status == '待执行':
                stats['pending'] += 1
            p = format_priority(labels)
            if p in stats:
                stats[p] += 1
        return stats

    backend_stats = count_stats(backend_issues)
    front_stats = count_stats(front_issues)
    pipeline_stats = count_stats(pipeline_issues)

    now = datetime.now().strftime('%Y-%m-%d %H:%M')

    md = f"""# 万德 AI 研发排程表

**当前 Sprint**: 2026-03-28 ~ 2026-04-11
**更新时间**: {now}
**重点模块**: 超管驾驶舱、Claude Office

---

## 统计概览

| 项目 | 待执行 | P0 | P1 | P2 | P3 |
|------|--------|----|----|----|----|
| Backend | {backend_stats['pending']} | {backend_stats['P0']} | {backend_stats['P1']} | {backend_stats['P2']} | {backend_stats['P3']} |
| Frontend | {front_stats['pending']} | {front_stats['P0']} | {front_stats['P1']} | {front_stats['P2']} | {front_stats['P3']} |
| Pipeline | {pipeline_stats['pending']} | {pipeline_stats['P0']} | {pipeline_stats['P1']} | {pipeline_stats['P2']} | {pipeline_stats['P3']} |

---

## Backend 排程 ({len(backend_sorted)} 个 Issues)

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for i, issue in enumerate(backend_sorted, 1):
        number = issue.get('number', 0)
        title = issue.get('title', '')[:80]
        labels = issue.get('labels', [])
        priority = format_priority(labels)
        status = get_status(labels)
        md += f"| {i} | #{number} | {title} | {priority} | {status} |\n"

    md += f"""
---

## Frontend 排程 ({len(front_sorted)} 个 Issues)

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for i, issue in enumerate(front_sorted, 1):
        number = issue.get('number', 0)
        title = issue.get('title', '')[:80]
        labels = issue.get('labels', [])
        priority = format_priority(labels)
        status = get_status(labels)
        md += f"| {i} | #{number} | {title} | {priority} | {status} |\n"

    md += f"""
---

## Pipeline 排程 ({len(pipeline_sorted)} 个 Issues)

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for i, issue in enumerate(pipeline_sorted, 1):
        number = issue.get('number', 0)
        title = issue.get('title', '')[:80]
        labels = issue.get('labels', [])
        priority = format_priority(labels)
        status = get_status(labels)
        md += f"| {i} | #{number} | {title} | {priority} | {status} |\n"

    md += """
---

## 状态说明

| 状态 | 含义 |
|------|------|
| 待执行 | Issue 已排程，等待 CC 处理 |
| 执行中 | CC 正在处理该 Issue |
| 已完成 | CC 已完成并推送代码 |
| 失败 | CC 处理失败 |
| 需人工 | 需要人工判断或处理 |
| 暂停 | 暂时暂停执行 |
"""

    output_path = Path('/home/ubuntu/projects/.github/docs/SCHEDULE.md')
    output_path.write_text(md, encoding='utf-8')
    print(f"排程表已更新: {output_path}")
    print(f"Backend: {len(backend_sorted)} issues")
    print(f"Frontend: {len(front_sorted)} issues")
    print(f"Pipeline: {len(pipeline_sorted)} issues")

if __name__ == '__main__':
    main()
