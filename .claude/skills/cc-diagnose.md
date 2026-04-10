---
name: cc-diagnose
description: 诊断卡住的编程CC，分析原因并通过tmux提示或汇总需人工介入的问题
user_invocable: true
---

# 编程CC诊断技能

扫描所有活跃的编程CC，检测异常状态（PR失败、部署失败、长时间运行等），自动分析原因：

- **自动修复**：通过tmux会话告知编程CC（如PR失败需查看日志）
- **人工介入**：总结到当前会话（如长时间运行可能卡住）

## 使用方式

```
/cc-diagnose
```

## 诊断范围

1. **PR_CHECK_FAILED** — CI检查失败，自动提示CC查看日志
2. **DEPLOY_FAILED** — 部署失败，需人工检查
3. **LONG_RUNNING** — 运行超过2小时，可能卡住
4. **ORPHAN_LOCK** — lock存在但tmux会话已消失

## 执行流程

```bash
bash scripts/cc-diagnose-stuck.sh
```

输出格式化的诊断报告，包含自动修复结果和需人工处理的问题列表。
