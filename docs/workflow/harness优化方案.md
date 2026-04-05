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
        - [ ] 单元测试已编写并通过
        - [ ] 未使用Ant Design Vue废弃API（visible→open）
        - [ ] 未引入嵌套Drawer/Modal结构
        - [ ] 新增路由已在sys_menu配置
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

**设计说明**：
- 验收标准中**不提及E2E测试**，原因：
  1. 职责分离：编程CC专注单元测试，E2E由CI/测试CC负责
  2. 推理效率：AI不需要知道"无法操作的信息"
  3. 工作目录隔离：编程CC在feature分支，无法访问E2E专用目录

---

### 3.5 AI Review与Agent Teams策略（P1，预计3h）

#### 3.5.1 执行方式对比

| 方式 | Token消耗 | 时间效率 | 适用场景 |
|------|----------|----------|----------|
| **同会话Review** | 上下文累积，Review阶段额外消耗20-30% token | 较快（无启动开销） | 简单Issue、小改动 |
| **独立CC Review** | 独立上下文，总token更多但可并行 | 较慢（需启动新CC） | 复杂Issue、架构审查 |
| **Agent Teams** | 最高（多个Agent并行+协调） | 最快（并行开发） | fullstack Issue |

#### 3.5.2 Agent Teams适用性分析

```
Issue类型判定：
├── module:backend → 单Agent（后端CC）
├── module:frontend → 单Agent（前端CC）  
├── module:pipeline → 单Agent（管线CC）
└── module:fullstack → 需要进一步分析
        ├── 简单fullstack（单表CRUD）→ 单Agent顺序开发
        │     理由：前后端强耦合，并行反而增加协调成本
        │
        └── 复杂fullstack（多表/新模块）→ Agent Teams
              理由：后端/前端可并行，接口契约作为协调点
```

#### 3.5.3 Token消耗估算

| 场景 | 单Agent | Agent Teams | 节省/增加 |
|------|---------|-------------|-----------|
| 简单CRUD（单表） | ~50k tokens | ~120k tokens（3 Agents） | +140% |
| 中等复杂（2-3表） | ~80k tokens | ~150k tokens | +87% |
| 复杂模块（5+表） | ~150k tokens（串行2天） | ~180k tokens（并行1天） | +20% token，**-50%时间** |

#### 3.5.4 Agent Teams触发规则

```yaml
# Agent Teams触发规则
agent_teams_policy:
  # 强制使用Agent Teams
  must_use:
    - labels: ["module:fullstack", "size/L"]
    - labels: ["module:fullstack", "priority/P0"]
    - condition: "涉及新建模块（需要同时创建Entity/Mapper/Service/Controller/页面）"
  
  # 禁止使用Agent Teams
  must_not_use:
    - labels: ["module:backend"]  # 单模块
    - labels: ["module:frontend"] # 单模块
    - condition: "单表CRUD、小改动（<10个文件）"
  
  # 可选（研发经理CC判断）
  optional:
    - labels: ["module:fullstack", "size/M"]
    - condition: "涉及2-3个表，但前后端有清晰边界"
```

#### 3.5.5 结论：不建议所有Issue使用Agent Teams

**原因**：
1. **Token成本**：简单任务使用Agent Teams会增加80-140%的token消耗
2. **协调开销**：前后端强耦合的简单任务，并行反而增加沟通成本
3. **适用范围窄**：仅`module:fullstack`标签的Issue需要考虑，占比不到20%

**建议策略**：
- 80%的Issue（backend/frontend/pipeline单模块）→ 单Agent + 同会话自检
- 15%的Issue（简单fullstack）→ 单Agent顺序开发
- 5%的Issue（复杂fullstack + size/L）→ Agent Teams并行

---

### 3.6 模型选择策略（P2，预计4h）

#### 3.6.1 两套API体系

| 体系 | 环境变量 | 适用场景 |
|------|----------|----------|
| **Claude Max订阅** | 无（unset） | high/max复杂度任务 |
| **Token Pool Proxy** | `ANTHROPIC_BASE_URL=http://localhost:9855` | low/medium复杂度任务 |

#### 3.6.2 环境变量切换

