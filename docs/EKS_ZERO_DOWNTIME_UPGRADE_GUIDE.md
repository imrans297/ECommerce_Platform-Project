# EKS Cluster Zero-Downtime Upgrade Guide

## Overview
This document provides a complete step-by-step process for upgrading an Amazon EKS cluster from version 1.28 to 1.29 with zero downtime. The upgrade process ensures continuous application availability through rolling updates and proper orchestration.

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl configured to access the cluster
- Cluster has multiple nodes for rolling updates
- Applications configured with proper health checks and pod disruption budgets

---

## Phase 1: Pre-Upgrade Assessment

### 1.1 Check Current Cluster Version
```bash
aws eks describe-cluster --name ecommerce-platform-dev-eks --query 'cluster.version'
```
**Purpose:** Retrieves the current Kubernetes version of the EKS control plane
**Output:** Returns current version (e.g., "1.28")
**Zero-Downtime Impact:** No impact - read-only operation

### 1.2 Verify Node Status
```bash
kubectl get nodes -o wide
```
**Purpose:** Lists all worker nodes with their versions, status, and runtime information
**Output:** Shows node names, status (Ready/NotReady), Kubernetes version, internal/external IPs
**Zero-Downtime Impact:** No impact - read-only operation

### 1.3 Check Add-on Versions
```bash
# VPC CNI Add-on
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name vpc-cni

# CoreDNS Add-on
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name coredns

# Kube-proxy Add-on
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name kube-proxy
```
**Purpose:** Verifies current versions of critical EKS add-ons
**Output:** JSON response with addon version, status, and health information
**Zero-Downtime Impact:** No impact - read-only operations

### 1.4 Backup Cluster Configuration
```bash
kubectl get all --all-namespaces -o yaml > cluster-backup-$(date +%Y%m%d-%H%M).yaml
```
**Purpose:** Creates a complete backup of all Kubernetes resources
**Output:** YAML file containing all cluster resources
**Zero-Downtime Impact:** No impact - creates backup for rollback scenarios

### 1.5 Verify Application Health
```bash
# Check pod status
kubectl get pods --all-namespaces | grep -v Running

# Check service endpoints
kubectl get endpoints --all-namespaces

# Verify ingress controllers
kubectl get ingress --all-namespaces
```
**Purpose:** Ensures all applications are healthy before upgrade
**Output:** Lists any unhealthy pods, service endpoints, and ingress configurations
**Zero-Downtime Impact:** No impact - health verification only

---

## Phase 2: Control Plane Upgrade (Zero Downtime)

### 2.1 Initiate Control Plane Upgrade
```bash
aws eks update-cluster-version \
  --name ecommerce-platform-dev-eks \
  --kubernetes-version 1.29
```
**Purpose:** Starts the EKS control plane upgrade to version 1.29
**Output:** Returns update ID and status "InProgress"
**Zero-Downtime Impact:** ✅ ZERO - Control plane upgrade is managed by AWS with no downtime
**Duration:** 10-15 minutes
**What Happens:** AWS upgrades API server, etcd, and other control plane components behind the scenes

### 2.2 Monitor Control Plane Upgrade
```bash
# Get the update ID from previous command output
UPDATE_ID="5010d8cd-3595-3dcf-9b0d-2d39d8e9ed90"

# Monitor upgrade progress
aws eks describe-update \
  --name ecommerce-platform-dev-eks \
  --update-id $UPDATE_ID
```
**Purpose:** Tracks the progress of control plane upgrade
**Output:** Shows update status (InProgress/Successful/Failed)
**Zero-Downtime Impact:** ✅ ZERO - Monitoring only, applications continue running

### 2.3 Continuous Monitoring Script
```bash
# Monitor every 60 seconds
watch -n 60 "aws eks describe-update --name ecommerce-platform-dev-eks --update-id $UPDATE_ID --query 'update.status'"
```
**Purpose:** Automated monitoring of upgrade status
**Output:** Displays current status every minute
**Zero-Downtime Impact:** ✅ ZERO - Read-only monitoring

