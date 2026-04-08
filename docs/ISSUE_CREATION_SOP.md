# Issue创建SOP — 自动编程需求源

> **版本**: v3.0 | **生效日期**: 2026-04-08
> **适用仓库**: wande-play（Monorepo）
> **上游**: 吴耀提出需求 → Perplexity分析
> **下游**: Claude Code从 wande-play Issue 接任务 → 自动编程执行 → Perplexity产品验收
> **关联文档**: [WANDE_LABEL.md](./WANDE_LABEL.md) · [status.md](./status.md)

---

## 一、SOP定位

```
吴耀提需求 → Perplexity按本SOP创建Issue → CC自动接任务执行 → Perplexity产品验收
                    ↑                              ↓                    ↓
              Skill §3场景路由表            §4自动编程SOP           本SOP §六
```

**核心目标**：让每个Issue都精准到CC可以直接自主执行，不产生歧义、不遗漏环境，且Perplexity验收时有明确Checklist可勾。

---

## 二、仓库路由（Monorepo版）

> **2026-04-02起，所有业务Issue统一创建在 `wande-play` 仓库。**
> Grasshopper插件例外，创建在 `wande-gh-plugins`。

通过 **module scope 标签** 决定CC行为：

| module标签 | 需求特征 | CC工作目录 | CC模式 |
|-----------|---------|-----------|-------|
| `module:backend` | 纯后端：Spring Boot API/Service/数据库 | `backend/` | 单Agent TDD |
| `module:frontend` | 纯前端：Vue3页面/组件/路由 | `frontend/` | 单Agent TDD |
| `module:pipeline` | 纯采集：Python爬虫/数据管线 | `pipeline/` | 单Agent |
| `module:fullstack` | **前后端联动**（涉及API+页面） | 根目录 | **Agent Teams 3-Agent并行** |

**路由原则**：
1. 前后端联动功能 → **一个Issue + `module:fullstack`**，不拆分为两个
2. 每个Issue有且仅有一个module scope标签
3. 跨越多个环境/仓库的需求 → **按环境拆分为独立Issue**（见 §三 Scope边界规则）

---

## 三、Scope边界规则（新增 — 解决多环境漏改问题）

> **背景**：Issue #3226 教训 — 旧版 `/cla/` 改动在评论中追加，CC未执行。
> **根因**：评论里的追加需求CC不一定读到，且 `/opt/claude-office/` 属于另一个仓库。

### 3.1 一个Issue只对应一个仓库

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| wande-play + /opt/claude-office/ 都要改 | 评论追加"旧版也要改" | **拆成2个独立Issue**，分别指向各自仓库 |
| 新版前端 + 旧版Vanilla JS都要改 | 在同一Issue body中描述两套 | 拆成 `module:frontend`（wande-play）+ `/opt/claude-office/` 专项Issue |
| 后端 + 前端都要改 | 拆成backend/frontend两个Issue | **一个Issue + `module:fullstack`**（同仓库联动不拆） |

**简单判断**：改动是否在同一个Git仓库？
- 同仓库 → 一个Issue可以覆盖（fullstack模式）
- 跨仓库 → 必须拆分

### 3.2 Issue body中明确列出环境清单

每个涉及前端可见功能的Issue，**必须在「产品验收清单」Section中列出所有需要检查的访问地址**：

```markdown
## 产品验收清单（Perplexity Review）

### 环境覆盖（必须全部验证）
- [ ] Dev新版：http://3.211.167.122:8083/wande/xxx
- [ ] Dev旧版（如有）：http://3.211.167.122:8083/cla/

### 功能Checklist
- [ ] [具体可见行为描述]
- [ ] [交互效果描述]
- [ ] [数据展示描述]
```

---

## 四、Issue模板（标准格式）

每个Issue的Body必须包含以下 **7个Section**：

