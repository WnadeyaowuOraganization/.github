# Jenkins CI 流水线

## 概述

Jenkins 运行 wande-play PR 完整流水线：冲突检测 → 质量门控 → 单元测试 → CI DB修复 → Flyway预校验 → E2E测试 → 自动合并 → 部署 → 关闭Issue

**访问**: http://54.234.200.59:18080/jenkins/job/wande-play-pr/

## 凭证（静态 PAT，过期需手动更新）

| ID | 类型 | 用途 |
|----|------|------|
| `github-bot-token` | StringCredentials (Secret text) | git clone + Flyway预校验 |
| `github-weiping-token` | StringCredentials (Secret text) | 冲突检测 + 自动合并PR |

**凭证由 `/home/ubuntu/.jenkins/init.groovy.d/jenkins-init.groovy` 在 Jenkins 启动时从 token 文件自动创建**。Token 文件位置：
- `github-bot-token`: `/home/ubuntu/projects/.github/scripts/tokens/bot.token`
- `github-weiping-token`: `/home/ubuntu/projects/.github/scripts/tokens/weiping.pat`

凭证过期后：更新 token 文件 → 重启 Jenkins（init groovy 会重建）。

**Jenkins Home**：`/home/ubuntu/.jenkins/`（非 `/var/lib/jenkins/`）。凭证存储在 `~/.jenkins/credentials.xml`。
修改凭证方式：① Groovy Script Console（需认证）② 直接改 XML + `POST /jenkins/reload` 热加载 ③ 重启 Jenkins。

## Webhook 触发

GitHub Webhook → `http://54.234.200.59:18080/jenkins/generic-webhook-trigger/invoke?token=wande-play-pr`

触发条件：`opened | synchronize | reopened`

## 流水线阶段

| 阶段 | 说明 |
|------|------|
| 冲突检测 | `weiping-token` 检测 MERGEABLE，冲突则自动 resolve |
| 质量门控 | 6道门（PR body/task.md/截图/smoke/端口/路径） |
| 单元测试 | `mvn package -pl ruoyi-modules/wande-ai -am -Pprod`（产 jar 供 E2E） |
| E2E测试 | `start-all.sh` 启动前后端 → Playwright 按 PR 变更过滤测试 |
| 自动合并 | `gh pr review --approve && gh pr merge --squash` |
| 部署 | backend: `mvn package` → start.sh；frontend: `pnpm build:antd` → rsync |
| 关闭Issue | gh issue close + 看板 Project Done |

## 文件说明

| 文件 | 说明 |
|------|------|
| `Jenkinsfile` | 主流水线脚本 |
| `start-all.sh` | E2E 前后端启动（跳过 mvn package，复用已构建 jar） |
| `quality-gate.sh` | 质量门控 6 道检查 |
| `notify-failure.sh` | 失败时评论 PR |
| `cycle-merge.sh` | 自动解决 PR 冲突 |
| `update-project-status.sh` | 关闭 Issue + 看板 Done |
| `release-cc-lock.sh` | 释放 kimi 目录锁 |
| `setup-jenkins.sh` | 首次配置脚本（创建凭证 + Pipeline Job） |
| `github-webhook-trigger.sh` | GitHub Webhook 回调脚本（参考） |

## CI 环境参数

| 参数 | 值 | 说明 |
|------|---|------|
| `CI_WORK_DIR` | `/home/ubuntu/projects/wande-play-ci` | PR 代码克隆目录 |
| `CI_BACKEND_PORT` | `6041` | CI 后端端口 |
| `CI_FRONTEND_PORT` | `8084` | CI 前端端口 |
| `CI_DB_NAME` | `wande-ai-ci` | CI 数据库名 |
| `WANDE_DIR` | `/home/ubuntu/projects/wande-play` | dev 部署基准目录 |
| `JENKINS_DIR` | `/home/ubuntu/projects/.github/jenkins` | 本目录 |
| `SCRIPTS_DIR` | `/home/ubuntu/projects/.github/scripts` | 共享脚本目录 |

## E2E 测试过滤

`gh pr diff --name-only` 检测变更路径：
- `backend/` 变更 → 跑 `tests/backend/`
- `frontend/` 变更 → 跑 `tests/backend/ + tests/front/`
- 无两端变更 → 降级跑 `tests/backend/` smoke 兜底

## 故障排除

### Jenkins 重启
```bash
sudo pkill -f jenkins.war
sudo systemctl start jenkins
# 等待约30秒后访问
curl -s http://localhost:18080/jenkins/api/json
```

### 凭证类型错误
Build 报错 `Credentials type mismatch` → 检查 `init.groovy.d/jenkins-init.groovy` 使用的是 `StringCredentialsImpl` 而非 `UsernamePasswordCredentialsImpl` → 重启 Jenkins

### 凭证过期
更新 `/home/ubuntu/projects/.github/scripts/tokens/bot.token` 或 `weiping.pat` → 重启 Jenkins → init groovy 自动重建凭证

### Webhook 不触发
检查 GitHub Webhook 配置 → Recent Deliveries 是否有 200 响应
