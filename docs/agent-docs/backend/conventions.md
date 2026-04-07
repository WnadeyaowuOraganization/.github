# 开发规范

## Entity（实体类）
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

## Mapper
```java
@DS("wande")   // 万德业务表必须加
@Mapper
public interface XxxMapper extends BaseMapperPlus<XxxEntity, XxxVo> {
    // 复杂查询在 resources/mapper/XxxMapper.xml 中定义
}
```

## Bo/Vo
- `Bo`（Business Object）：接收前端请求参数，放在 `domain/bo/` 下
- `Vo`（View Object）：返回前端数据，放在 `domain/vo/` 下
- Bo/Vo 不继承 BaseEntity，只包含业务字段

## Service 接口命名
```java
// 接口：I 前缀
public interface IXxxService extends IService<XxxEntity> { }

// 实现：Impl 后缀
@Service
public class XxxServiceImpl extends ServiceImpl<XxxMapper, XxxEntity> implements IXxxService { }
```

## Controller
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
- 统一返回 `R<T>`，`R.ok(data)` / `R.fail(msg)`
- 分页用 `PageQuery` 参数，返回 `TableDataInfo<T>`

## 数据源注解强制检查

`wande-ai-api` 模块下所有 Mapper 接口和 Service 实现类是否已添加 `@DS("wande")` 注解。原因：`dynamic.primary: master` 意味着不加 `@DS` 的代码默认走 master（ruoyi_ai 库），wande 模块的表在 wande_ai 库中，不加注解运行时必报错。不能参考 ruoyi-system-api 中不加 @DS 的写法——那些是走默认 master 的，场景不同。

## 必须使用 ubuntu 用户执行构建

**CC本身已在ubuntu用户下运行**，直接执行 `mvn clean compile` 即可，无需 `sudo -u ubuntu`。
`sudo -u ubuntu` 仅在当前是 root 用户时才需要。禁止用 root 执行 mvn，否则 target 目录权限会变成 root 所有，导致后续 CI/CD Runner（ubuntu 用户）无法清理 target 目录而构建失败。

## 同名实体类禁止共存（高危）

同一张数据库表**只能对应一个 Entity 类**。若多个 Issue 的 CC 分别为同一表创建了不同包下的实体类，会导致：
1. MyBatis-Plus `ServiceImpl<M, T>` 泛型类型约束报错（`type argument ... is not within bounds`）
2. IntelliJ import optimizer 持续在两个同名类之间翻转，源码永远无法稳定
3. `@AutoMapper` MapStruct 映射失败

**规则**：
- 新建实体前必须用 `grep -r "TableName.*your_table"` 确认该表是否已有 Entity
- 若已有 Entity，**禁止**再创建同名实体，应在原 Entity 类中追加字段
- Entity 扩展字段对应的 DB 列须同步在 `script/sql/update/wande_ai/` 下新增 ALTER TABLE 脚本

## Controller 路径唯一性（Ambiguous Mapping）

两个 `@RestController` 不能同时映射到相同的 HTTP 路径（含子路径）。常见触发场景：

> Issue #A 创建了 `FooController` → `/api/foo/timeline`  
> Issue #B 重构又创建了 `NewFooController` → `/api/foo/timeline`  
> Spring Boot 启动时抛 `BeanCreationException: Ambiguous mapping`，**后端无法启动**

**规则**：
- 新建 Controller 前必须 `grep -r "RequestMapping.*your-path"` 确认路径未被占用
- 若旧 Controller 需要被替代，必须**同时删除旧 Controller**，不能两者并存
- 若确需保留旧版，必须修改其 `@RequestMapping` 到不同路径（如 `-v1` 后缀）

## 测试文件必须放在正确的模块

测试类如果依赖 `wande-ai` 模块的 Mapper / Service / BaseServiceTest，必须放在 `ruoyi-modules/wande-ai/src/test/` 下，**不能**放在 `wande-ai-api` 模块。

错误示例：把 `DashboardEfficiencyServiceTest` 放到 `ruoyi-modules-api/wande-ai-api/src/test/`，编译时找不到 `BaseServiceTest`，导致整个模块 build 失败。

## @TableId 列名必须与数据库一致

实体类的 `@TableId(value = "列名")` **必须与数据库实际主键列名完全一致**。

```java
// ❌ 错误：DB 主键列是 id，却写成 equipment_id
@TableId(value = "equipment_id")
private Long equipmentId;

// ✅ 正确：DB 主键列是 id，字段名可以自定义但 value 必须匹配
@TableId(value = "id")
private Long equipmentId;
```

如果 Java 字段名与 DB 列名不一致，用 `@TableId(value = "db_column_name")` 显式指定，不要依赖 MyBatis-Plus 的驼峰转换（驼峰转换对非标准命名可能出错）。

## CI/CD 部署必须有回滚机制

后端 JAR 部署步骤：
1. 备份：`cp ruoyi-admin.jar ruoyi-admin.jar.bak`
2. 覆盖：`cp new.jar ruoyi-admin.jar`
3. 重启并做健康检查（timeout ≥ 60s）
4. 检查失败 → 恢复备份 → 重启 → 再次验证

健康检查接口：`GET http://localhost:6040/actuator/health`，返回 `{"status":"UP"}` 才算成功。

## 包路径规范（防止同名类冲突）

> **`wande-ai-api` 已废弃（D44），禁止在该模块下新增任何业务代码。**
> 所有新功能代码统一写在 `ruoyi-modules/wande-ai/`。

包路径模板：

```
org.ruoyi.wande.{feature}.domain.entity.XxxEntity   ← 实体
org.ruoyi.wande.{feature}.domain.vo.XxxVo           ← VO
org.ruoyi.wande.{feature}.domain.bo.XxxBo           ← BO
org.ruoyi.wande.mapper.{feature}.XxxMapper           ← Mapper接口
org.ruoyi.wande.service.{feature}.IXxxService        ← Service接口
org.ruoyi.wande.service.{feature}.impl.XxxServiceImpl ← Service实现
org.ruoyi.wande.controller.{feature}.XxxController   ← Controller
```

**禁止**：
- 在 `wande-ai-api` 下新建业务代码
- 使用旧路径 `org.ruoyi.wande.domain.{feature}.*`（会与新结构冲突导致 MyBatis alias 重复）
- 在 `org.ruoyi.wande` 下直接创建业务顶级包（如 `org.ruoyi.wande.d3/`）
- 跳过查重直接创建新类
