# 万德AI平台 — 统一标签规范 (WANDE_LABEL.md)

> **版本**: v1.0 | **生效日期**: 2026-03-18
> **适用仓库**: wande-ai-backend / wande-ai-front / wande-ai-web
> **维护者**: Perplexity（战略大脑）+ 吴耀（super_admin）

本文件定义了万德AI平台三个应用仓库的统一标签体系。所有Issue和PR必须按此规范打标签。
Claude Code / autonomous_worker 在处理Issue时，应读取本文件理解各标签含义，从而做出正确的执行决策。

---

## 一、标签命名规则

- 使用 `前缀:值` 或 `前缀/值` 格式，确保分类清晰
- 英文小写 + 短横线分词（如 `type:feature`）
- 每个Issue至少需要：**1个优先级** + **1个类型** + **1个状态**标签

---

## 二、优先级标签（Priority）— 必选一个

决定Issue的处理顺序。autonomous_worker按此排序拾取任务。

| 标签 | 颜色 | 含义 | Claude Code行为 |
|------|------|------|----------------|
| `priority/P0` | #E11D48 | **阻塞性** — 影响生产环境或核心功能不可用 | 立即处理，跳过队列中的其他任务 |
| `priority/P1` | #0052CC | **核心功能** — 当前Sprint必须完成的重要功能 | 按队列顺序优先处理 |
| `priority/P2` | #0E8A16 | **增强功能** — 有价值但不紧急的改进 | P0/P1处理完后再处理 |
| `priority/P3` | #FEF2C0 | **未来规划** — 记录想法，暂不执行 | 不主动处理，等标签变更后再拾取 |

---

## 三、类型标签（Type）— 必选一个

描述Issue的工作性质，影响代码审查标准和测试要求。

| 标签 | 颜色 | 含义 | Claude Code注意事项 |
|------|------|------|-------------------|
| `type:feature` | #7057FF | **全新功能** — 从零实现的新能力 | 必须包含完整测试；需创建/修改数据库migration时，标注在PR描述中 |
| `type:enhancement` | #A2EEEF | **功能增强** — 已有功能的改进或扩展 | 不破坏现有API兼容性；补充增量测试 |
| `type:bugfix` | #D73A4A | **Bug修复** — 修复已知缺陷 | 先写复现测试，再修复代码，确保回归测试通过 |
| `type:refactor` | #C5DEF5 | **代码重构** — 不改变外部行为的内部优化 | 确保所有现有测试通过；不引入新依赖 |
| `type:docs` | #0075CA | **文档变更** — README/注释/API文档更新 | 不涉及代码逻辑变更 |
| `type:test` | #BFD4F2 | **测试补充** — 补充缺失的测试覆盖 | 不修改生产代码 |
| `type:chore` | #E4E669 | **杂务** — 依赖更新/CI配置/构建脚本 | 谨慎处理，避免破坏构建流程 |
| `type:security` | #E11D48 | **安全相关** — 漏洞修复/权限加固 | 高优先处理；PR描述中不暴露具体漏洞细节 |
| `type:performance` | #F9D0C4 | **性能优化** — 响应时间/内存/查询优化 | 提供优化前后的性能对比数据 |

---

## 四、状态标签（Status）— 由自动化流程管理

反映Issue在工作流中的当前阶段。Claude Code和CI自动更新，通常不需要手动设置。

| 标签 | 颜色 | 含义 | 触发条件 |
|------|------|------|---------|
| `status:ready` | #006B75 | **就绪** — 需求明确，可以开始开发 | Perplexity/吴耀确认后添加 |
| `status:in-progress` | #0075CA | **进行中** — Claude Code正在处理 | Claude Code拾取Issue时自动添加 |
| `status:pr-created` | #0E8A16 | **已提PR** — 等待CI和Review | PR创建后自动添加 |
| `status:blocked` | #D93F0B | **阻塞中** — 等待外部依赖或人工决策 | 遇到阻塞时手动添加，同时说明阻塞原因 |
| `status:failed` | #D73A4A | **执行失败** — 需要重试或人工介入 | CI失败或Claude Code执行异常时添加 |

