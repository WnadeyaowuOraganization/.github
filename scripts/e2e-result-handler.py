#!/usr/bin/env python3
"""
E2E测试结果自动处理器 — 解析Playwright JSON报告，自动评论+改Label+改Project状态。
三层测试（CI/Smoke探活/全量回归）统一调用。

用法:
  # 模式1: 有PR和Issue（pr-test.yml CI层）
  python3 e2e-result-handler.py --report results.json --pr 123 --issue 456 --source ci --run-url https://...

  # 模式2: 有PR无Issue（CI层提取不到Issue号时）
  python3 e2e-result-handler.py --report results.json --pr 123 --source ci

  # 模式3: 无PR无Issue（smoke探活/全量回归，失败时自动创建Issue）
  python3 e2e-result-handler.py --report results.json --source smoke
  python3 e2e-result-handler.py --report results.json --source top

  # 模式4: 有Issue无PR（顶层手动指定已有Issue）
  python3 e2e-result-handler.py --report results.json --issue 789 --source top

退出码:
  0 = 测试通过（或无测试用例/报告不存在）
  1 = 测试失败
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime
HOME_DIR = os.environ.get('HOME_DIR', '/home/ubuntu')


REPO = "WnadeyaowuOraganization/wande-play"
SCRIPTS_DIR = f"{HOME_DIR}/projects/.github/scripts"

SOURCE_LABELS = {
    "ci": "CI",
    "smoke": "Smoke探活",
    "mid": "中层",
    "top": "顶层回归",
}


def parse_report(report_path):
    """解析Playwright JSON报告，返回 (total, passed, failed_list)
    failed_list: [(title, error_short, file_path), ...]
    """
    if not os.path.exists(report_path):
        return 0, 0, []

    try:
        with open(report_path, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        return 0, 0, []

    failures = []
    total = 0
    passed = 0

    def collect(suite, file_path=""):
        nonlocal total, passed
        # suite可能有file字段
        fp = suite.get("file", file_path)
        for spec in suite.get("specs", []):
            for test in spec.get("tests", []):
                total += 1
                status = test.get("status", "")
                if status == "expected":
                    passed += 1
                elif status == "unexpected":
                    title = spec.get("title", "unknown")
                    results = test.get("results", [{}])
                    error_msg = (
                        results[0].get("error", {}).get("message", "no detail")
                        if results
                        else "no detail"
                    )
                    error_short = error_msg[:200].replace("\n", " ").strip()
                    if len(error_msg) > 200:
                        error_short += "..."
                    failures.append((title, error_short, fp))
        for child in suite.get("suites", []):
            collect(child, fp)

    for suite in data.get("suites", []):
        collect(suite)

    return total, passed, failures


def detect_module(failures):
    """根据失败测试文件路径判断 module 标签"""
    modules = set()
    for _, _, fp in failures:
        if "backend" in fp:
            modules.add("backend")
        elif "front" in fp:
            modules.add("frontend")
        elif "pipeline" in fp:
            modules.add("pipeline")
    if len(modules) > 1:
        return "fullstack"
    elif len(modules) == 1:
        return modules.pop()
    return "backend"  # 默认


def run_cmd(cmd, check=False):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"命令失败: {cmd}\n{result.stderr}", file=sys.stderr)
    return result


def gh_comment(target_type, target_num, body):
    """评论到PR或Issue"""
    cmd_type = "pr comment" if target_type == "pr" else "issue comment"
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        f.flush()
        run_cmd(f'gh {cmd_type} {target_num} --repo {REPO} --body-file "{f.name}"')
        os.unlink(f.name)


def update_issue_labels(issue_num, add_labels, remove_labels):
    for label in add_labels:
        run_cmd(f'gh issue edit {issue_num} --repo {REPO} --add-label "{label}"')
    for label in remove_labels:
        run_cmd(f'gh issue edit {issue_num} --repo {REPO} --remove-label "{label}"')


def update_project_status(issue_num, status, retries=3, delay=10):
    """更新Project#4状态，带重试（新建Issue时auto-add-to-project.yml是异步的）"""
    script = os.path.join(SCRIPTS_DIR, "update-project-status.sh")
    import time
    for attempt in range(retries):
        result = run_cmd(f'bash "{script}" play "{issue_num}" "{status}"')
        if result.returncode == 0:
            return True
        if attempt < retries - 1:
            print(f"  Project状态更新失败，{delay}s后重试 ({attempt+1}/{retries})")
            time.sleep(delay)
    print(f"⚠️ Project状态更新最终失败: Issue #{issue_num}", file=sys.stderr)
    return False


