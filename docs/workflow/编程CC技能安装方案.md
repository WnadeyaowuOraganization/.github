# 编程CC技能安装方案

> 基于 Anthropic 官方技能库分析
> 创建日期：2026-04-11
> 适用对象：编程CC（处理Issue的全栈开发）

---

## 一、技能库概览

Anthropic 官方技能库（https://github.com/anthropics/skills.git）包含17个技能：

| 技能名称 | 用途 | 分类 |
|---------|------|------|
| algorithmic-art | 算法艺术创作 | 创意设计 |
| brand-guidelines | 品牌风格应用 | 设计 |
| canvas-design | 视觉艺术创作 | 创意设计 |
| claude-api | Claude API 开发 | 开发工具 |
| doc-coauthoring | 文档协作 | 企业应用 |
| docx | Word 文档操作 | 文档处理 |
| frontend-design | 前端界面设计 | 开发工具 |
| internal-comms | 内部沟通 | 企业应用 |
| mcp-builder | MCP 服务器开发 | 开发工具 |
| pdf | PDF 操作 | 文档处理 |
| pptx | PPT 操作 | 文档处理 |
| skill-creator | 技能创建工具 | 元技能 |
| slack-gif-creator | Slack GIF 创建 | 创意设计 |
| theme-factory | 主题样式应用 | 设计 |
| web-artifacts-builder | Web artifacts 构建 | 开发工具 |
| webapp-testing | Web 应用测试 | 开发工具 |
| xlsx | Excel 操作 | 文档处理 |

---

## 二、推荐安装技能（3个）

### 2.1 webapp-testing ⭐⭐⭐⭐⭐

**优先级**：最高

**为什么编程CC需要**：
- ✅ **前端截图验证**：编程CC需要在PR中提供前端截图作为验收依据
- ✅ **E2E测试**：质量门控要求E2E测试覆盖
- ✅ **UI调试**：诊断前端渲染问题（如#3544的Drawer问题）
- ✅ **Playwright支持**：项目已经在使用Playwright

**实际应用场景**：

**场景1：PR前端截图**
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:8083/wande-project/project')
    page.wait_for_load_state('networkidle')
    page.screenshot(path='screenshot.png', full_page=True)
    browser.close()
```

**场景2：E2E测试**
```python
# 自动化测试用户流程
page.fill('[name="username"]', 'admin')
page.fill('[name="password"]', 'admin123')
page.click('button[type="submit"]')
page.wait_for_url('**/dashboard')
```

**场景3：调试UI问题**
```python
# 诊断Drawer渲染问题
page.goto('http://localhost:8083/project/123')
page.click('button:has-text("详情")')
page.wait_for_selector('.ant-drawer')
drawer = page.locator('.ant-drawer')
print(drawer.evaluate('el => el.innerHTML'))
```

**技能特点**：
- 提供 `scripts/with_server.py` 辅助脚本管理服务器生命周期
- 支持多服务器启动（backend + frontend）
- 提供Reconnaissance-then-Action模式（先截图观察DOM，再执行操作）

---

### 2.2 frontend-design ⭐⭐⭐⭐

**优先级**：高

**为什么编程CC需要**：
- ✅ **高质量UI开发**：帮助创建符合原型的生产级前端界面
- ✅ **避免AI审美疲劳**：生成独特、有设计感的前端代码
- ✅ **Vue组件开发**：支持React/Vue/HTML多种前端框架
- ✅ **设计原则指导**：颜色、字体、动效、布局的最佳实践

**实际应用场景**：

**场景1：开发新页面**
```
用户：使用frontend-design技能，创建一个项目列表页面
要求：
- 使用Vue3 + Vben Admin
- 包含表格、筛选、分页
- 风格：现代、简洁、高效
```

**场景2：优化现有UI**
```
用户：使用frontend-design技能，优化项目矿场的UI
当前问题：表格列太多，信息密度过高
目标：提升可读性，突出关键信息
```

**技能设计理念**：
1. **设计思考**：先理解上下文，选择大胆的美学方向
2. **前端美学准则**：
   - 排版：选择独特、有趣的字体，避免Arial/Inter等通用字体
   - 颜色与主题：使用CSS变量，主导色+锐利点缀
   - 动效：CSS优先，React用Motion库
   - 空间构图：意外的布局、不对称、重叠、对角线流动
   - 背景与视觉细节：创造氛围和深度

**避免的AI审美陷阱**：
- ❌ 过度使用的字体系列（Inter, Roboto, Arial, system fonts）
- ❌ 陈词滥调的配色方案（尤其是白色背景上的紫色渐变）
- ❌ 可预测的布局和组件模式
- ❌ 缺乏上下文特色的千篇一律设计

---

### 2.3 skill-creator ⭐⭐⭐

**优先级**：中

**为什么编程CC需要**：
- ✅ **自定义工作流**：可以创建"质量门控检查"技能
- ✅ **规范自动化**：将shared-conventions.md转化为技能
- ✅ **测试验证**：创建针对特定项目的测试脚本

**潜在应用**：
- 创建"wande-quality-gate"技能（自动检查PR是否符合质量门控）
- 创建"flyway-validator"技能（验证数据库迁移脚本）
- 创建"frontend-screenshot"技能（自动化前端截图流程）

**技能创建流程**：
1. 确定技能用途和触发条件
2. 编写技能初稿（SKILL.md）
3. 创建测试提示词并运行
4. 评估结果（定性+定量）
5. 根据反馈重写技能
6. 扩展测试集并重复

---

## 三、可能有用技能（3个）

### 3.1 pdf ⭐⭐
**用途**：如果设计文档是PDF格式，可以读取和提取内容

### 3.2 pptx ⭐⭐
**用途**：如果原型是PPT格式，可以提取设计信息

### 3.3 docx ⭐⭐
**用途**：如果需求文档是Word格式，可以读取内容

---

## 四、不推荐安装技能（8个）

| 技能 | 不推荐原因 |
|------|-----------|
| algorithmic-art | 艺术创作类，编程CC不需要 |
| canvas-design | 艺术创作类，编程CC不需要 |
| brand-guidelines | 设计风格类，已有Vben Admin规范 |
| theme-factory | 设计风格类，已有Vben Admin规范 |
| internal-comms | 内部沟通类，与开发无关 |
| slack-gif-creator | GIF创建，与开发无关 |
| mcp-builder | MCP服务器开发，除非项目需要 |
| web-artifacts-builder | 复杂HTML artifacts，编程CC用Vue框架 |

---

## 五、安装方案

### 方案A：最小化安装（仅核心技能）

**适用场景**：编程CC资源有限，只需核心测试能力

```bash
# 安装方式（通过Plugin Marketplace）
cd ~/.claude
mkdir -p skills

