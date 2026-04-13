# 后端编程 CC 常见错误与规范

> 本文档记录了实际 CI/部署过程中发现的高频错误，要求后端编程 CC 在开发前阅读，避免重复踩坑。

---

## 1. 模块归属：不要在 `wande-ai-api` 里写业务实现

**错误现象：** Service 实现类（`*ServiceImpl.java`）放在 `ruoyi-modules-api/wande-ai-api/` 目录下，并在其中注入 `wande-ai` 模块的 Mapper。

**根因：** `wande-ai-api` 是 API 声明模块（接口 + DTO），已于 D44 标记为废弃，不应包含业务逻辑。业务代码统一放 `ruoyi-modules/wande-ai/`。

**规范：**
- 所有 `*ServiceImpl.java`、`*Controller.java`、`*Mapper.java` 必须在 `ruoyi-modules/wande-ai/` 下
- `wande-ai-api` 只允许保留：共享接口（`IXxxService`）、跨模块 DTO、枚举常量
- 新功能**禁止**在 `wande-ai-api` 新增实体类、Mapper、Service 实现

---

## 2. 包路径规范：新功能用 `wande.{feature}.domain`，不用 `wande.domain.{feature}`

**错误现象：** 新建的实体/VO/BO 放在 `org.ruoyi.wande.domain.changeorder.*`，与已有的 `org.ruoyi.wande.change.domain.*` 形成同名类冲突，MyBatis 启动时报 alias 重复。

```
The alias 'AcceptanceRecordVo' is already mapped to the value 
'org.ruoyi.wande.acceptance.domain.vo.AcceptanceRecordVo'.
```

**根因：** `typeAliasesPackage` 扫描所有 `org.ruoyi.**.domain` 包，两种路径都匹配，同名简单类名冲突。

**规范（新功能包路径模板）：**
```
org.ruoyi.wande.{feature}.domain.entity.XxxEntity
org.ruoyi.wande.{feature}.domain.vo.XxxVo
org.ruoyi.wande.{feature}.domain.bo.XxxBo
org.ruoyi.wande.mapper.{feature}.XxxMapper
org.ruoyi.wande.service.{feature}.impl.XxxServiceImpl
org.ruoyi.wande.controller.{feature}.XxxController
```

- **禁止** 使用 `wande.domain.{feature}.*` 路径（旧 api 模块残留风格）
- 新增 `domain` 包后需在 `ruoyi-admin/application.yml` 的 `typeAliasesPackage` 列表中补充

---

## 3. MyBatis XML：复杂类型字段不能直接映射，需用 Entity 中转

**错误现象：** VO 中有复杂嵌套类型字段（如 `PerformanceSummaryVo`、`List<Long>`），XML `<resultMap>` 直接将数据库 JSON/JSONB 列映射到该字段，启动时报：

```
No typehandler found for property performanceSummary
```

**根因：** MyBatis 不知道如何将 VARCHAR/JSONB 列转换为自定义 Java 类型。

**规范：**

```
❌ 错误做法：
<resultMap type="XxxVo">
    <result property="complexField" column="json_column"/>  <!-- 复杂类型，无法自动转 -->
</resultMap>

✅ 正确做法一：XML 映射到 Entity（Entity 用 String 存 JSON），Service 层反序列化
<resultMap type="XxxEntity">
    <result property="complexField" column="json_column"/>  <!-- String 字段，安全 -->
</resultMap>
// Service:
entity.getComplexField() → objectMapper.readValue(..., XxxVo.ComplexType.class)

✅ 正确做法二：在 resultMap 中指定 typeHandler
<result property="complexField" column="json_column"
        typeHandler="com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler"/>
// 同时 VO 字段加注解：
@TableField(typeHandler = JacksonTypeHandler.class)
private ComplexType complexField;
```

**注意：** `List<T>` 泛型类型使用方式二时需用 `FastjsonTypeHandler` 或自定义 Handler。推荐方式一（XML → Entity，Service 转 VO）。

---

## 4. MyBatis XML：不要保留已删除 Mapper 接口对应的 XML 文件

**错误现象：** 删除了 Mapper 接口类，但 `src/main/resources/mapper/` 下对应的 XML 文件未删除，启动时报：

```
Error resolving class. Cause: ClassNotFoundException: 
Cannot find class: org.ruoyi.wande.domain.changeorder.mapper.ChangeApprovalMapper
```

**规范：**
- 删除 Mapper 接口时，**必须同时删除** `resources/mapper/` 下同名 XML 文件
- 如果 Mapper 继承 `BaseMapperPlus` 且无自定义方法，直接删除 XML 即可（BaseMapperPlus 不依赖 XML）

---

## 5. typeAliasesPackage 新增包时必须显式注册

