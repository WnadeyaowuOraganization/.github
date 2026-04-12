# 编程CC虚拟环境E2E测试优化方案

## 问题背景

**当前痛点：**
1. PR-Test由CI触发，测试失败后通过通知机制告知编程CC，反馈延迟
2. 编程CC无法在本地快速验证E2E测试，只能等待CI结果
3. 缺乏隔离的测试环境，多个CC同时工作时互相干扰
4. 测试反馈链路长：代码提交 → CI排队 → 构建 → 测试 → 通知 → CC查看

**目标：**
让每个编程CC拥有独立的虚拟测试环境，写完代码后立即执行E2E测试，实时获得图形化反馈。

---

## 现有架构分析

### E2E测试框架
- **框架**: Playwright v1.59.1
- **配置**: `/home/ubuntu/projects/wande-play/e2e/playwright.config.ts`
- **测试数量**: 158个spec文件（86后端API + 65前端Smoke + E2E journey）
- **并行执行**: `fullyParallel: true`, CI workers=2

### 现有CI流程
```
PR创建/更新
  ↓
pr-test.yml触发
  ↓
构建CI环境(backend:6041, frontend:8084)
  ↓
执行E2E测试
  ↓
生成JSON报告
  ↓
e2e-result-handler.py解析
  ↓
PR评论/Issue更新
  ↓
CC收到通知
```

### 编程CC工作目录
- 20个kimi目录: `wande-play-kimi1` ~ `wande-play-kimi20`
- 每个目录有独立的前后端代码
- 共享dev服务(backend:6040, frontend:8083)

---

## 业界最佳实践调研

### 1. Playwright容器化测试
- **官方镜像**: `mcr.microsoft.com/playwright:v1.44.0-jammy`
- **优势**: 预装所有浏览器依赖，环境一致性
- **最佳实践**: 使用version-specific tags，multi-stage builds

### 2. 本地并行执行
```javascript
// playwright.config.ts
export default defineConfig({
  fullyParallel: true,
  workers: process.env.CI ? 2 : 4, // 本地更多workers
  retries: process.env.CI ? 2 : 0,  // 本地不重试
});
```

### 3. 测试隔离策略
- **认证状态复用**: 使用`storageState`避免每次登录
- **数据库隔离**: 每个CC独立数据库（已部分实现）
- **服务隔离**: 独立端口运行backend/frontend

### 4. AI Agent实时反馈
- **Playwright MCP**: AI直接控制浏览器进行测试
- **自我修复**: AI检测失败的selector并自动修复
- **即时反馈**: 测试失败立即在Agent会话中展示

---

## 优化方案设计

### 方案架构

```
┌─────────────────────────────────────────────────────────────┐
│                    编程CC虚拟测试环境架构                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  kimi1 CC   │    │  kimi2 CC   │    │  kimiN CC   │     │
│  │             │    │             │    │             │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │ Backend │ │    │ │ Backend │ │    │ │ Backend │ │     │
│  │ │ :7101   │ │    │ │ :7102   │ │    │ │ :71xx   │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │ Frontend│ │    │ │ Frontend│ │    │ │ Frontend│ │     │
│  │ │ :8101   │ │    │ │ :8102   │ │    │ │ :81xx   │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │ Test DB │ │    │ │ Test DB │ │    │ │ Test DB │ │     │
│  │ │ :5431   │ │    │ │ :5432   │ │    │ │ :54xx   │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │Playwright│    │ │Playwright│    │ │Playwright│     │
│  │ │Container│ │    │ │Container│ │    │ │Container│ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │            │
│         └──────────────────┼──────────────────┘            │
│                            │                               │
│                   ┌────────▼────────┐                      │
│                   │  Test Results   │                      │
│                   │  Dashboard      │                      │
│                   │  (Port 9000)    │                      │
│                   └─────────────────┘                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 核心组件

#### 1. CC虚拟环境管理器 (`cc-test-env.sh`)

**功能:**
- 为每个kimi目录分配独立端口
- 管理PostgreSQL容器生命周期
- 启动/停止/重启CC专属测试环境
- 健康检查和日志收集

**端口分配策略:**
```bash
# kimi{N} 端口分配
BACKEND_PORT=7100+N  # 7101-7120
FRONTEND_PORT=8100+N # 8101-8120
DB_PORT=5400+N       # 5401-5420
```

#### 2. 快速启动脚本 (`cc-test-quickstart.sh`)

**功能:**
- 一键启动CC测试环境
- 自动构建backend/frontend
- 初始化测试数据库
- 启动Playwright容器

**执行流程:**
```bash
# 1. 检查端口占用
# 2. 启动PostgreSQL容器 (如果未运行)
# 3. 初始化数据库 (Flyway migrate)
# 4. 构建并启动Backend (Maven)
# 5. 构建Frontend (Vite)
# 6. 启动HTTP服务器
# 7. 启动Playwright容器
# 8. 健康检查
# 9. 输出访问地址
```

#### 3. 实时测试执行器 (`cc-test-run.sh`)

**功能:**
- 在Playwright容器中执行测试
- 实时输出测试结果
- 生成HTML报告
- 捕获失败截图和视频

**模式:**
```bash
# 模式1: 快速 smoke 测试
cc-test-run.sh --smoke

