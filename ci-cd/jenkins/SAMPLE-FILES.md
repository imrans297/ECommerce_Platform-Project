# Sample Files for Complete Pipeline

## 📁 REQUIRED FILES IN YOUR GITHUB REPOSITORY

### 1. Package.json for User Service
**File**: `applications/user-service/package.json`
```json
{
  "name": "user-service",
  "version": "1.0.0",
  "description": "User management microservice",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/",
    "build": "echo 'Build completed'"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "jest": "^29.6.2",
    "nodemon": "^3.0.1",
    "eslint": "^8.47.0"
  }
}
```

### 2. Requirements.txt for Product Service
**File**: `applications/product-service/requirements.txt`
```txt
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-JWT-Extended==4.5.2
psycopg2-binary==2.9.7
redis==4.6.0
pytest==7.4.0
pytest-cov==4.1.0
flake8==6.0.0
bandit==1.7.5
```

### 3. Pom.xml for Order Service
**File**: `applications/order-service/pom.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.ecommerce</groupId>
    <artifactId>order-service</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.2</version>
        <relativePath/>
    </parent>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.8</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### 4. Go.mod for Notification Service
**File**: `applications/notification-service/go.mod`
```go
module notification-service

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/go-redis/redis/v8 v8.11.5
    github.com/lib/pq v1.10.9
    github.com/stretchr/testify v1.8.4
)

require (
    github.com/bytedance/sonic v1.9.1 // indirect
    github.com/cespare/xxhash/v2 v2.1.2 // indirect
    github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
    github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
    github.com/gabriel-vasile/mimetype v1.4.2 // indirect
    github.com/gin-contrib/sse v0.1.0 // indirect
    github.com/go-playground/locales v0.14.1 // indirect
    github.com/go-playground/universal-translator v0.18.1 // indirect
    github.com/go-playground/validator/v10 v10.14.0 // indirect
    github.com/goccy/go-json v0.10.2 // indirect
    github.com/json-iterator/go v1.1.12 // indirect
    github.com/klauspost/cpuid/v2 v2.2.4 // indirect
    github.com/leodido/go-urn v1.2.4 // indirect
    github.com/mattn/go-isatty v0.0.19 // indirect
    github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
    github.com/modern-go/reflect2 v1.0.2 // indirect
    github.com/pelletier/go-toml/v2 v2.0.8 // indirect
    github.com/twitchyliquid64/golang-asm v0.15.1 // indirect
    github.com/ugorji/go/codec v1.2.11 // indirect
    golang.org/x/arch v0.3.0 // indirect
    golang.org/x/crypto v0.9.0 // indirect
    golang.org/x/net v0.10.0 // indirect
    golang.org/x/sys v0.8.0 // indirect
    golang.org/x/text v0.9.0 // indirect
    google.golang.org/protobuf v1.30.0 // indirect
    gopkg.in/yaml.v3 v3.0.1 // indirect
)
```

### 5. Dockerfiles for All Services

**File**: `applications/user-service/Dockerfile`
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**File**: `applications/product-service/Dockerfile`
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

**File**: `applications/order-service/Dockerfile`
```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

**File**: `applications/notification-service/Dockerfile`
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o notification-service

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/notification-service .
EXPOSE 9000
CMD ["./notification-service"]
```

### 6. Kubernetes Manifests

**File**: `kubernetes/manifests/staging/user-service.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: 535537926657.dkr.ecr.us-east-1.amazonaws.com/user-service:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: staging
spec:
  selector:
    app: user-service
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

### 7. Test Files

**File**: `tests/integration/ecommerce-api-tests.json`
```json
{
  "info": {
    "name": "E-commerce API Tests",
    "description": "Integration tests for e-commerce platform"
  },
  "item": [
    {
      "name": "Health Check - User Service",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/health",
          "host": ["{{base_url}}"],
          "path": ["health"]
        }
      },
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status code is 200', function () {",
              "    pm.response.to.have.status(200);",
              "});"
            ]
          }
        }
      ]
    }
  ]
}
```

**File**: `tests/integration/staging-environment.json`
```json
{
  "id": "staging-env",
  "name": "Staging Environment",
  "values": [
    {
      "key": "base_url",
      "value": "http://user-service.staging.svc.cluster.local:3000",
      "enabled": true
    }
  ]
}
```

**File**: `tests/performance/load-test.js`
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
};

export default function () {
  let response = http.get('http://user-service.staging.svc.cluster.local:3000/health');
  check(response, { 'status was 200': (r) => r.status == 200 });
  sleep(1);
}
```

### 8. Sample Application Code

**File**: `applications/user-service/src/index.js`
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'user-service' });
});

app.get('/users', (req, res) => {
  res.json({ users: [] });
});

app.listen(port, () => {
  console.log(`User service listening on port ${port}`);
});

module.exports = app;
```

**File**: `applications/product-service/app.py`
```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'product-service'})

@app.route('/products')
def products():
    return jsonify({'products': []})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

## 📋 CHECKLIST: Files to Create

- [ ] `applications/user-service/package.json`
- [ ] `applications/user-service/Dockerfile`
- [ ] `applications/user-service/src/index.js`
- [ ] `applications/product-service/requirements.txt`
- [ ] `applications/product-service/Dockerfile`
- [ ] `applications/product-service/app.py`
- [ ] `applications/order-service/pom.xml`
- [ ] `applications/order-service/Dockerfile`
- [ ] `applications/notification-service/go.mod`
- [ ] `applications/notification-service/Dockerfile`
- [ ] `kubernetes/manifests/staging/user-service.yaml`
- [ ] `kubernetes/manifests/staging/product-service.yaml`
- [ ] `kubernetes/manifests/staging/order-service.yaml`
- [ ] `kubernetes/manifests/staging/notification-service.yaml`
- [ ] `kubernetes/manifests/production/` (copy from staging)
- [ ] `tests/integration/ecommerce-api-tests.json`
- [ ] `tests/integration/staging-environment.json`
- [ ] `tests/performance/load-test.js`
- [ ] `ci-cd/jenkins/Jenkinsfile`

Create these files in your GitHub repository to enable the complete pipeline! 🚀