**使用Token Pool Proxy时**：
```bash
export ANTHROPIC_BASE_URL=http://localhost:9855
export ANTHROPIC_API_KEY=dummy
export API_TIMEOUT_MS=3000000
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

**使用Claude Max订阅时**：
```bash
unset ANTHROPIC_BASE_URL
unset ANTHROPIC_API_KEY
unset API_TIMEOUT_MS
unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
```

#### 3.6.3 在run-cc.sh中实现API选择

```bash
# 在run-cc.sh中增加API选择逻辑
# effort参数由研发经理CC传入，脚本只负责根据effort设置环境变量

select_api_source() {
  local effort=$1

  case "$effort" in
    max)
      # 仅max级别：使用Claude Max订阅（真实Opus/Sonnet，1M上下文）
      unset ANTHROPIC_BASE_URL
      unset ANTHROPIC_API_KEY
      unset API_TIMEOUT_MS
      unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
      echo "使用Claude Max订阅（真实模型，1M上下文）"
      ;;
    low|medium|high)
      # 其他级别：全部走Token Pool Proxy（自动截断保护）
      export ANTHROPIC_BASE_URL=http://localhost:9855
      export ANTHROPIC_API_KEY=dummy
      export API_TIMEOUT_MS=3000000
      export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
      echo "使用Token Pool Proxy（模型重写+上下文截断）"
      ;;
  esac
}

# 在启动CC前调用
select_api_source "$EFFORT"
```

#### 3.6.4 分级路由策略：研发经理CC主动判断

**核心原则：effort和模型由研发经理CC结合Issue完整内容主动判断，不依赖labels自动化。**

研发经理CC（使用Claude Max订阅手工启动）在触发编程CC前：
1. 已读取Issue完整内容（标题+描述+评论）
2. 已了解当前Sprint目标和模块上下文
3. 根据以下维度综合判断effort参数

**判断维度**：

| 维度 | low | medium | high | max |
|------|-----|--------|------|-----|
| 涉及文件数 | 1-2个 | 3-10个 | 10-20个 | 20+个 |
| 涉及表数 | 0 | 1-2张 | 3-5张 | 5+张 |
| 是否新建模块 | 否 | 否 | 可能 | 是 |
| 跨模块依赖 | 无 | 无 | 有 | 复杂 |
| 业务逻辑复杂度 | 配置/文档 | 标准CRUD | 多表关联/复杂查询 | 架构设计 |
| 典型场景 | 改README、调CSS | Entity+CRUD+页面 | 权限重构、模块合并 | 数据库迁移、新业务域 |

**研发经理CC的调度命令示例**：

```bash
# max级别（默认Sonnet，真实模型 + 1M上下文）
bash scripts/run-cc.sh backend 1234 claude-sonnet-4-6 kimi3 max

# max级别 + Opus（极少使用，仅架构级决策）
bash scripts/run-cc.sh backend 1234 claude-opus-4-6 kimi3 max

# high级别（走proxy，实际用kimi-k2.5/glm-5.1）
bash scripts/run-cc.sh backend 1235 claude-sonnet-4-6 kimi4 high

