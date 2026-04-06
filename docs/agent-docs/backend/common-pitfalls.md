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

## 快速检查清单（PR 前自查）

| 检查项 | 说明 |
|--------|------|
| ✅ Service 实现在 `wande-ai` 模块 | 不在 `wande-ai-api` |
| ✅ 包路径用 `wande.{feature}.domain` | 不用 `wande.domain.{feature}` |
| ✅ 新增 domain 包已加入 `typeAliasesPackage` | 见 `ruoyi-admin/application.yml` |
| ✅ XML resultMap 无复杂类型字段 | 或已配置 `typeHandler` |
| ✅ 删除 Mapper 接口时同步删除 XML | `resources/mapper/` 下同名文件 |
| ✅ Entity 的 JSON 列用 `String` 存储 | Service 层负责序列化/反序列化 |
