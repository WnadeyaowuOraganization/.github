---

# 工作流优化方案V1

## 一、现状诊断

### 当前架构

```
调度层: 调度器CC → Plan/Todo/In Progress/Done/Fail/E2E Fail
    ↓
执行层: 后端CC / 前端CC / 管线CC / 测试CC
    ↓
CI/CD层: pr-test.yml / build-deploy-dev.yml / e2e_smoke / e2e_top_tier
```

### 核心痛点（结合报告分析）

| 问题 | 影响 | 报告依据 |
|------|------|---------|
| CLAUDE.md过长（agent-docs/下多个文件累计超300行） | AI注意力分散，指令遵循率下降 | HumanLayer分析：50条内置指令+150-200条可遵循上限 |
| 缺乏静态分析防御 | 废弃API（如`:visible`）、嵌套Drawer问题流入E2E | 报告2.2节：100%确定性、0延迟 |
| E2E只测功能不检测运行时警告 | 控制台deprecated警告被忽略 | 报告5.2节实践一 |
| 无视觉回归测试 | UI布局问题无法自动捕获 | 报告1.4节 |
| 自动重试无上限 | AI迭代修复反而放大问题（+37%漏洞） | 报告5.1节风险一 |
| Token Pool多模型质量波动 | Qwen实际编码能力远不如Claude | 报告4.2节 |

---

## 二、优化方案总览

```
┌─────────────────────────────────────────────────────────────────┐
│                      优化后工作流架构                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Issue创建 ──▶ [Plan] ──▶ [Todo] ──▶ [In Progress]            │
│       │                                    │                    │
│       ▼                                    ▼                    │
│   Issue模板增强                        编程CC执行                │
│   (验收标准+技术约束)                  (精简CLAUDE.md)           │
│                                            │                    │
│                                            ▼                    │
│                                   ┌───────────────────┐         │
│                                   │ 第一层: 静态分析   │         │
│                                   │ ESLint废弃API检查  │         │
│                                   │ 组件结构规则       │         │
│                                   │ 路由完整性检查     │         │
│                                   └─────────┬─────────┘         │
│                                             │ ✅                │
│                                             ▼                    │
│                                   ┌───────────────────┐         │
│                                   │ 第二层: 编译门控   │         │
│                                   │ mvn compile        │         │
│                                   │ pnpm build         │         │
│                                   │ 单元测试(TDD)      │         │
│                                   └─────────┬─────────┘         │
│                                             │ ✅                │
│                                             ▼                    │
│                                   ┌───────────────────┐         │
│                                   │ 第三层: AI Review  │         │
│                                   │ Claude Sonnet审查  │         │
│                                   │ (可选,high/max)    │         │
│                                   └─────────┬─────────┘         │
│                                             │ ✅                │
│                                             ▼                    │
│                                   PR创建 ──▶ CI E2E              │
│                                             │                    │
│                                             ▼                    │
│                                   ┌───────────────────┐         │
│                                   │ 第四层: CI质量门控  │         │
│                                   │ 功能E2E            │         │
│                                   │ 控制台警告检查      │         │
│                                   │ 视觉回归(可选)      │         │
│                                   └─────────┬─────────┘         │
│                                             │ ✅                │
│                                             ▼                    │
│                                   Auto Merge ──▶ [Done]         │
│                                                                 │
│   安全边界: 最大重试3次 | 无人值守≤20min | 分级信任等级            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 三、详细优化措施

### 3.1 CLAUDE.md精简优化（P0，预计2h）

**原则**：只写AI无法从代码推断的内容，控制在300行以内

**优化方案**：

```
docs/agent-docs/
├── CLAUDE.md（精简版，核心规则，<100行）    ← 注入到每个CC
├── shared-conventions.md（环境信息、Git规范）  ← 保留
├── issue-workflow.md（三阶段流程）            ← 保留
├── backend-guide.md（后端技术细节）           ← 仅后端CC读取
├── frontend-guide.md（前端技术细节）          ← 仅前端CC读取
├── testing-guide.md（E2E测试）               ← 仅测试CC读取
├── pipeline-guide.md（管线规范）             ← 仅管线CC读取
└── api-contracts.md（接口契约）              ← fullstack时读取
```

**精简版CLAUDE.md核心内容**：

```markdown
# 万德AI平台 - Claude Code约束

