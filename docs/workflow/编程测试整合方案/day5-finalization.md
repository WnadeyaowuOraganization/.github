# Day 5 方案定稿与文档输出计划

## 一、目标

整合Day 1-4的所有工作，输出最终技术方案和完整的实施文档。

## 二、最终交付物清单

### 2.1 技术文档（必须）

| 文档 | 内容 | 负责人 | 模板 |
|------|------|--------|------|
| ADR-001 | 编译-测试一体化架构决策 | 研发经理 | ADR模板 |
| ADR-002 | 共享Volume缓存策略决策 | 排程经理 | ADR模板 |
| 实施方案 | 详细实施步骤和回滚方案 | 排程经理 | 实施模板 |
| 运维手册 | 日常运维和监控指南 | 研发经理 | 运维模板 |
| 迁移指南 | 从现有方案迁移的SOP | 排程经理 | SOP模板 |

### 2.2 代码/配置（必须）

| 文件 | 内容 | 负责人 | 路径 |
|------|------|--------|------|
| pr-test-unified.yml | 最终版workflow | 研发经理 | .github/workflows/ |
| run-cc-optimized.sh | 优化版CC启动脚本 | 排程经理 | scripts/ |
| cache-init.sh | 缓存初始化脚本 | 排程经理 | scripts/ |
| docker-compose.test.yml | 测试环境配置 | 研发经理 | docker/ |

### 2.3 培训材料（可选）

| 材料 | 内容 | 负责人 |
|------|------|--------|
| 方案宣讲PPT | 架构设计和效果展示 | 排程经理 |
| 操作视频 | 关键操作录屏 | 研发经理 |
| FAQ文档 | 常见问题解答 | 双方共同 |

## 三、文档编写计划

### 3.1 ADR编写（上午9:00-12:00）

#### ADR-001: 编译-测试一体化架构决策

```markdown
# ADR-001: 采用编译-测试一体化架构

## 状态
- 日期: 2026-04-15
- 决策: 已接受
- 决策者: 排程经理、研发经理

## 背景
当前CI流程中，build和e2e-test为独立job，导致：
1. build job启动的服务进程在job结束后被清理
2. e2e-test必须重新启动服务，浪费60-120秒
3. job间通信通过磁盘产物，效率低

## 决策
将build和e2e-test合并为单个job，在同job内完成编译→启动→测试→清理。

## 方案对比

| 方案 | 优点 | 缺点 | 选择 |
|------|------|------|------|
| 保持现状 | 无改动风险 | 浪费2分钟/次 | ❌ |
| job间传递PID | 理论上可行 | GitHub Actions不支持 | ❌ |
| services容器 | 服务独立生命周期 | 资源占用高 | ❌ |
| **一体化job** | **消除重复启动** | **job变长** | ✅ |

## 影响
- 正向: CI时间减少2-3分钟
- 风险: 单job失败需全重跑
- 缓解: 保留原有workflow作为fallback

## 实施
- Day 1-4: POC验证和优化
- Day 5: 文档输出
- Week 2: 全量推广
```

#### ADR-002: 共享Volume缓存策略决策

```markdown
# ADR-002: 采用共享Volume缓存策略

## 状态
- 日期: 2026-04-15
- 决策: 已接受
- 决策者: 排程经理、研发经理

## 背景
20个kimi目录各自独立编译，导致：
1. 重复下载Maven依赖（每个约2GB）
2. 重复安装pnpm依赖（每个约1GB）
3. 磁盘I/O浪费，编译时间长

## 决策
采用"只读共享+本地写入"策略，共享依赖缓存。

## 方案对比

| 方案 | 优点 | 缺点 | 选择 |
|------|------|------|------|
| 各自独立 | 隔离性好 | 磁盘浪费40GB | ❌ |
| 完全共享 | 最省空间 | 并发写入冲突 | ❌ |
| 远程缓存 | 可跨机器 | 需额外基础设施 | ❌ |
| **只读共享+本地** | **平衡空间与并发** | **需定期合并** | ✅ |

## 实施细节
- 共享目录: ~/.m2/repository, ~/.pnpm-store
- 本地目录: /tmp/cc-maven-cache-kimi{N}/
- 合并策略: 后台任务定期合并本地到共享
```

### 3.2 实施方案编写（下午13:00-16:00）

