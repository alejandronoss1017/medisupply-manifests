#!/usr/bin/env bash
set -euo pipefail

# Ensure running under bash (avoid /bin/sh or dash syntax errors)
if [ -z "${BASH_VERSION:-}" ]; then
  echo "[INFO] Re-executing with bash..."
  exec /usr/bin/env bash "$0" "$@"
fi

# Event Mesh Setup Script (root/scripts)
# Installs RabbitMQ operators and topology first (queues/exchanges),
# then installs Kafka operator and a demo Kafka cluster/topics,
# then installs Knative Eventing with InMemoryChannel and MT-Channel-Broker,
# plus Knative RabbitMQ and Kafka Eventing components (optional sources/brokers).
#
# This aligns with docs in docs/rabbitmq-setup.md, docs/kafka-setup.md and docs/knative-eventing-setup.md.

# -------- Configuration (versions) --------
RABBITMQ_CLUSTER_OPERATOR_VERSION="v2.16.1"
CERT_MANAGER_VERSION="v1.5.4"
RABBITMQ_TOPOLOGY_OPERATOR_VERSION="v1.17.4"

KN_EVENTING_VERSION="knative-v1.19.6"
KN_SERVING_VERSION="latest"                         # Knative Serving CRDs and core
KN_NET_ISTIO_VERSION="latest"                       # Knative Istio networking layer
RABBIT_EVENTING_VERSION="knative-v1.19.6"           # RabbitMQ source/broker components for Knative

# Kafka related versions
EVENTING_KAFKA_CONTROLLER_VERSION="knative-v1.19.8" # Kafka controller + channel
EVENTING_KAFKA_SOURCE_VERSION="knative-v1.19.8"     # kafka source
EVENTING_KAFKA_BROKER_VERSION="knative-v1.19.8"     # Kafka broker components

# Namespaces
FIN_NAMESPACE="financial-billing"
KAFKA_SYSTEM_NS="kafka-system"
PSO_NAMESPACE="procurement-supply-optimization"

# Repo root resolved from this script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

info "Starting Event Mesh setup..."

# -------- 1) Ensure required namespaces exist --------
info "Ensuring namespaces exist..."
kubectl get ns "$FIN_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$FIN_NAMESPACE"
kubectl get ns "$KAFKA_SYSTEM_NS" >/dev/null 2>&1 || kubectl create namespace "$KAFKA_SYSTEM_NS"
kubectl get ns "$PSO_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$PSO_NAMESPACE"

# -------- 8) Install Knative Eventing (CRDs + Core) --------
info "Installing Knative Eventing CRDs and core ($KN_EVENTING_VERSION)..."
kubectl apply -f "https://github.com/knative/eventing/releases/download/${KN_EVENTING_VERSION}/eventing-crds.yaml"
kubectl apply -f "https://github.com/knative/eventing/releases/download/${KN_EVENTING_VERSION}/eventing-core.yaml"

# -------- 9) Install InMemoryChannel (development only) --------
info "Installing InMemoryChannel ($KN_EVENTING_VERSION)..."
kubectl apply -f "https://github.com/knative/eventing/releases/download/${KN_EVENTING_VERSION}/in-memory-channel.yaml"

# -------- 10) Install MT-Channel-Broker --------
info "Installing MT-Channel-Broker ($KN_EVENTING_VERSION)..."
kubectl apply -f "https://github.com/knative/eventing/releases/download/${KN_EVENTING_VERSION}/mt-channel-broker.yaml"

# -------- 12) Install Kafka Eventing components (Source + Controller) --------
info "Installing Knative Eventing Kafka components..."
info "  - Kafka Source ($EVENTING_KAFKA_SOURCE_VERSION)"
kubectl apply -f "https://github.com/knative-extensions/eventing-kafka-broker/releases/download/${EVENTING_KAFKA_SOURCE_VERSION}/eventing-kafka-source.yaml"

info "  - Kafka Controller ($EVENTING_KAFKA_CONTROLLER_VERSION)"
kubectl apply -f "https://github.com/knative-extensions/eventing-kafka-broker/releases/download/${EVENTING_KAFKA_CONTROLLER_VERSION}/eventing-kafka-controller.yaml"

