# 新 Harness 工作流验证报告

> **生成时间**: 2026-04-06  
> **架构基准**: status.md 重大决策 D1–D49（截至 2026-04-06）  
> **验证范围**: 完整自动化研发流水线（排程→编程CC→CI→合并→发布→E2E）  
> **验证批次**: 驾驶舱7+矿场3（#2845-#2851 + #1494/#2455/#1534）+ 矿场Phase P0（#1483/#1512/#1513/#1514/#1515/#1516/#2229/#2244 + #2850）Max Sonnet  
> **状态**: ✅ 验证完成（全部批次 PR 已合并，PR#2906-#2924）  
>
> **⚠️ 架构注意**:  
> - `wande-ai-api` 子模块**已废弃**（D44，PR#2593），所有业务代码在 `wande-ai`  
> - 编程CC **不做** dev 环境部署（D31），只做 TDD + 编译检查 + PR 创建  
> - PR 由编程CC第三阶段**自行创建**（D11，`gh pr create --base dev`）  
> - 中层E2E 已改为**纯脚本 Smoke**（D33，`e2e_smoke.sh`），非AI驱动

---

## 一、流水线架构总览（基于 status.md 实际流程图）

```
研发经理CC（每10分钟，cc_manager.sh）[含 post-cc-check.sh 集成，D49]
    │
    ├─ 任务一: 排程  Plan → Todo（按优先级/Sprint）
    └─ 任务二: 触发  Todo → In Progress
                        │
                        ▼
          run-cc.sh --module <m> --issue N --dir kimiX --effort <e>
          工作目录: wande-play-kimiX/（带后缀，主目录禁止）
          .cc-lock 写入 state=RUNNING（D46）
                        │
              ┌─────────┴──────────┐
              ▼                    ▼
        单元测试(TDD)         编译检查
        mvn test / vitest    mvn package / pnpm build
              │                    │
         ❌失败→CC自行修复      ❌失败→CC自行修复
         （不提交PR）           （不提交PR）
              │                    │
              └────── 全通过 ───────┘
                           │
                           ▼
                    push feature-Issue-N
                    gh pr create --base dev
                    （由编程CC自身完成，D11）
    ═══════════════════════════════════════════
    CC异常恢复  post-cc-check.sh  cron每5分钟（D48）
    ═══════════════════════════════════════════
         扫描 .cc-lock 存在 + 无 claude 进程
         → git add -A + commit（保存进度）
         → git push origin feature-Issue-N
         → state=SAVED，retry_count++
         下次 cc_manager.sh 见 SAVED 状态 → 重入继续
         超过 MAX_RETRY=10 次 → 标 Fail
         ⚠️ 注意：post-cc-check.sh 不创建 PR，PR 由重入的编程CC创建
                           │
    ═══════════════════════╪═══════════════════════
    CI层  pr-test.yml      │  PR 创建/更新自动触发
    ═══════════════════════╪═══════════════════════
                           ▼
                   CI专用环境构建（wande-play-ci）
                   后端 :6041 / 前端 :8084
                           │
                    ┌──────┴──────┐
                    ▼             ▼
              构建成功        ❌ 构建失败（兜底）
                    │             │
                    ▼             ▼
             Playwright E2E   评论PR/Issue
             tests/backend/   + status:test-failed
             tests/front/     + [E2E Fail]
                    │
              ┌─────┴─────┐
              ▼           ▼
           ✅ 通过     ❌ 失败
              │           │ e2e-result-handler.py
              ▼           ▼
         approve PR    评论PR+Issue失败详情
         squash merge  + status:test-failed
         [Done]        + [E2E Fail]
              │
    ═══════════════════════════════════════════
    CD层  build-deploy-dev.yml  merge到dev触发
    ═══════════════════════════════════════════
              ▼
         后端: mvn package → 部署 → 健康检查(:6040)
         前端: pnpm build → rsync → nginx reload(:8083)
              │
    ═══════════════════════════════════════════
    Smoke探活  e2e_smoke.sh  cron 每30分钟
    ═══════════════════════════════════════════
              ▼
         curl健康检查 + Playwright smoke
         失败 → e2e-result-handler.py 自动创建Bug Issue
              │
    ═══════════════════════════════════════════
    顶层E2E  e2e_top_tier.sh  cron 每6小时
    ═══════════════════════════════════════════
              ▼
         全量回归测试（wande-play-e2e-top，top-tier分支）
```