```markdown
# E2E测试优化实施方案

## 1. 实施阶段

### Phase 1: 基础设施准备（Day 1-2）
1. 创建共享目录结构
2. 配置权限和文件锁
3. 部署新workflow到测试分支

### Phase 2: 试点验证（Day 3）
1. 选择kimi18进行POC
2. 收集性能数据
3. 问题修复和优化

### Phase 3: 全量推广（Day 4-5）
1. 批量配置20个kimi目录
2. 切换所有CC使用新方案
3. 监控运行状态

## 2. 详细步骤

### Step 1: 创建共享目录
```bash
# 由排程经理执行
mkdir -p /home/ubuntu/.m2/repository
mkdir -p /home/ubuntu/.pnpm-store
chown -R ubuntu:ubuntu /home/ubuntu/.m2 /home/ubuntu/.pnpm-store
chmod -R 755 /home/ubuntu/.m2 /home/ubuntu/.pnpm-store
```

### Step 2: 创建各kimi产物目录
```bash
for i in $(seq 1 20); do
    mkdir -p /apps/wande-ai-backend-kimi${i}
    mkdir -p /apps/wande-ai-front-kimi${i}
    chown ubuntu:ubuntu /apps/wande-ai-backend-kimi${i} /apps/wande-ai-front-kimi${i}
done
```

### Step 3: 更新run-cc.sh
```bash
# 在每个kimi目录的run-cc.sh中添加
export MAVEN_OPTS="-Dmaven.repo.local=/home/ubuntu/.m2/repository -Xmx1g"
export PNPM_STORE_PATH="/home/ubuntu/.pnpm-store"
export LOCAL_MAVEN_CACHE="/tmp/cc-maven-cache-${KIMI_TAG}"
```

### Step 4: 部署新workflow
```bash
cp pr-test-unified.yml .github/workflows/
git add .github/workflows/pr-test-unified.yml
git commit -m "feat(ci): 编译-测试一体化workflow"
```

## 3. 回滚方案

### 回滚触发条件
- 测试失败率>10%
- CI时间无改善或恶化
- 稳定性问题（频繁失败）

### 回滚步骤
1. 恢复原有pr-test.yml
2. 清空共享目录（可选）
3. 恢复各kimi原有环境变量
4. 通知所有CC使用原方案

### 回滚时间
- 热回滚: 5分钟（仅切换workflow）
- 全回滚: 30分钟（恢复所有配置）

## 4. 监控指标

| 指标 | 当前 | 目标 | 告警阈值 |
|------|------|------|----------|
| CI总时间 | 25分钟 | 15分钟 | >20分钟 |
| 编译时间 | 6分钟 | 3分钟 | >5分钟 |
| 缓存命中率 | - | >80% | <60% |
| 测试失败率 | 5% | <5% | >10% |

## 5. 成功标准

- [ ] 80%以上PR的CI时间<15分钟
- [ ] 缓存命中率>80%
- [ ] 测试失败率不高于原有方案
- [ ] 无稳定性问题（连续7天）
```

### 3.3 运维手册编写（下午16:00-18:00）

```markdown
# E2E测试优化运维手册

## 1. 日常检查

### 1.1 检查共享目录状态
```bash
# 检查磁盘空间
df -h /home/ubuntu/.m2

# 检查目录权限
ls -la /home/ubuntu/.m2/repository | head -5

# 检查缓存大小
du -sh /home/ubuntu/.m2/repository
```

### 1.2 检查各kimi产物目录
```bash
for i in $(seq 1 20); do
    echo "kimi${i}:"
    du -sh /apps/wande-ai-backend-kimi${i} 2>/dev/null || echo "目录不存在"
done
```

### 1.3 监控I/O负载
```bash
iostat -x 1 5
```

## 2. 常见问题处理

### 2.1 缓存未生效
**现象**: 编译时间未缩短
**排查**:
1. 检查环境变量: `echo $MAVEN_OPTS`
2. 检查目录权限: `ls -la /home/ubuntu/.m2`
3. 检查缓存内容: `ls /home/ubuntu/.m2/repository/org/springframework`

**解决**:
```bash
# 修复权限
sudo chown -R ubuntu:ubuntu /home/ubuntu/.m2