# medium级别（走proxy）
bash scripts/run-cc.sh frontend 1236 claude-sonnet-4-6 kimi5 medium
```

**注意**：
- effort=max时不走proxy，model参数就是真实使用的模型
- effort非max时走proxy，model参数被重写为供应商模型
- **max默认用Sonnet即可，Opus需研发经理CC手动指定，仅限架构级决策**

#### 3.6.5 上下文窗口限制分析

| 供应商 | 模型 | 上下文窗口 |
|--------|------|-----------|
| Claude Max | claude-opus-4-6 | **1M tokens** |
| Kimi | kimi-k2.5 | 256K tokens |
| 智谱 | glm-5.1 | 200K tokens |
| 无问星穹 | glm-5 | 200K tokens |
| 火山方舟 | kimi-k2.5 | 256K tokens |

**关键发现**：
- Token Pool Proxy **没有上下文截断功能**，��不转发effort/thinking参数
- 当CC对话超过供应商上下文上限时（kimi 256K / glm 200K），供应商直接报错，CC进程崩溃
- high级别任务（多文件重构）上下文可能接近或超过200K

#### 3.6.6 API来源对照表（已确认：方��A+C）

| effort | API来源 | 模型 | 上下文 | 适用场景 |
|--------|---------|------|--------|---------|
| `max` | Claude Max订阅 | 真实claude-sonnet-4-6 | 1M | 跨模块重构、新业务域建设 |
| `high` | Token Pool Proxy | kimi-k2.5/glm-5.1 | 200-256K（自动截断） | 多文件重构、复杂业务 |
| `medium` | Token Pool Proxy | kimi-k2.5/glm-5.1 | 200-256K（自动截断） | 常规CRUD |
| `low` | Token Pool Proxy | kimi-k2.5/glm-5.1 | 200-256K（自动截断） | 文档、配置变更 |

**Claude Max订阅内的模型选择**：
- **默认使用Sonnet**（`claude-sonnet-4-6`），能满足绝大多数编程任务
- **仅在以下场景使用Opus**��`claude-opus-4-6`）：由研发经理CC手动指定
  - 全局架构调整（如Monorepo迁移、模块合并）
  - 15+文件的跨模块状态管理迁移
  - 复杂权衡的架构决策

当前平台一般不会有大的架构调整，所以**max级别实际上就是Sonnet + 1M上下文 + 真实模型**。

#### 3.6.7 Token Pool Proxy上下文截断功能（新增）

**keys.json增加`context_window`字段**：

```json
{
  "keys": [
    {
      "name": "kimi1",
      "type": "anthropic_compat",
      "provider": "kimi",
      "api_url": "https://api.kimi.com/coding/",
      "api_key": "sk-kimi-xxx",
      "context_window": 262144,
      "model_map": {
        "claude-opus-4-6": "kimi-k2.5",
        "claude-sonnet-4-6": "kimi-k2.5"
      }
    },
    {
      "name": "zhipu_max_1",
      "type": "anthropic_compat",
      "provider": "zhipu",
      "api_url": "https://open.bigmodel.cn/api/anthropic",
      "api_key": "xxx",
      "context_window": 204800,
      "model_map": {
        "claude-opus-4-6": "glm-5.1",
        "claude-sonnet-4-6": "glm-5.1"
      }
    },
    {
      "name": "claude_max",
      "type": "anthropic_compat",
      "provider": "anthropic",
      "api_url": "https://api.anthropic.com",
      "api_key": "sk-ant-xxx",
      "context_window": 1048576
    }
  ]
}
```

**proxy截断逻辑**：

```python
def truncate_messages(messages, system_prompt, context_window, reserve_output=8192):
    """根据目标模型的context_window自动截断消息历史"""
    max_input = context_window - reserve_output
    
    # 估算token数（1 token ≈ 4 chars中文/英文混合）
    def estimate_tokens(text):
        return len(text) // 3  # 保守估计
    
    system_tokens = estimate_tokens(system_prompt) if system_prompt else 0
    remaining = max_input - system_tokens
    
    # 保留策略：保留第一条（Issue内容）+ 尽可能多的最近消息
    if not messages:
        return messages
    
    first_msg = messages[0]
    first_tokens = estimate_tokens(str(first_msg.get("content", "")))
    remaining -= first_tokens
    
    # 从最新往前保留
    kept = []
    for msg in reversed(messages[1:]):
        msg_tokens = estimate_tokens(str(msg.get("content", "")))
        if remaining - msg_tokens < 0:
            break
        kept.insert(0, msg)
        remaining -= msg_tokens
    
    return [first_msg] + kept
```

**截断策略**：
1. 读取当前key的`context_window`值
2. 预留8192 tokens给输出
3. 保留第一条消息（通常含Issue内容，不可丢失）
4. 从最新消息往前保留，直到填满上下文窗口
5. 中间的旧消息被截断（丢失的是中间推理过程，不影响最终结果）

**设计说明**：
- 编程CC对API来源完全无感知，它只看到`--model`参数
- Token Pool Proxy会将`claude-opus-4-6`等模型名重写为实际供应商模型
- 研发经理CC通过设置/不设置环境变量来控制API来源，编程CC无需关心

**前提条件**：Claude Max订阅需要余额充足。不可用时，所有任务走Token Pool Proxy。

#### 3.6.6 重要约束：thinking签名不兼容

**同一CC会话不能混用两套API体系。** Token Pool Proxy（kimi/glm）生成的thinking block签名在Anthropic官方API中验证失败（HTTP 400 invalid signature）。

因此：
- 每个CC会话在启动时确定API来源，整个会话不可切换
- `run-cc.sh` 和 `run-cc-with-prompt.sh` 都必须在tmux启动前确定环境变量

---

### 3.6 自动化安全边界（P2，预计3h）

#### 3.6.1 最大重试次数限制（在run-cc.sh中）

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
```