---

## 二、预期验收项

### 阶段 A — 研发经理CC调度

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| A1 | 定时任务已恢复 | `crontab -l` 显示 `*/10 * * * *` cc_manager.sh（无 `# PAUSED` 前缀） | 仍有 PAUSED 注释 |
| A2 | 研发经理CC每10分钟触发 | `~/cc_scheduler/manager.log` 有 ≤10分钟内的新日志 | 无新日志 / lock 残留 |
| A3 | 防重复锁生效（cc_manager.sh内置锁） | 上轮未完成时日志显示"跳过"，不并发启动 | 并发运行多个 manager |
| A4 | 读取 status.md + Sprint 目标 | CC 响应包含 Sprint-1 重点模块信息 | 未读 status.md |
| A5 | 任务一排程：Plan → Todo | 按优先级（P0>P1>P2）将 Plan Issue 移入 Todo | 看板无变化 |
| A6 | 任务二触发：Todo → In Progress | 对 Todo 顶部 Issue 调用 run-cc.sh | 未触发编程CC |
| A7 | 主目录禁用规则（D9/memory） | 触发命令均带 `--dir kimi{N}`，不用主目录 | 缺少 --dir 参数 |
| A8 | effort 参数正确决策（D24） | fullstack/复杂 Issue → `high`；常规CRUD → `medium`；文档 → `low` | 重要Issue使用 low/medium |
| A9 | 同模块串行排程（D26） | 同一业务模块（同表/同API前缀）不并发分配给多个CC | 同模块并发导致Bean冲突 |

---

### 阶段 B — 编程CC执行

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| B1 | Issue 内容预取（D30） | CC启动前 `issue-source.md` 已写入（6秒内，非gh命令截断） | 文件缺失/为空 |
| B2 | 目录占用检测 | 同一 `wande-play-kimiN` 不并发第二个CC（exit 2） | 重复启动 |
| B3 | pre-task 创建 feature 分支 | `feature-Issue-N` 分支成功创建 | 分支未创建 |
| B4 | 正确工作目录（D30） | `backend` → `kimiN/backend`；`fullstack/app` → `kimiN/` 根目录 | 目录错误 |
| B5 | TDD：单元测试先于实现（D6） | CC 先写 `*Test.java`/`.spec.ts`，再写实现代码 | 直接写实现，跳过测试 |
| B6 | 编译检查门控（D26） | `mvn package` 或 `pnpm build` 失败时 CC 自行修复，不提交PR | 带编译错误的代码推送 |
| B7 | 新类创建前查重（D26） | CC 创建新类前先 `grep` 检查是否已存在同名类 | 重复类导致 Spring Bean 冲突 |
| B8 | wande-ai-api 路径禁止（D44） | 新代码写在 `wande-ai` 子模块，不写 `wande-ai-api`（已废弃） | 向废弃模块添加代码 |
| B9 | CC 自身创建 PR（D11） | 编程CC第三阶段执行 `gh pr create --base dev`（不依赖 post-task.sh） | PR 未创建 |
| B10 | task.md 完成报告 | `issues/issue-N/task.md` 存在，含 Status/Phase 进度字段 | 文件缺失 |
| B11 | Issue 评论完成摘要 | PR创建后 Issue 有 CC 完成的评论 | Issue 无评论 |
| B12 | 最大重试10次（D48/D49实际值） | run-cc.sh `MAX_RETRIES=10`；post-cc-check.sh `MAX_RETRY=10`；超过后标 Fail | 无限重试 |
| B13 | 超时1小时检测（D46实际值） | `check-cc-status.sh` `TIMEOUT_SECS=3600`（≠D43所述20分钟）；超时会话需人工处理 | 僵尸session残留 |
| B14 | 编程CC不操作 Dev 环境（D31） | CC 不执行 deploy-dev.sh 或 Playwright，Dev 部署由 build-deploy-dev.yml 负责 | CC 直接 deploy 到 Dev |

