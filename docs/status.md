# 万德AI平台 · 项目状态

> ⏰ 最后更新：2026-04-10 00:00 by Perplexity
> 📚 功能注册表：[`docs/feature-registry.md`](../docs/feature-registry.md) — 42个模块·1200个Issue全景索引
---
## 🔄 Issue 生命周期 + 测试层级

### 完整流程图

```
Issue创建
  │ issue-sync.yml (opened) → 加入Project#4 → [Plan]
  ▼
[Plan] ──── 排程经理CC ────▶ [Todo]
            依赖分析           │
            维护PLAN.md        │ 研发经理CC
                               │ run-cc.sh --module --issue --dir --effort
                               ▼
                           [In Progress]
                               │
                               ▼ 编程CC（tmux会话 cc-wande-play-kimiN-ISSUE）
                    ┌──────────┴──────────┐
                    ▼                     ▼
              单元测试(TDD)          编译检查
              mvn test / vitest      mvn package / pnpm build
                    │                     │
                    ▼                     ▼
               ❌ 失败 → 自行修复    ❌ 失败 → 自行修复
                    │                     │
                    └──────── 全通过 ──────┘
                                  │
                                  ▼
                           push feature分支
                           gh pr create --base dev
                           CC轮询等待merge或新指令（不主动退出）
                                  │
    ══════════════════════════════╪══════════════════════════════
    CI层 (pr-test.yml)            │  PR创建/更新自动触发
    ══════════════════════════════╪══════════════════════════════
                                  ▼
                      CI专用环境构建(:6041/:8084)
                                  │
                         ┌────────┴────────┐
                         ▼                 ▼
                    构建成功          ❌ 构建失败
                         │                 │ inject-cc-prompt.sh
                         ▼                 ▼ 注入修复提示词到活跃CC
                   Playwright E2E     + [E2E Fail]
                   tests/backend/
                   tests/front/
                         │
                   ┌─────┴─────┐
                   ▼           ▼
                ✅ 通过     ❌ 失败
                   │           │ inject-cc-prompt.sh
                   ▼           ▼ 注入修复提示词到活跃CC
              approve PR    + status:test-failed
              squash merge  + [E2E Fail]
                   │
    ══════════════════════════════════════════════════════════════
    CD层 (build-deploy-dev.yml)  merge到dev触发
    ══════════════════════════════════════════════════════════════
                   │
                   ▼
              后端: mvn package → 部署 → 健康检查
              前端: pnpm build → rsync → nginx reload
                   │
                   ├── ❌ 部署失败 → inject-cc-prompt.sh 注入修复提示词
                   ▼
              Dev环境更新完成(:6040/:8083)
                   │
                   ├─► cc-lock-manager.yml → release-cc-lock.sh
                   │                         (kill tmux session + rm .cc-lock)
                   │
                   └─► issue-sync.yml (PR merged → close Issue)
                                  ▼
                               [Done]
                   │
    ══════════════════════════════════════════════════════════════
    Smoke探活 (e2e_smoke.sh)  cron每30分钟，零AI消耗
    ══════════════════════════════════════════════════════════════
                   │
                   ▼
              curl健康检查 + Playwright smoke
                   │
                   ├── ✅ 通过 → 静默
                   └── ❌ 失败 → e2e-result-handler.py
                                 自动创建Issue + [E2E Fail]
                   │
    ══════════════════════════════════════════════════════════════
    全量回归 (e2e_top_tier.sh)  cron每6小时，AI驱动
    ══════════════════════════════════════════════════════════════
                   │
                   ▼
              regression/ + 全部smoke + API
                   │
                   ├── ✅ 通过 → 记录日志
                   └── ❌ 失败 → AI智能创建Issue（判断模块+写描述）
                                 + e2e-result-handler.py + [E2E Fail]
```

### 测试层级总览

| 层级 | 触发 | 范围 | 实现 | AI消耗 | 失败处理 |
|------|------|------|------|--------|----------|
| 单元测试 | 编程CC TDD | 当前Issue涉及的Service | mvn test / vitest | 无 | 编程CC自行修复，不提PR |
| 编译检查 | 编程CC提交前 | 全量编译 | mvn package / pnpm build | 无 | 编程CC自行修复，不提PR |
| CI E2E | PR创建/更新 | PR影响的模块 | pr-test.yml + e2e-result-handler.py | 无 | 评论PR/Issue + test-failed + E2E Fail |
| Smoke探活 | cron 30min | health + auth + 页面smoke | e2e_smoke.sh + e2e-result-handler.py | **无** | 自动创建Issue + test-failed + E2E Fail |
| 全量回归 | cron 6h | regression + 全模块 | Claude Code + e2e-result-handler.py | 有 | AI创建Issue + test-failed + E2E Fail |

### Project#4 状态流转

```
[Plan] → [Todo] → [In Progress] → [Done]     (正常路径)
                        │              │
                        ▼              ▼
                    [E2E Fail] ◀── CI/Smoke/回归发现失败
                        │
                        ▼ 排程经理优先排程
                    [In Progress] → 修复 → 重新提PR → [Done]
```

以上内容除非得到用户批准不可擅自修改
---


## 🚨 2026-04-07 / 2026-04-08 / 2026-04-09 重大基础设施变更

### 阶段七（2026-04-09 上午）：Maven 缓存 tmpfs 隔离 + 共享 base + 全脚本接入

| 项 | 详情 |
|---|---|
| 触发 | 排查 PR pre-test 全失败时发现 dev 后端 bean/编译错累积。深挖发现根因之一是 maven cache 跨 kimi 污染：20 个 `.m2-kimi*/repository` 之前用 `cp -al ~/.m2 .m2-kimiN` hardlink 共享，实测 `_remote.repositories` 等元信息文件 21 个 hardlink 同 inode → 一个 kimi 改影响所有兄弟 |
| 实证 | append `POLLUTED-FROM-KIMI1` 到 `.m2-kimi1/.../_remote.repositories` → kimi5 + 主 ~/.m2 立刻看到该字符串。jar 文件因 mvn 是 unlink+create 模式 OK，但元信息文件是 truncate-and-write → 跨 kimi 同步污染 |
| 4 类风险 | A. 元信息互污染（必发生）；B. `*.lastUpdated` 误标记导致跨 kimi 误判依赖不可用；C. 两 kimi 同时 mvn install 同一 SNAPSHOT 造成 jar partial write；D. 一个 CC 跑 `mvn dependency:purge` 让所有 kimi hardlink 兄弟丢数据 |
| 方案演化 | 先尝试系统级 fstab + systemd tmpfs mount（fstab 23 条 + m2-prewarm@.service 模板 + /usr/local/bin/m2-prewarm.sh）→ 用户判断"改动太大、未来迁移到小 RAM 服务器不一定有这么大 RAM" → 全部撤销 |
| **7.1 最终方案：脚本级 + /dev/shm tmpfs + 共享 base** | (a) 持久化 base 在磁盘 `~/.m2-base/repository` (586MB，预先 mvn clean install dev 后删除自产 jar `wande-ai/wande-ai-api/ruoyi-admin/ruoyi-mcp-server/copilot` 共 -437MB)；(b) `/dev/shm/m2-base/repository` 共享只读，第一个 CC 启动时 cp 进去；(c) `/dev/shm/m2-cc-<KIMI>/repository` 每 CC 独立写入区，cp -a base 进去；(d) refcount 文件管理 base 的引用计数，最后一个 CC 退出时自动释放 base |
| **7.2 新增脚本** | `scripts/m2-cc-prepare.sh` (62 行)：KIMI_TAG → 准备 tmpfs repo，stdout 输出 MAVEN_OPTS 给 caller export；`scripts/m2-cc-cleanup.sh` (50 行)：rm cc 区 + refcount-1 + 全退后释放 base。两个脚本用 `flock` 互斥避免 race |
| **7.3 .cc-lock 新增 m2_repo 字段** | run-cc.sh 把 maven repo 路径写入 lock 文件 (`m2_repo=/dev/shm/m2-cc-kimiN/repository`)；release-cc-lock.sh 优先从 lock 读路径 rm tmpfs，按 KIMI_TAG 兜底 |
| **7.4 全脚本/CI 接入** | (a) `scripts/run-cc.sh` 调 prepare 注入 tmux MAVEN_OPTS；(b) `scripts/release-cc-lock.sh` 调 cleanup；(c) `scripts/ci-env.sh` mvn clean package 前 prepare(`tag=ci-pr-${PR_NUM}`) + 后 cleanup；(d) `wande-play/.github/workflows/pr-test.yml` unit-test job(`tag=ci-unit-pr-${PR_NUM}`) + build job(`tag=ci-build-pr-${PR_NUM}`)；(e) `build-deploy-dev.yml` Maven编译打包(`tag=dev-deploy`) |
| 隔离验证 | (1) 改 cc1 的 jar 内容，cc2/base 完全不受影响 ✅ (2) 真实 mvn install wande-ai-api 18s SUCCESS，jar 写到 cc 区，base 不被污染 ✅ (3) prepare 2 个 CC → refcount=2 → cleanup 第一个 → refcount=1 → cleanup 最后一个 → base 自动释放 ✅ (4) lock m2_repo 字段写入 + cleanup 读取 ✅ |
| 资源对比 | 之前：1.1GB 假隔离（hardlink，元信息全共享，污染）；现在：586MB base + N × 586MB cc 区，15 并发 ≈ 9.4GB，/dev/shm 总 250GB 无压力 |
| 未来迁移到小 RAM 服务器 | 改 m2-cc-prepare.sh 第 23/24 行 `/dev/shm/m2-base` → `/tmp/m2-base`、`/dev/shm/m2-cc-${KIMI_TAG}` → `/tmp/m2-cc-${KIMI_TAG}` 即可，从 tmpfs 切到磁盘，**一处 2 行修改**，其他逻辑完全不动 |
| commits | `.github` `125e0a3` (m2-cc-prepare/cleanup + run-cc.sh + release-cc-lock.sh + lock m2_repo) + `c3634b2` (ci-env.sh)；`wande-play` `b3f638f07` (pr-test.yml × 2 + build-deploy-dev.yml × 1) |

### 阶段六（2026-04-09 凌晨）：.cc-lock 物理迁移 + GH token 自动刷新 + inject race 修复

| 项 | 详情 |
|---|---|
| 触发 | 14 个 CC 全部"假卡死"。根因调查发现三层叠加问题:(1) GH App installation token TTL 1h 过期、各 CC tmux env 内的 GH_TOKEN 是 fork 时快照无法热更;(2) inject-cc-prompt.sh 的 paste-buffer 与 send-keys Enter 之间没 sleep,导致 prompt 被粘贴但没提交;(3) 13 个 kimi 目录的 .cc-lock 内容完全相同(都是 issue=2893 dir=kimi1) — 因为历史 commit `66a3067c1` 把 .cc-lock 误带进 git,fc57f49c7 cleanup 不彻底,后续 PR merge 反复把 .cc-lock 加回 dev,各 kimi git pull 时同步污染 |
| **6.1 GH token 自动刷新** | 新建 `scripts/refresh-gh-token.sh`(写 hosts.yml + /tmp/.gh-token.env + 给所有 cc-/manager-/e2e- tmux 会话 set-environment GH_TOKEN);加 cron `*/45 * * * *`,留 15 分钟余量;立即跑了一次解了当前 401 |
| **6.2 inject 修复** | `scripts/inject-cc-prompt.sh` 在 paste-buffer 和 send-keys Enter 之间加 `sleep 0.5`;给 8 个之前卡着 [Pasted text] 的 CC 补 Enter 全部恢复 |
| **6.3 .cc-lock 物理迁移** | 所有 lock 从 kimi 目录的 working tree 迁出到 `/home/ubuntu/cc_scheduler/lock/<dirname>.lock`,9 个文件从原位置 mv,5 个被 cc-keepalive 误删的从 tmux session 重建。改动 9 个代码文件:`scripts/run-cc.sh` `cc-keepalive.sh` `cc-check.sh` `release-cc-lock.sh` `inject-cc-prompt.sh` `post-task.sh`、`/opt/claude-office/api/server.py`(4 处 lock 路径)、`wande-play/.github/workflows/issue-sync.yml`(PR merged 释放 lock 的 fs 路径) |
| **6.4 dev 污染清理** | `wande-play` 主仓 commit `3aaa8667b` `git rm .cc-lock + push origin dev`(从 dev HEAD 移除污染源)+ commit `f2abaefbc` 修 issue-sync.yml workflow 路径 |
| **6.5 lock module 推断 + 命名重写** | 14 个 lock 用 tmux session 名作权威源重写(`cc-wande-play-kimiN-ISSUE` → dir=kimiN issue=ISSUE),module 用 `git diff origin/dev..HEAD --name-only` 推断 |
| **6.6 6 个 kimi 目录 git rm --cached .cc-lock** | 把 .cc-lock 从 git index 移除,staged for deletion 状态等 CC 自然 commit 一起进 PR |
| **6.7 保留 history** | 用户决定不做 history rewrite(避免破坏 14 个 active CC 的 feature 分支 + 所有 open PR);历史中的 .cc-lock 作为档案保留无害 |
| **附带修复:孤儿 server.py** | 发现 server.py 端口 9872 被一个跑了 4h56m 的孤儿 python 进程占着导致 systemctl restart 一直 fail。kill 后 service 恢复 |
| **未做的事(等用户处理)** | (a) wande-play-kimi1 仍处于 merge in progress(另一个会话在解决 pr-test.yml conflict,与本次无关);(b) kimi9 死锁(API message 损坏 + git remote 配置丢失,需 kill + run-cc.sh 重启);(c) kimi5 branch 名异常 `feature-Issue-2008-v2` |
| commits | wande-play `3aaa8667b` (cc-lock cleanup) + `f2abaefbc` (issue-sync.yml workflow 修复) + .github 待提交 |
| 实测 | `/api/status` 返回 18 agents 全部从新 lock 路径正确读取 module/effort/state;cron `*/45` token 刷新 + cron `*/5` cc-keepalive 已分别用新路径运行 |

