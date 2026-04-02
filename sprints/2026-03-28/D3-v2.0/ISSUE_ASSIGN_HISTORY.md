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

## 会话监控命令

```bash
# 查看所有CC会话
tmux list-sessions

# 查看实时日志
tail -f /home/ubuntu/cc_scheduler/logs/front-85.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-623.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-624.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-626.log
tail -f /home/ubuntu/cc_scheduler/logs/backend-627.log
tail -f /home/ubuntu/cc_scheduler/logs/plugins-1.log
tail -f /home/ubuntu/cc_scheduler/logs/plugins-17.log
```

## 恢复指令

如果CC中断，使用以下命令恢复：
```bash
# 示例：恢复Issue #623
bash /home/ubuntu/projects/.github/scripts/run-cc.sh backend 623 claude-opus-4-6 kimi1
```
