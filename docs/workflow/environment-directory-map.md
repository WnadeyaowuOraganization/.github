# 万德AI 全环境工作目录视图

> 最后更新：2026-04-12 | 机器：M7i 172.31.31.227

---

## 一、代码仓库目录

```
~/projects/
├── wande-play/                    ← 基础目录（基线代码、基础设施文件修改处）
│                                     branch: dev
│
├── wande-play-kimi{1..20}/        ← 编程CC外接目录（20个并行开发槽位）
│   每个 kimi 目录独立 feature 分支，空闲时 checkout dev
│
├── wande-play-ci/                 ← CI 专用（pr-test.yml 构建+E2E）
│                                     branch: dev
├── wande-play-e2e-mid/            ← E2E 中级回归测试
├── wande-play-e2e-top/            ← E2E 全量回归测试
├── wande-play-merge/              ← 冲突合并专用
└── wande-play-pr/                 ← PR 创建专用
```

## 二、部署目录 `/apps/`

```
/apps/
├── wande-ai-backend/              ← 主Dev后端
│   ├── ruoyi-admin.jar               profile=test, port=6040
│   ├── start.sh                      root/root MySQL → wande-ai schema
│   └── logs/backend.log
│
├── wande-ai-backend-ci/           ← CI 后端（E2E测试用）
│   ├── ruoyi-admin.jar               profile=dev, port=6041
│   └── logs/
│
├── wande-ai-backend-kimi{1..20}/  ← 编程CC各自的后端实例
│                                     port=710{1..20}
│
├── wande-ai-front/                ← 主Dev前端（nginx :8080）
│   ├── index.html
│   ├── _app.config.js
│   ├── css/ js/
│   └── ...
│
├── wande-ai-front-ci/             ← CI 前端（nginx :8084）
│
└── wande-ai-front-kimi{1..20}/    ← 编程CC各自的前端
                                      port=810{1..20}
```

## 三、Nginx 端口分配

| 环境 | 前端端口 | 后端端口 | API路径 | Nginx配置文件 |
|------|---------|---------|---------|--------------|
| **主Dev** | `:8080` | `:6040` | `/api/` | `wande-dev` |
| **CI** | `:8084` | `:6041` | `/prod-api/` | `wande-ci` |
| **kimi1** | `:8101` | `:7101` | `/prod-api/` | `wande-kimi1` |
| **kimi2** | `:8102` | `:7102` | `/prod-api/` | `wande-kimi2` |
| ... | ... | ... | ... | ... |
| **kimi20** | `:8120` | `:7120` | `/prod-api/` | `wande-kimi20` |

Nginx 配置目录：`/etc/nginx/sites-enabled/`

## 四、数据库隔离

```
MySQL 8.0 (Docker: mysql-dev, port 3306)
├── wande-ai               ← 主Dev schema（root/root 独占）
├── wande-ai-kimi1         ← kimi1 专用（wande用户, wande-ai-% 通配符授权）
├── wande-ai-kimi2         ← kimi2 专用
├── ...
└── wande-ai-kimi20        ← kimi20 专用

Redis 7 (Docker: redis-dev, port 6379)  ← 所有环境共用
```

**用户权限**：
- `root` → 主 `wande-ai` schema（仅主Dev后端 application-test.yml 使用）
- `wande` → `wande-ai-%` 通配符（编程CC只能访问自己的 kimi schema）

## 五、经理CC工作目录

```
/data/home/ubuntu/projects/.github/     ← 排程经理 + 研发经理
├── CLAUDE.md                              角色指南入口
├── docs/
│   ├── status.md                          唯一真相源
│   └── agent-docs/                        CC指南文档
├── sprints/sprint-1/PLAN.md               排程计划
├── scripts/                               40+ 运维脚本
│   ├── run-cc.sh                          启动编程CC
│   ├── cc-check.sh                        CC状态总览
│   ├── post-cc-cleanup.sh                 CC退出后兜底清理
│   ├── inject-cc-prompt.sh                向活跃CC注入提示词
│   ├── update-project-status.sh           看板状态更新
│   └── ...
└── logs/                                  系统日志
```

## 六、CI/CD 流水线

```
PR创建 → pr-test.yml
           ├── conflict-check      冲突检测
           ├── unit-test            后端单元测试（wande-play-ci）
           ├── build                CI环境构建（:6041/:8084）
           ├── e2e-test             Playwright E2E
           ├── quality-gate         四道质量门
           └── auto-merge           ← 合并 + 内联CD部署
                ├── squash merge
                ├── 后端: mvn → /apps/wande-ai-backend/ → 重启 → 健康检查
                ├── 前端: pnpm build → /apps/wande-ai-front/ → nginx reload
                ├── close Issue
                └── 标 Done

build-deploy-dev.yml                ← 备用CD（push to dev 触发，因token限制通常不被auto-merge触发）
```

**为什么 CD 内联在 pr-test.yml 而不是独立 workflow**：
GitHub Actions 安全限制 — 一个 workflow 中的 token（无论 GITHUB_TOKEN 还是 App Token）产生的事件不会触发其他 workflow。auto-merge 后的 push 事件不会触发 `build-deploy-dev.yml`，所以部署步骤必须内联在同一个 job 中。

## 七、Maven 缓存隔离（`/dev/shm` tmpfs）

```
~/.m2-base/repository              ← 磁盘持久化 base (586MB)
/dev/shm/m2-base/repository        ← 共享只读 base（第一个CC启动时cp进去）
/dev/shm/m2-cc-kimi{N}/repository  ← 每个CC独立写入区
/dev/shm/m2-cc-dev-deploy/         ← CD部署用
/dev/shm/m2-cc-ci-*/               ← CI构建用
```

**隔离机制**：`m2-cc-prepare.sh` 分配独立 tmpfs 区，`m2-cc-cleanup.sh` 释放 + refcount 管理共享 base。避免 hardlink 导致的元信息跨 kimi 污染。

## 八、CC 会话管理

```
~/cc_scheduler/lock/
├── wande-play-kimi1.lock          ← 编程CC锁文件
├── wande-play-kimi2.lock             内含: issue=XXXX, state=WORKING/DONE
├── ...                               m2_repo=/dev/shm/m2-cc-kimiN/repository
└── wande-play-kimi20.lock

tmux 会话命名: cc-wande-play-kimi{N}-{ISSUE}
```

**生命周期**：`run-cc.sh` 创建锁+tmux → 编程CC工作 → CC退出 → `POST_EXIT_CMD`（set-lock-state DONE + post-cc-cleanup + cc-test-env stop）
