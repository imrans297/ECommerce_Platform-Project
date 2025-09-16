#!/bin/bash

echo "🚀 Setting up ArgoCD for GitOps Deployment"

# Create ArgoCD namespace
kubectl create namespace argocd1 --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl apply -n argocd1 -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd1

# Patch ArgoCD server service to use NodePort
kubectl patch svc argocd-server -n argocd1 -p '{"spec":{"type":"LoadBalancer"}}'

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd1 get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Get ArgoCD LoadBalancer URL
echo "⏳ Waiting for LoadBalancer to get external IP..."
ARGOCD_URL=""
for i in {1..30}; do
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd1 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ ! -z "$ARGOCD_URL" ]; then
        break
    fi
    echo "Waiting for LoadBalancer... ($i/30)"
    sleep 10
done

# Create Git repository secret for your GitHub repo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ecommerce-repo
  namespace: argocd1
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/imrans297/ECommerce_Platform-Project.git
  username: imrans297
  password: ghp_your_github_token_here
EOF

# Create ArgoCD Project
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ecommerce
  namespace: argocd1
spec:
  description: E-commerce Platform Project
  
  sourceRepos:
  - 'https://github.com/imrans297/ECommerce_Platform-Project.git'
  - 'https://charts.helm.sh/stable'
  - 'https://prometheus-community.github.io/helm-charts'
  
  destinations:
  - namespace: 'ecommerce'
    server: https://kubernetes.default.svc
  - namespace: 'staging'
    server: https://kubernetes.default.svc
  - namespace: 'production'
    server: https://kubernetes.default.svc
  - namespace: 'monitoring'
    server: https://kubernetes.default.svc
    
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRole
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRoleBinding
    
  namespaceResourceWhitelist:
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  - group: ''
    kind: Service
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: StatefulSet
  - group: 'networking.k8s.io'
    kind: Ingress
  
  roles:
  - name: admin
    description: Admin role for ecommerce project
    policies:
    - p, proj:ecommerce:admin, applications, *, ecommerce/*, allow
    - p, proj:ecommerce:admin, repositories, *, *, allow
    groups:
    - ecommerce:admin
EOF

# Create Development Application (from your current repo)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-dev
  namespace: argocd1
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: ecommerce
  
  source:
    repoURL: https://github.com/imrans297/ECommerce_Platform-Project.git
    targetRevision: main
    path: kubernetes/manifests
    
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce
    
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
        
  revisionHistoryLimit: 10
EOF

# Create Staging Application
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-staging
  namespace: argocd1
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: ecommerce
  
  source:
    repoURL: https://github.com/imrans297/ECommerce_Platform-Project.git
    targetRevision: develop
    path: kubernetes/manifests
    
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
    
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
        
  revisionHistoryLimit: 10
EOF

# Create Production Application (Manual sync)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-production
  namespace: argocd1
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: ecommerce
  
  source:
    repoURL: https://github.com/imrans297/ECommerce_Platform-Project.git
    targetRevision: main
    path: kubernetes/manifests
    
  destination:
    server: https://kubernetes.default.svc
    namespace: production
    
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    # Manual sync for production
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
        
  revisionHistoryLimit: 10
EOF

# Install ArgoCD CLI
echo "🔧 Installing ArgoCD CLI..."
curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
rm /tmp/argocd-linux-amd64

echo "✅ ArgoCD setup completed successfully!"
echo ""
echo "🔗 Access ArgoCD:"
if [ ! -z "$ARGOCD_URL" ]; then
    echo "URL: https://${ARGOCD_URL}"
else
    echo "URL: Use 'kubectl get svc argocd-server -n argocd1' to get LoadBalancer URL"
fi
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"
echo ""
echo "🔧 ArgoCD CLI Login:"
if [ ! -z "$ARGOCD_URL" ]; then
    echo "argocd login ${ARGOCD_URL} --username admin --password ${ARGOCD_PASSWORD} --insecure"
else
    echo "argocd login <LOADBALANCER_URL> --username admin --password ${ARGOCD_PASSWORD} --insecure"
fi
echo ""
echo "📋 Applications Created:"
echo "✅ ecommerce-dev (Auto-sync from main branch)"
echo "✅ ecommerce-staging (Auto-sync from develop branch)"
echo "✅ ecommerce-production (Manual sync from main branch)"
echo ""
echo "🚀 Next Steps:"
echo "1. Create GitHub Personal Access Token"
echo "2. Update the repository secret with your token"
echo "3. Push Kubernetes manifests to your repo"
echo "4. ArgoCD will automatically deploy your applications"
echo ""
echo "📝 Update Repository Secret:"
echo "kubectl patch secret ecommerce-repo -n argocd1 -p '{\"stringData\":{\"password\":\"YOUR_GITHUB_TOKEN\"}}'"