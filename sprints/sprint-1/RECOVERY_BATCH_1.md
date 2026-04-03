# Sprint-1 Issue 恢复计划 (2026-04-02)

## 现状
- 18个 Sprint-1 status:in-progress Issue 无对应 tmux 会话、无分支、无 PR，判定为 CC 中断
- 1个 test-failed Issue (#169) 已回归 Todo 队列
- 可用目录: kimi1-kimi10 全部空闲

## 恢复批次

### 批次1 (P0 backend, 6并发)
| Issue | 模块 | 目录 | 说明 |
|-------|------|------|------|
| 953 | backend | kimi1 | 销售记录聚合引擎 P0 |
| 956 | backend | kimi2 | 一键状态更新API P0 |
| 957 | backend | kimi3 | 老板Nudge API P0 |
| 959 | backend | kimi4 | 记录中心统一数据模型 P0 |
| 960 | backend | kimi5 | 商务周报提交API P0 |
| 171 | backend | kimi6 | 问题发现4张表 P0 |

### 批次2 (P0 frontend + 剩余 P0 backend, ≤6并发)
| Issue | 模块 | 目录 | 说明 |
|-------|------|------|------|
| 1259 | frontend | kimi7 | 项目周报自动汇总页 P1 |
| 1261 | frontend | kimi8 | 项目详情页看板周报催更新 P0 |
| 1262 | frontend | kimi9 | 记录中心前端 P0 |
| 1263 | frontend | kimi10 | 商务周报月报填写页 P0 |
| 962 | backend | 待空闲 | 经销国贸客户维度适配 P1 |

### 批次3 (P1)
| Issue | 模块 | 说明 |
|-------|------|------|
| 954 | backend | 里程碑门控配置 P1 |
| 955 | backend | 智能提醒频率引擎 P1 |
| 958 | backend | 老板周报自动生成引擎 P1 |
| 963 | backend | 增强#1047职责边界调整 P1 |
| 1260 | frontend | 三维驱动规则配置页 P2 |
| 222 | backend | 项目信息变更时增量同步推送 P1 |

### test-failed 优先
| Issue | 模块 | 说明 |
|-------|------|------|
| 169 | backend | 开发效率统计API (已回Todo，下次空闲优先启动) |
