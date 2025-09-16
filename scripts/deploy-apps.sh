#!/bin/bash

echo "🚀 Deploying E-commerce Applications to EKS"

# Check if kubectl is configured
kubectl cluster-info > /dev/null 2>&1 || { echo "kubectl not configured. Exiting."; exit 1; }

# Create application namespace
echo "🏗️  Creating application namespace..."
kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -

# Deploy applications using the built Docker images
echo "📦 Deploying applications..."

# User Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: ecommerce
  labels:
    app: user-service
    tags.datadoghq.com/env: "dev"
    tags.datadoghq.com/service: "user-service"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tags.datadoghq.com/env: "dev"
        tags.datadoghq.com/service: "user-service"
    spec:
      containers:
      - name: user-service
        image: user-service:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DD_ENV
          value: "dev"
        - name: DD_SERVICE
          value: "user-service"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: ecommerce
spec:
  selector:
    app: user-service
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF

# Product Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ecommerce
  labels:
    app: product-service
    tags.datadoghq.com/env: "dev"
    tags.datadoghq.com/service: "product-service"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
        tags.datadoghq.com/env: "dev"
        tags.datadoghq.com/service: "product-service"
    spec:
      containers:
      - name: product-service
        image: product-service:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
        env:
        - name: FLASK_ENV
          value: "production"
        - name: DD_ENV
          value: "dev"
        - name: DD_SERVICE
          value: "product-service"
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ecommerce
spec:
  selector:
    app: product-service
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
EOF

# Order Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce
  labels:
    app: order-service
    tags.datadoghq.com/env: "dev"
    tags.datadoghq.com/service: "order-service"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        tags.datadoghq.com/env: "dev"
        tags.datadoghq.com/service: "order-service"
    spec:
      containers:
      - name: order-service
        image: order-service:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: DD_ENV
          value: "dev"
        - name: DD_SERVICE
          value: "order-service"
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce
spec:
  selector:
    app: order-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

# Notification Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: ecommerce
  labels:
    app: notification-service
    tags.datadoghq.com/env: "dev"
    tags.datadoghq.com/service: "notification-service"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
        tags.datadoghq.com/env: "dev"
        tags.datadoghq.com/service: "notification-service"
    spec:
      containers:
      - name: notification-service
        image: notification-service:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 9000
        env:
        - name: GO_ENV
          value: "production"
        - name: DD_ENV
          value: "dev"
        - name: DD_SERVICE
          value: "notification-service"
---
apiVersion: v1
kind: Service
metadata:
  name: notification-service
  namespace: ecommerce
spec:
  selector:
    app: notification-service
  ports:
  - port: 9000
    targetPort: 9000
  type: ClusterIP
EOF

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n ecommerce

echo "✅ Applications deployed successfully!"
echo ""
echo "🔍 Verify deployments:"
echo "kubectl get pods -n ecommerce"
echo "kubectl get svc -n ecommerce"
echo ""
echo "📊 DataDog Dashboard: https://app.datadoghq.com/apm/services"