#### 3.6.2 无人值守超时检测（在研发经理CC中）

**执行时机**：研发经理CC触发下一个编程CC前执行

```bash
# 在 check-cc-status.sh 中增加超时检测

MAX_IDLE_MINUTES=20

check_idle_timeout() {
  local logfile="$LOGDIR/${REPO}-${ISSUE}.log"
  local last_modified=$(stat -c %Y "$logfile" 2>/dev/null || echo 0)
  local now=$(date +%s)
  local idle_minutes=$(( (now - last_modified) / 60 ))
  
  if [ "$idle_minutes" -ge "$MAX_IDLE_MINUTES" ]; then
    echo "WARNING: ${REPO}#${ISSUE} 已空闲${idle_minutes}分钟，可能卡住"
    
    # 1. 发送通知
    curl -X POST https://api.getmoshi.app/api/webhook \
      -d "{\"title\":\"CC超时\",\"message\":\"${REPO}#${ISSUE}已空闲${idle_minutes}分钟\"}"
    
    # 2. 标记Issue为Fail
    bash scripts/update-project-status.sh play "$ISSUE" "Fail"
    
    # 3. 清理tmux会话
    tmux kill-session -t "cc-${REPO}-${ISSUE}" 2>/dev/null
    
    return 1  # 超时
  fi
  return 0  # 正常
}
```

#### 3.6.3 研发经理CC调度流程（更新后）

```bash
# 研发经理CC调度流程
dispatch_next_cc() {
  # 1. 检查CC状态
  bash scripts/check-cc-status.sh
  
  # 2. 检测超时CC（新增）
  for session in $(tmux list-sessions 2>/dev/null | grep "^cc-" | cut -d: -f1); do
    repo=$(echo "$session" | cut -d- -f2)
    issue=$(echo "$session" | cut -d- -f3)
    check_idle_timeout "$repo" "$issue"
  done
  
  # 3. 查看空闲目录
  available_dirs=$(get_available_dirs)
  
  # 4. 触发下一个CC
  if [ -n "$available_dirs" ]; then
    bash scripts/run-cc.sh <module> <issue> <model> <suffix> <effort>
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

### 3.8 自动冲突解决工作流（P1，预计4h）

#### 3.8.1 问题背景

当前调度器直接执行 `git checkout --theirs` 解决冲突，存在风险：
1. 可能丢失 PR 作者的代码
2. 没有智能分析冲突语义
3. 复杂冲突无法自动处理

#### 3.8.2 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    调度器 (Scheduler CC)                      │
│                  /home/ubuntu/projects/.github               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 检测到 PR 冲突
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              冲突解决 CC (Conflict Resolver)                   │
│               /home/ubuntu/projects/wande-play-ci            │
│                                                              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐        │
│  │ 分析冲突    │ → │ 智能合并    │ → │ 编译测试    │        │
│  │ 分类处理    │   │ 保留功能    │   │ 推送结果    │        │
│  └─────────────┘   └─────────────┘   └─────────────┘        │
│                                                              │
│  并发控制: CI 全局排队 (concurrency.group: pr-e2e-test)       │
└─────────────────────────────────────────────────────────────┘
```

#### 3.8.3 冲突分类处理策略

| 文件类型 | 处理方式 | 理由 |
|---------|---------|------|
| `**/schema.sql` | 自动解决（使用dev版本） | 测试数据库结构，dev为准 |
| `**/pom.xml` | 自动解决 | 依赖配置，dev为准 |
| `**/test/**/*.java` | 自动解决 | 测试代码，不影响业务 |
| `**/*.java` | CC智能解决 | 业务代码，需理解意图 |
| `**/*.ts` / `**/*.vue` | CC智能解决 | 前端代码，需理解意图 |
| rename/delete冲突 | CC智能解决 | 文件重命名/删除，需人工判断 |