## 项目概览
Vue3 + Ant Design Vue 4.x + Vben Admin / Spring Boot + RuoYi / Python Pipeline
Monorepo: backend/ + frontend/ + e2e/ + pipeline/

## IMPORTANT: 绝对禁止
- **YOU MUST NOT** 使用 `visible` 属性在Drawer/Modal上 → 使用 `open`
- **YOU MUST NOT** 嵌套Drawer/Modal → 使用独立组件+事件通信
- **YOU MUST NOT** 添加前端路由而不配置后端sys_menu表
- **YOU MUST NOT** 使用 `any` 类型
- **YOU MUST NOT** 引用不存在的静态页面

## 核心命令
| 任务 | 命令 |
|------|------|
| 前端开发 | cd frontend && pnpm dev |
| 后端开发 | cd backend && mvn spring-boot:run |
| 前端构建 | cd frontend && pnpm build |
| 后端编译 | cd backend && mvn compile -Pprod |
| 单元测试 | mvn test / pnpm test |

## 工作流程
1. 阅读Issue → 创建./issues/issue-N/task.md
2. 先写测试(TDD) → 运行确认失败
3. 实现代码 → 测试通过
4. 构建/编译检查通过
5. 提交PR

## 领域知识（按需阅读）
- Ant Design Vue 4.x: @docs/antdv-constraints.md
- VxeGrid规范: @docs/vxe-grid-api.md
- 菜单配置: @docs/menu-config-guide.md

## Git规范
- 分支: feat/issue-N-desc
- Commit: feat(scope): desc #N
```

---

### 3.2 静态分析防御层（P0，预计4h）

#### 3.2.1 ESLint废弃API规则

创建 `frontend/eslint-rules/no-deprecated-antdv-props.js`：

```javascript
module.exports = {
    meta: {
        type: 'problem',
        docs: { description: '禁止Ant Design Vue 4.x废弃属性' },
        fixable: 'code',
        messages: {
            deprecated: '{{old}}已废弃，请使用{{new}}'
        }
    },
    create(context) {
        const DEPRECATED = {
            'a-drawer': { visible: 'open' },
            'a-modal': { visible: 'open' },
            'a-dropdown': { visible: 'open' },
            'a-tooltip': { visible: 'open' },
            'a-popover': { visible: 'open' },
        };
        return {
            VAttribute(node) {
                const tag = node.parent?.name?.toLowerCase();
                const prop = node.key?.argument?.name;
                if (DEPRECATED[tag]?.[prop]) {
                    context.report({
                        node,
                        messageId: 'deprecated',
                        data: { old: prop, new: DEPRECATED[tag][prop] },
                        fix: f => f.replaceText(node.key.argument, DEPRECATED[tag][prop])
                    });
                }
            }
        };
    }
};
```

#### 3.2.2 组件嵌套检查规则

创建 `frontend/eslint-rules/no-nested-overlay.js`：

```javascript
module.exports = {
    meta: { type: 'problem' },
    create(context) {
        const OVERLAYS = ['a-drawer', 'a-modal'];
        const stack = [];
        return {
            VElement(node) {
                const tag = node.name?.toLowerCase();
                if (OVERLAYS.includes(tag)) {
                    if (stack.length > 0) {
                        context.report({ node, message: `禁止嵌套${tag}，当前在${stack[stack.length-1]}内` });
                    }
                    stack.push(tag);
                }
            },
            'VElement:exit'(node) {
                if (OVERLAYS.includes(node.name?.toLowerCase())) stack.pop();
            }
        };
    }
};
```

#### 3.2.3 路由完整性检查脚本

创建 `scripts/check-route-integrity.sh`：

```bash
#!/bin/bash
# 检查前端路由是否都有后端菜单配置
FRONTEND_ROUTES=$(grep -rPoh "path:\s*['\"]([^'\"]+)['\"]" frontend/src/router/ | grep -oP "(?<=['\"])[^'\"]+")

