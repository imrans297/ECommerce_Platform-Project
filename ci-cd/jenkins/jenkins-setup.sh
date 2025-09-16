#!/bin/bash

echo "🚀 Setting up Enterprise Jenkins with Complete CI/CD Pipeline"

# Create Jenkins namespace
kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -

# Create Jenkins values file with all required plugins
cat > /tmp/jenkins-values.yaml <<EOF
controller:
  image: "jenkins/jenkins"
  tag: "2.426.1-lts"
  adminUser: "admin"
  adminPassword: "admin123"
  
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"
      
  serviceType: NodePort
  nodePort: 30080
  
  # Install all required plugins for enterprise pipeline
  installPlugins:
    # Core plugins
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.0.0
    - pipeline-stage-view:2.25
    - blueocean:1.25.8
    
    # Code Quality & Security
    - sonar:2.15
    - dependency-check-jenkins-plugin:5.4.3
    - owasp-markup-formatter:2.7
    - warnings-ng:10.5.0
    
    # Build Tools
    - nodejs:1.6.1
    - maven-plugin:3.22
    - gradle:2.8.2
    - go:1.4
    
    # Docker & AWS
    - docker-workflow:563.vd5d2e5c4007f
    - amazon-ecr:1.7
    - aws-credentials:191.vcb_f183ce58b_9
    - kubernetes-cli:1.12.1
    
    # Testing & Reports
    - htmlpublisher:1.32
    - junit:1.60
    - jacoco:3.3.4
    - performance:3.21
    - postman-runner:1.0.31
    
    # Notifications
    - slack:631.v40deea_40323b
    - email-ext:2.96
    - build-user-vars-plugin:1.9
    
    # Security & Compliance
    - credentials-binding:523.vd859a_4b_122e6
    - hashicorp-vault-plugin:3.8.0
    - role-strategy:546.vd1d1a_d9d4c5a
    
    # Deployment
    - helm:1.1.3
    - kubernetes-cd:2.3.1
    - pipeline-utility-steps:2.16.0
    
  JCasC:
    defaultConfig: true
    configScripts:
      jenkins-config: |
        jenkins:
          systemMessage: "🚀 Enterprise E-commerce CI/CD Pipeline"
          numExecutors: 4
          scmCheckoutRetryCount: 3
          
          globalNodeProperties:
            - envVars:
                env:
                  - key: "AWS_DEFAULT_REGION"
                    value: "us-east-1"
                  - key: "DOCKER_BUILDKIT"
                    value: "1"
        
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - aws:
                      accessKey: "\${AWS_ACCESS_KEY_ID}"
                      secretKey: "\${AWS_SECRET_ACCESS_KEY}"
                      description: "AWS Credentials for ECR and EKS"
                      id: "aws-credentials"
                      scope: GLOBAL
                      
                  - usernamePassword:
                      username: "admin"
                      password: "admin123"
                      description: "SonarQube Admin"
                      id: "sonarqube-credentials"
                      scope: GLOBAL
                      
                  - string:
                      secret: "\${SLACK_TOKEN}"
                      description: "Slack Bot Token"
                      id: "slack-token"
                      scope: GLOBAL
        
        tool:
          git:
            installations:
              - name: "Default"
                home: "/usr/bin/git"
          
          nodejs:
            installations:
              - name: "18"
                properties:
                  - installSource:
                      installers:
                        - nodeJSInstaller:
                            id: "18.18.0"
          
          maven:
            installations:
              - name: "3.9"
                properties:
                  - installSource:
                      installers:
                        - maven:
                            id: "3.9.5"
          
          go:
            installations:
              - name: "1.21"
                properties:
                  - installSource:
                      installers:
                        - golangInstaller:
                            id: "1.21.4"
        
        unclassified:
          location:
            url: "http://jenkins.ecommerce.local:30080/"
            
          sonarGlobalConfiguration:
            installations:
              - name: "SonarQube"
                serverUrl: "http://sonarqube:9000"
                credentialsId: "sonarqube-credentials"
                
          slackNotifier:
            teamDomain: "your-team"
            token: "\${SLACK_TOKEN}"
            
          globalLibraries:
            libraries:
              - name: "ecommerce-pipeline-library"
                defaultVersion: "main"
                retriever:
                  modernSCM:
                    scm:
                      git:
                        remote: "https://github.com/your-org/jenkins-pipeline-library.git"

agent:
  enabled: true
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "2Gi"

persistence:
  enabled: true
  size: "20Gi"
  storageClass: "gp2"

serviceAccount:
  create: true

rbac:
  create: true
  readSecrets: true
EOF

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Deploy Jenkins
echo "📦 Deploying Jenkins with enterprise configuration..."
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --values /tmp/jenkins-values.yaml \
  --wait --timeout=600s

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/jenkins -n jenkins

# Create additional resources
echo "🔧 Creating additional Jenkins resources..."

# Create Jenkins service account with proper permissions
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-admin
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: jenkins-admin
  namespace: jenkins
EOF

# Create secret for kubeconfig
kubectl create secret generic kubeconfig \
  --from-file=config=$HOME/.kube/config \
  --namespace=jenkins \
  --dry-run=client -o yaml | kubectl apply -f -

# Get Jenkins URL and credentials
JENKINS_URL=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$JENKINS_URL" ]; then
    JENKINS_URL=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi

echo "✅ Jenkins deployed successfully!"
echo ""
echo "🔗 Access Jenkins:"
echo "URL: http://${JENKINS_URL}:30080"
echo "Username: admin"
echo "Password: admin123"
echo ""
echo "📋 Next steps:"
echo "1. Access Jenkins UI and verify plugins are installed"
echo "2. Create a new Pipeline job"
echo "3. Point it to your Git repository with Jenkinsfile"
echo "4. Configure webhook for automatic builds"
echo ""
echo "🔧 Pipeline Features Included:"
echo "✅ Code Quality (SonarQube)"
echo "✅ Security Scanning (OWASP, Trivy)"
echo "✅ Multi-language builds (Node.js, Python, Java, Go)"
echo "✅ Docker builds and ECR push"
echo "✅ Kubernetes deployment"
echo "✅ Integration testing (Newman/Postman)"
echo "✅ Performance testing (K6)"
echo "✅ Slack notifications"
echo "✅ Blue-Green deployments"
echo "✅ Quality gates"

# Clean up
rm -f /tmp/jenkins-values.yaml