#### 3.8.4 工作流程

```
feature分支push / CI合并时检测冲突
    │
    ▼
分析冲突文件类型
    │
    ├─── 简单冲突（schema/pom/test）
    │         │
    │         ▼
    │    自动解决：git checkout --theirs
    │         │
    │         ▼
    │    提交并继续
    │
    └─── 复杂冲突（业务代码/rename/delete）
              │
              ▼
         触发冲突解决CC
              │
              ├── 1. 读取冲突详情 (issues/issue-pr-N/conflict.md)
              ├── 2. 分析双方修改意图
              ├── 3. 智能合并，保留双方功能
              ├── 4. 编译验证 (mvn compile / pnpm build)
              ├── 5. 提交: fix: resolve merge conflicts for PR #N
              └── 6. 推送并报告结果
```

#### 3.8.5 触发时机

| 触发点 | 触发条件 | 脚本 |
|--------|----------|------|
| feature分支push | `git push` 失败（冲突） | `post-task.sh` 检测并触发 |
| CI合并 | `gh pr merge` 失败 | `cycle-merge.sh` 检测并触发 |
| 定时任务 | 每10分钟扫描冲突PR | `trigger-conflict-resolver.sh` |

#### 3.8.6 CC Prompt模板

```markdown
# 任务：解决 PR 合并冲突

## PR 信息
- PR 号: #123
- 标题: [模块] 功能描述
- 分支: feature-xxx -> dev

## 冲突详情
请阅读 `issues/issue-pr-123/conflict.md`

## 解决原则
1. **保留双方功能**: 不要简单地选择一边，要合并两边的逻辑
2. **语义理解**: 理解代码修改的意图，而不是机械合并
3. **编译验证**: 解决后运行 `mvn compile` 确保编译通过
4. **测试验证**: 如果有测试，确保测试通过

## 输出要求
1. 解决所有冲突文件
2. 提交 commit: `fix: resolve merge conflicts for PR #123`
3. 推送到远程分支
4. 报告解决结果
```

#### 3.8.7 目录隔离

```
wande-play-ci/              # 冲突解决CC专用目录（复用CI目录）
├── issues/
│   └── issue-pr-123/
│       ├── conflict.md     # 冲突详情（自动生成）
│       ├── resolved.md     # 解决报告（CC输出）
│       └── .progress       # 进度标记
├── backend/
└── frontend/
```

#### 3.8.8 并发控制

利用现有的CI全局排队机制：
```yaml
concurrency:
  group: pr-e2e-test        # 与CI共享队列
  cancel-in-progress: false # 不取消进行中的任务
```

确保：
1. 冲突解决CC与CI测试串行执行
2. 不会出现多个CC同时修改同一分支
3. 避免资源竞争

---

## 四、实施路线图

| 优先级 | 措施 | 预计工时 | 效果 |
|--------|------|----------|------|
| **P0** | CLAUDE.md精简优化 | 2h | 提升AI指令遵循率 |
| **P0** | ESLint废弃API规则 | 2h | 100%阻止`:visible`问题 |
| **P0** | ESLint嵌套检查规则 | 1h | 阻止嵌套Drawer/Modal |
| **P0** | 创建antdv-constraints.md | 1h | 渐进式披露关键约束 |
| **P1** | Agent Teams触发规则 | 2h | 优化Token消耗，仅必要场景使用 |
| **P1** | 控制台警告CI检查 | 4h | 捕获运行时废弃API |
| **P1** | 路由完整性检查脚本 | 3h | 防止前后端路由不一致 |
| **P1** | Issue模板增强 | 2h | 从源头约束AI行为 |
| **P1** | 自动冲突解决工作流 | 6h | 智能解决PR冲突，减少人工介入 |
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

## 六、目录结构优化方案（已确认）

### 6.1 设计原则

| 维度 | 说明 |
|------|------|
| **注意力预算** | 主CLAUDE.md精简，AI不会被过多信息稀释注意力 |
| **单一真相源** | 公共约束只维护一份，避免不一致 |
| **按需加载** | 编程CC根据module标签只读取对应的子模块约束 |
| **维护成本** | 集中在.github/agent-docs/管理，不分散在各仓库 |

### 6.2 目录结构

```
wande-play/
├── CLAUDE.md                    # 主约束（<100行，公共内容+索引）
├── backend/
│   └── (无CLAUDE.md)            # 子模块不再单独维护
├── frontend/
│   └── (无CLAUDE.md)
├── pipeline/
│   └── (无CLAUDE.md)
└── .github/agent-docs/
    ├── README.md                # 索引文件
    ├── shared-conventions.md    # 公共规范（Git、数据库、认证）
    ├── issue-workflow.md        # Issue三阶段流程
    ├── backend/
    │   ├── README.md            # 后端索引
    │   ├── architecture.md      # 项目结构、包路径规范
    │   ├── conventions.md       # Entity/Mapper/Service模板
    │   ├── testing.md           # TDD规范
    │   └── db-schema.md         # 数据库规范
    ├── frontend/
    │   ├── README.md            # 前端索引
    │   ├── ui-guide.md          # UI规范（useVbenVxeGrid等）
    │   ├── conventions.md       # 命名规范、文件组织
    │   ├── antdv-constraints.md # Ant Design Vue 4.x约束
    │   └── testing.md           # 组件测试规范
    └── pipeline/
        ├── README.md            # 管线索引
        ├── domestic-projects.md # 国内项目管线
        └── testing.md           # pytest规范
