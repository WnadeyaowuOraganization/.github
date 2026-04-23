---
name: sse-streaming
description: SSE 流式接口开发规范 — SseEmitter / Flux<ServerSentEvent> 选型、Nginx 缓冲关闭、CORS、生命周期
type: skill
---

# SSE 流式接口规范

Server-Sent Events 在 Wande-Play 主要用于聊天流式输出、长任务进度推送、Agent 思考过程透传。错误的生命周期管理会导致连接泄漏、内存堆积、Nginx 缓冲后「一次性吐字」。

## 何时使用

- 后端向前端单向推送、延迟敏感（Token 级流式）→ **用 SSE**
- 需要双向通信（客户端持续发消息）→ **用 WebSocket**，不要用 SSE 强凑
- 一次性返回可接受等待（<2s）→ **普通 REST**，不要为了"看起来流式"套 SSE
- 文件下载 / 二进制流 → **StreamingResponseBody**，不是 SSE

## 技术选型

| 场景 | 推荐 | 原因 |
|------|------|------|
| Spring MVC（本项目主栈） | `SseEmitter` | RuoYi 已集成 `SseEmitterManager`，复用心跳 + 多会话管理 |
| Spring WebFlux | `Flux<ServerSentEvent<T>>` | 响应式栈原生支持，背压可控 |
| 需要手动控制事件名 / id / retry | `SseEmitter.event().name().id().reconnectTime()` | `Flux` 需 `ServerSentEvent.builder()` |
| 多租户 / 多会话广播 | 复用 `SseEmitterManager`（`ruoyi-common-sse`） | 已实现 USER→TOKEN→Emitter 三级映射 + 60s 心跳 |

**本项目新功能一律用 `SseEmitter` + 注入 `SseEmitterManager`**，禁止自建连接池。

## 标准 Controller 骨架

```java
@RestController
@RequestMapping("/wande/xxx")
@RequiredArgsConstructor
public class XxxStreamController {

    private final SseEmitterManager sseEmitterManager;
    private final XxxStreamService streamService;

    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@RequestBody @Valid XxxBo bo) {
        Long userId = LoginHelper.getUserId();
        String token = StpUtil.getTokenValue();

        // 复用 manager：内部已挂 onCompletion/onTimeout/onError 清理
        SseEmitter emitter = sseEmitterManager.connect(userId, token);

        // 异步执行，立即返回 emitter，禁止在 Controller 线程同步 emit
        streamService.runAsync(bo, userId, token);
        return emitter;
    }
}
```

**关键点**：
- `produces = MediaType.TEXT_EVENT_STREAM_VALUE` 必须，否则浏览器按普通 JSON 接收
- 返回类型直写 `SseEmitter`，**禁止** `ResponseEntity<SseEmitter>`（Spring MVC 会报 `IllegalStateException: ServletResponse` 或丢 content-type）
- timeout 交给 `SseEmitterManager`（默认 86400000ms=24h）；自建 Emitter 时显式传 timeout，`new SseEmitter(0L)` 代表无超时但会吃 Tomcat 异步线程池

## 异步发送端（Service 层）

```java
@Async
public void runAsync(XxxBo bo, Long userId, String token) {
    try {
        for (String chunk : producer.produce(bo)) {
            SseEventDto dto = SseEventDto.content(chunk);
            sseEmitterManager.sendEvent(userId, dto);  // 内部 try/catch + 失败移除
        }
        SseMessageUtils.sendDone(userId);
    } catch (Exception e) {
        SseMessageUtils.sendError(userId, e.getMessage());
    } finally {
        SseMessageUtils.completeConnection(userId, token);  // 必须 complete
    }
}
```

## Nginx 必须配置

SSE 经过 Nginx 反向代理时，**默认 `proxy_buffering on` 会把流缓冲到响应结束**，前端看不到增量输出。

```nginx
location /api/wande/xxx/stream {
    proxy_pass http://backend;
    proxy_http_version 1.1;

    # SSE 三件套（缺一不可）
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;

    # 长连接
    proxy_read_timeout 24h;
    proxy_send_timeout 24h;
    proxy_set_header Connection '';
}
```

验证：`curl -N http://host/api/.../stream`，应看到 `data: ...` 逐条吐出，**不是**等结束才一次性输出。

## CORS

SSE 受同源策略约束，浏览器 `EventSource` **不支持自定义 header**（无法加 `Authorization`），解决方式：

- **鉴权 token 走 query**：`?access_token=xxx`，Sa-Token 已支持 `StpUtil.setTokenValue(request.getParameter("access_token"))`
- 跨域时响应必须含 `Access-Control-Allow-Credentials: true` 且 `Allow-Origin` 不能为 `*`

## 前端 EventSource 对接要点

```ts
const url = `${baseURL}/wande/xxx/stream?access_token=${token}`;
const es = new EventSource(url, { withCredentials: true });

es.addEventListener('message', (e) => { /* 默认事件 */ });
es.addEventListener('content', (e) => { render(JSON.parse(e.data)); });
es.addEventListener('done', () => es.close());          // 必须主动 close
es.addEventListener('error', () => es.close());         // 否则浏览器自动重连打爆后端
```

POST body + SSE 组合浏览器不原生支持，需用 `@microsoft/fetch-event-source` 或改 GET + query。

## 生命周期与并发

`SseEmitterManager.connect(userId, token)` 行为：
- 同一 `(userId, token)` 新建会**关闭老连接**并 `complete()`
- `onCompletion` / `onTimeout` / `onError` 全挂钩清理映射表
- 60s 心跳 `: heartbeat\n\n`（注释行），失败即移除

自建 Emitter 时必须三钩齐全：

```java
emitter.onCompletion(() -> cleanup(id));
emitter.onTimeout(() -> { emitter.complete(); cleanup(id); });
emitter.onError(e -> { emitter.completeWithError(e); cleanup(id); });
```

## 红线

- ❌ **禁 `ResponseEntity<SseEmitter>`** — 用裸 `SseEmitter` 返回
- ❌ **禁在 `@Transactional` 方法内 emit** — 事务持有 DB 连接期间长流会占死连接池，拆成 `事务方法 → @Async SSE 推送`
- ❌ **禁不 complete 直接 return** — Emitter 会挂到超时（默认 30s Tomcat）才释放线程
- ❌ **禁在 Controller 线程同步 emit 大量数据** — 阻塞 Tomcat worker，改 `@Async` 或 `CompletableFuture`
- ❌ **禁裸 `new SseEmitter()`（默认 30s 超时）** — 必须显式 timeout 或走 `SseEmitterManager`
- ❌ **禁 Nginx 默认配置** — 缺 `proxy_buffering off` = 流式假象
- ❌ **禁自建 `ConcurrentHashMap<userId, Emitter>`** — 复用 `SseEmitterManager`，避免心跳 / 清理重复造轮子
- ❌ **禁忘记 done 事件** — 前端 `EventSource` 不 close 会无限重连（默认 3s）打爆后端

## 自测 checklist

- [ ] `curl -N -H "Accept: text/event-stream" http://localhost:710<N>/wande/xxx/stream` 看到逐条 `data:` 增量输出（不是一次性）
- [ ] 浏览器 DevTools → Network → EventStream 面板有事件流
- [ ] 断网 60s 后后端日志有心跳失败清理，内存 `USER_TOKEN_EMITTERS` 条目数不增长
- [ ] 同一用户连开 2 个 tab：老连接被 `complete()`，不会双推
- [ ] 异常路径（模型报错）走 `onError` → 前端收到 `error` 事件 → emitter 被 complete
