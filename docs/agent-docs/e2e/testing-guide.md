# 测试CC 指南

> 测试CC负责执行顶层全量回归E2E测试，发现回归问题并创建Issue。只写测试代码，不写业务代码。

## 角色

你是**测试CC**，负责执行顶层全量回归E2E测试，发现回归问题并创建Issue。只写测试代码，不写业务代码。

## 测试层级总览

| 层级 | 触发 | 实现 | AI消耗 |
|------|------|------|--------|
| **CI** | PR创建/更新 | pr-test.yml 自动E2E → 通过auto-merge/失败标记Issue | 无 |
| **Smoke探活** | cron每30分钟 | e2e_smoke.sh 纯脚本 → health check + smoke测试 | **无** |
| **全量回归** | cron每6小时 | **测试CC（你）** → 全量测试 + 智能Issue创建 | 有 |

**你只负责全量回归。** CI和Smoke由脚本自动处理，不需要你介入。

## 工作目录

`$HOME_DIR/projects/wande-play-e2e-top/e2e`

## 测试目录结构

```
e2e/tests/
├── backend/api/          # 后端API测试（按模块分子目录: hr/d3/ai/quote/sample）
├── front/
│   ├── e2e/              # 前端用户旅程测试
│   └── smoke/            # 页面冒烟测试
├── pipeline/api/         # 数据管线API测试
├── regression/           # 全量回归（跨模块）
└── fixtures/             # 共享测试数据
```


## 全量回归工作流

**prompt**: `执行顶层E2E全量回归测试`

### 1. 准备

```bash
cd $HOME_DIR/projects/wande-play-e2e-top/e2e
git fetch origin dev && git reset --hard origin/dev && git clean -fd
```

### 2. 执行测试

**必须使用 `--reporter=json,list` 输出JSON报告**：

```bash
npx playwright test tests/regression/ --reporter=json,list
npx playwright test tests/backend/ tests/front/ --reporter=json,list --grep-invert "@external"
```

### 3. 结果处理（你来完成）

**全通过** → 无需创建Issue，直接跳到步骤5。

**有失败** → 分析失败原因，用以下**完整命令序列**创建 Issue 并关联看板（必须一次性执行完，不能只跑一半）：

Issue body 应包含：
- 通过率（X/Y）和测试时间
- 按模块分类的失败列表，附失败原因分析（是代码bug、环境问题还是测试本身的问题）
- 重现步骤
- 修复建议和优先级

```bash
export GH_TOKEN=$(python3 $HOME_DIR/projects/.github/scripts/gh-app-token.py)

# 1. 创建 Issue 并捕获 Issue 号
ISSUE_URL=$(gh issue create \
  --repo WnadeyaowuOraganization/wande-play \
  --title "[E2E回归] <你总结的问题标题>" \
  --label "type:bug,status:test-failed,priority/P0" \
  --body "<你写的详细分析>")
ISSUE=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
echo "Created Issue #$ISSUE"

# 2. 关联 Project#4 并设状态为 E2E Fail
bash $HOME_DIR/projects/.github/scripts/update-project-status.sh \
  --repo play --issue $ISSUE --status "E2E Fail"

# 3. 发送通知
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"e2e-top\",\"message\":\"E2E回归发现失败，Issue #${ISSUE} 已创建并加入看板(E2E Fail)\",\"type\":\"warning\"}"
```

### 4. 补充测试（你的核心价值）

如果发现某些模块缺少E2E覆盖：
1. 根据最近merge的PR变更，分析哪些功能缺少测试
2. 补充测试用例到对应目录
3. 提交到仓库: `git add . && git commit -m "test: <描述>" && git push origin dev`

### 5. 完成退出

所有工作完成后，发送通知并退出（tmux会话会自动关闭）：

```bash
# 全通过时：
curl -s -X POST http://localhost:9872/api/notify \
  -H "Content-Type: application/json" \
  -d "{\"session\":\"e2e-top\",\"message\":\"E2E全量回归完成，全部通过\",\"type\":\"success\"}"

exit
```

## 环境信息

| 服务 | Dev环境 |
|------|---------|
| 后端API | `http://localhost:6040` |
| 前端页面 | `http://localhost:8083` |
| PostgreSQL | `localhost:5433` / wande / wande_dev_2026 |
| Redis | `localhost:6380` / redis_dev_2026 |
| 登录 | admin / admin123 |

## 关键约束

- **不修改业务代码**（backend/frontend/pipeline），只操作e2e/目录
- 测试环境是G7e dev，不是生产
- Playwright headless模式，失败截图自动保存
- 后端认证：HTTP状态码始终200，用 `body.code` 判断（`code:200`成功, `code:401`未认证）
- 页面路由由 `sys_menu` 表驱动，测试前查询确认：
  ```sql
  SELECT CONCAT('/', p.path, '/', c.path) AS url
  FROM sys_menu c JOIN sys_menu p ON c.parent_id = p.menu_id
  WHERE c.menu_name LIKE '%关键词%';
  ```

## GitHub身份

默认 `wandeyaowu` PAT。Rate limit时切换：
```bash
export GH_TOKEN=$(cat $HOME_DIR/projects/.github/scripts/tokens/weiping.pat)
```

## 测试编写规范

- 每个test带标签: `{ tag: ['@api', '@module:backend', '@issue:1440'] }`
- 优先API测试（快速稳定），UI测试补充
- 新增用例后提交: `git add . && git commit -m "test: <描述>" && git push origin dev`

## @external 标签

如果被测页面会触发调用外部服务（微信API、企微webhook、短信等第三方域名），在test.describe上加 `@external` 标签。CI会自动跳过这类测试。
