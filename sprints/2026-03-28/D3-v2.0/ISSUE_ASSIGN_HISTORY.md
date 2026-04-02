# D3-v2.0 Issue 指派记录

## 2026-04-02 指派记录

| Issue # | 仓库 | 目录 | 优先级 | 描述 | 状态 |
|---------|------|------|--------|------|------|
| #85 | front | front-kimi1 | P1/test-failed | 合同管理跨模块打通前端 | In Progress |
| #623 | backend | backend-kimi1 | P0 | 模具库数据化 | In Progress |
| #624 | backend | backend-kimi2 | P0 | 模具选型引擎 | In Progress |
| #626 | backend | backend-kimi3 | P0 | 模具接口标准化 | In Progress |
| #627 | backend | backend-kimi4 | P0 | 钢架自动选型规则 | In Progress |
| #1 | plugins | plugins-glm1 | P0 | G7e D3云端引擎代码迁入 | In Progress |
| #17 | plugins | plugins-glm2 | P0 | 2D板材排料电池包 | In Progress |

## 2026-04-02 第二批指派（10:36-10:37）

| Issue # | 仓库 | 目录 | 优先级 | 描述 | 状态 |
|---------|------|------|--------|------|------|
| #56 | backend | backend-kimi1 | P1 | 国际贸易矿场-国际客户CRUD API | In Progress |
| #70 | backend | backend-kimi2 | P1 | 合同管理AI自动填充 | In Progress |
| #43 | front | front-kimi2 | P1 | 合同管理跨模块打通页面 | **已完成** |
| #2 | plugins | plugins-glm3 | P1 | DfMA制造可行性自动检测引擎 | In Progress |
| #3 | plugins | plugins-glm4 | P1 | 几何审计脚本 | **已完成** |

## 2026-04-02 第三批指派（10:50-10:51）

| Issue # | 仓库 | 目录 | 优先级 | 描述 | 状态 |
|---------|------|------|--------|------|------|
| #858 | backend | backend-kimi3 | **P0/E2E阻塞** | wdpp_tender_data.has_embedding类型不匹配 | In Progress |
| #632 | backend | backend-kimi4 | **P0** | 发货防错系统 | In Progress |
| #4 | plugins | plugins-glm1 | P1 | 钢管下料优化（1D Nesting）| In Progress |

**当前运行中**: 10个CC  
**已完成**: 3个 (#1, #3, #43)  
**已创建PR**: 1个 (PR #27 - Issue #1, 有冲突)

## 会话监控命令

```bash
# 查看所有CC会话
tmux list-sessions | grep "cc-"

# 查看实时日志（10个运行中）
tail -f /home/ubuntu/cc_scheduler/logs/front-85.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-56.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-623.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-624.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-627.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-70.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-858.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-632.log
tail -f /home/ubuntu/cc_scheduler/logs/plugins-2.log
tail -f /home/ubuntu/cc_scheduler/logs/plugins-4.log
```

## 恢复指令

如果CC中断，使用以下命令恢复：
```bash
# 示例：恢复Issue #623
bash /home/ubuntu/projects/.github/scripts/run-cc.sh backend 623 claude-opus-4-6 kimi1
```