# 手动复制webapp-testing
git clone --depth 1 https://github.com/anthropics/skills.git /tmp/skills
cp -r /tmp/skills/skills/webapp-testing ~/.claude/skills/
```

**优点**：
- 占用空间小
- 满足核心测试需求
- 学习成本低

**缺点**：
- 缺少UI设计指导
- 无法创建自定义技能

---

### 方案B：推荐安装（核心+设计技能）⭐ 推荐

**适用场景**：编程CC需要完整的开发和测试能力

```bash
# 1. 克隆技能库
git clone --depth 1 https://github.com/anthropics/skills.git /tmp/skills

# 2. 创建技能目录
mkdir -p ~/.claude/skills

# 3. 复制推荐的3个技能
cp -r /tmp/skills/skills/webapp-testing ~/.claude/skills/
cp -r /tmp/skills/skills/frontend-design ~/.claude/skills/
cp -r /tmp/skills/skills/skill-creator ~/.claude/skills/

# 4. 验证安装
ls -la ~/.claude/skills/
```

**优点**：
- 完整的开发测试能力
- 支持自定义技能创建
- UI设计质量提升

**缺点**：
- 占用空间较大
- 需要学习多个技能的使用

---

### 方案C：通过Plugin Marketplace安装 ⭐ 最推荐

**适用场景**：使用Claude Code，支持插件系统

```bash
# 1. 在Claude Code中添加marketplace
/plugin marketplace add anthropics/skills

# 2. 安装example-skills插件包（包含webapp-testing、frontend-design等）
/plugin install example-skills@anthropic-agent-skills

# 3. 安装document-skills插件包（可选，包含pdf/pptx/docx/xlsx）
/plugin install document-skills@anthropic-agent-skills
```

**优点**：
- 自动更新
- 版本管理
- 一键安装
- 官方支持

**缺点**：
- 需要Claude Code最新版本
- 需要网络连接

---

## 六、使用建议

### 6.1 webapp-testing 使用建议

#### 最佳实践

1. **前端截图验证**
```python
# PR创建前的标准流程
from playwright.sync_api import sync_playwright

def capture_frontend_screenshot(url, output_path):
    """捕获前端页面截图"""
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        page.wait_for_load_state('networkidle')
        page.screenshot(path=output_path, full_page=True)
        browser.close()

# 使用示例
capture_frontend_screenshot(
    'http://localhost:8083/wande-project/project',
    'frontend-screenshot.png'
)
```

2. **E2E测试**
```python
# 用户登录流程测试
def test_login_flow():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # 访问登录页
        page.goto('http://localhost:8083/login')

        # 填写表单
        page.fill('[name="username"]', 'admin')
        page.fill('[name="password"]', 'admin123')

        # 提交登录
        page.click('button[type="submit"]')

        # 等待跳转
        page.wait_for_url('**/dashboard')

        # 验证登录成功
        assert page.is_visible('text=欢迎回来')

        browser.close()
