---
name: backend-test
description: Test Wande-Play backend endpoints and services using curl integration smoke, JUnit unit tests (BaseServiceTest with @Transactional rollback), and Playwright API specs in the isolated kimi environment (:810N backend, wande-ai-kimi{N} schema, Redis db{N}, wande user without main-DB access). Covers startup, auth token acquisition, positive/negative/auth cases, and TDD red/green workflow.
---

# 后端测试

后端改动 PR 两道强制门，**按顺序**过：

1. **JUnit 单测**（继承 `BaseServiceTest`）绿 + `mvn compile` 通过——不过后端起不来。
2. **Playwright API spec**（`e2e/tests/backend/**/*.spec.ts`）绿——断 status/body/落库。

两门证据贴 `issues/issue-<N>/task.md`。纯文档/配置可跳，task.md 注明原因。curl 仅作手动 debug，不是 PR 证据。

## 独立 kimi 环境

每个编程 CC 有独立环境，**禁止**连主 Dev 环境（`:6040`）测试：

| 资源 | kimiN 值 |
|------|---------|
| 后端端口 | `810N`（kimi1=8101、kimi2=8102 ...） |
| 前端端口 | `710N` |
| MySQL schema | `wande-ai-kimi{N}` |
| Redis DB | `db{N}` |
| DB 用户 | `wande`（无主库 `wande-ai` 权限）|

## TDD 红灯先行（强制）

1. 写测试（单测 + Playwright API）
2. 跑测试确认**红灯**
3. 写实现
4. 跑测试变**绿灯**
5. 编译 / 打包 / 门禁

跳过红灯 = 容易写过度实现、漏 case。

## 启动独立后端

```bash
cd /data/home/ubuntu/projects/wande-play-kimiN
bash e2e/scripts/start-backend.sh      # 启动 810N，连 kimiN 独立 DB
tail -f logs/sys-info.log              # 启动日志
# 看到 "Started RuoYiApplication" 即就绪（~60s）
```

## 拿登录 token

```bash
PORT=810N  # 替换 N
TOKEN=$(curl -s -X POST http://localhost:${PORT}/auth/login \
  -H "Content-Type: application/json" \
  -d '{"tenantId":"000000","clientId":"e5cd7e4891bf95d1d19206ce24a7b32e","grantType":"password","username":"admin","password":"admin123"}' \
  | jq -r '.data.access_token')
echo $TOKEN
```

## curl 手动 debug

仅联调用：`curl -H "Authorization: Bearer $TOKEN" ...`。不是 PR 证据，不要贴 task.md。

## JUnit 单测（有业务分支时才写）

### 位置

```
backend/ruoyi-modules/wande-ai/src/test/java/org/ruoyi/wande/<feature>/
└── XxxServiceTest.java
```

### 基类

继承 `BaseServiceTest`（自动配置 MySQL 测试容器 + `@Transactional` 回滚）：

```java
@SpringBootTest(classes = RuoYiApplication.class)
@Transactional
public abstract class BaseServiceTest { }
```

### 写法（Mockito 专注业务规则）

```java
@ExtendWith(MockitoExtension.class)
class ProjectMineServiceTest {
    @Mock ProjectMineMapper mapper;
    @InjectMocks ProjectMineServiceImpl service;

    @Test
    void batchEvaluate_allValid_updatesAllRows() {
        when(mapper.updateById(any())).thenReturn(1);
        service.batchEvaluate(List.of(1L,2L,3L), 1);
        verify(mapper, times(3)).updateById(any());
    }

    @Test
    void batchEvaluate_emptyIds_throws() {
        assertThatThrownBy(() -> service.batchEvaluate(List.of(), 1))
            .isInstanceOf(ServiceException.class);
    }
}
```

### 最小覆盖

| Issue 类型 | 要求 |
|-----------|------|
| 新 Service | 创建 `XxxServiceTest`，覆盖核心 CRUD + 业务分支 |
| 改已有 Service | 补充变更方法的用例 |
| Bug 修复 | 先写复现 bug 的回归用例（红灯）再修 |
| 新 Controller | 可选 `XxxControllerTest`（MockMvc） |
| 纯文档 / 配置 | 可跳过，task.md 注明原因 |

### 运行

```bash
mvn test -pl ruoyi-modules/wande-ai -Dtest=ProjectMineServiceTest   # 单类
mvn test -pl ruoyi-modules/wande-ai                                 # 模块全量
mvn test                                                            # 全项目
```

## Playwright API（门 2）

每个后端 Issue 至少一个 spec 覆盖核心 endpoint，断 status/body/落库。位置：`e2e/tests/backend/api/<module>.ts`。

```ts
import { test, expect, request } from '@playwright/test';
test('project-mine list 返回分页结构', async () => {
  const api = await request.newContext({ baseURL: 'http://localhost:8101' });
  const login = await api.post('/auth/login', { data: {...} });
  const token = (await login.json()).data.access_token;
  const res = await api.get('/wande/project/mine/list', {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.code).toBe(200);
  expect(Array.isArray(body.rows)).toBeTruthy();
});
```

执行：

```bash
cd /data/home/ubuntu/projects/wande-play-kimiN/e2e
npx playwright test tests/backend/api/<module>.ts --workers=1
```

## 编译 + 打包门禁（提交前必过）

```bash
cd backend
mvn clean compile -Pprod -DskipTests                   # 编译
mvn test -pl ruoyi-modules/wande-ai                    # 模块单测
mvn clean package -Pprod -Dmaven.test.skip=true        # 打包（CI 等价）
```

**失败必修**，不管是否与本 Issue 直接相关（否则堵住整个分支 CI）。

## 权限 / 租户验证

- 每个 Controller 方法必须有 `@SaCheckPermission("wande:xxx:yyy")` 或 `@SaCheckLogin`
- 多租户隔离走拦截器，但要 curl 用**非 000000 租户**账号复测一次（回归 #3517 类事故）
- 看 `sys_menu` 表的 perms 值与 Controller 注解**完全一致**

## 禁止免责语（约束 6）

task.md / PR body **禁止** `测试配置待解决` / `待 CI 验证` / `编译通过但未运行测试` 等字样，被 quality-gate 拦截。

## 反模式

- ❌ 连主 Dev 环境（`:6040`）跑测试（污染数据）
- ❌ 只看编译通过就提交，跳过 Playwright API spec
- ❌ **跳顺序**：JUnit 没绿就先写 Playwright API（后端启动不了，白忙）
- ❌ **只跑 JUnit 不写 Playwright API spec**（两道门缺一，CI/quality-gate 会拦）
- ❌ **只跑 curl 不写 Playwright API spec**：curl 不是 PR 证据，CI 不认
- ❌ Playwright API spec 只写 `expect(res.status()).toBe(200)` 不断言 body / 不验证 DB 落库
- ❌ `new TableDataInfo<>()` 手设字段（前端判失败）
- ❌ 漏 `@SaCheckPermission`（任何登录用户都能调）
- ❌ JUnit 单测不继承 `BaseServiceTest`（缺 `@Transactional` 回滚，污染测试库）
- ❌ 把单测结果写成"通过"不贴证据到 task.md
