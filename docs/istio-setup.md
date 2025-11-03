# Istio Installation Guide

This guide documents the installation steps for Istio service mesh on Kubernetes. These are shell commands to install the operator, not Kubernetes manifests.

## Overview

### What is a service mesh?

A service mesh is an infrastructure layer that manages service-to-service communication in a microservices architecture. It provides:

- **Traffic Management**: Intelligent routing, load balancing, and traffic splitting
- **Security**: mTLS encryption, authentication, and authorization between services
- **Observability**: Distributed tracing, metrics, and logging for all service communications
- **Resilience**: Circuit breakers, retries, timeouts, and fault injection

### What is Istio?

Istio is an open-source service mesh that provides a uniform way to connect, secure, control, and observe microservices. Key features:

- **Sidecar Proxy Pattern**: Uses Envoy proxies deployed alongside application containers
- **Control Plane**: `istiod` manages and configures the proxies to route traffic
- **Gateway**: Manages inbound and outbound traffic at the edge of the mesh
- **No Application Code Changes**: Works transparently with existing applications


## Prerequisites

- [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Kubernetes command-line tool
- [helm](https://helm.sh/) - Kubernetes package manager (v3.x or later)
- A running Kubernetes cluster (v1.24 or later recommended)
- Cluster admin permissions

## Installation Steps

### 1. Add Istio Helm Repository

Add the official Istio Helm chart repository:

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

**Expected output:**
```
"istio" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "istio" chart repository
```

### 2. Install Istio Base Components

Install the base CRDs (Custom Resource Definitions) required by Istio:

```bash
helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
```

This creates the `istio-system` namespace and installs foundational resources.

### 3. Verify Base Installation

```bash
helm ls -n istio-system
```

**Expected output:**
```
NAME       	NAMESPACE   	REVISION	STATUS  	CHART           
 istio-base	istio-system	1       	deployed	base-1.x.x
```

**Note:** If you intend to use Istio CNI chart you must install it now, before installing istiod. [See Install Istio with the CNI plugin](https://istio.io/latest/docs/setup/additional-setup/cni/#installing-with-helm) for more info.


### 4. Install Istio Control Plane (istiod)

Install the Istio discovery service, which acts as the control plane:

```bash
helm install istiod istio/istiod -n istio-system --wait
```

The `--wait` flag ensures the command waits until all pods are running.

### 5. Verify Control Plane Installation

```bash
helm ls -n istio-system
```

**Expected output:**
```
NAME       	NAMESPACE   	REVISION	STATUS  	CHART
istio-base 	istio-system	1       	deployed	base-1.x.x
istiod     	istio-system	1       	deployed	istiod-1.x.x
```

### 6. Check Helm Chart Status

Get detailed status information about the istiod installation:

```bash
helm status istiod -n istio-system
```

This shows the deployment status, resources created, and any notes from the chart.

### 7. Verify istiod Pods are Running

Confirm the control plane pods are healthy:

```bash
kubectl get deployments -n istio-system --output wide
```

**Expected output:**
```
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
istiod   1/1     1            1           2m
```

**Check pods:**
```bash
kubectl get pods -n istio-system
```

All pods should be in `Running` state with `READY 1/1`.

### 8. Install Istio Ingress Gateway (Optional)

Install the ingress gateway to manage incoming traffic to the mesh:

```bash
helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
```

**Verify the gateway:**
```bash
kubectl get pods -n istio-ingress
kubectl get svc -n istio-ingress
```

The service will have an `EXTERNAL-IP` assigned (on cloud providers) or `<pending>` (on local clusters).

### 9. Install Gateway API CRDs

Install the Kubernetes Gateway API CRDs (if not already present):

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; }
```

This enables the use of the newer Gateway API resources alongside Istio.

### 10. Verify Gateway API CRDs Installation

```bash
kubectl get crds | grep gateway.networking.k8s.io
```

**Expected output:**
```
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
```

## Enable Sidecar Injection

To automatically inject Envoy sidecar proxies into your application pods, label your namespace:

```bash
kubectl label namespace <your-namespace> istio-injection=enabled
```

**Example for default namespace:**
```bash
kubectl label namespace default istio-injection=enabled
```

**Verify the label:**
```bash
kubectl get namespace -L istio-injection
```

After labeling, any new pods created in the namespace will automatically get an Istio sidecar proxy.

## Troubleshooting

### Pods Not Starting

If istiod or gateway pods are not starting:

```bash
# Check pod details
kubectl describe pod <pod-name> -n istio-system

# Check logs
kubectl logs <pod-name> -n istio-system
```

### Sidecar Not Injecting

If sidecars are not being injected:

1. Verify namespace label:
   ```bash
   kubectl get namespace <namespace> --show-labels
   ```

2. Check istiod logs:
   ```bash
   kubectl logs -n istio-system -l app=istiod
   ```

3. Manually test injection:
   ```bash
   kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].name}'
   ```
   Should show both your app container and `istio-proxy`.

### Gateway External IP Pending

On local clusters (Docker Desktop, Minikube), use port-forwarding:

```bash
kubectl port-forward -n istio-ingress svc/istio-ingress 8080:80
```

## Next Steps

1. **Enable sidecar injection** for your application namespaces
2. **Deploy a sample application** to test the mesh
3. **Configure traffic management** using VirtualServices and DestinationRules
4. **Set up observability** with Kiali, Prometheus, and Grafana
5. **Implement security policies** using PeerAuthentication and AuthorizationPolicy

## Additional Resources

- [Istio Official Documentation](https://istio.io/latest/docs/)
- [Istio Getting Started Guide](https://istio.io/latest/docs/setup/getting-started/)
- [Istio Best Practices](https://istio.io/latest/docs/ops/best-practices/)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Istio Security](https://istio.io/latest/docs/concepts/security/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)

## Uninstallation

If you need to uninstall Istio:

```bash
# Remove ingress gateway
helm delete istio-ingress -n istio-ingress

# Remove istiod
helm delete istiod -n istio-system

# Remove base components
helm delete istio-base -n istio-system

# Remove namespaces (optional)
kubectl delete namespace istio-ingress
kubectl delete namespace istio-system

# Remove Gateway API CRDs (optional)
kubectl delete crd gatewayclasses.gateway.networking.k8s.io
kubectl delete crd gateways.gateway.networking.k8s.io
kubectl delete crd httproutes.gateway.networking.k8s.io
kubectl delete crd referencegrants.gateway.networking.k8s.io
kubectl delete crd grpcroutes.gateway.networking.k8s.io
```