---

## 五、审批标签（Approval）— PR合并策略

决定PR合并到main分支时需要的审批级别。

| 标签 | 颜色 | 含义 | 合并规则 |
|------|------|------|---------|
| `approval:auto` | #0E8A16 | **全自动** — CI通过即合并 | 适用于文档/测试/配置等低风险变更 |
| `approval:notify` | #FBCA04 | **通知确认** — 24h无回复视为同意 | 适用于功能增强/性能优化等中等风险 |
| `approval:required` | #D93F0B | **必须审批** — CEO明确批准才合并 | 适用于新功能/架构变更/安全/数据库迁移 |

---

## 六、来源标签（Source）— 追踪Issue创建者

| 标签 | 颜色 | 含义 |
|------|------|------|
| `source:perplexity` | #7057FF | 由Perplexity（战略大脑）创建 |
| `source:claude-code` | #1D76DB | 由Claude Code自动发现并创建 |
| `source:user` | #FFD700 | 由吴耀或团队成员手动创建 |

---

## 七、AI选择标签（AI）— 指定处理模型

当Issue需要特定AI模型处理时使用。不添加时默认走ModelRouter自动路由。

| 标签 | 颜色 | 含义 | 适用场景 |
|------|------|------|---------|
| `ai:auto` | #1D76DB | ModelRouter自动路由（默认） | 大多数Issue |
| `ai:qwen122b` | #5319E7 | 本地Qwen3.5-122B深度推理 | 复杂架构设计/深度分析 |
| `ai:kimi` | #FBCA04 | Kimi K2.5（月之暗面） | 代码密集型任务 |
| `ai:glm5` | #D93F0B | GLM-5（智谱AI） | 复杂推理备选 |
| `ai:xykjy` | #B60205 | xykjy中转池（顶级模型） | 需要GPT-5/Claude等顶级模型时 |
| `ai:council` | #006B75 | 多模型会诊 | 重大架构决策，需要多视角 |

---

## 八、控制标签（Control）— 特殊指令

影响自动化流程行为的控制标签。

| 标签 | 颜色 | 含义 | Claude Code行为 |
|------|------|------|----------------|
| `human-only` | #5319E7 | 仅人工处理 — Claude Code必须跳过 | 检测到此标签时，不拾取、不处理、不评论 |
| `needs-human` | #D93F0B | 需要人工介入 — 处理到一半遇到问题 | 暂停处理，企微通知吴耀 |
| `worker-skip` | #E4E669 | Worker应跳过 — 临时暂停自动处理 | 与human-only类似，但可恢复 |
| `has-auto-pr` | #FEF2C0 | 已有自动PR — 避免重复创建 | 检测到此标签时，不再为该Issue创建新PR |

---

## 九、跨仓库关联标签（Cross-Repo）— 标识依赖关系

用于标识Issue与其他仓库的关联关系。

| 标签 | 颜色 | 含义 | Claude Code行为 |
|------|------|------|----------------|
| `depends:backend` | #0E8A16 | 依赖后端仓库的Issue | 处理前检查被依赖的Issue是否已关闭 |
| `depends:front` | #E99695 | 依赖管理后台前端仓库的Issue | 处理前检查被依赖的Issue是否已关闭 |
| `depends:web` | #1D76DB | 依赖用户端前端仓库的Issue | 处理前检查被依赖的Issue是否已关闭 |
| `cross-repo` | #FF6600 | 跨仓库协作 — 该Issue关联其他仓库的Issue | Issue body中必须包含具体的跨仓库引用链接 |

**跨仓库引用格式**：在Issue body中使用完整引用格式
```
## 跨仓库依赖
- 后端API: WnadeyaowuOraganization/wande-ai-backend#15
- 前端页面: WnadeyaowuOraganization/wande-ai-front#8
- 用户端: WnadeyaowuOraganization/wande-ai-web#3
```

**PR关联跨仓库Issue**：在PR描述中使用关键词自动关闭对应Issue
```
Fixes WnadeyaowuOraganization/wande-ai-backend#15
```

---

## 十、模块标签（Module）— 可选，按仓库差异化

