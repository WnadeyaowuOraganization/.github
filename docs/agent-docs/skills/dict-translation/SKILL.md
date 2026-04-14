---
name: dict-translation
description: 字典 / 枚举 / 外键翻译开发规范 — @Translation 注解、TranslationInterface SPI、命名约定
type: skill
---

# 字典 / 枚举 / 外键翻译规范

RuoYi-Vue-Plus 的 `ruoyi-common-translation` 模块提供基于 Jackson 序列化的**注解式翻译**：VO 序列化到前端时，自动把 `user_id / dept_id / dict value / oss_id` 等字段翻译成可读文案，前端直接取 `xxxName / xxxLabel / xxxUrl`，**无需在 Service 层手工 JOIN / 查字典**。

## 何时使用本 skill

**凡是返回前端的 VO 含以下字段，必用 `@Translation`**：

| 字段特征 | 必配翻译 |
|----------|---------|
| `status / type / sex / state` 等字典值 | `DICT_TYPE_TO_LABEL` |
| `user_id / create_by / update_by / approver` | `USER_ID_TO_NAME` 或 `USER_ID_TO_NICKNAME` |
| `dept_id` | `DEPT_ID_TO_NAME` |
| `avatar / attach_id / file_id`（OSS 附件 ID） | `OSS_ID_TO_URL` |
| 业务外键 ID（`category_id / project_id / plan_id` 等） | **自建** `TranslationInterface` |

漏配 = 前端表格显示 `1 / 2 / 3` 或 `1001`（用户 ID）而不是名称 → PR 图形化验收不过。

## `@Translation` 三要素速查

```java
@Translation(type = "...", mapper = "...", other = "...")
```

| 属性 | 作用 | 何时用 |
|------|------|--------|
| `type` | 翻译类型（对应实现类 `@TranslationType(type=...)`） | **必填** |
| `mapper` | 取哪个字段的值去翻译（默认取当前字段自己的值） | 当翻译后文案字段 ≠ 源 ID 字段时（典型：`deptId` → `deptName`） |
| `other` | 额外参数 | 仅字典翻译需要，填字典 `dict_type`（如 `sys_user_sex`） |

## 内置翻译类型清单

位于 `org.ruoyi.common.translation.constant.TransConstant`：

| 常量 | type 值 | 入参 | 返回 | 实现类 |
|------|---------|------|------|--------|
| `USER_ID_TO_NAME` | `user_id_to_name` | `Long userId` | 用户账号 | `UserNameTranslationImpl` |
| `USER_ID_TO_NICKNAME` | `user_id_to_nickname` | `Long userId` | 用户昵称 | `NicknameTranslationImpl` |
| `DEPT_ID_TO_NAME` | `dept_id_to_name` | `Long deptId` | 部门名称 | `DeptNameTranslationImpl` |
| `DICT_TYPE_TO_LABEL` | `dict_type_to_label` | `String dictValue` + `other=dict_type` | 字典 label | `DictTypeTranslationImpl` |
| `OSS_ID_TO_URL` | `oss_id_to_url` | `Long ossId` | 文件预览 URL | `OssUrlTranslationImpl` |

业务模块追加（如 workflow）：`FlowConstant.CATEGORY_ID_TO_NAME` → `CategoryNameTranslationImpl`。

## VO 层标准写法

### 命名约定（强制）

| 源字段 | 翻译后字段 | 说明 |
|--------|-----------|------|
| `userId: Long` | `userName: String` | name 字段**不要**映射数据库列，纯序列化产物 |
| `deptId: Long` | `deptName: String` | |
| `status: String`（字典值） | `statusName: String` | |
| `avatar: Long`（OSS ID） | **原字段上直接贴注解**（字段类型保留 Long，输出变 URL） | OSS 场景 |

### 模板 1：用户 / 部门外键翻译（分离字段）

```java
@Data
public class ProjectVo {
    private Long id;
    private String projectName;

    /** 负责人 ID（数据库列） */
    private Long ownerId;

    /** 负责人昵称（翻译产物，前端用） */
    @Translation(type = TransConstant.USER_ID_TO_NICKNAME, mapper = "ownerId")
    private String ownerName;

    /** 所属部门 */
    private Long deptId;

    @Translation(type = TransConstant.DEPT_ID_TO_NAME, mapper = "deptId")
    private String deptName;
}
```

### 模板 2：字典翻译（type + 分离 label 字段）