# 模式2: 指定测试文件
cc-test-run.sh --spec tests/front/smoke/login.spec.ts

# 模式3: 修复模式 (自动重试失败的测试)
cc-test-run.sh --fix

# 模式4: UI模式 (带浏览器界面)
cc-test-run.sh --ui
```

#### 4. 结果实时反馈 (`cc-test-feedback.py`)

**功能:**
- 解析Playwright JSON报告
- 在tmux会话中显示结果摘要
- 发送通知到manager会话
- 自动分类: 代码问题 vs 测试问题

**输出格式:**
```
========================================
E2E测试结果 - kimi1
========================================
✅ 通过: 42 / 45 (93.3%)
❌ 失败: 3

失败测试:
1. [登录] should login with valid credentials
   → 截图: /tmp/cc-test/kimi1/screenshots/login-fail.png
   → 视频: /tmp/cc-test/kimi1/videos/login-fail.webm
   → 可能原因: 后端登录接口返回500

2. [项目列表] should display project list
   → 原因: 选择器 .project-table 未找到
   → 建议: 检查最新代码中类名是否变更

修复建议:
- 检查 backend/src/.../LoginController.java:45
- 确认前端 views/wande/project/index.vue 第23行
```

#### 5. Playwright容器配置

**Dockerfile:**
```dockerfile
FROM mcr.microsoft.com/playwright:v1.59.1-jammy

WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm ci

# 复制测试代码
COPY . .

# 预下载浏览器
RUN npx playwright install chromium

# 默认命令
CMD ["npx", "playwright", "test", "--reporter=json,line"]
```

**Docker Compose (per CC):**
```yaml
version: '3.8'
services:
  playwright-kimi1:
    build: ./e2e
    environment:
      - BASE_URL_API=http://host.docker.internal:7101
      - BASE_URL_FRONT=http://host.docker.internal:8101
      - CI=false
      - WORKERS=4
    volumes:
      - ./e2e/test-results:/app/test-results
      - ./e2e/playwright-report:/app/playwright-report
    network_mode: host  # 访问宿主机的服务
```

### 工作流程

#### 场景1: CC编写新功能后立即测试

```bash
# 在kimi1目录中工作
cd ~/projects/wande-play-kimi1

# 编写代码...

# 启动测试环境 (一次性，后续复用)
cc-test-quickstart.sh
# 输出:
# ✅ Backend 启动成功: http://localhost:7101
# ✅ Frontend 启动成功: http://localhost:8101
# ✅ Playwright 就绪
# 📝 执行测试: cc-test-run.sh

# 执行E2E测试
cc-test-run.sh --smoke
# 实时输出测试结果...
# 3秒后显示结果摘要

# 如果有失败，查看详情
cat /tmp/cc-test/kimi1/report.json | cc-test-feedback.py
```

#### 场景2: 修复Bug后验证

```bash
# 修改代码...

# 只运行失败的测试
cc-test-run.sh --fix

# 或指定测试文件
cc-test-run.sh --spec tests/front/smoke/login.spec.ts
```

#### 场景3: 完整回归测试

```bash
# 提交前完整测试
cc-test-run.sh --full
# 等价于: npx playwright test
```

#### 场景4: 调试模式

```bash
# 带浏览器界面的调试模式
cc-test-run.sh --ui
# 自动打开 Playwright UI 模式
```

### 关键优化点

#### 1. 环境预热 (Warm-up)

**问题**: 每次启动环境需要3-5分钟
**方案**: 使用Docker volume缓存
```bash
# 预构建镜像并缓存依赖
docker build -t wande-playwright:latest ./e2e

