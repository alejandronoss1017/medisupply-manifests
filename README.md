# 🏥 MediSupply - Medical Supply Chain Management Platform

> A cloud-native microservices platform for managing medical supply chains with advanced inventory tracking, regulatory compliance, and distribution logistics.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/Istio-466BB0?style=flat&logo=istio&logoColor=white)](https://istio.io/)
[![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://gateway-api.sigs.k8s.io/)

## 📋 Overview

MediSupply is a comprehensive microservices-based platform designed to manage complex medical supply chains. It provides real-time inventory tracking, regulatory compliance monitoring, and optimized distribution logistics across multiple distribution centers.

### 🏗️ Architecture

The platform follows a microservices architecture with the following core services:

```
┌──────────────────────────────────────────────────────┐
│                    Istio Gateway                     │
│                 (medisupply-gateway)                 │
└─────────────────────────┬────────────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           │              │              │
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   Sales     │ │   Batches   │ │ Distribution│
    │  Service    │ │  Service    │ │   Centers   │
    └─────────────┘ └─────────────┘ └─────────────┘
           │              │              │
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   Trips     │ │   Alerts    │ │ Regulations │
    │  Service    │ │  Service    │ │   Service   │
    └─────────────┘ └─────────────┘ └─────────────┘
```

### 🔧 Services

| Service | Description | API Endpoint | Port |
|---------|-------------|--------------|------|
| **Sales** | Handle sales transactions and orders | `/api/v1/sales` | 3000 |
| **Batches** | Track product batches and expiration dates | `/api/v1/batches` | 3000 |
| **Distribution Centers** | Manage warehouse operations and inventory | `/api/v1/distribution-centers` | 3000 |
| **Trips** | Coordinate logistics and delivery schedules | `/api/v1/trips` | 3000 |
| **Alerts** | Monitor critical events and notifications | `/api/v1/alerts` | 3000 |
| **Regulations** | Ensure compliance with health regulations | `/api/v1/regulations` | 3000 |

### 🚀 Key Features

- 📦 **Real-time Inventory Management** - Track medical supplies across multiple locations
- 🔄 **Batch Tracking** - Monitor expiration dates and batch information
- 🚛 **Logistics Optimization** - Efficient trip planning and delivery coordination
- ⚖️ **Regulatory Compliance** - Automated compliance monitoring and reporting
- 🚨 **Alert System** - Proactive notifications for critical events
- 💰 **Sales Management** - Comprehensive order and transaction processing

## 📋 Prerequisites

Before installing MediSupply, ensure you have the following tools installed:

- [Kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes command-line tool
- [Istioctl](https://istio.io/latest/docs/setup/install/) - Istio service mesh CLI
- A Kubernetes cluster (local or cloud-based)

### Supported Kubernetes Distributions

- ✅ **Local Development**: [Minikube](https://minikube.sigs.k8s.io/docs/start/), [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/), [Docker Desktop](https://docs.docker.com/desktop/kubernetes/)
- ✅ **Cloud Providers**: GKE, EKS, AKS
- ✅ **On-Premises**: Vanilla Kubernetes, OpenShift

## 🚀 Installation

Follow these steps to deploy MediSupply to your Kubernetes cluster:

### Step 1: Install Required Tools

**Install Kubectl:**
```bash
brew install kubectl
```

**Install Istio CLI:**
```bash
brew install istioctl
```

### Step 2: Prepare Your Kubernetes Cluster

**Create and configure the namespace:**
```bash
# Create the medisupply namespace
kubectl create namespace medisupply

# Enable Istio sidecar injection
kubectl label namespace medisupply istio-injection=enabled
```

### Step 3: Install Istio Service Mesh

```bash
# Install Istio with default profile
istioctl install --set profile=default --set values.global.platform=gke -y
```

### Step 4: Install Gateway API CRDs

```bash
# Install Kubernetes Gateway API Custom Resource Definitions
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { 
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; 
}
```

### Step 5: Deploy MediSupply Services

**Deploy all microservices:**
```bash
# Deploy all services to the medisupply namespace
kubectl apply -f inventories-storage/ -n medisupply
kubectl apply -f commerce-sales/ -n medisupply
kubectl apply -f logistics-distributions/ -n medisupply
kubectl apply -f regulatory-health-compliance/ -n medisupply
```

**Deploy the Gateway configuration:**
```bash
kubectl apply -f gateway.yaml -n medisupply
```

**Change the service type to ClusterIP by annotating the gateway:** 
```bash
kubectl annotate gateway medisupply-gateway networking.istio.io/service-type=ClusterIP --namespace=medisupply
```

### Step 6: Verify Deployment

**Check all pods are running:**
```bash
kubectl get pods -n medisupply
```

**Verify services are accessible:**
```bash
kubectl get svc -n medisupply
```

**Check Gateway and HTTPRoute status:**
```bash
kubectl get gateway,httproute -n medisupply
```

### Step 7: Access the Application

**Port Forwarding**
```bash
# Forward traffic to access the services locally
kubectl port-forward svc/medisupply-gateway-istio 8080:80
```

## 🔧 Configuration

### Environment Variables

Each service can be configured using environment variables. Common configurations include:

- Database connection strings
- External API endpoints
- Logging levels
- Cache configurations

### Scaling Services

```bash
# Scale a specific service
kubectl scale deployment sales-v1 --replicas=3 -n medisupply

# Auto-scale based on CPU usage
kubectl autoscale deployment sales-v1 --cpu-percent=70 --min=1 --max=10 -n medisupply
```

## 📊 API Documentation

Once deployed, the services expose RESTful APIs:

- **Base URL**: `http://localhost:8080` (with port-forward)
- **API Version**: `v1`
- **Format**: JSON

### Example API Calls

```bash
# Get all sales
curl http://localhost:8080/api/v1/sales

# Get batch information
curl http://localhost:8080/api/v1/batches

# Get distribution centers
curl http://localhost:8080/api/v1/distribution-centers
```

## 🔍 Monitoring and Observability

MediSupply includes built-in observability through Istio's telemetry features:

### Access Observability Tools

```bash
# Kiali (Service Mesh Visualization)
istioctl dashboard kiali

# Grafana (Metrics Dashboard)
istioctl dashboard grafana

# Jaeger (Distributed Tracing)
istioctl dashboard jaeger
```

### Health Checks

```bash
# Check service health
kubectl get pods -n medisupply -w

# View service logs
kubectl logs -f deployment/sales-v1 -n medisupply
```

## 🔧 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n medisupply
kubectl logs <pod-name> -n medisupply
```

**Gateway not accessible:**
```bash
kubectl get gateway -n medisupply -o yaml
kubectl describe httproute medisupply -n medisupply
```

**Service mesh issues:**
```bash
istioctl proxy-config cluster <pod-name> -n medisupply
istioctl analyze -n medisupply
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE]() file for details.
