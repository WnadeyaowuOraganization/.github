# 明道云数据 → D90 四入口架构迁移指导文档

> **版本**: v1.0  
> **日期**: 2026-04-21  
> **作者**: Perplexity（基于 m7i 真实数据表结构扫描）  
> **适用范围**: Issue #4014 / #4015 / #4016（Sprint-3 启动时排程执行）  
> **前置依赖**: `.github/docs/mdy-migration/migration-plan.md` + `mingdao_s3_data_mapping.md`

---

## 一、数据现状总览（m7i 真实扫描）

### 1.1 明道云源数据（mongodb-mdy + mysql-mdy）

| 集合/表 | wsid | 业务含义 | 行数 | 迁入目标 | 迁移优先级 |
|---------|------|----------|------|----------|------------|
| mdwsrows.ws6886d61c... | sjcj | **线索** | 8,895 | `crm_leads`（#4014 新建） | 🔥 P0 |
| mdwsrows.ws68a320d0... | hlwxs 主 | **互联网线索** | 65,869 | `wdpp_project_mine` | 🔥 P0 |
| mdwsrows.ws68b2603b...9b9c | hlwxs 副本 | 互联网线索副本 | 1,063 | `wdpp_project_mine`（合并） | P1 |
| mdwsrows.ws6886d6bc... | xsfx 主 | **商机** | 5,313 | `crm_opportunity` | 🔥 P0 |
| mdwsrows.ws68afed1c... | xsfx 副本 | 商机副本 | 1,042 | `crm_opportunity`（合并去重） | P1 |
| mdwsrows.ws6886d6d2... | kehu | **客户** | 29,366 | `crm_customer` | P1（增量补齐） |
| mdwsrows.ws68bbd2be... | hlwxs 操作日志 | 互联网线索操作日志 | 48,953 | 归档（可不迁） | P3 |
| mdwsrows.ws6886d7a7... | gjjl | **销售记录** | 651,070 | `crm_activity_log` | P1（分批） |
| MDProject.Account | — | 用户 | 124 | `sys_user` | ✅ 已完成 |
| MDProject.Project_Department | — | 部门 | 65 | `sys_dept` | ✅ 已完成 |

### 1.2 新平台 wande-ai 现状（已迁入情况）

| 目标表 | 当前行数 | 期望最终行数 | 差距 | 完成度 |
|--------|----------|--------------|------|--------|
| `sys_user` | 126 | 124+ | ✅ | 100% |
| `sys_dept` | 76 | 65+ | ✅ | 100% |
| `crm_customer` | 24,838 | 29,366 | +4,528 | 85% |
| `wdpp_project_mine` | 10,194 | 66,932 | +56,738 | 15% |
| `crm_opportunity` | 0 | 5,313+去重 | 全量 | 0% |
| `crm_activity_log` | 216 | 651,070 | 全量 | 0.03% |
| **`crm_leads`** | **表不存在** | 8,895 | 建表+全量 | — |

### 1.3 辅助表现状

| 辅助表 | 当前行数 | 用途 |
|--------|----------|------|
| `wdpp_project_mine_assign_log` | 8,639 | 指派日志（已有部分数据） |
| `wdpp_project_mine_source` | 0 | 来源字典（待迁） |
| `wdpp_project_mine_edit_log` | 0 | 编辑日志 |
| `wdpp_project_mine_escalation_log` | 0 | 升级日志 |

---

## 二、核心架构映射规则

### 2.1 D90 四入口业务类型判定（business_type / biz_line）

新平台将销售业务按"入口"划分三类，需从明道云字段推断：

