# Issue创建SOP — 自动编程需求源

> **版本**: v1.3 | **生效日期**: 2026-03-21
> **适用仓库**: 全部
> **上游**: 吴耀提出需求 → Perplexity分析
> **下游**: Claude Code从各仓库Issue中接任务 → 自动编程执行
> **关联文档**: [WANDE_LABEL.md](./WANDE_LABEL.md) · [仓库导航](./README.md)

---

## 一、SOP定位

```
吴耀提需求 → Perplexity按本SOP创建Issue → Claude Code自动接任务执行
                    ↑                              ↓
              §3.5一站式交付                  §7.9自动编程SOP
```

本SOP是自动编程体系的**需求入口**，规范Issue从需求到创建的全过程。核心目标：让每个Issue都**精准到Claude Code可以直接自主执行**，无需人工二次解释。

---

## 二、仓库路由决策

创建Issue前，必须先根据需求类型确定目标仓库。参照 `.github/docs/README.md` 仓库导航：

| 需求特征 | 目标仓库 | 示例 |
|---------|---------|------|
| API接口 / 数据库 / 后端逻辑 / 定时任务 | `wande-ai-backend` | 新增招标查询接口、修改用户权限逻辑 |
| 管理后台页面 / 运营端功能 / 后台表单 | `wande-ai-front` | 新增供应商管理页面、修改报表筛选 |
| 前后端都涉及的功能 | **分拆为多个Issue**，分别创建在对应仓库 | 新增CRM模块 → backend一个Issue + front一个Issue |
| 爬虫 / 数据采集 / 平台基础设施 | `wande-ai-platform` | 招标爬虫规则调整、wande-infra服务 |
| Grasshopper参数化设计插件 / Rhino插件 | `wande-gh-plugins` | GH插件功能开发、组件新增 |

### 路由原则

1. **单一职责**：一个Issue只在一个仓库中创建
2. **前后端分拆**：涉及前后端的功能，必须拆为独立Issue，通过跨仓库引用建立关联
3. **纯后端优先**：如果不确定是否需要前端改动，先创建后端Issue，后续按需追加前端Issue
4. **不在.github仓库创建业务Issue**：.github仓库仅存放规范文档

---

## 三、标签规范

每个Issue**至少需要3个标签**：1个优先级 + 1个类型 + 1个状态标签。

完整标签体系参照 [WANDE_LABEL.md](./WANDE_LABEL.md)，以下为创建时的最常用组合：

### 必选标签

| 维度 | 创建时常用 | 说明 |
|------|----------|------|
| 优先级 | `priority/P0` `priority/P1` `priority/P2` | P0=阻塞生产，P1=Sprint必做，P2=增强改进 |
| 类型 | `type:feature` `type:bugfix` `type:enhancement` | 决定Claude Code的开发策略和测试要求 |
| 状态 | `status:ready` | 创建时如果需求已明确，直接标记ready让Claude Code接任务 |

### 可选标签（按需添加）

| 维度 | 常用标签 | 场景 |
|------|---------|------|
| 来源 | `source:perplexity` `source:human` | 追踪Issue来源 |
| 审批 | `approval:auto` `approval:required` | 控制PR合并策略 |
| 模块 | `module:bid` `module:crm` `module:chat` 等 | 标识业务模块 |
| 规模 | `size/S` `size/M` `size/L` | 预估工作量 |
| 跨仓库 | `cross-repo` | 存在跨仓库依赖时添加 |

### 标签决策速查

```
是Bug修复？ → type:bugfix + priority/P0或P1
是新功能？ → type:feature + priority/P1或P2
是现有功能改进？ → type:enhancement + priority/P2
涉及安全？ → type:security + priority/P0 + approval:required
只改文档？ → type:docs + priority/P2 + approval:auto
```

---

## 四、Issue模板（标准格式）

每个Issue的Body必须包含以下5个section。Claude Code依赖这些结构化信息来自主理解和执行任务。

