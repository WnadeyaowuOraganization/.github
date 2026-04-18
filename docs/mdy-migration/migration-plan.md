# 明道云数据迁移方案 → 万德AI新平台

> 生成时间: 2026-04-18
> 数据来源: S3 `s3://wande-nas-sync/万德明道云数据0316/`
> 参考文档: `mingdao_s3_data_mapping.md` (字段级映射)

---

## 一、数据源现状

### 已恢复的数据服务

| 服务 | 容器 | 端口 | 数据量 | 说明 |
|------|------|------|--------|------|
| MongoDB 4.4 | `mongodb-mdy` | 27017 | 2.90 GB / 39 库 / 12,914,210 文档 | `--ulimit nofile=65536` |
| MySQL 5.7 | `mysql-mdy` | 3307 | 8.1 MB / 5 库 / 62 表 | `--skip-grant-tables` |

### 核心数据量

| 数据 | 数量 | 说明 |
|------|------|------|
| 工作表定义 (worksheet) | 1,416 张 | 含活跃 1,105 + 已删 311 |
| 字段定义 (wscontrols) | 34,494 个 | 每表平均 24 字段 |
| 业务数据行 (mdwsrows) | 915,214 行 / 315 集合 | **P0 必须迁移** |
| 审批流实例 (wf_instance) | 2,809,948 条 | P1 按需迁移 |
| 应用 (apk) | 23 个 | 应用=工作表分组 |
| 用户 (MDProject.Account) | 124 人 | 需映射到新平台 sys_user |
| 部门 (Project_Department) | 65 个 | 需映射到新平台 sys_dept |

---

## 二、迁移优先级

### P0 必须迁移（影响周一交付）

| 业务域 | 明道云工作表 | 新平台目标表 | 预计行数 | 迁移方式 |
|--------|------------|-------------|---------|---------|
| **CRM/商机** | 商机 (xsfx) ×7份 | `crm_opportunity` | ~数千 | ETL脚本 |
| **CRM/客户** | 客户 (wd_kh) | `crm_customer` | ~数千 | ETL脚本 |
| **CRM/线索** | 线索 | `crm_lead` | ~数千 | ETL脚本 |
| **CRM/跟进记录** | 跟进记录 (gjjl) | `crm_activity_log` | ~万级 | ETL脚本 |
| **CRM/合同** | 合同/订单 | `crm_contract` | ~数百 | ETL脚本 |
| **用户/部门** | MDProject.Account + Department | `sys_user` + `sys_dept` | 124+65 | SQL直插 |

### P1 重要但不阻塞交付

| 业务域 | 明道云工作表 | 新平台目标表 | 说明 |
|--------|------------|-------------|------|
| 审批流历史 | mdworkflow.wf_instance | `wf_*` | 280万条，可后补 |
| 附件元数据 | mdservicedata | `sys_oss` | 文件URL映射 |
| 报价表 | 报价表 (bjb) | `crm_quotation` | 配对商机 |
| 投标申请 | 标书申请 | `crm_bid_application` | 配对商机 |

### P2 可选/延后

| 数据 | 说明 |
|------|------|
| 变更日志 (mdworksheetlog) | 66万条，审计用，可不迁 |
| 站内信 (mdinbox) | 12万条通知，新平台重建 |
| 集成配置 (mdintegration) | 旧系统对接，新平台不需要 |

### P3 不迁

| 数据 | 原因 |
|------|------|
| mdmap (映射关系) | 明道云内部用 |
| mdcalendar | 新平台重建日历 |
| mdpost | 旧动态帖子 |

---

## 三、迁移技术路线

### 3.1 核心难点：明道云动态 Schema

明道云使用 **EAV 模型**（Entity-Attribute-Value）：
- 每张"工作表"对应 `mdwsrows` 中一个 MongoDB 集合 `ws{worksheetId}`
- 行数据的 key 是 `controlId`（如 `6881c49d8a4d1323c51be9d7`），不是字段名
- 需要通过 `mdworksheet.wscontrols` 做 controlId → 字段名映射