| business_type | 新平台值 | 明道云判定规则（优先级从上到下） |
|---------------|----------|------------------------------------|
| **direct（直销）** | `biz_line=1` | ① `商机.业务类型` ∈ (直销类商机 / 【部门级】直销类 / 直销)<br>② `商机.信息来源` ∈ (矿场 / 互联网线索 / 网络搜集 / 招标网)<br>③ `客户.业务类型` = "直销" |
| **dealer（经销）** | `biz_line=2` | ① `商机.业务类型` ∈ (经销类商机 / 经销产品采购类 / 经销)<br>② `商机.商机类型` = "WD"<br>③ `客户.业务类型` ∈ (经销 / 代理商) |
| **international（国贸）** | `biz_line=3` | ① `商机.商机类型` ∈ (TYSZ / TYDC / TYWL / TYJY)<br>② `商机.信息来源` ∈ (LinkedIn / 展会 / 海外询盘)<br>③ `客户.业务类型` ∈ (国贸 / 国际贸易 / 客户_体游) |

**兜底规则**：若三项规则均无匹配 → 默认 `direct`，并在 `remark` 字段标注"迁移自明道云，业务类型待人工核对"。

### 2.2 商机阶段映射（50个历史值 → 5个新值）

| 明道云 stage | 新平台 stage | 说明 |
|--------------|--------------|------|
| 新建商机 / 立项 / 初步接触 | `NEW` | 初始阶段 |
| 商务谈判 / 需求确认 / 方案沟通 | `NEGOTIATION` | 谈判阶段 |
| 招投标 / 投标中 / 围标 | `BIDDING` | 招投标阶段 |
| 签订合同 / 合同签署 | `CONTRACTED` | 已签约 |
| 回款阶段 / 验收阶段 / 结束 / 完成 | `CLOSED_WON` | 成交 |
| 输单 / 无效 / 放弃 | `CLOSED_LOST` | 丢单 |

**技术实现**：在 ETL 脚本中维护字典 `STAGE_MAP = {...}`，所有 `isdel=true` 的历史 opt 也要加进字典（参见明道云 xsfx 的 43 个 isdel 值）。

### 2.3 来源字段映射（48个枚举合并）

明道云 `信息来源` 有 48 个值，需合并为新平台 `source` 枚举。核心映射：

| 新平台 source | 合并明道云来源 |
|---------------|----------------|
| `internet` | 互联网线索 / 网络搜集 / 网络搜索 / 招标网 |
| `referral` | 客户推荐 / 转介绍 |
| `exhibition` | 展会 / 广交会 |
| `outreach` | 陌生拜访 / 电话拜访 / 外展 |
| `dealer` | 经销商推荐 |
| `inbound` | 主动咨询 / 客户来电 / 官网留言 |
| `linkedin` | LinkedIn / 领英 |
| `other` | 其他（兜底） |

---

## 三、分 Issue 迁移指导

## 3.1 #4014 — 线索池 + 评分引擎（P0·size/L）

### 源数据
- MongoDB: `mongodb-mdy.mdwsrows.ws6886d61c074a71b93636d2da`
- 行数: **8,895**
- 业务实体: 明道云"线索(sjcj)" — 独立于互联网线索和客户之外的销售线索池

### 目标
- 新建 `crm_leads` 表（见下方 DDL）
- 全量迁移 8,895 条线索 + 评分种子数据

### `crm_leads` 建议 DDL（Flyway 脚本 `V20260501_01__create_crm_leads.sql`）

