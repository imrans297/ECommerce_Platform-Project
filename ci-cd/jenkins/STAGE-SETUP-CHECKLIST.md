# Pipeline Stage Setup Checklist

## ✅ BEFORE RUNNING PIPELINE

### 1. Jenkins Tools Configuration
Go to: Manage Jenkins → Global Tool Configuration

- [ ] **NodeJS**: Name: `NodeJS-18`, Version: `18.19.0`
- [ ] **Maven**: Name: `Maven-3.9`, Version: `3.9.6`  
- [ ] **SonarQube Scanner**: Name: `SonarQube-Scanner`, Latest version

### 2. Jenkins Credentials Setup
Go to: Manage Jenkins → Manage Credentials → System → Global

- [ ] **aws-access-key** (Secret text): Your AWS Access Key
- [ ] **aws-secret-key** (Secret text): Your AWS Secret Key
- [ ] **sonarqube-token** (Secret text): Generate from SonarQube UI
- [ ] **github-token** (Secret text): GitHub Personal Access Token

### 3. SonarQube Configuration
Go to: Manage Jenkins → Configure System → SonarQube servers

- [ ] **Name**: `SonarQube`
- [ ] **Server URL**: `http://ae4a917fa6ef1499ea8319779cf5b4bf-571257061.us-east-1.elb.amazonaws.com:9000`
- [ ] **Server authentication token**: `sonarqube-token`

### 4. Required Files in Repository
Ensure these files exist in your repo:

- [ ] `applications/user-service/package.json` (with test scripts)
- [ ] `applications/product-service/requirements.txt`
- [ ] `applications/order-service/pom.xml`
- [ ] `applications/notification-service/go.mod`
- [ ] `tests/integration/ecommerce-api-tests.json` (Postman collection)
- [ ] `tests/performance/load-test.js` (K6 script)
- [ ] `kubernetes/manifests/staging/` (staging manifests)
- [ ] `kubernetes/manifests/production/` (production manifests)

## 🔧 STAGE-BY-STAGE TROUBLESHOOTING

### Stage 1: Checkout & Setup
**Common Issues**:
- Git credentials not configured
- Repository URL incorrect

**Fix**:
```bash
# Test git access
git clone https://github.com/imrans297/ECommerce_Platform-Project.git
```

### Stage 2: Code Quality & Security
**Common Issues**:
- SonarQube server not accessible
- OWASP dependency check fails
- Trivy installation issues

**Fix**:
```bash
# Test SonarQube connection
curl -u admin:admin http://ae4a917fa6ef1499ea8319779cf5b4bf-571257061.us-east-1.elb.amazonaws.com:9000/api/system/status

# Install tools manually if needed
apt-get update && apt-get install -y wget unzip
```

### Stage 3: Build & Test Services
**Common Issues**:
- Missing package.json scripts
- Python/Java dependencies not found
- Go module issues

**Fix**:
```bash
# Check if files exist
ls applications/user-service/package.json
ls applications/product-service/requirements.txt
ls applications/order-service/pom.xml
ls applications/notification-service/go.mod
```

### Stage 4: Docker Build & Security Scan
**Common Issues**:
- Dockerfile not found
- Docker daemon not accessible
- Trivy not installed

**Fix**:
```bash
# Test Docker
docker --version
docker ps

# Check Dockerfiles
ls applications/*/Dockerfile
```

### Stage 5: Push to ECR & Nexus
**Common Issues**:
- AWS credentials not configured
- ECR repositories don't exist
- Nexus not accessible

**Fix**:
```bash
# Test AWS access
aws sts get-caller-identity

# Create ECR repositories
aws ecr create-repository --repository-name user-service
aws ecr create-repository --repository-name product-service
aws ecr create-repository --repository-name order-service
aws ecr create-repository --repository-name notification-service

# Test Nexus
curl -u admin:admin123 http://a46ac20f3e2a74d41a0b01368d1f826b-101476107.us-east-1.elb.amazonaws.com:8081/
```

### Stage 6: Quality Gate
**Common Issues**:
- SonarQube quality gate not configured
- Timeout issues

**Fix**:
- Configure quality gate in SonarQube UI
- Increase timeout if needed

### Stage 7: Deploy to Staging
**Common Issues**:
- Kubernetes manifests not found
- kubectl not configured
- Staging namespace doesn't exist

**Fix**:
```bash
# Test kubectl
kubectl get nodes

# Create staging namespace
kubectl create namespace staging

# Check manifests
ls kubernetes/manifests/staging/
```

### Stage 8: Integration Tests
**Common Issues**:
- Newman not installed
- Postman collection not found
- API endpoints not accessible

**Fix**:
```bash
# Install Newman
npm install -g newman

# Test API endpoints
curl http://staging-api-url/health
```

### Stage 9: Performance Tests
**Common Issues**:
- K6 not installed
- Performance test script not found

**Fix**:
```bash
# Download K6
wget https://github.com/grafana/k6/releases/download/v0.45.0/k6-v0.45.0-linux-amd64.tar.gz
tar -xzf k6-v0.45.0-linux-amd64.tar.gz
```

### Stage 10: Production Approval
**Common Issues**:
- Timeout on manual approval
- User permissions

**Fix**:
- Increase timeout
- Ensure user has approval permissions

### Stage 11: Deploy to Production
**Common Issues**:
- Production namespace doesn't exist
- Blue-green deployment issues

**Fix**:
```bash
# Create production namespace
kubectl create namespace production
```

### Stage 12: Notifications
**Common Issues**:
- Slack webhook not configured
- Email server not configured

**Fix**:
- Configure Slack webhook URL
- Set up email server settings

## 🚀 QUICK START PIPELINE
If you want to test quickly, use this minimal version first:

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                echo 'Pipeline is working!'
                sh 'kubectl get nodes'
                sh 'docker --version'
            }
        }
    }
}
```

Then gradually add stages one by one!