for route in $FRONTEND_ROUTES; do
  # 查询sys_menu表
  exists=$(psql -h localhost -p 5433 -U wande -d wande_ai -tAc \
    "SELECT 1 FROM sys_menu WHERE path='$route' LIMIT 1")
  if [ -z "$exists" ]; then
    echo "WARNING: 路由 '$route' 未在sys_menu配置"
  fi
done
```

---

### 3.3 控制台警告检测（P1，预计4h）

在E2E测试中增加控制台监控：

```typescript
// e2e/helpers/console-monitor.ts
import { Page } from '@playwright/test';

export function setupConsoleMonitor(page: Page) {
    const issues: string[] = [];

    page.on('console', msg => {
        const text = msg.text();
        if (text.includes('deprecated') ||
            text.includes('[Vue warn]') ||
            text.includes('is not a function')) {
            issues.push(`[${msg.type()}] ${text} (at ${page.url()})`);
        }
    });

    return {
        getIssues: () => issues,
        assertNoIssues: () => {
            if (issues.length > 0) {
                throw new Error(`发现${issues.length}个控制台问题:\n${issues.join('\n')}`);
            }
        }
    };
}

// 使用示例
test('页面无废弃警告', async ({ page }) => {
    const monitor = setupConsoleMonitor(page);
    await page.goto('/your-page');
    await page.waitForLoadState('networkidle');
    monitor.assertNoIssues();
});
```

---

### 3.4 Issue模板增强（P1，预计2h）

创建 `.github/ISSUE_TEMPLATE/feature-request.yml`：

```yaml
name: 功能需求
body:
  - type: textarea
    id: description
    attributes:
      label: 功能描述
    validations:
      required: true

  - type: textarea
    id: acceptance
    attributes:
      label: 验收标准
      value: |
        - [ ] 功能按描述正常工作
        - [ ] 未使用Ant Design Vue废弃API（visible→open）
        - [ ] 未引入嵌套Drawer/Modal结构
        - [ ] 新增路由已在sys_menu配置
        - [ ] E2E测试覆盖核心路径
        - [ ] 无控制台警告或错误
    validations:
      required: true

  - type: textarea
    id: constraints
    attributes:
      label: 技术约束
      value: |
        ## 组件库版本
        - Ant Design Vue 4.x: Drawer/Modal用open而非visible
        - VxeGrid: 参考docs/vxe-grid-api.md

        ## 架构约束
        - 新页面必须: 前端路由 + sys_menu配置
        - 禁止嵌套Drawer/Modal
```

---

### 3.5 模型选择策略（P2，预计4h）

**分级路由策略**：

```bash
# 在run-cc.sh中增加复杂度判断逻辑

decide_model() {
  local issue_num=$1
  local labels=$(gh issue view $issue_num --json labels --jq '.labels[].name')
  
  # 高复杂度：架构决策、跨模块重构
  if echo "$labels" | grep -qE "type:refactor|size/L"; then
    echo "claude-opus-4-6"
    echo "high"
    
  # 中等复杂度：常规CRUD
  elif echo "$labels" | grep -qE "type:feature"; then
    echo "claude-sonnet-4-6"
    echo "medium"
    
  # 低复杂度：文档、配置
  elif echo "$labels" | grep -qE "type:docs|type:config"; then
    echo "claude-sonnet-4-6"
    echo "low"
    
  # 默认
  else
    echo "claude-sonnet-4-6"
    echo "medium"
  fi
}
```

**Token Pool分级路由**（配置proxy）：

```yaml
# 禁止前端任务路由到Qwen
frontend_tasks:
  allowed_models:
    - claude-opus-4-6
    - claude-sonnet-4-6
  fallback: claude-sonnet-4-6