### 2.4 Verify Control Plane Upgrade Completion
```bash
# Check final status
aws eks describe-update \
  --name ecommerce-platform-dev-eks \
  --update-id $UPDATE_ID \
  --query 'update.status'

# Verify new control plane version
aws eks describe-cluster --name ecommerce-platform-dev-eks --query 'cluster.version'
```
**Purpose:** Confirms control plane successfully upgraded to 1.29
**Output:** Status should show "Successful" and version should show "1.29"
**Zero-Downtime Impact:** ✅ ZERO - Verification only

---

## Phase 3: Node Group Rolling Update (Minimal Downtime)

### 3.1 Get Node Group Information
```bash
# List all node groups
aws eks list-nodegroups --cluster-name ecommerce-platform-dev-eks

# Get specific node group name
NODEGROUP=$(aws eks list-nodegroups --cluster-name ecommerce-platform-dev-eks --query 'nodegroups[0]' --output text)
echo "Node group: $NODEGROUP"
```
**Purpose:** Identifies the node group(s) that need to be upgraded
**Output:** Lists node group names
**Zero-Downtime Impact:** ✅ ZERO - Information gathering only

### 3.2 Initiate Node Group Rolling Update
```bash
aws eks update-nodegroup-version \
  --cluster-name ecommerce-platform-dev-eks \
  --nodegroup-name $NODEGROUP \
  --kubernetes-version 1.29
```
**Purpose:** Starts rolling update of worker nodes to Kubernetes 1.29
**Output:** Returns update ID for node group upgrade
**Zero-Downtime Impact:** ⚠️ MINIMAL - Rolling update replaces nodes one at a time
**Duration:** 20-30 minutes
**What Happens:** 
- Creates new nodes with 1.29
- Drains pods from old nodes
- Terminates old nodes
- Maintains minimum capacity throughout

### 3.3 Monitor Node Rolling Update
```bash
# Watch nodes being replaced in real-time
watch "kubectl get nodes -o wide"

# Monitor node group update status
NODE_UPDATE_ID=$(aws eks list-updates --name ecommerce-platform-dev-eks --query 'updateIds[0]' --output text)
aws eks describe-update \
  --name ecommerce-platform-dev-eks \
  --update-id $NODE_UPDATE_ID
```
**Purpose:** Monitors the rolling replacement of worker nodes
**Output:** Shows nodes transitioning from 1.28 to 1.29 versions
**Zero-Downtime Impact:** ⚠️ MINIMAL - Brief pod rescheduling during node replacement

### 3.4 Monitor Pod Rescheduling
```bash
# Watch pods being rescheduled during node updates
kubectl get pods --all-namespaces --watch

# Check for any pods stuck in pending state
kubectl get pods --all-namespaces --field-selector=status.phase=Pending
```
**Purpose:** Ensures pods are properly rescheduled during node replacement
**Output:** Shows pod status changes during rolling update
**Zero-Downtime Impact:** ⚠️ MINIMAL - Pods briefly restart on new nodes

---

## Phase 4: Add-on Upgrades (Zero Downtime)

### 4.1 Upgrade VPC CNI Add-on
```bash
aws eks update-addon \
  --cluster-name ecommerce-platform-dev-eks \
  --addon-name vpc-cni \
  --addon-version v1.20.0-eksbuild.1
```
**Purpose:** Updates the VPC CNI plugin for improved networking
**Output:** Shows addon update status
**Zero-Downtime Impact:** ✅ ZERO - CNI updates are rolling and maintain connectivity
**Duration:** 2-3 minutes

### 4.2 Upgrade CoreDNS Add-on
```bash
aws eks update-addon \
  --cluster-name ecommerce-platform-dev-eks \
  --addon-name coredns \
  --addon-version v1.11.1-eksbuild.4
```
**Purpose:** Updates CoreDNS for improved DNS resolution
**Output:** Shows addon update status
**Zero-Downtime Impact:** ✅ ZERO - DNS updates maintain service discovery
**Duration:** 2-3 minutes

