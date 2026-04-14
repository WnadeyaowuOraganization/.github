---
name: agentic-ai
description: Pure Agentic AI 开发规范 — SupervisorAgent + SubAgent + Tool，LangChain4j 注解与 AgenticServices 构建
type: skill
---

# Agentic AI 编码规范

LangChain4j 1.11 **Pure Agentic AI** 架构。业务代码位于 `backend/ruoyi-modules/ruoyi-chat/`。参考实现：`org.ruoyi.agent.SqlAgent` + `org.ruoyi.agent.tool.*`。

## 何时使用

- 新建一个业务智能体（SubAgent），例如图表生成、网页搜索、报告分析
- 为已有智能体新增工具（Tool）
- 在 `OpenAIServiceImpl.doAgent()` 或同级入口注册新的 SubAgent 到 SupervisorAgent
- 涉及多 Agent 协作（Supervisor 调度多个 SubAgent）

只有"自然语言 → LLM 决策 → 调用工具"的场景才属于 Agentic AI；纯同步问答或固定链路用 `AiServices` 即可，**不要**套 Supervisor。

## 三层架构职责

| 层 | 载体 | 职责 | 禁止 |
|---|------|------|------|
| Supervisor | `AgenticServices.supervisorBuilder()` 产出 | 接用户请求，决策调用哪个 SubAgent，聚合响应 | 直接调 Tool；写死调用顺序 |
| SubAgent | `interface XxxAgent`（LangChain4j 动态代理生成实现） | 在某一**领域**内理解需求 → 选 Tool → 组织返回 | 跨领域扩展；手写 impl 类 |
| Tool | `@Tool` 方法所在 Spring Bean | 一次**原子、确定性**操作（查库、HTTP、算） | 调 LLM；做副作用写操作；跨领域混合 |

**边界提示**：一个 SubAgent 对应一个"专家角色"（SqlAgent = 数据库专家；EchartsAgent = 图表专家）。新业务先问"是加 Tool 还是加 SubAgent" —— 能在已有 Agent 下加 Tool 就不拆新 Agent。

## 核心注解速查

| 注解 | 位置 | 用途 |
|------|------|------|
| `@SystemMessage` | SubAgent 接口方法 | 系统提示，约束角色、输出格式、可用工具的使用策略 |
| `@UserMessage` | SubAgent 接口方法 | 模板化用户输入，含 `{{var}}` 占位符 |
| `@Agent("desc")` | SubAgent 接口方法 | **关键**：Supervisor 据此描述选择调用哪个 SubAgent，描述必须清晰概括能力 |
| `@V("var")` | 方法参数 | 绑定到 `@UserMessage` 的 `{{var}}` 占位符 |
| `@Tool("desc")` | Tool 类的 public 方法 | 声明该方法可被 LLM 调用；描述决定 LLM 是否/何时选它 |
| `@P("desc")` | Tool 方法参数（可选） | 参数语义说明，帮 LLM 正确填参 |

`@Agent` / `@Tool` 的 description **面向 LLM 而非人类**：用英文、动宾结构、列典型输入输出，避免"工具1""处理数据"这类空话。

## 标准实现骨架

### 1. SubAgent 接口

```java
package org.ruoyi.agent;

public interface ReportAgent {

    @SystemMessage("""
        你是报告分析专家。可用工具：
        - queryMetrics(range)：拉取指定时间段指标
        - summarize(text)：压缩长文本
        策略：先拉数据再总结，不要编造数字。
        """)
    @UserMessage("请回答：{{query}}")
    @Agent("A report analysis expert that fetches metrics and produces concise summaries. Use it for any question about KPI/metrics/trend reports.")
    String analyze(@V("query") String query);
}
```

接口方法返回 `String`（或 `TokenStream`，但 Supervisor 组合时优先 String）。**不写** impl 类，LangChain4j 动态代理。

### 2. Tool 类

```java
package org.ruoyi.agent.tool;

@Component
@RequiredArgsConstructor
public class QueryMetricsTool {

    private final MetricsMapper metricsMapper;

    @Tool("Query aggregated metrics in a given time range, e.g. '2026-04-01~2026-04-14'. Returns formatted rows, max 20.")
    public String queryMetrics(@P("time range, format YYYY-MM-DD~YYYY-MM-DD") String range) {
        // 1. 输入校验（正则 / 白名单，防注入）
        // 2. 只读查询
        // 3. 格式化为行文本，截断到 20 行
        // 4. 失败返回可读 error string，**不抛异常**（抛异常会被 LangChain4j 包成冷冰冰的 ToolExecutionException）
    }
}
```

Tool 必须是 Spring Bean（`@Component` / `@Service`），依赖通过构造注入。**返回 String**，让 LLM 继续推理；如必须返回结构化，用 JSON 字符串。

### 3. 注册到 Supervisor

