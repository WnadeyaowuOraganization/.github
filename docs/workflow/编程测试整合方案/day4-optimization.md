# Day 4 问题修复与优化计划

## 一、目标

基于Day 3 POC测试结果，修复发现的问题，优化方案细节。

## 二、问题分类与修复

### 2.1 POC问题清单（假设发现）

| 优先级 | 问题 | 影响 | 负责人 |
|--------|------|------|--------|
| P0 | Maven缓存未生效 | 编译时间无改善 | 排程经理 |
| P0 | 服务启动后立即退出 | 测试无法执行 | 研发经理 |
| P1 | pnpm store权限错误 | 前端编译失败 | 排程经理 |
| P1 | 健康检查超时 | 启动时间过长 | 研发经理 |
| P2 | I/O负载过高 | 并发性能下降 | 排程经理 |
| P2 | 测试日志不完整 | 问题定位困难 | 研发经理 |

### 2.2 问题修复方案

#### P0-1: Maven缓存未生效

**根因分析**:
- 环境变量未正确注入
- 或.m2/repository路径不存在

**修复方案**:
```bash
# 1. 验证环境变量
echo $MAVEN_OPTS
# 应输出: -Dmaven.repo.local=/home/ubuntu/.m2/repository

# 2. 验证目录存在
ls -la /home/ubuntu/.m2/repository

# 3. 修复run-cc.sh
cat >> /home/ubuntu/projects/wande-play-kimi18/run-cc.sh << 'EOF'
export MAVEN_OPTS="-Dmaven.repo.local=/home/ubuntu/.m2/repository -Xmx1g"
export MAVEN_REPOSITORY=/home/ubuntu/.m2/repository
EOF

# 4. 预热缓存（手动下载常用依赖）
cd /tmp && mvn dependency:get -Dartifact=org.springframework.boot:spring-boot:2.7.x
```

**验证**:
- [ ] 再次编译，观察是否使用缓存
- [ ] 检查~/.m2/repository是否有新文件

#### P0-2: 服务启动后立即退出

**根因分析**:
- 端口冲突
- 配置文件错误
- 依赖未完整

**修复方案**:
```bash
# 1. 检查端口占用
lsof -ti :6041

# 2. 查看启动日志
tail -50 /apps/wande-ai-backend-kimi18/logs/backend.log

# 3. 修复启动脚本
# 确保java命令使用nohup且输出重定向正确
nohup java -jar /apps/wande-ai-backend-kimi18/ruoyi-admin.jar \
    --server.port=6041 \
    > /apps/wande-ai-backend-kimi18/logs/backend.log 2>&1 &

# 4. 延长健康检查等待时间（如果必要）
# 从5轮×1秒改为10轮×1秒
```

**验证**:
- [ ] 服务启动后保持运行
- [ ] 健康检查通过

#### P1-1: pnpm store权限错误

**修复方案**:
```bash
# 1. 修复权限
sudo chown -R ubuntu:ubuntu /home/ubuntu/.pnpm-store
chmod -R 755 /home/ubuntu/.pnpm-store

# 2. 配置pnpm使用共享store
cd /home/ubuntu/projects/wande-play-kimi18/frontend
echo "store-dir=/home/ubuntu/.pnpm-store" > .npmrc

# 3. 验证
pnpm config get store-dir
```

#### P1-2: 健康检查超时

**优化方案**:
```yaml
# 原方案：20轮×3秒 = 60秒
# 优化方案：10轮×2秒 = 20秒（平衡速度和稳定性）

- name: 等待CI后端就绪（优化后）
  run: |
    for i in $(seq 1 10); do
      if curl -sf http://localhost:6041/actuator/health --max-time 5 >/dev/null 2>&1; then
        echo "✅ CI后端就绪"
        exit 0
      fi
      echo "等待中... ($((i*2))s/20s)"
      sleep 2
    done
    exit 1
```

#### P2-1: I/O负载过高