backend_tasks:
  allowed_models:
    - claude-opus-4-6
    - claude-sonnet-4-6
    - qwen-122b  # 仅后端可降级
  fallback: claude-sonnet-4-6
```

---

### 3.6 自动化安全边界（P2，预计3h）

**在run-cc.sh中增加**：

```bash
# 最大重试次数
MAX_RETRIES=3
RETRY_COUNT_FILE="/tmp/cc-retry-${REPO}-${ISSUE}"

check_retry_limit() {
  local count=$(cat "$RETRY_COUNT_FILE" 2>/dev/null || echo 0)
  if [ "$count" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: 已达到最大重试次数($MAX_RETRIES)，需人工介入"
    bash scripts/update-project-status.sh play "$ISSUE" "Fail"
    exit 1
  fi
  echo $((count + 1)) > "$RETRY_COUNT_FILE"
}

# 无人值守超时检测（20分钟）
MAX_IDLE_MINUTES=20
check_idle_timeout() {
  local logfile="$LOGDIR/${REPO}-${ISSUE}.log"
  local last_modified=$(stat -c %Y "$logfile" 2>/dev/null || echo 0)
  local now=$(date +%s)
  local idle_minutes=$(( (now - last_modified) / 60 ))
  
  if [ "$idle_minutes" -ge "$MAX_IDLE_MINUTES" ]; then
    echo "WARNING: CC已空闲${idle_minutes}分钟，可能卡住"
    # 发送通知
    curl -X POST https://api.getmoshi.app/api/webhook \
      -d "{\"title\":\"CC超时\",\"message\":\"${REPO}#${ISSUE}已空闲${idle_minutes}分钟\"}"
  fi
}
```

---

### 3.7 渐进式信任等级（P3，预计8h）

| 等级 | 条件 | 自动化程度 |
|------|------|-----------|
| L0 | 任何PR | AI写代码 + 人工审查 + 人工merge |
| L1 | 仅测试/文档 | AI写代码 + AI审查 + 人工一键merge |
| L2 | 变更<50行 + CI全通过 | AI写代码 + AI审查 + 延迟1h自动merge |
| L3 | L2 + 同类任务连续20次成功 | 即时自动merge |

**实现方式**：在PR描述中记录统计信息

```yaml
# PR模板
model_used: claude-sonnet-4-6
task_complexity: medium
lines_changed: 45
trust_level: L1
```

---

## 四、实施路线图

| 优先级 | 措施 | 预计工时 | 效果 |
|--------|------|----------|------|
| **P0** | CLAUDE.md精简优化 | 2h | 提升AI指令遵循率 |
| **P0** | ESLint废弃API规则 | 2h | 100%阻止`:visible`问题 |
| **P0** | ESLint嵌套检查规则 | 1h | 阻止嵌套Drawer/Modal |
| **P0** | 创建antdv-constraints.md | 1h | 渐进式披露关键约束 |
| **P1** | 控制台警告CI检查 | 4h | 捕获运行时废弃API |
| **P1** | 路由完整性检查脚本 | 3h | 防止前后端路由不一致 |
| **P1** | Issue模板增强 | 2h | 从源头约束AI行为 |
| **P2** | 模型分级路由策略 | 4h | 优化成本/质量平衡 |
| **P2** | 自动化安全边界 | 3h | 防止无限重试 |
| **P3** | 渐进式信任等级 | 8h | 安全扩展自动化范围 |

---

## 五、预期效果

1. **质量提升**：静态分析100%拦截废弃API和嵌套结构问题
2. **效率提升**：精简CLAUDE.md提升AI理解效率，减少无效迭代
3. **成本优化**：Sonnet/Opus分级路由，80%任务用Sonnet完成
4. **风险可控**：最大重试3次、无人值守≤20分钟、渐进式信任等级

---

请确认这个优化方案是否符合你的预期，我可以按优先级逐步执行。