```

### 6.3 主CLAUDE.md内容

```markdown
# 万德AI平台 - Claude Code约束

## 项目概览
Vue3 + Ant Design Vue 4.x + Vben Admin / Spring Boot + RuoYi / Python Pipeline
Monorepo: backend/ + frontend/ + e2e/ + pipeline/

## IMPORTANT: 接口契约优先
前后端接口契约是**唯一接口真相源**。任何新增、修改、删除API都必须：
1. **先更新契约** — `shared/api-contracts/` 目录下的YAML文件
2. **再写代码** — 后端Controller/前端API调用必须与契约一致
3. **契约文件**: @shared/api-contracts/README.md

## IMPORTANT: 绝对禁止
- **YOU MUST NOT** 使用 `visible` 属性 → 用 `open`
- **YOU MUST NOT** 嵌套Drawer/Modal → 独立组件+事件
- **YOU MUST NOT** 添加路由而不配置sys_menu
- **YOU MUST NOT** 使用 `any` 类型

## 公共命令
| 任务 | 命令 |
|------|------|
| 前端构建 | cd frontend && pnpm build |
| 后端编译 | cd backend && mvn compile -Pprod |
| 单元测试 | mvn test / pnpm test |

## 工作流程
1. 阅读Issue → 创建./issues/issue-N/task.md
2. **涉及API变更？先更新接口契约**
3. TDD：先写测试 → 确认失败 → 实现 → 通过
4. 构建/编译检查 → 提交PR

## 子模块约束（按需阅读）
- **接口契约**: @shared/api-contracts/README.md
- **backend**: @.github/agent-docs/backend/README.md
- **frontend**: @.github/agent-docs/frontend/README.md
- **pipeline**: @.github/agent-docs/pipeline/README.md
- **公共规范**: @.github/agent-docs/shared-conventions.md
- **Issue流程**: @.github/agent-docs/issue-workflow.md

## Git规范
- 分支: feat/issue-N-desc
- Commit: feat(scope): desc #N
- PR: 只push feature分支，创建feature→dev的PR
```

### 6.4 run-cc.sh触发逻辑调整

```bash
# 根据module参数决定额外注入哪些约束
case "$REPO" in
  backend)
    PROMPT="$PROMPT

参考约束文件:
- @.github/agent-docs/backend/README.md
- @.github/agent-docs/shared-conventions.md"
    ;;
  frontend)
    PROMPT="$PROMPT

参考约束文件:
- @.github/agent-docs/frontend/README.md
- @.github/agent-docs/frontend/antdv-constraints.md
- @.github/agent-docs/shared-conventions.md"
    ;;
  ...
