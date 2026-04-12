# 共享Volume详细设计

## 1. 目录结构设计

### 1.1 Maven依赖缓存（只读共享）

```
/home/ubuntu/.m2/
├── repository/                    # 共享依赖仓库
│   ├── org/                       # 组织命名空间
│   ├── com/
│   └── ...
└── repository.lock                # 全局锁文件（仅在后台更新时使用）
```

**说明**:
- 所有kimi目录共享同一个Maven本地仓库
- 新依赖首次下载时写入共享目录
- 使用文件锁防止并发写入冲突

### 1.2 本地写入缓存（各kimi独立）

```
/tmp/cc-maven-cache/
├── kimi1/                         # kimi1本地编译缓存
│   └── target/                    # 编译中间产物
├── kimi2/
│   └── target/
└── ...
```

**说明**:
- 各kimi目录独立，避免并发冲突
- 使用/tmp目录，重启后自动清理
- 可通过环境变量覆盖默认路径

### 1.3 pnpm依赖缓存（只读共享）

```
/home/ubuntu/.pnpm-store/          # 共享pnpm store
├── v3/
│   ├── files/                     # 包内容存储
│   └── ...
```

**说明**:
- 所有kimi共享同一个pnpm store
- 节省磁盘空间，避免重复下载
- pnpm的content-addressable存储天然去重

### 1.4 编译产物目录（各kimi独立，持久化）

```
/apps/
├── wande-ai-backend-kimi1/        # kimi1后端产物
│   └── ruoyi-admin.jar
├── wande-ai-front-kimi1/          # kimi1前端产物
│   └── dist/
├── wande-ai-backend-kimi2/
├── wande-ai-front-kimi2/
└── ...
```

**说明**:
- 各kimi独立，避免产物冲突
- 持久化存储，可跨CC复用
- 与CI环境产物路径一致

## 2. 权限方案

### 2.1 共享目录权限

```bash
# 创建共享目录
mkdir -p /home/ubuntu/.m2/repository
mkdir -p /home/ubuntu/.pnpm-store

# 设置权限（ubuntu用户读写，其他用户只读）
chown -R ubuntu:ubuntu /home/ubuntu/.m2
chmod -R 755 /home/ubuntu/.m2

chown -R ubuntu:ubuntu /home/ubuntu/.pnpm-store
chmod -R 755 /home/ubuntu/.pnpm-store
```

### 2.2 本地缓存权限

```bash
# 各kimi目录创建时自动设置
mkdir -p /tmp/cc-maven-cache-kimi${N}
chmod 755 /tmp/cc-maven-cache-kimi${N}
```

### 2.3 产物目录权限

```bash
# 创建持久化产物目录
for i in $(seq 1 20); do
    mkdir -p /apps/wande-ai-backend-kimi${i}
    mkdir -p /apps/wande-ai-front-kimi${i}
    chown -R ubuntu:ubuntu /apps/wande-ai-backend-kimi${i}
    chown -R ubuntu:ubuntu /apps/wande-ai-front-kimi${i}
    chmod 755 /apps/wande-ai-backend-kimi${i}
    chmod 755 /apps/wande-ai-front-kimi${i}
done
```

## 3. 并发控制方案

### 3.1 推荐方案：只读共享 + 本地写入

**读取流程**:
1. 编译时优先读取共享目录 `~/.m2/repository`
2. 如果依赖不存在，检查本地缓存 `/tmp/cc-maven-cache-kimi{N}/`
3. 如果都不存在，从远程仓库下载

**写入流程**:
1. 新依赖先下载到本地缓存 `/tmp/cc-maven-cache-kimi{N}/`
2. 后台任务定期合并到共享目录
3. 或使用符号链接指向共享目录

**优势**:
- 避免并发写入冲突
- 实现简单，无需分布式锁
- 本地缓存作为缓冲区

### 3.2 备选方案：文件锁机制

```bash
# 写入前获取锁
flock /home/ubuntu/.m2/repository.lock -c "mvn dependency:resolve"
```

**适用场景**:
- 需要实时更新共享仓库
- 后台依赖同步任务

### 3.3 环境变量配置

```bash
# 在run-cc.sh中注入
export MAVEN_OPTS="-Dmaven.repo.local=/home/ubuntu/.m2/repository"
export PNPM_STORE_PATH="/home/ubuntu/.pnpm-store"

# 本地缓存路径（各kimi不同）
export LOCAL_MAVEN_CACHE="/tmp/cc-maven-cache-${KIMI_TAG}"
```

## 4. 实施步骤

### Step 1: 创建共享目录
```bash
mkdir -p /home/ubuntu/.m2/repository
mkdir -p /home/ubuntu/.pnpm-store
chown -R ubuntu:ubuntu /home/ubuntu/.m2 /home/ubuntu/.pnpm-store
```

### Step 2: 创建各kimi产物目录
```bash
for i in $(seq 1 20); do
    mkdir -p /apps/wande-ai-backend-kimi${i}
    mkdir -p /apps/wande-ai-front-kimi${i}
    chown ubuntu:ubuntu /apps/wande-ai-backend-kimi${i} /apps/wande-ai-front-kimi${i}
done
```

### Step 3: 修改run-cc.sh注入环境变量
```bash
# 在run-cc.sh中添加上述export语句
```

### Step 4: 验证缓存命中率
```bash
# 观察maven下载日志，检查"Downloaded from"出现频率
# 预期：首次后应大幅减少
```

## 5. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| I/O竞争 | 20个CC同时读取共享目录 | 使用SSD，监控I/O负载 |
| 磁盘空间不足 | 共享仓库无限增长 | 定期清理未使用依赖 |
| 权限问题 | 无法写入共享目录 | 统一使用ubuntu用户 |
| 缓存失效 | 代码更新后缓存未刷新 | 版本号变化自动失效 |

---
**设计完成时间**: Day 2
**负责人**: 排程经理