```
mdwsrows.ws6886d6bc074a71b93636d2e5 (商机数据)
  └─ { "6881c49d...": "万德XX项目", "68930662...": "2025-03-01", ... }
              ↓ 通过 wscontrols 映射
  └─ { "商机名称": "万德XX项目", "发布日期": "2025-03-01", ... }
```

### 3.2 迁移脚本架构

```
scripts/mdy-migration/
├── 00_build_field_map.py       # 从 wscontrols 构建 controlId→字段名 映射表
├── 01_export_users.py          # MySQL MDProject.Account → sys_user INSERT
├── 02_export_departments.py    # MySQL MDProject.Department → sys_dept INSERT
├── 10_export_customers.py      # 客户工作表 → crm_customer INSERT
├── 11_export_opportunities.py  # 商机工作表(7份合并去重) → crm_opportunity INSERT
├── 12_export_leads.py          # 线索 → crm_lead INSERT
├── 13_export_activities.py     # 跟进记录 → crm_activity_log INSERT
├── 14_export_contracts.py      # 合同 → crm_contract INSERT
├── 20_export_workflows.py      # 审批流历史（P1，可后补）
└── common.py                   # MongoDB/MySQL连接 + 字段映射工具
```

### 3.3 每个脚本的工作流

```python
# 伪代码
1. 连接 MongoDB (localhost:27017)
2. 从 mdworksheet.wscontrols 查出目标表的字段映射
   { controlId → { name: "商机名称", type: 2 } }
3. 从 mdwsrows.ws{id} 读取所有行
4. 对每行：
   a. 用字段映射把 controlId key 替换为字段名
   b. 类型转换（明道云 type 2=文本, 6=数值, 8=日期, 9=地区, 11=选项...）
   c. 用户ID映射（accountId → sys_user.user_id）
   d. 关联记录解引用
5. 生成 INSERT SQL 或直连新平台 MySQL 写入
```

### 3.4 字段类型映射表

| 明道云 type | 含义 | 新平台 MySQL 类型 | 转换逻辑 |
|------------|------|------------------|---------|
| 2 | 文本(多行) | VARCHAR/TEXT | 直接取值 |
| 3 | 手机 | VARCHAR(20) | 直接取值 |
| 5 | 邮箱 | VARCHAR(100) | 直接取值 |
| 6 | 数值 | DECIMAL | parseFloat |
| 8 | 金额 | DECIMAL(12,2) | parseFloat |
| 15 | 日期 | DATETIME | ISO8601 转换 |
| 16 | 日期+时间 | DATETIME | ISO8601 转换 |
| 9 | 地区 | VARCHAR(200) | JSON省市区拼接 |
| 11 | 选项(下拉) | VARCHAR/TINYINT | 值映射到枚举 |
| 10 | 选项(多选) | VARCHAR/JSON | JSON数组 |
| 26 | 成员 | BIGINT(FK) | accountId→user_id |
| 27 | 部门 | BIGINT(FK) | departmentId→dept_id |
| 29 | 关联记录 | BIGINT(FK) | rowId→target_id |
| 14 | 附件 | VARCHAR(500) | 文件key，需S3 URL |
| 33 | 自动编号 | VARCHAR(50) | 直接取值 |
| 36 | 检查项 | TINYINT | boolean |
| 41 | 富文本 | TEXT | HTML内容 |
| 28 | 等级 | TINYINT | 1-5 |

---

## 四、分阶段执行计划

### Phase 1: 用户/部门基础数据（预计 1h）

```bash
# 从 MySQL 5.7 (mysql-mdy:3307) 导出用户和部门
# 生成 Flyway SQL → 新平台 MySQL (mysql-dev:3306) wande-ai 库
docker exec mysql-mdy mysql -uroot -e "SELECT * FROM MDProject.Account" > /tmp/mdy-accounts.tsv
docker exec mysql-mdy mysql -uroot -e "SELECT * FROM MDProject.Project_Department" > /tmp/mdy-depts.tsv
# Python 脚本做 ID 映射 + INSERT 生成
```