```markdown
## 需求背景 / 问题描述

<!-- 
用1-3段话说明：
- 为什么需要这个功能/修复？业务场景是什么？
- 当前存在什么问题？用户痛点是什么？
- 期望达到什么效果？
-->

## 关联的Issue（可跨仓库引用）

<!-- 
- 本仓库关联：#12, #15
- 跨仓库关联：WnadeyaowuOraganization/wande-ai-front#8
- 依赖关系：blocked-by WnadeyaowuOraganization/wande-ai-backend#5（需要后端API先完成）
- 无关联时写"无"
-->

## 环境 / 配置 / 关联文件 / 参考资料

<!--
- 涉及的配置文件路径（如 application-dev.yml）
- 需要的环境变量或Secret
- 数据库表名或SQL文件路径
- 参考的API文档URL或设计稿链接
- 相关的第三方库或依赖
-->

## 处理步骤

<!--
以表格形式列出具体执行步骤，让Claude Code明确知道做什么。
如果步骤较复杂，可使用子任务列表 [ ] 替代表格。
-->

| 步骤 | 操作内容 | 涉及文件/路径 | 验收标准 |
|------|---------|-------------|---------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |
| 3 | ... | ... | ... |

## 其他要求

<!--
- 编码规范要求（如需特别注意的注解、命名约定）
- 测试要求（单元测试、集成测试、手动验证点）
- 兼容性要求（不破坏现有API、数据库向后兼容）
- 部署注意事项（需要新的环境变量、数据库迁移等）
- 无特殊要求时写"按项目现有规范开发即可"
-->

## 测试验收标准

<!--
定义此Issue完成后，自动测试（wande-ai-e2e）应验证的内容。
测试CC会根据此section决定是否需要编写新的测试用例。

格式建议：
- 用户场景描述（如"用户可以在招标列表页看到新增的筛选条件"）
- 关键数据验证（如"API返回的分页数据total字段不为0"）
- 页面元素验证（如"页面包含id为supplier-rating的评分组件"）
- 无特殊测试需求时写"由自动测试CC根据变更范围自动判断"
-->
```

---

## 五、Issue编写指南

### 5.1 标题规范

```
[模块] 动词 + 对象 + 限定条件
```

**好的标题**：
- `[招投标] 新增招标项目列表分页查询接口`
- `[CRM] 修复供应商详情页手机号显示异常`
- `[用户端] 添加AI对话历史记录侧边栏`

**差的标题**：
- `修改一个bug`（没有模块、没有具体描述）
- `前端优化`（过于宽泛）

### 5.2 处理步骤编写要点

处理步骤是Claude Code的核心执行依据，要做到：

1. **路径明确**：涉及的文件给出完整路径（如 `ruoyi-modules/wande-ai/src/main/java/...`）
2. **输入输出明确**：API接口需说明请求参数和响应结构
3. **依赖明确**：需要import的类、需要注入的Service给出全限定名
4. **验收标准可执行**：用"编译通过"、"接口返回200"、"页面可正常渲染"等可验证的描述

### 5.3 跨仓库引用格式

```
# 引用其他仓库的Issue
WnadeyaowuOraganization/wande-ai-backend#12
WnadeyaowuOraganization/wande-ai-front#8

# 在PR描述中自动关闭跨仓库Issue（仅合并到默认分支时生效）
Fixes WnadeyaowuOraganization/wande-ai-backend#12
```

### 5.4 前后端分拆示例

需求："新增供应商评分功能"

**后端Issue**（创建在 `wande-ai-backend`）：
```
标题：[CRM] 新增供应商评分CRUD接口
标签：priority/P1, type:feature, status:ready, module:crm
Body：
  - 需求背景：需要对供应商进行评分管理...
  - 关联Issue：WnadeyaowuOraganization/wande-ai-front#N（前端评分页面）
  - 处理步骤：建表 → Entity → Mapper → Service → Controller → SQL迁移
```

**前端Issue**（创建在 `wande-ai-front`）：
```
标题：[CRM] 新增供应商评分管理页面
标签：priority/P1, type:feature, status:ready, module:crm, cross-repo
Body：
  - 需求背景：配合后端评分接口，提供管理界面...
  - 关联Issue：blocked-by WnadeyaowuOraganization/wande-ai-backend#N（等待后端接口）
  - 处理步骤：路由注册 → 页面组件 → API调用层 → 表格+表单实现
```

---

## 六、创建流程

### 6.1 Perplexity创建Issue的标准流程

```
1. 接收吴耀需求
2. 分析需求 → 确定目标仓库（按第二章路由决策）
3. 确定标签组合（按第三章标签规范）
4. 按第四章模板填写Issue Body
5. 调用 GitHub API 创建Issue：
   gh issue create \
     --repo WnadeyaowuOraganization/{目标仓库} \
     --title "[模块] 标题" \
     --body "..." \
     --label "priority/P1,type:feature,status:ready"
6. 将Issue关联到自动编程看板（必须）：
   gh project item-add 2 \
     --owner WnadeyaowuOraganization \
     --url {Issue的URL}
7. 如有跨仓库依赖，在关联Issue的Body中补充引用
8. 向吴耀确认已创建（附Issue链接）
```

### 6.2 批量创建（§3.5 一站式交付模式）

当需求较大需要拆分为多个Issue时：