def create_issue(source, module, fail_detail, total, failed_count):
    """自动创建Issue，返回Issue号"""
    source_label = SOURCE_LABELS.get(source, source)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    title = f"fix: {source_label}发现E2E测试失败 ({failed_count}个用例)"

    body = f"""## 问题描述

{source_label}E2E测试发现 {failed_count}/{total} 个用例失败。

### 失败用例
{fail_detail}

## 环境
- 测试时间: {now}
- 环境: G7e Dev (:6040/:8083)
- 来源: {source_label}

## 处理步骤

| Step | 内容 |
|------|------|
| 1 | 复现失败用例 |
| 2 | 定位根因 |
| 3 | 修复并确认测试通过 |
"""

    labels = f"priority/P0,type:bugfix,status:test-failed,module:{module}"
    result = run_cmd(
        f'gh issue create --repo {REPO} '
        f'--title "{title}" '
        f'--body-file /dev/stdin '
        f'--label "{labels}"',
    )
    # 上面用stdin不方便，改用tempfile
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        f.flush()
        result = run_cmd(
            f'gh issue create --repo {REPO} '
            f'--title "{title}" '
            f'--body-file "{f.name}" '
            f'--label "{labels}"'
        )
        os.unlink(f.name)

    # 提取Issue号: gh issue create输出类似 https://github.com/.../issues/123
    if result.returncode == 0 and result.stdout.strip():
        match = re.search(r"/issues/(\d+)", result.stdout.strip())
        if match:
            return int(match.group(1))
    print(f"⚠️ 创建Issue失败: {result.stderr}", file=sys.stderr)
    return None


def build_fail_body(source, total, passed, failures, run_url=None):
    """构建失败评论内容"""
    source_label = SOURCE_LABELS.get(source, source)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    failed_count = len(failures)

    fail_lines = "\n".join(
        f"- **{title}**: {error}" for title, error, _ in failures
    )
    if not fail_lines:
        fail_lines = "- 未能从报告中提取失败详情，请查看日志"

    body = f"❌ **{source_label}E2E测试失败** {now}\n\n"
    body += f"共 {total} 个用例，通过 {passed}，失败 {failed_count}\n\n"
    body += f"### 失败用例\n{fail_lines}\n"
    if run_url:
        body += f"\n### CI日志\n{run_url}\n"
    return body


def handle_pass(args, total, passed):
    """测试通过"""
    source_label = SOURCE_LABELS.get(args.source, args.source)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    summary = f"✅ **{source_label}E2E测试通过** {now} — 共 {total} 个用例，全部通过。"

    if args.pr:
        gh_comment("pr", args.pr, summary)

    if args.issue:
        update_issue_labels(
            args.issue,
            add_labels=["status:test-passed"],
            remove_labels=["status:test-failed", "status:in-progress"],
        )


def handle_fail(args, total, passed, failures):
    """测试失败"""
    body = build_fail_body(args.source, total, passed, failures, args.run_url)
    module = detect_module(failures)
    issue_num = args.issue

    # 评论到PR
    if args.pr:
        gh_comment("pr", args.pr, body)

    # 有Issue → 评论+改标签+改状态
    # 无Issue → 自动创建Issue
    if not issue_num:
        print(f"📝 无关联Issue，自动创建（module:{module}）")
        issue_num = create_issue(
            args.source, module, 
            "\n".join(f"- **{t}**: {e}" for t, e, _ in failures),
            total, len(failures)
        )
        if not issue_num:
            print("⚠️ 创建Issue失败，跳过后续状态更新", file=sys.stderr)
            return

    # 评论到Issue
    gh_comment("issue", issue_num, body)

    # 更新Label + Project状态
    update_issue_labels(
        issue_num,
        add_labels=["status:test-failed"],
        remove_labels=["status:test-passed", "status:in-progress"],
    )
    update_project_status(issue_num, "E2E Fail")
    print(f"📌 Issue #{issue_num} → status:test-failed + E2E Fail")


def main():
    parser = argparse.ArgumentParser(description="E2E测试结果自动处理器")
    parser.add_argument("--report", required=True, help="Playwright JSON报告路径")
    parser.add_argument("--pr", type=int, help="PR号（可选）")
    parser.add_argument("--issue", type=int, help="关联Issue号（可选，无则失败时自动创建）")
    parser.add_argument(
        "--source", required=True,
        choices=["ci", "smoke", "mid", "top"],
        help="测试来源"
    )
    parser.add_argument("--run-url", help="CI运行链接（可选）")
    args = parser.parse_args()

    total, passed, failures = parse_report(args.report)

    if total == 0:
        print("⚠️ 无测试用例或报告不存在，跳过")
        sys.exit(0)

    if failures:
        print(f"❌ 失败: {len(failures)}/{total}")
        handle_fail(args, total, passed, failures)
        sys.exit(1)
    else:
        print(f"✅ 通过: {total}/{total}")
        handle_pass(args, total, passed)
        sys.exit(0)


if __name__ == "__main__":
    main()