### 阶段五（2026-04-08 夜）：研发经理 token 优化 + Done 硬隔离 + 进度估算

| 项 | 详情 |
|---|---|
| 触发 | 研发经理每轮巡检 tmux capture-pane × N 个 CC ≈ 70k tokens/轮 ≈ 10M/天，原始日志噪声大、LLM 重复劳动 |
| 改造目标 | token 降 ~89%，质量不降反升，让 CC 自监控、研发经理只处理 attention case |
| **5.1 进度估算** | server.py `_estimate_progress` 多源回退：PR > lock state > TodoWrite > Phase 标题 > effort 兜底；前端卡片显示 `via X` 标明可信度 |
| **5.2 标签统一** | 像素小人/卡片主标签按 repo 名 `-` 切片最后一节(`wande-play-kimi4 → kimi4`)；REPO_COLORS 简化只保留 fill/light；Proxy 自动 fallback；server.py 修正 `_scan_play_sessions` 返回真实 dirname |
| **5.3 PR 计数展示** | active-count 徽章追加 `N 个PR待处理`；后端共享 30s 缓存的 pr_index，0 额外 GitHub 调用 |
| **5.4 Done 硬隔离** | `update-project-status.sh` 内置 Done Guard：`--status Done` 时强制 `gh pr list` 校验 issue 关联 PR 的 mergedAt 非空，否则 exit 2；`FORCE_DONE=1` 仅限超管绕过；assign-guide.md 同步更新 |
| **5.5 排程经理切 Haiku 4.5** | run-manager.sh 加 MODEL 参数；排程经理用 `claude-haiku-4-5-20251001`(任务结构化强、清单驱动)；研发经理本阶段保持 sonnet，5.7 后切 Haiku |
| **5.6 W1: post-task summary 纯规则版** | post-task.sh Step 5 追加：push 后用 git stat + .cc-lock + gh pr 抽硬数据写 `post-task-summary.json`(schema_version=1, fallback=true)；**主路径与 task.md 同级**(`issues/issue-N/`),自动 `git add+commit+push [skip ci]` 进 feature 分支跟随 task.md 生命周期；TASK_FILE 缺失时 fallback 到 `.github/post-task-summaries/`;不阻塞主流程 |
| **5.7 W2: needs_attention 规则引擎** | server.py `/api/status` 新增字段 `silent_minutes` / `pr_summary` / `lock_state` / `needs_attention` / `attention_reason`；规则：silent>120 兜底升级、PR+silent<30 自监控不打扰、无PR+silent>30 卡住；不调 LLM |
| **5.8 W3: 任务二改 attention-only** | assign-guide.md 任务二完全重写：先 `curl /api/status \| jq 'select(.needs_attention)'`，只对返回的 0~3 个 CC 做精细 capture/inject；旧的全场扫保留为兜底 |
| 后续 W4-W7 | 见 [docs/workflow/2026-04-08-manager-token-optimization.md](workflow/2026-04-08-manager-token-optimization.md):lock 状态机扩展 / Haiku summary 升级 / 任务四验收报告改造 / cc-self-check cron 兜底 |
| 实测效果 | 16 个活跃 CC,W3 后规则引擎只标 1 个 needs_attention(e2e-top 静默 208m);单轮 token 预期从 ~70k 降到 ~5k(降 93%) |
| commits | (本阶段) `.github/scripts/post-task.sh`、`.github/scripts/update-project-status.sh`、`.github/scripts/run-manager.sh`、`.github/docs/agent-docs/manager/assign-guide.md`、`/opt/claude-office/api/server.py`、`/opt/claude-office/static/office.js`、`/opt/claude-office/static/style.css` |

### 阶段四（2026-04-08 晚）：CI 流程修复 + 菜单/前端路由对账

#### 4.1 CI 流程漏洞修复

| 项 | 详情 |
|---|---|
| 触发 | PR #3487 (#3458) 第一次 CI 构建失败但通知不全，inject 给 CC 的 prompt 中"失败详情："后面是空的 |
| 漏洞 1 | `ci-env.sh` mvn 用 `2>&1 \| tail -5` 屏蔽退出码 + `mvn clean` 不一定清空 target → 残留旧 jar 被 find 找到 → 用旧 jar 部署掩盖编译失败 |
| 漏洞 2 | `BACKEND_CHANGED=false` 时使用 CI 残留 jar（可能是上一个 PR 的产物），不是当前 dev 真实部署 |
| 漏洞 3 | `wait_healthy` 失败时强制重新构建掩盖问题 |
| 漏洞 4 | inject-cc-prompt.sh 只查 .cc-lock，lock 已删但 session 还在时找不到，找不到 exit 0 静默 |
| 漏洞 5 | test-failed 的失败详情只读 `summary.md`（playwright 报告），构建失败发生在 playwright 之前 → 详情为空 |
| **核心决策** | 删除 `scripts/ci-env.sh` (197 行)，逻辑全部内联到 `.github/workflows/pr-test.yml` 的 build job 中 9 个独立 step |
| 内联收益 | mvn/pnpm 输出实时进 Actions 日志流（`::group::` 分组），CC 可通过 `gh run view --log-failed` 实时拉取，不再有黑盒包装 |
| build job 拆分 | 检测变更 → 拉取代码 → 构建后端 jar (backend 变更时) → 复用 dev jar (无变更时) → 构建前端 dist → 复用 dev dist → 停旧 → 启动 → 健康检查 |
| inject-cc-prompt 增强 | 三层 fallback (.cc-lock → tmux 精确匹配 → 包含 -N 后缀)、找不到 exit 3、改用 `tmux load-buffer + paste-buffer` 注入避免 shell 解析特殊字符、新增 `--prompt-file` 支持长 prompt |
| test-failed 增强 | 通过 `gh api repos/.../actions/jobs/$ID/logs` 实时拉取失败 step 完整日志（grep ERROR 行 + tail 100 行）、附 Actions 完整日志 URL、覆盖 unit-test/build/e2e 任一 job 失败 |
| commits | `.github` 16cac17 + `wande-play` ff0fa3d13 |

#### 4.2 gh-app-token.py fallback PAT 失效

| 项 | 详情 |
|---|---|
| 触发 | kimi10 编程 CC 报 `HTTP 401: Bad credentials` 调 gh API |
| 根因 | `weiping.pat` 已失效（401），但 `gh-app-token.py` 在 `check_graphql_remaining()` urllib 瞬时失败时返回 0 → 触发 fallback 到死 PAT |
| 修复 | (1) `check_graphql_remaining` 加 timeout=5 + 3 次重试，失败返回 -1 而非 0；(2) main() 改为 `> 100 or == -1` 才用 App token 保守保留；(3) fallback 改用已验证有效的 `wandeyaowu.pat` |
| commit | `.github` 待提交（同次菜单工作链中） |

#### 4.3 cc-check.sh 整数比较错

| 项 | 详情 |
|---|---|
| 触发 | `cc-check.sh:82 [: : integer expression expected` |
| 根因 | `pr_count=$(gh pr list...)` 在 gh 失败时返回空字符串，`[ "" -gt 0 ]` 报错 |
| 修复 | `[ "${pr_count:-0}" -gt 0 ]` |
| commit | `.github` 待提交 |

#### 4.4 菜单表 vs 前端路由对账与修复

