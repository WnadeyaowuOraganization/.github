---
name: backend-coding
description: Write Spring Boot 3 backend Java code for Wande-Play following RuoYi-Vue-Plus conventions. Covers mandatory package path (wande.{feature}.domain not wande.domain.{feature}), ServiceImpl extends ServiceImpl<Mapper,Entity> (not bare implements), ComponentScan for com.wande.ai, typeAliasesPackage registration, R.ok/fail + TableDataInfo.build response format, no wande-ai-api business code, no @DS annotation, MyBatis XML cleanup rules, and Bean-name conflict avoidance.
---

# 后端编码规范

> **⛔ MUST NOT — fullstack 配对红线**（4次 kimi4/kimi3 违规后加入）：
> 研发经理在启动你的会话后发消息告知「配对前端 Issue #XXXX」时，**禁止**在前端代码完成之前提交任何 PR。
> **必须**：后端 + 前端全部完成后，在同一分支合并为一个 fullstack PR，PR body 中必须同时包含后端文件截图和前端截图（参考 pr-visual-proof skill）。
> 违反 = manager 会拒绝 merge + 要求重做前端，PR 作废。

Spring Boot 3 + MyBatis-Plus + Sa-Token + RuoYi-Vue-Plus。**业务代码只能写在 `ruoyi-modules/wande-ai/`**。

## 启动编码前必读 issue-source.md（2026-05-06 #2329 教训）

编码前 **必须** 先阅读 `issues/issue-<N>/issue-source.md` 的完整内容，重点确认：
1. **需求范围与数据模型** — 表结构、字段类型、关联关系
2. **API 路径与命名约定** — Controller 方法名、权限码、请求/响应格式
3. **关联 Issue 状态** — 前端配对 Issue 是否已启动/完成，是否需要等待
4. **原型与设计引用** — 若 issue body 引用 `.github/docs/design/<模块>/` 设计文档，后端 CC 同样需要阅读以理解业务上下文

**禁止**未读 issue-source.md 直接开始编码。若需求范围不明确或关联 Issue 状态异常，立即 pause 并报告研发经理，**禁止**自行假设业务逻辑。

案例：kimi2 #2329 未读 issue-source.md 中原型引用，误报"缺原型"并自行 pause，实际设计文档已存在。后端 CC 同理，若未读 issue-source.md 可能导致 API 设计与前端预期不一致。

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

> ⚠️ **红线：每个 Controller 方法必须加 `@SaCheckPermission`，无一例外**
> - 缺失 = 安全漏洞，研发经理 code review 必驳回
> - 新建子模块（`com.wande.ai.modules.plm.*` 等）同样适用，不受包路径影响
> - `import cn.dev33.satoken.annotation.SaCheckPermission;`

```java
@RestController
@RequestMapping("/wande/xxx")
@RequiredArgsConstructor
public class XxxController {
    private final IXxxService xxxService;

    @SaCheckPermission("wande:xxx:list")          // ← 必填，缺失直接驳回
    @GetMapping("/list")
    public TableDataInfo<XxxVo> list(XxxBo bo, PageQuery pageQuery) {
        return xxxService.queryPageList(bo, pageQuery);
    }

    @SaCheckPermission("wande:xxx:add")           // ← 必填，缺失直接驳回
    @PostMapping
    public R<Void> add(@Validated @RequestBody XxxBo bo) {
        xxxService.insertByBo(bo);
        return R.ok();
    }
}
```

**PLM 子模块权限命名规范**（`com.wande.ai.modules.plm.*`）：
- 查询类：`"plm:<module>:query"`
- 写入/执行类：`"plm:<module>:<action>"`（如 `"plm:eco:execute"`、`"plm:configurator:confirm"`）
- 管理员兜底：`orRole = "admin"`

**Controller 路径前缀规范（/api vs /wande）：**
- 继承 `BaseController` → 路径自动拼接 `/api/wande/xxx`，Controller 只需写 `/wande/xxx`
- **不继承** BaseController（如独立微服务接口）→ 路径**不带** `/api` 前缀，直接写 `/wande/xxx`
- 自测时用 curl 验证路径：先试 `/wande/xxx/page`，404 再试 `/api/wande/xxx/page`

事故案例：#2752 E2E 测试路径写 `/api/wande/xxx/page`，但 Controller 不继承 BaseController 导致路径不匹配，排查 45min。

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

## ruoyi-admin fat-jar 传递依赖（3 CC 踩过，必读）

> **⛔ MUST** — 在 `wande-ai` 模块新增**第三方 dependency**（如 WxJava、Jackson XML、AWS SDK 等）后，**必须同步**在 `backend/ruoyi-admin/pom.xml` 的 `<dependencies>` 节点中显式声明该依赖。

原因：Spring Boot Maven Plugin `repackage` 生成的 fat-jar 只打包 `ruoyi-admin` 直接声明的依赖，不自动包含子模块的传递依赖。编译（`mvn install`）可通过，但运行时报 `ClassNotFoundException`。

```xml
<!-- 示例：已有的 SQS / WxJava / jackson-dataformat-xml 块 -->
<dependency>
    <groupId>com.github.binarywang</groupId>
    <artifactId>weixin-java-cp</artifactId>
    <version>${weixin-java-cp.version}</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-xml</artifactId>
</dependency>
```

若新依赖版本由根 `pom.xml` `dependencyManagement` 管控，可省略 `<version>`；否则显式指定版本。

