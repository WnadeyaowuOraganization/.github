---
name: issue-task-md
description: Evaluate an Issue against design docs and existing code, produce a task.md plan with checkboxes, split complex work via Agent Teams when needed, and resume from last checkpoint after a restart or /compact. This is the mandatory first action for every new Issue in Wande-Play.
---

# Issue 评估与 task.md 计划

收到 Issue 号后的**第一步**。输出 `issues/issue-<N>/task.md`（仓库根 `issues/` 目录，研发经理已预建），作为后续编码/测试/PR 的唯一进度源。重启或 /compact 后读它找下一步。

## 使用时机

- 首次拿到 Issue：`--issue N` 参数启动 CC
- 重启 / compact 后恢复
- 研发经理要求拆分复杂 Issue

## 原型检查（三方对仗之前，强制第一步）

读完 Issue 后，**先判断是否有原型支撑**：

| 条件 | 判定 | 动作 |
|------|------|------|
| Issue body 引用了 `docs/design/` 下文件 | ✅ 有原型 | 继续三方对仗 |
| Issue body 含原型截图或 Figma 链接 | ✅ 有原型 | 继续三方对仗 |
| 纯后端API/数据库/pipeline（无UI） | ✅ 无需原型 | 继续三方对仗 |
| `type:bugfix` / `type:docs` / `type:refactor` / `type:test` | ✅ EXEMPT | 继续三方对仗 |
| **以上都不满足** | ❌ 缺原型 | **立即停止，执行以下命令** |

```bash
# 缺原型处理流程
bash ~/projects/.github/scripts/update-project-status.sh --repo play --issue ${ISSUE} --status "pause"
gh issue edit ${ISSUE} --repo WnadeyaowuOraganization/wande-play --add-label "needs-prototype"
MSG="[#${ISSUE}] 缺少原型支撑，已pause等待原型补充" && \
tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter && \
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"warning\"}" >/dev/null
```

## 三方对仗（强制顺序）

缺一步 = 漏需求 / 字段错位 / 返工。

| 来源 | 读取命令 | 用途 |
|------|---------|------|
| 1. Issue 原文 | 优先 `cat issues/issue-<N>/issue-source.md`；兜底 `gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments` | 需求 + 验收标准 |
| 2. 原型/详设 | `~/projects/.github/docs/design/**/*.md`，Issue 正文通常含链接 | 字段 / UI / 交互细节 |
| 3. 现有代码 | 读 Issue "涉及文件" 列出的路径 | 已实现部分 / 冲突点 |

**若 gh 失败**：

```bash
export GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py)
curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/WnadeyaowuOraganization/wande-play/issues/<N>" | python3 -m json.tool
```

## 复杂度判定

| 判定 | 触发条件 | 动作 |
|------|---------|------|
| 简单 | 单文件 < 200 行改动 | 单 CC 串行 |
| 中等 | 前后端都涉及 / 3~8 文件 | 单 CC + task.md 分阶段 |
| **复杂** | 跨模块 / 建表 / > 8 文件 / 含 E2E / `module:fullstack` 标签 | **必须 Agent Teams**（Backend + Frontend + Integration 三角色并行） |

复杂 Issue 硬扛 = 返工。`module:fullstack` 标签还要求先提交契约才能开始编码。

## Agent Teams 模板（复杂 Issue 专用）

```
创建 3-Agent 团队开发 Issue #N：
- Backend Agent：只改 backend/，按 shared/api-contracts 实现 API
- Frontend Agent：只改 frontend/，API 调用对齐契约
- Integration Agent：只改 e2e/、shared/，验证前后端一致性
门控：backend mvn compile 通过 + frontend pnpm build 通过 + 契约两端都有实现
```

## task.md 标准结构

写入前先自检：Steps 中**不得包含**上方「反模式」列表中任一写法。如不确定，写完后再 grep 自查一遍。

```markdown
# Task: Issue #N — <一句话标题>

## Status: IN_PROGRESS
## Phase: PREPARE

## 对账表（原型 vs 现状）
| 设计要求 | 现状 | Gap | 任务 |
|---------|------|-----|------|
| 5张KPI卡片 | 未渲染 | 接stats接口 | T1 |

## 原型核对清单（§X.X）
- [ ] 表格列：项目名称/编码/类型/... (共13列，与01-all.html一致)
- [ ] 筛选栏：项目类型/区域/...
- [ ] 操作按钮：详情/修正/有效/无效/分配/删除 (tooltip文字已核对)

## Steps（仅业务实现项，CC标准操作不写入）
- [ ] T1 建表 wdpp_xxx + Flyway 脚本
- [ ] T2 Entity + Mapper + Service + Controller
- [ ] T3 JUnit 单测（BaseServiceTest）通过 + mvn compile 绿
- [ ] T4 Playwright API spec（`e2e/tests/backend/api/<module>.ts`）通过
- [ ] T5 index.vue + data.ts + detail-drawer.vue
- [ ] T6 cp smoke 模板改 ROUTE/PAGE_NAME 保留 3 条反事故断言
- [ ] T7 pnpm build 通过
- [ ] T8 Playwright e2e spec 通过（前端门）
- [ ] T9 截图上传 Release screenshot-<PR>

## Files Changed
（随开发更新）

## Blockers
（无 / 列出阻塞项）
```