| 项 | 详情 |
|---|---|
| 数据源 | dev `ruoyi_ai.sys_menu` (86 个 C 型菜单) + `frontend/apps/web-antd/src/views/**` + `routes/modules/*.ts` 静态路由 |
| 问题 1 | menu 100「用户管理」component 错指 `system/user/index`（vue 不存在），实际页面在 `operator/user/index` → 点击 404 |
| 问题 2 | 42 个 wande/* 业务页面已合并 PR 但未注册菜单（D3/安全/工作流/财务/CRM/dealer/budget...）|
| 问题 3 | 4 组真重复菜单（同 vue 引用 2 次）：30002↔20600 Issue看板, 30003↔20603 验收中心, 30005↔20104 我的项目, 20505↔20503 G7e监控/系统监控 |
| 问题 4 | 5 组前端静态路由 name 与后端动态菜单 name 冲突 → vue-router 重名导致后注册的动态路由被静默忽略 → 用户访问 404 |
| 问题 5 | 82 个菜单从未授权给任何角色（包括 superadmin role_id=1）；不过 admin 用户 (user_id=1) 走 `LoginHelper.isSuperAdmin(userId)` bypass 自动看到全部，所以这条对 admin 用户无影响，但对其他角色有影响 |
| 问题 6 | `types.ts` 因之前 `git merge-file --union` 自动合并 PR 冲突时拼接两个 interface，导致 `ProjectMineFunnelTrend` 缺少闭合 `}`，前端构建失败 |
| 修复 SQL | `V20260408_2__menu_route_recon.sql` UPDATE 1 + INSERT 39 (3 父目录 + 36 叶子) ；`V20260408_3__menu_dedup.sql` DELETE 4 menu + 3 role_menu；`V20260408_4__menu_role_grant.sql` INSERT 100 (role 1) + 124 (role admin) |
| 修复前端 | `routes/modules/dashboard.ts` Dashboard → DashboardRoot；`wande.ts` Wande → WandeRoot, Execution → ExecutionRoot；`monitor.ts` Monitor → MonitorRoot；`workflow.ts` Workflow → WorkflowList；`views/workflow/edit.vue` 同步改 router.push name；`views/wande/dashboard/cron-alert-rule/` 重复目录已删 |
| 修复 types.ts | 补 `ProjectMineFunnelTrend` 闭合 `}` |
| 对账后效果 | menu→vue 缺失 1→0；wande/* 孤儿 42→5（剩 5 个全是已有菜单的代码 dedup 重复，非菜单问题）；前端路由 name 冲突 5→0 |
| 已合并 commits | 941136f42 (recon) + cc8bfb853 (dedup) + 35703383e (grant) + 632d975fb (route name) + 342f55e6b (types.ts fix) |

#### 4.5 [P0][项目挖掘改版] 系列 Issue 误关审计

| 项 | 详情 |
|---|---|
| 触发 | 用户问 #3449~#3456 代码写到哪了，为什么页面看不到 |
| 真实情况 | 8 个 issue 全部 `closed/completed`，但只有 3 个真完成：#3449/#3450 PR open 未合并，#3456 文档已更新，**5 个 (#3451-3455) 完全没写代码**就被关了（#3452 kimi16 启动 CC 但 0 commit）|
| 根因 | post-task / 状态机 bug：CC 退出时把 issue 标 completed 而不验证 PR 是否真的 merged。需要后续修 `scripts/post-task.sh` 加 PR merge gate |
| 处理 | (1) 解决 #3485 的 types.ts 冲突 → squash merge 进 dev；(2) #3486 直接 squash merge；(3) #3451-3455 全部 reopen 并加注释；(4) 通知研发经理插队补做 |

#### 4.6 PR #3270 损坏关闭

| 项 | 详情 |
|---|---|
| 触发 | 自动冲突解析时发现 #3270 异常 |
| 异常 | 212 commits, +698042/-5458 lines, 4445 files —— 不是 feature PR，是 merge 灾难 |
| 处理 | 评论说明 + 关闭 PR；建议从干净 dev 重做 #2065 |

---

### 阶段三（2026-04-08 下午）：批量解决 PR 冲突 + 菜单基础设施

| 项 | 详情 |
|---|---|
| 触发 | Flyway/test 基础设施落地后，49 个 open PR 中 44 个 CONFLICTING |
| 自动解析器 | 用 4 类规则批量解决：(A) dev 已删文件 git rm；(B) test 基础设施 (TestApplication.java/application.yml/pom.xml) sed 移除 ours hunk；(C) types.ts/requirements.txt/task.md union merge；(D) modify/delete 与 add/add 按 stage 解析 |
| base ref 修正 | 9 个 PR 错把 base 设为 `main`，用 PATCH 改为 `dev` |
| 自动解决 | 22 个 PR 冲突自动消除 |
| 批量 merge | iterative loop：resolve → merge mergeable → 等 GitHub recompute → 重复，最终 squash merge **34 个 PR** |
| 关闭 | #3270（212 commits / 4445 files 的 merge 灾难）|
| 剩余 | 12-14 个真实 feature-vs-feature 代码冲突，已注入研发经理 tmux 会话由 CC 自行 rebase |

---

### 阶段一（2026-04-07）：单元测试 H2 → Docker PostgreSQL + CI 加 mvn test 关卡

| 项 | 详情 |
|---|---|
| 触发 | 调研 SCHEMA_ORDER.txt 并行冲突 → 发现 H2/PG 双套维护浪费 → 发现 dev 长期 `-Dmaven.test.skip=true` 导致 2117 个测试错误无人发现 |
| 测试 PG 容器 | `wande-test-pg` (postgres:16-alpine, 端口 5434/wande_ai/wande/wande_test) |
| 启动脚本 | `scripts/ensure-test-pg.sh`（per-kimi 独立 DB 隔离）|
| 当前基线 | **338 通过** / 2462 总测试（写入 `.test-baseline`，CI 不允许下降） |
| 历史欠债清理 | 2117 errors 拆成 20 个 issue（#3335-#3354），4 小时内 20/20 全部 closed |
| 完整记录 | [docs/workflow/2026-04-07-mvn-test-baseline.md](workflow/2026-04-07-mvn-test-baseline.md) |

### 阶段二（2026-04-08）：数据库迁移改用 Flyway 自动执行

| 项 | 详情 |
|---|---|
| 触发 | 重新冻结后发现 `wande-ai-pg.sql` 与 `test-base-schema.pg.sql` 冗余 + bash 维护的 `sql_migrations_history` 不符合 Spring 生态 |
| 引入 | `flyway-core` + `flyway-database-postgresql` 依赖 |
| 自定义配置 | `backend/ruoyi-admin/src/main/java/org/ruoyi/config/WandeFlywayConfig.java` 同时迁移 `ruoyi_ai` + `wande_ai` 两个库 |
| 迁移脚本位置 | `backend/ruoyi-modules/wande-ai/src/main/resources/db/migration_{ruoyi_ai,wande_ai}/V*.sql` |
| Baseline | `V1__baseline_2026_04_08.sql` 包含 dev PG snapshot 全量 (ruoyi_ai 62 + wande_ai 408 张表) |
| 历史 bash 脚本 | `script/sql/update/{ruoyi_ai,wande_ai}/_archive_2026-04-08/` 归档保留 |
| 删除 | `build-deploy-dev.yml` 的 `run_migrations` 函数 + `run-sql-updates.sh` 替换为 stub |
| **CC 新流程** | 写 `db/migration_wande_ai/V<日期>_<序号>__<描述>.sql`，Spring 启动时 Flyway 自动跑，**不需要任何手工同步**。详见 [db-schema.md](agent-docs/backend/db-schema.md) |
| **新环境部署** | Docker / dev / prod 启动应用即自动建表 + 跑增量，**无需任何 setup 步骤** |

---
## 🎯 Sprint 计划

> **2026-04-08 重大调整（D77）**：Sprint体系从5+Backlog重构为8个Sprint，每个Sprint有清晰主题定位。矿场核心45个Issue从Backlog移入Sprint-2；商战情报前移Sprint-3；原Backlog拆分为Sprint 6/7/8。

| Sprint | 主题 | 状态 | Issue数 | 一句话定位 | 交付物（用户能做什么） |
|--------|------|------|---------|-----------|---------------------|
| Sprint-1 | 🏗️ 基座搭建 | 🟢 进行中 | ~156 | 驾驶舱+D3+销售记录+询盘（能用） | 商务打开矿场看到项目→标记→写销售记录→你在驾驶舱看到；D3 Web端可配置电池包；询盘→报价→PI |
| Sprint-2 | 💰 商务全闭环 | ⏳ 待启动 | ~188 | 矿场发现→投标→签约→执行→审批→企微（能赚钱） | 矿场AI评分筛选→投标方案PPT→中标建项目→图纸/BOM→回款；企微审批；47个OA流程全覆盖 |
| Sprint-3 | 🎯 商战情报 | ⏳ 待启动 | ~81 | 情报中台7Phase+MEDDIC（能决策） | 行业情报+中标概率预测+竞品知识图谱+客户雷达→企微推送；MEDDIC六维度评估 |
| Sprint-4 | 📢 内容获客+数据 | ⏳ 待启动 | ~117 | 品牌自动化+多通道获客+客户生命周期+S3（能获客） | 海报/文章自动生成→审批→发布；邮件+企微+LinkedIn三通道获客；客户交付提醒+赢丢单复盘；S3数据资产挖掘 |
| Sprint-5 | 👥 组织管理 | ⏳ 待启动 | ~78 | 人事+制度+审批+报销（能管人） | 员工档案+培训管理；21个制度文档版本化；审批引擎完整版(AI预检+SLA)；报销费控全流程 |
| Sprint-6 | 💵 财务+运营 | ⏳ 待启动 | ~121 | 资金闭环+预算+提成+项目风控+库存（能管钱） | 财务对账+保证金台账；色卡在线配色→审批；仓库库存可视化；项目全景+风险台账；提成绩效考核 |
| Sprint-7 | 🤖 AI增强+知识 | ⏳ 待启动 | ~95 | 设计AI+知识库+方案引擎+对话中枢（更智能） | LoRA训练万德风格→批量渲染；知识库214国标入库；PPT方案引擎D3联动；AI跨渠道对话 |
| Sprint-8 | 🔗 生态+售后 | ⏳ 待启动 | ~113 | 企微深度+质保售后+运营中心（生态闭环） | 企微通讯录同步+会话存档；质保→工单→备件→复购CRM；业务运营看板+合同回款增强 |

---

### Sprint-1 重点模块（🟢 进行中 | 2026-03-28 ~ 04-11）
> **主题：基座搭建** — 让系统能用起来

| 模块 | Issue数 | 做什么 | sprints子目录 |
|------|---------|--------|-------------|
| 超管驾驶舱 | ~95 | 平台系统监控(Token Pool/GPU/健康检查)+开发者协同(确认中心/验收中心/Claude Office)+安全审计+问题发现+FinOps | `sprints/sprint-1/超管驾驶舱/` |
| D3参数化设计 | ~72 | Web端电池包参数化配置+AI集成+模具库+3D预览 | `sprints/sprint-1/D3参数化设计/` |
| 销售记录体系 | 16 | 三维驱动(流程/项目/时间)+记录中心+周报月报+老板Nudge+经销/国贸适配 | `sprints/sprint-1/销售记录体系/` |
| 统一询盘管理 | 13 | 三线统一(直销/经销/国贸)：询盘→报价→PI→订单跟踪→发货→单据 | — |
| 项目矿场/投标 P0 | 7 | D54优先：矿场增强P0(#1534/#1535/#2256/#2257/#2407)+投标引擎(#2206)+增量同步(#2028) | — |
| 数据采集管线 | ~17 | 4管线架构(招标/企业/行业/竞品) | — |
| AI内容生成(文生图) | ~14 | ComfyUI FLUX文生图基础 | — |

---

### Sprint-2 重点模块（💰 商务全闭环）
> **主题：从发现到签约的完整商务闭环** — 矿场发现项目→投标跟进→合同审批→签约后建项目→图纸/BOM/回款；企微审批+H5移动端打通

| 模块 | Issue数 | 做什么 |
|------|---------|--------|
| **矿场核心** | **~45** | **ICP评分/赢率统计/每日简报/跨境评估/意图评分/验证仪表盘/国际项目模型/买家意图信号（从Backlog移入）** |
| **投标增强** | **~11** | **投标方案引擎+RAG辅助（非情报中台部分）** |
| 执行管理 | ~57 | 建表→CRUD→图纸/BOM/采购/生产/安装/验收/变更→利润/成本/回款→AI预警→EVM |
| 项目计划管理 | 11 | 甲方视角五条业务线+三级管控+多供应商排程+关键路径+甘特图+BOM联动 |
| CRM | 6 | 跟进记录+商机管理+经销体系+报价引擎 |
| H5移动端基座 | 8 | Vant4+MobileLayout+TabBar+路由守卫+企微SDK+认证+开发规范 |
| 企微审批贯通 | 6 | SDK封装+回调处理+H5审批页+消息卡片增强+双端状态同步+数据分析 |
| 流程补齐·通用表单 | 8 | JSON Schema表单引擎+渲染器+模板管理+7模块28个表单模板(人事/行政/质量/印章/运营/国贸/管理)，覆盖47个OA遗留流程 |
| 回款资料管理 | 7 | 资料Checklist全局看板+节点联动门控+审批附件强制+催收提醒+企业信息库+甲方表单辅助 |
| 方案引擎P0 | 9 | DB+API+PPT插件架构+VI标准+素材库基础 |
| 审批引擎P0 | 3 | 数据模型+审批核心引擎+审批中心页面 |
| 数据迁移 | 5 | 明道云→万德平台(用户/部门/角色/权限/产值) |
| 品牌中心基础 | 3 | 多平台数据采集+竞品监测 |
| PageGuide | 4 | 可复用组件+全量数据配置+存量接入 |
| 其他补充 | 5 | 质保/协同/代理商/提成零散 |

**用户旅程**：商务打开矿场→AI评分筛选→标记跟进→投标方案PPT一键生成→中标后建项目→图纸BOM管理→回款跟踪→企微内审批合同/报价→47个OA流程线上化

---

### Sprint-3 重点模块（🎯 商战情报）
> **主题：从被动等信息到主动情报驱动决策** — 情报中台7Phase全覆盖+MEDDIC客户情报

| 模块 | Issue数 | 做什么 | Issue范围 |
|------|---------|--------|----------|
| Phase1: 共享基础设施 | 12 | 统一实体模型+知识图谱+采集引擎+通知+权限+全文检索 | #2674-#2685 |
| Phase2: 行业信息中心 | 10 | 7章节行业档案+政策采集+趋势仪表盘+产品数据库+案例库 | #2686-#2695 |
| Phase3: 矿场→中标概率引擎 | 10 | 中标概率前置+能力匹配+AI标书解析+Go/No-Go | #2696-#2705 |
| Phase4: 客户雷达ICP | 10 | ICP评分+意图信号+购买阶段+暗漏斗+自动推送 | #2706-#2715 |
| Phase5: 竞品全息情报 | 10 | 知识图谱+事实卡片+动态战斗卡+大规模源监控 | #2716-#2725 |
| Phase6: 智能联动层 | 10 | 事件总线+三角关联+AI洞察+商机评分+Copilot | #2726-#2735 |
| Phase7: 统一分发 | 8 | 企微Bot+邮件订阅+H5+小程序+CRM双向同步 | #2736-#2743 |
| 客户情报(MEDDIC) | ~11 | MEDDIC六维度+直销/经销/国贸三模式差异化评分+阶段拦截 | — |

---

### Sprint-4 重点模块（📢 内容获客+数据）
> **主题：品牌自动化输出+多通道获客+客户后中标全链路+S3知识资产挖掘**

| 模块 | Issue数 | 做什么 | Issue范围 |
|------|---------|--------|----------|
| 品牌中心·内容自动化 | 5 | 节日海报自动生成+文章选题引擎+AI初稿+审批工作台 | #2653-#2657 |
| 品牌中心·AI数字人 | 7 | 数字分身+声音克隆+视频生成+自动管线+平台选型 | #2633-#2639 |
| 品牌中心·视频裂变+员工代言 | 5 | 裂变服务+素材包+内容池+分享追踪+H5分享页 | #2640-#2644 |
| 品牌中心·舆情/SEO/广告 | 5 | 舆情监测+SEO管线+LinkedIn广告投放 | #2645-#2649 |
| 外展获客+营销自动化 | 25 | 5 Phase：营销序列引擎→外贸邮件外展→企微获客→LinkedIn导入→统一获客数据层 | #2793-#2818 |
| 客户生命周期 | 12 | 6大引擎：提醒框架→交付里程碑→赢丢单复盘→满意度回访→复购信号→设备生命周期+客户分层 | #2744-#2755 |
| 协同修改 | 14 | Phase2: 多语言翻译引擎+模板多语言化+文件管理(OnlyOffice) | — |
| 素材库/DAM | 14 | 分类树+标签+项目关联+AI自动标签 | — |
| S3数据管线 | 18 | SQS→G7e处理(OCR/CLIP/3D)→pgvector→驾驶舱监控+企微告警 | #3290-#3308 |
| 总控预算二维矩阵+BOM联动 | 10 | 区域×科目预算编制+BOM余额校验+热力图仪表盘 | #3208-#3220 |
| 项目全景控制表 | 2 | 进度×预算×BOM三维聚合+EVM指标+区域健康度气泡图 | #3222-#3223 |

---

### Sprint-5 重点模块（👥 组织管理）
> **主题：企业内部管理数字化** — 人事/制度/审批完善/报销

| 模块 | Issue数 | 做什么 |
|------|---------|--------|
| 人事管理 | 10 | Phase1: 员工档案+合同+变动记录 / Phase7: 培训管理(计划/课程/证书/评估) |
| 审批引擎(完整版) | ~25 | 4种审批人规则+SLA+AI预检服务+完整审批中心前端 |
| 制度管理 | 21 | 制度文档+版本控制+审批发布+知识竞赛 |
| 报销费控 | ~14 | 报销申请+审批+费控规则(Phase1-6) |
| 认证完善 | 5 | 企微OAuth扫码登录+密码重置+OAuth优化 |
| 样品管理补充 | ~3 | 样品管理补充功能 |

---

### Sprint-6 重点模块（💵 财务+运营）
> **主题：钱管起来+项目风控+运营工具完善**

| 模块 | Issue数 | 做什么 |
|------|---------|--------|
| 资金闭环 | 7 | 报价成本模型+应收应付+对账 |
| 预算管控+保证金 | 20 | 7张核心表+CRUD+保证金台账 |
| 提成绩效 | ~14 | 提成规则配置+明细+考核(Phase1-10) |
| 项目中心 | ~22 | 项目全景API+费用归集+设计变更联动+风险台账(5维健康度) |
| PLM/BOM增强 | 20 | 产品生命周期管理增强 |
| 整改工单 | 10 | 工艺标准+状态流转+超时预警 |
| 色卡配色器 | 4 | 配色方案CRUD+交互式配色面板+需求表导出+审批提交 |
| 库存联通 | 5 | P0: 仓库维度表+多仓匹配+调拨单+前端看板 / P1: 外部仓库API+同步+差异告警 |
| 样品箱制度 | 3 | 标准箱模板+项目箱一键生成+业务员领用归还追踪 |
| 商务赋能 | 16 | 产品参数查询+投标文档生成+经销报价单+竞品对比+知识库 |

---

### Sprint-7 重点模块（🤖 AI增强+知识）
> **主题：AI能力全面升级** — 设计模型训练/知识库/AI对话/方案引擎完整版

| 模块 | Issue数 | 做什么 |
|------|---------|--------|
| 设计模型训练+AI内容高级 | ~36 | LoRA训练(万德风格/国际美学)+批量渲染引擎+风格迁移 |
| AI对话中枢 | 15 | 统一对话状态/日志+渠道适配器+跨渠道上下文共享 |
| 知识库RAG | 10 | Embedding修复+文档扩展+分类优化(214个国标文件入库) |
| 方案引擎完整版 | ~20 | PPT模板中心+D3联动+全面重构(剩余部分) |
| 项目组织管理 | ~14 | 文档中心(版本控制)+公告板(讨论→行动项)+阶段门禁+经验教训 |

---

### Sprint-8 重点模块（🔗 生态+售后）
> **主题：从平台延伸到企微生态+售后服务闭环+运营中心**

| 模块 | Issue数 | 做什么 |
|------|---------|--------|
| 企微集成完整版 | 10 | 消息SDK+通知双通道+通讯录同步+企微会话存档 |
| 质保/售后完善 | ~30 | 质保登记+工单+备件+复购联动CRM(全链路) |
| 合同管理完善 | ~10 | 合同审批+回款联动+剩余功能 |
| 回款增强 | ~8 | 回款高级功能 |
| 业务运营中心 | 8 | 项目分配工作台+CRM操作面板+业务看板 |
| 工具中心 | 4 | 工具下载+使用统计+分类页面 |
| 菜单重组 | 2 | 支持中心/综合管理/资源中心板块菜单 |
| 无标签Issue清理 | ~41 | 分类归位或关闭 |

---

### Sprint路线图总览

```
Sprint-1 基座搭建     ████████████████ 能用
Sprint-2 商务全闭环   ██████████████████████ 能赚钱
Sprint-3 商战情报     █████████ 能决策
Sprint-4 内容获客     ██████████████ 能获客
Sprint-5 组织管理     █████████ 能管人
Sprint-6 财务运营     ██████████████ 能管钱
Sprint-7 AI增强       ███████████ 更智能
Sprint-8 生态售后     █████████████ 生态闭环
```
## 🏗️ 仓库架构
> **2026-04-02起，backend和front合并为 Monorepo `wande-play`。** 2026-04-03起，data-pipeline 也整合进 wande-play/pipeline。旧仓库保留但不再新增Issue。
| 仓库 | 用途 | 看板 |
|------|------|------|
| [wande-play](https://github.com/WnadeyaowuOraganization/wande-play) | Monorepo：后端(Spring Boot) + 前端(Vue3) + E2E(Playwright) + 数据管线(Python) + 接口契约 | Project#4 |
| [wande-gh-plugins](https://github.com/WnadeyaowuOraganization/wande-gh-plugins) | Grasshopper 参数化插件库 | Project#4 |
| [.github](https://github.com/WnadeyaowuOraganization/.github) | 组织级配置 — 排程经理/研发经理CC指令、辅助脚本、Sprint记录 | — |
### 已归档（仅追溯）
| 仓库 | 说明 |
|------|------|
| wande-ai-backend | 已合并入 wande-play/backend |
| wande-ai-front | 已合并入 wande-play/frontend |
| wande-data-pipeline | 已合并入 wande-play/pipeline |
### Issue 路由规则
| 类型 | 目标仓库 |
|------|----------|
| Java/Spring Boot 后端 | wande-play（标签 `module:backend`） |
| Vue3/Vben Admin 前端 | wande-play（标签 `module:frontend`） |
| 前后端联动 | wande-play（标签 `module:fullstack`） |
| Python爬虫/采集/G7e采集 | wande-play（标签 `module:pipeline`） |
| Grasshopper插件 | wande-gh-plugins |
| 基础设施/CI/CD/自动编程 | .github |
## 📋 重大决策
| # | 日期 | 状态 | 决策 | 背景 | 决策人 |
|---|------|------|------|------|--------|
| D1 | 03-12 | ❌ | ~~main-only 分支策略~~ → 被D11取代：feature→dev→main | 团队小，dev分支增加合并成本。**已过时：实际已改为feature→dev→main流程** | 吴耀 |
| D2 | 03-12 | ✅ | 后端Java/Spring Boot，数据管道Python脚本 | 技术栈分离。~~原描述async SQLAlchemy已过时~~，pipeline用纯Python脚本不用ORM | 吴耀 |
| D3 | 03-22 | ❌ | ~~数据管道独立仓库 wande-data-pipeline~~ → 被D12取代：整合进wande-play/pipeline | 爬虫与业务逻辑分离。**已过时：D12将pipeline合并入Monorepo** | 吴耀 |
| D4 | 03-11 | ✅ | 环境隔离：Lightsail=生产 / G7e=GPU+测试 / m7i=开发 | 生产环境功能上线需审批。2026-04-12新增m7i.8xlarge(172.31.31.227/54.234.200.59)专用于编程开发，G7e保留GPU/模型服务 | 吴耀 |
| D5 | 03-29 | ✅ | 调度器v2：Plan→Todo→In Progress→Done 全自动 | 替代手动SCHEDULE.md | 吴耀 |
| D6 | 03-27 | ✅ | TDD模式 + E2E测试解耦 | 编程CC先写单元测试再编码；E2E改为定时调度独立触发，不阻塞编程CC | 吴耀 |
| D7 | 04-01 | ✅ | 驾驶舱预算=开发运维预算(FinOps)，业务预算回归module:budget | 边界清晰 | 吴耀 |
| D8 | 04-02 | ✅ | 销售记录三维驱动：流程+项目+时间 | 替代纯手动周报 | 吴耀 |
| D9 | 04-02 | ✅ | Monorepo：backend+front合并为 wande-play | 减少跨仓库协调成本，支持Agent Teams并行开发 | 吴耀 |
| D10 | 04-02 | ✅ | Project#4 (wande-play研发看板) 替代 Project#2 管理play仓库Issue | Monorepo需要独立看板 | 吴耀 |
| D11 | 03-28 | ✅ | PR创建职责固化给编程CC（gh pr create --base dev） | post-task.sh触发不稳定，PR创建回归编程CC第三阶段 | 吴耀 |
| D12 | 04-03 | ✅ | data-pipeline 整合进 wande-play/pipeline | 统一Monorepo管理，减少跨仓库协调 | 吴耀 |
| D13 | 04-03 | ✅ | Sprint-2执行管理变更→合同联动(#2085)提升为P0 | 行业最佳实践：变更金额直接影响合同回款，是核心功能 | 吴耀 |
| D14 | 04-03 | ✅ | Sprint-2新增EVM挣值管理简化版(#2506, module:fullstack) | 行业标配，SPI/CPI实时计算+项目健康度评分，适合万德长周期项目 | 吴耀 |
| D15 | 04-03 | ✅ | Sprint-2去重：关闭#2184-#2188，保留#2464-#2468 | 5组完全重复Issue清理 | 吴耀 |
| D16 | 04-03 | ✅ | E2E测试独立工作目录：wande-play-e2e-mid / wande-play-e2e-top | 中层/顶层E2E各自完整wande-play克隆，互不干扰，也不影响编程CC | 伟平 |
| D17 | 04-03 | ✅ | 排程计划按重点模块分子目录 | sprints/日期/超管驾驶舱/PLAN.md，支持多模块并行排程 | 伟平 |
| D18 | 04-03 | ✅ | query-project-issues.sh 输出增加 module/priority 列 | 研发经理CC排程时可直接按标签分类，识别fullstack触发Agent Teams | 伟平 |
| D19 | 04-03 | ✅ | 首个fullstack Issue #1440（D3技术确认中心）用于测试Agent Teams | 合并#443+#1166，验证研发经理CC对module:fullstack的排程和触发 | 伟平 |
| D20 | 04-03 | ✅ | Claude Office新增CC实时日志显示 | 点击agent/研发经理卡片打开终端风格日志面板，3秒自动刷新 | 伟平 |
| D21 | 04-03 | ✅ | Project#2废弃，wande-gh-plugins迁移到Project#4 | 统一看板管理，Project#2仅保留历史追溯 | 伟平 |
| D22 | 04-03 | ✅ | 测试架构改革：编程CC接管构建部署，CI仅负责PR E2E和pipeline同步 | build-deploy-dev.yml剥离构建部署job，编程CC在feature分支完成TDD→build→deploy→smoke→PR全流程；CI pr-test.yml负责E2E自动merge/fail；cron 2h/6h兜底回归 | 伟平 |
| D23 | 04-04 | ✅ | 根CLAUDE.md增加Issue拾取指引+清理主目录引用 | 编程CC收到非标准prompt时不知道怎么获取Issue内容（gh issue view失败后无备用方案）。根CLAUDE.md新增「Issue拾取」章节：唯一正确方式(gh issue view)+三级备用方案(token重获→curl REST API→curl评论API)+非标准prompt说明。同时修正Project看板链接(#2→#4)和辅助脚本路径，删除主目录引用 | 伟平 |
| D24 | 04-04 | ✅ | Thinking模式改为effort参数动态控制，由研发经理CC按Issue复杂度决策 | 原方案：settings.json全局DISABLE_THINKING=1一刀切关闭。新方案：移除所有settings.json中的DISABLE_THINKING，三个启动脚本(run-cc.sh/run-cc-with-prompt.sh/run-cc-play.sh)新增第5个参数[effort]，不传时默认medium。研发经理CC根据Issue标签决策：docs/config→low，常规CRUD→medium，多文件重构/复杂bug→high，架构级重构/fullstack→high或max | 伟平 |
| D25 | 04-04 | ✅ | pr-test.yml独立目录+全局排队 | PR E2E使用wande-play-ci专用目录，concurrency全局排队避免并发互踩，与cron e2e-mid/e2e-top目录隔离 | 伟平 |
| D26 | 04-04 | ✅ | CI编译门禁+编程CC防重复类规范 | pr-test.yml新增mvn compile步骤；编程CC创建新类前必须查重；包路径唯一映射规则；研发经理CC同模块Issue串行排程 | 伟平 |
| D27 | 04-04 | ✅ | 合并wande-ai-api到wande-ai（#2585 P0） | PR #2593 已创建：删除wande-ai-api模块，迁移1000+类到wande-ai，清理17个内部重复+15个跨模块重复，编译打包通过 | 伟平 |
| D28 | 04-04 | 🟡 | 接口契约目录启用（#2586 P0） | shared/api-contracts/作为前后端唯一真相源，扫描现有API初始化契约文件；契约先行规则写入CLAUDE.md | 伟平 |
| D29 | 04-04 | ✅ | Sprint管理规范化：表格化+按阶段命名 | status.md Sprint计划改为表格（阶段/状态/时间/重点模块/子目录路径）；sprints目录按阶段命名(sprint-1)而非日期；研发经理CC直接查表获取sprint名和模块子目录 | 伟平 |
| D30 | 04-04 | ✅ | 统一run-cc.sh为唯一CC启动脚本+Issue预取机制 | 合并run-cc-play.sh到run-cc.sh，启动前自动预取Issue内容到issue-source.md，编程CC从本地文件读取（解决kimi模型截断gh命令导致10分钟空转的问题，降至6秒）；删除round-executor.sh，修复cc-error-parser.py旧路径 | 伟平 |
| D31 | 04-04 | ✅ | 编程CC职责简化：去掉deploy-dev.sh和Playwright，只保留编译检查+单元测试 | build-deploy-dev.yml补全后端/前端自动构建部署（merge到dev后触发），编程CC不再操作Dev环境 | 吴耀 |
| D32 | 04-04 | ✅ | E2E测试失败统一使用Project#4的E2E Fail状态 | 三层测试失败均标E2E Fail(efdab43b)而非Todo；Label用status:test-failed/test-passed；e2e-result-handler.py统一处理 | 吴耀 |
| D33 | 04-04 | ✅ | 中层E2E从AI驱动改为纯脚本Smoke探活 | e2e_smoke.sh每30分钟零AI消耗跑smoke测试；原e2e_mid_tier.sh(Claude Code)废弃；e2e-result-handler.py支持无Issue时自动创建 | 吴耀 |
| D34 | 04-04 | ✅ | pr-test.yml兜底构建失败场景 | 构建失败时Playwright不跑、无测试报告，handler跳过导致Issue未标记。新增兜底：报告不存在时直接评论PR/Issue+标test-failed+设E2E Fail | 吴耀 |
| D35 | 04-04 | ✅ | 全平台PageGuide页面说明体系 | 每个前端页面顶部必须包含可折叠Banner（三段式：这是什么/解决什么问题/快速上手），通过可复用Vue3组件+集中数据配置实现。Issue创建SOP新增PageGuide必填Section。#2614-#2617 Sprint-2 | 吴耀 |
| D36 | 04-04 | ✅ | 过时Issue清理：63个重复Issue关闭 + D1/D3标废 + CRM跟进记录统一 | 关闭63个无Sprint标签的重复Issue；D1(main-only)、D3(独立仓库)标❌；D2描述修正；#1705 CRM跟进记录需对接D8的activity_logs三维驱动体系 | 吴耀 |
| D37 | 04-04 | ✅ | H5移动端全量适配：双视图架构+完整功能+底部TabBar | 所有页面需手机端可访问（企微内打开），PC端views/wande/+H5端views/h5/双视图，Vant4组件库，新页面强制双端/旧页面逐步补齐，8个P0基座Issue(#2625-#2632) Sprint-2 | 吴耀 |
| D38 | 04-04 | ✅ | 功能注册表体系：`docs/feature-registry.md` | 1029个Issue戉1个文件管理，41个功能模块×9大业务域，带状态/Sprint/策略备注。与status.md互补：status记架构/技术决策，registry记功能级策略调整 | 吴耀 |
| D39 | 04-04 | ✅ | 业务域"其他"治理：关闭24+重分配49+新建数据迁移域 | 78个"其他"Issue全量审计：19个决策过期(G7e旧架构/测试基建已被v10.0替代)+3个重复+2个低ROI=24个关闭；23个归入正确业务域；26个保留Issue也重归类(矿场增强15→项目矿场、明道云3→数据迁移、色卡2→D3、工具中心2+问题发现1→驾驶舱、Agent基建3→数据采集)。新建"数据迁移"业务域(一次性，完成后归档)。"其他"分组清零 | 吴耀 |
| D39 | 04-04 | ✅ | Project#4增加「业务域」+「Sprint」自定义字段 | 1043个Item全量填充业务域(32个选项)+Sprint(6个选项)。支持按业务域过滤、按Sprint分组、Board/Table/Roadmap多视图。研发经理CC可用业务域字段进行模块级排程 | 吴耀 |
| D40 | 04-05 | ✅ | 商战情报中台业务线：7 Phase·70个Issue·对标TenderStrike+6sense+Contify+Vertical IQ |
| D41 | 04-05 | ✅ | Sprint 1-5 负载均衡调整 | Sprint-1瘦身：27个P2 Issue移到Sprint-2（D3 AI/矿场复盘/问题发现/协同修改等非核心）；Sprint-2增强：方案引擎P0(9个)从Sprint-3提前+审批引擎P0(3个)从Sprint-4提前；Sprint-4补充：品牌中心低优(视频裂变/员工代言/舆情/SEO/广告10个)从无标签分配；Sprint-Backlog：377个无标签Issue统一归入。调整后Sprint-1:138/Sprint-2:139/Sprint-3:178/Sprint-4:120/Sprint-5:79/Backlog:459 | 吴耀 | 三合一整合：投标发现(中标概率引擎)+客户发现(ICP评分)+竞品全息情报(知识图谱+战斗卡)+行业信息(7章节模板)。新增biz:intelligence-hub标签，Phase 1 P0可插入Sprint-2，主体Sprint-5。Issue #2674-#2743 | 吴耀 |
| D41 | 04-05 | ✅ | 外展获客+营销自动化业务线：5 Phase·25个Issue·三通道覆盖 | 营销序列引擎(P0基础设施)+外贸邮件外展(冷外展7步+A/B+追踪)+企微获客(活码+SOP培育+批量加好友)+LinkedIn导入(意图信号+协同序列)+统一获客数据层(线索评分+ROI看板+自动移交)。新增biz:outreach+biz:marketing-automation+biz:crm标签。对标HubSpot Sequences+Lemlist+Apollo.io+WeSCRM。Issue #2793-#2818 | 吴耀 |
| D42 | 04-05 | ✅ | 行业专家知识体系启动：wande-industry Skill + 知识结晶机制 | 平台从「文档检索」升级为「行业顶级专家」。Nurture-First三层架构+5级能力模型。P0: wande-industry Skill(6知识域+4决策树)+结晶SOP(6标签)+Memory种子+wande-ai v54更新。P1-P4: S3蒸馏→GraphRAG→推理引擎→飞轮 | 吴耀 |
| D43 | 04-05 | ✅ | Harness优化方案V1落地（28/29完成） | **CLAUDE.md精简**：wande-play主CLAUDE.md从67行精简至40行，接口契约最优先，删除backend/frontend/pipeline子模块CLAUDE.md。**agent-docs子目录**：.github/docs/agent-docs/{backend,frontend,pipeline}/README.md集中管理，wande-play跨仓库引用。**静态分析**：ESLint废弃API规则+嵌套检查+antdv-constraints.md。**工作流精简**：编程CC去需求评估、task.md合并进度字段(Status/Phase)、研发经理CC读tmux capture-pane实时输出（D65已改）。**模型分级**：仅max走Claude Max订阅（默认Sonnet），其余走Token Pool Proxy+上下文自动截断(kimi 256K/glm 200K)。**冲突解决**：cycle-merge智能分类+trigger-conflict-resolver+pr-test.yml/post-task.sh集成。**安全边界**：最大重试3次+超时20分钟自动清理。**过时文件清理**：删除15个过时文档/脚本/prompt | 伟平 |
| D44 | 04-05 | ✅ | wande-ai-api模块废弃确认 | wande-ai-api已合并入wande-ai（D27 PR#2593），万德业务功能全部在wande-ai子模块实现。backend/ruoyi-modules-api/wande-ai-api目录已废弃 | 伟平 |
| D45 | 04-06 | ✅ | Harness优化V2 + Claude Office重构 | run-cc.sh命名参数+内置pre-task；Claude Office server.py重写(2424→479行)；进程检测统一扫描；日志JSONL直读；PR CI全链路优化（冲突检测→构建部署→smoke→E2E→失败自动修复） | 伟平 |
| D46 | 04-06 | ✅ | 外接目录指派锁机制 | run-cc.sh写入.cc-lock(issue号+时间)，issue-sync.yml关闭时release-cc-lock.sh释放，cc-check.sh（原check-cc-status.sh）整合锁状态检查(超1小时需处理) | 伟平 |
| D47 | 04-08 | ✅ | S3数据管线业务线：5 Phase·18个Issue·G7e自托管方案 | S3 4.5TB数据资产全景扫描完成(38万文件)→发现加密文件签名(17da5fa0)→EventBridge+SQS+G7e轮询架构→pgvector入库→驾驶舱监控+企微告警→解密管线+AI蒸馏。月成本~$10(仅SQS+EventBridge)，处理全在G7e。新增biz:data-pipeline标签。S3 Metadata已开启。Issue #3290-#3308 | 吴耀 |
| D47 | 04-06 | ✅ | Issue关闭自动清理全链路 | issue-sync.yml: 删除.cc-lock + 本地git branch -D + 远程git push --delete。不依赖外部脚本，直接在workflow中遍历kimi1~20 | 伟平 |
| D48 | 04-06 | ✅ | CC异常退出cron恢复机制 | cc-keepalive.sh（原post-cc-check.sh）由cron每5分钟巡检：.cc-lock存在+无claude进程→自动commit/push/PR，10次重试失败标Fail+评论原因。去掉tmux内post-check（快速路径），全部由cron兜底 | 伟平 |
| D49 | 04-06 | ✅ | 辅助脚本全面审计修复 | cc_manager.sh已废弃→run-manager.sh替代（D65）; run-cc.sh: 重入逻辑修复(统一retry_count/锁检测前置/SAVED状态跳过checkout dev/api_source不重复追加); scheduler-guide: 锁状态机文档化(RUNNING→SAVED→NO_CHANGES)+SAVED处理流程; 删除resume-inprogress-ccs.sh+monitor-issue-2893.sh | 伟平 |
| D49 | 04-06 | ✅ | 清理孤立脚本+修复check-cc-status.sh会话解析bug | **删除cc-error-parser.py**（596行，无调用者，/var/log/coding-cc已停止写入，CI失败详情走pr-test.yml内联grep，页面已直接读~/.claude/projects/ JSONL）。**修复check-cc-status.sh**：session名从cc-backend-1234改为cc-kimi1-2893后，*kimi1*模糊匹配kimi10-19，误判超时Kill正在运行的CC+标Fail；改为从.cc-lock读issue/module，JSONL搜索改用精确路径。**修复monitor-issue-2893.sh**：新增CC存活检测，threshold从>6h降至>=3h | 伟平 |
| D50 | 04-06 | ✅ | build-deploy-dev.yml部署失败处理+日志简化 | **新增deploy-failed job**：后端/前端/pipeline任意一个部署失败时，自动创建新P0 bugfix Issue（标priority/P0+type:bugfix+status:test-failed），Project状态设为E2E Fail，由研发经理CC优先安排修复。**简化日志**：去掉Maven/前端构建的tee本地文件逻辑，健康检查失败直接tail打到CI控制台；deploy-failed只附CI日志URL（不再读/tmp/deploy-*.log），减少40行冗余代码 | 伟平 |
| D51 | 04-06 | ✅ | run-cc.sh重构：交互模式+CLAUDE_CONFIG_DIR隔离+会话稳定性 | **交互模式**：去掉`-p`改用`tmux send-keys`注入，支持`tmux attach`直接对话编程CC。**目录修复**：`-c $PROJECT_DIR`确保启动目录正确，加`--dangerously-skip-permissions`。**Auth隔离**：proxy模式用`CLAUDE_CONFIG_DIR`隔离claude.ai凭证（rsync复制除credentials外全部文件+stub `.credentials.json`+复制`~/.claude.json`），避免auth conflict同时跳过onboarding。**会话稳定性**：去掉`tmux kill-session`（防止claude异常退出时会话立即消失，影响cron检测），加`exec bash`保持会话存活，sleep改为5s。**keys.json**：删除失效的`claude_max` API key配置 | 伟平 |
| D52 | 04-06 | ✅ | CLAUDE.md文档路径改为绝对路径 | wande-play所有kimi目录CLAUDE.md中子模块指南由相对路径`../../.github/docs/...`改为绝对路径`/home/ubuntu/projects/.github/docs/...`，避免编程CC在子目录操作时路径解析错误，也避免与项目自身`.github/workflows/`混淆 | 伟平 |
| D53 | 04-06 | ✅ | post-cc-check.sh进程检测Bug修复 + session命名统一 | **Bug根因**：`HAS_PROCESS`检测用`DIRNAME=wande-play-kimi11`匹配session名`cc-kimi11-backend-1633`，grep永远不匹配→所有CC误判无进程→每5分钟retry+1→触发retry=10标Fail，CC实际正在运行。**修复**：session命名统一为`cc-{basename(BASE_DIR)}-{issue}`（如`cc-wande-play-kimi11-1633`），post-cc-check.sh改为精确匹配`cc-{DIRNAME}-{ISSUE}`，无需读DIR_SUFFIX字段。**check-cc-status.sh**：session解析从`cc-wande-play-kimiN-1234`提取kimiN和issue。**Claude Office兼容**：`/log`接口`rsplit("-",1)`提取dir_name=`wande-play-kimi11`→`_find_jsonl`按最近修改匹配JSONL，功能不受影响 | 伟平 |
| D55 | 04-07 | ✅ | CC目录锁完整生命周期重构 | **CC不退出**：issue-workflow.md改为PR创建后轮询等待合并，不主动退出。**锁释放**：新增release-cc-lock.sh（kill session+rm .cc-lock+checkout dev），唯一出口。**cc-lock-manager.yml**：双触发路径——①workflow_run(build-deploy-dev完成后，不受cancel-in-progress影响)→部署成功释放锁/失败注入提示；②pull_request merged兜底（仅改issues/docs等被paths-ignore过滤时dev CI不触发，靠PR事件直接释放）。**CI注入**：pr-test.yml/build-deploy-dev.yml失败时改为inject-cc-prompt.sh直接注入活跃CC会话，不再创建新Issue。**post-cc-check.sh简化**：去掉commit/push/SAVED状态机，只做保活——进程消失注入恢复提示词，session消失重启run-cc.sh。**全量同步**：所有kimi1-20目录+main分支同步 | 伟平 |
| D56 | 04-09 | ✅ | CRM商务中心Sprint-1：原型确认+13个Issue | 10页HTML原型+详细设计文档→.github/docs/design/crm-商务中心/。#3526-#3538创建(Sprint-1)。代码对账：7个新Issue补已有代码路径。关闭13个旧重复Issue(#3099-3102/#3110/#1706/#2130/#2210-2212/#1464/#2247/#2248)，Sprint调整8个(#3103-3108→S2/#3109#3111→S3) | 吴耀 |
| D57 | 04-09 | ✅ | 产品技术中心联邦架构确立 | 调研Odoo PLM/Arena/Tacton CPQ最佳实践→确立"PLM作数字主干"联邦架构。8页原型(总览/零件/BOM/ECO/配置器/技术确认/D3工作台/合规)。Phase0零件号命名→Phase1 PLM核心+D3桥接→Phase2超级BOM+配置器→Phase3 ETO→CTO转化 | 吴耀 |
| D58 | 04-09 | ✅ | 产品技术中心Issue对账清理 | 关闭12个被PLM取代Issue(#2155/#2084/#2128/#1863等)。合并7对重叠(#1935→#3390, #2055→#3379, #1936→#1845, #2315→#2306, #1859→#3388, #1860→#3380, #1918→#3391)。新标签biz:ptc标记26个Issue | 吴耀 |
| D59 | 04-09 | ✅ | 产品技术中心32个Issue→Sprint-2 | PLM20个+D3Web6个+合规6个统一从Sprint-3移入sprint:2。Sprint-1保留D3 GH电池包(纯GH/Python不依赖PLM)，S2 PLM建好后通过#3390桥接 | 吴耀 |
| D54 | 04-07 | ✅ | Sprint-1矿场优先级提升：矿场P0(5个)+投标引擎(1个)+矿场增量同步(1个)→Todo | Sprint-1矿场完成率0%(19个Issue全部未启动)，算力被D3吸收。矿场P0的5个Issue(#1534/#1535/#2256/#2257/#2407)+投标引擎#2206(P0)+#2028(P1)看板状态从Plan→Todo，确保研发经理CC能排程。矿场P0优先于D3剩余Todo | 吴耀 |
| D56 | 04-06 | ✅ | Claude Office Safari/iPhone兼容性修复 | **Safari相对URL**：fetch从`window.location.origin+'/api/inject'`改为`'api/inject'`（Safari不接受origin拼接）。**iPhone注入栏不可见**：`height:100vh`→`100dvh`（动态视口高度，排除浏览器地址栏）+`padding-bottom:max(10px,env(safe-area-inset-bottom,10px))`（Home Indicator遮挡）。**viewport**：`<meta>`加`viewport-fit=cover`（iOS safe-area-inset生效前提） | 伟平 |
| D57 | 04-06 | ✅ | Claude Office研发经理CC日志Tab重构 | **问题**：manager session无法通过JSONL uuid直接找到tmux会话，注入失效+tab名错误。**方案**：新增`tmux_session`字段（真实tmux会话名）与`log_session`（JSONL uuid）分离。`_scan_manager_tmux_sessions()`扫描非cc-前缀tmux会话→找claude进程→按进程启动时间vs JSONL mtime分配最近修改文件。Tab名特殊处理：cc-前缀截去`cc-{org}-{repo}-`前缀保留`kimiN-issue`，manager按uuid前8位显示。前端inject用`cur.tmux_session||cur.log_session` | 伟平 |
| D58 | 04-06 | ✅ | Claude Office实时Webhook通知系统 | **问题**：通知轮询8s延迟，刷新页面才显示。**方案**：SSE长连接（`GET /api/events`，EventSource），`ThreadingHTTPServer`避免阻塞。`POST /api/notify`存储通知+推送所有SSE队列。Toast UI：右上角固定，12s自动消失，按type着色左边框。`connectNotificationSSE()`自动5s重连。CLAUDE.md新增每轮结束后`curl /api/notify`的指令让研发经理CC主动推送 | 伟平 |
| D59 | 04-06 | ✅ | Canvas工作区取消拖拽、自适应铺满 | 去掉鼠标drag handler（mousedown/mouseup），保留hover tooltip。新增`autoZoomFit()`：`zoom=min(containerW/(OFFICE_W*T), containerH/(OFFICE_H*T))`，panX/panY归零，实现fit-contain铺满。初始化和`window.resize`时通过`requestAnimationFrame`触发，跟随浏览器窗口大小 | 伟平 |
| D60 | 04-06 | ✅ | 前端UI图形E2E测试体系建立 | 使用Playwright对Claude Office、wande-play前端进行一次完整图形测试。发现P0 bug：①Claude Office /api/events Content-Type缺失SSE标准头；②多个路由404（/service-records、/pit-analysis等）；③Modal点击无响应；④看板数据加载异常。创建[bug]标题P0 Issue至E2E Fail状态。新增`docs/workflow/ui-test-coverage-plan.md`三级测试改进方案 | 伟平 |
| D61 | 04-06 | ✅ | update-project-status.sh自动关联看板 | `gh issue create`不自动添加到GitHub Project看板，导致update-project-status.sh找不到Item ID。**修复**：ITEM_IDS为空时，①`addProjectV2ItemById` GraphQL mutation获取issue node ID②添加到Project→获取item ID③继续更新Status。对所有已创建未关联的bug Issue批量补关联。脚本现在幂等，issue未在看板中会自动加入 | 伟平 |
| D62 | 04-07 | ✅ | 编程CC文档误读三大问题修复 | **①.github项目入口缺失**：CLAUDE.md顶部新增强制阅读块，明确文档库在`/home/ubuntu/projects/.github/docs/agent-docs/`（独立项目，非当前.github/workflows目录），run-cc.sh初始prompt前置"先读issue-workflow.md"。**②schema.sql/wande-ai-api禁令未在CLAUDE.md体现**：新增两条YOU MUST NOT——禁止直接编辑schema.sql/禁止在wande-ai-api下新增代码。**③RuoYi原版文档冲突**：`database-specification.md`顶部加覆盖声明（禁止按原版改schema.sql/使用MySQL语法/日期命名）；`backend/CLAUDE.md`去掉6个不存在的本地docs引用；`backend/README.md`wande-ai-api标为已废弃；`frontend/CLAUDE.md`3个不存在的本地docs引用替换为`.github`绝对路径；`shared-conventions.md`/`backend/conventions.md`sudo误用修正。全部同步kimi1-20 | 伟平 |
| D63 | 04-07 | ✅ | 第2轮排程：超管驾驶舱+Claude Office迁移+矿场增强 | 12个Issue并行启动：超管驾驶舱P0(#2409/#1572/#2076/#2043/#2081/#2276)、Claude Office全量迁移(#2893)、矿场增强P0(#2257/#2407/#2256)、投标方案引擎(#2206)、矿场增量同步(#2028)。当前16空闲→12锁定 | 伟平 |
| D64 | 04-07 | ✅ | 统一询盘管理体系：客户为中心+三线统一数据模型 | 客户(Account)→询盘(Inquiry)→报价(Quotation)→订单(Order)层级，直销/经销/国贸共用trade_inquiries+trade_quotations表(business_type区分)。直销主流程仍走矿场→商机模式(项目驱动)，询盘模式服务经销+国贸+少量直销非招标场景。13个Issue(#3099-#3111) Sprint-1：P0询盘模型+报价模型+客户Tab+看板+报价PDF+PI生成，P1订单跟踪+发货+单据+合同扩展，P2信用额度+转化率+汇率。对标SAP SD文档流+Salesforce Account-Opportunity | 吴耀 |
| D65 | 04-07 | ✅ | 直销vs询盘双入口架构确认 | 直销(国内+澳门)=项目驱动→矿场系统(68个Issue)；经销+国贸=客户驱动→询盘工作台(13个Issue)。两套入口共享客户/合同/回款/销售记录层，互不混用。少量直销非招标场景可走询盘模式(business_type=direct) | 吴耀 |
| D66 | 04-07 | ✅ | 企微审批贯通：万德平台主控+企微端审批双引擎 | 使用企微「审批流程引擎」API（非审批应用API），自建应用集成，控制权在万德平台侧。4核心API(submit/detail/list/status)+回调实时同步+H5发起+消息卡片一键审批+双端状态监控。6个Issue(#3161-#3166) Sprint-2，blocked-by #1564(企微SDK)+#2026(审批状态机) | 吴耀 |
| D67 | 04-07 | ✅ | OA遗留47流程全覆盖：JSON Schema动态表单+条件路由 | 170+旧流程→33简化流程，47个OA未覆盖流程采用「通用表单引擎+审批引擎条件路由」方案，不逐个定制开发。JSON Schema驱动表单配置化，7模块28个模板(人事6+行政5+质量5+印章3+运营2+国贸1+管理6)。8个Issue(#3167-#3174) Sprint-2 | 吴耀 |
| D68 | 04-07 | ✅ | 回款资料管理体系：Checklist+催收+企业信息库+甲方表单辅助 | 解决甲方回款资料丢失和收集难题。三层方案：①流程节点强制附件+自动归集；②回款节点资料Checklist+完整度门控+自定义甲方要求；③企业信息库自动填充+甲方表单模板生成导出。资料催收企微+站内双通道。7个Issue(#3185-#3191) Sprint-2。复用现有#1999凭证数据库+#2124回款计划+#3179项目360看板+企微通知能力 | 吴耀 |
| D69 | 04-07 | ✅ | 体游甲方视角的项目计划管理体系 | 中标后项目计划从万德供应商视角转为体游甲方视角。五条业务线(设计/合约/工程/报建/商务)+三级管控(一级节点=项目生死线/二级=管理层关注/三级=日常跟踪)+多供应商三段式排程(设计→生产→现场)+关键路径自动识别+计划模板一键生成+BOM变更→计划联动引擎。BOM独立模块(execution包)通过Spring Event与计划模块联动。11个Issue(#3193-#3203) Sprint-2。参考：琴澳公园全景计划表+天力合项目安排计划表+加工深化清单 | 吴耀 |
| D71 | 04-07 | ✅ | 总控预算二维矩阵：区域×科目+BOM联动 | 增强现有budget模块为「区域×科目」二维预算矩阵。三个关键决策：①区域跟招标文件走+手动补充；②成本类型复用现有科目树；③供应商作为科目树子级。三级校验(L1项目≤成本池/L2区域≤合同×(1-利润率)/L3格子≥0)+两级管控(设计阶段软提醒+采购硬拦截)。BOM汇总价≤分项预算红线。10个Issue(#3208-#3220) Sprint-3。参考：PMWEB WBS+CBS双轨制+计支宝「一责三化」+Mastt施工预算控制 | 吴耀 |
| D72 | 04-07 | ✅ | 项目全景控制表：一张表看进度×预算×BOM | 用区域(zone)作为计划管理(plan_milestone.zone)+预算矩阵(budget_zone)+BOM(bom_items.budget_zone_id)三模块的公共轴，聚合查询生成项目全景视图。核心指标：EVM挣值管理(PV/EV/AC/SPI/CPI)+区域级健康度(🟢🟡🔴)+进度-成本气泡图。纯查询聚合不新建数据模型。2个Issue(#3222-#3223) Sprint-3。参考：5D BIM(空间+时间+成本)+AACE统一WBS+EPC挣值管理 | 吴耀 |
| D73 | 04-07 | ✅ | 经理CC全面优化：PLAN.md重构+指派建议表+Project#4回补 | **PLAN.md结构重构**：当前运行+指派历史+指派建议三表置于底部研发经理/排程经理专区，Tier系列表删除状态/指派目录列（排程经理只看依赖），修复全文||双竖线格式错误。**指派建议表**：排程经理新增任务三，维护`## 指派建议（最近20个）`，Jump/Fail/E2E Fail插队首，建议全Done时重建；研发经理指派步骤改为优先读建议表。**经理CC升级**：run-manager.sh从Proxy模式切换为Claude Max订阅Sonnet 4.6，unset ANTHROPIC_API_KEY；cron保活从30分钟缩短为10分钟。**ISSUE_ASSIGN_HISTORY.md防复建**：assign-guide修正旧引用（下次指派时优先选择→指派历史），加入.gitignore。**Project#4 TOKEN失效修复**：issue-sync.yml已整合自动关联Project#4逻辑，仅PROJECT_TOKEN secret失效需人工更新；新增backfill-project-issues.sh回补4月3日后约400个未关联Issue | 伟平 |
| D74 | 04-07 | ✅ | 基础设施：Claude Office四区域独立发现+tmux日志+gh-app-token合并 | **Claude Office重构**：`_scan_coding_cc_sessions()`拆为三个独立方法——`_scan_play_sessions()`(cc-wande-play-*)、`_scan_e2e_sessions()`(e2e-*)、`_scan_gh_plugins_sessions()`(cc-wande-gh-plugins-*)，各区域发现逻辑独立互不干扰。日志端点`/api/logs/{name}`全面改为`tmux capture-pane`直读终端内容，删除JSONL映射/`_parse_jsonl_log`/`_manager_session_jsonl`/`SESSION_MAP_FILE`等复杂日志链路。末尾UI chrome过滤：两轮剥离去掉横线/bash提示/权限提示，保留`[Model]`状态栏行。`e2e_top_tier.sh`改为interactive tmux会话（与run-manager.sh同模式）。**gh-app-token合并**：`get-gh-token.sh`逻辑（e2e目录→wandeyaowu PAT、GitHub App token、fallback weiping PAT）全部整合进`gh-app-token.py`，删除`get-gh-token.sh`，全仓库17处引用统一更新为`python3 gh-app-token.py` | 伟平 |
| D76 | 04-08 | ✅ | 域名策略确认：测试环境 ceshi.tiyouoperation.com + 正式环境 www.tiyouoperation.com | 吴耀确认：测试环境继续使用 ceshi.tiyouoperation.com，正式环境使用 www.tiyouoperation.com。影响扫描：26个open Issue的验收标准中引用了 ceshi.tiyouoperation.com，均为正确引用，无需修改。当前架构：m7i(172.31.31.227)=开发编程 / G7e(3.211.167.122)=GPU+Dev测试 / Lightsail(47.131.77.9)=生产，后续需配置 DNS 指向 | 吴耀 |
| D78 | 04-12 | ✅ | 编程开发环境迁移至m7i.8xlarge（无GPU） | G7e的GPU利用率<1%，编程开发不需要GPU。新增m7i.8xlarge(32vCPU/128GB/1TB gp3)专用于编程CC开发，预计月费从~$7000降至~$720(1年RI)，节省~87%。G7e保留用于GPU/模型服务。新机器已完成：20个kimi目录+38个项目目录+PG(5432/5433)+Redis(6380)+Docker+Claude Code+所有脚本 | 吴耀 |
| D75 | 04-08 | ✅ | S3三级检索架构确立：Perplexity直连S3知识库 | **管道已验证**：Perplexity AWS连接器(aws__pipedream) presigned URL→curl下载→本地解析，端到端可用。**三级优先级**：L0 Skill内嵌 references/（零成本）→ L1 S3直接读取 JSON/TXT/CSV/MD/DOCX/XLSX（低credit）→ L2 G7e RAG pgvector PDF/扫描件（零credit）。**Skill更新**：wande-industry v3.0（§3.2新增S3实时检索执行协议）+ wande-ai v55.0（§3新增S3检索场景+§7新增Perplexity独有能力）。**已知限制**：无List Objects（依赖directory_mapping.json索引）、presigned URL 1h有效期、本地无OCR。下一步：#37数据管线P0上线打通L2通路 | 吴耀 |
| D70 | 04-07 | ✅ | 研发经理架构拆分：排程经理+研发经理双角色CC | **角色分离**：单一研发经理CC拆为两个独立角色——排程经理（监控Jump/Fail/排程分析/维护PLAN.md）、研发经理（指派CC/巡检进度/注入提示词/验收报告）。**run-manager.sh**：统一启动脚本，幂等启动`manager-排程经理`+`manager-研发经理`两个tmux会话，`\loop 10m`自驱动，cron每30分钟保活。**CLAUDE.md重构**：统一角色路由入口，公共信息（看板ID/脚本/Effort/通知）集中管理，各角色读对应guide文件。**guide文件**：scheduler-guide.md（排程经理专属）/ assign-guide.md（研发经理专属），去除与CLAUDE.md重复内容。**脚本重命名**：check-cc-status.sh→cc-check.sh，post-cc-check.sh→cc-keepalive.sh，cc_manager.sh删除。**巡检改进**：研发经理巡检改为tmux capture-pane实时输出，不再读滞后的task.md。**Sprint多版本支持**：guide中路径统一用sprints/sprint-N，由CC从status.md「🟢进行中」行自行识别当前Sprint。**PLAN.md整合**：增加指派目录列，删除独立ISSUE_ASSIGN_HISTORY.md；sprint-1目录清理19个过时文件 | 伟平 |
| D77 | 04-08 | ✅ | Sprint体系重构：5+Backlog→8个Sprint，每个Sprint有清晰主题 | 矿场核心45个Issue从Backlog移入Sprint-2形成商务全闭环；商战情报前移Sprint-3；原Backlog拆分为Sprint 5(组织管理)/6(财务运营)/7(AI增强)/8(生态售后)。8个Sprint主线：能用→能赚钱→能决策→能获客→能管人→能管钱→更智能→生态闭环 | 吴耀 |
> **规则**：🟡=提议待确认 / ✅=已生效 / ❌=已废弃（保留追溯）
> **决策权**：吴耀有最终决策权

## 📊 工作状态
### Project#4 — wande-play 研发看板（2026-04-04 18:45）
| 状态 | 数量 |
|------|------|
| Plan | 720 |
| Todo | 89 |
| In Progress | 178 |
| Done | 44 |
| E2E Fail | 9 |
| Fail | 3 |
| 总Items | 1055 |
| Open Issue | 1182 |

**自定义字段（D39新增）**：
- **业务域**（32个选项）— 超管驾驶舱/CRM/执行管理/D3/品牌中心等，已全量填充
- **Sprint**（6个选项）— Sprint-1到5 + Backlog，已填充749个（294个无Sprint标签）

**建议创建的视图**（需在[GitHub Web](https://github.com/orgs/WnadeyaowuOraganization/projects/4)手动创建）：
1. Board视图 — 按「业务域」分组，看各域进度
2. Table视图 — 按「Sprint」过滤，规划下一个Sprint
3. Roadmap视图 — 按业务域分组，时间线展示

**看板地址**: https://github.com/orgs/WnadeyaowuOraganization/projects/4
### Project#2 — 已废弃
> 2026-04-03 起 Project#2 不再使用。所有活跃 Issue 已迁移到 Project#4，wande-gh-plugins 的 22 个 Issue 也已迁移。Project#2 仅保留历史数据供追溯。
### 最近完成（wande-play 04-03）
- [后端重构] 合并 wande-ai-api 到 wande-ai，消除42个重复类冲突 #2585 → PR #2593
- [接口契约] 初始化 shared/api-contracts 目录与规范文档 #2586
- [项目矿场] 新增运营仪表盘页面 #870
- [项目矿场] 矿场运营仪表盘核心指标可视化 #869
- [前端] URL去.html后缀+域名统一 #868
### Sprint-2 调整记录（04-04）
- 新增H5移动端基座 8个Issue（#2625-#2632）：Vant4依赖安装、MobileLayout、TabBar导航、设备检测路由守卫、H5路由架构、企微SDK、移动端认证、CLAUDE.md开发规范
- Sprint-2 当前：84个有效Issue（76 + 8 H5基座）
### Sprint-2 调整记录（04-03）
- 关闭5个重复Issue：#2184→#2464, #2185→#2465, #2186→#2466, #2187→#2467, #2188→#2468
- #2085 变更→合同联动优先级 P1→P0
- 新增 #2506 EVM挣值管理简化版（module:fullstack, Sprint-2）
- Sprint-2 当前：76个有效Issue（81 - 5重复）
### 基础设施变更（04-03）
- E2E测试目录：wande-ai-e2e → wande-play-e2e-mid（中层）/ wande-play-e2e-top（顶层）
- 316个Issue批量关联到Project#4（之前仅在Project#2）
- 研发经理CC排程改为按重点模块分子目录（超管驾驶舱/销售记录体系/D3参数化/其他）
- query-project-issues.sh输出增加module/priority/labels列
- Claude Office新增CC实时日志显示（/api/logs端点 + 终端风格面板）
- 首个fullstack Issue #1440 创建（合并#443+#1166），用于Agent Teams测试
- Project#2废弃，wande-gh-plugins 22个Issue迁移到Project#4
- 测试架构改革落地：编程CC接管构建部署，build-deploy-dev.yml仅保留pipeline sync，新增pr-test.yml自动E2E+merge/fail
- CC prompt全面优化：研发经理(425→160行)、backend(45→28)、frontend(617→119)、E2E(263→80)
### 基础设施变更（04-05）— Harness优化V1
- CLAUDE.md精简：wande-play主CLAUDE.md 67→40行，删除3个子模块CLAUDE.md
- agent-docs子目录化：.github/docs/agent-docs/{backend,frontend,pipeline}/README.md集中管理
- 新增ESLint自定义规则：废弃API检查(visible→open) + 嵌套Drawer/Modal检查
- 新增antdv-constraints.md、console-monitor.ts、Issue模板(feature-request.yml)
- 编程CC工作流精简：去需求评估、task.md合并进度字段(Status/Phase)
- 模型分级路由：仅effort=max走Claude Max订阅，其余走Token Pool Proxy
- Token Pool Proxy新增上下文截断：keys.json配context_window(kimi 256K/glm 200K)
- run-cc.sh/run-cc-with-prompt.sh：按effort自动选择API来源
- 冲突解决全链路：analyze-conflict-type.sh + cycle-merge智能分类 + post-task.sh/pr-test.yml集成
- 安全边界：run-cc.sh最大重试3次 + cc-check.sh（原check-cc-status.sh）超时30分钟自动清理
- 过时文件清理：删除15个过时文档/脚本/prompt（旧版guide、迁移文档、废弃脚本等）
- wande-ai-api确认废弃：万德业务功能全部在wande-ai子模块实现
### 基础设施变更（04-06）— Harness优化V2 + Claude Office重构
- run-cc.sh改为--命名参数（--module/--issue/--dir/--effort/--prompt），消除下标解析bug
- run-cc.sh内置pre-task（自动checkout dev→pull→创建feature分支→校验分支名）
- run-cc.sh --module支持fullstack作为app别名
- run-cc.sh session名用真实目录名（cc-kimi1-backend-2854），server.py不再推断
- run-cc.sh Issue模式必须传--dir（主目录仅--prompt可用）
- query-project-issues.sh/update-project-status.sh改为--命名参数（兼容已删除）
- cycle-merge.sh支持指定PR号（--all批量模式保留）
- cycle-merge.sh合并trigger-conflict-resolver.sh功能
- 删除cc-stream-parser.py：tmux显示正常CLI界面，日志由JSONL直读
- 删除所有/home/ubuntu硬编码：统一HOME_DIR变量（30个文件）
- Claude Office server.py重写（2424→479行）：仅保留status/manager/logs/sprint/project 5个API
- Claude Office进程检测改为统一扫描claude进程按cwd分类（替代tmux+ps双重检测）
- Claude Office日志统一JSONL直读（编程CC/研发经理CC/E2E全部统一）
- Claude Office研发经理CC支持tab页切换会话日志
- Claude Office编程CC日志tab统一（所有活跃CC共享tab列表）
- Claude Office看板计数从GitHub Project#4 GraphQL API实时获取（后台30秒刷新）
- Claude Office日志滚动优化（翻看历史不跳转，滚到底部恢复跟随）
- pr-test.yml增加conflict-check job（E2E前解决冲突）
- pr-test.yml轻量smoke改用CI专用环境(:6041/:8084)
- pr-test.yml构建部署步骤按BACKEND_CHANGED/FRONTEND_CHANGED增量部署
- pr-test.yml E2E失败评论含错误详情（body-file方式避免YAML注入）
- pr-test.yml Issue号提取改用env传递PR body（修复shell注入漏洞）
- pr-test.yml E2E失败后自动触发CC修复（run-cc.sh --prompt）
- ~~ci-env.sh启动失败自动重新构建重试~~ (2026-04-08 删除：ci-env.sh 已废弃，逻辑内联到 pr-test.yml；fallback 旧版本是漏洞)
- 批量清理重复Bean定义（45个文件，-4187行）
- 编程CC文档统一迁移到.github/docs/agent-docs/（18个文件）
- 删除server_old.py等废弃文件
### 基础设施变更（04-06）— Claude Office平台增强
- Claude Office Safari/iPhone兼容：fetch改相对URL、100dvh、safe-area-inset、viewport-fit=cover
- Claude Office研发经理CC日志Tab重构：tmux_session/log_session分离，_scan_manager_tmux_sessions()按进程启动时间分配JSONL，Tab名cc-前缀截去org/repo前缀
- Claude Office SSE实时通知：ThreadingHTTPServer+/api/events SSE端点+Toast UI，替代8s轮询
- Claude Office Canvas取消拖拽：autoZoomFit()自适应铺满，跟随window.resize
- update-project-status.sh自动关联看板：ITEM_IDS为空时addProjectV2ItemById自动加入
- CLAUDE.md新增注入提示词和发送通知webhook两节指令
- 前端UI图形E2E测试：Playwright全面测试，发现P0 bug并创建Issue至E2E Fail状态
### 基础设施变更（04-07）— E2E与CC管理优化
- e2e_top_tier.sh重构：从claude -p headless+临时脚本改为交互式tmux+send-keys注入，对齐run-manager.sh保活模式（session存在跳过，cron每6h重启），新增_associate_jsonl JSONL关联供Claude Office日志展示，配置隔离同run-cc.sh Token Pool Proxy stub credentials
- assign-guide.md修正：Step顺序改为run-cc.sh成功后再标In Progress（原反序），删除死代码ISSUE_ASSIGN_HISTORY.md步骤
- check-cc-status.sh：去除超时自动kill+标Fail逻辑，改为30min发warning通知人工重启（防误杀正常CC）
- Reject Issue批量清理：121个Reject状态Issue全部标Done（均已CLOSED，为迁移/替代/过时旧需求）
### 矿场管线紧急修复（04-09）— 6个故障修复·管线恢复运转
- **根本原因**：Monorepo迁移后，Flyway创建的新表使用`wdpp_`前缀（如`wdpp_discovered_projects`），但4个旧脚本仍引用旧表名（如`discovered_projects`），导致`UndefinedTable`错误
- **故障1**：`project_verifier.py` — 旧表名`discovered_projects`+旧列名`created_at`/`updated_at` → 修复为`wdpp_discovered_projects`+`create_time`/`update_time`
- **故障2**：`match_grade_calculator.py` — 旧表名+`source_type`列不存在+`company_name`列不存在 → 修复为`source_name`+`NULL as company_name`
- **故障3**：`project_activity_monitor.py` — 旧表名 → 修复为`wdpp_discovered_projects`
- **故障4**：`tender_crawler_v3.py` — 旧表名`tender_data`+序列号不同步(next=10289 vs max=17080) → 修复表名+重置序列号
- **故障5**：`project_mine_pipeline.sh` — 缺执行权限(644→755)+SCRIPT_DIR指向旧路径`/opt/agent/` → 修复权限+改为wande-play路径
- **故障6**：SearXNG容器消失 → 重新启动(`--restart unless-stopped`)
- **附带修复**：安装`antiword`(kb_pipeline需要)、添加`relationship_score`列到`wdpp_discovered_projects`
- **正常运转的脚本**：`smart_project_discovery.py`和`project_mine_sync.py`（已在之前更新过表名）
- **验证结果**：6个管线全部恢复运转，tender_crawler首次运行即新增40条数据
- **Issue**：#3552 记录完整故障清单和修复过程
- **教训**：Monorepo迁移时需建立「表名/列名兼容性检查清单」，pipeline脚本应统一表名常量
### 基础设施变更（04-07）— Claude Office重构+文档体系整理
- Claude Office server.py四区域独立扫描：_scan_play_sessions/_scan_e2e_sessions/_scan_gh_plugins_sessions/_scan_manager_tmux_sessions，日志改tmux capture-pane直读（替代JSONL解析+SESSION_MAP），chrome行过滤（保留状态栏）
- get-gh-token.sh删除：逻辑合并到gh-app-token.py（e2e路径→wandeyaowu PAT，默认→GitHub App Token，兜底→weiping PAT），更新17处引用
- e2e_top_tier.sh：去除exec bash，CC退出后tmux会话自动关闭；testing-guide.md改为CC自行创建Issue+标签+通知，移至docs/agent-docs/e2e/
- 文档重命名：agent-docs/backend/README.md→backend-guide.md，frontend/README.md→frontend-guide.md，全路径索引，同步kimi1-20/ci/pr/main/e2e-top等24个仓库CLAUDE.md；第二轮补漏database-specification.md/frontend/CLAUDE.md共42个文件
- 单元测试H2→PostgreSQL迁移：新增scripts/ensure-test-pg.sh（wande-test-pg容器端口5434），backend-guide.md删H2章节，testing.md改为PG描述，.test-baseline=338
- 文档分层体系：新增docs/agent-docs/share/（shared-conventions/api-contracts/issue-workflow/db-schema），backend-guide/frontend-guide新增"共享文档"节全路径引用，agent-docs/README.md添加目录树+六层分层说明
## 📌 需要对方处理
### @伟平 待讨论
- ~~**dev分支后端无法启动（P0）**~~ — 已通过 #2585 / PR #2593 解决
### @吴耀
- ~~明道云 API Key — 解锁 CRM 对接~~ — 已确认：明道云仅做一次性数据迁移，平台上线后团队不再使用明道云。不需要CRM对接API Key，迁移数据已有(#2017/#2019/#2154)
- ~~ceshi.tiyouoperation.com 决策确认~~ — 已确认(D76)：测试环境 ceshi.tiyouoperation.com / 正式环境 www.tiyouoperation.com
- **【Sprint-3前必须完成】品牌中心多平台发布 — 外部平台授权** (2026-04-08)
  - 微信公众号：确认公众号已认证 → 提供 AppID + AppSecret → 配置IP白名单
  - 抖音/B站/小红书/YouTube：各平台注册开发者账号 → 创建应用 → 获取 OAuth 凭证
  - LinkedIn：注册 LinkedIn Developer App → 申请 Marketing API 权限 → 获取 Client ID/Secret
  - 说明：品牌中心 Phase2（#2058/#2059/#2195/#2199/#2200/#2202 等20个Issue）依赖这些凭证方可让 CC 开发发布集成
### @CC（研发经理）
- Sprint目标以本文件「当前目标」章节为准
- 完成一个重点功能后更新本文件的「工作状态」和「最近完成」

### @伟平 分支卫生+仓库设置决策（2026-04-09 代码↔Issue对账发现）
> ⚠️ 以下决策由Perplexity提出建议，需开发者确认后执行。吴耀明确不做此决策。
> 
> **误操作说明**: Perplexity在对账过程中误删了5个分支（feature-Issue-1626/1508/1696/1695/1756），这5个分支对应的Issue均已CLOSED且PR已merged（1756为closed未merge），无实际影响但操作不应在未经确认前执行。auto-delete设置已回滚为false。

✅ **D78: 开启仓库auto-delete head branches** — 已生效（2026-04-09，伟平确认）
- 现状：PR merge后feature分支不会自动删除，导致残留
- 对账发现：87个feature分支中78个对应Issue已CLOSED，占90%
- 建议：开启`delete_branch_on_merge=true`，从根源解决分支堆积
- 影响：未来所有PR merge后自动删除head branch
- 操作：GitHub仓库Settings → General → 勾选"Automatically delete head branches"

✅ **D79: 批量清理过期分支** — 已执行（2026-04-09）。共删除81个过期分支（76个feature-Issue-* + 5个旧格式feature/*）。保留11个Issue仍OPEN的分支
- 现状：87个feature分支中78个Issue已CLOSED + 4个旧格式feature/分支已过期（已误删5个，剩82个）
- 需保留的9个分支（Issue仍OPEN）：feature-Issue-1490/1505/1531/1597/1601/1630/1698/1702 + feature/issue-1946
- 建议：一次性脚本删除82个过期分支
- 风险：极低（对应Issue均已CLOSED，代码已在dev/main中）

✅ **D80: PR#3435** — 已关闭，Issue#2261已CLOSED，无需操作
- 现状：PR#3435（模板库管理页面）对应Issue#2261已CLOSED，PR在对账前就已是CLOSED状态
- 无需操作，仅记录



### 基础设施变更（04-12）— 新开发环境m7i.8xlarge + 编程环境整合

| 项 | 详情 |
|---|---|
| **环境迁移决策** | D78确认：G7e GPU利用率<1%，编程开发不需GPU。新增m7i.8xlarge(172.31.31.227)专用编程，降成本~87%/月($7000→$720 1年RI)；G7e保留GPU/模型服务；测试环境由dev(G7e 旧)→新m7i专用E2E目录 |
| **新机器配置** | m7i.8xlarge(32vCPU/128GB/1TB gp3) + PostgreSQL(5432/5433) + Redis(6380) + Docker + 20个kimi目录(kimi1-kimi20) + 38个项目目录(wande-play等) + Claude Code CLI + 所有基础脚本 |
| **编程环境架构** | 20个kimi目录独立隔离，各自后端port=7100+N、前端port=8100+N。nginx反向代理(端口8100+N→backend 7100+N)。Flyway自动建表，无手工setup。dev分支清零：仅含ruoyi-ai框架+V2菜单基线(V1__baseline.sql+V2__wande_menu_baseline.sql) |
| **菜单基线脚本** | `V2__wande_menu_baseline.sql`：368个INSERT(sys_menu)+595个INSERT(sys_role_menu)+5个UPDATE(隐藏旧菜单)，全部idempotent `ON CONFLICT DO NOTHING`。完整合并8个菜单重组Issue，创建Issue#3597 Tier-0 P0 |
| **排程计划生成** | `sprints/new-dev.md` 6-Tier 4周计划：Tier-0菜单验证→Tier-1 RBAC仪表盘(并行5CC)→Tier-2全球项目矿场(独立1-2CC，用户优先)→Tier-3/4/5/6；周进度表+CC分配曲线(Week1:4-5人→Peak周2:12-13→周3:8-9→周4:4-5) |
| **测试环境脚本** | ✅ `cc-test-env.sh`(启动/停止/重启/状态/端口)、`cc-test-run.sh`(smoke/api/spec/full + --compile)、`cc-test-nginx-setup.sh`(20个server block)。BASE_URL/BASE_URL_FRONT/BASE_URL_API环境变量补全，restart命令已添加 |
| **技能部署完成** | 9个技能全部部署到20个kimi目录：6个custom(e2e-test/smoke-scaffold/pr-preflight/screenshot/phase-report/flyway-validate) + 3个official(webapp-testing/frontend-design/skill-creator)。spot check验证kimi1/5/10/15/20全部就绪 |
| **开发者文档** | wande-play-kimi*/CLAUDE.md新增：快速启动命令+6个技能详细使用方式+board查询+design文档位置+FAQ+troubleshooting。绝对路径参考.github文档，避免相对路径解析错误 |
| **Claude Office整合** | systemd service启动(port 9872)+nginx反向代理(http://172.31.31.227:8083/cla/)。新增看板可视化(Project#4实时数据)+技能执行面板+日志查看(所有区域:play/e2e/gh-plugins/manager) |
| **验收标准达成** | ✅ 编程CC可在任意kimi目录快速启动、独立编译测试；✅ 菜单基线验证通过(8大工作区+角色权限)；✅ 排程计划确认(6 Tier优先级+CC资源分配)；✅ 全景服务(文档/脚本/技能/环境)完整可用 |

### 已完成（2026-04-12 新开发环境完整交付）
- ✅ 编程开发环境完全迁移到m7i.8xlarge (172.31.31.227)
- ✅ 20个kimi目录完整配置(后端+前端+Flyway)
- ✅ 菜单基线Issue#3597创建(V2脚本+8个重组合并)
- ✅ 排程计划sprints/new-dev.md生成(6 Tier+全球矿场Tier-2优先)
- ✅ 9个技能部署到所有kimi目录(custom+official全覆盖)
- ✅ E2E测试脚本完整(smoke/api/spec/full模式)
- ✅ nginx反向代理配置完成(20个server block)
- ✅ Claude Office整合(systemd+nginx+看板)
- ✅ 开发者文档完成(CLAUDE.md+快速启动)
- ✅ 技能验收通过(6个custom skill全部可用)

### 已完成（2026-04-09 代码↔Issue对账清理）
- ✅ 81个过期feature分支已删除（Issue均已CLOSED）
- ✅ auto-delete head branches 已开启（PR merge后自动清理分支）
- ✅ 238个空状态Issue已全部补设Plan状态（Project#4看板准确性恢复）
- ✅ #2028矿场Issue的错误biz:cockpit标签已移除
- ✅ 对账报告已存档：`.github/docs/code-issue-audit.md`
- ✅ 4个新biz:标签已创建：biz:acceptance / biz:change / biz:rectification / biz:collab