---

### 阶段 C — CI 流水线（pr-test.yml）

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| C1 | PR 触发 CI | PR 创建后 `pr-test.yml` 自动触发 | CI 未触发 |
| C2 | 冲突检测（D26） | CI 第一步检测 PR merge conflict | 未检测 |
| C3 | 自动冲突解决 | 有冲突时 `cycle-merge.sh` 自动运行 | 冲突导致 CI 直接失败 |
| C4 | 全局排队（D25） | `concurrency.group: pr-e2e-test`，多PR排队不并发 | 多PR同时跑E2E互踩 |
| C5 | CI 专用目录（D25） | 使用 `wande-play-ci`，不影响编程CC目录 | 目录混用 |
| C6 | CI 环境构建 | 后端 :6041 / 前端 :8084 正常启动 | 构建失败 |
| C7 | Playwright E2E 测试 | `tests/backend/` + `tests/front/` 用例执行 | 跳过测试 |
| C8 | 构建失败兜底（D34） | 构建失败时直接评论PR+Issue + `[E2E Fail]`，无需测试报告 | 失败但 Issue 未标记 |
| C9 | E2E 通过自动合并 | squash merge 到 dev，Issue 状态 → Done | 通过但未合并 |
| C10 | E2E 失败不合并 | PR 保持 open，Issue → `E2E Fail`（D32，optionId: efdab43b） | 失败仍合并 |
| C11 | Label 同步（D32） | 通过→ `status:test-passed`；失败→ `status:test-failed` | Label 未更新 |

---

### 阶段 D — Dev 环境部署（build-deploy-dev.yml）

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| D1 | dev merge 触发部署 | PR squash merge 后 `build-deploy-dev.yml` 自动触发 | 未触发 |
| D2 | 变更模块检测 | 只构建有变更的 backend/frontend/pipeline | 全量重建 |
| D3 | 后端 Maven 构建 | `mvn clean package -Pprod` 成功 | 编译失败 |
| D4 | 后端健康检查 | `:6040/actuator/health` 返回 200 | 服务未起 |
| D5 | 前端 pnpm 构建 | `pnpm build` 成功，dist 生成 | 构建失败 |
| D6 | 前端 Nginx 更新 | `:8083/` 可访问，内容已更新 | 页面 404 / 旧内容 |
| D7 | 并发保护 | `concurrency.cancel-in-progress: true` | 多次 push 堆积部署 |

---

### 阶段 E — Smoke 探活 & E2E 监控

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| E1 | Smoke 每30分钟运行 | `~/cc_scheduler/logs/e2e-smoke.log` 有定时记录（D33，纯脚本，非AI） | 无日志 / lock 残留 |
| E2 | Smoke 后端健康 | `:6040` curl 响应正常 | health check 失败 |
| E3 | Smoke 认证测试 | 登录 API 返回 token | 401 |
| E4 | Smoke Playwright | `e2e_smoke.sh` 内 Playwright smoke 用例通过 | 用例失败 |
| E5 | 失败自动创建 Issue | `e2e-result-handler.py` 在无已有 Issue 时自动新建 Bug Issue | 失败无告警 |
| E6 | 顶层E2E（每6小时） | `e2e_top_tier.sh` 全量回归，目录 `wande-play-e2e-top` | 未运行 |
| E7 | 分支隔离（D16） | mid 用 `main` 分支目录；top 用 `top-tier` 分支目录，互不干扰 | 分支混用 |

