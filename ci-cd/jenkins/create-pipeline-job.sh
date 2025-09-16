#!/bin/bash

echo "🚀 Creating Jenkins Pipeline Job for E-commerce Platform"

# Jenkins connection details
JENKINS_URL="${JENKINS_URL:-http://localhost:30080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD}"

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be accessible..."
until curl -s -f "$JENKINS_URL/login" > /dev/null; do
    echo "Waiting for Jenkins..."
    sleep 10
done

echo "✅ Jenkins is accessible!"

# Create pipeline job XML configuration
cat > /tmp/pipeline-job.xml <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1316.vd2290d3341a_f">
  <actions/>
  <description>Enterprise E-commerce Platform CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3659.v582dc37621d8">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.0.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/imrans297/ECommerce_Platform-Project.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>ci-cd/jenkins/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Create the pipeline job
echo "📦 Creating pipeline job..."
curl -X POST "$JENKINS_URL/createItem?name=ecommerce-platform-pipeline" \
  --user "$JENKINS_USER:$JENKINS_PASSWORD" \
  --header "Content-Type: application/xml" \
  --data-binary @/tmp/pipeline-job.xml

if [ $? -eq 0 ]; then
    echo "✅ Pipeline job created successfully!"
    echo ""
    echo "🔗 Access your pipeline at:"
    echo "$JENKINS_URL/job/ecommerce-platform-pipeline/"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure GitHub webhook for automatic builds"
    echo "2. Set up AWS credentials in Jenkins"
    echo "3. Configure SonarQube server"
    echo "4. Set up Slack notifications"
    echo "5. Run your first build!"
else
    echo "❌ Failed to create pipeline job"
    exit 1
fi

# Clean up
rm -f /tmp/pipeline-job.xml

echo ""
echo "🎯 Pipeline Features:"
echo "✅ Multi-stage builds (Node.js, Python, Java, Go)"
echo "✅ Code quality analysis (SonarQube)"
echo "✅ Security scanning (OWASP, Trivy, Bandit)"
echo "✅ Docker builds and ECR push"
echo "✅ Kubernetes deployments (Staging/Production)"
echo "✅ Integration and performance testing"
echo "✅ Quality gates and approvals"
echo "✅ Slack notifications"
echo "✅ Blue-green deployment support"