**关键**：建立 `accountId → sys_user.user_id` 映射表，后续所有"成员"类型字段都要用。

### Phase 2: CRM 核心数据（预计 4-6h）

执行顺序（有外键依赖）：
1. `crm_customer` ← 客户表（无外键依赖）
2. `crm_lead` ← 线索表（可关联客户）
3. `crm_opportunity` ← 商机表（关联客户+线索，**7份工作表合并去重**）
4. `crm_activity_log` ← 跟进记录（关联商机/客户）
5. `crm_contract` ← 合同（关联商机）
6. `crm_bid_application` ← 投标申请（关联商机）

**商机去重策略**：7 份商机工作表（7 个部门各一份），用 `唯一性ID` 字段去重，取最新版本（按 `utime` 排序）。

### Phase 3: 附件迁移（预计 2h）

```bash
# mdservicedata 中记录了明道云文件的元数据
# 需要：
# 1. 提取文件 key/路径
# 2. 从明道云 S3 bucket 下载（如果可访问）或标记为"待迁移"
# 3. 上传到新平台 S3 bucket
# 4. 更新新平台数据库中的文件 URL
```

### Phase 4: 审批流历史（P1，可交付后补）

280 万条 `wf_instance`，建议：
- 只迁移最近 1 年的活跃流程
- 或按业务域（CRM 审批）筛选迁移
- 旧审批流作为只读归档

---

## 五、数据访问方式

### 当前环境

```bash
# MongoDB（无认证）
docker exec mongodb-mdy mongo
# 或从宿主机
mongo --host 127.0.0.1 --port 27017

# MySQL 5.7（skip-grant-tables，无密码）
docker exec mysql-mdy mysql -uroot
# 或从宿主机
mysql -h 127.0.0.1 -P 3307 -uroot

# 新平台 MySQL 8（目标库）
mysql -h 127.0.0.1 -P 3306 -uroot -p  # wande-ai 库
```

### 关键查询示例

```javascript
// 查某个工作表的字段映射
db.getSiblingDB('mdworksheet').wscontrols.find(
  {wsid: "6886d6bc074a71b93636d2e5"},  // 商机表
  {cid:1, cname:1, type:1, required:1}
)

// 查商机数据（前5条）
db.getSiblingDB('mdwsrows').getCollection('ws6886d6bc074a71b93636d2e5').find().limit(5)

// 统计各工作表数据量
db.getSiblingDB('mdwsrows').getCollectionNames().forEach(function(c){
  var count = db.getSiblingDB('mdwsrows').getCollection(c).count();
  if(count > 0) print(c + ': ' + count);
})
```

---

## 六、风险与注意事项

| 风险 | 影响 | 应对 |
|------|------|------|
| 商机 7 份工作表字段不完全一致 | 合并时某些字段缺失 | 取并集，缺失填 NULL |
| 用户 accountId 无法映射 | 负责人/创建人字段丢失 | 先建映射表，无法匹配的记为"系统迁移" |
| 关联记录解引用 | 跨表引用用 rowId，需要重建 FK | 先导主表，再用 rowId→新ID 映射更新 FK |
| 明道云选项值与新平台枚举不一致 | 商机阶段/状态映射 | 建立值映射字典，人工确认 |
| 附件 S3 bucket 可能已过期 | 文件无法下载 | 先检查 S3 可达性，不可达则记录缺失清单 |
| MongoDB Too many open files | 315 个集合触发 ulimit | 已设置 `--ulimit nofile=65536` 解决 |

---

## 七、执行建议

1. **周一交付前**：完成 Phase 1（用户/部门）+ Phase 2 前 3 步（客户/线索/商机），确保 CRM 模块有真实数据可展示
2. **周一当天**：Phase 2 剩余（跟进记录/合同/投标）
3. **下周内**：Phase 3（附件）+ Phase 4（审批流）
4. **迁移脚本建议由编程CC实现**：创建 Issue，指派 kimi 写 Python ETL 脚本，输出为 Flyway SQL
