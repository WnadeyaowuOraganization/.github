# 测试架构改革方案（已实施）

> 状态：已实施 | 创建：2026-04-03 | 实施：2026-04-03

## 目标

将测试环节从 AI 驱动改为 CI/CD 驱动，减少模型调用，提高效率和可靠性。

## 最终架构

```
编程CC: TDD → build → deploy-dev → smoke → push feature → create PR → done
CI (pr-test.yml): PR event → E2E test → auto merge or test-failed
CI (build-deploy-dev.yml): dev push → pipeline sync only
Cron: 2h mid-tier E2E (兜底) + 6h top-tier regression
```

## 三层测试体系

| 层级 | 触发方式 | 范围 | 频率 | AI参与 |
|------|---------|------|------|--------|
| 编程CC内建 | 编程CC开发流程中 | TDD + build + deploy + smoke | 每次开发 | 编程CC自身 |
| PR E2E | PR 创建/更新 → pr-test.yml | 按变更模块完整E2E | 每次PR | 仅失败分析 |
| Cron兜底 | crontab 定时 | mid: 按模块 / top: 全量回归 | 2h / 6h | 仅创建Issue |

## 编程CC开发流程

```
1. TDD: 写测试 → 写代码 → 通过
2. build: pnpm build / mvn compile
3. deploy-dev: 构建Docker + 部署到Lightsail测试环境
4. smoke: 快速验证部署成功
5. push feature → create PR → done（编程CC工作结束）
```

关键变更：构建部署由编程CC在feature分支完成，不再由CI负责。

## PR 测试流水线 (pr-test.yml)

```
PR 创建/更新 → CI 触发
  Step 1: checkout dev 分支
  Step 2: 按变更模块跑 E2E 测试
  Step 3: 通过 → auto approve + merge + Issue 标 Done
  Step 4: 失败 → PR评论失败详情 + Issue 标 test-failed
```

## dev push 流水线 (build-deploy-dev.yml)

```
dev push → CI 触发
  仅检查 pipeline/ 目录变更 → 同步到G7e基础目录
```

已删除 build-backend-dev 和 build-frontend-dev jobs。

## Cron E2E 测试

| 脚本 | 频率 | 工作目录 | 内容 |
|------|------|---------|------|
| e2e_mid_tier.sh | 每2小时 | /home/ubuntu/projects/wande-play-e2e-mid | git checkout dev, 按模块E2E |
| e2e_top_tier.sh | 每6小时 | /home/ubuntu/projects/wande-play-e2e-top | git checkout dev, 全量回归 |

## 已废弃

- post-task.sh: PR创建已由编程CC直接完成
- CI快速验证(quick-verify): 编程CC内建smoke替代
- CI构建部署(build-backend-dev, build-frontend-dev): 编程CC直接完成
- 旧E2E工作目录: wande-ai-e2e, wande-ai-e2e-full, wande-play-e2e-full（已删除）

## 角色分工

| 角色 | 职责 |
|------|------|
| 编程CC | TDD + 构建 + 部署 + smoke + push + PR创建 |
| pr-test.yml | E2E测试 + auto merge/fail |
| build-deploy-dev.yml | pipeline代码同步 |
| E2E CC (cron) | 兜底回归测试 + 失败后创建Issue |
| 测试CC | 补充测试用例 + 分析复杂失败 |
