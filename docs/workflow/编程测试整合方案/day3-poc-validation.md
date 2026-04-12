# Day 3 原型验证计划（POC）

## 一、验证目标

验证共享Volume + 编译-测试一体化方案的可行性，收集性能基线数据。

## 二、测试范围

### 2.1 选择测试PR

**推荐选择**: kimi18（已确认）（当前空闲）

**选择标准**:
- [ ] 有backend变更（验证Maven缓存）
- [ ] 有frontend变更（验证pnpm缓存）
- [ ] 非紧急P0 Issue（允许失败重试）
- [ ] 测试用例覆盖api/smoke/e2e

**候选Issue**:
- #1531 可赢性评分模型（backend，有api测试）
- #1766 代理商工作台（frontend，有smoke测试）

### 2.2 验证场景

| 场景 | 描述 | 预期结果 |
|------|------|----------|
| 场景1: 首次编译 | 清空缓存后首次编译 | 下载依赖，记录时间 |
| 场景2: 缓存命中 | 相同代码再次编译 | 大幅缩短，验证缓存有效 |
| 场景3: 一体化流程 | 编译→启动→测试完整流程 | 无重复启动等待 |
| 场景4: 并发测试 | 2个kimi同时编译 | 验证并发控制 |

## 三、执行步骤

### Step 1: 环境准备（9:00-10:00）

**排程经理执行**:
```bash
# 1. 创建共享目录
mkdir -p /home/ubuntu/.m2/repository
mkdir -p /home/ubuntu/.pnpm-store
chown -R ubuntu:ubuntu /home/ubuntu/.m2 /home/ubuntu/.pnpm-store

# 2. 创建kimi18产物目录
mkdir -p /apps/wande-ai-backend-kimi18
mkdir -p /apps/wande-ai-front-kimi18
chown ubuntu:ubuntu /apps/wande-ai-backend-kimi18 /apps/wande-ai-front-kimi18

# 3. 修改kimi18的run-cc.sh注入环境变量
echo 'export MAVEN_OPTS="-Dmaven.repo.local=/home/ubuntu/.m2/repository"' >> /home/ubuntu/projects/wande-play-kimi18/.env
echo 'export PNPM_STORE_PATH="/home/ubuntu/.pnpm-store"' >> /home/ubuntu/projects/wande-play-kimi18/.env
```

**研发经理执行**:
```bash
# 4. 部署新workflow到测试分支
cp /tmp/pr-test-unified.yml /home/ubuntu/projects/.github/.github/workflows/pr-test-poc.yml

# 5. 配置测试PR使用新workflow
# 在PR分支添加label: poc-unified-test
```

### Step 2: 首次编译测试（10:00-11:00）

**执行命令**:
```bash
cd /home/ubuntu/projects/wande-play-kimi18

# 记录开始时间
date +%s > /tmp/poc-start-time

# 执行编译
mvn clean package -Pprod -Dmaven.test.skip=true
pnpm install
pnpm build

# 记录结束时间
date +%s > /tmp/poc-end-time

# 计算耗时
echo "编译耗时: $(($(cat /tmp/poc-end-time) - $(cat /tmp/poc-start-time)))秒"
```

**数据收集**:
- [ ] Maven下载依赖数量
- [ ] pnpm安装依赖数量
- [ ] 编译总耗时
- [ ] 产物大小

### Step 3: 缓存命中测试（11:00-12:00）

**执行命令**:
```bash
cd /home/ubuntu/projects/wande-play-kimi18

# 清空本地target（模拟重新编译）
rm -rf backend/target frontend/dist

# 记录开始时间
date +%s > /tmp/poc-cache-start

# 再次编译（应使用缓存）
mvn clean package -Pprod -Dmaven.test.skip=true
pnpm install
pnpm build

# 记录结束时间
date +%s > /tmp/poc-cache-end

# 计算耗时
echo "缓存编译耗时: $(($(cat /tmp/poc-cache-end) - $(cat /tmp/poc-cache-start)))秒"
```

**数据收集**:
- [ ] 是否命中Maven缓存
- [ ] 是否命中pnpm缓存
- [ ] 缓存命中率
- [ ] 编译耗时对比

### Step 4: 一体化流程测试（13:00-15:00）

**执行命令**:
```bash
# 触发测试PR的workflow
gh workflow run pr-test-poc.yml --ref feature-Issue-${ISSUE_NUM}

# 监控执行
gh run watch
```

**数据收集**:
- [ ] 总执行时间
- [ ] 各阶段时间（编译/启动/测试）
- [ ] 是否消除重复启动等待
- [ ] 测试通过率

### Step 5: 并发测试（15:00-16:00）

**执行命令**:
```bash
# 同时启动kimi18和kimi19编译
cd /home/ubuntu/projects/wande-play-kimi18 && mvn clean package &
cd /home/ubuntu/projects/wande-play-kimi19 && mvn clean package &

# 监控I/O负载
iostat -x 1 10
```

**数据收集**:
- [ ] 并发编译是否成功
- [ ] I/O负载峰值
- [ ] 是否有竞争冲突
- [ ] 总耗时对比串行

## 四、成功标准

| 指标 | 当前 | POC目标 | 验收标准 |
|------|------|---------|----------|
| 首次编译 | - | <10分钟 | ✅ 通过 |
| 缓存命中编译 | 5-8分钟 | <3分钟 | 提升>50% |
| 重复启动等待 | 60-120秒 | 0秒 | 完全消除 |
| 并发编译 | - | 无冲突 | 2个CC同时成功 |
| 测试通过率 | - | >95% | 不降低质量 |

## 五、风险预案

| 风险 | 应对措施 |
|------|----------|
| 缓存不生效 | 检查环境变量，确认路径正确 |
| 并发冲突 | 启用文件锁，或改用本地写入方案 |
| 测试失败 | 对比原workflow，定位问题 |
| 性能无提升 | 分析瓶颈，调整方案 |

## 六、交付物

1. **POC测试报告**: 包含所有测试数据和对比分析
2. **问题清单**: 发现的问题及解决方案
3. **优化建议**: 基于POC结果的方案调整
4. **性能基线**: 用于后续优化的参考数据

---
**执行时间**: Day 3全天
**负责人**: 排程经理 + 研发经理联合执行
**交付时间**: Day 3 18:00前

## 七、验证PR确认

**已选定验证PR**: #2367
**理由**: 
- 中等复杂度
- 有backend+frontend变更
- 可验证缓存和一体化流程

**备选**: kimi19（如kimi18遇到问题）

**更新时间**: Day 3启动时确认
