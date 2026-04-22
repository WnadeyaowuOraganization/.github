---
name: quick-fix
description: 甲方问题反馈收集工具。接收甲方在测试环境（http://localhost:8080）发现的问题，自动采集页面上下文（路由+控制台错误+网络错误），按SOP创建标准GitHub Issue留痕，附before截图。不直接修改代码，Issue创建后由排程经理分配给编程CC处理。Use this skill whenever the user mentions bugs, UI issues, data problems, client complaints, or any feedback about the test environment.
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
- 「是所有账号都有问题还是特定账号」
```

### 2. 复现 + 截图

用 Playwright 截取问题现场（before截图）：

```bash
source /data/home/ubuntu/projects/.github/docs/agent-docs/quick-fix/scripts/utils.sh

take-screenshot \
  "http://localhost:8080/<问题页面路径>" \
  "/tmp/before-fix.png"
```

### 3. 创建 Issue（按SOP标准格式）

#### 3.1 初始化

```bash
init-gh-token
BEFORE_URL=$(upload-release-asset "/tmp/before-fix.png")
```

#### 3.2 按问题类型创建Issue

Issue Body 必须包含以下 **7个Section**（来自 issue-creation-sop.md）：

```bash
export GH_TOKEN=$(python3 /data/home/ubuntu/projects/.github/scripts/gh-app-token.py)

gh issue create \
  --repo WnadeyaowuOraganization/wande-play \
  --title "[Quick-Fix] <一句话描述问题>" \
  --label "type:bugfix,module:<backend|frontend|fullstack>,priority/P1" \
  --body "$(cat <<'EOF'
## 需求背景

甲方在测试环境发现问题：
<甲方原话，不润色>

页面路由：<自动采集的路由>
发现时间：$(date '+%Y-%m-%d %H:%M')

## 关联Issue

无（如有关联在此填写）

## 环境 / 配置 / 关联文件

- 测试环境前端：http://100.99.88.8:8080
- 测试环境后端：http://localhost:6040
- 问题页面：<具体路由>

## 处理步骤

| 步骤 | 操作内容 | 涉及文件/路径 | 验收标准 |
|------|---------|-------------|---------|
| 1 | 复现问题 | <路径> | 能稳定复现 |
| 2 | 定位根因 | <待CC填写> | 确认根因 |
| 3 | 修复代码 | <待CC填写> | 编译通过 |
| 4 | 验证修复 | <待CC填写> | 问题消失 |

## 其他要求

- 最小改动原则，只修复本Issue涉及的问题
- 按项目现有规范开发

## 技术验收标准（CC自验）

- 后端编译通过（mvn compile）
- 前端构建通过（pnpm build）
- 问题页面功能恢复正常

## 产品验收清单（Perplexity Review）

### 是否需要产品验收
是

### 问题截图（修复前）
![Before](<BEFORE_URL>)

### 控制台/网络错误
<自动采集的错误信息>

### 功能Checklist
- [ ] 问题页面不再报错
- [ ] 相关功能正常使用
- [ ] 未引入新问题
EOF
)"
```

#### 3.3 标签规则

每个Issue **至少4个标签**：

| 维度 | 标签 | 说明 |
|------|------|------|
| **模块** | `module:backend` / `module:frontend` / `module:fullstack` | 按问题类型选择 |
| **优先级** | `priority/P0`(阻塞) / `priority/P1`(必修) / `priority/P2`(增强) | 按严重程度 |
| **类型** | `type:bugfix` | 甲方反馈一般是bugfix |
| **状态** | `status:ready` | 需求已明确 |

#### 3.4 问题类型判断速查

| 现象 | module标签 | 典型特征 |
|------|-----------|---------|
| 页面样式错位/空白/报错 | `module:frontend` | 控制台有JS错误 |
| 接口404/500/超时 | `module:backend` | 网络错误有status code |
| 数据不对/缺失/乱码 | `module:backend` | SQL错误或空数据 |
| 页面+接口都有问题 | `module:fullstack` | 前后端联动问题 |

### 4. 回复甲方

Issue创建后回复甲方：
- 已记录问题，Issue编号 #xxx
- 预计处理时间（简单问题1小时内，复杂问题需排期）

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
| 5 | Issue Body必须包含7个Section（SOP标准格式） |
| 6 | Issue必须至少4个标签（module+priority+type+status） |
| 7 | 不代替甲方做需求判断，原话记录 |