```sql
CREATE TABLE crm_leads (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  lead_name           VARCHAR(200) NOT NULL COMMENT '线索名称（对应明道云"线索名称"）',
  lead_code           VARCHAR(50) COMMENT '线索编号（对应"线索编号"）',
  contact_name        VARCHAR(100) COMMENT '联系人姓名',
  contact_phone       VARCHAR(50) COMMENT '联系人电话',
  contact_status      VARCHAR(30) COMMENT '联系人状态',
  customer_name       VARCHAR(200) COMMENT '客户名称（未转客户时保留文本）',
  customer_id         BIGINT COMMENT '转化后的客户ID',
  intent_level        VARCHAR(20) COMMENT '客户意向（高/中/低）',
  lead_type           VARCHAR(50) COMMENT '线索类型',
  lead_category       VARCHAR(50) COMMENT '线索分类',
  source              VARCHAR(50) COMMENT '线索来源（统一枚举）',
  business_type       TINYINT DEFAULT 1 COMMENT '业务入口 1=direct 2=dealer 3=international',
  industry            VARCHAR(100) COMMENT '项目所属行业',
  region              VARCHAR(200) COMMENT '地区',
  project_address     VARCHAR(500) COMMENT '项目地址',
  estimated_amount    DECIMAL(18,2) COMMENT '预估成单金额',
  owner_user_id       BIGINT COMMENT '负责人',
  owner_dept_id       BIGINT COMMENT '领取部门',
  process_status      VARCHAR(30) COMMENT '流程状态',
  score               INT DEFAULT 0 COMMENT '评分（0-100）',
  score_detail        JSON COMMENT '评分明细（意向+预算+时效等维度）',
  related_opp_id      BIGINT COMMENT '关联商机ID',
  last_followup_time  DATETIME COMMENT '最近一次跟进',
  no_followup_days    INT DEFAULT 0 COMMENT '未跟进天数',
  attachment          JSON COMMENT '附件',
  mdy_unique_id       VARCHAR(50) COMMENT '明道云唯一性ID（去重用）',
  mdy_row_id          VARCHAR(50) COMMENT '明道云 rowid',
  create_time         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  create_by           BIGINT,
  update_by           BIGINT,
  tenant_id           VARCHAR(20) DEFAULT '000000',
  del_flag            CHAR(1) DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY uk_mdy_unique (mdy_unique_id),
  KEY idx_owner (owner_user_id),
  KEY idx_source (source),
  KEY idx_score (score),
  KEY idx_business_type (business_type)
) ENGINE=InnoDB COMMENT='CRM 线索池（D90 四入口架构）';
```

### 字段映射表（明道云 sjcj → crm_leads）

| 明道云字段 | controlId | 新平台字段 | 转换规则 |
|------------|-----------|------------|----------|
| 线索名称 | — | `lead_name` | 直接映射 |
| 线索编号 | — | `lead_code` | 直接映射 |
| 唯一性ID | 689aaa04074a71b9363719a9 | `mdy_unique_id` | 去重 key |
| 联系人姓名 | — | `contact_name` | 直接映射 |
| 联系人电话 | — | `contact_phone` | 直接映射 |
| 联系人状态 | — | `contact_status` | 直接映射 |
| 客户名称 | — | `customer_name` | 文本保留；另查 `crm_customer` 匹配 `customer_id` |
| 客户意向 | type28 | `intent_level` | opts 解码（高/中/低） |
| 线索类型 | — | `lead_type` | 直接映射 |
| 线索分类 | — | `lead_category` | 直接映射 |
| 线索来源 | — | `source` | 按 §2.3 枚举合并 |
| 项目所属行业 | — | `industry` | 直接映射 |
| 地区 | — | `region` | 直接映射 |
| 项目地址 | — | `project_address` | 直接映射 |
| 项目预估成单金额 | — | `estimated_amount` | 直接映射 |
| 负责人 | type26 | `owner_user_id` | MDProject.Account → sys_user 映射（已完成） |
| 线索领取部门 | type27 | `owner_dept_id` | Project_Department → sys_dept 映射 |
| 流程状态 | — | `process_status` | 直接映射 |
| 关联商机 | — | `related_opp_id` | 商机迁完后二次回填 |
| 最近一次跟进日期 | — | `last_followup_time` | 直接映射 |
| 未跟进天数 | — | `no_followup_days` | 直接映射 |
| 附件 | — | `attachment` | JSON 格式保留 |
| 创建日期 | — | `create_time` | 直接映射 |

### 评分引擎种子数据策略

CC 开发评分引擎时，可基于以下明道云字段作为初始评分特征：

```python
# 评分维度（满分 100）
score_demand_match   = 客户意向 → 高(40) / 中(25) / 低(10)
score_budget         = 预估成单金额 → >=100万(25) / 50-100万(15) / <50万(5)
score_timeliness     = 未跟进天数 → <=7天(20) / 8-30天(10) / >30天(0) / >90天=-10（降级信号）
score_source_quality = 来源 → 客户推荐(15) / 展会(12) / 互联网(5) / 其他(3)
```

