# 后端CC完整指南

> 后端CC负责万德AI平台Spring Boot后端的TDD开发。

## 技术栈

- **框架**: Spring Boot (RuoYi框架)
- **ORM**: MyBatis-Plus
- **数据库**: PostgreSQL (多数据源)
- **认证**: Sa-Token

## 项目结构

| 目录 | 内容 |
|------|------|
| `ruoyi-modules/wande-ai` | **唯一业务模块**：Entity/Mapper/Service/Controller 全部在此 |
| `ruoyi-modules-api/wande-ai-api` | ⚠️ **已废弃（D44）**，禁止新增业务代码，仅保留历史引用 |

> **重要**：新功能代码必须全部写在 `ruoyi-modules/wande-ai/` 下，不要碰 `wande-ai-api`。

## 核心规则

1. **测试先行（TDD）** — 理解Issue后第一件事是编写/补充单元测试
2. **万德业务Mapper/Service必须加 `@DS("wande")`** — 不加会默认走master库导致运行时报错
3. **必须用ubuntu用户执行构建** — root执行会导致CI/CD Runner权限失败
4. **数据库新表必须用 `wdpp_` 前缀** + `create_time`/`update_time` 列
5. **每个Issue必须有对应测试** — 没有测试 = 没完成
6. **编译检查必须通过** — 提交前 `mvn clean package -Pprod -Dmaven.test.skip=true` 必须成功
7. **只push feature分支** — 创建feature->dev的PR
8. **创建新类前必须查重** — 已有同名类则复用扩展
9. **禁止直接编辑 `schema.sql`** — 所有新表必须放入 `schemas/issue_XXXX.sql`

## TDD开发流程

### Step 0: 查重（创建任何新类之前必须执行）

```bash
grep -rn "class 类名" --include="*.java" backend/ | grep -v target
```

如果已存在同名类，直接复用或扩展，禁止在新包下重复创建。

### Step 1: 单元测试先行

1. 分析Issue需要测试的Service方法
2. 编写 `src/test/java/` 下的 `XxxServiceTest.java`（继承 `BaseServiceTest`）
3. 运行确认红灯：`mvn test -pl ruoyi-modules/wande-ai -Dtest=XxxServiceTest`

### Step 2: 编写业务代码

1. Entity -> Mapper -> Service -> Controller
2. 持续运行测试确认绿灯
3. 全量测试无回归：`mvn test -pl ruoyi-modules/wande-ai`

### Step 3: 编译检查

```bash
mvn clean package -Pprod -Dmaven.test.skip=true
```

编译失败必须修复，不管是否与当前Issue相关。

## 包路径规范

所有新功能统一放在 `ruoyi-modules/wande-ai/`，包路径模板：

```
org.ruoyi.wande.{feature}.domain.entity.XxxEntity   <- 实体
org.ruoyi.wande.{feature}.domain.vo.XxxVo           <- VO
org.ruoyi.wande.{feature}.domain.bo.XxxBo           <- BO
org.ruoyi.wande.mapper.{feature}.XxxMapper           <- Mapper
org.ruoyi.wande.service.{feature}.IXxxService        <- Service接口
org.ruoyi.wande.service.{feature}.impl.XxxServiceImpl <- Service实现
org.ruoyi.wande.controller.{feature}.XxxController   <- Controller
```

**禁止**：
- 使用旧路径 `org.ruoyi.wande.domain.{feature}.*`（会与新结构冲突导致 MyBatis alias 重复）
- 在 `wande-ai-api` 下新建业务代码
- 跳过查重直接创建新类

> 新增 domain 包后，必须在 `ruoyi-admin/src/main/resources/application.yml` 的 `typeAliasesPackage` 列表中追加，否则 XML 别名会报 ClassNotFoundException。

## 代码模板

### Entity

```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("table_name")
public class XxxEntity extends BaseEntity {
    @Serial
    private static final long serialVersionUID = 1L;
    @TableId(value = "id")
    private Long id;
    // 其他字段...
}
```

### Mapper

```java
@DS("wande")   // 万德业务表必须加
@Mapper
public interface XxxMapper extends BaseMapperPlus<XxxEntity, XxxVo> {
    // 复杂查询在 resources/mapper/XxxMapper.xml 中定义
}
```

### Service

```java
// 接口：I 前缀
public interface IXxxService extends IService<XxxEntity> { }

// 实现：Impl 后缀
@Service
public class XxxServiceImpl extends ServiceImpl<XxxMapper, XxxEntity> implements IXxxService { }
```

### Controller

```java
@RestController
@RequestMapping("/wande/xxx")
@RequiredArgsConstructor
public class XxxController {
    private final IXxxService xxxService;

    @SaCheckPermission("wande:xxx:list")
    @GetMapping("/list")
    public R<PageInfo<XxxVo>> list(XxxBo bo, PageQuery pageQuery) {
        return R.ok(xxxService.queryPageList(bo, pageQuery));
    }
}
```

