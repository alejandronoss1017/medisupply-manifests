#!/usr/bin/env bash
set -euo pipefail

# Ensure running under bash (avoid /bin/sh or dash syntax errors)
if [ -z "${BASH_VERSION:-}" ]; then
  echo "[INFO] Re-executing with bash..."
  exec /usr/bin/env bash "$0" "$@"
fi

# Istio Setup Script (root/scripts)
# Installs Istio service mesh using Helm and configures Gateway API CRDs.
#
# This aligns with docs in docs/istio-setup.md.

# -------- Configuration (versions) --------
GATEWAY_API_VERSION="v1.3.0"

# -------- Helper functions --------
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
success(){ echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

kubectl_wait_ns_ready() {
  local ns=$1
  info "Waiting for deployments in namespace '$ns' to be available..."
  kubectl get deploy -n "$ns" >/dev/null 2>&1 || true
  kubectl wait --for=condition=available --timeout=300s deployment --all -n "$ns" || true
}

# -------- Pre-flight checks --------
if ! command -v kubectl >/dev/null 2>&1; then
  err "kubectl is required but not found in PATH. Please install kubectl first: https://kubernetes.io/releases/download/"
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  err "helm is required but not found in PATH. Please install Helm first: https://helm.sh/docs/intro/install/"
  exit 1
fi

info "Starting Istio service mesh setup..."

# -------- 1) Add Istio Helm Repository --------
info "Adding Istio Helm repository..."
if helm repo list | grep -q "^istio"; then
  info "Istio repository already exists; skipping 'helm repo add'."
else
  helm repo add istio https://istio-release.storage.googleapis.com/charts
fi
helm repo update

# -------- 2) Install Istio Base Components (CRDs) --------
info "Checking if Istio base is already installed..."
if helm -n istio-system status istio-base >/dev/null 2>&1; then
  info "Istio base already installed; skipping."
else
  info "Installing Istio base components (CRDs)..."
  helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
fi

# Verify base installation
info "Verifying Istio base installation..."
helm ls -n istio-system | grep istio-base || err "Failed to verify istio-base installation"

# -------- 3) Install Istio Control Plane (istiod) --------
info "Checking if istiod is already installed..."
if helm -n istio-system status istiod >/dev/null 2>&1; then
  info "istiod already installed; skipping."
else
  info "Installing Istio control plane (istiod)..."
  helm install istiod istio/istiod -n istio-system --wait
fi

# Verify istiod installation
kubectl_wait_ns_ready istio-system

info "Verifying istiod deployment..."
kubectl get deployment istiod -n istio-system || err "Failed to verify istiod deployment"

success "Istio service mesh installed successfully."

# -------- 4) Install Gateway API CRDs --------
info "Installing Kubernetes Gateway API CRDs ($GATEWAY_API_VERSION)..."
if kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  info "Gateway API CRDs already installed; skipping."
else
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=${GATEWAY_API_VERSION}" | kubectl apply -f -
fi

# Verify Gateway API CRDs
info "Verifying Gateway API CRDs installation..."
kubectl get crds | grep gateway.networking.k8s.io || warn "Gateway API CRDs may not be fully installed"

success "Gateway API CRDs installed."

# -------- 5) Enable Istio injection for default namespace --------
info "Enabling Istio sidecar injection for default namespace..."
if kubectl get namespace default -o jsonpath='{.metadata.labels.istio-injection}' 2>/dev/null | grep -q "enabled"; then
  info "Istio injection already enabled for default namespace."
else
  kubectl label namespace default istio-injection=enabled --overwrite
  success "Istio injection enabled for default namespace."
fi

# -------- Summary --------
info "Summary:"
echo "✓ Istio Helm repository added and updated."
echo "✓ Istio base components (CRDs) installed in namespace: istio-system."
echo "✓ Istio control plane (istiod) installed in namespace: istio-system."
echo "✓ Kubernetes Gateway API CRDs installed (version: $GATEWAY_API_VERSION)."
echo "✓ Istio sidecar injection enabled for default namespace."

# -------- Quick status --------
info "Quick status (pods in istio-system namespace):"
echo "--- Namespace: istio-system ---"
kubectl get pods -n istio-system || true
echo ""

# -------- Next Steps --------
info "Next steps:"
echo "1. Label application namespaces for Istio injection:"
echo "   kubectl label namespace <namespace> istio-injection=enabled"
echo ""
echo "2. Apply MediSupply manifests:"
echo "   kubectl apply -f namespaces.yaml"
echo "   kubectl apply -k commerce-sales/"
echo "   kubectl apply -k inventories-storage/"
echo "   kubectl apply -k logistics-distributions/"
echo "   kubectl apply -k regulatory-health-compliance/"
echo "   kubectl apply -k financial-billing/"
echo "   kubectl apply -k procurement-supply-optimization/"
echo "   kubectl apply -f gateway.yaml -n default"
echo "   kubectl annotate gateway medisupply-gateway networking.istio.io/service-type=ClusterIP --namespace=default"
echo ""
echo "3. Run event mesh setup (RabbitMQ, Kafka, Knative):"
echo "   ./scripts/setup-event-mesh.sh"
echo ""
echo "4. Access Istio dashboards:"
echo "   istioctl dashboard kiali"
echo "   istioctl dashboard grafana"
echo "   istioctl dashboard jaeger"
echo ""
echo "5. Deploy observability addons (optional):"
echo "   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/kiali.yaml"
echo "   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/grafana.yaml"
echo "   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/prometheus.yaml"
echo "   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/addons/jaeger.yaml"

success "Istio service mesh setup complete."
