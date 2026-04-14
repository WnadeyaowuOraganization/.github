# G7e PostgreSQL → m7i MySQL 接入方案

> **抢救状态（2026-04-14）**：数据已 100% 保真拉回 m7i。两个库并存：
> - **权威备份**：本地 Docker PG `legacy-pg`（端口 15432，pw=legacy，db=wande_ai）— 449 张表，全部数据 0 误差
> - **MySQL 预迁移**：`wande_ai_legacy`（3306）— 438/442 表，关键表 `wdpp_discovered_projects` 8287/9015 (91.9%)、`wdpp_tender_data` 16869/17120 (98.5%)。JSON/特殊字符兼容剩余尾部可后续按表补齐
>
> **G7e 可随时关机**。Phase 1 接入可优先用 PG 源做权威对齐，MySQL 侧可作为 RuoYi 业务库的初始化基线。

> **目标**：G7e 开机 1 小时内，把停机前的全量历史表+数据抢救到 m7i MySQL 的独立 `wande_ai_legacy` 库，并据此规划业务库 `wande-ai` 的接入路径。
>
> 范围：`wande_ai` 数据库 public schema 下所有表（包括 44+ 个 `wdpp_*` 表和其他历史遗留表）。

---

## 一、抢救阶段（G7e 在线 1 小时内必须完成）

### 1.1 执行步骤

```bash
cd ~/projects/.github/scripts/g7e-migration

# 默认走 VPC 内网直连 G7e (172.31.33.224:5433)，速度最快
bash run-migration.sh

# 若内网探测失败，脚本会自动回退到 SSH 隧道模式
# 公网回退：G7E_HOST=3.211.167.122 VPC_DIRECT=no bash run-migration.sh
```

脚本做的事：
1. **优先 VPC 直连**（m7i 172.31.31.227 ↔ G7e 172.31.33.224，同子网），不开 SSH 隧道
2. 若内网 5433 不可达，自动回退 SSH 隧道把 G7e:5433 映射到 m7i:15433
2. 探活 PG 并打印所有表 + 源端 row count（存档到 `reports/pg_rowcount_*.txt`）
3. 在 m7i MySQL 建 `wande_ai_legacy`（若存在则 DROP 重建）
4. `pgloader migration.load` 执行全量迁移，包含：
   - 所有 public 表结构 + 索引 + 外键
   - PG 类型 → MySQL 类型自动映射（`jsonb→json`, `timestamp→datetime`, `bool→tinyint(1)`, `text[]→json`）
5. 打印 m7i 目标库 row count（`reports/mysql_rowcount_*.txt`）供人工比对

### 1.2 兜底方案

若 pgloader 报错导致数据未进：

```bash
bash fallback-pg-dump.sh
# 产出 dumps/g7e_pg_*.tar.gz（schema.sql + data.sql INSERT 格式）
```

这个 tar 必须落盘到 m7i，G7e 关机后仍可离线分析和分次手工导入。

### 1.3 抢救成功标准

- [ ] `wande_ai_legacy` 中表数量 ≥ G7e public 表数量
- [ ] 关键 3 张表 row count 一致：`wdpp_discovered_projects`、`wdpp_tender_data`、`wdpp_competitor_wins_jobs`
- [ ] `reports/` 下两份快照文件已存档

**达到标准后**立即通知吴耀可以关 G7e。

---

## 二、接入阶段（G7e 关机后可慢慢做）

### 2.1 架构选择

```
┌─────────────────────────────┐       ┌─────────────────────────────┐
│  wande_ai_legacy（只读）     │       │  wande-ai（业务库，当前）    │
│  - 44 张 wdpp_* 原始表       │       │  - Flyway 管理的新表         │
│  - 原始字段名（PG 命名）      │──映射─▶│  - RuoYi 标准 7 列           │
│  - 历史数据快照（抢救自 G7e）│       │  - 符合 Java Entity         │
└─────────────────────────────┘       └─────────────────────────────┘
         ↑                                      ↑
         │                                      │
     （pipeline 不再写这里）              （pipeline 新写入点）
                                                │
                                         ggzy_collector.py
                                         competitor_win_collector.py
                                         score_decay_engine.py
```

**原则**：
- `wande_ai_legacy` 作为**历史参考库**，只读，不再接管道写入
- 所有新增数据一律进 `wande-ai`（业务库）
- 接入时用 SQL `INSERT ... SELECT` 从 legacy 初始化业务库数据

### 2.2 分 Phase 推进（按业务价值排序）

