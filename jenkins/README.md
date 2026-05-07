# Jenkins 迁移指南

## 当前状态

- Jenkins 已安装在 m7i 服务器
- 访问地址: http://localhost:8080/jenkins
- 初始密码: `5efd84ca8e254709b2824a60e4a71b3c`

## 需要手动完成的步骤

### 1. 首次登录 Jenkins

1. 打开 http://localhost:8080/jenkins
2. 输入初始密码: `5efd84ca8e254709b2824a60e4a71b3c`
3. 点击 "Install suggested plugins"
4. 创建管理员用户

### 2. 安装必要插件

在 Jenkins > Manage Jenkins > Manage Plugins:
- Git
- Pipeline
- GitHub Integration
- Email Extension
- Groovy

### 3. 配置 GitHub 凭证

1. Jenkins > Credentials > System > Global credentials
2. 添加两个凭证:
   - ID: `github-bot-token` - GitHub Bot 的 PAT (用于提交PR)
   - ID: `github-weiping-token` - Weiping 的 PAT (用于合并PR)

### 4. 创建 Pipeline

1. 新建 Item > Pipeline
2. Name: `wande-play-pr`
3. 选择 "Pipeline script from SCM"
4. SCM: Git
5. Repository: https://github.com/WnadeyaowuOraganization/wande-play
6. Script Path: `jenkins/Jenkinsfile`
7. 添加 GitHub credentials

### 5. 配置 GitHub Webhook

1. GitHub > Settings > Webhooks > Add webhook
2. Payload URL: `http://<m7i-ip>:8080/jenkins/github-webhook/`
3. Content type: `application/json`
4. Events: Pull requests
5. Secret: (生成一个secret)

### 6. 将初始化脚本复制到 Jenkins

```bash
sudo cp init.groovy.d/01-init.groovy /var/lib/jenkins/init.groovy.d/
sudo systemctl restart jenkins
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `Jenkinsfile` | 主流水线脚本 |
| `github-webhook-trigger.sh` | Webhook 触发脚本 |
| `setup-jenkins.sh` | 自动化配置脚本 |
| `init.groovy.d/01-init.groovy` | 初始化凭证脚本 |

## 质量门控（6道门）

| 门 | 内容 | 实现 |
|----|------|------|
| 门1 | PR body checkbox | `grep '^- \\[ \\]'` |
| 门2 | task.md checkbox | `grep '^- \\[ \\]'` |
| 门3 | 前端截图 | `grep '!\['` |
| 门4 | smoke 用例存在 | `gh api` 检查文件 |
| 门5 | 无硬编码端口 | `grep 'localhost:710'` |
| 门6 | 使用相对路径 | `grep "http://localhost:"` |

## 故障排除

### 凭证创建失败
```bash
# 手动通过 Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/jenkins/ -auth admin:password \
  create-credentials-by-system \
  "SystemCredentialsProvider::SystemContextResolver::jenkins" \
  "GlobalCredentialsDomain" \
  -impl StringCredentialsImpl \
  id github-bot-token \
  description "GitHub Bot Token"
```

### Webhook 不触发
```bash
# 检查 GitHub webhook 投递日志
# GitHub > Settings > Webhooks > 点击 webhook > Recent Deliveries
```

## 迁移进度

- [x] Jenkins 安装
- [x] Jenkinsfile 编写
- [x] 质量门控脚本
- [ ] Jenkins UI 配置
- [ ] GitHub Webhook 配置
- [ ] 测试 PR 触发
- [ ] 灰度验证