```java
// OpenAIServiceImpl.doAgent()
SupervisorAgent supervisor = AgenticServices
    .supervisorBuilder()
    .chatModel(PLANNER_MODEL)
    .subAgents(sqlAgent, echartsAgent, reportAgent)   // 多个 SubAgent 并列
    .responseStrategy(SupervisorResponseStrategy.SUMMARY)
    .build();

String answer = supervisor.invoke(userQuery);
```

`SubAgent` 通过 `AiServices.builder(ReportAgent.class).chatModel(model).tools(queryMetricsTool, summarizeTool).build()` 构造后注入给 Supervisor。Tool 列表在此阶段装配，**不在** Supervisor 上挂 Tool。

### 4. ResponseStrategy 选择

| 策略 | 含义 | 用法 |
|------|------|------|
| `SUMMARY` | 聚合所有 SubAgent 输出为摘要 | **默认**。多 Agent 协作 |
| `LAST` | 只返回最后一个 SubAgent 结果 | 串行确定末尾输出 |
| `SCORED` | 评分挑最优 | 候选生成类任务 |

## 参考案例命名与返回约定

| Tool | 描述风格 | 返回 |
|------|---------|------|
| `QueryAllTablesTool.queryAllTables()` | `@Tool("Query all tables in the database and return table names and basic information")` | 多行 `表名 | 注释` |
| `QueryTableSchemaTool.queryTableSchema(String)` | `@Tool("Query the CREATE TABLE statement (DDL) for a specific table by table name")` | 建表 SQL，表名正则校验失败返回 error 文本 |
| `ExecuteSqlQueryTool.executeSql(String)` | `@Tool("Execute a SELECT SQL query and return the results. Example: SELECT * FROM sys_user")` | 表格文本，最多 20 行；非 SELECT 拒绝 |

命名规则：`动词+名词+Tool`（Query/Execute/Fetch/Generate …），方法名与类名动词一致。描述必带一个 **Example**，显著提升 LLM 选择准确率。

## 数据源 / 外部资源隔离

- Agent 专用数据源走 `agentDataSource` Bean（`AgentMysqlConfig`，HikariCP），**禁止**复用业务主数据源
- 配置走 `agent.mysql.*` / `agent.<feature>.*` properties 类，凭证不硬编码
- 只读工具（查库、查 API）与写工具**不要放同一个 Tool 类**，便于权限审计

## 禁止事项

- ❌ 在 Tool 里做**副作用写操作**（INSERT/UPDATE/DELETE/发外部订单）— Agent 决策不可预测，写操作必须走显式业务 Service + 人工确认
- ❌ 手写 SubAgent impl 类（`class SqlAgentImpl implements SqlAgent`）— 必须由 `AiServices` 动态生成
- ❌ 在 Supervisor 上直接挂 `.tools(...)` — Tool 归属 SubAgent
- ❌ 混用旧的 `AiServices` 同步流 + `SupervisorAgent` 于同一请求（要么 Supervisor 统筹，要么直接 AiServices，**不叠加**）
- ❌ `@SystemMessage` 里写"你必须先调 ToolA 再调 ToolB" 这种硬流程 — 这是 Agentic AI 的反模式，写死就用普通 Service
- ❌ Tool 抛 checked/runtime 异常到 LangChain4j — 捕获后返回 error String，给 LLM 一个重试机会
- ❌ `@Tool` 描述用中文 / "工具1" / "处理" 等空话 — 用英文动宾 + Example
- ❌ 一个 Tool 方法既做查询又做格式化 LLM 已能处理的长结构 — 职责拆分，单方法单意图
- ❌ SubAgent 的 `@Agent` 描述缺失或与其他 Agent 重叠 — Supervisor 无法正确路由

## 调试 / 验证

```bash
# 启动 chat 模块（随后端整体启动）
cd ~/projects/wande-play-kimi<N>
bash e2e/scripts/start-backend.sh

# 观察 Agent 决策链路
tail -f logs/sys-info.log | grep -E "Agent|Tool|Supervisor"

# 触发一次对话测试
curl -X POST http://localhost:810<N>/chat/agent \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"数据库里有哪些表"}'
```

日志应依次出现：`SupervisorAgent` 决策 → `<SubAgent>` 调用 → `<Tool>` 执行 → 结果回传。没看到任一层 = 注解 / 注册漏了。

## 新增 Agent 的最小检查清单

1. SubAgent 接口含 `@SystemMessage` + `@UserMessage` + `@Agent` + `@V`，返回 String
2. 每个 Tool 类 `@Component`，方法 `@Tool("英文描述 + Example")`，返回 String
3. `AiServices.builder(XxxAgent.class).tools(...)` 装配 SubAgent
4. `supervisorBuilder().subAgents(...)` 注册新 SubAgent
5. 新数据源走独立 properties + Config，**不复用**主库
6. 只读：Tool 内做输入白名单 / 正则校验 / 行数截断
7. 日志能看到三层调用链；异常不外抛，以 error String 回传
