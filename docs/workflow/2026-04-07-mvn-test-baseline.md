# 单元测试基础设施切换：H2 → Docker PostgreSQL

**日期**：2026-04-07
**触发**：调研 SCHEMA_ORDER.txt 并行冲突，进而发现单元测试 H2/PG 双套维护问题
**结论**：dev 单元测试已累积 ~2117 个 errors，CI 长期 `-Dmaven.test.skip=true` 没把关

---

## 一、问题暴露过程

### 1.1 起点：SCHEMA_ORDER.txt 并行冲突

CC 写新表时同时维护两个文件：
- `backend/script/sql/update/wande_ai/V<日期>__xxx.sql`（PG 生产）
- `backend/ruoyi-modules/wande-ai/src/test/resources/schemas/issue_<N>.sql`（H2 测试）+ 在 `SCHEMA_ORDER.txt` 末尾追加文件名

后者两处都是共享文件，多 CC 并发写就 merge 冲突，影响 PR 合并。

### 1.2 第一次修复：自动发现 schemas/

`TestApplication.schemaAutoLoader` 改为 glob 扫描 `schemas/issue_*.sql`，删除 `SCHEMA_ORDER.txt`。冲突点变成只有"在 schemas/ 新建文件"，看似解决了。

### 1.3 第二次发现：双套 schema 本身就是浪费

PG 生产已经有 `backend/script/sql/update/wande_ai/`（256+ 个增量脚本），CC 实际是把 PG 语法手动翻译为 H2 方言放到 `schemas/`。**纯重复劳动**。

### 1.4 第三次发现：dev 单元测试根本跑不起

切到 PG 后第一次跑 mvn test，发现 1700+ errors。一开始以为是切换引入的，详细对比后发现：

| 配置 | Tests run | Passed | Errors |
|------|----------:|-------:|------:|
| 干净 dev clone + H2（原状） | 2462 | **338** | 2117 |
| dev + PG 切换 | 2462 | **338** | 2023 |

**PG 切换是 zero-impact，dev 上 2117 个 errors 是长期累积的历史欠债。**

### 1.5 根本原因：CI 长期跳过 mvn test

`build-deploy-dev.yml` 用 `-Dmaven.test.skip=true` 跳过单元测试，`pr-test.yml` 只跑 E2E smoke。结果：

- CC 写代码本地不跑 mvn test 也能合并
- dev 编译错误（如 `SalesActivityType.OPPORTUNITY_CREATE` 找不到）能合进 dev
- H2 schema 和 PG schema 漂移（H2 有 17 张表 PG 没有，dev PG 有 36 张表 H2 没有）
- mapper 包路径错（`WdppWecomUserMappingMapper` 在 `domain.wecom` 包下而非 `mapper.wecom`）

---

## 二、本次修复内容

### 2.1 wande-play 仓库改动（PR commit `56d06674`，已 merge dev）

| 文件 | 变更 |
|------|------|
| `backend/ruoyi-modules/wande-ai/pom.xml` | 替换 `com.h2database` 为 `org.postgresql` + 加 `spring-security-test` |
| `src/test/resources/application-test.yml` | 改 PG 连接（`localhost:5434/wande_ai/wande/wande_test`，可被 `TEST_PG_*` 环境变量覆盖） |
| `src/test/java/.../TestApplication.java` | 重写 `schemaAutoLoader`：drop public → load base → load 不在 applied list 的 update 脚本 |
| `src/test/resources/test-base-schema.pg.sql` | **新增** 368 张表 DDL，由 dev PG snapshot 自动生成（vector 列统一为 bytea） |
| `src/test/resources/test-base-applied.txt` | **新增** 261 行，冻结现有 update 脚本（视为已执行跳过） |
| `src/test/resources/schema.sql`、`schemas/`、`schema-slide-bucket.sql` | 删除 |
| `.github/workflows/pr-test.yml` | 新增 `unit-test` job，在 `conflict-check` 后、`e2e-test` 前 |

### 2.2 .github 仓库改动（commit `093935b`，已 push main）

| 文件 | 变更 |
|------|------|
| `scripts/ensure-test-pg.sh` | **新增** 启动/复用 `wande-test-pg` 容器（端口 5434） |
| `.test-baseline` | **新增** 写入 `338`（dev 当前真实通过数） |
| `docs/agent-docs/backend/db-schema.md` | 加新 PG 单脚本流程提示 |

---

## 三、PG 容器规约

```bash
container=wande-test-pg
image=postgres:16-alpine
port=5434              # 与 dev PG 5433 隔离
db=wande_ai
user=wande
password=wande_test
restart=unless-stopped
```