## 单元测试规范

### 编写规范

- 文件位置：`src/test/java/` 对应包下
- 命名：`XxxServiceTest.java`
- 继承：`BaseServiceTest`（自动配置H2内存数据库 + @Transactional回滚）
- 最少覆盖：创建、查询、更新、删除（针对Service层核心方法）

### 测试策略

| Issue类型 | 测试要求 |
|-----------|---------|
| 新增Service/功能 | 创建 `XxxServiceTest.java`，覆盖核心CRUD方法 |
| 修改已有Service | 在已有Test中补充新增/变更方法的测试用例 |
| Bug修复 | 编写能复现Bug的回归测试 |
| Controller新增 | 创建 `XxxControllerTest.java` |
| 纯配置/文档变更 | 可跳过单元测试（在task.md中说明原因） |

### 运行命令

```bash
# 运行单个测试类
mvn test -pl ruoyi-modules/wande-ai -Dtest=XxxServiceTest

# 运行wande-ai模块全量测试
mvn test -pl ruoyi-modules/wande-ai

# 运行全项目测试
mvn test
```

## 门禁检查

| 检查项 | 命令 | 状态 |
|--------|------|------|
| 单元测试已写 | 检查 `src/test/java/` 下有新增/修改的测试文件 | PASS |
| 单元测试全部通过 | `mvn test -pl ruoyi-modules/wande-ai` | PASS |
| mvn clean compile 编译通过 | `mvn clean compile -Pprod -DskipTests` | PASS |
| 无新增编译警告 | 检查编译输出 | PASS |

## 数据库变更管理规范

### 新增数据库表

#### 步骤 1：创建 H2 测试脚本（必须先做）

**位置**: `backend/ruoyi-modules/wande-ai/src/test/resources/schemas/`
**文件名**: `issue_XXXX.sql`（XXXX 是 Issue 号）

```sql
-- H2 测试 Schema - Issue #XXXX
CREATE TABLE IF NOT EXISTS wdpp_xxx (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);
```

#### 步骤 2：创建 PostgreSQL 增量脚本

**位置**: `backend/script/sql/update/wande_ai/`
**文件名**: `create-<表名>-issue-XXXX.sql`

```sql
-- 变更说明：创建 XXX 表 - Issue #XXXX
-- 变更日期：2026-04-05

CREATE TABLE IF NOT EXISTS wdpp_xxx (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_by BIGINT,
    update_by BIGINT,
    create_dept BIGINT
);
```

#### 步骤 4：验证

```bash
cd backend && mvn test -pl ruoyi-modules/wande-ai
```

### PostgreSQL -> H2 语法转换

| PostgreSQL | H2 |
|------------|-----|
| `BIGSERIAL` | `BIGINT AUTO_INCREMENT` |
| `SERIAL` | `INT AUTO_INCREMENT` |
| `TEXT` | `CLOB` |
| `JSONB` | `VARCHAR(4000)` |

### 修改现有表

H2脚本文件名: `_alter_issue_XXXX.sql`（alter 前缀）

```sql
ALTER TABLE wdpp_xxx ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
```

### 数据库变更检查清单

- [ ] 创建了 `schemas/issue_XXXX.sql`（无需修改任何配置，测试启动时自动加载）
- [ ] 创建了增量脚本
- [ ] 没有直接编辑 `schema.sql`

## API集成测试

确认E2E项目中有对应的API测试：
- 查看 `$HOME_DIR/projects/wande-ai-e2e/tests/api/` 是否有本模块的测试文件
- 如果没有，创建 `tests/api/<module-name>.spec.ts` 基本测试

## 详细文档（按需阅读）

| 文档 | 内容 | 何时读取 |
|------|------|---------|
| [**common-pitfalls.md**](/home/ubuntu/projects/.github/docs/agent-docs/backend/common-pitfalls.md) | **⚠️ 必读：高频错误与规范，CI 曾踩过的坑** | **开始每个 Issue 前** |
| [architecture.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/architecture.md) | 项目概述、技术栈、构建命令 | 首次接触项目时 |
| [conventions.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/conventions.md) | Entity/Mapper/Service/Controller编码模板 | 写代码时 |
| [db-schema.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/db-schema.md) | 数据库变更管理、增量SQL流程 | 涉及数据库变更时 |
| [testing.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/testing.md) | TDD流程、单元测试、质量门禁 | 每次开始新Issue时 |
| [workflow.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/workflow.md) | TDD三阶段开发流程 | 每次开始新Issue时 |
| [menu-config.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/menu-config.md) | 菜单与权限注册（sys_menu） | 新增功能模块时 |
| [wechat-integration.md](/home/ubuntu/projects/.github/docs/agent-docs/backend/wechat-integration.md) | 企微/微信集成规范 | 涉及企微功能时 |