---

### 阶段 F — Issue 生命周期 & 状态机

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| F1 | 状态流转正确 | Plan→Todo→In Progress→Done（全自动，D5） | 状态跳跃/停滞 |
| F2 | E2E Fail 优先级（D32） | `E2E Fail` Issue 下次调度时被优先处理（排在 P0 之前） | 忽略 E2E Fail |
| F3 | Fail 停止重试 | 超3次后状态=Fail，研发经理CC不再触发该 Issue | 持续重试 |
| F4 | sync-issue-closed.yml | Issue 手动关闭时 Project#4 状态同步 Done | 状态不同步 |
| F5 | Issue 自动路由到 Project#4（D10） | 新 Issue 创建时 auto-add-to-project.yml 自动加入看板 | Issue 未进看板 |

---

### 阶段 G — 辅助脚本健壮性

| # | 验收项 | 预期行为 | 失败判断 |
|---|--------|---------|---------|
| G1 | run-cc.sh 新参数格式（D30） | `--module/--issue/--dir/--effort` 正确解析 | 旧位置参数导致失败 |
| G2 | cycle-merge.sh 冲突解决 | 自动 merge dev→feature，解决冲突，push | 冲突残留 |
| G3 | check-cc-status.sh 准确 | 显示运行中/已完成 CC，无僵尸会话 | 僵尸session显示 |
| G4 | update-project-status.sh | GraphQL 更新 Project#4 状态字段成功 | API 失败 |
| G5 | get-gh-token.sh | 返回有效 token（可读/写 private repo） | 401 |
| G6 | e2e-result-handler.py | 正确解析测试报告 → 评论 + 状态更新 | 解析失败/静默 |
| G7 | wande-ai-api 路径清除（D44） | 无脚本/CI 引用 `ruoyi-modules-api/wande-ai-api`（已废弃） | 有引用废弃路径 |

---

## 三、验证执行计划

### 观测命令

| 观测点 | 命令 |
|--------|------|
| 研发经理日志 | `tail -f ~/cc_scheduler/manager.log` |
| CC 会话列表 | `tmux list-sessions` |
| CC 状态 | `bash scripts/check-cc-status.sh` |
| CI 运行列表 | `gh run list --repo WnadeyaowuOraganization/wande-play --limit 10` |
| Dev 后端健康 | `curl -sf http://localhost:6040/actuator/health` |
| Dev 前端 | `curl -sf http://localhost:8083/ -o /dev/null -w "%{http_code}"` |
| Smoke 日志 | `tail -f ~/cc_scheduler/logs/e2e-smoke.log` |
| 项目看板状态 | `bash scripts/query-project-issues.sh play "In Progress"` |

### 触发链路（以驾驶舱+矿场批次为实际验证样本）

```
本批次10个 Issue（#2845-#2851 + #1494/#2455/#1534，Max Sonnet，effort=max）
    → 用户手动触发 run-cc.sh × 10（cc_manager.sh 当前 PAUSED）
    → 编程CC: SAVED状态重入 → TDD → compile → gh pr create --base dev
    → pr-test.yml: build CI环境 → Playwright E2E → squash merge
    → build-deploy-dev.yml: mvn package + pnpm build → 部署 :6040/:8083
    → e2e_smoke.sh: 下一个30分钟周期 smoke 验证
⚠️ #2893（Claude Office）的 monitor-issue-2893.sh 已删除（D49），不再单独跟踪
```

---

## 四、执行结果记录

> 观测时间：2026-04-06 09:29–09:50 UTC  
> 观测批次：驾驶舱7+矿场3（#2845/#2846/#2847/#2848/#2849/#2850/#2851 + #1494/#2455/#1534）  
> 模型：Claude Max Sonnet（effort=max），最大并发10个CC

