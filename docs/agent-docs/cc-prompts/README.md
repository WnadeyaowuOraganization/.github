# CC Prompt 模板库

> P3.2（2026-04-09）— 事故后的 prompt 模板版本化目录，便于追踪每次调整带来的质量影响

## 目录

| 文件 | 版本 | 引用方 | 用途 |
|------|-----|-------|------|
| `default-issue.md` | v2 | `scripts/run-cc.sh:196+` | Issue 模式启动 CC 时的默认 prompt，含 6 条硬约束 |

## 版本历史

### v2 — 2026-04-09（#3458 事故后紧急升级）

**缘起**：#3458/#3118/#2391 三 PR 平均 5.43/10，全部 CI 全绿但实际质量不合格。v1 的 prompt 仅一句话，导致 CC 缺乏质量约束。

**变更**：
- 追加 6 条硬约束（task.md 全勾 / PR body checkbox 全勾 / 前端截图 / slot VNode / 集成链声明 / 单测本地跑通）
- 明确对标 `pr-test.yml quality-gate` 三道门
- 附反例（slot 字符串反模式）和正例（模板插槽 / h 函数）

**commit**：见 `docs/workflow/新harness验证报告.md` 「P1.2 完成记录」小节

### v1 — 2026-03（初版）

**prompt 正文**：
```
阅读 issues/issue-${ISSUE}/issue-source.md 中的 Issue 内容，按流程完成任务。Issue 编号: #${ISSUE}
```

**问题**：无任何质量约束，CC 全凭自身直觉，导致 #3458 事故链。

## 如何添加新模板

1. 新建 `docs/agent-docs/cc-prompts/<场景>.md`，按 v2 格式写硬约束部分
2. 在 `scripts/run-cc.sh` 或对应调用方引用该文件（`envsubst` 替换 `${ISSUE}` 等占位符）
3. 在本 README 追加表格行 + 版本历史
4. 在 `docs/workflow/新harness验证报告.md` 记录上线日期 + commit hash

## 如何度量 prompt 升级效果

用 `scripts/weekly-quality-report.sh` 对比升级前后的平均评分和反模式出现次数。目标：每次 prompt 升级都带来 +0.5 以上的平均分提升。
