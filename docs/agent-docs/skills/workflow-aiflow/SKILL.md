---
name: workflow-aiflow
description: LangGraph4j 工作流编排模块开发规范 — 节点类型/表结构/SSE 流式执行/Component 注册
type: skill
---

# 工作流编排（ruoyi-aiflow）

RuoYi-AI 自带的 **LangGraph4j** 工作流引擎模块。用于可视化编排 AI 问答 / 图像生成 / 知识检索 / 条件分支 / 人机交互等节点，SSE 流式回吐。

> **单一事实来源**：`backend/ruoyi-modules/ruoyi-aiflow/流程编排模块说明.md`（整份框架文档）。本 skill 只沉淀操作级要点，有出入以源文档为准。

## 何时使用本 skill

| 触发条件 | 说明 |
|---------|------|
| Issue 涉及「工作流 / 流程编排 / aiflow / langgraph」 | 必读 |
| 新增/修改 **节点组件**（Component / Node） | 必读 |
| 改 `t_workflow*` 系列表 | 必读 + backend-schema |
| 对接 `/workflow/run` SSE 流式接口 | 必读 |
| 仅消费已发布工作流（前端调 `/workflow/run`） | 可选，看一下 SSE 事件即可 |

> ⚠️ 本模块**不在** `ruoyi-modules/wande-ai/` 下，而在 `ruoyi-modules/ruoyi-aiflow/`。修改前确认改动属于工作流引擎本身，而非 wande 业务。业务逻辑仍应走 wande-ai，不要把业务代码污染进 aiflow。

## 核心依赖版本（改依赖前核对）

| 依赖 | 版本 | 作用 |
|------|------|------|
| LangGraph4j | 1.5.3 | 图执行引擎（StateGraph） |
| LangChain4j | 1.11.0 | AI 模型集成 |
| Spring Boot | 3.5.8 | 框架 |
| MyBatis-Plus | — | DAO |
| Redis | — | 运行时状态缓存 |

## 5 类节点速查（共 15 种）

| 分类 | 节点 name | 用途 |
|------|----------|------|
| **基础** | `Start` | 入口，定义工作流输入 |
| | `End` | 出口，汇总输出 |
| **AI 模型** | `Answer` | LLM 问答（LangChain4j）|
| | `Dalle3` | DALL-E 3 生图 |
| | `Tongyiwanx` | 通义万相生图 |
| | `Classifier` | 内容分类（多分支路由常搭配） |
| **数据处理** | `DocumentExtractor` | 文档抽取 |
| | `KeywordExtractor` | 关键词抽取 |
| | `FaqExtractor` | FAQ 抽取 |
| | `KnowledgeRetrieval` | RAG 知识库检索 |
| **控制流** | `Switcher` | 条件分支（多路由） |
| | `HumanFeedback` | 人机交互，挂起等用户输入 |
| **外部集成** | `Google` | Google 搜索 |
| | `MailSend` | 邮件发送 |
| | `HttpRequest` | 任意 HTTP 调用 |
| | `Template` | 字符串/JSON 模板渲染 |

节点实现类位于 `ruoyi-modules/ruoyi-aiflow/src/main/java/.../node/`，命名形如 `LLMAnswerNode` / `SwitcherNode`，统一继承 `AbstractWfNode`。

## 数据流与类型

```java
public class NodeIOData {
    private String name;               // 参数名
    private NodeIODataContent content; // 参数值 + type
}

public enum WfIODataTypeEnum {
    TEXT, NUMBER, BOOLEAN, FILES, OPTIONS
}
```

- 上下游节点引用：下游 `input_config` 里用 `${上游节点UUID.输出字段}` 表达式，引擎自动解析。
- 类型不匹配时引擎不会静默转换，务必 VO 上声明正确 `WfIODataTypeEnum`。

## 5 张核心表速览

