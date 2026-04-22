---
name: quick-fix
description: 甲方问题反馈收集工具。接收甲方在测试环境（http://localhost:8080）发现的问题，自动采集页面上下文（路由+控制台错误+网络错误），创建GitHub Issue留痕，附before截图。不直接修改代码，Issue创建后由排程经理分配给编程CC处理。Use this skill whenever the user mentions bugs, UI issues, data problems, client complaints, or any feedback about the test environment.
---

# Quick Fix — 甲方问题反馈收集

> **职责**：只负责收集问题、创建Issue。**不修改代码、不push、不部署。**
> 
> Issue创建后，由排程经理纳入排程，研发经理分配CC修复。

---

## 工作流程

### 1. 理解问题

收到甲方反馈后，先完整理解：

- 甲方描述的**现象**是什么
- 甲方期望的**正确行为**是什么
- 是否有截图/操作步骤

**不清楚就追问，不要猜测：**
```
常见追问：
- 「哪个菜单/哪个页面」
- 「操作步骤是什么」
- 「期望结果是什么样的」
```

### 2. 复现 + 截图

用 Playwright 截取问题现场（before截图）：

```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/quick-fix/scripts/utils.sh

take-screenshot \
  "http://localhost:8080/<问题页面路径>" \
  "/tmp/before-fix.png"
```

### 3. 创建 Issue

```bash
init-gh-token

# 上传截图
BEFORE_URL=$(upload-release-asset "/tmp/before-fix.png")

# 按问题类型创建Issue
# 前端问题
ISSUE_NUM=$(create-issue-frontend "问题标题" "$BEFORE_URL" "甲方反馈描述")

# API/后端问题
ISSUE_NUM=$(create-issue-api "问题标题" "$BEFORE_URL" "甲方反馈描述" "GET /api/xxx")

# 数据问题
ISSUE_NUM=$(create-issue-data "问题标题" "$BEFORE_URL" "甲方反馈描述" "表名")

echo "✅ Issue #$ISSUE_NUM 已创建，等待排程经理分配"
```

### 4. 回复甲方

Issue创建后回复甲方：
- 已记录问题，Issue编号 #xxx
- 预计处理时间（简单问题1小时内，复杂问题需排期）

---

## Issue模板

### 前端问题
```
## 甲方反馈
<原话>

## 问题类型
🖼️ 前端页面问题

## 问题截图
![Before](截图URL)

## 页面路由
<自动采集>

## 控制台/网络错误
<自动采集>
```

### API问题
```
## 甲方反馈
<原话>

## 问题类型
🔌 API/后端问题

## Endpoint
<接口路径>

## 问题截图
![Before](截图URL)
```

### 数据问题
```
## 甲方反馈
<原话>

## 问题类型
💾 数据异常

## 受影响表
<表名>

## 问题截图
![Before](截图URL)
```

---

## Flyway命名规范（如Issue涉及DB）

```bash
# 时间戳必须精确到秒，禁止手动补0
TS=$(date +%Y%m%d%H%M%S)
# 文件名: V${TS}__desc.sql
```

---

## ⛔ 红线

| # | 规则 |
|---|------|
| 1 | **禁止直接修改代码** — 只创建Issue |
| 2 | 禁止不复现就创建Issue |
| 3 | Issue必须有截图 |
| 4 | Issue必须包含自动采集的上下文（路由+错误） |
| 5 | 不代替甲方做需求判断，原话记录 |