## 常用库注意

- Thumbnailator（`com.sksamuel.scrimage:thumbnailator`）0.4.20 **无 CropType**，图片裁切需手动实现 BufferedImage 坐标裁切，不要花时间找 CropType API
- **单元测试 @ServiceImpl**：Mockito `@InjectMocks` 时 `baseMapper=null`，解决：`ReflectionTestUtils.setField(service, "baseMapper", mockMapper)`
- **后端启动**：`java -jar` 模式不走源码的 `ComponentScan`，改动后必须 `mvn install` 重建（`mvn spring-boot:run` 则实时加载源码）
- **create_by / update_by**：字段类型是 `BIGINT(Long)`，不是 `String`；Flyway 默认填 `system` 字符串会导致 `SQLSyntaxErrorException`

---

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
- 🚨 **`git clean -fd` 在业务文件未 staged 前执行 = 4 次已触发全删灾难**（#4735 kimi1删mapper、#4688删契约文件、#4650删service、#4725删全部代码文件）
  - **红线：禁止在任何情况下对工作目录运行 `git clean -fd`**
  - 正确流程：**先 `git add` 所有 .java/.sql/.ts/.yaml/.xml/.md 业务文件**，再决定如何处理未跟踪文件
  - Maven 产物/CC产物清理：加入 `.gitignore`，**绝不**用 git clean 清除
  - CLAUDE.md 要求的清理：`git checkout -- .`（丢弃所有未 staged 的修改）+ `git clean -fd -e '.claude/skills/' -e 'CLAUDE.md' -e 'issues/'`（只删CC内部产物）
- ❌ **`mysql -h 127.0.0.1 -uroot -proot ...` 从宿主机裸连**（4 次已触发自动止血）— 属红线 #3 环境隔离违规，容易连错库。**必须**走 docker exec：
  ```bash
  docker exec mysql-dev mysql -uroot -proot -D wande-ai-kimi<N>
  # 或用低权限 wande 用户：-uwande -pwande_dev_2026
  ```
  容器名是 `mysql-dev`（`docker ps` 可查）。**只**允许查自己的 schema `wande-ai-kimi<N>`，**禁止**访问主库 `wande-ai`（无权限场景用 wande 用户自动隔离）

## 编译 + 启动验证（改完必跑）

> **⛔ MUST NOT — 高频踩坑（3+ CC 已中招，禁止重蹈）**：`mvn compile` / `mvn clean compile` **不等于** `mvn install`。`spring-boot:run` 从 per-kimi M2 仓库（`~/cc_scheduler/m2/kimiN/repository`）加载 `wande-ai` 依赖 jar。只做 `compile` 不做 `install`，运行时加载的是 seed 旧 jar，新增 Controller/Service **永远不存在** → 404、Bean 未注册。**每次新增或改动 `ruoyi-modules/wande-ai/` 下的代码，必须先 `mvn install`，再 `restart-backend`，顺序不可颠倒。**

> **MUST NOT**: 禁止直接用 `mvn spring-boot:run`（`-Dspring-boot.run.profiles=test` 会连到公共库 `wande-ai` 而非隔离库 `wande-ai-kimiN`，导致数据污染且 Controller 404）。

> **⛔ MUST NOT — 禁止 `-Dmaven.test.skip=true`**：该 flag 会同时跳过测试**编译**和运行，将编译错误隐藏到后续环节。**任何编译错误（含非本 Issue 模块的历史错误）必须立即修复，不允许用任何 skip 参数绕过。** 允许用 `-DskipTests`（只跳过运行，仍编译测试类），但凡编译失败一律修代码。

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

### 后端启动失败排查路径（优先级从高到低）

```
1. Controller 404？
   → cc-test-env.sh wait 后诊断：GET /wande/plan/alert/page 返回 404
   → 根因：spring-boot:run JAR 未 unpack，Controller 注解未扫描
   → 解决：bash cc-test-env.sh restart-backend kimiN

2. 循环依赖导致 Bean 创建失败？
   → 日志搜 "Circular reference" 或 "BeanCurrentlyInCreationException"
   → 根因：A 注入 B，B 注入 A（无 @Lazy 解耦）
   → 解决：在被注入方加 @Lazy（只在注入点懒加载，不影响其他注入点）
   → 例：AcceptanceAiReportTaskExecutor / DesignNonstandardApprovalServiceImpl
   → 注意：循环依赖通常在本 Issue 新增的 Service 之间产生（PR #4560/#4559 引入了新注入点）

3. @Lazy 生效但仍是 404？
   → 检查 @Lazy 打在哪个方向（A→B 还是 B→A）
   → 原则：打在"被多方依赖"的 Service 上，而非"依赖方"
   → 验证：restart 后 GET /wande/新模块/xxx/page 返回 401（非404）= Controller 已注册

4. ruoyi-common-bom / wande-ai jar 缺失？
   → 日志搜 "Non-resolvable import POM" / "Could not find artifact"
   → 解决：bash cc-test-env.sh restart-backend kimiN（自动触发 BOM 预装）

5. MySQL schema 迁移脚本错误？
   → 日志搜 "flyway" / "Unknown column" / "Table doesn't exist"
   → 解决：bash cc-test-env.sh restart kimiN（重新 init-db + rebuild）
```

事故案例：#2664 修复 PR #4560/#4559 引入的循环依赖（2处 @Lazy），耗时 20min。
