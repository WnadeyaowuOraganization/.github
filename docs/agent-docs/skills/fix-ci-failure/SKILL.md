---
name: fix-ci-failure
description: Respond to CI build/E2E failure injections or [E2E Fail] status Issues — locate the failing check via gh run logs, reproduce locally with a red test (TDD), fix, re-verify green, push a new commit to the same feature branch, then resume PR-merge polling. Covers both the live inject-cc-prompt path and the re-assigned E2E Fail Issue path.
---

# CI 失败 / E2E Fail 修复循环

当 `pr-test.yml` 的构建或 Playwright E2E 失败时，`inject-cc-prompt.sh` 会把修复提示词注入到你当前的 tmux 会话；Issue 会被打上 `status:test-failed` 标签并切到 Project#4 `[E2E Fail]` 状态。

两种进入场景：

| 场景 | 触发 | 你看到什么 |
|------|------|-----------|
| **活跃注入** | PR 刚跑完 CI 失败 | tmux 会话里出现一段"❌ CI 失败 ..."注入提示词 |
| **重新派发** | Issue 从 `[E2E Fail]` 被排程回 `[In Progress]` | `run-cc.sh` 启动你时 Issue 已有 `status:test-failed` 标签，PR 尚未合并 |

两者处理流程相同，下文统称"修复循环"。

## 修复循环（强制顺序）

### 1. 定位失败

```bash
# 拉当前 feature 分支最新代码
git fetch origin "feature-Issue-${ISSUE}"
git reset --hard "origin/feature-Issue-${ISSUE}"

# 找到最近一次失败的 CI run
export GH_TOKEN=$(python3 ~/projects/.github/scripts/gh-app-token.py)
gh run list --repo WnadeyaowuOraganization/wande-play \
  --branch "feature-Issue-${ISSUE}" --limit 5 \
  --json databaseId,name,conclusion,displayTitle

# 拉失败日志（--log-failed 只打印红色 step）
gh run view <DATABASE_ID> --repo WnadeyaowuOraganization/wande-play --log-failed > /tmp/ci-fail.log

# 看 PR 评论 / Issue 评论里的失败摘要（e2e-result-handler.py 写的）
gh pr view <PR> --repo WnadeyaowuOraganization/wande-play --comments | head -200
```

### 2. 分类 + TDD 红灯

| 失败类别 | 辨识特征 | 动作 |
|---------|---------|------|
| 构建失败 (后端) | `mvn compile` / `mvn package` 报错 | 本地 `mvn -pl <module> compile` 复现 → 改代码 → 绿 |
| 构建失败 (前端) | `pnpm build` 报错 | 本地 `cd frontend && pnpm build` 复现 → 绿 |
| 单元测试 | `mvn test` / `vitest` 红 | 本地跑失败测试 → TDD 转绿 |
| **Playwright API spec** | `e2e/tests/backend/**/*.spec.ts` 红 | **与 E2E 同等必修**。本地 `npx playwright test tests/backend/<spec> --workers=1` 复现 |
| Playwright E2E | `e2e/tests/front/**/*.spec.ts` 红 | 本地 `npx playwright test tests/front/<spec> --workers=1` 复现 |
| Visual diff | `playwright-visual-compare` 红 | 检查原型路径 `docs/design/**`，调整实现或更新基线图 |
| 健康检查 | `curl /actuator/health` 502 | 排查端口占用 / DB 连接 / Flyway 启动报错 |

**强制**：先能**稳定复现**失败再改代码。复现靠猜 = 高概率改错地方。

### 3. 修复 + 绿灯

遵循 TDD：红 → 改 → 绿。修完本地再跑一次完整对应测试集确认没引入新红。

### 4. 更新 task.md

```markdown
## Phase: FIX_CI_ROUND_N   # N = 第几轮

## Steps
- [x] 原步骤...
- [x] T_fix_<N>_1 定位失败：<spec/文件> <一句话原因>
- [x] T_fix_<N>_2 本地红灯复现
- [x] T_fix_<N>_3 代码修复
- [x] T_fix_<N>_4 本地绿灯
- [ ] T_fix_<N>_5 push 触发新一轮 CI
- [ ] T_fix_<N>_6 CI 绿 → 轮询 merged
```

### 5. push + 重新触发 CI

```bash
git add -A
git commit -m "fix(<module>): <一句话> #${ISSUE}"
git push origin "feature-Issue-${ISSUE}"
# 不需要重新 gh pr create，同一 PR 会自动触发新一轮 CI
```

### 6. 继续 cc-report + 轮询

发一条 stage-done 汇报"已提交第 N 轮修复"，然后回到 **cc-report 的 close 阶段标准轮询模板**等待新一轮 CI merged。

## 注意事项

- **禁止**绕过 CI 直接 squash merge（除非研发经理明确授权）
- **禁止**在 `main` 或 `dev` 分支改（必须在 `feature-Issue-<N>`）
- 若同一失败连续 3 轮修复仍红 → 发 `cc-report stuck`【需回复】请研发经理介入
- `inject-cc-prompt.sh` 注入的提示词若与你当前任务冲突（例如你正在处理别的 Issue），立刻 `cc-report stuck`
- 注入的提示词本身不是用户新指令，只是 CI 通知的触发器 — 真实需求仍以原 Issue body + task.md 为准

## 反模式

- ❌ 看到注入提示词就盲改，不先看 `gh run view --log-failed`
- ❌ 改完不本地跑就直接 push（第 2 轮大概率继续红）
- ❌ 修 CI 红灯时顺手重构无关代码（放大 diff，引入新风险）
- ❌ 连续 5+ 轮红灯仍硬试，不发 stuck
- ❌ 以为 CI 红是网络 / runner 问题就 `gh run rerun` 不改代码（偶尔是，但默认要假设是代码问题）