> 表名**不带 `wdpp_` 前缀**（aiflow 是框架表，非万德业务表），也**没有** 7 列租户标准（tenant_id 不自动注入）。改表时不要套 wande-ai 表规范。

| 表 | 主键 | 关键字段 | 作用 |
|----|------|---------|------|
| `t_workflow` | `id` / `uuid` | `title` `remark` `user_id` `is_public` `is_enable` | 工作流定义 |
| `t_workflow_node` | `id` / `uuid` | `workflow_id` `workflow_component_id` `input_config`(JSON) `node_config`(JSON) `position_x/y` | 图节点实例 |
| `t_workflow_edge` | `id` / `uuid` | `workflow_id` `source_node_uuid` `source_handle` `target_node_uuid` | 有向边（source_handle 用于 Switcher 多分支） |
| `t_workflow_runtime` | `id` / `uuid` | `workflow_id` `user_id` `input`(JSON) `output`(JSON) `status` `status_remark` | 一次执行实例（含中断恢复） |
| `t_workflow_component` | `id` / `uuid` | `name`(唯一，代码 key) `title` `remark` `display_order` `is_enable` | 节点类型注册表 |

**status 枚举**（t_workflow_runtime）：1=运行中 / 2=完成 / 3=失败 / 4=等待用户反馈（HumanFeedback 挂起）。具体以代码枚举为准。

**JSON 列**：`input_config` / `node_config` / `input` / `output` — Entity 层统一用 `String`，Service 层 `ObjectMapper` 反序列化（与 backend-coding 保持一致）。

## 新增节点类型的标准流程（最常见改动）

1. **节点类**
   ```java
   public class MyCustomNode extends AbstractWfNode {
       public MyCustomNode(WorkflowComponent c, WorkflowNode n,
                           WfState wfState, WfNodeState nodeState) {
           super(c, n, wfState, nodeState);
       }
       @Override
       protected NodeProcessResult onProcess() {
           // 1. 读取输入：this.getInputs() → List<NodeIOData>
           // 2. 业务处理
           // 3. 构造输出
           List<NodeIOData> outputs = new ArrayList<>();
           outputs.add(NodeIOData.of("result", WfIODataTypeEnum.TEXT, "..."));
           return NodeProcessResult.success(outputs);
           // 失败：NodeProcessResult.fail("msg")
           // 需挂起人机交互：NodeProcessResult.waitFeedback(...)
       }
   }
   ```

2. **工厂注册**：在 `WfNodeFactory.create()` switch 加 `case "MyCustomNode": return new MyCustomNode(...);`。

3. **组件入库**（Flyway 增量，走 `ruoyi-modules/ruoyi-aiflow/src/main/resources/db/migration/`，不是 ruoyi-admin 目录）：
   ```sql
   INSERT INTO t_workflow_component (uuid, name, title, remark, display_order, is_enable)
   VALUES (REPLACE(UUID(),'-',''), 'MyCustomNode', '我的自定义节点',
           '节点功能说明', 100, 1);
   ```
   `name` 必须和 Java switch case / 前端元数据完全一致，大小写敏感。

4. **前端节点元数据**（前端工作流画布基于 Vue Flow）：在前端 `workflow/components/nodes/` 注册拖拽面板项 + 属性表单 schema。不写则画布上拖不出来。

5. **单测 + e2e**：
   - JUnit：构造 `WfState` + 最小 Graph，断言 `onProcess()` 输出
   - Playwright API：POST `/workflow/run` 带含该节点的 workflow，校验 SSE 流中收到 `[NODE_OUTPUT_<uuid>]`

## SSE 流式执行接口

```http
POST /workflow/run
Content-Type: application/json
Accept: text/event-stream

{
  "uuid": "工作流UUID",
  "inputs": [
    { "name": "input",
      "content": { "type": 1, "textContent": "你好" } }
  ]
}
```

**事件前缀**（前端按前缀路由到不同 UI 状态）：