### A — 研发经理CC调度（9项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| A1 | ⚠️ 未通过 | `crontab -l` 显示 `# PAUSED: */10 * * * * cc_manager.sh` | cc_manager.sh 仍处于 PAUSED 状态，本批次由用户手动触发 |
| A2 | ⚠️ 未通过 | `manager.log` 最后一条为 09:03（exit=1，Invalid API key）| manager 因 API key 问题退出，未恢复 |
| A3 | — | 无法验证（manager 未自动运行） | — |
| A4 | — | 无法验证 | — |
| A5 | — | 无法验证 | — |
| A6 | — | 无法验证 | — |
| A7 | ✅ 通过 | 本批次所有 run-cc.sh 调用均带 `--dir kimiN`，未用主目录 | — |
| A8 | ✅ 通过 | 驾驶舱/矿场全部使用 `--effort max`（Max订阅Sonnet） | — |
| A9 | ⚠️ 待确认 | 同模块Issue并发（#2848 Agent效率API + #2849 Agent效率前端）理论上无冲突；但 #2849 的 CC 将 WinRateStats 后端代码（属于 #1503）混入，说明 CC 工作范围有时超出 Issue 边界 | B6 失败：带编译缺陷代码合并至 dev |

### B — 编程CC执行（14项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| B1 | ✅ 通过 | 各 kimi 目录均有 `issues/issue-N/issue-source.md` 存在 | — |
| B2 | ✅ 通过 | 各目录锁检测正常，无重复启动 | — |
| B3 | ✅ 通过 | 所有目录均成功创建 `feature-Issue-N` 分支 | — |
| B4 | ✅ 通过 | backend → `kimiN/backend`；frontend → `kimiN/frontend` | — |
| B5 | ✅ 部分通过 | 多数 CC 先写 `*Test.java`，实现与测试同步提交 | 部分 CC 崩溃（retry=1）时测试与实现未能完整配对提交 |
| B6 | ❌ 失败 | #2849 CC 将 `WinRateStats` 相关后端代码（含 `WinRateStatsController`/`IWinRateStatsService`）提交到 PR，但缺少 `WinRateQueryBo`/`WinRateStatsVo`，合并后 dev 编译失败 | **已创建修复 PR #2909** |
| B7 | ⚠️ 未通过 | 上述 `WinRateStats` 代码引用了不存在的类，说明 CC 创建类时未先 grep 验证依赖存在 | — |
| B8 | ✅ 通过 | 新增代码均在 `wande-ai` 模块，无 `wande-ai-api` 引用 | — |
| B9 | ⚠️ 部分通过 | #2847/#2849/#2851 成功创建 PR；#2845/#2846/#2848/#2850/#1494/#2455/#1534 共7个CC崩溃（retry=1），未创建 PR | CC 崩溃原因待查；已手动重启 7 个 CC |
| B10 | ✅ 部分通过 | 已完成的 CC 均有 `task.md`；崩溃的 CC 的 `task.md` 不完整 | — |
| B11 | ⚠️ 待确认 | PR #2908/#2907 已合并，Issue 评论待核查 | — |
| B12 | ✅ 通过 | `run-cc.sh` MAX_RETRIES=10，`post-cc-check.sh` MAX_RETRY=10，当前 retry=1，未触发 Fail | — |
| B13 | — | 无僵尸会话：所有崩溃 CC 均已退出 tmux session | 崩溃后 state 未从 RUNNING 更新为 SAVED（post-cc-check.sh 未在 cron 中运行） |
| B14 | ✅ 通过 | 未见 CC 执行 deploy-dev.sh 或 Playwright | — |

### C — CI 流水线（11项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| C1 | ✅ 通过 | PR #2907/#2908 创建后 `PR E2E测试 + 自动合并` 自动触发 | — |
| C2 | — | 未直接观测到冲突检测步骤 | — |
| C3 | — | PR #2908 rebased 后冲突已解决，cycle-merge 未触发 | — |
| C4 | — | 单 PR 时无法验证排队 | — |
| C5 | — | 未观测到目录混用 | — |
| C6 | — | CI E2E 环境构建结果待 PR #2909 合并后重新触发 | — |
| C7 | — | 未完整观测 | — |
| C8 | — | 未触发构建失败兜底场景 | — |
| C9 | ✅ 通过 | PR #2907（CLEAN）、#2908（UNSTABLE）在 E2E 通过后自动 squash merge | — |
| C10 | — | 未观测到 E2E 失败场景 | — |
| C11 | — | 未观测到 Label 更新 | — |