| Phase | Issue | 涉及 legacy 表 | 目标业务表（wande-ai） | 对应功能 |
|-------|-------|---------------|----------------------|---------|
| **Phase 1** | **#3624**（已立项） | `wdpp_discovered_projects` | 同名，重建 schema 符合 RuoYi | 项目矿场主列表、A/B/C 分级 |
| Phase 2 | 待创建 | `wdpp_tender_data` | 同名 | 招投标原始池（discovered_projects 上游） |
| Phase 3 | 待创建 | `wdpp_competitor_wins_jobs`、`wdpp_win_history`、`wdpp_competitor_companies` | 同名 | 竞品中标监控（#2748 复购信号前置） |
| Phase 4 | 待创建 | `wdpp_project_role_*`、`wdpp_owner_monitor_list`、`wdpp_project_owner_match` | 同名 | 甲方/乙方/项目三角匹配 |
| Phase 5 | 待创建 | `wdpp_design_*`、`wdpp_d3_*` | 同名 | D3 设计 AI（独立管线） |
| Phase 6 | 待创建 | `wdpp_win_rate_*`(4张) | 同名 | 赢率预测模型 |
| Phase 7 | 待创建 | 剩余 20+ 辅助表 | 同名 | 按需补 |

### 2.3 单表接入标准流程（每 Phase 复用）

```
  1) legacy 表字段 Review
     └─ 列出所有字段、类型、空值率、唯一索引
          ↓
  2) 设计业务表 schema（wande-ai）
     └─ 在原字段基础上补：tenant_id, create_dept, create_by, update_by,
                            create_time, update_time, del_flag
     └─ 对外字段命名若 Java VO 已有习惯，用业务表列名去 match
          ↓
  3) 写 Flyway V{YYYYMMDD}{NNN}__create_xxx.sql
          ↓
  4) 写字段映射 SQL：
     INSERT INTO wande-ai.xxx (业务字段) 
     SELECT legacy字段 FROM wande_ai_legacy.xxx;
          ↓
  5) Pipeline 改写入点：shared/db.py 已指 wande-ai，
                      核对每个 collector 的 INSERT SQL
          ↓
  6) Java Entity/Mapper/Service 对齐新表
          ↓
  7) 端到端验证：前端页面 → 后端 API → 真数据
          ↓
  8) 关闭对应 Phase Issue
```

### 2.4 Phase 1 交付（今日目标）

Issue #3624 的具体交付物：

- [ ] `V20260414001__create_wdpp_discovered_projects.sql` — Flyway 脚本
- [ ] `INSERT INTO wande-ai.wdpp_discovered_projects SELECT ... FROM wande_ai_legacy.wdpp_discovered_projects` — 数据初始化
- [ ] `ProjectMineServiceImpl` 去 mock，改真查询
- [ ] 字段映射：
  - `title` → `project_name`（VO: projectName）
  - `score_total` → `ai_evaluation_score`（VO: aiEvaluationScore）
  - `grade` → `match_grade`
  - `stage_category` → `mine_category`
  - `status` → `mine_status`
- [ ] m7i 装 pymysql：`pip3 install pymysql`
- [ ] 调用一次 `ggzy_collector.py` 验证新数据能写进去

---

## 三、风险与预案

| 风险 | 预案 |
|------|------|
| G7e 启动后 IP 变了 | 登录 AWS 控制台拿到新 IP，`G7E_HOST=<新IP> bash run-migration.sh` |
| PG 5433 未启动 | G7e 上 `systemctl start postgresql@13-main`（或对应版本） |
| SSH key 不对 | 换 `G7E_SSH_KEY` 变量，或用控制台 Session Manager 先拿 key |
| pgloader 对 `TEXT[]` 转换失败 | 跑 fallback-pg-dump.sh，离线手工处理 |
| pgloader 内存 OOM | 减小 `workers`、`batch rows` 参数 |
| row count 不一致 | 对 legacy 特定大表单独 pg_dump → 手工导入 |
| G7e 时间不够 | 优先抢：`wdpp_discovered_projects` / `wdpp_tender_data` / `wdpp_competitor_wins_jobs`（pgloader 支持单表模式：`LOAD FROM postgresql://... INTO mysql://... WITH including only table names matching 'wdpp_discovered_projects'`） |

---

## 四、时间节奏建议

```
T+0      G7e 开机通知发出
T+5min   确认 SSH/PG 可达，启动 run-migration.sh
T+30min  pgloader 完成（24k 行主表 + 其他小表通常 10 分钟内结束）
T+45min  人工比对 rowcount，确认关键表无差异
T+50min  通知吴耀可以关 G7e
T+1h     G7e 关机，数据已在 m7i
T+2h     Phase 1 Issue #3624 交给 kimi1 启动（基于 legacy 数据建 wande-ai 表）
```

---

## 五、文件索引

| 文件 | 作用 |
|------|------|
| `scripts/g7e-migration/run-migration.sh` | 主脚本，一键迁移 |
| `scripts/g7e-migration/migration.load` | pgloader 配置（类型映射） |
| `scripts/g7e-migration/fallback-pg-dump.sh` | 备用 pg_dump 导出 |
| `scripts/g7e-migration/reports/` | 每次运行的行数快照+完整日志 |
| `scripts/g7e-migration/dumps/` | pg_dump tar.gz 备份 |
| `docs/agent-docs/migration/g7e-to-m7i-integration-plan.md` | 本方案 |