将以上公式写入 `lead_scoring_service.py`，历史数据入库时批量计算并填充 `score_detail`。

### ETL 脚本位置
- `.github/docs/mdy-migration/scripts/10_export_leads.py`（待 CC 实现）
- 入口命令：`python3 10_export_leads.py --dry-run` / `--execute`

### 验收断言
- [ ] `crm_leads` 表已创建，字段与 DDL 一致
- [ ] `SELECT COUNT(*) FROM crm_leads` = 8,895（或 ≥ 8,800 扣除脏数据）
- [ ] `mdy_unique_id` 唯一，无重复
- [ ] `source` 枚举值 ∈ 合并后的 8 个值，无原文泄漏
- [ ] 评分分布合理（非全为 0）
- [ ] 抽样 10 条明道云线索，新平台记录字段完全对齐

---

## 3.2 #4015 — 矿场 Readiness 整改（P1·rework）

### 源数据（共 10 份互联网线索变体需合并）
- 主表: `ws68a320d0...` (65,869 行)
- 副本: `ws68b2603b...9b9c` (1,063 行)
- 其他小副本 × 8

### 目标
- 在已迁入的 10,194 行基础上 **补齐剩余 ~56,738 行**
- 新增 2 个核心字段
- 回填 `source_type` 和 `readiness_json`

### 现状评估
新平台 `wdpp_project_mine` 表已有 **62 个字段**，核心字段齐全（见扫描结果）：
- ✅ 已有：`project_name` / `publish_time` / `budget_amount` / `client_name` / `source_url` 等
- ✅ 已有评分字段：`ai_evaluation_score` / 6个子评分 / `score_win_probability`
- ✅ 已有状态字段：`mine_status` / `evaluation_status` / `verification_status`
- ❌ **缺失**：`transit_readiness_json`（转化就绪度评估）
- ❌ **缺失**：`converted_opportunity_id`（转化商机反向链接）

### 需新增的字段（Flyway `V20260501_02__alter_project_mine_readiness.sql`）

```sql
ALTER TABLE wdpp_project_mine
  ADD COLUMN transit_readiness_json JSON COMMENT '转化商机就绪度评估（预算/联系人/决策链/时效等维度）',
  ADD COLUMN converted_opportunity_id BIGINT COMMENT '已转化的商机ID（反向链接）',
  ADD KEY idx_converted_opp (converted_opportunity_id);
```

### 字段映射表（明道云 hlwxs → wdpp_project_mine）

| 明道云字段 | 新平台字段 | 转换规则 |
|------------|------------|----------|
| 线索标题 | `project_name` | 直接映射 |
| 招标信息 | `building_content` | type52 数组拼接 |
| 项目ID | `project_code` | 直接映射 |
| 线索状态 | `mine_status` | 正常→active / 垃圾箱→trash / 加急→urgent / 已转入→converted |
| 数据来源 | `source_name` | 直接映射（如"中国政府采购网"） |
| — | `discovery_source` | 固定值 `mingdao_hlwxs` |
| 发布时间 | `publish_time` | 直接映射 |
| 预算金额 | `budget_amount` | 直接映射 |
| 中标金额 | `investment_text` | 文本保留 |
| 关键词 | `discovery_keyword` | 直接映射 |
| 指派负责人 | `create_by` | sys_user 映射 |
| 是否加急 | `mine_status` | 为真时置 urgent |
| 描述 | `trust_summary` | 直接映射 |
| 附件 | `battle_info` | JSON 形式保存 |
| 正文解析 | `building_content` | 合并 |
| 招标网址 | `source_url` | 唯一键，去重依据 |
| 甲方名称 | `client_name` | 直接映射 |
| 甲方联系人/联系方式 | `business_info` | JSON: `{"客户联系人": {...}}` |
| 代理方联系人/联系方式 | `business_info` | JSON: `{"代理方联系人": {...}}` |

