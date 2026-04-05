# Claude Code 会员账号 + 外接 Kimi / GLM 大模型集成方案

## 概述

本方案旨在帮助用户在使用 Claude Code（基于 Anthropic 会员订阅）作为主力编程助手的同时，灵活接入国内 Kimi（Moonshot AI）和 GLM（智谱 AI）大模型，实现多模型协作、按需切换、成本优化的开发工作流。

---

## 一、整体架构设计

```
┌──────────────────────────────────────────────────────┐
│                   Claude Code CLI                     │
│              (终端 / VS Code 集成)                     │
├──────────────────────────────────────────────────────┤
│                                                       │
│   ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│   │  Claude 官方  │  │  Kimi API     │  │  GLM API    │ │
│   │  (会员直连)   │  │  (Moonshot)   │  │  (智谱 AI)  │ │
│   └──────┬──────┘  └──────┬───────┘  └──────┬──────┘ │
│          │                │                  │        │
│   Anthropic API     OpenAI 兼容协议    Anthropic 兼容协议│
│                                                       │
└──────────────────────────────────────────────────────┘
```

### 核心思路

- **主力模型**：Claude Opus 4 / Sonnet 4（会员账号直连，用于复杂编程、架构设计、代码审查）[cite:5]
- **辅助模型 1**：Kimi（Moonshot AI），擅长中文理解和长文本处理，API 兼容 OpenAI 协议[cite:6][cite:9]
- **辅助模型 2**：GLM-4.7（智谱 AI），支持 Anthropic 协议兼容接口，可直接在 Claude Code 中切换[cite:10][cite:24]

---

## 二、Claude Code 会员账号配置

### 2.1 订阅方案选择

Claude Code 可通过以下会员方案使用[cite:5]：

| 方案 | 适用场景 | Claude Code 支持 |
|------|----------|-----------------|
| Claude Pro ($20/月) | 个人轻度使用 | ✅ 有用量限制 |
| Claude Max ($100/月) | 重度编程用户 | ✅ 更高用量 |
| Claude Max ($200/月) | 专业开发者 | ✅ 最高用量 |
| API 按量付费 | 灵活计费 | ✅ 按 Token 计费 |

### 2.2 安装 Claude Code

```bash
# NPM 安装（推荐）
npm install -g @anthropic-ai/claude-code

# 或使用原生安装脚本
curl -fsSL https://claude.ai/install.sh | bash

# 验证安装
claude --version
```

### 2.3 登录会员账号

```bash
# 首次运行，按提示登录 Claude.ai 账户
claude

# 或使用 API Key 方式
export ANTHROPIC_API_KEY="your_anthropic_api_key"
claude
```

登录成功后，Claude Code 默认使用 Claude Sonnet 4 模型。可通过 `/model` 命令切换到 Opus 4 等其他模型[cite:16]。

---

## 三、外接 Kimi（Moonshot AI）大模型

### 3.1 获取 Kimi API Key

1. 访问 Kimi 开放平台：https://platform.moonshot.cn
2. 注册账号并完成实名认证
3. 进入「API Key 管理」创建新的 API Key[cite:9][cite:15]

### 3.2 Kimi API 基本信息

| 参数 | 值 |
|------|-----|
| Base URL | `https://api.moonshot.cn/v1` |
| 协议 | OpenAI 兼容协议 |
| 可用模型 | moonshot-v1-8k / moonshot-v1-32k / moonshot-v1-128k |
| 计费 | 按 Token 计费，新用户有免费额度 |

### 3.3 在项目中通过 Python 调用 Kimi

由于 Kimi 使用 OpenAI 兼容协议（非 Anthropic 协议），无法直接作为 Claude Code 的内置模型切换。推荐通过 MCP Server 或项目脚本方式集成[cite:6][cite:12]：

```python
from openai import OpenAI

client = OpenAI(
    api_key="your_kimi_api_key",
    base_url="https://api.moonshot.cn/v1",
)

completion = client.chat.completions.create(
    model="moonshot-v1-128k",  # 支持128k长上下文
    messages=[
        {"role": "system", "content": "你是 Kimi，擅长中文对话和长文本分析。"},
        {"role": "user", "content": "请分析这段代码的性能瓶颈..."}
    ],
    temperature=0.3,
)
print(completion.choices[0].message.content)
```

### 3.4 通过 MCP Server 集成 Kimi 到 Claude Code

在项目根目录创建 `.claude/settings.json`，配置 MCP Server 调用 Kimi：

```json
{
  "mcpServers": {
    "kimi": {
      "command": "python",
      "args": ["./scripts/kimi_mcp_server.py"],
      "env": {
        "KIMI_API_KEY": "your_kimi_api_key"
      }
    }
  }
}
```

创建 `scripts/kimi_mcp_server.py` 脚本，将 Kimi 封装为 MCP 工具，在 Claude Code 对话中通过工具调用 Kimi 进行特定任务（如长文档分析、中文内容生成等）。

---

## 四、外接 GLM（智谱 AI）大模型

### 4.1 获取 GLM API Key

1. 访问智谱开放平台：https://open.bigmodel.cn
2. 注册账号并完成实名认证
3. 订阅 GLM Coding Plan 套餐（推荐）或按量付费[cite:13]
4. 在「API Keys」页面创建新的 API Key

### 4.2 GLM 支持 Anthropic 协议兼容

智谱 AI 提供了 Anthropic 协议兼容接口，这意味着 GLM 可以**直接替换**为 Claude Code 的后端模型[cite:10][cite:24]。