```

3. **UI调试**
```python
# 诊断Drawer渲染问题
def debug_drawer_issue():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)  # 非headless模式便于调试
        page = browser.new_page()

        page.goto('http://localhost:8083/project/123')
        page.click('button:has-text("详情")')

        # 等待Drawer出现
        page.wait_for_selector('.ant-drawer', timeout=5000)

        # 检查Drawer内容
        drawer = page.locator('.ant-drawer')
        print("Drawer HTML:", drawer.evaluate('el => el.innerHTML'))

        # 截图保存
        page.screenshot(path='drawer-debug.png')

        browser.close()
```

#### 与项目现有测试的关系

| 项目现有测试 | webapp-testing技能 | 关系 |
|------------|-------------------|------|
| E2E测试框架 | 快速验证工具 | 补充关系，不重复建设 |
| Playwright配置 | Playwright脚本 | 共享配置，技能提供辅助脚本 |
| CI/CD集成 | 本地快速验证 | 技能用于本地，CI用于自动化 |

---

### 6.2 frontend-design 使用建议

#### 框架兼容性调整

编程CC使用的是 **Vben Admin + Vue3**，frontend-design生成的是通用前端代码，需要调整：

**1. 组件导入方式**

frontend-design可能生成：
```vue
<template>
  <Button>Click me</Button>
</template>

<script>
import { Button } from 'ant-design-vue'
</script>
```

调整为Vben Admin规范：
```vue
<template>
  <a-button>Click me</a-button>
</template>

<script setup lang="ts">
// 无需导入，unplugin-vue-components自动导入
</script>
```

**2. 设计Token**

frontend-design可能生成：
```css
:root {
  --primary-color: #1890ff;
  --font-family: 'Inter', sans-serif;
}
```

调整为Vben Admin设计Token：
```css
:root {
  /* 使用Vben Admin的设计token */
  --primary-color: var(--vben-primary-color);
  --font-family: var(--vben-font-family);
}
```

**3. 组件规范**

frontend-design可能生成原生HTML：
```html
<table>
  <tr><td>数据</td></tr>
</table>
```

调整为Vben Admin组件：
```vue
<a-table :dataSource="data" :columns="columns" />
```

#### 设计冲突处理原则

| frontend-design建议 | Vben Admin规范 | 决策 |
|-------------------|--------------|------|
| 使用独特字体 | Vben Admin字体规范 | 以Vben Admin为准 |
| 自定义CSS | Vben Admin设计Token | 使用Token |
| 自定义组件 | Vben Admin组件库 | 使用组件库 |
| 创意布局 | Vben Admin布局规范 | 在规范内创新 |

---

### 6.3 skill-creator 使用建议

#### 创建自定义技能示例

**示例1：wande-quality-gate 技能**

```markdown
---
name: wande-quality-gate
description: 检查PR是否符合万德AI平台的质量门控标准。触发条件：创建PR、PR更新。
---

# 万德AI平台质量门控检查

## 检查清单

### Gate 0: PR基础检查
- [ ] PR base 必须是 dev 分支
- [ ] PR body 包含完整的测试清单
- [ ] 前端变更提供截图

### Gate 1: 代码质量
- [ ] 无console.log残留
- [ ] 无TODO注释（或已创建Issue）
- [ ] TypeScript类型完整

### Gate 2: 测试覆盖
- [ ] 后端单元测试通过
- [ ] E2E测试覆盖关键流程

### Gate 3: 文档完整性
- [ ] API文档更新（如有后端变更）
- [ ] CLAUDE.md更新（如有架构变更）

## 自动化检查脚本

```bash
# 检查PR base
gh pr view $PR_NUM --json baseRefName --jq '.baseRefName'

# 检查前端截图
git diff --name-only | grep -E "\.vue$|\.tsx?$" && echo "需要前端截图"
```
```

**示例2：flyway-validator 技能**

```markdown
---
name: flyway-validator
description: 验证Flyway数据库迁移脚本的正确性。触发条件：创建或修改 db/migration_*/ 下的SQL文件。
---

# Flyway迁移脚本验证器

## 检查规则

### 命名规范
- [ ] 文件名符合 `V<日期>_<序号>__<描述>.sql` 格式
- [ ] 日期格式：YYYYMMDD
- [ ] 序号：_1, _2, _3...

### SQL规范
- [ ] 使用PostgreSQL语法
- [ ] 使用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等
- [ ] 头部注释包含变更说明、日期、关联Issue

### 目录规范
- [ ] 业务表写入 `db/migration_wande_ai/`
- [ ] 菜单表写入 `db/migration_ruoyi_ai/`
- [ ] 不允许跨库JOIN

