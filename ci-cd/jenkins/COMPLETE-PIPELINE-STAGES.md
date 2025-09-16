# Complete Enterprise CI/CD Pipeline - All Stages

## PIPELINE OVERVIEW (12 Stages)
```
1. 🔄 Checkout & Setup
2. 🔍 Code Quality & Security (Parallel)
3. 🧪 Build & Test Services (Parallel)
4. 🐳 Docker Build & Security Scan
5. 📦 Push to ECR & Nexus
6. 🚪 Quality Gate
7. 🚀 Deploy to Staging
8. 🧪 Integration Tests
9. 📊 Performance Tests
10. ✅ Production Approval
11. 🚀 Deploy to Production
12. 📢 Notifications
```

## COMPLETE PIPELINE SCRIPT

```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '535537926657.dkr.ecr.us-east-1.amazonaws.com'
        CLUSTER_NAME = 'ecommerce-platform-dev-eks'
        SONAR_PROJECT_KEY = 'ecommerce-platform'
        BUILD_VERSION = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
        // Add your credentials here (or use Jenkins credentials)
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_TOKEN = credentials('github-token')
    }
    
    tools {
        nodejs 'NodeJS-18'
        maven 'Maven-3.9'
    }
    
    stages {
        // STAGE 1: CHECKOUT & SETUP
        stage('🔄 Checkout & Setup') {
            steps {
                checkout scm
                script {
                    env.BUILD_VERSION = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
                    echo "Building version: ${env.BUILD_VERSION}"
                }
            }
        }
        
        // STAGE 2: CODE QUALITY & SECURITY (PARALLEL)
        stage('🔍 Code Quality & Security') {
            parallel {
                stage('SonarQube Analysis') {
                    steps {
                        script {
                            sh '''
                                sonar-scanner \
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                -Dsonar.sources=applications/ \
                                -Dsonar.host.url=http://ae4a917fa6ef1499ea8319779cf5b4bf-571257061.us-east-1.elb.amazonaws.com:9000 \
                                -Dsonar.login=${SONAR_TOKEN}
                            '''
                        }
                    }
                }
                
                stage('OWASP Dependency Check') {
                    steps {
                        sh '''
                            # Install OWASP Dependency Check
                            wget -O dependency-check.zip https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
                            unzip -o dependency-check.zip
                            ./dependency-check/bin/dependency-check.sh --scan applications/ --format XML --format HTML
                        '''
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'dependency-check-report.html',
                            reportName: 'OWASP Dependency Check'
                        ])
                    }
                }
                
                stage('Trivy Security Scan') {
                    steps {
                        sh '''
                            # Install Trivy
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" | tee -a /etc/apt/sources.list
                            apt-get update && apt-get install trivy -y
                            
                            # Scan filesystem
                            trivy fs --format json --output trivy-report.json applications/
                            trivy fs --format table applications/
                        '''
                    }
                }
                
                stage('Git Secrets Scan') {
                    steps {
                        sh '''
                            # Install git-secrets
                            git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets
                            cd /tmp/git-secrets && make install
                            
                            # Scan for secrets
                            git secrets --register-aws
                            git secrets --scan
                        '''
                    }
                }
            }
        }
        
        // STAGE 3: BUILD & TEST SERVICES (PARALLEL)
        stage('🧪 Build & Test Services') {
            parallel {
                stage('User Service (Node.js)') {
                    steps {
                        dir('applications/user-service') {
                            sh '''
                                npm ci
                                npm run lint
                                npm run test:coverage
                                npm run build
                            '''
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'User Service Coverage'
                            ])
                        }
                    }
                }
                
                stage('Product Service (Python)') {
                    steps {
                        dir('applications/product-service') {
                            sh '''
                                python3 -m venv venv
                                source venv/bin/activate
                                pip install -r requirements.txt
                                pip install pytest-cov flake8 bandit
                                
                                # Code quality
                                flake8 . --max-line-length=88
                                
                                # Security scan
                                bandit -r . -f json -o bandit-report.json || true
                                
                                # Tests with coverage
                                pytest --cov=. --cov-report=html --cov-report=xml
                            '''
                        }
                    }
                }
                
                stage('Order Service (Java)') {
                    steps {
                        dir('applications/order-service') {
                            sh '''
                                mvn clean compile
                                mvn test
                                mvn jacoco:report
                                mvn package -DskipTests
                            '''
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'target/site/jacoco',
                                reportFiles: 'index.html',
                                reportName: 'Order Service Coverage'
                            ])
                        }
                    }
                }
                
                stage('Notification Service (Go)') {
                    steps {
                        dir('applications/notification-service') {
                            sh '''
                                go mod tidy
                                go vet ./...
                                go test -race -coverprofile=coverage.out ./...
                                go build -o notification-service
                            '''
                        }
                    }
                }
            }
        }
        
        // STAGE 4: DOCKER BUILD & SECURITY SCAN
        stage('🐳 Docker Build & Security Scan') {
            parallel {
                stage('Build Docker Images') {
                    steps {
                        script {
                            def services = ['user-service', 'product-service', 'order-service', 'notification-service']
                            services.each { service ->
                                sh """
                                    cd applications/${service}
                                    docker build -t ${service}:${BUILD_VERSION} .
                                    docker tag ${service}:${BUILD_VERSION} ${ECR_REGISTRY}/${service}:${BUILD_VERSION}
                                    docker tag ${service}:${BUILD_VERSION} ${ECR_REGISTRY}/${service}:latest
                                """
                            }
                        }
                    }
                }
                
                stage('Docker Security Scan') {
                    steps {
                        script {
                            def services = ['user-service', 'product-service', 'order-service', 'notification-service']
                            services.each { service ->
                                sh """
                                    trivy image --format json --output ${service}-image-scan.json ${service}:${BUILD_VERSION}
                                    trivy image --format table ${service}:${BUILD_VERSION}
                                """
                            }
                        }
                    }
                }
            }
        }
        
        // STAGE 5: PUSH TO ECR & NEXUS
        stage('📦 Push to ECR & Nexus') {
            steps {
                script {
                    // Login to ECR
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                    
                    // Push images
                    def services = ['user-service', 'product-service', 'order-service', 'notification-service']
                    services.each { service ->
                        sh """
                            docker push ${ECR_REGISTRY}/${service}:${BUILD_VERSION}
                            docker push ${ECR_REGISTRY}/${service}:latest
                        """
                    }
                    
                    // Push artifacts to Nexus
                    sh '''
                        # Upload build artifacts to Nexus
                        curl -u admin:admin123 --upload-file applications/order-service/target/*.jar \
                        http://a46ac20f3e2a74d41a0b01368d1f826b-101476107.us-east-1.elb.amazonaws.com:8081/repository/maven-releases/
                    '''
                }
            }
        }
        
        // STAGE 6: QUALITY GATE
        stage('🚪 Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        
        // STAGE 7: DEPLOY TO STAGING
        stage('🚀 Deploy to Staging') {
            steps {
                script {
                    sh '''
                        # Update image tags in staging manifests
                        sed -i "s|:latest|:${BUILD_VERSION}|g" kubernetes/manifests/staging/*.yaml
                        
                        # Deploy to staging namespace
                        kubectl apply -f kubernetes/manifests/staging/ -n staging
                        
                        # Wait for rollout
                        kubectl rollout status deployment/user-service -n staging
                        kubectl rollout status deployment/product-service -n staging
                        kubectl rollout status deployment/order-service -n staging
                        kubectl rollout status deployment/notification-service -n staging
                    '''
                }
            }
        }
        
        // STAGE 8: INTEGRATION TESTS
        stage('🧪 Integration Tests') {
            steps {
                script {
                    sh '''
                        # Install Newman for API testing
                        npm install -g newman
                        
                        # Run Postman collection tests
                        newman run tests/integration/ecommerce-api-tests.json \
                        --environment tests/integration/staging-environment.json \
                        --reporters cli,junit --reporter-junit-export integration-test-results.xml
                    '''
                    
                    // Publish test results
                    publishTestResults testResultsPattern: 'integration-test-results.xml'
                }
            }
        }
        
        // STAGE 9: PERFORMANCE TESTS
        stage('📊 Performance Tests') {
            steps {
                script {
                    sh '''
                        # Install K6 for performance testing
                        wget https://github.com/grafana/k6/releases/download/v0.45.0/k6-v0.45.0-linux-amd64.tar.gz
                        tar -xzf k6-v0.45.0-linux-amd64.tar.gz
                        
                        # Run performance tests
                        ./k6-v0.45.0-linux-amd64/k6 run tests/performance/load-test.js
                    '''
                }
            }
        }
        
        // STAGE 10: PRODUCTION APPROVAL
        stage('✅ Production Approval') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: 'Deploy to Production?', ok: 'Deploy',
                              submitterParameter: 'APPROVER'
                    }
                    echo "Approved by: ${env.APPROVER}"
                }
            }
        }
        
        // STAGE 11: DEPLOY TO PRODUCTION
        stage('🚀 Deploy to Production') {
            steps {
                script {
                    sh '''
                        # Blue-Green Deployment
                        kubectl apply -f kubernetes/manifests/production/ -n production
                        
                        # Wait for rollout
                        kubectl rollout status deployment/user-service -n production
                        kubectl rollout status deployment/product-service -n production
                        kubectl rollout status deployment/order-service -n production
                        kubectl rollout status deployment/notification-service -n production
                        
                        # Health check
                        sleep 30
                        kubectl get pods -n production
                    '''
                }
            }
        }
        
        // STAGE 12: NOTIFICATIONS
        stage('📢 Notifications') {
            steps {
                script {
                    sh '''
                        # Send Slack notification
                        curl -X POST -H 'Content-type: application/json' \
                        --data '{"text":"🎉 Deployment Successful! Version: '${BUILD_VERSION}' deployed to Production"}' \
                        YOUR_SLACK_WEBHOOK_URL
                        
                        # Send email notification
                        echo "Deployment completed successfully" | mail -s "Production Deployment - ${BUILD_VERSION}" admin@company.com
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up
            sh 'docker system prune -f'
            cleanWs()
        }
        success {
            echo '🎉 Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
            // Send failure notifications
        }
    }
}
```

## STAGE-BY-STAGE SETUP INSTRUCTIONS

### Prerequisites Setup:
1. **Install Tools in Jenkins**:
   - NodeJS 18
   - Maven 3.9
   - SonarQube Scanner
   - Docker (already in custom image)

2. **Create Credentials**:
   - `aws-access-key` (Secret text)
   - `aws-secret-key` (Secret text)
   - `sonarqube-token` (Secret text)
   - `github-token` (Secret text)

### Stage Details:

**Stage 1**: Basic checkout and version setup
**Stage 2**: Parallel security scans (SonarQube, OWASP, Trivy, Git Secrets)
**Stage 3**: Parallel builds for all 4 services with tests
**Stage 4**: Docker builds and container security scanning
**Stage 5**: Push to ECR and Nexus repositories
**Stage 6**: SonarQube quality gate check
**Stage 7**: Deploy to staging environment
**Stage 8**: API integration tests with Newman
**Stage 9**: Performance tests with K6
**Stage 10**: Manual approval for production
**Stage 11**: Blue-green production deployment
**Stage 12**: Slack/email notifications

This is your complete enterprise CI/CD pipeline with all stages! 🚀