**背景：** `ruoyi-admin/src/main/resources/application.yml` 中的 `typeAliasesPackage` 已从通配符改为明确列表（排除废弃的 `wande-ai-api` 包）：

```yaml
typeAliasesPackage: >
  org.ruoyi.aihuman.domain,
  org.ruoyi.wande.acceptance.domain,
  org.ruoyi.wande.budget.domain,
  org.ruoyi.wande.change.domain,
  ...（完整列表见 application.yml）
```

**规范：**
- 新增功能模块时，如果创建了新的 `domain` 包（如 `org.ruoyi.wande.safety.domain`），**必须在 PR 中同时更新** `application.yml` 的 `typeAliasesPackage` 列表
- 否则 XML 中使用类名别名（非全路径）时会报 `ClassNotFoundException`

---

## 6. 数据库字段中存储 JSON 的实体类规范

**规范：**

```java
// Entity 中 JSON 列统一用 String 存储
@TableField(value = "performance_summary")
private String performanceSummary;  // 数据库存 JSON 字符串

// 如需 MyBatis Plus 自动序列化/反序列化，使用 JacksonTypeHandler
@TableField(value = "complex_data", typeHandler = JacksonTypeHandler.class)
private ComplexDataType complexData;  // 自动处理，但泛型集合类型慎用
```

- **不要** 在 Entity 中直接写 `private List<SomeType> field` 并期待 MyBatis 自动处理
- JSON 字段的反序列化统一在 Service 层 `convertToVo` 方法中处理

---

## 7. wande-ai-api 中的 XML 与 wande-ai 模块中的 XML 不能重名

**错误现象：** `mapperLocations: classpath*:mapper/**/*Mapper.xml` 会扫描所有 JAR 包，若 `wande-ai-api` 和 `wande-ai` 中存在相同 namespace 的 XML，启动时报：

```
Result Maps collection already contains value for org.ruoyi.wande.domain.dispatch.mapper.DispatchLogMapper.DispatchLogResult
```

**规范：**
- 在 `wande-ai` 中为某接口创建了 XML，需同时**删除** `wande-ai-api` 中同名旧 XML
- `wande-ai-api` 模块已废弃，其 `resources/mapper/` 下的文件应逐步清空

---

## 8. Spring Bean 名称冲突：同名 ServiceImpl/Mapper 必须指定唯一 Bean 名

**错误现象：** 两个不同包下存在同名 `XxxServiceImpl` 或 `XxxMapper`，Spring 启动时报：

```
ConflictingBeanDefinitionException: Annotation-specified bean name 'changeOrderServiceImpl' 
for bean class [org.ruoyi.wande.service.change.impl.ChangeOrderServiceImpl] conflicts with 
existing, non-compatible bean definition of same name and class 
[org.ruoyi.wande.change.service.impl.ChangeOrderServiceImpl]
```

**根因：** Spring 默认 Bean 名是类名首字母小写，不含包路径。同名类产生冲突。

**规范：**
```java
// ❌ 错误：两个包下都有 ChangeOrderServiceImpl
package org.ruoyi.wande.service.change.impl;
@Service  // bean名 = changeOrderServiceImpl → 冲突！

// ✅ 正确：遗留/兼容类显式指定不同 Bean 名
@Service("legacyChangeOrderServiceImpl")
public class ChangeOrderServiceImpl ...

// ✅ 或者：将旧类文件重命名（推荐）
public class LegacyChangeOrderMapper ...  // 不再叫 ChangeOrderMapper
```

**规则：**
- 新功能优先使用新包路径（`wande.{feature}.service.impl`）
- 遗留类若不能删除，**必须**通过 `@Service("uniqueBeanName")` 或重命名类避免冲突
- Mapper 接口名冲突时，重命名旧 Mapper 类（`@Mapper` 注解不支持 value 参数）

---

## 9. IService 子接口不能用简单的 implements 存根，必须用 ServiceImpl 继承

**错误现象：** 某 Service 接口继承了 `IService<T>`，为其创建存根 impl 时只写了 `implements IXxxService`，编译报错：

```
NudgeRecordServiceImpl is not abstract and does not override abstract method 
getEntityClass() in com.baomidou.mybatisplus.extension.repository.IRepository
```

**根因：** MybatisPlus `IService` 继承 `IRepository`，后者有 `getBaseMapper()`、`getEntityClass()`、`getObj()` 等抽象方法。简单 impl 必须全部实现，但数量多且易遗漏。

**规范：**
```java
// ❌ 错误：直接 implements，缺少 IRepository 抽象方法实现
@Service
public class XxxServiceImpl implements IXxxService { ... }

// ✅ 正确：extends ServiceImpl（需要对应 Mapper）
@Service
public class XxxServiceImpl extends ServiceImpl<XxxMapper, XxxEntity>
        implements IXxxService { ... }
```

