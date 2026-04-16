---
name: backend-coding
description: Write Spring Boot 3 backend Java code for Wande-Play following RuoYi-Vue-Plus conventions. Covers mandatory package path (wande.{feature}.domain not wande.domain.{feature}), ServiceImpl extends ServiceImpl<Mapper,Entity> (not bare implements), ComponentScan for com.wande.ai, typeAliasesPackage registration, R.ok/fail + TableDataInfo.build response format, no wande-ai-api business code, no @DS annotation, MyBatis XML cleanup rules, and Bean-name conflict avoidance.
---

# 后端编码规范

Spring Boot 3 + MyBatis-Plus + Sa-Token + RuoYi-Vue-Plus。**业务代码只能写在 `ruoyi-modules/wande-ai/`**。

## 模块归属（强制）

| 位置 | 允许放什么 |
|------|---------|
| `backend/ruoyi-modules/wande-ai/` | ✅ Entity / Mapper / ServiceImpl / Controller / XML — 全部新业务代码 |
| `backend/ruoyi-modules-api/wande-ai-api/` | ⚠️ **D44 已废弃**。只允许跨模块共享接口 / DTO / 枚举，**禁止**新增业务实现 |

违反 = 启动冲突 / CI 报错。

## 包路径（强制新模板）

```
org.ruoyi.wande.{feature}.domain.entity.XxxEntity
org.ruoyi.wande.{feature}.domain.vo.XxxVo
org.ruoyi.wande.{feature}.domain.bo.XxxBo
org.ruoyi.wande.mapper.{feature}.XxxMapper
org.ruoyi.wande.service.{feature}.IXxxService
org.ruoyi.wande.service.{feature}.impl.XxxServiceImpl
org.ruoyi.wande.controller.{feature}.XxxController
```

**禁止** `org.ruoyi.wande.domain.{feature}.*`（旧风格与新结构冲突，MyBatis alias 重复）。

新增 `domain` 包时，**必须同步更新** `ruoyi-admin/src/main/resources/application.yml` 的 `typeAliasesPackage` 列表追加新包，否则 XML 用类名短别名报 `ClassNotFoundException`。

## ComponentScan（新 `com.wande.ai` 包必读）

主类在 `org.ruoyi.*`，默认只扫 `org.ruoyi.**`。若必须放 `com.wande.ai` 下，需确认存在配置类：

```java
@Configuration
@ComponentScan("com.wande.ai")
public class WandeAiModuleConfig { }
```

API 返回 404 且代码编译正常 = 八成是 ComponentScan 漏配。

## 代码模板

### Entity

```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("wdpp_xxx")
public class XxxEntity extends BaseEntity {
    @Serial private static final long serialVersionUID = 1L;
    @TableId(value = "id")
    private Long id;
    private String title;
    // JSON 列统一用 String 存，Service 层反序列化
    @TableField(value = "config_json")
    private String configJson;
}
```

### Mapper（单库，**无 @DS**）

```java
@Mapper
public interface XxxMapper extends BaseMapperPlus<XxxEntity, XxxVo> {
    // 复杂查询在 resources/mapper/<feature>/XxxMapper.xml
}
```

删除 Mapper 接口时 **同步删除** `resources/mapper/` 下同名 XML，否则启动报 `ClassNotFoundException`。

### Service（必须 extends ServiceImpl）

```java
public interface IXxxService extends IService<XxxEntity> {
    TableDataInfo<XxxVo> queryPageList(XxxBo bo, PageQuery pageQuery);
}

@Service
@RequiredArgsConstructor
public class XxxServiceImpl extends ServiceImpl<XxxMapper, XxxEntity>
        implements IXxxService {
    // extends ServiceImpl<Mapper, Entity> 必须，否则缺 getBaseMapper/getEntityClass 抽象方法
}
```

**Bean 名冲突**：两个包下同名 `XxxServiceImpl` → Spring `ConflictingBeanDefinitionException`。遗留类改名或显式 `@Service("legacyXxxServiceImpl")`；Mapper 接口只能重命名类（`@Mapper` 不支持 value）。

### Controller

```java
@RestController
@RequestMapping("/wande/xxx")
@RequiredArgsConstructor
public class XxxController {
    private final IXxxService xxxService;

    @SaCheckPermission("wande:xxx:list")
    @GetMapping("/list")
    public TableDataInfo<XxxVo> list(XxxBo bo, PageQuery pageQuery) {
        return xxxService.queryPageList(bo, pageQuery);
    }

    @SaCheckPermission("wande:xxx:add")
    @PostMapping
    public R<Void> add(@Validated @RequestBody XxxBo bo) {
        xxxService.insertByBo(bo);
        return R.ok();
    }
}
```

## 响应格式（违反导致前端弹错、不展示数据）

| 场景 | 必须 | 禁止 |
|------|------|------|
| 列表 | `return TableDataInfo.build(list);` | `new TableDataInfo<>()` 手设字段（丢 code/msg，前端拦截器判失败）|
| 单体 | `R.ok(data)` / `R.fail(msg)` | 手动 `new R<>()` |

HTTP 状态码恒 200，前端用 `body.code` 判定（`200` 成功 / `401` 未认证）。

## MyBatis XML：复杂类型字段

VO 含嵌套类型或 `List<T>` 时，XML `<resultMap>` 直接映射报 `No typehandler found`。正解：

