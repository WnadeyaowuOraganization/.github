# 新 Harness 工作流验证报告

> **生成时间**: 2026-04-06  
> **架构基准**: status.md 重大决策 D1–D44（截至 2026-04-05）  
> **验证范围**: 完整自动化研发流水线（排程→编程CC→CI→合并→发布→E2E）  
> **验证 Issue**: #2893 Claude Office全量迁移-P0（已加入 Project#4 Todo 列最前方）  
> **状态**: ⏳ 预期验收项已生成，等待用户确认后开始执行验证  
>
> **⚠️ 架构注意**:  
> - `wande-ai-api` 子模块**已废弃**（D44，PR#2593），所有业务代码在 `wande-ai`  
> - 编程CC **不做** dev 环境部署（D31），只做 TDD + 编译检查 + PR 创建  
> - PR 由编程CC第三阶段**自行创建**（D11，`gh pr create --base dev`）  
> - 中层E2E 已改为**纯脚本 Smoke**（D33，`e2e_smoke.sh`），非AI驱动

---

## 一、流水线架构总览（基于 status.md 实际流程图）

```
研发经理CC（每10分钟，cc_manager.sh）
    │
    ├─ 任务一: 排程  Plan → Todo（按优先级/Sprint）
    └─ 任务二: 触发  Todo → In Progress
                        │
                        ▼
          run-cc.sh --module <m> --issue N --dir kimiX --effort <e>
          工作目录: wande-play-kimiX/（带后缀，主目录禁止）
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
| A3 | 防重复锁生效 | 上轮未完成时日志显示"跳过"，不并发启动 | 并发运行多个 manager |
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
| B12 | 最大重试3次（D43） | 超过3次失败后标 Fail，不再重试 | 无限重试 |
| B13 | 超时20分钟自动清理（D43） | 无响应超20分钟时 tmux session 被强制关闭 | 僵尸session残留 |
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

### 触发链路（#2893 为主验证 Issue）

```
Issue #2893 (Todo, 看板最前方)
    → 研发经理CC 下一个10分钟周期
    → run-cc.sh --module app --issue 2893 --dir kimiX --effort high
    → 编程CC: TDD → compile → gh pr create --base dev
    → pr-test.yml: build CI环境 → Playwright E2E → squash merge
    → build-deploy-dev.yml: mvn package + pnpm build → 部署 :6040/:8083
    → e2e_smoke.sh: 下一个30分钟周期 smoke 验证
```

---

## 四、执行结果记录

> 此区域在确认后填写

### A — 研发经理CC调度（9项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| A1 | | | |
| A2 | | | |
| A3 | | | |
| A4 | | | |
| A5 | | | |
| A6 | | | |
| A7 | | | |
| A8 | | | |
| A9 | | | |

### B — 编程CC执行（14项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| B1 | | | |
| B2 | | | |
| B3 | | | |
| B4 | | | |
| B5 | | | |
| B6 | | | |
| B7 | | | |
| B8 | | | |
| B9 | | | |
| B10 | | | |
| B11 | | | |
| B12 | | | |
| B13 | | | |
| B14 | | | |

### C — CI 流水线（11项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| C1 | | | |
| C2 | | | |
| C3 | | | |
| C4 | | | |
| C5 | | | |
| C6 | | | |
| C7 | | | |
| C8 | | | |
| C9 | | | |
| C10 | | | |
| C11 | | | |

### D — Dev 部署（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| D1 | | | |
| D2 | | | |
| D3 | | | |
| D4 | | | |
| D5 | | | |
| D6 | | | |
| D7 | | | |

### E — Smoke & E2E（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| E1 | | | |
| E2 | | | |
| E3 | | | |
| E4 | | | |
| E5 | | | |
| E6 | | | |
| E7 | | | |

### F — Issue 生命周期（5项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| F1 | | | |
| F2 | | | |
| F3 | | | |
| F4 | | | |
| F5 | | | |

### G — 辅助脚本（7项）

| # | 状态 | 实际行为 | 发现问题 |
|---|------|---------|---------|
| G1 | | | |
| G2 | | | |
| G3 | | | |
| G4 | | | |
| G5 | | | |
| G6 | | | |
| G7 | | | |

---

## 五、问题汇总与修复记录

| 问题ID | 发现阶段 | 严重程度 | 描述 | 修复方案 | 修复状态 |
|--------|---------|---------|------|---------|---------|
| — | — | — | — | — | — |

---

## 六、最终结论

> 等待验证完成后填写

- **总验收项**: 53 项
- **通过**: —  
- **失败**: —  
- **忽略/不适用**: —  
- **整体评分**: —  
- **是否可投入生产**: —  
- **遗留问题**: —