# -------- 11) Install RabbitMQ Eventing components (Source + Broker) --------
# info "Installing Knative Eventing RabbitMQ components ($RABBIT_EVENTING_VERSION)..."
# kubectl apply -f "https://github.com/knative-extensions/eventing-rabbitmq/releases/download/${RABBIT_EVENTING_VERSION}/rabbitmq-source.yaml"
# kubectl apply -f "https://github.com/knative-extensions/eventing-rabbitmq/releases/download/${RABBIT_EVENTING_VERSION}/rabbitmq-broker.yaml"

# -------- 2) Install RabbitMQ operators (Cluster, Cert-Manager, Topology) --------
info "Installing RabbitMQ Cluster Operator ($RABBITMQ_CLUSTER_OPERATOR_VERSION)..."
kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/download/${RABBITMQ_CLUSTER_OPERATOR_VERSION}/cluster-operator.yml"

info "Installing cert-manager ($CERT_MANAGER_VERSION)..."
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"

# Wait for cert-manager
kubectl_wait_ns_ready cert-manager

info "Installing RabbitMQ Messaging Topology Operator ($RABBITMQ_TOPOLOGY_OPERATOR_VERSION)..."
kubectl apply -f "https://github.com/rabbitmq/messaging-topology-operator/releases/download/${RABBITMQ_TOPOLOGY_OPERATOR_VERSION}/messaging-topology-operator-with-certmanager.yaml"

# Wait for rabbitmq-system
kubectl_wait_ns_ready rabbitmq-system

# -------- 3) Apply in-cluster RabbitMQ and topology (queues/exchanges) --------
info "Applying RabbitMQ cluster manifests (financial-billing/rabbitmq.yaml)..."
kubectl apply -f "$REPO_ROOT/financial-billing/rabbitmq.yaml"

# Create default RabbitMQ user credentials (idempotent)
info "Creating default RabbitMQ user credentials secrets in namespace '$FIN_NAMESPACE'..."
kubectl create secret generic purchases-app-queue-user-credentials --from-literal=username=purchases-app --from-literal=password=supersecret -n "$FIN_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic invoices-app-queue-user-credentials --from-literal=username=invoices-app --from-literal=password=supersecret -n "$FIN_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

info "Applying RabbitMQ messaging topology (financial-billing/queues.yaml)..."
kubectl apply -f "$REPO_ROOT/financial-billing/queues.yaml"

# Wait for RabbitmqCluster pods to be ready
info "Waiting for RabbitMQ cluster pods to be ready..."
kubectl wait --for=condition=Ready --timeout=600s pods -l app.kubernetes.io/name=financial-billing-rabbitmq -n "$FIN_NAMESPACE" || true

success "RabbitMQ operators and topology applied."

# -------- 4) Install Kafka operator (Strimzi) --------

info "Adding the official Strimzi Helm chart repository and update the local cache..."
if helm repo list | grep -q "^strimzi"; then
  info "Strimzi repository already exists; skipping 'helm repo add'."
else
  helm repo add strimzi https://strimzi.io/charts
fi
helm repo update

info "Ensuring Strimzi Kafka Operator is installed in namespace $KAFKA_SYSTEM_NS ..."
if helm -n "$KAFKA_SYSTEM_NS" status strimzi-kafka-operator >/dev/null 2>&1; then
  info "Strimzi Kafka Operator already installed in namespace $KAFKA_SYSTEM_NS; skipping Helm install."
else
  info "Installing Strimzi Kafka Operator with Helm in namespace $KAFKA_SYSTEM_NS ..."
  helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator --namespace "$KAFKA_SYSTEM_NS" --set watchAnyNamespace=true
fi

# Wait for Strimzi operator
info "Waiting for Strimzi operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/strimzi-cluster-operator -n "$KAFKA_SYSTEM_NS" || true

