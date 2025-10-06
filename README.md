# 🏥 MediSupply - Medical Supply Chain Management Platform

> A cloud-native microservices platform for managing medical supply chains with advanced inventory tracking, regulatory compliance, and distribution logistics.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/Istio-466BB0?style=flat&logo=istio&logoColor=white)](https://istio.io/)
[![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://gateway-api.sigs.k8s.io/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?style=flat&logo=rabbitmq&logoColor=white)](https://www.rabbitmq.com/)

## 📑 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Services & Namespaces](#-services--namespaces)
- [Key Features](#-key-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [API Documentation](#-api-documentation)
- [Monitoring and Observability](#-monitoring-and-observability)
- [Troubleshooting](#-troubleshooting)
- [Architecture Benefits](#️-architecture-benefits)
- [Security Best Practices](#-security-best-practices)
- [License](#-license)

## 📋 Overview

MediSupply is a comprehensive microservices-based platform designed to manage complex medical supply chains. It provides real-time inventory tracking, regulatory compliance monitoring, and optimized distribution logistics across multiple distribution centers.

### 🏗️ Architecture

The platform follows a domain-driven microservices architecture with services organized across multiple namespaces for better isolation and management:

```
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌────────────────────┐ ┌──────────────┐
│ commerce-     │ │ inventories-  │ │ logistics-    │ │ regulatory-health- │ │ financial-   │
│ sales         │ │ storage       │ │ distributions │ │ compliance         │ │ billing      │
├───────────────┤ ├───────────────┤ ├───────────────┤ ├────────────────────┤ ├──────────────┤
│ • Sales       │ │ • Batches     │ │ • Trips       │ │ • Regulations      │ │ • Purchases  │
│               │ │ • Distribution│ │ • Vehicles    │ │ • Alerts           │ │ • RabbitMQ   │
│               │ │   Centers     │ │               │ │                    │ │              │
└───────────────┘ └───────────────┘ └───────────────┘ └────────────────────┘ └──────────────┘
```

### 🔧 Services & Namespaces

| Namespace                        | Service              | Description                                  | API Endpoint                   | Port |
|----------------------------------|----------------------|----------------------------------------------|--------------------------------|------|
| **commerce-sales**               | Sales                | Handle sales transactions and orders         | `/api/v1/sales`                | 3000 |
| **inventories-storage**          | Batches              | Track product batches and expiration dates   | `/api/v1/batches`              | 3000 |
| **inventories-storage**          | Distribution Centers | Manage warehouse operations and inventory    | `/api/v1/distribution-centers` | 3000 |
| **logistics-distributions**      | Trips                | Coordinate logistics and delivery schedules  | `/api/v1/trips`                | 3000 |
| **logistics-distributions**      | Vehicles             | Manage fleet and vehicle assignments         | `/api/v1/vehicles`             | 3000 |
| **regulatory-health-compliance** | Alerts               | Monitor critical events and notifications    | `/api/v1/alerts`               | 3000 |
| **regulatory-health-compliance** | Regulations          | Ensure compliance with health regulations    | `/api/v1/regulations`          | 3000 |
| **financial-billing**            | Purchases            | Handle purchase orders and financial billing | `/api/v1/purchases`            | 8080 |
| **financial-billing**            | RabbitMQ             | Message broker for async communication       | N/A (Internal)                 | 5672 |

### 🚀 Key Features
 
- 📦 **Real-time Inventory Management** - Track medical supplies across multiple locations with live updates
- 🔄 **Batch Tracking** - Monitor expiration dates, lot numbers, and batch information for regulatory compliance
- 🚛 **Logistics Optimization** - Efficient trip planning, route optimization, and delivery coordination
- ⚖️ **Regulatory Compliance** - Automated compliance monitoring and reporting for healthcare regulations
- 🚨 **Alert System** - Proactive notifications for critical events (expiration, low stock, compliance issues)
- 💰 **Sales & Billing Management** - Comprehensive order processing, transaction management, and financial billing
- 📨 **Asynchronous Messaging** - RabbitMQ-powered message queues for reliable inter-service communication
- 🔒 **mTLS Security** - End-to-end encryption between all services via Istio service mesh
- 🎯 **Domain Isolation** - Services organized by business domain in separate namespaces for security and scalability
- 📊 **Distributed Tracing** - Full observability with Jaeger, Kiali, Grafana, and Prometheus integration

## 📋 Prerequisites

Before installing MediSupply, ensure you have the following tools and requirements:

### Required Tools

| Tool                                                    | Minimum Version | Purpose                           |
|---------------------------------------------------------|-----------------|-----------------------------------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/)      | 1.28+           | Kubernetes command-line interface |
| [istioctl](https://istio.io/latest/docs/setup/install/) | 1.27+           | Istio service mesh CLI            |
| Kubernetes Cluster                                      | 1.28+           | Container orchestration platform  |

### Cloud Requirements (Optional)

- **AWS Account** - Required for DynamoDB integration (with valid credentials)
- **Container Registry Access** - For pulling microservice images

### Supported Kubernetes Distributions

- ✅ **Local Development**: [Minikube](https://minikube.sigs.k8s.io/docs/start/), [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/), [Docker Desktop](https://docs.docker.com/desktop/kubernetes/)
- ✅ **Cloud Providers**: Google GKE, AWS EKS, Azure AKS
- ✅ **On-Premises**: Vanilla Kubernetes, Red Hat OpenShift

## ⚡ Quick Start

For experienced users with kubectl and istioctl already configured:

```bash
# 1. Install Istio
istioctl install --set profile=default -y

# 2. Install Gateway API CRDs
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -

# 3. Install RabbitMQ Operators
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/latest/download/messaging-topology-operator-with-certmanager.yaml

# 4. Create secrets and AWS credentials (update with your values)
kubectl create secret generic purchases-app-queue-user-credentials --from-literal=username=purchases-app --from-literal=password=supersecret -n financial-billing
kubectl create secret generic invoices-app-queue-user-credentials --from-literal=username=invoices-app --from-literal=password=supersecret -n financial-billing
# Create common/aws-credentials/.env.aws with your AWS credentials

# 5. Deploy namespaces and services
kubectl label namespace default istio-injection=enabled
kubectl apply -f namespaces.yaml
kubectl apply -k commerce-sales/
kubectl apply -k inventories-storage/
kubectl apply -k logistics-distributions/
kubectl apply -k regulatory-health-compliance/
kubectl apply -k financial-billing/

# 6. Deploy Gateway
kubectl apply -f gateway.yaml -n default
kubectl annotate gateway medisupply-gateway networking.istio.io/service-type=ClusterIP --namespace=default

# 7. Access the application
kubectl port-forward svc/medisupply-gateway-istio 8080:80 -n default
```

For detailed step-by-step instructions, see the [Installation](#-installation) section below.

## 🚀 Installation

Follow these steps to deploy MediSupply to your Kubernetes cluster:

### Step 1: Install Required Tools

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
```

### Step 3: Install Gateway API CRDs

```bash
# Install Kubernetes Gateway API Custom Resource Definitions
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { 
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; 
}
```

### Step 4: Install RabbitMQ operators

```bash
# RabbitMQ Operator
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml

# Dependencies for Topology Operator
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.crds.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml

# RabbitMQ Topology Operator
kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/latest/download/messaging-topology-operator-with-certmanager.yaml
```

### Step 5: Create secrets for RabbitMQ users

```bash
kubectl create secret generic purchases-app-queue-user-credentials \
  --from-literal=username=purchases-app \
  --from-literal=password=supersecret \
  -n financial-billing

kubectl create secret generic invoices-app-queue-user-credentials \
  --from-literal=username=invoices-app \
  --from-literal=password=supersecret \
  -n financial-billing
```

> **Note:** These secrets are required for application pods to communicate through the message queue,
> and for accessing the RabbitMQ management UI which will be exposed at `http://localhost:8080/rabbitmq/`.
> 
> **Important:** The URL must have the trailing slash (`/`).

### Step 6: Configure AWS Credentials for DynamoDB

To enable DynamoDB connection, create a `.env.aws` file in the `common/aws-credentials/` folder:

**Directory structure:**
```
medisupply-manifests/
├── gateway.yaml
├── namespaces.yaml
├── common/
│  └── aws-credentials/
│     ├── kustomization.yaml
│     └── .env.aws  # <-- Create this file
└── commerce-sales/
   └── ...
```

**File content (`common/aws-credentials/.env.aws`):**
```bash
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=your_aws_region
```

**Verify credentials are accessible:**
```bash
# Replace <namespace_name> with your target namespace
kubectl -n <namespace_name> get secret aws-creds
kubectl -n <namespace_name> describe secret aws-creds
```

### Step 7: Create and Configure Namespaces

```bash
# Enable Istio sidecar injection for default namespace
kubectl label namespace default istio-injection=enabled

# Create all application namespaces with Istio injection enabled
kubectl apply -f namespaces.yaml
```

> **Note:** The `namespaces.yaml` file creates the following namespaces:
> - `commerce-sales` - Sales transaction services
> - `inventories-storage` - Inventory and warehouse management
> - `logistics-distributions` - Transportation and delivery coordination
> - `regulatory-health-compliance` - Compliance monitoring and alerts
> - `financial-billing` - Financial transactions and message queues
>
> All namespaces have Istio sidecar injection enabled for service mesh functionality.

### Step 8: Deploy MediSupply Services

```bash
# Deploy Commerce Sales domain services
kubectl apply -k commerce-sales/

# Deploy Inventories Storage domain services
kubectl apply -k inventories-storage/

# Deploy Regulatory Health Compliance domain services
kubectl apply -k regulatory-health-compliance/

# Deploy Logistics Distributions domain services
kubectl apply -k logistics-distributions/

# Deploy Financial Billing domain services
kubectl apply -k financial-billing/
```

### Step 9: Deploy MediSupply Gateway

```bash
kubectl apply -f gateway.yaml -n default
```

### Step 10: Change the services type to ClusterIP by annotating the gateway

```bash
kubectl annotate gateway medisupply-gateway networking.istio.io/service-type=ClusterIP --namespace=default
```

### Step 11: Verify Deployment

**Check all pods are running:**
```bash
# Check pods in all application namespaces
kubectl get pods -n commerce-sales
kubectl get pods -n inventories-storage
kubectl get pods -n logistics-distributions
kubectl get pods -n regulatory-health-compliance
kubectl get pods -n financial-billing

# Or check all at once
kubectl get pods -A | grep -E "commerce-sales|inventories-storage|logistics-distributions|regulatory-health-compliance|financial-billing"
```

**Verify services are accessible:**
```bash
# List services across all MediSupply namespaces
kubectl get svc -A | grep -E "commerce-sales|inventories-storage|logistics-distributions|regulatory-health-compliance|financial-billing"
```

**Check Gateway and HTTPRoute status:**
```bash
# Check gateways
kubectl get gateway -A

# Check HTTP routes
kubectl get httproute -A
```

### Step 12: Access the Application

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
curl http://localhost:8080/api/v1/sales/health

# Inventories Storage
curl http://localhost:8080/api/v1/batches
curl http://localhost:8080/api/v1/distribution-centers

# Logistics Distributions
curl http://localhost:8080/api/v1/trips
curl http://localhost:8080/api/v1/vehicles

# Regulatory Health Compliance
curl http://localhost:8080/api/v1/alerts
curl http://localhost:8080/api/v1/regulations

# Financial Billing
curl http://localhost:8080/api/v1/purchases
```

### RabbitMQ Management UI

Access the RabbitMQ management interface:
```bash
# Access at: http://localhost:8080/rabbitmq/
# Credentials: purchases-app / supersecret (or invoices-app / supersecret)
```

**Note:** The trailing slash (`/`) is required in the RabbitMQ URL.

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
```

### Configure Istio for distributed tracing
```bash
# Install distributed tracing with istioctl
istioctl install -f ./tracing.yaml --skip-confirmation

# Apply distributed tracing configuration
kubectl apply -f telemetry.yaml
```

Simulate a requests to generate traces:
```bash
for i in {1..30}; do
  curl http://localhost:8080/api/v1/sales/health
  curl http://localhost:8080/api/v1/batches/health
  curl http://localhost:8080/api/v1/distribution-centers/health
  curl http://localhost:8080/api/v1/trips/health
  curl http://localhost:8080/api/v1/vehicles/health
  curl http://localhost:8080/api/v1/alerts/health
  curl http://localhost:8080/api/v1/regulations/health
done
```

See the traces in Jaeger:
```bash
istioctl dashboard jaeger
```

### Health Checks

```bash
# Monitor pods across all namespaces
watch kubectl get pods -A | grep -E "commerce-sales|inventories-storage|logistics-distributions|regulatory-health-compliance|financial-billing"

# View logs for a specific service
kubectl logs -f deployment/sales-v1 -n commerce-sales
kubectl logs -f deployment/batches-v1 -n inventories-storage
kubectl logs -f deployment/purchases-v1 -n financial-billing

# Check Istio proxy logs
kubectl logs deployment/sales-v1 -c istio-proxy -n commerce-sales

# Check RabbitMQ logs
kubectl logs -f statefulset/medisupply-rabbitmq-server -n financial-billing
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

# Debug financial-billing namespace
istioctl analyze -n financial-billing
kubectl get all -n financial-billing

# Check RabbitMQ cluster status
kubectl get rabbitmqclusters -n financial-billing
kubectl describe rabbitmqcluster medisupply-rabbitmq -n financial-billing
```

### RabbitMQ-Specific Issues

**RabbitMQ pods not starting:**
```bash
# Check RabbitMQ operator status
kubectl get pods -n rabbitmq-system

# Check RabbitMQ cluster status
kubectl get rabbitmqclusters -n financial-billing

# View RabbitMQ logs
kubectl logs -f statefulset/medisupply-rabbitmq-server -n financial-billing

# Check messaging topology resources
kubectl get queues,exchanges,bindings -n financial-billing
```

**Secrets not found:**
```bash
# Verify secrets exist
kubectl get secrets -n financial-billing | grep queue-user-credentials

# Recreate secrets if needed
kubectl delete secret purchases-app-queue-user-credentials -n financial-billing
kubectl create secret generic purchases-app-queue-user-credentials \
  --from-literal=username=purchases-app \
  --from-literal=password=supersecret \
  -n financial-billing
```

## 🏗️ Architecture Benefits

### Multi-Namespace Architecture Advantages

| Benefit                  | Description                                                                         |
|--------------------------|-------------------------------------------------------------------------------------|
| **Domain Isolation**     | Each business domain operates independently in its own namespace, reducing coupling |
| **Security Boundaries**  | Network policies and RBAC can be applied granularly per namespace                   |
| **Resource Management**  | Resource quotas, limits, and priorities can be set per domain                       |
| **Team Autonomy**        | Different teams can manage, deploy, and monitor their own namespaces independently  |
| **Fault Isolation**      | Issues in one namespace (crashes, resource exhaustion) don't affect other domains   |
| **Compliance**           | Easier to implement and audit regulatory requirements per domain                    |
| **Scalability**          | Each domain can be scaled independently based on its specific needs                 |
| **Development Velocity** | Teams can iterate faster without impacting other domains                            |

## 🔐 Security Best Practices

### Service Mesh Security

1. ✅ **Always use FQDNs** for cross-namespace communication (e.g., `service.namespace.svc.cluster.local`)
2. ✅ **Enable strict mTLS** for all service-to-service communication via Istio
3. ✅ **Certificate rotation** is handled automatically by Istio's certificate management

### Network Security

4. ✅ **Apply NetworkPolicies** to restrict traffic between namespaces and pods
5. ✅ **Use Istio AuthorizationPolicies** for fine-grained access control
6. ✅ **Limit ingress/egress** traffic to only what's necessary

### Access Control

7. ✅ **Implement RBAC** (Role-Based Access Control) to control access to namespace resources
8. ✅ **Use PodSecurityStandards** (PSS) to enforce security policies on pods
9. ✅ **Principle of least privilege** - Grant minimum necessary permissions

### Secrets Management

10. ✅ **Never commit secrets** to version control (use `.gitignore` for `.env.aws`)
11. ✅ **Use Kubernetes Secrets** for sensitive data (credentials, API keys, certificates)
12. ✅ **Consider external secret managers** like HashiCorp Vault or AWS Secrets Manager for production
13. ✅ **Rotate credentials regularly** (RabbitMQ passwords, AWS keys, etc.)

### Monitoring & Compliance

14. ✅ **Enable audit logging** for Kubernetes API server
15. ✅ **Monitor mTLS status** using `istioctl authn tls-check`
16. ✅ **Regular security scans** of container images
17. ✅ **Review Istio configurations** regularly using `istioctl analyze`

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute to MediSupply:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the existing patterns and includes appropriate documentation.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

**Built with ❤️ using Kubernetes, Istio, and modern cloud-native technologies**