# 重新注入环境变量
source /home/ubuntu/projects/wande-play-kimi{N}/.env
```

### 2.2 并发写入冲突
**现象**: 多个CC同时编译时报错
**解决**:
1. 启用文件锁: `flock /home/ubuntu/.m2/repository.lock -c "mvn package"`
2. 或切换到本地写入模式

### 2.3 磁盘空间不足
**现象**: 编译失败，提示No space left
**解决**:
```bash
# 清理旧版本依赖
find /home/ubuntu/.m2/repository -name "*.jar" -mtime +30 -delete

# 清理未使用产物
find /apps -name "*.jar" -mtime +7 -delete
```

## 3. 升级维护

### 3.1 更新共享依赖
```bash
# 手动下载新依赖到共享目录
cd /tmp
mvn dependency:get -Dartifact=xxx:xxx:xxx \
  -Dmaven.repo.local=/home/ubuntu/.m2/repository
```

### 3.2 重新冻结缓存
```bash
# 备份当前缓存
tar czf /backup/m2-repo-$(date +%Y%m%d).tar.gz /home/ubuntu/.m2/repository

# 清空并重新填充
rm -rf /home/ubuntu/.m2/repository/*
# 触发一次全量编译
```

## 4. 告警配置

```yaml
# 建议配置的告警规则
- alert: CI_Time_High
  expr: ci_duration_minutes > 20
  for: 5m
  
- alert: Cache_Hit_Low
  expr: cache_hit_rate < 0.6
  for: 10m
  
- alert: Disk_Space_Low
  expr: disk_free_gb < 10
  for: 1m
```

## 5. 联系信息

- 技术负责人: 排程经理/研发经理
- 紧急情况: 立即停止新workflow，切回原方案
```

## 四、代码交付物

### 4.1 pr-test-unified.yml（最终版）

```yaml
name: PR E2E测试一体化

on:
  pull_request:
    branches: [dev]
    types: [opened, synchronize, reopened]

jobs:
  unified-build-test:
    name: 编译+测试一体化
    runs-on: [self-hosted, linux, x64, g7e]
    steps:
      # 1. 检出代码
      - uses: actions/checkout@v4
      
      # 2. 检测变更
      - name: 检测变更模块
        id: detect
        run: |
          echo "backend=$(git diff --name-only origin/dev | grep -q "^backend/" && echo true || echo false)" >> $GITHUB_OUTPUT
          echo "frontend=$(git diff --name-only origin/dev | grep -q "^frontend/" && echo true || echo false)" >> $GITHUB_OUTPUT
      
      # 3. 编译后端（使用共享缓存）
      - name: 编译后端
        if: steps.detect.outputs.backend == 'true'
        env:
          MAVEN_OPTS: "-Dmaven.repo.local=/home/ubuntu/.m2/repository -Xmx1g"
        run: |
          cd backend
          mvn clean package -Pprod -DskipTests -T 1C
          cp target/ruoyi-admin.jar /apps/wande-ai-backend-ci/
      
      # 4. 编译前端（使用共享缓存）
      - name: 编译前端
        if: steps.detect.outputs.frontend == 'true'
        env:
          PNPM_STORE_PATH: "/home/ubuntu/.pnpm-store"
        run: |
          cd frontend
          pnpm install --store-dir $PNPM_STORE_PATH
          pnpm build
          rsync -a apps/web-antd/dist/ /apps/wande-ai-front-ci/
      
      # 5. 启动服务
      - name: 启动CI服务
        run: |
          # 停止旧进程
          PID=$(lsof -ti :6041 2>/dev/null || true)
          [ -n "$PID" ] && kill -9 $PID 2>/dev/null || true
          
          # 启动新进程
          nohup java -jar /apps/wande-ai-backend-ci/ruoyi-admin.jar \
            --server.port=6041 \
            > /apps/wande-ai-backend-ci/logs/backend.log 2>&1 &
          echo "PID=$!" > /apps/wande-ai-backend-ci/backend.pid
      
      # 6. 健康检查（优化后5轮×1秒）
      - name: 等待服务就绪
        run: |
          for i in $(seq 1 5); do
            curl -sf http://localhost:6041/actuator/health && exit 0
            sleep 1
          done
          exit 1
      
      # 7. 执行测试
      - name: E2E测试
        run: |
          cd e2e
          npx playwright test --workers=4
      
      # 8. 清理
      - name: 清理服务
        if: always()
        run: |
          PID=$(cat /apps/wande-ai-backend-ci/backend.pid 2>/dev/null || echo "")
          [ -n "$PID" ] && kill $PID 2>/dev/null || true
```

### 4.2 cache-init.sh（缓存初始化脚本）

```bash
#!/bin/bash
# 缓存初始化脚本
# 用途: 预热共享缓存，避免首次编译缓慢

set -e

echo "=== 初始化Maven共享缓存 ==="
mkdir -p /home/ubuntu/.m2/repository
chown -R ubuntu:ubuntu /home/ubuntu/.m2

# 预下载常用依赖
cd /tmp
cat > pom.xml << 'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>cache</groupId>
  <artifactId>warmup</artifactId>
  <version>1.0</version>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
      <version>2.7.18</version>
    </dependency>
  </dependencies>
</project>
EOF

mvn dependency:resolve -Dmaven.repo.local=/home/ubuntu/.m2/repository
rm pom.xml

echo "=== 初始化pnpm共享缓存 ==="
mkdir -p /home/ubuntu/.pnpm-store
chown -R ubuntu:ubuntu /home/ubuntu/.pnpm-store

echo "=== 缓存初始化完成 ==="
echo "Maven缓存: $(du -sh /home/ubuntu/.m2/repository)"
echo "pnpm缓存: $(du -sh /home/ubuntu/.pnpm-store)"
```

## 五、交付检查清单

### 5.1 文档检查

- [ ] ADR-001 已编写并评审
- [ ] ADR-002 已编写并评审
- [ ] 实施方案 已编写并评审
- [ ] 运维手册 已编写并评审
- [ ] 迁移指南 已编写并评审

### 5.2 代码检查

- [ ] pr-test-unified.yml 语法正确
- [ ] cache-init.sh 可执行
- [ ] run-cc-optimized.sh 已测试
- [ ] 所有脚本有注释和usage说明

### 5.3 验证检查

- [ ] POC测试报告 已输出
- [ ] 性能基线数据 已记录
- [ ] 回滚方案 已验证可行
- [ ] 监控指标 已配置

### 5.4 培训检查

- [ ] 方案宣讲PPT 已完成
- [ ] FAQ文档 已整理
- [ ] 团队宣讲 已排期

## 六、提交与归档

### 6.1 Git提交

```bash
# 提交所有文档和代码
git add docs/workflow/编程测试整合方案/
git add .github/workflows/pr-test-unified.yml
git add scripts/cache-init.sh
git add scripts/run-cc-optimized.sh

git commit -m "feat(e2e): 编译-测试一体化方案完整实现

- 共享Volume缓存策略
- 编译-测试一体化workflow
- 完整实施文档和运维手册
- POC验证通过，性能提升50%

Fixes #E2E-OPT-2026"
```

### 6.2 文档归档

| 文档 | 路径 | 状态 |
|------|------|------|
| Day 1调研报告 | docs/workflow/编程测试整合方案/day1-report.md | ✅ |
| 共享Volume设计 | shared-volume-design.md | ✅ |
| G7e资源评估 | g7e-resource-assessment.md | ✅ |
| 一体化设计 | /tmp/pr-test-unified.yml | ✅ |
| Day 3 POC计划 | day3-poc-validation.md | ✅ |
| Day 4优化计划 | day4-optimization.md | ✅ |
| Day 5定稿计划 | day5-finalization.md | ✅ |
| 最终ADR | adr/ | ✅ |
| 实施方案 | implementation.md | ✅ |
| 运维手册 | operations.md | ✅ |

### 6.3 通知发布

```markdown
【发布通知】E2E测试优化方案已完成

经过5天设计、验证和优化，E2E测试优化方案已完成全部开发和文档工作。

核心成果:
- CI时间: 20-35分钟 → 8-15分钟 (-50%~60%)
- 编译缓存: 实现Maven/pnpm共享缓存
- 一体化: 消除重复启动等待

交付物:
- 技术文档: 5份
- 代码: 3个脚本/配置
- 验证数据: POC报告

下一步:
- Week 2启动全量推广
- 逐步切换所有kimi目录
- 监控运行状态

详细文档: docs/workflow/编程测试整合方案/
```

---
**执行时间**: Day 5全天
**负责人**: 排程经理 + 研发经理联合执行
**最终交付**: Day 5 18:00前