**方案 A（推荐）**：XML 映射到 Entity（`String` 字段），Service 层 `ObjectMapper.readValue` 转 VO。

**方案 B**：指定 `typeHandler`

```xml
<result property="complexField" column="json_column"
        typeHandler="com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler"/>
```
```java
@TableField(typeHandler = JacksonTypeHandler.class)
private ComplexType complexField;
```

`List<T>` 泛型建议用方案 A（泛型擦除 + TypeHandler 易踩坑）。

## 查重（创建新类前必做）

```bash
grep -rn "class 类名" --include="*.java" backend/ | grep -v target
```

存在同名 → 复用或扩展，禁止在新包下重复创建（会触发 Bean 冲突或 alias 重复）。

## 租户隔离

- `tenant_id` 由 `TenantLineInnerInterceptor` 自动注入，**Service 层不要手动 set**
- 查询不要手动 `eq("tenant_id", ...)`，拦截器自动拼 WHERE
- 若需跨租户查询，在 application.yml `tenant.excludes` 列表排除该表

## 禁止清单

- ❌ 新建类放 `com.wande.*` 包（主类仅扫 `org.ruoyi.**`，落到 `com.wande.*` → API 404 / Bean 不注册；#3517 踩过）。新代码**只**用 `org.ruoyi.wande.*`，除非已显式配置 `@ComponentScan("com.wande.ai")`
- ❌ `@DS("wande")` / `@DS("slave")` / `@DS("master")` — 单库无多数据源
- ❌ 在 `wande-ai-api` 新增业务代码（已废弃）
- ❌ `wande.domain.{feature}` 旧包路径
- ❌ `implements IXxxService` 只 implements 不 extends ServiceImpl
- ❌ `@Transactional` 不写 `rollbackFor = Exception.class`（只回滚 RuntimeException）
- ❌ `SELECT *` — 用显式字段或 XxxVo
- ❌ Controller 直接用 Entity — 用 BO / VO 隔离
- ❌ `System.out.println` — 用 `@Slf4j` + `log.info/warn/error`
- ❌ root 用户跑 `mvn`（target 权限污染）— 用 ubuntu
- ❌ push `dev` / `main`，只能 push `feature-Issue-<N>`
- ❌ 删 Mapper 接口不删 XML
- ❌ **`mysql -h 127.0.0.1 -uroot -proot ...` 从宿主机裸连**（4 次已触发自动止血）— 属红线 #3 环境隔离违规，容易连错库。**必须**走 docker exec：
  ```bash
  docker exec mysql-dev mysql -uroot -proot -D wande-ai-kimi<N>
  # 或用低权限 wande 用户：-uwande -pwande_dev_2026
  ```
  容器名是 `mysql-dev`（`docker ps` 可查）。**只**允许查自己的 schema `wande-ai-kimi<N>`，**禁止**访问主库 `wande-ai`（无权限场景用 wande 用户自动隔离）

## 编译 + 启动验证（改完必跑）

> **⛔ MUST NOT — 高频踩坑（2 CC 已中招）**：`mvn compile` / `mvn clean compile` **不等于** `mvn install`。`spring-boot:run` 从 per-kimi M2 仓库（`~/cc_scheduler/m2/kimiN/repository`）加载 `wande-ai` 依赖 jar。只做 `compile` 不做 `install`，运行时加载的是 seed 旧 jar，新增 Controller/Service **永远不存在** → 404、Bean 未注册。**每次新增或改动 `ruoyi-modules/wande-ai/` 下的代码，必须先 `mvn install`，再 `restart-backend`，顺序不可颠倒。**

> **MUST NOT**: 禁止直接用 `mvn spring-boot:run`（`-Dspring-boot.run.profiles=test` 会连到公共库 `wande-ai` 而非隔离库 `wande-ai-kimiN`，导致数据污染且 Controller 404）。

```bash
# 1. 编译 wande-ai 模块（新增 Controller 后必须先 install，否则启动时用旧 jar）
#    MUST NOT: 去掉 -q，让编译错误可见（-q 会静默吞掉 ERROR 日志）
cd /data/home/ubuntu/projects/wande-play-kimiN/backend
mvn install -pl ruoyi-modules/wande-ai -am -DskipTests \
    -Dmaven.repo.local=~/cc_scheduler/m2/kimiN/repository

# 1a. MUST: 验证新 Controller 类已打入 jar（缺失 = 编译失败或路径错误）
jar tf ~/cc_scheduler/m2/kimiN/repository/org/ruoyi/wande-ai/3.0.0/wande-ai-3.0.0.jar \
    | grep "YourNewController"
# 必须有输出，否则重查编译错误，禁止直接 restart-backend

# 2. 单测
mvn test -pl ruoyi-modules/wande-ai \
    -Dmaven.repo.local=~/cc_scheduler/m2/kimiN/repository

# 3. 启动（唯一正确方式，自动注入隔离库 wande-ai-kimiN + Redis dbN）
bash ~/projects/.github/scripts/cc-test-env.sh restart-backend kimiN
# 等待就绪（任意 HTTP 响应 = UP，包括 401）
bash ~/projects/.github/scripts/cc-test-env.sh wait kimiN
```

看到 `Started RuoYiApplication` / wait 返回 `OK (Ns, HTTP=4xx/2xx)` + 无 `ConflictingBeanDefinitionException` / `ClassNotFoundException` / `Unknown column` = 通过。
