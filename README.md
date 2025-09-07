# 🏥 MediSupply - Medical Supply Chain Management Platform

> A cloud-native microservices platform for managing medical supply chains with advanced inventory tracking, regulatory compliance, and distribution logistics.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/Istio-466BB0?style=flat&logo=istio&logoColor=white)](https://istio.io/)
[![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://gateway-api.sigs.k8s.io/)

## 📋 Overview

MediSupply is a comprehensive microservices-based platform designed to manage complex medical supply chains. It provides real-time inventory tracking, regulatory compliance monitoring, and optimized distribution logistics across multiple distribution centers.

### 🏗️ Architecture

The platform follows a domain-driven microservices architecture with services organized across multiple namespaces for better isolation and management:

```
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌────────────────────┐
│ commerce-     │ │ inventories-  │ │ logistics-    │ │ regulatory-health- │
│ sales         │ │ storage       │ │ distributions │ │ compliance         │
├───────────────┤ ├───────────────┤ ├───────────────┤ ├────────────────────┤
│ • Sales       │ │ • Batches     │ │ • Trips       │ │ • Regulations      │
│   Service     │ │ • Distribution│ │ • Vehicles    │ │ • Alerts           │
│               │ │   Centers     │ │               │ │                    │
└───────────────┘ └───────────────┘ └───────────────┘ └────────────────────┘
```

### 🔧 Services & Namespaces

| Namespace                        | Service              | Description                                 | API Endpoint                   | Port |
|----------------------------------|----------------------|---------------------------------------------|--------------------------------|------|
| **commerce-sales**               | Sales                | Handle sales transactions and orders        | `/api/v1/sales`                | 3000 |
| **inventories-storage**          | Batches              | Track product batches and expiration dates  | `/api/v1/batches`              | 3000 |
| **inventories-storage**          | Distribution Centers | Manage warehouse operations and inventory   | `/api/v1/distribution-centers` | 3000 |
| **logistics-distributions**      | Trips                | Coordinate logistics and delivery schedules | `/api/v1/trips`                | 3000 |
| **logistics-distributions**      | Vehicles             | Manage fleet and vehicle assignments        | `/api/v1/vehicles`             | 3000 |
| **regulatory-health-compliance** | Alerts               | Monitor critical events and notifications   | `/api/v1/alerts`               | 3000 |
| **regulatory-health-compliance** | Regulations          | Ensure compliance with health regulations   | `/api/v1/regulations`          | 3000 |

### 🚀 Key Features
 
- 📦 **Real-time Inventory Management** - Track medical supplies across multiple locations
- 🔄 **Batch Tracking** - Monitor expiration dates and batch information
- 🚛 **Logistics Optimization** - Efficient trip planning and delivery coordination
- ⚖️ **Regulatory Compliance** - Automated compliance monitoring and reporting
- 🚨 **Alert System** - Proactive notifications for critical events
- 💰 **Sales Management** - Comprehensive order and transaction processing
- 🔒 **mTLS Security** - End-to-end encryption between all services
- 🎯 **Domain Isolation** - Services organized by business domain in separate namespaces

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

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

**Install Kubectl:**
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows (using Chocolatey)
choco install kubernetes-cli

# Windows (using winget)
winget install -e --id Kubernetes.kubectl
```

**Install Istio CLI:**
```bash
# macOS
brew install istioctl

# Linux/Windows
curl -L https://istio.io/downloadIstio | sh -
# Add istioctl to your PATH
```

### Step 2: Install Istio Service into Your Kubernetes Cluster

```bash
# Install Istio with default profile
istioctl install --set profile=default --set values.global.platform=gke -y

# Verify Istio installation
istioctl verify-install
```

### Step 3: Install Gateway API CRDs

```bash
# Install Kubernetes Gateway API Custom Resource Definitions
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { 
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; 
}
```

### Step 4: Include .env.aws credentials file

To handle DynamoDB connection, create a `.env.aws` file in the common/aws-credentials folder:

```
medisupply-manifests/
├─ gateway.yaml
├─ namespaces.yaml
├─ common/
│  └─ aws-creds/
│     ├─ kustomization.yaml
│     └─ .env.aws  ------>  # contains AWS credentials
└─ commerce-sales/
   └─ ...
```   
With the following content:

```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=your_aws_region
```

verify your namespace can access the credentials:

```bash
kubectl -n namespace_name get secret aws-creds
kubectl -n namespace_name describe secret aws-creds
```

### Step 5: Create and Configure Namespaces

```bash
# Apply namespace configuration with Istio injection enabled
kubectl label namespace default istio-injection=enabled
kubectl apply -f namespaces.yaml
```
> Note: The `namespaces.yaml` file contains the namespace definitions for the services.
> The default namespace is used for the Istio ingress gateway. The other namespaces are used for the services.

### Step 6: Deploy MediSupply Services

```bash
# Deploy Commerce Sales domain services
kubectl apply -k commerce-sales/

# Deploy Inventories Storage domain services
kubectl apply -k inventories-storage/

# Deploy Logistics Distributions domain services
kubectl apply -k logistics-distributions/

# Deploy Regulatory Health Compliance domain services
kubectl apply -k regulatory-health-compliance/
```
### Step 7: Deploy MediSupply Gateway

```bash
kubectl apply -f gateway.yaml -n default
```

### Step 8: Change the services type to ClusterIP by annotating the gateway

```bash
kubectl annotate gateway medisupply-gateway networking.istio.io/service-type=ClusterIP --namespace=default
```


### Step 9: Verify Deployment

**Check all pods are running:**
```bash
# Check pods in all namespaces
kubectl get pods -n commerce-sales
kubectl get pods -n inventories-storage
kubectl get pods -n logistics-distributions
kubectl get pods -n regulatory-health-compliance
```

**Verify services are accessible:**
```bash
# List services across all namespaces
kubectl get svc -A | grep -E "commerce-sales|inventories-storage|logistics-distributions|regulatory-health-compliance"
```

**Check Gateway and HTTPRoute status:**
```bash
# Check gateways
kubectl get gateway -A

# Check HTTP routes
kubectl get httproute -A
```


### Step 10: Access the Application

**Port Forwarding**
```bash
kubectl port-forward svc/medisupply-gateway-istio 8080:80 -n default
```

## 🔧 Configuration

### Cross-Namespace Communication

Services communicate across namespaces using Fully Qualified Domain Names (FQDNs):

```yaml
# Example: Sales service calling Distribution Centers
env:
  - name: CENTRO_MS_URL
    value: "http://distribution-centers.inventories-storage.svc.cluster.local:3000"
```

### Environment Variables

Each service can be configured using environment variables. Common configurations include:

- Database connection strings
- External API endpoints
- Service discovery URLs (using FQDNs for cross-namespace)
- Logging levels
- Cache configurations

### Scaling Services

```bash
# Scale a specific service
kubectl scale deployment sales-v1 --replicas=3 -n commerce-sales

# Auto-scale based on CPU usage
kubectl autoscale deployment batches-v1 --cpu-percent=70 --min=1 --max=10 -n inventories-storage
```

## 📊 API Documentation

Once deployed, the services expose RESTful APIs:

- **Base URL**: `http://localhost:8080` (with port-forward)
- **API Version**: `v1`
- **Format**: JSON

### Example API Calls

```bash
# Commerce Sales
curl http://localhost:8080/api/v1/sales

# Inventories Storage 
curl http://localhost:8080/api/v1/batches
curl http://localhost:8080/api/v1/distribution-centers

# Logistics Distributions
curl http://localhost:8080/api/v1/trips

# Regulatory Health Compliance
curl http://localhost:8080/api/v1/alerts
curl http://localhost:8080/api/v1/regulations
```

## 🔍 Monitoring and Observability

MediSupply includes built-in observability through Istio's telemetry features:

### Access Observability Tools

**Install Kiali, Grafana, Prometheus and Jaeger addons:**
```bash
# Install kiali addon
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/kiali.yaml

# Install grafana addon
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/grafana.yaml

# Install Prometheus addon
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/prometheus.yaml

# Install Jaeger addon
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/jaeger.yaml

# Wait for all deployments to be ready
kubectl rollout status deployment/kiali -n istio-system
```

```bash
# Kiali (Service Mesh Visualization)
istioctl dashboard kiali

# Grafana (Metrics Dashboard)
istioctl dashboard grafana

# Prometheus (Metrics Dashboard)
istioctl dashboard prometheus

# Jaeger (Distributed Tracing)
istioctl dashboard jaeger
```

### Health Checks

```bash
# Monitor pods across all namespaces
watch kubectl get pods -A | grep -E "commerce-sales|inventories-storage|logistics-distributions|regulatory-health-compliance"

# View logs for a specific service
kubectl logs -f deployment/sales-v1 -n commerce-sales
kubectl logs -f deployment/batches-v1 -n inventories-storage

# Check Istio proxy logs
kubectl logs deployment/sales-v1 -c istio-proxy -n commerce-sales
```

## 🔧 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -c istio-proxy -n <namespace>
```

**Cross-namespace communication issues:**
```bash
# Verify DNS resolution
kubectl exec -it deployment/sales-v1 -n commerce-sales -- nslookup distribution-centers.inventories-storage.svc.cluster.local

# Test connectivity
kubectl exec -it deployment/sales-v1 -n commerce-sales -- curl -v http://distribution-centers.inventories-storage.svc.cluster.local:3000/health

# Check mTLS status
istioctl authn tls-check $(kubectl get pod -l app=sales -n commerce-sales -o jsonpath={.items[0].metadata.name}).commerce-sales distribution-centers.inventories-storage.svc.cluster.local
```

**Gateway not accessible:**
```bash
# Check gateway status
kubectl get gateway -A -o wide
kubectl describe gateway <gateway-name> -n <namespace>

# Check HTTPRoute configuration
kubectl describe httproute <route-name> -n <namespace>

# Verify Istio ingress gateway
kubectl get svc -n istio-system
```

**Service mesh issues:**
```bash
# Analyze Istio configuration
istioctl analyze -A

# Check proxy configuration
istioctl proxy-config cluster <pod-name> -n <namespace>

# Verify sidecar injection
kubectl get pods -n <namespace> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

### Namespace-Specific Debugging

```bash
# Debug commerce-sales namespace
istioctl analyze -n commerce-sales
kubectl get all -n commerce-sales

# Debug inventories-storage namespace  
istioctl analyze -n inventories-storage
kubectl get all -n inventories-storage

# Debug logistics-distributions namespace
istioctl analyze -n logistics-distributions
kubectl get all -n logistics-distributions

# Debug regulatory-health-compliance namespace
istioctl analyze -n regulatory-health-compliance
kubectl get all -n regulatory-health-compliance
```

## 🏛️ Architecture Benefits

### Multi-Namespace Architecture Advantages

1. **Domain Isolation**: Each business domain operates in its own namespace
2. **Security Boundaries**: Network policies and RBAC can be applied per namespace
3. **Resource Management**: Resource quotas and limits per domain
4. **Team Autonomy**: Different teams can manage their own namespaces
5. **Fault Isolation**: Issues in one namespace don't affect others
6. **Compliance**: Easier to implement regulatory requirements per domain

## 🔐 Security Best Practices

1. **Always use FQDNs** for cross-namespace communication
2. **Enable strict mTLS** for all service-to-service communication
3. **Apply NetworkPolicies** to restrict traffic between namespaces
4. **Use RBAC** to control access to namespace resources
5. **Implement PodSecurityPolicies** or PodSecurityStandards
6. **Regular certificate rotation** (handled automatically by Istio)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE]() file for details.