esac
```

---

## 七、待办事项

### 7.1 P0 任务（立即执行）

| # | 任务 | 文件/位置 | 预计工时 | 状态 |
|---|------|----------|----------|------|
| 1 | 创建 `.github/agent-docs/` 子目录结构 | `.github/agent-docs/{backend,frontend,pipeline}/` | 0.5h | ✅ 已完成 |
| 2 | 创建精简版主 `CLAUDE.md`（含接口契约优先） | `wande-play/CLAUDE.md` | 1h | ✅ 已完成 |
| 3 | 整合后端约束到 `backend/` 子目录（含db-prompt） | `.github/agent-docs/backend/` | 1h | ✅ 已完成 |
| 4 | 整合前端约束到 `frontend/` 子目录 | `.github/agent-docs/frontend/` | 1h | ✅ 已完成 |
| 5 | 整合管线约束到 `pipeline/` 子目录 | `.github/agent-docs/pipeline/` | 0.5h | ✅ 已完成 |
| 6 | 删除各子模块CLAUDE.md（**含解决backend冲突标记**） | `backend/CLAUDE.md`, `frontend/CLAUDE.md`, `pipeline/CLAUDE.md` | 0.5h | ✅ 已完成 |
| 7 | 创建 `antdv-constraints.md` | `.github/agent-docs/frontend/antdv-constraints.md` | 1h | ✅ 已完成 |
| 8 | 创建ESLint废弃API规则 | `frontend/eslint-rules/no-deprecated-antdv-props.js` | 2h | ⏳ 需Issue创建后由编程CC执行 |
| 9 | 创建ESLint嵌套检查规则 | `frontend/eslint-rules/no-nested-overlay.js` | 1h | ⏳ 需Issue创建后由编程CC执行 |

### 7.2 P1 任务（本周完成）

| # | 任务 | 文件/位置 | 预计工时 | 状态 |
|---|------|----------|----------|------|
| 10 | 实现Agent Teams触发规则 | `scripts/run-cc.sh` | 2h | ⏳ 待执行 |
| 11 | 创建路由完整性检查脚本 | `scripts/check-route-integrity.sh` | 3h | ⏳ 待执行 |
| 12 | 创建控制台警告监控工具 | `e2e/helpers/console-monitor.ts` | 4h | ⏳ 待执行 |
| 13 | 创建Issue模板（含验收标准） | `.github/ISSUE_TEMPLATE/feature-request.yml` | 2h | ⏳ 待执行 |
| 14 | 更新 `run-cc.sh` API选择逻辑 | `scripts/run-cc.sh` | 2h | ✅ 已完成 |
| 15 | 更新 `run-cc-with-prompt.sh` API选择逻辑 | `scripts/run-cc-with-prompt.sh` | 1h | ✅ 已完成 |
| 16 | 创建冲突类型分析脚本 | `scripts/analyze-conflict-type.sh` | 2h | ⏳ 待执行 |
| 17 | 验证/完善已有 `trigger-conflict-resolver.sh` | `scripts/trigger-conflict-resolver.sh` | 1h | ✅ 脚本已存在，需验证 |
| 18 | 修改 `post-task.sh` 集成冲突检测 | `scripts/post-task.sh` | 1h | ⏳ 待执行 |
| 19 | 修改 `cycle-merge.sh` 替换粗暴冲突解决 | `scripts/cycle-merge.sh` | 2h | ⏳ 待执行 |
| 20 | 修改 `pr-test.yml` 增加冲突检测+触发解决 | `wande-play/.github/workflows/pr-test.yml` | 2h | ⏳ 待执行 |

### 7.3 P2 任务（本月完成）

| # | 任务 | 文件/位置 | 预计工时 | 状态 |
|---|------|----------|----------|------|
| 21 | keys.json增加`context_window`字段 | `scripts/model-switch/keys.json` | 0.5h | ⏳ 待执行 |
| 22 | proxy增加上下文自动截断功能 | `scripts/model-switch/token_pool_proxy.py` | 4h | ⏳ 待执行 |
| 23 | 增加最大重试次数限制（run-cc.sh） | `scripts/run-cc.sh` | 1h | ⏳ 待执行 |
| 24 | 增加超时检测（check-cc-status.sh） | `scripts/check-cc-status.sh` | 2h | ⏳ 待执行 |

### 7.4 P3 任务（下月规划）

| # | 任务 | 文件/位置 | 预计工时 | 状态 |
|---|------|----------|----------|------|
| 25 | 实现渐进式信任等级系统 | CI/CD配置 | 8h | ⏳ 待规划 |
| 26 | 集成Playwright视觉回归测试 | `e2e/visual/` | 8h | ⏳ 待规划 |
| 27 | 设置Claude PR Review Action | `.github/workflows/` | 4h | ⏳ 待规划 |

### 7.5 执行顺序

```
Phase 1 (P0): 目录结构整合 + 静态分析防御
    │
    ├─→ Task 1-6: CLAUDE.md重构
    │       └─→ 创建子目录 → 整合内容（含db-prompt）→ 删除子模块CLAUDE.md（含修复backend冲突标记）
    │
    └─→ Task 7-9: ESLint规则
            └─→ 废弃API检查 + 嵌套检查

