// Groovy script to create credentials
// Run via: curl -X POST http://localhost:8080/jenkins/scriptText --data-urlencode "script=<this-script>"

import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*

// Read tokens from files
def weipingTokenFile = new File('/opt/wande-ai/tokens/weiping.pat')
def weipingToken = weipingTokenFile.text.trim()

// Get credentials store
def store = CredentialsProvider.lookupStores(jenkins.model.Jenkins.instance).first()

// Create Weiping credentials
def weipingCredentials = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-weiping-token",
    "GitHub Weiping PAT",
    hudson.util.Secret.fromString(weipingToken)
)

try {
    store.addCredentials(Domains.GLOBAL, weipingCredentials)
    println "✅ Weiping Token credentials created successfully"
} catch (Exception e) {
    println "⚠️ Error: " + e.message
}

// List existing credentials
println "\nExisting credentials:"
store.credentials.each { c ->
    println "  - ${c.id}: ${c.description}"
}