## 验证脚本

```bash
# 检查文件名格式
find backend -name "V*.sql" -path "*/migration_*" | while read f; do
  basename "$f" | grep -E "^V[0-9]{8}_[0-9]+__.*\.sql$" || echo "命名错误: $f"
done

# 检查幂等性
grep -r "CREATE TABLE" backend/*/migration_*/V*.sql | grep -v "IF NOT EXISTS" && echo "缺少IF NOT EXISTS"
```
```

---

## 七、注意事项

### 7.1 前端框架兼容性

编程CC使用的是 **Vben Admin + Vue3**，需要特别注意：

| frontend-design输出 | Vben Admin要求 | 调整方式 |
|-------------------|--------------|---------|
| 通用Vue3代码 | Vben Admin组件库 | 使用 `<a-*>` 组件 |
| 自定义CSS | Vben Admin设计Token | 使用CSS变量 |
| 原生HTML | Vben Admin封装组件 | 使用 `<a-table>` 等 |
| 通用字体 | Vben Admin字体规范 | 遵循项目规范 |

### 7.2 技能冲突处理

**原则**：
1. 项目规范优先（shared-conventions.md）
2. Vben Admin规范次之
3. 技能建议作为灵感来源

**具体处理**：
- frontend-design生成的代码 → 对照Vben Admin规范调整
- webapp-testing的脚本 → 与项目Playwright配置对齐
- 自定义技能 → 遵循项目工作流

### 7.3 测试基础设施

项目已有完整的测试体系：

| 层级 | 现有设施 | webapp-testing角色 |
|------|---------|-------------------|
| 单元测试 | JUnit + Vitest | 不涉及 |
| E2E测试 | Playwright | 快速验证补充 |
| 前端截图 | 手动截图 | 自动化截图 |
| UI调试 | 手动调试 | 自动化诊断 |

**建议**：webapp-testing作为快速验证工具，不重复建设测试基础设施。

---

## 八、效果预估

安装这三个技能后，编程CC的工作效率提升：

| 技能 | 提升环节 | 预估效果 |
|------|---------|---------|
| webapp-testing | 前端截图+E2E测试 | 节省50%时间，提高覆盖率 |
| frontend-design | UI开发质量 | 减少30%返工，提升设计感 |
| skill-creator | 工作流自动化 | 潜力巨大（取决于自定义技能） |

**总体预期**：
- 前端开发效率提升 40%
- 测试覆盖率提升 20%
- UI设计质量提升 30%
- 工作流自动化程度提升（可扩展）

---

## 九、安装检查清单

安装完成后，请验证：

### 9.1 webapp-testing
- [ ] 技能文件存在：`~/.claude/skills/webapp-testing/SKILL.md`
- [ ] 测试脚本可运行：`python scripts/with_server.py --help`
- [ ] Playwright可用：`python -c "from playwright.sync_api import sync_playwright"`

### 9.2 frontend-design
- [ ] 技能文件存在：`~/.claude/skills/frontend-design/SKILL.md`
- [ ] 可以触发技能：询问Claude "使用frontend-design创建一个页面"

### 9.3 skill-creator
- [ ] 技能文件存在：`~/.claude/skills/skill-creator/SKILL.md`
- [ ] 评估脚本可用：检查 `eval-viewer/` 目录

---

## 十、后续行动

### 10.1 立即行动
1. 安装推荐的3个技能（方案B或方案C）
2. 测试webapp-testing的基本功能
3. 尝试使用frontend-design创建一个简单页面

### 10.2 中期优化
1. 创建"wande-quality-gate"技能（自动化质量门控检查）
2. 创建"frontend-screenshot"技能（自动化前端截图流程）
3. 调整frontend-design输出以适配Vben Admin

### 10.3 长期规划
1. 建立技能评估机制（定期检查技能效果）
2. 创建更多自定义技能（根据项目需求）
3. 与团队分享最佳实践

---

## 十一、参考资料

1. **Anthropic官方技能库**：https://github.com/anthropics/skills
2. **技能文档**：
   - What are skills: https://support.claude.com/en/articles/12512176-what-are-skills
   - Using skills: https://support.claude.com/en/articles/12512180-using-skills-in-claude
   - Creating custom skills: https://support.claude.com/en/articles/12512198-creating-custom-skills
3. **Agent Skills规范**：http://agentskills.io
4. **项目相关文档**：
   - 质量门控：`docs/agent-docs/share/shared-conventions.md`
   - Vben Admin规范：前端代码库CLAUDE.md
   - 测试规范：E2E测试配置文件

---

## 十二、变更历史

| 日期 | 变更内容 |
|------|---------|
| 2026-04-11 | 创建文档，基于官方技能库分析推荐3个技能 |