Phase 2 (P1): CI增强 + Agent Teams + 冲突解决 + API选择
    │
    ├─→ Task 10: Agent Teams触发规则
    │
    ├─→ Task 11-13: 检查脚本 + Issue模板
    │
    ├─→ Task 14-15: 启动脚本更新（run-cc.sh + run-cc-with-prompt.sh）
    │       └─→ 模块约束注入 + API来源选择 + thinking签名约束
    │
    └─→ Task 16-20: 自动冲突解决
            └─→ 分析脚本 + trigger验证 + post-task + cycle-merge + pr-test.yml

Phase 3 (P2): 安全边界
    │
    └─→ Task 21-24: 自动化限制
            └─→ 模型路由 + 重试限制 + 超时检测

Phase 4 (P3): 进阶功能
    │
    └─→ Task 25-27: 信任等级 + 视觉回归
```

---

## 八、讨论记录

| 日期 | 讨论内容 | 决策 |
|------|----------|------|
| 2026-04-05 | 目录结构方案：是否将各子模块CLAUDE.md整合到.github/agent-docs/ | ✅ 已确认执行 |
| 2026-04-05 | AI Review执行方式：同会话 vs 独立CC | ✅ 简单Issue同会话自检，复杂Issue可选独立Review |
| 2026-04-05 | Agent Teams是否应用于所有Issue | ✅ **不应用**。仅复杂fullstack（size/L或新建模块）使用，80%单模块Issue用单Agent |
| 2026-04-05 | 接口契约位置 | ✅ 放在主CLAUDE.md第二位（项目概览之后、绝对禁止之前） |
| 2026-04-05 | Issue模板是否提及E2E测试 | ✅ **不提及**。职责分离（编程CC做单元测试，E2E由CI/测试CC负责），避免无效推理 |
| 2026-04-05 | 自动冲突解决工作流 | ✅ 已确认。简单冲突自动解决，复杂冲突触发CC智能解决，复用wande-play-ci目录 |
| 2026-04-05 | 无人值守超时检测执行时机 | ✅ 由研发经理CC在触发下一个CC前执行（check-cc-status.sh），而非编程CC自检 |
| 2026-04-05 | 两套API体系切换策略 | ✅ high/max用Claude Max订阅（unset环境变量），low/medium用Token Pool Proxy（设置4个环境变量） |
| 2026-04-05 | thinking签名不兼容 | ✅ 同一CC会话不能混用两套API，启动时确定，整个会话不可切换 |
| 2026-04-05 | 全面复查发现9个遗漏 | ✅ backend/CLAUDE.md冲突标记、run-cc-with-prompt.sh缺API选择、cycle-merge.sh粗暴解决、pr-test.yml缺冲突检测、trigger脚本已存在、db-prompt未纳入目录等 |
| 2026-04-05 | 分级路由策略改为研发经理CC主动判断 | ✅ 不依赖labels自动化，由研发经理CC读取Issue完整内容后综合判断effort，run-cc.sh只负责根据effort选择API来源 |
| 2026-04-05 | API来源分级 + proxy截断 | ✅ 方案A+C：仅max走Claude Max订阅，其余走proxy。keys.json按真实模型配置`context_window`（kimi 256K/glm 200K），proxy自动截断 |
| 2026-04-05 | Claude Max内模型选择 | ✅ max级别默认用Sonnet（够用且省额度），Opus仅架构级决策时手动指定。当前平台一般无大架构调整 |

---

请确认这个优化方案是否符合你的预期，我可以按优先级逐步执行。
