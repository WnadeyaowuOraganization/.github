# 共享规范

> 本文档包含所有编程CC必须遵守的通用规则。

## 环境信息

| 服务 | Dev (G7e) | 生产 (Lightsail) |
|------|-----------|----------------- |
| 前端 | http://3.211.167.122:8083 | http://47.131.77.9 |
| 后端API | http://3.211.167.122:6040 | Docker |
| API代理 | :8083/prod-api/ → :6040 | nginx代理 |
| PostgreSQL | localhost:5433 / wande / wande_dev_2026 | Docker |
| Redis | localhost:6380 / redis_dev_2026 | Docker |

## Git 分支规范

| 分支 | 用途 |
|------|------|
| **main** | 生产分支，PR merge触发CI/CD → 构建 → Lightsail部署 |
| **dev** | 开发分支，PR merge到dev触发dev环境部署 |
| **feature-Issue-\<N\>** | 功能分支，从dev签出，创建PR到dev |

### 分支操作规则

- **只push feature分支**，不要push dev或main
- 开发任何代码前**必须**先检查当前分支，不在feature分支则从dev签出新分支
- feature分支命名格式：`feature-Issue-<N>` 或 `feature-<描述>`

## 数据库规范

### 表命名

- **新表必须用 `wdpp_` 前缀**（如 `wdpp_tender_project`）
- 必须包含 `create_time` / `update_time` 列（与BaseEntity一致）

### 列命名

- 后端 `BaseEntity` 要求表有 `create_time`/`update_time` 列
- 老表（`created_at`）需增量SQL迁移或Entity中 `@TableField("created_at")` 映射

### 数据源注解（后端）

万德业务 Mapper/Service 必须加 `@DS("wande")`：
- 不加会默认走master库导致运行时报错
- wande模块的表在wande_ai库中

## 构建规范

### 必须用ubuntu用户执行构建

**CC本身已在ubuntu用户下运行**，直接执行即可：

```bash
# CC环境下直接运行（CC已是ubuntu用户）
mvn clean compile
```

> `sudo -u ubuntu` 仅在当前是 root 用户时才需要（例如手动SSH进服务器以root身份操作）。
> 禁止用 root 执行 mvn，否则 target 目录权限变成 root 所有，导致后续 CI/CD Runner（ubuntu 用户）无法清理 target 目录而构建失败。

## GitHub CLI

```bash
# 获取Token
export GH_TOKEN=$(python3 $HOME_DIR/projects/.github/scripts/gh-app-token.py)

# 查看Issue
gh issue view <N> --repo WnadeyaowuOraganization/wande-play --comments

# 更新Project状态
bash $HOME_DIR/projects/.github/scripts/update-project-status.sh play <N> "<Status>"
```

## 认证机制

### 后端认证

HTTP状态码始终200，用 `body.code` 判断：
- `code: 200` = 成功
- `code: 401` = 未认证

### 前端认证

统一返回 `R<T>`：
- `R.ok(data)` = 成功
- `R.fail(msg)` = 失败

## 菜单机制（重要）

侧边栏菜单由**后端 `sys_menu` 表**驱动，不是前端路由静态定义。

新页面完整清单：
1. `views/wande/` 创建页面组件
2. `api/wande/` 创建API调用
3. **后端** 创建 `sys_menu` 增量SQL（决定菜单是否显示）
4. `component` 字段值匹配 `views/` 下的路径（不含 `views/` 前缀和 `.vue` 后缀）

调试菜单不显示：检查 `/system/menu/getRouters` 返回 → `sys_menu` 记录 → `sys_role_menu` 绑定 → `component` 路径。

## 组织信息

- **组织**: WnadeyaowuOraganization
- **Project看板（研发看板）**: https://github.com/orgs/WnadeyaowuOraganization/projects/4
- **CODEOWNERS**: @wandeyaowu