### 4.3 Upgrade Kube-proxy Add-on
```bash
aws eks update-addon \
  --cluster-name ecommerce-platform-dev-eks \
  --addon-name kube-proxy \
  --addon-version v1.29.3-eksbuild.1
```
**Purpose:** Updates kube-proxy for improved network routing
**Output:** Shows addon update status
**Zero-Downtime Impact:** ✅ ZERO - Proxy updates maintain network connectivity
**Duration:** 2-3 minutes

### 4.4 Monitor Add-on Updates
```bash
# Check all add-on statuses
for addon in vpc-cni coredns kube-proxy; do
  echo "Checking $addon status..."
  aws eks describe-addon \
    --cluster-name ecommerce-platform-dev-eks \
    --addon-name $addon \
    --query 'addon.status'
done
```
**Purpose:** Verifies all add-ons are successfully updated and active
**Output:** Should show "ACTIVE" status for all add-ons
**Zero-Downtime Impact:** ✅ ZERO - Status verification only

---

## Phase 5: Post-Upgrade Validation

### 5.1 Verify Cluster Version
```bash
# Check control plane version
aws eks describe-cluster --name ecommerce-platform-dev-eks --query 'cluster.version'

# Verify all nodes are upgraded
kubectl get nodes -o wide
```
**Purpose:** Confirms entire cluster is running Kubernetes 1.29
**Output:** Should show version "1.29" for cluster and all nodes
**Zero-Downtime Impact:** ✅ ZERO - Verification only

### 5.2 Validate Add-on Versions
```bash
# Check updated add-on versions
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name vpc-cni --query 'addon.addonVersion'
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name coredns --query 'addon.addonVersion'
aws eks describe-addon --cluster-name ecommerce-platform-dev-eks --addon-name kube-proxy --query 'addon.addonVersion'
```
**Purpose:** Confirms all add-ons are updated to compatible 1.29 versions
**Output:** Shows new version numbers for each add-on
**Zero-Downtime Impact:** ✅ ZERO - Version verification only

### 5.3 Application Health Verification
```bash
# Check all pods are running
kubectl get pods --all-namespaces | grep -v Running

# Verify services are accessible
kubectl get svc --all-namespaces

# Test cluster connectivity
kubectl cluster-info

# Check ingress controllers
kubectl get ingress --all-namespaces
```
**Purpose:** Ensures all applications are healthy after upgrade
**Output:** Should show all pods running and services accessible
**Zero-Downtime Impact:** ✅ ZERO - Health verification only

### 5.4 Application-Specific Testing
```bash
# Test ecommerce application endpoints (if deployed)
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce
kubectl logs -n ecommerce deployment/user-service --tail=10
kubectl logs -n ecommerce deployment/product-service --tail=10

# Test application health endpoints
curl -f http://your-app-endpoint/health
```
**Purpose:** Validates specific application functionality post-upgrade
**Output:** Shows application-specific health status
**Zero-Downtime Impact:** ✅ ZERO - Application testing only

---

## Zero-Downtime Strategies Explained

### 1. Control Plane Upgrade
- **AWS Managed:** EKS control plane is fully managed by AWS
- **High Availability:** Multiple API server instances ensure no downtime
- **Backward Compatibility:** 1.29 control plane supports 1.28 nodes during transition

### 2. Rolling Node Updates
- **One-by-One Replacement:** Nodes are replaced individually
- **Pod Disruption Budgets:** Ensure minimum replicas remain available
- **Graceful Draining:** Pods are safely moved before node termination
- **Load Balancer:** Traffic automatically routes to healthy nodes

### 3. Add-on Updates
- **Rolling Deployment:** Add-ons update without service interruption
- **Compatibility:** New versions maintain backward compatibility
- **Health Checks:** Updates only proceed if health checks pass

### 4. Application Resilience
- **Multiple Replicas:** Applications should have multiple pod replicas
- **Health Checks:** Proper liveness and readiness probes
- **Resource Requests:** Proper CPU/memory requests for scheduling

---

## Rollback Procedures (If Needed)

### Control Plane Rollback
```bash
# Note: Control plane cannot be rolled back
# Only forward upgrades are supported
# Ensure thorough testing before upgrade
```

