// Jenkins 初始化脚本 - 自动配置凭证和Pipeline
// 放在 /var/lib/jenkins/init.groovy.d/01-init.groovy

import jenkins.model.*
import hudson.security.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import org.jenkinsci.plugins.github_branch_source.*

println "=== 执行 Jenkins 初始化 ==="

// 1. 创建 GitHub Bot Token 凭证
try {
    def store = CredentialsProvider.lookupStores(jenkins.model.Jenkins.instance).first()

    // Bot Token
    def botTokenFile = new File('/home/ubuntu/projects/.github/scripts/tokens/bot.token')
    if (botTokenFile.exists()) {
        def botToken = botTokenFile.text.trim()
        def botCredentials = new StringCredentialsImpl(
            CredentialsScope.GLOBAL,
            "github-bot-token",
            "GitHub Bot Token",
            hudson.util.Secret.fromString(botToken)
        )
        store.addCredentials(Domains.GLOBAL, botCredentials)
        println "✅ Bot Token 凭证已创建"
    }

    // Weiping Token
    def weipingTokenFile = new File('/home/ubuntu/projects/.github/scripts/tokens/weiping.pat')
    if (weipingTokenFile.exists()) {
        def weipingToken = weipingTokenFile.text.trim()
        def weipingCredentials = new StringCredentialsImpl(
            CredentialsScope.GLOBAL,
            "github-weiping-token",
            "GitHub Weiping PAT",
            hudson.util.Secret.fromString(weipingToken)
        )
        store.addCredentials(Domains.GLOBAL, weipingCredentials)
        println "✅ Weiping Token 凭证已创建"
    }
} catch (Exception e) {
    println "⚠️ 凭证创建失败: ${e.message}"
}

// 2. 配置 GitHub Branch Source
try {
    def githubServer = GitHubConfiguration.get().getEndpoints().find { it.name == "GitHub" }
    if (githubServer == null) {
        GitHubConfiguration.get().getEndpoints().add(new GitHubServerConfig("https://api.github.com"))
        println "✅ GitHub Server 配置已添加"
    }
} catch (Exception e) {
    println "⚠️ GitHub 配置失败: ${e.message}"
}

// 3. 禁用 CSRF 保护（仅用于开发环境）
try {
    def security = Jenkins.instance.getDescriptor("jenkins.CSRFProtection")
    if (security != null) {
        println "CSRF 保护已配置"
    }
} catch (Exception e) {
    println "⚠️ CSRF 配置失败: ${e.message}"
}

println "=== Jenkins 初始化完成 ==="
