#!/usr/bin/env python3
"""
E2E测试结果自动处理器 — 解析Playwright JSON报告，自动评论+改Label+改Project状态。
三层测试（CI/中层/顶层）统一调用。

用法:
  # CI层（pr-test.yml）— 有PR号和Issue号
  python3 e2e-result-handler.py --report results.json --pr 123 --issue 456 --source ci --run-url https://...

  # 中层（测试CC）— 有PR号和Issue号
  python3 e2e-result-handler.py --report results.json --pr 123 --issue 456 --source mid

  # 顶层（测试CC）— 只有Issue号（回归测试发现的bug，可能是新建Issue）
  python3 e2e-result-handler.py --report results.json --issue 456 --source top

退出码:
  0 = 测试通过（或报告不存在/无法解析时视为跳过）
  1 = 测试失败（有用例失败）
"""
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime


REPO = "WnadeyaowuOraganization/wande-play"
SCRIPTS_DIR = "/home/ubuntu/projects/.github/scripts"


def parse_report(report_path):
    """解析Playwright JSON报告，返回 (total, passed, failed_list)"""
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

    def collect(suite):
        nonlocal total, passed
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
                    # 截断避免评论过长
                    error_short = error_msg[:200].replace("\n", " ").strip()
                    if len(error_msg) > 200:
                        error_short += "..."
                    failures.append((title, error_short))
        for child in suite.get("suites", []):
            collect(child)

    for suite in data.get("suites", []):
        collect(suite)

    return total, passed, failures


def run_cmd(cmd, check=False):
    """运行shell命令"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"命令失败: {cmd}\n{result.stderr}", file=sys.stderr)
    return result


def comment_pr(pr_num, body):
    """评论到PR"""
    import tempfile
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        f.flush()
        run_cmd(f'gh pr comment {pr_num} --repo {REPO} --body-file "{f.name}"')
        os.unlink(f.name)


def comment_issue(issue_num, body):
    """评论到Issue"""
    import tempfile
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        f.flush()
        run_cmd(f'gh issue comment {issue_num} --repo {REPO} --body-file "{f.name}"')
        os.unlink(f.name)


def update_issue_labels(issue_num, add_labels, remove_labels):
    """更新Issue标签"""
    for label in add_labels:
        run_cmd(f'gh issue edit {issue_num} --repo {REPO} --add-label "{label}"')
    for label in remove_labels:
        run_cmd(f'gh issue edit {issue_num} --repo {REPO} --remove-label "{label}"')


def update_project_status(issue_num, status):
    """更新Project#4看板状态"""
    script = os.path.join(SCRIPTS_DIR, "update-project-status.sh")
    run_cmd(f'bash "{script}" play "{issue_num}" "{status}"')


def handle_pass(args, total, passed):
    """测试通过处理"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    source_label = {"ci": "CI", "mid": "中层", "top": "顶层"}.get(args.source, args.source)
    summary = f"✅ **{source_label}E2E测试通过** {now}\n\n共 {total} 个用例，全部通过。"

    if args.pr:
        # 评论到PR（通过时简短即可）
        comment_pr(args.pr, summary)

    if args.issue:
        # 更新Label: 加 test-passed, 去掉 test-failed
        update_issue_labels(
            args.issue,
            add_labels=["status:test-passed"],
            remove_labels=["status:test-failed", "status:in-progress"],
        )
        # 通过时不改Project状态 — 留给auto-merge job改Done


def handle_fail(args, total, passed, failures):
    """测试失败处理"""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    source_label = {"ci": "CI", "mid": "中层", "top": "顶层"}.get(args.source, args.source)
    failed_count = len(failures)

    # 拼装失败详情
    fail_lines = "\n".join(f"- **{title}**: {error}" for title, error in failures)
    if not fail_lines:
        fail_lines = "- 未能从报告中提取失败详情，请查看日志"

    body = f"❌ **{source_label}E2E测试失败** {now}\n\n"
    body += f"共 {total} 个用例，通过 {passed}，失败 {failed_count}\n\n"
    body += f"### 失败用例\n{fail_lines}\n"

    if args.run_url:
        body += f"\n### CI日志\n{args.run_url}\n"

    # 评论到PR
    if args.pr:
        comment_pr(args.pr, body)

    # 评论到Issue + 改Label + 改Project状态
    if args.issue:
        comment_issue(args.issue, body)
        update_issue_labels(
            args.issue,
            add_labels=["status:test-failed"],
            remove_labels=["status:test-passed", "status:in-progress"],
        )
        update_project_status(args.issue, "E2E Fail")


def main():
    parser = argparse.ArgumentParser(description="E2E测试结果自动处理器")
    parser.add_argument("--report", required=True, help="Playwright JSON报告路径")
    parser.add_argument("--pr", type=int, help="PR号")
    parser.add_argument("--issue", type=int, help="关联Issue号")
    parser.add_argument("--source", required=True, choices=["ci", "mid", "top"], help="测试来源")
    parser.add_argument("--run-url", help="CI运行链接（仅ci层使用）")
    args = parser.parse_args()

    total, passed, failures = parse_report(args.report)

    if total == 0:
        print("⚠️ 无测试用例或报告不存在，跳过处理")
        sys.exit(0)

    if failures:
        print(f"❌ 测试失败: {len(failures)}/{total} 个用例失败")
        handle_fail(args, total, passed, failures)
        sys.exit(1)
    else:
        print(f"✅ 测试通过: {total}/{total} 个用例全部通过")
        handle_pass(args, total, passed)
        sys.exit(0)


if __name__ == "__main__":
    main()