标识Issue所属的业务模块。各仓库可根据自身特点使用不同模块标签。

### 通用模块（三仓库共用）

| 标签 | 颜色 | 含义 |
|------|------|------|
| `module:crm` | #5319E7 | CRM客户关系管理 |
| `module:bidding` | #0052CC | 项目矿场/招投标 |
| `module:execution` | #006B75 | 中标后执行管理 |
| `module:knowledge` | #C5DEF5 | 知识库 |
| `module:wecom` | #0E8A16 | 企业微信集成 |
| `module:rbac` | #D4C5F9 | 权限与角色控制 |
| `module:cockpit` | #F9D0C4 | 超管驾驶舱 |
| `module:brand` | #01696F | 品牌中心 |
| `module:ai-assistant` | #7057FF | AI助手/对话 |
| `module:analytics` | #5319E7 | 数据分析/报表 |

### 仓库特有模块

**wande-ai-backend**:
| 标签 | 颜色 | 含义 |
|------|------|------|
| `module:api` | #0E8A16 | REST API端点 |
| `module:migration` | #D93F0B | 数据库迁移 |
| `module:scheduler` | #0075CA | 定时任务/调度器 |

**wande-ai-front**:
| 标签 | 颜色 | 含义 |
|------|------|------|
| `module:dashboard` | #0052CC | 仪表盘/看板页面 |
| `module:form` | #BFD4F2 | 表单/输入组件 |
| `module:chart` | #5319E7 | 图表/可视化 |

**wande-ai-web**:
| 标签 | 颜色 | 含义 |
|------|------|------|
| `module:portal` | #006B75 | 员工门户 |
| `module:mobile` | #0E8A16 | 移动端适配 |
| `module:supplier` | #FBCA04 | 供应商协作 |

---

## 十一、工作量标签（Size）— 可选

预估Issue的工作量，帮助排期。

| 标签 | 颜色 | 含义 |
|------|------|------|
| `size/XS` | #C5DEF5 | 极小 — < 30分钟，改几行代码 |
| `size/S` | #BFD4F2 | 小 — 30分钟~2小时 |
| `size/M` | #D4C5F9 | 中 — 2~8小时 |
| `size/L` | #F9D0C4 | 大 — 1~3天 |
| `size/XL` | #E99695 | 超大 — 建议拆分为多个Issue |

---

## 十二、标签组合示例

### 示例1：新增回款API（后端）
```
priority/P0  type:feature  status:ready  approval:required  
module:execution  source:perplexity  size/M
```

### 示例2：修复登录Bug（前端）
```
priority/P1  type:bugfix  status:ready  approval:auto  
module:rbac  source:user  size/S
```

### 示例3：跨仓库功能 — 回款监控台（前端依赖后端）
```
priority/P0  type:feature  status:blocked  depends:backend  cross-repo
module:execution  source:perplexity  size/L
```
Issue body中写：
```
## 跨仓库依赖
- 后端API: WnadeyaowuOraganization/wande-ai-backend#15 (回款计划API)
- 端点: GET/POST /api/execution/projects/{id}/payment-plans
- 后端状态: 待完成 → 后端Issue关闭后自动解除blocked
```

### 示例4：Claude Code处理决策树

```
拾取Issue前检查:
1. 有 human-only/worker-skip/has-auto-pr? → 跳过
2. 有 status:blocked? → 跳过，检查依赖Issue状态
3. 有 depends:xxx? → 检查被依赖Issue是否closed
   - 未closed → 跳过
   - 已closed → 移除blocked，继续处理
4. 按 priority/P0 > P1 > P2 > P3 排序拾取
5. 读取 type: 标签确定代码规范和测试要求
6. 读取 approval: 标签确定PR合并策略
7. 读取 ai: 标签选择模型（默认auto路由）
```

---

## 十三、维护规则

1. **新增标签**：需更新本文件并同步推送到三个仓库
2. **废弃标签**：先标记为 `[deprecated]`，下个Sprint移除
3. **同步机制**：三个仓库的 `WANDE_LABEL.md` 内容必须完全一致
4. **版本追踪**：每次变更在文件头部更新版本号和日期
