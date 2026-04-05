# 架构与技术栈

## 项目概述

- **名称**: wande-play
- **用途**: 万德 AI 平台后端（Spring Boot 版），集成 AI 对话、知识库、招投标、项目挖掘、CRM 等业务
- **技术栈**: Spring Boot 3.4.4 + MyBatis Plus 3.5.11 + Sa-Token 1.34.0 + dynamic-datasource 4.3.1 + Redis (Redisson) + Undertow
- **Java 版本**: 17
- **Maven 版本管理**: 父 POM 统一管理，所有模块版本号使用 `${revision}=1.0.0`，不在子模块 pom 中写死版本
- **启动方式**: 入口模块 `ruoyi-admin`，端口 6039，`mvn clean package` 后 `java -jar ruoyi-admin.jar`
- **原始仓库**: https://gitee.com/ageerle/ruoyi-ai

## 关键技术点

### dynamic-datasource 多数据源
- 使用 `com.baomidou:dynamic-datasource-spring-boot-starter:4.3.1`
- 在 `application-dev.yml` 的 `spring.datasource.dynamic.datasource` 下配置多个数据源
- 切换数据源：在 Mapper 接口或 Service 方法上加 `@DS("数据源名称")`
- 万德业务表统一使用 `@DS("wande")`，主库使用 `@DS("master")` 或不加注解

### Sa-Token 认证
- 版本 1.34.0，配置在 `ruoyi-common-satoken`
- Controller 接口用 `@SaCheckPermission("权限标识")` 控制访问
- 权限标识格式：`模块：资源：操作`，如 `wande:tender:list`

### MyBatis Plus 基类
- `BaseEntity`：在 `org.ruoyi.core.domain` 包，包含 `createTime`、`updateTime`、`createBy`、`updateBy`等公共字段
- `BaseMapperPlus<T, V>`：在 `org.ruoyi.core.mapper` 包，泛型 T=Entity, V=Vo，提供分页查询等增强方法
- 所有 Entity 必须继承 `BaseEntity`，所有 Mapper 必须继承 `BaseMapperPlus<Entity, Vo>`

### DataBaseHelper
- `org.ruoyi.helper.DataBaseHelper`
- 提供 `isPostgerSql()` 方法判断当前数据库类型，用于多数据库兼容写法

### MapStruct 对象映射
- Entity ↔ Bo/Vo 转换，通过 MapStruct 接口自动生成
- 命名规范：`XxxConverter` 接口，`@Mapper(componentModel = "spring")`

## 构建与运行

```bash
# 编译所有模块
mvn clean compile

# 打包（跳过测试）
mvn clean package -DskipTests

# 启动
java -jar ruoyi-admin/target/ruoyi-admin.jar

# 指定配置文件
java -jar ruoyi-admin.jar --spring.profiles.active=dev

# 本地开发端口
# 默认端口：6039（application.yml 中配置）
```