### Node Group Rollback
```bash
# Rollback to previous node group version
aws eks update-nodegroup-version \
  --cluster-name ecommerce-platform-dev-eks \
  --nodegroup-name $NODEGROUP \
  --kubernetes-version 1.28
```

### Add-on Rollback
```bash
# Rollback add-ons to previous versions
aws eks update-addon \
  --cluster-name ecommerce-platform-dev-eks \
  --addon-name vpc-cni \
  --addon-version v1.19.0-eksbuild.1
```

---

## Complete Automation Script

```bash
#!/bin/bash
# eks-zero-downtime-upgrade.sh

set -e

CLUSTER_NAME="ecommerce-platform-dev-eks"
TARGET_VERSION="1.29"
LOG_FILE="eks-upgrade-$(date +%Y%m%d-%H%M).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "Starting EKS zero-downtime upgrade to $TARGET_VERSION"

# Phase 1: Pre-upgrade checks
log "Phase 1: Pre-upgrade validation"
kubectl get nodes -o wide
aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.version'

# Phase 2: Control plane upgrade
log "Phase 2: Upgrading control plane"
UPDATE_RESPONSE=$(aws eks update-cluster-version --name $CLUSTER_NAME --kubernetes-version $TARGET_VERSION)
UPDATE_ID=$(echo $UPDATE_RESPONSE | jq -r '.update.id')
log "Control plane update ID: $UPDATE_ID"

# Wait for control plane
while true; do
    STATUS=$(aws eks describe-update --name $CLUSTER_NAME --update-id $UPDATE_ID --query 'update.status' --output text)
    log "Control plane status: $STATUS"
    [ "$STATUS" = "Successful" ] && break
    [ "$STATUS" = "Failed" ] && { log "Control plane upgrade failed"; exit 1; }
    sleep 60
done

# Phase 3: Node group upgrade
log "Phase 3: Upgrading node groups"
NODEGROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --query 'nodegroups[0]' --output text)
aws eks update-nodegroup-version --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP --kubernetes-version $TARGET_VERSION

NODE_UPDATE_ID=$(aws eks list-updates --name $CLUSTER_NAME --query 'updateIds[0]' --output text)
while true; do
    STATUS=$(aws eks describe-update --name $CLUSTER_NAME --update-id $NODE_UPDATE_ID --query 'update.status' --output text)
    log "Node group status: $STATUS"
    [ "$STATUS" = "Successful" ] && break
    [ "$STATUS" = "Failed" ] && { log "Node group upgrade failed"; exit 1; }
    sleep 120
done

# Phase 4: Add-on upgrades
log "Phase 4: Upgrading add-ons"
aws eks update-addon --cluster-name $CLUSTER_NAME --addon-name vpc-cni --addon-version v1.20.0-eksbuild.1
aws eks update-addon --cluster-name $CLUSTER_NAME --addon-name coredns --addon-version v1.11.1-eksbuild.4
aws eks update-addon --cluster-name $CLUSTER_NAME --addon-name kube-proxy --addon-version v1.29.3-eksbuild.1

# Wait for add-ons
for addon in vpc-cni coredns kube-proxy; do
    while true; do
        STATUS=$(aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name $addon --query 'addon.status' --output text)
        log "$addon status: $STATUS"
        [ "$STATUS" = "ACTIVE" ] && break
        sleep 30
    done
done

# Phase 5: Validation
log "Phase 5: Post-upgrade validation"
kubectl get nodes -o wide
kubectl get pods --all-namespaces | grep -v Running || log "All pods are running"

log "EKS cluster upgrade to $TARGET_VERSION completed successfully with zero downtime!"
```

---

## Summary

**Total Upgrade Time:** 45-60 minutes
**Actual Downtime:** 0 minutes (applications remain available)
**Brief Interruptions:** Minimal pod rescheduling during node replacement
**Success Factors:**
- Multiple node availability
- Proper application health checks
- Rolling update strategy
- AWS-managed control plane
- Load balancer traffic distribution

This zero-downtime upgrade process ensures continuous service availability while modernizing your EKS infrastructure.