| 参数 | 值 |
|------|-----|
| Anthropic 兼容 Base URL | `https://open.bigmodel.cn/api/anthropic` |
| OpenAI 兼容 Base URL | `https://open.bigmodel.cn/api/paas/v4/` |
| 推荐模型 | GLM-4.7 / GLM-4 |
| 协议 | 同时支持 Anthropic 和 OpenAI 协议 |

### 4.3 方式一：直接在 Claude Code 中切换到 GLM

编辑 `~/.claude/settings.json`[cite:24]：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_zhipu_api_key",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
```

启动 Claude Code 后，输入 `/status` 确认模型状态，输入 `/config` 或 `/model` 切换模型[cite:24]。

### 4.4 方式二：通过 Python 脚本调用 GLM

```python
from openai import OpenAI

client = OpenAI(
    api_key="your_zhipu_api_key",
    base_url="https://open.bigmodel.cn/api/paas/v4/"
)

completion = client.chat.completions.create(
    model="glm-4",
    messages=[
        {"role": "system", "content": "你是人工智能助手，擅长代码分析。"},
        {"role": "user", "content": "请优化以下代码..."}
    ],
    temperature=0.3,
)
print(completion.choices[0].message.content)
```

---

## 五、多模型快速切换方案

### 5.1 环境变量切换脚本

创建 Shell 脚本实现一键切换不同模型后端：

```bash
#!/bin/bash
# switch_model.sh - 多模型切换工具

case "$1" in
  claude)
    echo "切换到 Claude 官方（会员账号）"
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_MODEL
    # 使用会员账号默认配置
    ;;
  glm)
    echo "切换到 智谱 GLM-4.7"
    export ANTHROPIC_AUTH_TOKEN="your_zhipu_api_key"
    export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
    export ANTHROPIC_MODEL="glm-4.7"
    export API_TIMEOUT_MS=3000000
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    ;;
  kimi)
    echo "切换到 Kimi（需通过 MCP/脚本调用）"
    echo "Kimi 使用 OpenAI 协议，请通过项目内 Python 脚本调用"
    echo "Base URL: https://api.moonshot.cn/v1"
    ;;
  *)
    echo "用法: source switch_model.sh [claude|glm|kimi]"
    ;;
esac
```

使用方式：

```bash
# 切换到 Claude 官方
source switch_model.sh claude && claude

# 切换到 GLM
source switch_model.sh glm && claude

# Kimi 通过项目脚本使用
source switch_model.sh kimi
```

### 5.2 使用 CC Switch 工具（推荐）

CC Switch 是一个开源的多模型 API 配置管理工具，支持 Windows / macOS / Linux[cite:24]：

- GitHub 地址：https://github.com/farion1231/cc-switch
- 支持一键切换 Claude Code、Cursor、Gemini CLI 等工具的 API 配置
- 可视化管理多个 API Key 和 Base URL

---

## 六、推荐使用策略

### 6.1 按任务分配模型

| 任务类型 | 推荐模型 | 理由 |
|----------|----------|------|
| 复杂架构设计、代码重构 | Claude Opus 4（会员） | 最强推理能力[cite:5] |
| 日常编码、Bug 修复 | Claude Sonnet 4（会员） | 速度快、性价比高 |
| 中文文档生成、长文本分析 | Kimi 128k | 中文能力强、支持128k上下文[cite:6] |
| 国内合规项目、中文代码注释 | GLM-4.7 | 国产模型、低延迟、支持 Coding Plan[cite:13] |
| 快速原型验证 | GLM-4（按量） | 成本最低 |

### 6.2 成本优化建议

1. **主力使用 Claude 会员**：Max 方案月费固定，不限 Token 数，适合高频编程[cite:1]
2. **GLM Coding Plan 做备用**：智谱提供专门的 Coding Plan 套餐，固定月费，性价比高[cite:13]
3. **Kimi 按量付费**：仅在需要长文本分析或中文特定任务时调用，控制成本[cite:9]
4. **轻量任务用小模型**：设置 `ANTHROPIC_SMALL_FAST_MODEL` 为低成本模型处理简单查询

---

## 七、注意事项

1. **API Key 安全**：所有 API Key 建议存储在环境变量或加密配置文件中，不要硬编码到项目代码
2. **网络环境**：Claude 官方 API 需要海外网络环境；Kimi 和 GLM 均为国内服务，延迟更低
3. **协议兼容性**：GLM 支持 Anthropic 协议可直接替换 Claude Code 后端；Kimi 仅支持 OpenAI 协议，需通过脚本或 MCP Server 间接调用[cite:10][cite:15]
4. **模型能力差异**：不同模型在代码生成、中文理解、长上下文等方面各有优劣，建议根据具体任务选择
5. **会员账号与 API 模式互斥**：在 Claude Code 中，使用会员登录和使用第三方 API Key 是两种不同模式，切换时需要重新配置环境变量[cite:24]
6. **CC Switch 工具**可以大幅简化多平台 API 配置的切换管理[cite:24]

---

## 附录：快速配置清单

### 需要准备的账号和 Key

- [ ] Anthropic Claude 会员账号（Pro / Max）
- [ ] Kimi API Key（https://platform.moonshot.cn）
- [ ] 智谱 AI API Key（https://open.bigmodel.cn）

### 需要安装的工具

- [ ] Node.js 18+
- [ ] Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- [ ] Python 3.10+（用于 Kimi/GLM 脚本调用）
- [ ] OpenAI Python SDK (`pip install openai`)
- [ ] CC Switch（可选，用于多模型配置管理）