**处理步骤：**
1. 若存在 `XxxMapper`（或可创建），让 impl 继承 `ServiceImpl<XxxMapper, XxxEntity>`
2. 若 Entity 在 `wande-ai-api` 中，需先在 `wande-ai` 中创建对应 Mapper
3. 若同名 Mapper 冲突，重命名新 Mapper（如 `XxxDomainMapper`）

---

## 10. 新模块 ComponentScan：`com.wande.ai` 包下的 Controller 不会被自动扫描

**错误现象：** 新增的 Controller 放在 `com.wande.ai.xxx` 包下，启动后 API 返回 404，但代码编译正常。

**根因：** Spring Boot 主类在 `org.ruoyi` 包下，默认只扫描 `org.ruoyi.**`。`com.wande.ai` 不在扫描范围内，需要通过配置类显式引入。

**规范：**
```java
// 新模块的 Controller/Service 如果在 com.wande.ai 包下，
// 必须确保项目中存在 WandeAiModuleConfig（或等效配置类）注册该包扫描路径：
@Configuration
@ComponentScan("com.wande.ai")
public class WandeAiModuleConfig { }
```

- 新建 `com.wande.ai` 子包前，先确认 `WandeAiModuleConfig` 已存在
- 若 Controller 注册后仍 404，检查 `@RequestMapping` 路径是否与 nginx 代理规则匹配

---

## 11. Flyway 增量 SQL：MySQL 与 MariaDB 语法差异

**错误现象：** Flyway 迁移脚本使用了 MariaDB 特有语法（如 `ADD KEY IF NOT EXISTS`），在 MySQL 8.x 上执行失败。

**根因：** MariaDB 对 DDL 做了许多 `IF NOT EXISTS` / `IF EXISTS` 扩展，MySQL 不支持这些写法。

**规范：**
```sql
-- ❌ MariaDB 专有语法，MySQL 不支持
ALTER TABLE xxx ADD KEY IF NOT EXISTS idx_name (col);
ALTER TABLE xxx ADD COLUMN IF NOT EXISTS col_name VARCHAR(255);

-- ✅ MySQL 兼容写法：先查再加（或直接 CREATE INDEX IF NOT EXISTS 仅 MySQL 8.0.29+）
-- 推荐做法：Flyway 脚本保持幂等，用标准 MySQL 语法
ALTER TABLE xxx ADD INDEX idx_name (col);        -- 重复执行会报错，由版本号保证幂等
CREATE INDEX IF NOT EXISTS idx_name ON xxx(col); -- MySQL 8.0.29+ 支持
```

**附加检查：**
- 新增数据库列时，Entity 字段类型必须与表列类型匹配（如 `update_by` 列为 `BIGINT` 则 Entity 用 `Long`，不能用 `String`）
- 新业务表必须包含 RuoYi 标准列：`tenant_id`、`create_dept`、`create_by`、`update_by`、`create_time`、`update_time`、`del_flag`
- 提交前用 `mvn flyway:validate` 或启动后端验证迁移脚本无报错

---

## 快速检查清单（PR 前自查）

| 检查项 | 说明 |
|--------|------|
| ✅ Service 实现在 `wande-ai` 模块 | 不在 `wande-ai-api` |
| ✅ 包路径用 `wande.{feature}.domain` | 不用 `wande.domain.{feature}` |
| ✅ 新增 domain 包已加入 `typeAliasesPackage` | 见 `ruoyi-admin/application.yml` |
| ✅ XML resultMap 无复杂类型字段 | 或已配置 `typeHandler` |
| ✅ 删除 Mapper 接口时同步删除 XML | `resources/mapper/` 下同名文件 |
| ✅ Entity 的 JSON 列用 `String` 存储 | Service 层负责序列化/反序列化 |
| ✅ wande-ai-api 同名 XML 已删除 | 避免 ResultMap duplicate 冲突 |
| ✅ 新建 ServiceImpl 无同名 Bean 冲突 | 检查跨包同名类，必要时指定 `@Service("uniqueName")` |
| ✅ IService 子接口存根用 ServiceImpl 继承 | 不能仅 `implements`，需配套 Mapper |
| ✅ `com.wande.ai` 包下有 ComponentScan 配置 | 确认 `WandeAiModuleConfig` 存在 |
| ✅ Flyway SQL 用标准 MySQL 语法 | 不用 MariaDB 专有 `IF NOT EXISTS` DDL |
| ✅ 新表包含 RuoYi 标准 7 列 | `tenant_id`、`create_dept`、`create_by` 等 |
| ✅ Entity 字段类型与表列类型一致 | `BIGINT` → `Long`，不能用 `String` |