# -------- 5) Provision Kafka cluster and topics (data plane) --------
info "Applying Kafka cluster manifest (procurement-supply-optimization/kafka.yaml)..."
kubectl apply -f "$REPO_ROOT/procurement-supply-optimization/kafka.yaml"

# Wait for Kafka to be ready (best-effort): wait for StatefulSet <cluster>-kafka to be ready
info "Waiting for Kafka brokers to be ready (best effort)..."
kubectl wait --for=condition=Ready --timeout=900s statefulset/events-cluster-kafka -n "$PSO_NAMESPACE" || true

info "Applying Kafka topics (procurement-supply-optimization/topics.yaml)..."
kubectl apply -f "$REPO_ROOT/procurement-supply-optimization/topics.yaml"

success "Kafka operator and cluster configured."

# Wait for knative-eventing system to be ready
kubectl_wait_ns_ready knative-eventing

# -------- 14) Deploy Knative Broker --------
info "Deploying Knative Broker (event-mesh/broker.yaml)..."
kubectl apply -f "$REPO_ROOT/event-mesh/broker.yaml"

info "Waiting for Broker to be Ready..."
kubectl wait --for=condition=Ready --timeout=300s broker/medisupply-broker -n default || true


# -------- 16) Apply sources aligned with this repo --------

info "Deploying KafkaSource (event-mesh/sources/kafka.yaml)..."
kubectl apply -f "$REPO_ROOT/event-mesh/sources/kafka.yaml"

#info "Deploying RabbitmqSource (financial-billing namespace)..."
#kubectl apply -f "$REPO_ROOT/event-mesh/sources/rabbitmq.yaml"

# Wait for sources to be Ready (best-effort)
info "Waiting for KafkaSource to be Ready..."
kubectl wait --for=condition=Ready --timeout=300s kafkasource/kafka-source -n default || true

#info "Waiting for RabbitmqSource to be Ready..."
#kubectl wait --for=condition=Ready --timeout=300s rabbitmqsource/purchases-rabbitmq-source -n "$FIN_NAMESPACE" || true

info "Deploying Triggers aligned with this repo..."
kubectl apply -f "$REPO_ROOT/event-mesh/triggers/purchases-trigger.yaml"

info "Waiting for triggers to be ready..."
kubectl wait --for=condition=Ready --timeout=300s trigger/purchases-trigger -n default || true

success "Knative Eventing fully configured"

# -------- Summary --------
info "Summary:"
echo "- RabbitMQ operators installed (cluster, cert-manager, topology)."
echo "- RabbitMQ cluster and messaging topology applied under namespace: $FIN_NAMESPACE."
echo "- RabbitMQ credentials created in namespace: $FIN_NAMESPACE"
echo "  * purchases-app-queue-user-credentials (username: purchases-app password: supersecret)"
echo "  * invoices-app-queue-user-credentials (username: invoices-app password: supersecret)"
echo "- Kafka operator (Strimzi) installed in namespace: $KAFKA_SYSTEM_NS."
echo "- Kafka data plane applied under namespace: $PSO_NAMESPACE (cluster: events-cluster)."
echo "- Knative Serving installed with Istio networking layer."
echo "- Knative Eventing installed with: InMemoryChannel and MT-Channel-Broker."
echo "- Knative Kafka components (source + controller) installed."
#echo "- Knative RabbitMQ components (source + broker) installed."
echo "- Knative Broker 'medisupply-broker' deployed in namespace: default (MTChannelBasedBroker)."
echo "- KafkaSource deployed in namespace: default."
echo "- Triggers deployed in namespace: default."
#echo "- RabbitMQ and Kafka sources applied (RabbitmqSource in $FIN_NAMESPACE, KafkaSource in $PSO_NAMESPACE)."
# -------- Quick status --------
info "Quick status (pods in key namespaces):"
for ns in cert-manager rabbitmq-system knative-serving knative-eventing "$FIN_NAMESPACE" "$KAFKA_SYSTEM_NS" "$PSO_NAMESPACE"; do
  echo "--- Namespace: $ns ---"
  kubectl get pods -n "$ns" || true
  echo ""
done

success "Event Mesh setup complete."