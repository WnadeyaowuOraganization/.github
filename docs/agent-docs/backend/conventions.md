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
