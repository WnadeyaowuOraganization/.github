---
name: smoke测试空状态检测建议
description: smoke测试空状态检测用count()>0而非isVisible()
type: feedback
---

smoke 测试空状态检测优先用 `count()>0` 而非 `isVisible()`。

**来源**: kimi4 (CC #3223 全景控制表)

**为什么**: isVisible() 可能受前端渲染时序影响不稳定，count() 直接查 DOM/接口更可靠
**如何应用**: e2e/tests/front/smoke/ 中的空状态断言，优先使用 page.locator('table tr').count() > 0 或 page.getByText('暂无数据').count() > 0