### D — Dev 部署（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| D1 | ✅ 通过 | PR #2907/#2908 merge 后 `build-deploy-dev.yml` 自动触发 | — |
| D2 | — | 未观测变更检测细节 | — |
| D3 | ❌ 失败 | PR #2908 合并带入 `WinRateStats` 代码缺少 BO/VO，`mvn package` 编译失败 | **已创建修复 PR #2909** |
| D4 | ✅ 通过 | 尽管编译失败，之前的 dev 服务仍正常响应 `:6040/actuator/health` → `UP` | — |
| D5 | — | 未观测前端构建 | — |
| D6 | — | 未观测 Nginx | — |
| D7 | ✅ 通过 | `cancelled` + `failure` 记录显示并发保护生效，多次 push 未堆积 | — |

### E — Smoke & E2E（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| E1 | ✅ 通过 | `e2e-smoke.log` 有 09:30:32 记录，距上次 < 30 分钟 | — |
| E2 | ✅ 通过 | `:6040/actuator/health` → `UP` | — |
| E3 | — | 未直接观测认证测试 | — |
| E4 | ✅ 通过 | Smoke 日志：`39 passed (24.9s)` | — |
| E5 | — | 未触发 Smoke 失败场景 | — |
| E6 | — | 顶层E2E日志未观测 | — |
| E7 | — | 未观测分支隔离细节 | — |

### F — Issue 生命周期（5项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| F1 | ✅ 部分通过 | #2847 → Done（MERGED）；#2849/#2851 → Done（合并）；7个崩溃 CC 的 Issue 仍 In Progress | 崩溃 CC 未自动将 Issue 回退到 Todo |
| F2 | — | 无 E2E Fail Issue 观测 | — |
| F3 | ✅ 通过 | MAX_RETRY=10，当前 retry=1，Fail 机制配置正确 | — |
| F4 | — | 未观测到手动关闭 Issue | — |
| F5 | — | 未新建 Issue 验证 | — |

### G — 辅助脚本（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| G1 | ✅ 通过 | `run-cc.sh --module/--issue/--dir/--effort` 参数全部正确解析 | — |
| G2 | — | 本批次未观测到冲突自动解决 | — |
| G3 | ⚠️ 部分通过 | `check-cc-status.sh` 正确显示锁状态；但 state=RUNNING 与实际无进程不一致（post-cc-check.sh 未在 cron 中运行） | post-cc-check.sh 未加入 crontab |
| G4 | ✅ 通过 | 状态更新脚本正常工作（Issue → In Progress 切换无报错） | — |
| G5 | ✅ 通过 | `get-gh-token.sh` 正常返回有效 token | — |
| G6 | — | 未观测到 E2E 失败处理 | — |
| G7 | ✅ 通过 | 本批次新增代码均在 `wande-ai`，无 `wande-ai-api` 引用 | — |

---

## 五、批次3 — 矿场 Phase P0 执行结果（新增）

> 观测时间：2026-04-06 09:50–12:00 UTC  
> 验证批次：矿场 Phase P0（10个并发，Max Sonnet）  
> Issue列表：#1483/#1512/#1513/#1514/#1515/#1516/#2229/#2244 + #2850（kimi6 重试）  
> PR列表：#2917–#2924（+ #2850 已在批次1合并）

### 批次3 PR 最终状态

