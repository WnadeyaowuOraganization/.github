#!/usr/bin/env python3
"""
解析 Playwright JSON 报告，提取失败用例摘要。
用法: python3 parse-e2e-failures.py <json报告路径>
输出: Markdown格式的失败用例列表（供PR/Issue评论使用）
"""
import json
import sys
import os


def parse_failures(report_path):
    if not os.path.exists(report_path):
        print("- 测试报告文件不存在，请查看CI日志")
        return

    try:
        with open(report_path, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        print("- 无法解析测试报告JSON，请查看CI日志")
        return

    failures = []
    for suite in data.get("suites", []):
        collect_failures(suite, failures)

    if not failures:
        print("- 未能从报告中提取失败详情，请查看CI日志")
        return

    for title, error in failures:
        # 截断错误信息，避免评论过长
        error_short = error[:200].replace("\n", " ").strip()
        if len(error) > 200:
            error_short += "..."
        print(f"- **{title}**: {error_short}")


def collect_failures(suite, failures):
    """递归收集所有失败的测试用例"""
    for spec in suite.get("specs", []):
        for test in spec.get("tests", []):
            if test.get("status") == "unexpected":
                title = spec.get("title", "unknown")
                results = test.get("results", [{}])
                error_msg = (
                    results[0].get("error", {}).get("message", "no detail")
                    if results
                    else "no detail"
                )
                failures.append((title, error_msg))

    # 递归处理嵌套suites
    for child in suite.get("suites", []):
        collect_failures(child, failures)


if __name__ == "__main__":
    report_path = sys.argv[1] if len(sys.argv) > 1 else "test-results/reports/results.json"
    parse_failures(report_path)