```markdown
## 需求背景

<!--
1-3段话说明：
- 为什么需要这个功能？业务场景是什么？
- 当前存在什么问题？用户痛点是什么？
- 期望达到什么效果？
-->

## 关联Issue

<!--
- 本仓库依赖：#12, #15
- 跨仓库依赖：WnadeyaowuOraganization/repo#N
- 阻塞关系：blocked-by #N（需要先完成）
- 无关联时写"无"
-->

## 环境 / 配置 / 关联文件

<!--
- 访问地址（Dev：http://3.211.167.122:6040 / http://3.211.167.122:8083）
- 涉及的配置文件路径
- 数据库Flyway迁移脚本路径规则：backend/ruoyi-modules/wande-ai/src/main/resources/db/migration_wande_ai/V<日期>_<序号>__<描述>.sql
- 参考API文档或设计稿链接
- 相关第三方库或依赖
-->

## 处理步骤

<!--
以表格形式列出具体执行步骤。
涉及数据库变更时，必须写Flyway迁移脚本（不要直接改schema.sql）。
-->

| 步骤 | 操作内容 | 涉及文件/路径 | 验收标准 |
|------|---------|-------------|---------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

## 其他要求

<!--
- 接口契约：涉及前后端联动时，先在 shared/api-contracts/ 更新契约文件
- 编码规范：如需特别注意的注解、命名约定
- 兼容性：不破坏现有API、数据库向后兼容
- 无特殊要求时写"按项目现有规范开发即可"
-->

## 技术验收标准（CC自验）

<!--
CC执行完成后自行验证的技术指标：
- 编译/构建通过
- 单元测试通过（mvn test / vitest / pytest）
- curl验证命令（如：curl http://localhost:6040/wande/xxx → {code:200}）
- 无特殊要求时写"由CI pr-test.yml自动验证"
-->

## 产品验收清单（Perplexity Review）

<!--
⚠️ 此Section专供Perplexity做产品级验收用，CC不需要执行。
凡是涉及前端可见功能的Issue（module:frontend / module:fullstack），必须填写。
纯后端API、type:docs、type:bugfix可写"无需产品验收"。

格式：
-->

### 是否需要产品验收
<!-- 是 / 否（纯后端/文档/bugfix可填否） -->

### 环境覆盖（必须全部验证）
- [ ] Dev新版前端：http://3.211.167.122:8083/wande/[路径]
- [ ] （如有旧版）：http://3.211.167.122:8083/cla/

### 功能Checklist
- [ ] [Given-When-Then格式：进入XX页面，执行XX操作，应看到XX结果]
- [ ] [交互效果：点击/悬停/展开等]
- [ ] [数据展示：字段/格式/颜色状态]
- [ ] [响应式：窄屏/手机端是否正常]
```

---

## 五、标签规范

每个Issue **至少4个标签**：1个module scope + 1个优先级 + 1个类型 + 1个状态。

完整标签体系参照 [WANDE_LABEL.md](./WANDE_LABEL.md)。

### 必选标签

| 维度 | 常用标签 | 说明 |
|------|---------|------|
| **模块范围** | `module:backend` `module:frontend` `module:pipeline` `module:fullstack` | **最高优先级**，决定CC启动目录和工作模式 |
| 优先级 | `priority/P0` `priority/P1` `priority/P2` | P0=阻塞，P1=Sprint必做，P2=增强 |
| 类型 | `type:feature` `type:bugfix` `type:enhancement` | 决定开发策略和测试要求 |
| 状态 | `status:ready` | 创建时需求已明确则直接标ready |

### 产品验收相关标签（新增）

| 标签 | 颜色 | 含义 | 触发条件 |
|------|------|------|---------|
| `review:needed` | #7057FF | 需要Perplexity产品验收 | 含前端可见功能的Issue merge后，由CI自动或手动添加 |
| `review:passed` | #0E8A16 | 产品验收通过 | Perplexity在Issue评论写验收通过后添加 |
| `review:rework` | #D73A4A | 产品验收未通过，需返工 | Perplexity验收发现问题时添加，Issue重回In Progress |

### 标签决策速查

```
type:feature + module:frontend/fullstack → 创建时加 review:needed
type:feature + module:backend            → 无需产品验收
type:bugfix                              → 无需产品验收（除非P0且影响UI）
type:docs                                → 无需产品验收
```

---

## 六、产品验收流程（Perplexity执行）

### 6.1 什么时候触发验收

以下情况触发Perplexity产品验收（优先级由高到低）：
1. 吴耀明确要求"验收一下"
2. Issue带有 `review:needed` 标签且状态已 Done
3. 新模块/新页面首次上线前

以下情况**跳过**产品验收，由CI自动完成即可：
- 纯后端API Issue（`module:backend`）
- 文档变更（`type:docs`）
- Bug修复（`type:bugfix`），除非P0且影响UI

### 6.2 验收步骤

```
1. 打开Issue，读「产品验收清单」Section
2. 逐条勾选 Checklist（用 browser_task 访问环境）
3. 在Issue评论中写验收结果：
   - 通过：添加 review:passed 标签，评论"✅ 产品验收通过"
   - 未通过：添加 review:rework 标签，评论具体问题 + 修复建议
4. 未通过时，创建新Issue（type:bugfix + blocked-by 原Issue）
```

### 6.3 验收评论模板

```markdown
## 产品验收结果 — Perplexity Review

**验收时间**: 2026-XX-XX
**验收环境**: Dev（http://3.211.167.122:8083）

### Checklist结果
- [x] ✅ 进入/wande/claude-office，右上角可见紧凑指标条（✅🔀🤖🩺）
- [x] ✅ 点击指标条，展开详情面板，6项数据完整
- [ ] ❌ /cla/ 旧版页面未见DailyStatusBar — **阻塞**

### 结论
**未通过** — 旧版 /cla/ 页面缺少同步改动。
已创建修复Issue：#XXXX（[claude-office旧版] DailyStatusBar同步）

🤖 Perplexity Computer | 2026-04-08
```

---

## 七、预检清单（创建前必须自检）

> CC的harness会在执行前验证Issue可执行性，但发现问题=浪费G7e算力。
> Perplexity在创建阶段就要确保质量。

### 7.1 Scope预检