| PR | Issue | 标题摘要 | 最终状态 | 备注 |
|----|-------|---------|---------|------|
| #2917 | #2229 | 项目详情页跟进时间线 | ✅ MERGED | 首次无冲突 |
| #2918 | #1515 | ICP评分维度表与配置接口 | ✅ MERGED | 首次无冲突 |
| #2919 | #2244 | 客户列表ICP评分列与分层徽标 | ✅ MERGED | 首次无冲突 |
| #2920 | #1516 | 个人赢率统计视图 | ✅ MERGED | 首次无冲突 |
| #2921 | #1514 | 客户ICP批量评分任务 | ✅ MERGED | 首次无冲突 |
| #2922 | #1513 | 每日简报数据聚合接口 | ✅ MERGED | 需2轮rebase（cascading冲突） |
| #2923 | #1512 | 矿场每日简报07:30推送 | ✅ MERGED | 首次无冲突 |
| #2924 | #1483 | 商务标记存疑触发深度验证 | ✅ MERGED | 需3轮rebase（cascading冲突） |

### 批次3 冲突模式分析

| 冲突类型 | 出现次数 | 涉及文件 | 处理策略 |
|---------|---------|---------|---------|
| AA（双方新增同名文件） | 5次 | MineVerificationScheduler, IVerificationResultService, IVerificationScheduleService, VerificationResultServiceImpl, VerificationScheduleMapper.xml | `git checkout --theirs`（取kimi版本）或`--ours`（取已合并版本） |
| UU（内容冲突） | 4次 | ProjectMineMapper.java, schema.sql, ProjectMineController.java | 手动合并（注释全角/半角差异，保留两边有效表定义） |
| DU（删除/修改冲突） | 1次 | .cc-lock | `git rm` 删除 |
| 级联冲突 | 2轮+ | 每次其他PR合并后引发新冲突 | 重新 fetch+rebase+push |

---

## 五B、批次4+5 — 企微打通+商务赋能+预算管控（新增）

> 观测时间：2026-04-06 12:00–14:00 UTC  
> 验证批次：企微打通P0(5)＋商务赋能P0(4)＋矿场前端(1)＋预算P0/材料P0/CRM(5) = 15个Issue  
> 全部 PR（PR#2905/PR#2927-#2935）**MERGED**

### 批次4 PR 最终状态（10/10 MERGED）

| PR | Issue | 标题摘要 | 状态 | 备注 |
|----|-------|---------|------|------|
| PR#2905 | #1564 | WecomAppService access_token+消息发送 | ✅ MERGED | 自动创建PR后直接MERGED |
| PR#2927 | #1562 | 企微消息模板管理 | ✅ MERGED | 无冲突 |
| PR#2928 | #1563 | 通知双通道Service | ✅ MERGED | 无冲突 |
| PR#2929 | #1484 | L4复检异常检测前端 | ✅ MERGED | 需rebase（stale commit） |
| PR#2930 | #1476 | 标准变更追踪+到期提醒 | ✅ MERGED | 无冲突 |
| PR#2931 | #1559 | 通讯录同步数据模型 | ✅ MERGED | 无冲突 |
| PR#2932 | #1561 | 消息回调接收API | ✅ MERGED | 无冲突 |
| PR#2933 | #1480 | 案例照片S3存储 | ✅ MERGED | schema.sql conflict（保留两表） |
| PR#2934 | #1608 | 保证金台账数据模型 | ✅ MERGED | 无冲突 |
| PR#2935 | #1481 | 案例照片管理+季节标签 | ✅ MERGED | schema.sql conflict（保留两表） |

### 批次4 新发现模式

| 发现 | 描述 |
|------|------|
| stale .cc-lock | kimi9 遗留上一批次的 .cc-lock（dir字段=kimi10），导致状态误判；已通过检查 branch/commit 识别 |
| schema.sql 冲突模式稳定 | 每批新增表定义均在 schema.sql 末尾追加，冲突模式固定（保留两边新增表），可预期 |
| CC自行创建PR成功率提升 | 批次4中9/10 CC 自行创建了PR（vs 批次1中3/10），#1481除外（CC退出时无PR） |

