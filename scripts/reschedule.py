#!/usr/bin/env python3
"""
排程脚本 - 按新的 Sprint 规则重新排序 Issue
"""

import json
import subprocess
import re
from datetime import datetime

# 拉取 Issue 数据
def fetch_issues(repo):
    cmd = [
        "gh", "issue", "list",
        "--repo", repo,
        "--state", "open",
        "--label", "status:ready",
        "--json", "number,title,labels",
        "-L", "500"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error fetching {repo}: {result.stderr}")
        return []
    return json.loads(result.stdout)

# 判断是否是 Sprint 重点模块
def is_sprint_priority(title, labels):
    """判断是否是项目矿场或超管驾驶舱"""
    title_lower = title.lower()
    label_names = [l["name"] for l in labels]

    # 项目矿场
    if "[项目矿场]" in title_lower or "[项目中心]" in title_lower:
        return True, "project_mine"
    if "module:project" in label_names or "project-mine" in label_names:
        return True, "project_mine"

    # 超管驾驶舱
    if "[超管驾驶舱]" in title_lower or "[claude office]" in title_lower:
        return True, "dashboard"
    if "module:dashboard" in label_names:
        return True, "dashboard"

    return False, None

# 提取优先级数字
def get_priority_num(labels):
    """P0=0, P1=1, P2=2, P3=3"""
    for l in labels:
        name = l["name"]
        if name == "P0" or name == "priority/P0":
            return 0
        if name == "P1" or name == "priority/P1":
            return 1
        if name == "P2" or name == "priority/P2":
            return 2
        if name == "P3" or name == "priority/P3":
            return 3
    return 4  # 无优先级标记

# 提取 Phase 编号
def get_phase_num(title):
    """提取 Phase 编号，用于同模块内排序"""
    match = re.search(r'Phase[^\d]*(\d+)', title, re.IGNORECASE)
    if match:
        return int(match.group(1))
    return 999  # 无 Phase 标记的排后面

# 判断是否是 test-failed
def is_test_failed(labels):
    for l in labels:
        if l["name"] == "status:test-failed":
            return True
    return False

# 排序函数
def sort_issues(issues):
    """按新规则排序"""
    def sort_key(issue):
        title = issue["title"]
        labels = issue["labels"]
        number = issue["number"]

        test_failed = is_test_failed(labels)
        priority = get_priority_num(labels)
        sprint_priority, sprint_type = is_sprint_priority(title, labels)
        phase = get_phase_num(title)

        # 排序元组:
        # 1. test_failed 最优先 (False=1, True=0)
        # 2. 优先级 (0=P0, 1=P1, ...)
        # 3. Sprint 模块优先 (False=1, True=0)
        # 4. Sprint 类型 (dashboard=0, project_mine=1, None=2)
        # 5. Phase 编号
        # 6. Issue 号
        return (
            0 if test_failed else 1,
            priority,
            0 if sprint_priority else 1,
            0 if sprint_type == "dashboard" else (1 if sprint_type == "project_mine" else 2),
            phase,
            number
        )

    return sorted(issues, key=sort_key)

# 生成 Markdown 表格行
def make_row(idx, issue, status="待执行"):
    num = issue["number"]
    title = issue["title"]
    labels = issue["labels"]

    # 提取优先级
    priority = "P0"
    for l in labels:
        if l["name"] in ["P0", "priority/P0"]:
            priority = "P0"
        elif l["name"] in ["P1", "priority/P1"]:
            priority = "P1"
        elif l["name"] in ["P2", "priority/P2"]:
            priority = "P2"
        elif l["name"] in ["P3", "priority/P3"]:
            priority = "P3"

    # 标记 Sprint 模块
    is_sprint, sprint_type = is_sprint_priority(title, labels)
    sprint_marker = ""
    if is_sprint:
        sprint_marker = " ⭐" if sprint_type == "dashboard" else " 🏷️"

    return f"| {idx} | #{num} | {title}{sprint_marker} | {priority} | {status} |"

# 主函数
def main():
    # 获取 token
    token_script = "/opt/wande-ai/scripts/gh-app-token.py"
    result = subprocess.run(["python3", token_script], capture_output=True, text=True)
    token = result.stdout.strip()

    # 拉取三个仓库的 Issue
    backend_issues = fetch_issues("WnadeyaowuOraganization/wande-ai-backend")
    front_issues = fetch_issues("WnadeyaowuOraganization/wande-ai-front")
    pipeline_issues = fetch_issues("WnadeyaowuOraganization/wande-data-pipeline")

    # 排序
    backend_issues = sort_issues(backend_issues)
    front_issues = sort_issues(front_issues)
    pipeline_issues = sort_issues(pipeline_issues)

    # 统计
    backend_count = len(backend_issues)
    front_count = len(front_issues)
    pipeline_count = len(pipeline_issues)
    total_count = backend_count + front_count + pipeline_count

    # 生成时间戳
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")

    # 生成 SCHEDULE.md
    md = f"""# 自动编程排程清单

> 由调度器自主维护，每次执行后自动更新状态。
> 人工可通过修改本文件调整优先级和执行顺序。

## 概览

| 项目 | 待执行 | 执行中 | 已完成 | 失败 | 需人工 |
|------|--------|--------|--------|------|--------|
| backend | {backend_count} | 0 | 0 | 0 | 0 |
| front | {front_count} | 0 | 0 | 0 | 0 |
| pipeline | {pipeline_count} | 0 | 0 | 0 | 0 |
| **合计** | **{total_count}** | **0** | **0** | **0** | **0** |

当前 Sprint: 项目矿场 + 超管驾驶舱

最后更新：{timestamp} CST

## backend

### 执行队列

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for idx, issue in enumerate(backend_issues, 1):
        md += make_row(idx, issue) + "\n"

    md += f"""
<!-- 完整待执行列表由调度器自动维护，此处展示排队前列的 Issue -->

### 已完成 (0)

<details>
<summary>展开查看</summary>

由调度器自动填充

</details>

### 失败/跳过 (0)

<details>
<summary>展开查看</summary>

由调度器自动填充

</details>

## front

### 执行队列

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for idx, issue in enumerate(front_issues, 1):
        md += make_row(idx, issue) + "\n"

    md += """
### 已完成 (0)

<details>
<summary>展开查看</summary>

由调度器自动填充

</details>

## pipeline

### 执行队列

| 序号 | Issue | 标题 | 优先级 | 状态 |
|------|-------|------|--------|------|
"""

    for idx, issue in enumerate(pipeline_issues, 1):
        md += make_row(idx, issue) + "\n"

    md += """
### 已完成 (0)

<details>
<summary>展开查看</summary>

由调度器自动填充

</details>

## 需人工确认

| 项目 | Issue | 说明 |
|------|-------|------|
| backend | 待调度器填充 | — |
| front | 待调度器填充 | — |
| pipeline | 待调度器填充 | — |

---

## 格式说明

- 调度器通过 GitHub API 读取本文件，解析 `执行队列` 表格中的 Issue 号和状态
- **手动调整优先级**：直接编辑表格行的顺序或状态字段
- **暂停某个 Issue**：将状态改为 `暂停`
- **状态值**：`待执行` / `执行中` / `已完成` / `失败` / `需人工` / `暂停`
- 调度器每次执行后自动 commit + push 更新状态
"""

    # 写入文件
    with open("/home/ubuntu/projects/.github/docs/SCHEDULE.md", "w") as f:
        f.write(md)

    print(f"排程更新完成:")
    print(f"  backend: {backend_count} 个 Issue")
    print(f"  front: {front_count} 个 Issue")
    print(f"  pipeline: {pipeline_count} 个 Issue")
    print(f"  合计：{total_count} 个 Issue")

if __name__ == "__main__":
    main()
