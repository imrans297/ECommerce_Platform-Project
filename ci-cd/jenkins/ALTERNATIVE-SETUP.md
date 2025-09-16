# Alternative Jenkins Setup (If CSRF Issues Persist)

## OPTION 1: Use Pipeline Script Directly
Instead of SCM, use "Pipeline script" and paste this minimal pipeline:

```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '535537926657.dkr.ecr.us-east-1.amazonaws.com'
        CLUSTER_NAME = 'ecommerce-platform-dev-eks'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/imrans297/ECommerce_Platform-Project.git'
            }
        }
        
        stage('Build User Service') {
            steps {
                dir('applications/user-service') {
                    sh '''
                        npm install
                        npm test
                        npm run build
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                        cd applications/user-service
                        docker build -t user-service:${BUILD_NUMBER} .
                        echo "Docker image built successfully"
                    '''
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                sh '''
                    kubectl get pods -n ecommerce
                    echo "Deployment would happen here"
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}
```

## OPTION 2: Manual Credential Setup via CLI
If UI doesn't work, use Jenkins CLI:

1. Download Jenkins CLI:
```bash
wget http://ae689dcfdd27f4d1c96353b6876122a8-1933858496.us-east-1.elb.amazonaws.com:8080/jnlpJars/jenkins-cli.jar
```

2. Create credentials XML files and import via CLI

## OPTION 3: Environment Variables in Pipeline
Use environment variables directly in pipeline instead of credentials:

```groovy
environment {
    AWS_ACCESS_KEY_ID = 'your-access-key'
    AWS_SECRET_ACCESS_KEY = 'your-secret-key'
    GITHUB_TOKEN = 'your-github-token'
}
```

## OPTION 4: Restart Jenkins Pod
```bash
kubectl delete pod -n jenkins -l app=jenkins
# Wait for new pod to start
kubectl get pods -n jenkins
```

Then try accessing Jenkins UI again - CSRF should be disabled.

## QUICK TEST PIPELINE
Create this simple pipeline first to test:

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                echo 'Hello from Jenkins!'
                sh 'kubectl get nodes'
                sh 'docker --version'
            }
        }
    }
}
```