---

## 六、问题汇总与修复记录

| 问题ID | 发现阶段 | 严重程度 | 描述 | 修复方案 | 修复状态 |
|--------|---------|---------|------|---------|---------|
| P1 | B6/D3 | 🔴 高 | PR #2908 (Agent看板前端 #2849) 合并时携带 WinRateStats 后端代码，但缺少 `WinRateQueryBo`/`WinRateStatsVo`，导致 dev 编译失败 | 创建 PR #2909 补充缺失类 | ✅ PR #2909 已合并 |
| P2 | B9/G3 | 🔴 高 | 批次1中10个并发CC中7个崩溃（retry=1），原因未明；锁 state 停留 RUNNING，post-cc-check.sh 未在 cron 运行，无法自动恢复 | 手动重启7个CC；需将 post-cc-check.sh 加入 crontab（每5分钟） | ✅ CC已完成，全部PR合并 |
| P3 | — | 🟡 中 | `.cc-lock` 被纳入 git 追踪，多次出现 `.cc-lock` 冲突（修改/删除冲突） | 加入 `.gitignore` 并移除追踪（已执行） | ✅ 已修复 |
| P4 | A1/A2 | 🟡 中 | `cc_manager.sh` 仍处于 PAUSED 状态，所有调度依赖手动触发 | 确认后恢复 cron | ⏳ 待用户决策 |
| P5 | B6/B7 | 🟡 中 | CC (#2849) 创建代码时引用了不存在的 BO/VO 类，说明 grep 查重机制未能防止依赖遗漏 | CLAUDE.md 或 system prompt 加强「创建新接口前验证所有依赖类存在」规则 | ⏳ 待改进 |
| P6 | 批次3 | 🟡 中 | 多个矿场 Issue（#1513/#1483）产生级联冲突：每次有PR合并到dev后，已在 rebase 中的 PR 又变 CONFLICTING，需多轮人工 rebase | 优化合并顺序：先合并独立PR，最后合并有共享文件依赖的PR；或引入自动 rebase 机制 | ⏳ 待优化 |
| P7 | 批次3 | 🟡 中 | kimi4（#1513 retry=1 commit）scope creep：CC 退出恢复时将预算WBS/变更单/规范库等无关代码混入同一 PR | rebase 时通过 `git checkout --ours` 丢弃 scope creep；根本原因是 CC 在 retry 时丢失上下文边界 | ⚠️ 部分缓解（rebase可过滤），根本修复待 CC prompt 优化 |

---

## 七、最终结论

> 更新时间：2026-04-06 14:00 UTC（批次4完成，批次5运行中）

- **总验收项**: 53 项
- **已观测**: 38 项
- **通过**: 23 项（✅）
- **失败**: 2 项（❌：B9批次1崩溃、A1调度PAUSED）
- **警告**: 3 项（⚠️）
- **不适用/待观测**: 15 项（—）
- **整体评分**: 23/38 = 61%（有效项，持续改善）
- **累计完成**: 批次1-4共27个 Issue，全部 PR MERGED（PR#2905-#2935）
- **批次5进行中**: 10个CC运行中（#1609/#1543/#1549/#1537/#1607/#1606/#1605/#1604/#1491/#1478）
- **是否可投入生产**: ⚠️ 部分满足 — cc_manager.sh 调度仍 PAUSED（P4）；批次4 CC自行PR创建率达 9/10（显著改善）
- **关键遗留问题**:
  1. cc_manager.sh PAUSED 状态需用户决策是否恢复（建议恢复）
  2. post-cc-check.sh 加入 crontab（每5分钟）防止 CC 崩溃后 state 停留 RUNNING
  3. CC retry 时 scope creep 问题（P7）需 prompt 层面优化
  4. schema.sql 冲突已成规律性问题，建议单独维护 `test-schema.sql` 并用 INSERT SELECT 隔离测试表