### 合并去重规则
- **主键**: `source_url`（已 UNIQUE）
- **冲突策略**: 以 utime 最新为准，合并 `business_info` 字段（联系人信息合并而非覆盖）
- **10份副本合并顺序**: 主表 → 副本按 utime 降序追加

### Readiness 种子评分生成规则

对所有 66,932 行计算 `transit_readiness_json` 初始值：

```python
readiness = {
  "budget_ready": bool(budget_amount and budget_amount > 0),
  "contact_ready": bool(甲方联系人.电话 or 甲方联系人.邮箱),
  "time_window": compute_days_until(bid_deadline),  # 投标截止天数
  "client_quality": 高(客户是政府/国企) / 中(企业) / 低(未知),
  "score": 0-100,   # 综合分
  "computed_at": now
}
```

### 验收断言
- [ ] `wdpp_project_mine` 总行数 ≥ 66,900
- [ ] 新增 2 个字段生效
- [ ] 10 份明道云副本全部合并，`source_url` 唯一
- [ ] `transit_readiness_json` 非空字段占比 ≥ 95%
- [ ] `business_info` 包含甲方+代理方两组联系人
- [ ] 抽样 10 条源数据，核对新平台记录无字段遗漏

### 注意事项
1. ⚠️ **65,866 条记录 `ownerid=user-undefined`** → 迁移时归给"系统迁移"虚拟用户（建议在 sys_user 建 `id=-1` 占位账号）
2. ⚠️ 已有 8,639 条 `wdpp_project_mine_assign_log` 需与新迁入数据关联
3. ⚠️ 字段 `name=undefined` 问题：wscontrols 真实字段名在 `name` 字段而非 `cname`

---

## 3.3 #4016 — 架构蓝图 + 数据字典（P2·size/S）

### 交付物清单
1. `architecture-blueprint.md` — 四入口架构蓝图
2. `data-dictionary.md` — 字段映射+枚举字典
3. `migration-checklist.md` — Sprint-3 迁移任务 checklist

### 数据字典必含章节

#### ① business_type 三类映射规则（参见 §2.1）

#### ② 商机阶段 5 值映射表（参见 §2.2）

#### ③ source 字段枚举合并表（48 → 8，参见 §2.3）

#### ④ 客户业务类型 9 项
| 明道云值 | 新平台 customer_type |
|---------|----------------------|
| 经销 | 2 |
| 直销 | 1 |
| 合作 | 5 |
| 战略合作 | 6 |
| 合作投标 | 7 |
| 代理商 | 2 |
| 客户_体游 | 3 |
| 其他 | 9 |

#### ⑤ 客户等级映射（customer_grade）
- A级 → 'A'
- B级 → 'B'
- C级 → 'C'
- D级 → 'D'

#### ⑥ ID 映射查找表（三层）
- **用户映射**: MDProject.Account.accountid → sys_user.id（建立 `mdy_account_map` 临时表辅助）
- **部门映射**: Project_Department._id → sys_dept.dept_id
- **客户映射**: 明道云客户 rowid → crm_customer.id

#### ⑦ 明道云 opts 字段解码规则
opts 是 BSON 结构 `{k: UUID, v: 显示值, idx, isdel, color}`，迁移时取 `v` 作为枚举字符串，同时保留历史 `isdel=true` 的映射避免数据丢失。

