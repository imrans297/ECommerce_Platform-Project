#!/bin/bash

echo "🔧 Deploying Jenkins to EKS Cluster"

# Check if kubectl is configured
kubectl cluster-info > /dev/null 2>&1 || { echo "kubectl not configured. Exiting."; exit 1; }

# Create Jenkins namespace
echo "🏗️  Creating Jenkins namespace..."
kubectl create namespace jenkins --dry-run=client -o yaml | kubectl apply -f -

# Add Jenkins Helm repository
echo "📦 Adding Jenkins Helm repository..."
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create Jenkins values file
echo "📝 Creating Jenkins configuration..."
cat > /tmp/jenkins-values.yaml <<EOF
controller:
  image: "jenkins/jenkins"
  tag: "2.414.1-lts"
  adminUser: "admin"
  adminPassword: "admin123"
  
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
      
  serviceType: LoadBalancer
  
  installPlugins:
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.0.0
    - configuration-as-code:1670.v564dc8b_982d0
    - docker-workflow:563.vd5d2e5c4007f
    - pipeline-stage-view:2.25
    - aws-credentials:191.vcb_f183ce58b_9
    - amazon-ecr:1.7
    - kubernetes-cli:1.12.1
    - slack:631.v40deea_40323b
    - datadog:5.4.1
    
  JCasC:
    defaultConfig: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Welcome to Jenkins for E-commerce Platform!"
        
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - aws:
                      accessKey: "\${AWS_ACCESS_KEY_ID}"
                      secretKey: "\${AWS_SECRET_ACCESS_KEY}"
                      description: "AWS Credentials"
                      id: "aws-credentials"
                      scope: GLOBAL
                      
        unclassified:
          location:
            url: "http://jenkins.ecommerce.local/"
            
          slackNotifier:
            teamDomain: "your-team"
            token: "your-slack-token"
            
agent:
  enabled: true
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"

persistence:
  enabled: true
  size: "20Gi"
  storageClass: "gp2"
EOF

# Deploy Jenkins
echo "🚀 Deploying Jenkins..."
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --values /tmp/jenkins-values.yaml \
  --wait --timeout=600s

echo "⏳ Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/jenkins -n jenkins

# Get Jenkins URL
echo "🔍 Getting Jenkins access information..."
JENKINS_URL=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "✅ Jenkins deployed successfully!"
echo ""
echo "🔗 Access Jenkins:"
echo "URL: http://${JENKINS_URL}:8080"
echo "Username: admin"
echo "Password: admin123"
echo ""
echo "📋 Next steps:"
echo "1. Access Jenkins UI"
echo "2. Configure AWS credentials"
echo "3. Create pipeline jobs"
echo "4. Set up webhooks"

# Clean up
rm -f /tmp/jenkins-values.yaml