**优化方案**:
```bash
# 1. 实施错峰启动
# 在run-cc.sh中添加随机延迟
sleep $((RANDOM % 30))

# 2. 预热共享目录（定时任务）
# 每小时读取一次~/.m2/repository保持热点
cat > /tmp/warmup-cache.sh << 'EOF'
#!/bin/bash
find /home/ubuntu/.m2/repository -type f -name "*.jar" | head -100 | xargs cat > /dev/null
EOF
chmod +x /tmp/warmup-cache.sh

# 3. 监控I/O
iostat -x 1 | tee /tmp/io-stats.log
```

#### P2-2: 测试日志不完整

**优化方案**:
```yaml
# 在workflow中添加详细日志收集
- name: 收集测试日志
  if: always()
  run: |
    mkdir -p /tmp/test-logs/${{ github.run_id }}
    cp -r /apps/wande-ai-backend-kimi18/logs /tmp/test-logs/${{ github.run_id }}/
    cp -r /home/ubuntu/projects/wande-play-kimi18/e2e/test-results /tmp/test-logs/${{ github.run_id }}/
    
- name: 上传日志
  uses: actions/upload-artifact@v4
  with:
    name: test-logs-${{ github.run_id }}
    path: /tmp/test-logs/${{ github.run_id }}/
```

## 三、性能优化

### 3.1 Maven编译优化

```bash
# 启用并行编译
export MAVEN_OPTS="-Dmaven.repo.local=/home/ubuntu/.m2/repository \
  -T 1C \
  -Dmaven.compile.fork=true"

# 跳过非必要插件
mvn package -DskipTests \
  -Dmaven.javadoc.skip=true \
  -Dmaven.source.skip=true
```

### 3.2 pnpm构建优化

```bash
# 使用并行构建
pnpm build --parallel

# 启用缓存
pnpm config set cache-dir /home/ubuntu/.pnpm-store/cache
```

### 3.3 Playwright测试优化

```javascript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 4 : undefined,  // 提升并发
  fullyParallel: true,
  timeout: 30000,  // 减少单测试超时
  expect: {
    timeout: 5000,
  },
  // 重用已认证状态
  projects: [
    {
      name: 'setup',
      testMatch: /global\.setup\.ts/,
    },
    {
      name: 'tests',
      dependencies: ['setup'],
      use: {
        storageState: 'playwright/.auth/user.json',
      },
    },
  ],
});
```

## 四、验证修复

### 4.1 回归测试

| 测试项 | 修复前 | 修复后 | 通过标准 |
|--------|--------|--------|----------|
| Maven缓存 | ❌ 未生效 | ✅ 生效 | 编译<3分钟 |
| 服务启动 | ❌ 退出 | ✅ 稳定 | 运行>5分钟 |
| pnpm权限 | ❌ 错误 | ✅ 正常 | 前端编译成功 |
| 健康检查 | ❌ 超时 | ✅ 通过 | <20秒 |
| 并发编译 | ⚠️ 高IO | ✅ 正常 | iowait<50% |

### 4.2 性能基准

修复后应达到：
- 首次编译: <8分钟
- 缓存编译: <2分钟
- 启动等待: 0秒（消除）
- 测试执行: <8分钟
- **总计**: <18分钟（对比当前20-35分钟）

## 五、文档更新

### 5.1 更新内容

1. **shared-volume-design.md**: 补充问题修复细节
2. **pr-test-unified.yml**: 更新修复后的workflow
3. **troubleshooting.md**: 新建问题排查手册

### 5.2 输出清单

- [ ] 修复记录（问题+根因+方案）
- [ ] 优化后的完整workflow yaml
- [ ] 更新后的技术设计文档
- [ ] 问题排查手册

## 六、交付物

| 交付物 | 负责人 | 截止时间 |
|--------|--------|----------|
| 问题修复记录 | 双方 | 12:00 |
| 优化后workflow | 研发经理 | 15:00 |
| 性能基准报告 | 排程经理 | 17:00 |
| 问题排查手册 | 研发经理 | 18:00 |

---
**执行时间**: Day 4全天
**负责人**: 排程经理 + 研发经理联合执行
**交付时间**: Day 4 18:00前