由 `scripts/ensure-test-pg.sh` 维护（幂等：已运行→跳过、已停止→启动、不存在→创建）。

---

## 四、CI 关卡机制

`pr-test.yml` 的 `unit-test` job：

1. 检测 PR 是否有 `backend/` 变更，无则跳过
2. 调用 `ensure-test-pg.sh` 启动测试 PG 容器
3. 在 `wande-play-ci` 工作目录 checkout PR 分支
4. 跑 `mvn test -Dtest='*ServiceTest'`
5. 解析 surefire 报告统计通过数
6. 与 `/home/ubuntu/projects/.github/.test-baseline`（当前 `338`）对比：
   - `passed >= baseline` ✅ 进入 e2e-test
   - `passed < baseline` ❌ 阻止合并

**基线提升规则**：每次 CC 修复一批历史欠债后，执行：
```bash
echo "$NEW_PASSED" > /home/ubuntu/projects/.github/.test-baseline
git -C /home/ubuntu/projects/.github commit -am "chore(test): 提升 mvn test 基线 → $NEW_PASSED"
```

---

## 五、TestApplication.schemaAutoLoader 工作原理

```java
// Step 1: 重置
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

// Step 2: 加载冻结的基础 schema
classpath:test-base-schema.pg.sql  // 368 张表

// Step 3: 加载新增 update 脚本（排除 applied list 中的）
file:backend/script/sql/update/wande_ai/*.sql
   .filter(name -> !appliedList.contains(name))
   .sortByName()
```

**冻结机制说明**：
- `test-base-schema.pg.sql`：从 dev PG 一次性 dump 的快照（含历史所有表）
- `test-base-applied.txt`：冻结时已存在的 261 个 update 脚本名清单（视为已应用）
- CC 后续新写的 update 脚本（不在清单里的）会自动加载

**何时重新冻结**：
- dev PG schema 大幅演进后（添加几十张新表），可重跑 dump 脚本刷新 base
- 命令模板见 `regen-test-base-schema.sh`（待补）

---

## 六、技术细节坑

### 6.1 pgvector 扩展导致 pg_dump 失败

dev PG 装了 pgvector 扩展但 server 端 lib 文件路径有问题（`could not access file "$libdir/vector"`），导致 `pg_dump -s` 整体失败。

**workaround**：不用 `pg_dump`，直接用 SQL 查 `information_schema.columns + table_constraints` 自己拼 `CREATE TABLE` + `ALTER TABLE ADD PRIMARY KEY`。生成脚本见 `regen-test-base-schema.py`（保存在 docs 仓库 `scripts/` 待补）。

### 6.2 vector 列在测试库统一为 bytea

测试库不需要做向量查询，把 `udt_name='vector'` 列在 dump 时改成 `bytea`，避免依赖 pgvector 扩展。

### 6.3 数组类型处理

`information_schema` 用 `_text`、`_varchar` 等内部表示数组，需要转成 `text[]`、`varchar[]`。

### 6.4 nextval 默认值跳过

`nextval('xxx_seq'::regclass)` 这种 sequence default 在 dump 时跳过（保留 `BIGSERIAL` 风格反而更通用）。

---

## 七、待解决：2117 个历史 errors

按业务功能拆成 ≤20 个 GitHub issue（dev 上提交 `2026-04-07-mvn-test-fix-{N}` 系列）：

| 功能 | Errors | 主要 root cause |
|------|-------:|----------------|
| D3 设计与参数化 | 410 | excludeFilters 排除导致 NoBean / SQL 不兼容 |
| 项目执行与看板 | 235 | 同上 |
| 预算资金与佣金 | 222 | mapper 重复定义 |
| Token 池与运营 | 210 | NoBean |
| 整改与质保 | 116 | `deleted` 列 boolean vs integer |
| 驾驶舱与运维 | 110 | NoBean |
| ...（共 19 组） | ~800 | 各种 |

修复策略由 CC 在各 issue 内独立处理，PR 合并时 `unit-test` 关卡自动校验通过数不退化。

---

## 八、未来改进

1. **schema 重新冻结脚本**：把 dump python 脚本固化到 `scripts/regen-test-base-schema.py`，定期（每月或大版本前）重跑刷新 base
2. **每个 PR 显示 delta**：`unit-test` job 把 `passed - baseline` 写到 PR comment
3. **基线自动提升**：每周 cron 扫 dev 跑测试，若 passed > baseline 自动 commit 提升基线
4. **mapper 命名规范**：禁止 mapper 接口写在 `domain.*` 包下，强制 `mapper.*`，加 lint 规则
