# 管线CC 指南

> 管线CC负责万德AI平台数据采集层的Python开发。

## 仓库定位

**wande-play/pipeline** 是万德AI平台的**数据采集层**：

```
互联网数据源 → 采集(Collect) → 清洗(Clean) → 验证(Verify) → 落库(Persist)
```

| 目录 | 职责 | 语言 |
|------|------|------|
| **pipeline/**（本目录） | 数据采集→清洗→验证→落库 + 深挖 | Python |
| backend/ | 后端API + 数据展示 + 人工标记 | Java |
| frontend/ | 前端页面 + 人工操作界面 | Vue3 |

## 快速导航

| 文档 | 内容 | 何时读取 |
|------|------|---------|
| [docs/workflow.md](docs/workflow.md) | 三阶段开发流程、Issue读取、验证门禁 | 每次开始新Issue时 |
| [docs/environment.md](docs/environment.md) | G7e服务器、数据库、AI模型、搜索引擎 | 需要连接外部服务时 |
| [docs/conventions.md](docs/conventions.md) | 建表规范、Python规范、代码模板 | 写代码时 |
| [docs/pipeline-domestic-projects.md](docs/pipeline-domestic-projects.md) | 国内项目采集（7步管线、5张表） | 处理国内项目Issue时 |
| [docs/pipeline-domestic-clients.md](docs/pipeline-domestic-clients.md) | 国内客户采集（4步管线） | 处理国内客户Issue时 |
| [docs/pipeline-international-clients.md](docs/pipeline-international-clients.md) | 国际客户采集（5步管线、6张表） | 处理国际客户Issue时 |
| [docs/pipeline-competitors.md](docs/pipeline-competitors.md) | 竞争对手采集（5步管线、7张表） | 处理竞品Issue时 |

## 四类数据管线总览

| # | 数据类 | 目录 | 状态 | 频率 |
|---|--------|------|------|------|
| 1 | 国内项目 | `pipelines/domestic_projects/` | ✅ 已运行 | 每2h |
| 2 | 国内客户 | `pipelines/domestic_clients/` | 🔲 待开发 | 每日 |
| 3 | 国际客户 | `pipelines/international_clients/` | 🔲 待开发 | 每日 |
| 4 | 竞争对手 | `pipelines/competitors/` | 🔲 待开发 | 每周 |

## 核心规则

1. **所有表必须 `wdpp_` 前缀** + `create_time`/`update_time` 字段
2. **Python 3.10+**，psycopg2直连，不用ORM
3. **数据库连接**: localhost:5433 / wande_ai / wande / wande_dev_2026
4. **AI调用**: vLLM localhost:8000，模型ID `/model`
5. **只push feature分支** — 创建feature→dev的PR
6. **commit必须包含Issue号** — `feat(管线): 描述 #Issue号`

## 测试规范

### 测试框架

- **测试工具**: pytest + pytest-asyncio
- **测试目录**: `tests/` 按管线类型组织
- **配置文件**: `pytest.ini` + `tests/conftest.py`
- **覆盖率要求**: `--cov=pipelines` 生成覆盖率报告

### 测试文件结构

```
tests/
├── conftest.py              # 全局fixtures
├── domestic_projects/       # 国内项目测试
│   ├── test_match_grade_calculator.py
│   └── test_project_dedup.py
├── domestic_clients/        # 国内客户测试（占位）
├── international_clients/   # 国际客户测试（占位）
└── competitors/             # 竞争对手测试
```

### 测试分类

| 类型 | 说明 | 示例 |
|------|------|------|
| **单元测试** | 测试单个函数/方法 | `test_clean_title()`, `test_rule_based_grade()` |
| **集成测试** | 测试多组件协作 | `test_crawl_all_products()` with mocks |
| **Schema测试** | 验证数据结构和表规范 | `test_required_fields()`, `test_table_name_prefix()` |

### 外部依赖Mock

- **数据库**: `@patch('pipelines.xxx.db.connect')` 或使用conftest.py中的 `mock_db_connection`
- **LLM**: `@patch('pipelines.xxx.llm.call_vllm')` 返回预定义响应
- **浏览器**: `@patch('pipelines.xxx.browser.browse')` 返回模拟页面内容
- **搜索引擎**: `@patch('pipelines.xxx.search.search')` 返回模拟搜索结果

### CI门禁

- **触发条件**: push到dev/feature分支 或 创建PR
- **检查项**: `pytest tests/ -v --cov=pipelines`
- **通过率要求**: 所有测试必须通过
- **覆盖率报告**: 显示在CI输出中

### 测试命名规范

- 文件名：`test_<模块名>.py`
- 类名：`Test<组件名>`
- 函数名：`test_<功能>_<预期>`
- 示例：`test_clean_title_remove_xinhuana()`, `test_rule_based_grade_a_keywords()`

## 开发流程

### 第一阶段：准备

1. **读取Issue**：`gh issue view <N> --repo WnadeyaowuOraganization/wande-play/pipeline --comments`
2. **读取对应管线文档**：根据Issue类别读取 `docs/pipeline-*.md`
3. **创建 task.md**：在 `./issues/issue-<N>/` 下创建任务文件
4. **需求评估**：A(可执行)→继续 / B(需确认)→标pause / C(不可执行)→标blocked

### 第二阶段：开发 + 本地验证

1. 按 task 逐步开发采集脚本
2. **本地测试运行**：确保脚本可以正常执行
3. **验证数据落库**：检查目标表是否有正确的数据写入
4. 持续记录踩坑/发现到 task.md

### 第三阶段：提交收尾

1. **完善 task.md**
2. **commit**：`git add -A && git commit -m "feat(管线类别): 功能描述 #<Issue号>"`
3. **push feature分支**：`git push origin feature-<功能描述>`
4. **创建PR**：创建feature→dev的PR

## 验证门禁

| 检查项 | 验证方式 | 必须状态 |
|--------|---------|---------|
| 脚本可运行 | `python3 pipelines/xxx/script.py` 无报错 | PASS |
| 数据正确落库 | psql查询目标表有数据 | PASS |
| 表名规范 | 所有新表 `wdpp_` 前缀 + `create_time`/`update_time` | PASS |

## 环境信息

| 服务 | 值 |
|------|------|
| 数据库 | localhost:5433 / wande_ai / wande / wande_dev_2026 |
| vLLM | localhost:8000 |
| 模型ID | `/model` |