```
1. 分析需求 → 输出执行清单（含所有Issue的标题/仓库/标签/依赖）
2. 等待吴耀"同意"
3. 按依赖顺序批量创建所有Issue
4. 被依赖的Issue先创建（获取Issue编号后，在依赖方的Body中引用）
5. 将所有Issue关联到自动编程看板（#2）
6. 汇总所有已创建Issue的链接
```

### 6.3 Project看板关联（必须步骤）

**所有仓库创建的Issue，必须关联到自动编程看板（Project #2）。**

```bash
# 创建Issue后立即执行：
gh project item-add 2 \
  --owner WnadeyaowuOraganization \
  --url https://github.com/WnadeyaowuOraganization/{仓库}/issues/{编号}
```

**看板信息**：
- 名称：万德应用开发 — 自动编程看板
- 编号：#2
- URL：https://github.com/orgs/WnadeyaowuOraganization/projects/2
- Project Node ID：`PVT_kwDOD3gg584BSCFx`

**关联范围**：
- `wande-ai-backend` 的所有Issue → 关联到 Project #2
- `wande-ai-front` 的所有Issue → 关联到 Project #2
- `wande-ai-platform` 的所有Issue → 关联到 Project #2
- `wande-gh-plugins` 的所有Issue → 关联到 Project #2

**为什么必须关联**：
- 统一管理所有开发任务的进度
- Claude Code / autonomous_worker 的工作全部可追踪
- 方便吴耀在一个看板上掌握全部开发状态

### 6.4 创建后的自动衔接

```
Issue创建（status:ready）+ 关联到 Project #2
  ↓
Claude Code每次启动时执行：
  gh issue list --repo WnadeyaowuOraganization/{仓库} --state open --label ready -L 10
  ↓
按 priority 排序拾取 → 开发 → push到main → CI/CD自动部署 → 关闭Issue
```

---

## 七、质量检查清单

Perplexity在创建Issue前，对照以下清单自检：

- [ ] 仓库选择正确？（后端逻辑→backend，管理页面→front，爬虫/基础设施→platform，GH插件→wande-gh-plugins）
- [ ] 标签至少3个？（优先级 + 类型 + 状态）
- [ ] 标签名称拼写正确？（与 WANDE_LABEL.md 一致）
- [ ] 5个Section都已填写？（需求背景/关联Issue/环境配置/处理步骤/其他要求）
- [ ] 处理步骤有表格或清单？（不是纯文字描述）
- [ ] 文件路径准确？（参照各仓库CLAUDE.md中的项目目录结构）
- [ ] 跨仓库引用格式正确？（`WnadeyaowuOraganization/repo#number`）
- [ ] 验收标准可执行？（Claude Code能自主验证）
- [ ] 需要前后端分拆的已分拆？（一个Issue只对应一个仓库）
- [ ] 已关联到自动编程看板？（`gh project item-add 2 --owner WnadeyaowuOraganization --url {Issue URL}`）
- [ ] 测试验收标准Section已填写？（至少写"由自动测试CC根据变更范围自动判断"）

---

## 八、与Skill其他章节的关系

| Skill章节 | 与本SOP的关系 |
|-----------|-------------|
| §3.5 需求→执行一站式交付 | 上层框架：大需求拆分为多个Issue的流程 |
| §7.1 代码开发流 | 下游执行：Issue创建后Claude Code如何接任务 |
| §7.9 自动编程SOP | 平行文档：自动编程的执行侧，本SOP是需求侧 |
| §9.1 CI/CD流水线 | 下游部署：代码push后自动构建和部署 |
| WANDE_LABEL.md | 标签字典：所有标签的含义和Claude Code行为指引 |
| 各仓库CLAUDE.md | 执行手册：Claude Code的项目上下文和开发规范 |

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0 | 2026-03-18 | 初版发布 |
| v1.1 | 2026-03-19 | 新增§6.3 Project看板关联（必须步骤），所有应用仓库Issue必须关联到自动编程看板(#2)；移除wande-ai-web仓库路由（项目已弃用）；质量检查清单新增看板关联检查项；创建流程6.1/6.2补充关联步骤 |
| v1.3 | 2026-03-21 | 新增"测试验收标准"Section（第6个Section）；质量检查清单新增测试验收标准检查项；配合自动测试SOP(wande-ai-e2e) |
| v1.2 | 2026-03-19 | Project #2关联范围从backend/front扩展到全部仓库（新增platform和wande-gh-plugins）；路由表新增wande-gh-plugins仓库（Grasshopper插件）；路由表platform描述补充"平台基础设施"；质量检查清单更新仓库列表 |