# 使用匿名volume保留node_modules
-v /app/node_modules
```

#### 2. 数据库快速恢复

**问题**: Flyway migration耗时
**方案**: 使用数据库快照
```bash
# 创建基准数据库快照
pg_dump -h localhost -p 5431 -U postgres wande_ai > /tmp/cc-test/baseline.sql

# 快速恢复
createdb -h localhost -p 5431 -U postgres wande_ai_test
psql -h localhost -p 5431 -U postgres wande_ai_test < /tmp/cc-test/baseline.sql
```

#### 3. 并行测试优化

**配置:**
```javascript
// playwright.config.ts
export default defineConfig({
  fullyParallel: true,
  workers: process.env.CI ? 2 : Math.min(4, require('os').cpus().length),
  retries: process.env.CI ? 2 : 0,
  
  // 认证状态复用
  projects: [
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
```

#### 4. 实时日志流

**方案**: 使用inotifywatch + tail
```bash
# 监控测试结果文件变化
inotifywait -m /tmp/cc-test/kimi1/test-results \
  -e create -e modify \
  --format '%w%f' \
  | while read file; do
      cc-test-feedback.py --file "$file"
    done
```

### 集成到现有工作流

#### 1. 修改编程CC启动脚本

在`run-cc.sh`中添加环境初始化检查:
```bash
# 启动CC前检查测试环境
if [ ! -f "$KIMI_DIR/.test-env-ready" ]; then
  echo "🚀 初始化测试环境..."
  cc-test-quickstart.sh --kimi $KIMI_ID
  touch "$KIMI_DIR/.test-env-ready"
fi
```

#### 2. 添加测试命令到CC prompt

在编程CC的system prompt中添加:
```markdown
## 测试命令
当你完成代码修改后，可以立即执行E2E测试验证:

```bash
# 快速Smoke测试 (~30秒)
cc-test-run.sh --smoke

# 指定测试文件
cc-test-run.sh --spec tests/front/smoke/xxx.spec.ts

# 调试模式 (带UI)
cc-test-run.sh --ui
```

测试结果会自动显示在本会话中。
```

#### 3. 失败自动诊断

增强`cc-test-feedback.py`:
```python
# 自动诊断失败原因
def diagnose_failure(test_name, error_message, screenshot_path):
    # 1. 检查是否是selector问题
    if "TimeoutError" in error_message and "locator" in error_message:
        return "可能是前端DOM结构变更，建议检查最近的代码修改"
    
    # 2. 检查是否是API问题
    if "expected 200" in error_message:
        return "后端API返回非200，建议检查backend日志"
    
    # 3. 使用AI分析截图
    if os.path.exists(screenshot_path):
        return ai_analyze_screenshot(screenshot_path)
```

### 预期效果

| 指标 | 优化前 | 优化后 |
|-----|-------|-------|
| 测试启动时间 | 3-5分钟(CI排队+构建) | 10秒(环境已预热) |
| 反馈延迟 | 5-15分钟(CI完成) | 30-60秒(本地执行) |
| 环境隔离 | 共享dev环境 | 每个CC完全隔离 |
| 并发能力 | 依赖CI队列 | 20个CC并行测试 |
| 调试效率 | 远程日志+截图 | 本地浏览器+断点 |

### 实施步骤

**Phase 1: 基础设施 (Week 1)**
1. 创建 `cc-test-env.sh` 端口分配和管理
2. 创建 `cc-test-quickstart.sh` 环境启动脚本
3. 配置 Playwright Docker 镜像

**Phase 2: 测试执行 (Week 1-2)**
1. 创建 `cc-test-run.sh` 测试执行脚本
2. 创建 `cc-test-feedback.py` 结果反馈
3. 集成到编程CC prompt

**Phase 3: 优化和迭代 (Week 2-3)**
1. 环境预热优化
2. 数据库快照机制
3. 失败自动诊断

**Phase 4: 全量推广 (Week 3)**
1. 所有kimi目录启用
2. 文档更新
3. 监控和告警

---

## 参考资源

- [Playwright Parallel Execution Guide](https://testdino.com/blog/playwright-parallel-execution/)
- [Running Playwright Tests in Docker](https://nareshit.com/blogs/running-playwright-tests-in-docker-containers)
- [Playwright MCP for AI Agents](https://claudecode.app/blog/playwright-mcp-advanced-browser-automation-for-ai-agents)
- [E2E Test AI Agent Architecture](https://dev.to/robin_xuan_nl/5-minutes-of-human-ai-interaction-from-requirements-to-e2e-test-result-1o71)