### ⛔ 禁止写入 task.md 的内容（写入 = lint 门 2 必然失败）

以下均为 CC 标准操作，由 CC 自动执行，**不得作为 task.md 检查项**：

| 禁止写法 | 原因 |
|---------|------|
| `T_N rebase origin/dev` | CC 在 `pr-body-lint` 前自动执行，写入 = 循环依赖 |
| `T_N gh pr create` | CC 在 `pr-body-lint` 通过后自动执行，同上 |
| `T_N 轮询等待 merge` | CC 在 PR 创建后自动轮询，同上 |
| `T_N task.md 全勾 + pr-body-lint 通过` | lint 检查 task.md 本身，此项 = 自指循环 |
| `T_N 截图上传 Release` | 截图是 `pr-visual-proof` skill 的输出，不是业务实现 |

**违反以上任一条，pr-body-lint Gate 2 必然失败。** 如业务步骤确实做不完，拆追补 Issue 并在原 task.md 备注 `→ 追补 #M`，不要写 CC 操作项。

### 质量门（task.md 业务检查项必须全部 `- [ ]` 勾完）

`任何 - [ ]` 未勾 = quality-gate 门 2 拦截。做不完的项：拆追补 Issue → 备注 `→ 追补 #M` → 勾原步骤。

## 开工同步

task.md 提交后发开工汇报（tmux + notify 双通道）：

```bash
MSG="[#${ISSUE}] 开工：复杂度<简单/中等/复杂>, 涉及 <文件>, 预计阶段 <A→B→C>"
tmux send-keys -t 'manager-研发经理' "[CC-REPORT] $MSG" Enter
curl -s -X POST http://localhost:9872/api/notify -H 'Content-Type: application/json' \
  -d "{\"session\":\"cc-report-${ISSUE}\",\"message\":\"$MSG\",\"type\":\"info\"}"
```

## 恢复规则（重启 / compact 后）

1. `cat issues/issue-<N>/task.md` 找第一个 `- [ ]`
2. `git status` + `git diff` 看当前文件真实状态（可能半途完成）
3. **不重新规划**：若已部分完成则先勾选已做部分，直接接续做下一项
4. 不清楚现状时才主动问研发经理，不要自行推翻计划

## E2E Fail / `status:test-failed` 分支（Issue 被重派时）

Issue 若带 `status:test-failed` 标签或 Project#4 状态是 `[E2E Fail]`，说明**之前已经提过 PR 但 CI 红**，现在是修复轮次。**不要**重新写 task.md，按以下顺序续：

1. **确认分支**：`git branch --show-current` 应是 `feature-Issue-<N>`；若不是，`git fetch origin feature-Issue-<N> && git checkout feature-Issue-<N>`
2. **找历史 PR**：`gh pr list --head feature-Issue-<N> --state all --repo WnadeyaowuOraganization/wande-play` → 找 OPEN 或最近的
3. **读 PR 评论中的失败摘要**（`e2e-result-handler.py` 会把失败 spec/log 贴进来）：`gh pr view <PR> --comments | head -200`
4. **读原 task.md**（研发经理或 cc-lock-manager 通常保留了 `issues/issue-<N>/task.md`）找已勾选部分
5. **切 `fix-ci-failure` skill** 进入修复循环（定位失败 → TDD 红 → 修 → 绿 → push）

对账表 / 原型清单 / Steps 不重写，在 `## Phase` 加 `FIX_CI_ROUND_N` 并追加 `T_fix_*` 系列步骤即可。

## 反模式

- ❌ 跳过三方对账直接开码
- ❌ 把所有任务堆一个阶段（失败不易恢复）
- ❌ 复杂/fullstack Issue 单 CC 硬扛
- ❌ task.md 放 `/tmp` 或非仓库路径（重启丢失）
- ❌ 勾选"截图"却 body 里没真截图（quality-gate 门 3 拦截）
- ❌ 对账表缺省（后期验收时对不上原型）
