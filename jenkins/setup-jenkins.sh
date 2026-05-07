#!/bin/bash
# Jenkins 初始化配置脚本
# 用法: bash setup-jenkins.sh

set -e

JENKINS_URL="http://localhost:8080/jenkins"
JENKINS_USER="admin"
JENKINS_PASS=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

echo "=== Jenkins 初始化配置 ==="

# 等待 Jenkins 就绪
echo "等待 Jenkins 就绪..."
for i in {1..30}; do
    if curl -s "${JENKINS_URL}/api/json" > /dev/null 2>&1; then
        echo "Jenkins 已就绪"
        break
    fi
    sleep 2
done

# 获取 crumb
echo "获取 CSRF token..."
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" "${JENKINS_URL}/crumbIssuer/api/json" | jq -r '.crumb')
CRUMB_FIELD=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" "${JENKINS_URL}/crumbIssuer/api/json" | jq -r '.crumbRequestField')

# 创建 GitHub Bot Token 凭证
echo "创建 GitHub 凭证..."
BOT_TOKEN=$(cat /home/ubuntu/projects/.github/scripts/tokens/bot.token 2>/dev/null || echo "")
WEIPING_TOKEN=$(cat /home/ubuntu/projects/.github/scripts/tokens/weiping.pat 2>/dev/null || echo "")

curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
    -H "${CRUMB_FIELD}: ${CRUMB}" \
    -X POST "${JENKINS_URL}/credentials/store/system/domain/_/createCredentials" \
    --data-urlencode "json={
        \"credentials\": {
            \"scope\": \"GLOBAL\",
            \"id\": \"github-bot-token\",
            \"username\": \"wandeyaowu\",
            \"password\": \"${BOT_TOKEN}\",
            \"description\": \"GitHub Bot Token\"
        }
    }"

# 创建 Pipeline Job
echo "创建 Pipeline Job..."
curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
    -H "${CRUMB_FIELD}: ${CRUMB}" \
    -X POST "${JENKINS_URL}/createItem?name=wande-play-pr" \
    -H "Content-Type: application/xml" \
    --data '<?xml version="1.0" encoding="UTF-8"?>
<project>
    <description>Wande-Play PR Pipeline</description>
    <keepDependencies>false</keepDependencies>
    <properties>
        <org.jenkinsci.plugins.workflow.multibranch.BranchSourceProperty>
            <source class="org.jenkinsci.plugins.github_branch_source.GitHubSCMSource">
                <id>wande-play</id>
                <credentialsId>github-bot-token</credentialsId>
                <repoOwner>WnadeyaowuOraganization</repoOwner>
                <repository>wande-play</repository>
            </source>
        </org.jenkinsci.plugins.workflow.multibranch.BranchSourceProperty>
    </properties>
    <builders>
        <org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition>
            <script>
pipeline {
    agent any
    stages {
        stage("Test") {
            steps {
                echo "Hello World"
            }
        }
    }
}
            </script>
        </org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition>
    </builders>
</project>'

echo "=== Jenkins 配置完成 ==="
echo "访问 http://localhost:8080/jenkins 配置 GitHub Webhook"