### 架构蓝图核心图（建议用 Mermaid）

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│  直销入口     │  经销入口     │  国贸入口     │  代理入口     │
│ (矿场驱动)    │ (询盘驱动)    │ (询盘驱动)    │ (客户管理)    │
├──────────────┴──────────────┴──────────────┴──────────────┤
│           crm_leads（线索池 + 评分引擎）                     │
├───────────────────────────────────────────────────────────┤
│         crm_opportunity（商机，business_type 区分）          │
├───────────────────────────────────────────────────────────┤
│    crm_customer ─ crm_contract ─ crm_payment_record         │
├───────────────────────────────────────────────────────────┤
│  wdpp_project_mine（矿场）→ 转 opportunity → biz_line=1      │
└───────────────────────────────────────────────────────────┘
```

---

## 四、执行顺序与排程建议（Sprint-3）

| 周次 | 任务 | 责任 |
|------|------|------|
| W1 Day1-2 | #4014 建表 DDL + ETL 脚本骨架 | CC |
| W1 Day3-4 | #4015 新增 2 字段 + 补迁 ETL | CC |
| W1 Day5 | #4014 线索全量迁入 + 评分种子数据 | CC |
| W2 Day1-2 | #4015 10份副本合并 + readiness 回填 | CC |
| W2 Day3 | 商机迁入（5,313 + 1,042 去重） | CC（blocked-by #4014） |
| W2 Day4 | 客户补齐 4,528 行 | CC |
| W2 Day5 | #4016 数据字典 + 架构蓝图交付 | Perplexity |
| W3 | 销售记录分批迁入 + 验收 | CC |

---

## 五、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 负责人 user-undefined | 65k+ 记录无归属 | 建 `id=-1` 虚拟用户"系统迁移"，后续人工认领 |
| 商机副本重复 | 1,042 行与 5,313 主表可能冲突 | 按 `唯一性ID` 去重，utime 最新者胜出 |
| 客户名称模糊匹配 | 线索/商机关联客户时同名不同司 | 先用精确匹配，失败时保留 `customer_name` 文本 |
| 业务类型误判 | 迁后 direct/dealer/international 分错入口 | 兜底 `direct` + `remark` 标注，给吴耀提供"待人工核对"清单 |
| 迁移回滚 | ETL 失败污染新表 | 所有 ETL 开启 `--dry-run` 模式先验证，正式运行前 `mysqldump` 快照 |

---

## 六、验收总清单（三个 Issue 汇总）

- [ ] `crm_leads` 表建成，8,895 行迁入，`mdy_unique_id` 唯一
- [ ] `wdpp_project_mine` 行数 ≥ 66,900，新增 2 字段生效
- [ ] `crm_opportunity` 行数 ≥ 6,000（去重后），`business_type` 三类分布合理
- [ ] `crm_customer` 行数 ≥ 29,300
- [ ] `crm_activity_log` 行数 ≥ 650,000（分批迁）
- [ ] 评分引擎对 8,895 条线索计算非空评分
- [ ] `transit_readiness_json` 在 66k 条矿场数据上填充完成
- [ ] 数据字典 `data-dictionary.md` 交付
- [ ] 架构蓝图 `architecture-blueprint.md` 交付
- [ ] Sprint-3 Day15 前全部数据迁移完成，E2E 回归测试通过

---

## 附录 A：关键 m7i 命令速查

```bash
# SSH runner
python3 /tmp/m7i_ssh.py "<command>"

# 查 MongoDB 源行数
docker exec mongodb-mdy mongo mdproject --quiet --eval 'db.mdwsrows.count({wsid:"ws<id>"})'

# 查新平台 MySQL 行数
docker exec mysql-dev mysql -uroot -ppassword -N -e \
  'SELECT COUNT(*) FROM `wande-ai`.crm_leads;'

# 表结构对比
docker exec mysql-dev mysql -uroot -ppassword -e \
  'DESC `wande-ai`.wdpp_project_mine;'
```

## 附录 B：相关文件索引

- `.github/docs/mdy-migration/migration-plan.md` — 总体方案（已有，9.6KB）
- `.github/docs/mdy-migration/mingdao_s3_data_mapping.md` — 字段映射详表（已有，891KB）
- `.github/docs/mdy-migration/mingdao_s3_data_mapping.json` — 结构化字段映射（已有，3.9MB）
- `.github/docs/mdy-migration/scripts/` — ETL 脚本目录（待补充 10_export_leads.py）
- `.github/docs/mdy-migration/m7i-deploy-all.sh` — m7i 部署脚本

---

**文档状态**: ✅ Ready for Sprint-3