| 事件 | 含义 | 载荷 |
|------|------|------|
| `[NODE_RUN_<uuid>]` | 节点开始 | — |
| `[NODE_INPUT_<uuid>]` | 节点入参 | `List<NodeIOData>` |
| `[NODE_OUTPUT_<uuid>]` | 节点完整输出 | `List<NodeIOData>` |
| `[NODE_CHUNK_<uuid>]` | LLM 流式分片 | 文本片段 |
| `[NODE_WAIT_FEEDBACK_BY_<uuid>]` | 等用户反馈（挂起） | — |

**恢复挂起的 workflow**：
```http
POST /workflow/runtime/resume/{runtimeUuid}
{ "feedbackContent": "用户补充的输入" }
```

其余端点：
- `POST /workflow/add|update`、`POST /workflow/del/{uuid}`、`POST /workflow/enable/{uuid}?enable=true`
- `GET  /workflow/mine/search` / `/workflow/public/search`
- `GET  /workflow/public/component/list` — 前端画布拉节点目录
- `GET  /workflow/runtime/page` / `/workflow/runtime/nodes/{runtimeUuid}`
- 管理端：`POST /admin/workflow/search` / `POST /admin/workflow/enable`

## 常见陷阱与红线

- ❌ **按 wande 业务规范套 aiflow 表** — 表名**不加 `wdpp_`**、**不加** tenant_id/create_dept 等 7 列；Flyway 脚本位置是 `ruoyi-aiflow` 模块自己的 `db/migration/`。
- ❌ **业务代码写进 aiflow** — 万德业务逻辑必须在 `wande-ai` 模块；aiflow 只留通用节点与引擎。若要让业务调工作流，通过 `/workflow/run` REST 接口调用。
- ❌ **Component.name 与 Java switch case 不一致** — 拖到画布上运行时会走 `default` 抛 "unknown component"。
- ❌ **新节点忘了在前端注册元数据** — 后端代码再齐也无法从画布拖出。
- ❌ **SSE Emitter 没在节点异常路径 complete/completeWithError** — 连接悬挂，前端转圈。`onProcess()` 抛异常引擎会兜底，但自行在节点里 catch 后**必须**返回 `NodeProcessResult.fail()` 让引擎继续处理 SSE 关闭。
- ❌ **在节点里阻塞调用外部 HTTP 不设超时** — 整个工作流卡死。`HttpRequest` 节点自带超时，自定义节点务必显式设 connect/read timeout。
- ❌ **改 `t_workflow_*` 表字段不走 Flyway 增量** — aiflow 的 baseline SQL 不允许直接编辑，同 backend-schema 规范。
- ❌ **`input_config` / `node_config` JSON 存成对象字段** — Entity 用 `String`，Service 层 ObjectMapper 处理（避免 MyBatis TypeHandler 踩坑）。
- ❌ **Switcher 多分支忘设 `source_handle`** — 引擎找不到分支目的地，执行停在 Switcher。每个 case 对应一条 edge，edge 的 `source_handle` 要与 Switcher `node_config` 里的 case key 对齐。
- ❌ **HumanFeedback 节点后用 `/workflow/run` 而非 `/resume`** — 会新建 runtime 不延续上下文。挂起态必须走 resume。

## 改完必验

```bash
cd backend
# 1. 编译（aiflow 模块在父 pom 里，整包编译）
mvn clean compile -Pprod -DskipTests

# 2. 单测只跑 aiflow
mvn test -pl ruoyi-modules/ruoyi-aiflow

# 3. 启动后 curl 组件列表，确认新节点出现
curl -s http://localhost:810<N>/workflow/public/component/list \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {name,title,isEnable}'

# 4. Playwright API spec：构造含新节点的 workflow 跑一次 /workflow/run，断言 SSE 流包含 [NODE_OUTPUT_<uuid>]
```

看到组件列表含新节点 + SSE 流正常结束（`[DONE]` 或连接自然 close）= 通过。
