# AI开发质量管控最佳实践研究报告

> 研究对象：万德AI平台（Vue3 + Ant Design Vue 4.x + Vben Admin + VxeGrid / Spring Boot + RuoYi）
> 研究时间：2026年4月
> 适用范围：Claude Code自动拾取GitHub Issue → TDD → PR → CI E2E → auto merge 全流程

---

## 目录

1. [行业最佳实践综述](#一行业最佳实践综述)
2. [针对万德平台的具体改进建议](#二针对万德平台的具体改进建议)
3. [Harness/CLAUDE.md改进建议](#三harnessclaudemd改进建议)
4. [大模型选择建议](#四大模型选择建议)
5. [被忽视的风险和前沿实践](#五被忽视的风险和前沿实践)

---

## 一、行业最佳实践综述

### 1.1 CLAUDE.md / AI编程约束机制最佳实践

#### 核心原则：少即是多

根据 [HumanLayer 的深度分析](https://www.humanlayer.dev/blog/writing-a-good-claude-md)，Claude Code 的系统提示已包含约 **50 条内置指令**。前沿思维模型（如 Claude Opus/Sonnet）能可靠遵循约 **150-200 条指令**，这意味着 CLAUDE.md 中的每一条规则都在消耗有限的"注意力预算"。更关键的是，Claude Code 会注入如下系统提示：

> "IMPORTANT: this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly relevant to your task."

这意味着当 CLAUDE.md 文件太长或内容不够聚焦时，Claude **会主动忽略其中的指令**。

**行业共识的 CLAUDE.md 最佳实践**（来源：[Anthropic 官方文档](https://docs.anthropic.com/en/docs/claude-code/best-practices)、[HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)、[SFEIR Institute](https://institute.sfeir.com/en/claude-code/claude-code-resources/best-practices/)）：

| 策略 | 说明 |
|------|------|
| **WHAT/WHY/HOW 框架** | 告诉 Claude 项目是什么、为什么这样设计、如何工作 |
| **控制在 300 行以内** | HumanLayer 的 CLAUDE.md 不到 60 行；越短越好 |
| **只写 Claude 无法从代码推断的内容** | 如果 Claude 读代码就能知道的，不要写进 CLAUDE.md |
| **渐进式披露（Progressive Disclosure）** | 将领域知识放在 `agent_docs/` 等独立文件，CLAUDE.md 只列文件目录和简介 |
| **不要当 Linter 用** | 代码风格规则用 ESLint/Prettier 处理，不要塞进 CLAUDE.md |
| **用 IMPORTANT/YOU MUST 强调关键规则** | 对于绝不能违反的约束，加强语气标注 |
| **使用 Hooks 而非指令** | 确定性操作（如 lint、format）用 hooks 保证执行，而非依赖 LLM "记住" |
| **定期修剪** | 像对待代码一样审查 CLAUDE.md，删除不再需要的规则 |

#### Anthropic 官方推荐的 CLAUDE.md 结构

根据 [Anthropic 官方最佳实践文档](https://docs.anthropic.com/en/docs/claude-code/best-practices)：

**应该包含的内容：**
- Claude 无法猜到的 Bash 命令
- 与默认不同的代码风格规则
- 测试指令和首选测试运行器
- 仓库规范（分支命名、PR 约定）
- 项目特有的架构决策
- 开发环境配置（环境变量等）
- 常见陷阱和非显而易见的行为

**不应该包含的内容：**
- Claude 通过阅读代码就能弄清的信息
- Claude 已知的标准语言约定
- 详细的 API 文档（应链接到文档而非内联）
- 频繁变化的信息
- 冗长的解释或教程
- 逐文件的代码库描述
- "写干净代码"等不言自明的规则

#### Cursor Rules 最佳实践

根据 [Kirill Markin 的实践指南](https://kirill-markin.com/articles/cursor-ide-rules-for-ai/) 和 [Trigger.dev 的博客](https://trigger.dev/blog/cursor-rules)，Cursor 的三级规则体系是当前最成熟的 AI 编程约束架构：

1. **全局规则**（Rules for AI in Settings）—— 适用于所有项目的基础规则
2. **项目级规则**（`.cursor/index.mdc`，Rule Type: Always）—— 项目标准
3. **动态上下文规则**（`.cursor/rules/*.mdc`）—— 仅在处理相关任务时激活

**关键洞察**：据 [Startupbricks 的研究](https://www.startupbricks.in/blog/cursor-rules-why-needed-setup-guide)，配置良好规则的开发者报告 **代码审查周期减少 40%**，AI 生成代码的修订周期减少 **40-60%**。带代码示例的规则效果是纯文字规则的 **3 倍**。

### 1.2 行业领先团队的 AI 编程配置

#### Anthropic 自身的实践

[Anthropic 的工程团队](https://www.reddit.com/r/ClaudeAI/comments/1k5slll/anthropics_guide_to_claude_code_best_practices/) 推荐的核心工作流：

1. **先探索、再计划、再编码**（Explore → Plan → Implement）
2. **给 Claude 验证自己工作的方式**（测试套件、Linter、截图对比）
3. **使用子代理（Subagents）处理调查性任务**——避免污染主会话上下文
4. **配置 Skills 封装可重用工作流**——如 `fix-issue` skill 自动从 GitHub Issue 到 PR

Anthropic 还推荐了 **Agent Teams** 模式：一个会话写代码，另一个会话审查代码，角色分离保证质量。

#### Shopify 的实践

[Shopify 的 CLAUDE.md 模板](https://gist.github.com/karimmtarek/3a8a636a05ae1c349ad0bba9d10425f0) 侧重前端主题开发约束。其关键策略是通过 **Shopify Dev MCP Server** 让 Claude 实时读取最新的 Shopify 文档，从根本上消除了 AI 模型"幻觉"过时 API 端点的问题。

#### Vercel 的实践

[Vercel 通过 AI Gateway](https://vercel.com/docs/agent-resources/coding-agents/claude-code) 统一管理 Claude Code 的流量，提供：
- AI Gateway Overview 中的流量和 Token 使用监控
- Vercel Observability 中的详细追踪
- 统一的 API 密钥管理

### 1.3 AI 生成前端代码的常见质量问题

根据 [Ranger 的研究报告](https://www.ranger.net/post/common-bugs-ai-generated-code-fixes) 和 [Baytech Consulting 的分析](https://www.baytechconsulting.com/blog/enterprise-coding-ai-milestone-2025)，AI 生成代码的常见问题包括：

| 问题类别 | 发生率 | 说明 |
|----------|--------|------|
| **安全漏洞** | 45% 的 AI 代码包含安全缺陷 | Java 代码失败率高达 72% |
| **静默逻辑故障** | 占故障的 60% | 通过测试但在边缘情况失败 |
| **废弃 API 使用** | 约 20% 包含幻觉引用 | 引用不存在的库或过时 API |
| **格式不一致** | AI PR 比人工多 2.66 倍 | 间距不一致、命名不规范 |
| **错误处理缺失** | AI PR 比人工多近 2 倍 | 缺少 null 检查、边界验证 |
| **性能问题** | GPT-4 生成代码慢 3 倍 | O(n²) 代替 O(n)、字符串拼接 |
| **过度依赖** | 外部依赖是人工代码的 2 倍 | "以防万一"地引入额外库 |

**特别是万德平台遇到的问题——废弃 API 使用——是 AI 编程中最普遍的问题之一。** 根据 [ZenVanRiel 的分析](https://zenvanriel.com/ai-engineer-blog/why-does-ai-generate-outdated-code-explained/)，AI 生成过时代码的根本原因是模型训练数据的时间滞后，尤其对快速迭代的前端框架（如 Ant Design Vue 从 `visible` 到 `open` 的变更）影响最大。

### 1.4 视觉回归测试在 AI 开发流程中的应用

根据 [OneUptime 的完整指南](https://oneuptime.com/blog/post/2026-01-30-visual-regression-testing/view) 和 [Bug0 的 Percy 分析](https://bug0.com/knowledge-base/percy-visual-regression-testing)：

**三大主流工具对比：**

| 工具 | 适用场景 | 集成方式 | 特点 |
|------|----------|----------|------|
| **Playwright 内置截图对比** | 轻量入门 | `toHaveScreenshot()` | 免费、本地运行、需自管基线 |
| **Percy（BrowserStack）** | 全页面/全流程 | `percySnapshot()` | 真实浏览器渲染、AI 智能差异分析、免费层可用 |
| **Chromatic（Storybook团队）** | 组件级测试 | Storybook 集成 | 专为组件库设计、交互式快照 |

**关键最佳实践：**
- **Mask 动态内容**（时间戳、头像、实时数据）防止误报
- **禁用 CSS 动画**后再截图
- **在 CI 中执行**而非本地，确保环境一致
- **每个 PR 触发**视觉测试，作为合并门控

### 1.5 Issue-driven AI 开发的质量门控

根据 [Anthropic 的 Skills 机制](https://docs.anthropic.com/en/docs/claude-code/best-practices)、[GitHub 的 Spec-driven Development](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) 和 [Skywork 的 CI/CD 集成指南](https://skywork.ai/blog/how-to-integrate-claude-code-ci-cd-guide-2025/)：

**理想的质量门控链路：**

```
Issue 描述 → AI 理解约束 → 生成测试（TDD）→ 实现代码 → 
本地验证 → PR → AI Review → CI/CD（lint + type + test + visual） → 
人工审查（架构级）→ Merge
```

**Spec-driven Development 模式**（来源：[GitHub Spec Kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)）：
- 把规格说明当作"可执行的活文档"而非静态文件
- Spec 成为共享的唯一事实来源
- 当出问题时回到 spec；当项目复杂时细化 spec

**AI Review AI 的双循环实践**（来源：[Test Double](https://testdouble.com/insights/pragmatic-approaches-to-agentic-coding-for-engineering-leaders)、[Reddit 实践者](https://www.reddit.com/r/vibecoding/comments/1r4i8sf/my_workflow_two_ai_coding_agents_crossreviewing/)）：

- **Loop 1（产品模式）**：快速迭代功能的外观和体验
- **Loop 2（工程模式）**：打开 Draft PR，用工程标准审查代码质量
- **跨模型审查**：一个模型写代码，另一个模型审查——不同模型的"盲点"不同，互补效果好

### 1.6 大模型选择对代码质量的影响

根据 [BenchLM 2026 年编码排行榜](https://benchlm.ai/blog/posts/best-llm-for-coding)、[NxCode 的决策指南](https://www.nxcode.io/resources/news/claude-opus-or-sonnet-for-coding-decision-guide-2026)、[Ian Paterson 的 38 任务测试](https://ianlpaterson.com/blog/llm-benchmark-2026-38-actual-tasks-15-models-for-2-29/) 和 [BetterStack 的 Qwen vs Claude 对比](https://betterstack.com/community/guides/ai/qwen-3-5-vs-claude-sonnet-4-5/)：

**2026 年主流编码模型排名（BenchLM Coding Score）：**

| 排名 | 模型 | Coding Score | SWE-Rebench | 说明 |
|------|------|-------------|-------------|------|
| 1 | GPT-5.4 Pro | 88.3 | — | 推理型，最强综合 |
| 2 | **Claude Opus 4.6** | 79.3 | 65.3 | 非推理型，架构理解最佳 |
| 3 | Gemini 3.1 Pro | 77.8 | 62.3 | 非推理型 |
| 8 | **Claude Sonnet 4.6** | 74.2 | 60.7 | 非推理型，性价比之王 |

**关键发现——Sonnet vs Opus 的选择策略**（来源：[NxCode](https://www.nxcode.io/resources/news/claude-opus-or-sonnet-for-coding-decision-guide-2026)）：

> "80/20 法则：80% 的编码任务用 Sonnet 即可，只有 20% 需要 Opus"

- **SWE-bench Verified 差距仅 1.2%**（Opus 80.8% vs Sonnet 79.6%）
- **Opus 价格是 Sonnet 的 5 倍**（$15/$75 vs $3/$15 per 1M tokens）
- **Opus 在跨文件协调时优势明显**：迁移 15+ 文件的状态管理、复杂权衡的架构决策
- **Sonnet 在日常任务上表现等同**：Bug 修复、功能添加、测试编写、代码审查

**Qwen 与 Claude 的实际对比**（来源：[BetterStack](https://betterstack.com/community/guides/ai/qwen-3-5-vs-claude-sonnet-4-5/)）：
- Qwen 3.5（35B 参数 MoE，仅激活 3B）在 benchmark 上声称接近 Sonnet 4.5
- **但在实际编码测试中，Claude Sonnet 4.5 以 3:0 完胜 Qwen 3.5**
- Qwen 在调试现有代码库方面差距最大——无法有效理解和修改复杂代码

---

## 二、针对万德平台的具体改进建议

### 2.1 根因分析：为什么现有 CI E2E 没有捕获这些问题

万德平台最近发现的四个问题：

| 问题 | 根因 | 现有防线为何失效 |
|------|------|-----------------|
| Drawer 用了废弃的 `:visible`（应为 `:open`） | AI 模型训练数据包含旧版 Ant Design 代码模式 | E2E 测试只测功能，不检查 API 使用正确性 |
| Drawer 套 Drawer 冲突结构 | AI 缺乏 UI/UX 最佳实践约束 | 没有组件结构审查规则 |
| 前端路由注册但后端菜单表未配置 | AI 不了解前后端联动的数据流 | E2E 没有"从菜单进入"的完整用户路径测试 |
| 跳转不存在的静态页面 | AI 幻觉了页面路径 | 没有链接可达性检查 |

### 2.2 分层防御体系（可直接落地）

#### 第一层：静态分析（100%确定性，0延迟）

**2.2.1 ESLint 自定义规则——禁止废弃 API**

```javascript
// eslint-rules/no-deprecated-antdv-props.js
module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: '禁止使用 Ant Design Vue 4.x 已废弃的属性',
    },
    fixable: 'code',
    messages: {
      deprecated: '{{ oldProp }} 已在 Ant Design Vue 4.x 废弃，请使用 {{ newProp }}'
    }
  },
  create(context) {
    // 废弃属性映射表
    const DEPRECATED_PROPS = {
      'a-drawer': { 'visible': 'open' },
      'a-modal': { 'visible': 'open' },
      'a-dropdown': { 'visible': 'open' },
      'a-tooltip': { 'visible': 'open' },
      'a-popover': { 'visible': 'open' },
      'a-popconfirm': { 'visible': 'open' },
      // ... 其他废弃属性
    };
    
    return {
      VAttribute(node) {
        const component = node.parent?.name?.toLowerCase();
        const propName = node.key?.argument?.name;
        if (DEPRECATED_PROPS[component]?.[propName]) {
          context.report({
            node,
            messageId: 'deprecated',
            data: {
              oldProp: propName,
              newProp: DEPRECATED_PROPS[component][propName]
            },
            fix(fixer) {
              return fixer.replaceText(
                node.key.argument,
                DEPRECATED_PROPS[component][propName]
              );
            }
          });
        }
      }
    };
  }
};
```

**2.2.2 组件结构检查规则——禁止嵌套 Drawer/Modal**

```javascript
// eslint-rules/no-nested-overlay.js
module.exports = {
  create(context) {
    const OVERLAY_COMPONENTS = ['a-drawer', 'a-modal', 'a-dialog'];
    const stack = [];
    
    return {
      VElement(node) {
        const tag = node.name?.toLowerCase();
        if (OVERLAY_COMPONENTS.includes(tag)) {
          if (stack.length > 0) {
            context.report({
              node,
              message: `禁止嵌套 ${tag}，当前已在 ${stack[stack.length-1]} 内部。请使用独立组件 + 事件通信。`
            });
          }
          stack.push(tag);
        }
      },
      'VElement:exit'(node) {
        const tag = node.name?.toLowerCase();
        if (OVERLAY_COMPONENTS.includes(tag)) {
          stack.pop();
        }
      }
    };
  }
};
```

**2.2.3 路由完整性检查脚本**

```bash
#!/bin/bash
# scripts/check-route-integrity.sh
# 检查前端路由是否都有对应的后端菜单配置

echo "=== 路由完整性检查 ==="

# 提取前端路由路径
FRONTEND_ROUTES=$(grep -rPoh "path:\s*['\"]([^'\"]+)['\"]" frontend/src/router/ | \
  grep -oP "(?<=path:\s['\"])[^'\"]+")

# 提取后端菜单表路径（从 SQL 或配置文件）
BACKEND_MENUS=$(grep -rPoh "path['\"]?\s*[:=]\s*['\"]([^'\"]+)['\"]" \
  backend/src/main/resources/sql/ | grep -oP "(?<=path['\"]?\s*[:=]\s*['\"])[^'\"]+")

# 对比找出缺失
MISSING=0
for route in $FRONTEND_ROUTES; do
  if ! echo "$BACKEND_MENUS" | grep -q "$route"; then
    echo "WARNING: 前端路由 '$route' 未在后端菜单表中找到"
    MISSING=$((MISSING + 1))
  fi
done

if [ $MISSING -gt 0 ]; then
  echo "发现 $MISSING 个路由缺少后端菜单配置"
  exit 1
fi

echo "所有前端路由均有后端菜单配置 ✓"
```

**2.2.4 死链检查——CI 中自动检测**

```yaml
# .github/workflows/link-check.yml
- name: 检查前端死链
  run: |
    # 提取所有路由跳转目标
    grep -rPoh "router\.push\(['\"]([^'\"]+)['\"]\)" frontend/src/ | \
      grep -oP "(?<=push\(['\"])[^'\"]+(?=['\"])" | sort -u > /tmp/jump_targets.txt
    
    # 提取所有已注册路由
    grep -rPoh "path:\s*['\"]([^'\"]+)['\"]" frontend/src/router/ | \
      grep -oP "(?<=path:\s['\"])[^'\"]+(?=['\"])" | sort -u > /tmp/registered_routes.txt
    
    # 检查静态资源引用
    grep -rPoh "href=['\"]([^'\"]+\.html)['\"]" frontend/src/ | \
      grep -oP "(?<=href=['\"])[^'\"]+(?=['\"])" | while read -r page; do
        if [ ! -f "frontend/public/$page" ]; then
          echo "ERROR: 引用了不存在的静态页面: $page"
          exit 1
        fi
      done
```

#### 第二层：AI Review Hook（Claude Code Hooks）

在 `.claude/settings.json` 中配置 hooks：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "npx eslint --rule 'no-deprecated-antdv-props: error' --rule 'no-nested-overlay: error' ${file}"
      }
    ],
    "PreCommit": [
      {
        "command": "bash scripts/check-route-integrity.sh"
      }
    ]
  }
}
```

#### 第三层：视觉回归测试（CI 中）

```typescript
// e2e/visual/drawer-component.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Drawer 组件视觉回归', () => {
  test('抽屉打开后渲染正确', async ({ page }) => {
    await page.goto('/your-page-with-drawer');
    await page.click('[data-testid="open-drawer-btn"]');
    await page.waitForSelector('.ant-drawer-open');
    
    // Mask 动态内容
    await expect(page).toHaveScreenshot('drawer-open.png', {
      mask: [
        page.locator('.timestamp'),
        page.locator('.user-avatar'),
      ],
      maxDiffPixelRatio: 0.01,
    });
  });

  test('新页面不应有控制台废弃警告', async ({ page }) => {
    const warnings: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'warning' && msg.text().includes('deprecated')) {
        warnings.push(msg.text());
      }
    });

    await page.goto('/your-new-page');
    expect(warnings).toHaveLength(0);
  });
});
```

#### 第四层：CI/CD 质量门控工作流

```yaml
# .github/workflows/quality-gate.yml
name: AI Code Quality Gate

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  # 第一步：静态分析
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - name: ESLint 检查（含废弃 API 规则）
        run: npx eslint frontend/src/ --rule 'no-deprecated-antdv-props: error'
      - name: TypeScript 类型检查
        run: npx tsc --noEmit
      - name: 路由完整性检查
        run: bash scripts/check-route-integrity.sh
      - name: 死链检查
        run: bash scripts/check-dead-links.sh

  # 第二步：AI Review
  ai-review:
    runs-on: ubuntu-latest
    needs: static-analysis
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - name: Claude Code PR Review
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            /review
            重点检查：
            1. 是否使用了 Ant Design Vue 4.x 已废弃的 API
            2. 是否存在嵌套的 Drawer/Modal 结构
            3. 新增路由是否有完整的前后端配置
            4. 跳转目标页面/路由是否存在
            5. VxeGrid 的 API 使用是否与当前版本兼容
          claude_args: "--max-turns 5"

  # 第三步：E2E + 视觉回归
  e2e-visual:
    runs-on: ubuntu-latest
    needs: static-analysis
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - name: 启动应用
        run: |
          npm run build
          npm run start &
          npx wait-on http://localhost:3000
      - name: E2E 功能测试
        run: npx playwright test e2e/functional/
      - name: 视觉回归测试
        run: npx playwright test e2e/visual/
      - name: 控制台废弃警告检查
        run: npx playwright test e2e/deprecation-check/
      - name: 上传测试结果
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: visual-test-results
          path: test-results/
```

### 2.3 Issue 模板改进（嵌入约束）

```markdown
<!-- .github/ISSUE_TEMPLATE/feature-request.yml -->
name: 功能需求
description: 提交新功能需求（AI 将自动拾取此 Issue）
body:
  - type: textarea
    id: description
    attributes:
      label: 功能描述
      description: 清晰描述需要实现什么
    validations:
      required: true
  
  - type: textarea
    id: acceptance-criteria
    attributes:
      label: 验收标准
      description: 明确列出验收条件
      value: |
        - [ ] 功能按描述正常工作
        - [ ] 所有新增路由已在后端菜单表中配置
        - [ ] 未使用任何 Ant Design Vue 已废弃 API
        - [ ] 未引入嵌套 Drawer/Modal 结构
        - [ ] 所有页面跳转目标可达
        - [ ] E2E 测试覆盖核心交互路径
        - [ ] 无控制台警告或错误
    validations:
      required: true

  - type: textarea
    id: technical-constraints
    attributes:
      label: 技术约束
      description: AI 必须遵守的技术限制
      value: |
        ## 组件库版本约束
        - Ant Design Vue 4.x：Drawer/Modal 使用 `open` 而非 `visible`
        - VxeGrid：参考 /docs/vxe-grid-api.md
        - Vben Admin：参考 /docs/vben-conventions.md
        
        ## 架构约束
        - 新页面必须注册路由 AND 配置后端菜单
        - 不允许嵌套 Drawer/Modal，使用独立组件 + 事件
        - 静态页面引用前确认文件存在
    validations:
      required: true
  
  - type: textarea
    id: related-files
    attributes:
      label: 相关文件
      description: 需要修改或参考的文件
      placeholder: |
        - frontend/src/views/xxx/ （新页面位置）
        - backend/src/main/java/xxx/menu/ （菜单配置）
        - e2e/xxx.spec.ts （测试文件）
```

---

## 三、Harness/CLAUDE.md 改进建议

### 3.1 推荐的 CLAUDE.md 文件（可直接写入项目根目录）

```markdown
# 万德AI平台 - Claude Code 约束

## 项目概览
Vue3 + Ant Design Vue 4.x + Vben Admin + VxeGrid 前端 / Spring Boot + RuoYi 后端
Monorepo: backend/ + frontend/ + e2e/ + pipeline/

## 关键命令
- 前端开发: `cd frontend && pnpm dev`
- 后端开发: `cd backend && mvn spring-boot:run`
- 类型检查: `cd frontend && pnpm typecheck`
- Lint: `cd frontend && pnpm lint`
- 单个 E2E: `cd e2e && npx playwright test <file> --headed`
- 全量 E2E: `cd e2e && npx playwright test`

## IMPORTANT: 绝对禁止（违反将导致 CI 失败）
- **YOU MUST NOT** 使用 `visible` 属性在 Drawer/Modal/Dropdown/Tooltip/Popover 上——Ant Design Vue 4.x 已废弃，使用 `open`
- **YOU MUST NOT** 嵌套 Drawer 或 Modal——使用独立组件 + 事件通信
- **YOU MUST NOT** 添加前端路由而不配置后端菜单表——每个路由必须同时在 `sys_menu` 表和前端路由文件中注册
- **YOU MUST NOT** 引用不存在的静态页面——在 router.push/href 之前确认目标存在
- **YOU MUST NOT** 使用 `any` 类型——所有变量和函数必须有明确类型

## 工作流程
1. 阅读 Issue 的技术约束部分
2. 先写 E2E 测试（TDD），运行确认失败
3. 实现代码
4. 运行测试确认通过
5. 运行 `pnpm lint && pnpm typecheck` 确认无错误
6. 验证无控制台 deprecated 警告

## 领域知识（按需阅读）
- Ant Design Vue 4.x API 约束: @docs/antdv-constraints.md
- VxeGrid 使用规范: @docs/vxe-grid-api.md
- Vben Admin 约定: @docs/vben-conventions.md
- 后端菜单配置指南: @docs/menu-config-guide.md
- E2E 测试编写指南: @docs/e2e-testing-guide.md

## Git 规范
- 分支命名: feat/issue-{number}-{short-desc}
- Commit 格式: feat(scope): description #issue-number
- PR 描述必须包含截图（如涉及 UI 变更）
```

### 3.2 渐进式披露文件（建议创建）

**`docs/antdv-constraints.md`**：

```markdown
# Ant Design Vue 4.x 约束清单

## 废弃属性映射（MUST 遵守）

| 组件 | 废弃属性 | 正确属性 | 版本 |
|------|----------|----------|------|
| Drawer | visible | open | 4.0+ |
| Modal | visible | open | 4.0+ |
| Dropdown | visible | open | 4.0+ |
| Tooltip | visible | open | 4.0+ |
| Popover | visible | open | 4.0+ |
| Popconfirm | visible | open | 4.0+ |
| Tag | closable | closable（保持但事件改为 onClose） | 4.0+ |

## 组件使用约束

### Drawer
- 使用 `open` 控制显示，不用 `visible`
- 关闭回调使用 `@close`，不用 `@afterVisibleChange`
- 禁止 Drawer 嵌套 Drawer，使用事件通信：
  ```vue
  <!-- ✅ 正确：独立 Drawer 组件 -->
  <DetailDrawer :open="showDetail" @close="showDetail = false" />
  <EditDrawer :open="showEdit" @close="showEdit = false" />
  
  <!-- ❌ 错误：嵌套 Drawer -->
  <a-drawer :open="show">
    <a-drawer :open="showInner">...</a-drawer>
  </a-drawer>
  ```

### 验证方式
运行 `pnpm lint` 会自动检查这些规则。如果控制台出现 `[antd: xxx] yyy is deprecated` 警告，说明使用了废弃 API。
```

**`docs/menu-config-guide.md`**：

```markdown
# 前后端菜单配置指南

## 添加新页面的完整流程

### 1. 前端路由（必须）
文件：`frontend/src/router/modules/xxx.ts`
```ts
{
  path: '/new-page',
  name: 'NewPage',
  component: () => import('@/views/new-page/index.vue'),
  meta: { title: '新页面', icon: 'xxx' }
}
```

### 2. 后端菜单表（必须）
文件：`backend/sql/menu.sql` 或通过 RuoYi 后台管理
```sql
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon)
VALUES ('新页面', {parent_id}, 1, 'new-page', 'xxx/new-page/index', 'C', '0', '0', 'xxx:newPage:list', 'xxx');
```

### 3. 验证清单
- [ ] 前端路由文件中已注册
- [ ] 后端 sys_menu 表中已插入
- [ ] 从侧边栏菜单点击可以正常进入
- [ ] 权限配置正确（perms 字段）
```

### 3.3 Claude Code Hooks 配置

```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run typecheck)",
      "Bash(npx playwright test *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(gh pr create *)",
      "Bash(gh issue view *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(npm publish *)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "cd frontend && npx eslint --no-error-on-unmatched-pattern --rule 'no-deprecated-antdv-props: error' ${file} 2>/dev/null || true"
      }
    ],
    "PreCommit": [
      {
        "command": "cd frontend && pnpm lint && pnpm typecheck"
      },
      {
        "command": "bash scripts/check-route-integrity.sh"
      }
    ]
  }
}
```

### 3.4 配置子代理用于安全审查

```markdown
<!-- .claude/agents/ui-reviewer.md -->
---
name: ui-reviewer
description: 审查 UI 代码的组件使用和结构正确性
tools: Read, Grep, Glob, Bash
model: sonnet
---
你是 Ant Design Vue 4.x 和 Vben Admin 的专家审查员。审查代码时重点检查：

1. **废弃 API 使用**：Drawer/Modal/Dropdown 等是否用了 `visible`（应为 `open`）
2. **组件嵌套**：是否存在 Drawer 嵌套 Drawer 或 Modal 嵌套 Modal
3. **路由完整性**：新增路由是否同时配置了后端菜单
4. **链接可达性**：router.push 和 href 的目标是否存在
5. **VxeGrid API**：是否使用了正确版本的 VxeGrid API

对每个问题提供具体的文件行号和修复建议。
```

---

## 四、大模型选择建议

### 4.1 任务-模型匹配矩阵

基于 [NxCode 的决策指南](https://www.nxcode.io/resources/news/claude-opus-or-sonnet-for-coding-decision-guide-2026)、[BenchLM 排行榜](https://benchlm.ai/blog/posts/best-llm-for-coding) 和 [Helicone 的 Claude 4 评测](https://www.helicone.ai/blog/claude-opus-and-sonnet-4-full-developer-guide)：

| 任务类型 | 推荐模型 | 理由 |
|----------|----------|------|
| **日常 Bug 修复** | Claude Sonnet 4.6 | 质量等同 Opus，成本仅 1/5 |
| **单文件功能开发** | Claude Sonnet 4.6 | 性价比最优 |
| **E2E 测试编写** | Claude Sonnet 4.6 | 测试生成是 Sonnet 最强领域之一 |
| **跨文件重构（5+文件）** | Claude Opus 4.6 | 跨文件依赖追踪更准确 |
| **架构设计决策** | Claude Opus 4.6 | 更深层次的权衡推理 |
| **PR 代码审查** | Claude Sonnet 4.6 | 审查任务不需要 Opus 的深度推理 |
| **紧急补丁/hotfix** | Claude Sonnet 4.6 | 更快响应，质量足够 |
| **前端 UI 组件开发** | Claude Sonnet 4.6 或 Opus 4.6 | Claude 系列在 UI 美学上一致优于竞品 |

### 4.2 关于 Token Pool Proxy 多模型切换的建议

**核心风险：模型能力差异导致质量波动**

根据 [BetterStack 的实际对比](https://betterstack.com/community/guides/ai/qwen-3-5-vs-claude-sonnet-4-5/)，Qwen 3.5 在实际编码中 **远不如 Claude Sonnet 4.5**，尤其在调试和修改现有代码方面差距最大。

**具体建议：**

1. **分级路由策略（必须实施）**：
   ```
   高复杂度任务（新功能、架构变更）→ 仅 Claude Sonnet/Opus
   中等复杂度（Bug 修复、小功能）→ Claude Sonnet 优先，Claude 不可用时降级到 Qwen 122B
   低复杂度（文档更新、注释添加）→ 任意可用模型
   ```

2. **为不同模型设置不同的 CLAUDE.md/约束文件**：
   - 给 Qwen 122B 提供更详细的约束（因为小模型的指令遵循能力更差）
   - 给 Claude 提供精简版约束（大模型能从代码上下文推断更多信息）

3. **质量一致性保障**：
   - 无论用哪个模型生成代码，**都必须通过相同的 CI 质量门控**
   - 对 Qwen 生成的代码增加额外的 Claude PR Review 步骤
   - 在 PR 标签中记录使用的模型，用于后续质量追踪

4. **前端 UI 开发禁止使用弱模型**：
   - [Helicone 的评测](https://www.helicone.ai/blog/claude-opus-and-sonnet-4-full-developer-guide) 显示 Claude 在 UI 美学方面一致优于竞品
   - Qwen 系列在组件库 API 的版本记忆上更不可靠
   - **建议**：前端 Vue/Ant Design Vue 相关任务强制路由到 Claude

### 4.3 模型选择的量化框架

建议在 PR 中记录并追踪以下指标：

```yaml
# 在 PR 描述中自动添加
model_used: claude-sonnet-4.6
task_complexity: medium  # low/medium/high
first_pass_success: true  # CI 是否一次通过
review_iterations: 1      # 需要几轮修改
deprecated_api_found: 0   # 发现的废弃 API 数量
```

每月汇总分析：哪些模型的 first_pass_success 率更高？哪些任务类型需要更多迭代？

---

## 五、被忽视的风险和前沿实践

### 5.1 被忽视的系统性风险

#### 风险一：迭代 AI 修复反而放大漏洞

根据 [Cranium AI 引用的研究](https://cranium.ai/resources/blog/part-one-when-ai-writes-the-code-who-fixes-the-bugs-why-agentic-remediation-is-the-new-control-layer/)，旧金山大学 2025 年的研究发现：**经过 5 轮 AI 迭代修复后，关键漏洞增加了 37%**。这意味着让 AI 反复修改自己的代码可能越改越差。

**对万德平台的影响**：如果 CI 失败后让 AI 自动重试修复，需要设置**最大重试次数**（建议不超过 3 次），超过后必须升级为人工处理。

#### 风险二：级联失败模式

根据 [arXiv 的自主代理安全调查](https://arxiv.org/html/2506.23844v1)，AI Agent 的错误具有**级联传播**特性：早期子任务中的推理错误会传播到后续步骤，在运行时难以检测。一个错误的依赖分析可能导致不兼容的重写，然后被提交并部署。

**对万德平台的影响**：在自动 merge 流程中，**单一 CI 管道不足以捕获级联错误**。需要增加：
- 增量式验证：每完成一个子任务就验证一次
- 回滚能力：自动部署必须配合自动回滚

#### 风险三：审查疲劳导致质量退化

根据 [Ranger 的研究](https://www.ranger.net/post/common-bugs-ai-generated-code-fixes)，AI 生成的 PR 包含的问题是人工的 1.7 倍，这导致"审查员疲劳"——大量 AI 引入的小问题可能让人审查时遗漏更严重的缺陷。

**对万德平台的影响**：当 auto merge 流程让人只需"偶尔看看"时，真正需要人类判断的架构问题更容易被忽略。

#### 风险四：AI Agent 错误权限配置

根据 [LeadDev 的 2026 安全风险分析](https://leaddev.com/ai/ai-assisted-coding-and-unsanctioned-tools-headline-2026s-biggest-security-risks)，一个配置错误的 AI "可能最终成为跨多个系统的超级管理员"。如果它失败或被攻击，攻击者会继承它接触到的一切访问权限。

**对万德平台的影响**：Claude Code 的权限需要最小化，特别是：
- 禁止 `sudo` 和 `rm -rf` 等危险命令
- 限制只能写入特定目录
- 数据库操作只允许通过 migration 文件

### 5.2 大多数团队还没想到的创新实践

#### 实践一：控制台废弃警告作为 CI 门控

大多数 E2E 测试只检查功能是否正常，**完全忽略浏览器控制台的警告信息**。万德平台的 `:visible` 废弃问题本可以在运行时被控制台警告 `[antd: Drawer] visible is deprecated` 捕获。

**建议实现**：

```typescript
// e2e/helpers/console-monitor.ts
import { Page } from '@playwright/test';

export function setupConsoleMonitor(page: Page) {
  const issues: { type: string; text: string; url: string }[] = [];

  page.on('console', msg => {
    const text = msg.text();
    if (
      text.includes('deprecated') ||
      text.includes('is not a function') ||
      text.includes('Cannot read properties of') ||
      text.includes('[Vue warn]')
    ) {
      issues.push({
        type: msg.type(),
        text: text,
        url: page.url()
      });
    }
  });

  return {
    getIssues: () => issues,
    assertNoIssues: () => {
      if (issues.length > 0) {
        throw new Error(
          `发现 ${issues.length} 个控制台问题:\n` +
          issues.map(i => `  [${i.type}] ${i.text} (at ${i.url})`).join('\n')
        );
      }
    }
  };
}
```

#### 实践二：API 版本合规性快照测试

类似视觉回归测试的理念，但用于 API 使用合规性：

```typescript
// e2e/api-compliance.spec.ts
test('所有组件使用的 Ant Design Vue API 与 4.x 兼容', async ({ page }) => {
  // 遍历所有页面路由
  const routes = ['/dashboard', '/user/list', '/order/detail', /* ... */];
  
  for (const route of routes) {
    await page.goto(route);
    
    // 检查是否有废弃 API 的 console warning
    const warnings = await page.evaluate(() => {
      return (window as any).__antd_deprecation_warnings || [];
    });
    
    expect(warnings, `页面 ${route} 使用了废弃 API`).toHaveLength(0);
  }
});
```

#### 实践三：Spec-driven AI 开发

参考 [GitHub 的 Spec Kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)，将 Issue 升级为可执行规格说明：

```markdown
## Spec: 用户详情页 Drawer 重构

### 目标状态
- 用户列表点击"查看" → 打开 DetailDrawer（使用 `open` 属性）
- DetailDrawer 中点击"编辑" → 关闭 DetailDrawer → 打开 EditDrawer
- 不允许同时显示两个 Drawer

### 约束
- 组件文件：frontend/src/views/user/components/DetailDrawer.vue
- 使用 `open` 属性而非 `visible`
- Drawer 之间通过 emit 事件通信，不嵌套

### 验收测试
```typescript
test('用户详情 Drawer 交互流程', async ({ page }) => {
  await page.goto('/user/list');
  await page.click('[data-testid="view-user-1"]');
  await expect(page.locator('.detail-drawer')).toBeVisible();
  
  await page.click('[data-testid="edit-user"]');
  await expect(page.locator('.detail-drawer')).not.toBeVisible();
  await expect(page.locator('.edit-drawer')).toBeVisible();
});
```
```

#### 实践四：多模型"陪审团"审查

根据 [Reddit 社区实践](https://www.reddit.com/r/vibecoding/comments/1r4i8sf/my_workflow_two_ai_coding_agents_crossreviewing/)，使用不同模型交叉审查可以发现单一模型的盲点：

```yaml
# .github/workflows/multi-model-review.yml
jobs:
  claude-review:
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          prompt: "/review 重点检查架构设计和组件库API使用"
  
  secondary-review:
    needs: claude-review
    steps:
      - name: 将 Claude 的审查结果交给另一个模型复核
        run: |
          CLAUDE_REVIEW=$(gh pr view $PR_NUMBER --json body -q .body)
          echo "$CLAUDE_REVIEW" | claude -p "复核以上审查意见，是否有遗漏或误判？"
```

#### 实践五：渐进式自动化信任等级

不要一步到位实现全自动 merge，而是建立信任等级：

| 信任等级 | 条件 | 自动化程度 |
|----------|------|-----------|
| Level 0 | 任何 PR | AI 写代码 + 人工审查 + 人工 merge |
| Level 1 | 仅修改测试/文档 | AI 写代码 + AI 审查 + 人工一键 merge |
| Level 2 | 变更 < 50 行 + 所有 CI 通过 | AI 写代码 + AI 审查 + 自动 merge（延迟 1 小时） |
| Level 3 | Level 2 + 该类任务连续 20 次成功 | 即时自动 merge |

### 5.3 全自动开发流水线的安全边界

基于 [LinkedIn 的 CI/CD Agent 安全分析](https://www.linkedin.com/posts/thenextgentechinsider_thoughtworks-cicd-headlesscli-activity-7441567567544139776-OZKG) 和 [Skywork 的 Claude Agent SDK 实践](https://skywork.ai/blog/claude-agent-sdk-best-practices-ai-agents-2025/)：

**可以安全自动化的：**
- 从 Issue 生成代码 + 测试
- 运行 lint + typecheck + E2E
- 生成 PR + 填写描述
- 简单的文档/测试更新自动 merge

**必须保留人工审查的：**
- 数据库 schema 变更
- 涉及认证/授权的代码
- 新增外部依赖
- 修改 CI/CD 配置本身
- 跨模块架构变更
- 涉及用户数据的处理逻辑

**安全边界建议：**
- **最大无人值守时间：20 分钟**——超过此时间未完成的任务应暂停等待人工介入
- **最大自动重试：3 次**——防止 AI 迭代放大问题
- **所有 Agent 操作全量日志**——包括工具调用的输入输出、时间戳、使用的模型
- **数据库操作只能通过 migration 文件**——禁止 Agent 直接执行 SQL
- **部署后监控窗口：1 小时**——自动 merge 后如果监控异常自动回滚

---

## 附录：实施优先级路线图

| 优先级 | 措施 | 预计工时 | 预期效果 |
|--------|------|----------|----------|
| **P0（立即）** | 添加废弃 API ESLint 规则 | 2h | 100% 阻止 `:visible` 类问题 |
| **P0（立即）** | 更新 CLAUDE.md 为精简版 | 1h | 提升 AI 指令遵循率 |
| **P0（立即）** | 创建 `docs/antdv-constraints.md` | 1h | 渐进式披露关键约束 |
| **P1（本周）** | 添加控制台废弃警告 CI 检查 | 4h | 捕获运行时废弃 API |
| **P1（本周）** | 添加路由完整性检查脚本 | 3h | 防止前后端路由不一致 |
| **P1（本周）** | 配置 Claude Code Hooks | 2h | 每次编辑自动 lint |
| **P2（本月）** | 集成 Playwright 视觉回归测试 | 8h | 捕获 UI 布局问题 |
| **P2（本月）** | 设置 Claude PR Review Action | 4h | AI 审查 AI 生成的代码 |
| **P2（本月）** | 改进 Issue 模板嵌入约束 | 2h | 从源头约束 AI 行为 |
| **P3（下月）** | Token Pool Proxy 分级路由 | 8h | 不同任务用不同模型 |
| **P3（下月）** | 多模型交叉审查流程 | 4h | 发现单模型盲点 |
| **P3（下月）** | 渐进式信任等级系统 | 8h | 安全地扩展自动化范围 |

---

## 参考来源

1. [Anthropic - Claude Code Best Practices](https://docs.anthropic.com/en/docs/claude-code/best-practices)
2. [HumanLayer - Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
3. [SFEIR Institute - Claude Code Best Practices](https://institute.sfeir.com/en/claude-code/claude-code-resources/best-practices/)
4. [Kirill Markin - Cursor IDE Rules for AI](https://kirill-markin.com/articles/cursor-ide-rules-for-ai/)
5. [Startupbricks - Cursor Rules Setup Guide](https://www.startupbricks.in/blog/cursor-rules-why-needed-setup-guide)
6. [Trigger.dev - How to Write Great Cursor Rules](https://trigger.dev/blog/cursor-rules)
7. [BenchLM - Best LLM for Coding 2026](https://benchlm.ai/blog/posts/best-llm-for-coding)
8. [NxCode - Claude Opus or Sonnet Decision Guide 2026](https://www.nxcode.io/resources/news/claude-opus-or-sonnet-for-coding-decision-guide-2026)
9. [BetterStack - Qwen 3.5 vs Claude Sonnet 4.5](https://betterstack.com/community/guides/ai/qwen-3-5-vs-claude-sonnet-4-5/)
10. [Ian Paterson - LLM Benchmark 2026](https://ianlpaterson.com/blog/llm-benchmark-2026-38-actual-tasks-15-models-for-2-29/)
11. [Helicone - Claude Opus 4 and Sonnet 4 Review](https://www.helicone.ai/blog/claude-opus-and-sonnet-4-full-developer-guide)
12. [OneUptime - Visual Regression Testing Guide](https://oneuptime.com/blog/post/2026-01-30-visual-regression-testing/view)
13. [Bug0 - Percy Visual Regression Testing](https://bug0.com/knowledge-base/percy-visual-regression-testing)
14. [Ranger - Common Bugs in AI-Generated Code](https://www.ranger.net/post/common-bugs-ai-generated-code-fixes)
15. [ZenVanRiel - Why AI Generates Outdated Code](https://zenvanriel.com/ai-engineer-blog/why-does-ai-generate-outdated-code-explained/)
16. [GitHub Blog - Spec-driven Development with AI](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
17. [Test Double - Double Loop Model for Agentic Coding](https://testdouble.com/insights/pragmatic-approaches-to-agentic-coding-for-engineering-leaders)
18. [Skywork - Claude Agent SDK Best Practices](https://skywork.ai/blog/claude-agent-sdk-best-practices-ai-agents-2025/)
19. [Skywork - Claude Code CI/CD Integration Guide](https://skywork.ai/blog/how-to-integrate-claude-code-ci-cd-guide-2025/)
20. [Cranium AI - AI Code Risks](https://cranium.ai/resources/blog/part-one-when-ai-writes-the-code-who-fixes-the-bugs-why-agentic-remediation-is-the-new-control-layer/)
21. [arXiv - Autonomy-Induced Security Risks in Large Model Agents](https://arxiv.org/html/2506.23844v1)
22. [LeadDev - 2026 Biggest Security Risks](https://leaddev.com/ai/ai-assisted-coding-and-unsanctioned-tools-headline-2026s-biggest-security-risks)
23. [Baytech Consulting - Enterprise Coding AI Milestone 2025](https://www.baytechconsulting.com/blog/enterprise-coding-ai-milestone-2025)
24. [Bright Security - Reviewing AI-Generated Code](https://brightsec.com/blog/5-best-practices-for-reviewing-and-approving-ai-generated-code/)
25. [Propel - Improve AI Code Review Process](https://www.propelcode.ai/blog/improve-ai-code-review-process-2025)
26. [Cosmic - Claude Sonnet 4.5 vs Opus 4.5 Comparison](https://www.cosmicjs.com/blog/claude-sonnet-45-vs-opus-45-a-real-world-comparison)
27. [GitHub - Ant Design Drawer visible Deprecated](https://github.com/ant-design/ant-design-pro/issues/10447)
28. [Vercel - Claude Code AI Gateway Integration](https://vercel.com/docs/agent-resources/coding-agents/claude-code)
29. [Reddit - Two AI Agents Cross-Reviewing](https://www.reddit.com/r/vibecoding/comments/1r4i8sf/my_workflow_two_ai_coding_agents_crossreviewing/)
30. [Hugging Face Forums - Claude Code Best Practices](https://discuss.huggingface.co/t/10-essential-claude-code-best-practices-you-need-to-know/174731)