```java
/** 状态（字典值：0=禁用 1=启用，字典 type=sys_normal_disable） */
private String status;

@Translation(type = TransConstant.DICT_TYPE_TO_LABEL, mapper = "status", other = "sys_normal_disable")
private String statusName;
```

前端表格列直接绑 `statusName`，**不要**再走 `useDict('sys_normal_disable')` 二次查询。

### 模板 3：OSS 附件（同字段替换）

```java
/** 头像 OSS ID；序列化时被替换为 URL 字符串 */
@Translation(type = TransConstant.OSS_ID_TO_URL)
private Long avatar;
```

注意：字段类型 `Long`，输出 JSON 是 `String`（URL）。前端 TS 类型应声明为 `string`。

## 新增自定义 TranslationInterface 的标准步骤

场景：业务外键（如 `plan_id → plan_name`、`bidding_id → bidding_title`）内置翻译不覆盖。

### 1. 在业务模块定义常量

```java
// org.ruoyi.wande.{feature}.common.constant.XxxTransConstant
public interface XxxTransConstant {
    String PLAN_ID_TO_NAME = "plan_id_to_name";
}
```

### 2. 实现 `TranslationInterface<String>` 并注册为 Spring Bean

```java
package org.ruoyi.wande.plan.service.impl;

@Slf4j
@Service
@RequiredArgsConstructor
@TranslationType(type = XxxTransConstant.PLAN_ID_TO_NAME)
public class PlanNameTranslationImpl implements TranslationInterface<String> {

    private final IPlanService planService;

    @Override
    public String translation(Object key, String other) {
        if (key instanceof Long id) {
            return planService.selectNameById(id);  // Service 暴露轻查询方法
        }
        return null;
    }
}
```

**要点**：
- 必须 `@Service`（或 `@Component`）+ `@TranslationType(type=...)` 双注解，`TranslationConfig` 启动时自动扫描 `List<TranslationInterface<?>>` 并按 type 注册到 `TRANSLATION_MAPPER`。
- 禁止把翻译实现放到 Controller / 工具类。
- Service 层应提供 `selectNameById(Long)` 之类的轻量方法（最好加 Redis/Caffeine 缓存，否则一个列表页 N 次单查）。
- 抛异常会被吞掉（`TranslationHandler` catch 后输出原始 key），但仍会污染日志——`translation()` 内部必须做 null / 类型判断。

### 3. VO 使用

```java
private Long planId;

@Translation(type = XxxTransConstant.PLAN_ID_TO_NAME, mapper = "planId")
private String planName;
```

### 4. 测试

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:710N/wande/xxx/list" | jq '.rows[0] | {planId, planName, ownerId, ownerName}'
```

JSON 里 `planName / ownerName` 非空 = 翻译生效。

## 红线

| ❌ 禁止 | ✅ 正解 |
|--------|--------|
| Service / Controller 里手工 `dictService.getDictLabel(...)` 再塞进 VO | VO 字段贴 `@Translation` |
| Mapper XML `LEFT JOIN sys_user / sys_dept / sys_dict_data` 拼名称 | VO 贴注解，Mapper 只查本表 |
| 前端 `useDict('...')` 兜底转名字（覆盖后端漏配） | 后端 VO 补 `@Translation`，前端直接用翻译字段 |
| 翻译后的字段映射到数据库列（`@TableField` + `@Translation` 同用） | 翻译字段是**纯序列化产物**，不映射列，不参与查询/更新 |
| `TranslationInterface` 实现忘记 `@TranslationType` | 启动日志警告「未标注 TranslationType」，翻译静默失效 |
| `translation()` 内部 `throw new RuntimeException` | 返回 `null`，让 Handler 输出原值 |
| 在 `wande-ai-api` 模块写翻译实现 | 放到对应业务模块 `ruoyi-modules/wande-ai/` 下 |
| 自定义 type 字符串拼写错（VO 的 `type=` 和实现类 `@TranslationType(type=)` 不一致） | 统一走 `XxxTransConstant` 常量 |

## 排查口诀

1. 前端看到 ID 没看到名字 → 先查 VO 字段是否贴 `@Translation`
2. 注解贴了但仍是 null → 检查 `mapper="..."` 字段名拼写 / 字典 `other="..."` type 是否正确
3. 自定义翻译不生效 → 启动日志搜 `未标注 TranslationType`；检查 Bean 扫描路径（新 `com.wande.ai` 包需 `@ComponentScan`）
4. 列表页慢 → 翻译实现加缓存，避免 N+1 单查