- [ ] 改动是否跨仓库？跨仓库 → 已拆分为独立Issue
- [ ] 是否涉及 `/opt/claude-office/` 旧版？→ 已创建独立Issue（不在wande-play）
- [ ] 评论里有追加需求？→ 已更新到Issue body（不只在评论）
- [ ] 有blocked-by依赖？→ 已标注且依赖Issue状态确认

### 7.2 技术预检

- [ ] **路径验证**：引用的每个文件路径已用 `gh api` 确认存在（或注明"待创建"）
  ```bash
  gh api repos/WnadeyaowuOraganization/wande-play/contents/<路径>?ref=dev --jq '.name'
  ```
- [ ] **技术栈一致性**：
  - `module:backend` → 只引用 `backend/` 下Java/Spring路径
  - `module:frontend` → 只引用 `frontend/` 下Vue3/TypeScript路径
  - `module:pipeline` → 只引用 `pipeline/` 下Python路径
  - `module:fullstack` → 可同时引用 `backend/` + `frontend/` + `shared/api-contracts/`
- [ ] **数据库变更**：需新建表/字段 → 使用Flyway迁移脚本，不直接改schema.sql
  - 路径：`backend/ruoyi-modules/wande-ai/src/main/resources/db/migration_wande_ai/V<YYYYMMDD>_<序号>__<描述>.sql`
- [ ] **接口契约**：module:fullstack的Issue → 已要求先更新 `shared/api-contracts/`

### 7.3 模板预检

- [ ] 7个Section都已填写（需求背景/关联Issue/环境配置/处理步骤/其他要求/技术验收/产品验收）
- [ ] 处理步骤有表格或清单（不是纯文字描述）
- [ ] 「产品验收清单」已填写环境URL和功能Checklist（`module:frontend/fullstack` 必填）
- [ ] 标签至少4个（module + 优先级 + 类型 + 状态）
- [ ] 标签名称拼写正确（与WANDE_LABEL.md一致）
- [ ] Sprint标签已添加（Sprint-1 / Sprint-2 等）

---

## 八、Issue批量创建（一站式交付）

当需求较大需拆分多个Issue时：

```
1. 分析需求 → 识别Scope边界（§三）→ 输出执行清单
   清单包含：标题 / 仓库 / module标签 / 依赖关系 / 是否需要产品验收
2. 向吴耀确认Sprint编号（硬性门控，不可跳过）
3. 按依赖顺序批量创建（被依赖的Issue先创建）
4. 创建后：
   - CI/CD的 auto-add-to-project.yml 自动关联Project#4
   - 无需手动关联看板
5. 汇总所有已创建Issue链接向吴耀确认
```

**关于 Project 看板**：
- 2026-04-02起，Project#4（wande-play研发看板）由 `auto-add-to-project.yml` 自动关联
- **不需要手动执行** `gh project item-add`（旧SOP已废弃）

---

## 九、创建命令参考

```bash
# 标准创建命令
gh issue create \
  --repo WnadeyaowuOraganization/wande-play \
  --title "[模块名] 动词+对象" \
  --body "$(cat issue_body.md)" \
  --label "module:fullstack,priority/P1,type:feature,status:ready,biz:cockpit,Sprint-1,review:needed,source:perplexity"

# 创建后确认Issue编号
gh issue list --repo WnadeyaowuOraganization/wande-play --state open -L 3

# 路径验证（创建前预检）
gh api repos/WnadeyaowuOraganization/wande-play/contents/frontend/apps/web-antd/src/views/wande/claude-office/index.vue?ref=dev --jq '.name' 2>/dev/null || echo "路径不存在"
```

---

## 十、与其他文档的关系

| 文档 | 关系 |
|------|------|
| `WANDE_LABEL.md` | 标签字典，本SOP的标签Section的上游权威 |
| `status.md` | Sprint计划，Issue创建时确认Sprint编号的依据 |
| `agent-docs/backend/db-schema.md` | 数据库Flyway规范，涉及DB变更时参考 |
| `shared/api-contracts/` | 接口契约目录，fullstack Issue必须先更新 |
| Skill wande-ai §4 | 产品验收SOP的调用方，与本文档保持同步 |

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|------|------|---------| 
| v1.0 | 2026-03-18 | 初版发布 |
| v1.1 | 2026-03-19 | 新增Project看板关联步骤 |
| v1.3 | 2026-03-21 | 新增测试验收标准Section |
| v2.0 | 2026-04-03 | Monorepo重构，仓库路由更新 |
| **v3.0** | **2026-04-08** | **全面重写**：①对齐Monorepo+Project#4+Flyway现状；②新增§三「Scope边界规则」（Issue #3226 教训：跨仓库需求必须拆分，不能在评论追加）；③Issue模板新增「产品验收清单」Section（第7个Section）；④新增§六「产品验收流程」（Given-When-Then Checklist + 验收评论模板）；⑤新增 review:needed / review:passed / review:rework 标签；⑥预检清单新增Scope预检组；⑦废弃手动Project看板关联步骤（已由auto-add-to-project.yml自动化）|
