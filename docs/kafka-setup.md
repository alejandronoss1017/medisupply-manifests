# Kafka Installation Guide

This guide documents the installation steps for Apache Kafka on Kubernetes using the Strimzi operator. These are shell commands to install the operator, not Kubernetes manifests for Kafka clusters themselves.

## Overview

### What is Strimzi?

Strimzi is a Kubernetes operator that simplifies the deployment and management of Apache Kafka on Kubernetes. It provides:

- **Kafka Cluster Management**: Deploy and manage Kafka brokers, ZooKeeper/KRaft clusters
- **Topic Management**: Create and configure Kafka topics via Kubernetes CRDs
- **User Management**: Manage Kafka users and ACLs declaratively
- **Connect & MirrorMaker**: Deploy Kafka Connect and MirrorMaker 2 for data integration
- **Monitoring Integration**: Built-in Prometheus metrics and Grafana dashboards

### Control Plane vs Data Plane Architecture

This installation follows the **separation of concerns** pattern:

- **Control Plane** (`kafka-system` namespace): Contains the Strimzi operator that manages Kafka resources
- **Data Plane** (any namespace): Contains actual Kafka clusters, topics, users, and workloads

**Benefits of this separation:**
- **Isolation**: Operator has elevated permissions but is isolated from application workloads
- **Multi-tenancy**: Deploy multiple Kafka clusters in different namespaces for different teams/environments
- **Security**: Easier to apply namespace-level RBAC and network policies
- **Operations**: Upgrade the operator independently from Kafka clusters

## Prerequisites

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/)

## Installation Steps

### 1. Create Namespace for Kafka Operator (Control Plane)

Create a dedicated namespace for the Strimzi operator. This separates the control plane from data plane resources.

```bash
kubectl create namespace kafka-system
```

### 2. Add Strimzi Helm Repository

Add the official Strimzi Helm chart repository and update the local cache.

```bash
helm repo add strimzi https://strimzi.io/charts
helm repo update
```

### 3. Install Strimzi Operator

Install the Strimzi operator in the `kafka-system` namespace with cluster-wide watching enabled.

```bash
helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator \
  --namespace kafka-system \
  --set watchAnyNamespace=true
```

**Why `watchAnyNamespace=true`?**

This flag enables the operator to watch and manage Kafka resources across **all namespaces**, not just `kafka-system`. This is critical for the control plane/data plane separation:

- ✅ **Operator (Control Plane)**: Runs in `kafka-system` with elevated permissions
- ✅ **Kafka Clusters (Data Plane)**: Can be deployed in any namespace (e.g., `production`, `staging`, `team-a`)
- ✅ **Flexibility**: Deploy multiple isolated Kafka clusters without installing multiple operators
- ✅ **Centralized Management**: Single operator manages all Kafka infrastructure

**Alternative Approaches:**
- `watchNamespaces`: Watch specific namespaces (comma-separated list)
- Default (no flag): Watch only the operator's namespace (not recommended for multi-tenant setups)

### 4. Verify Operator Installation

Check that the operator was successfully installed:

```bash
helm ls -n kafka-system
```

You should see the `strimzi-kafka-operator` listed as deployed.

### 5. Wait for Operator to be Ready

Ensure the operator deployment is fully ready before creating Kafka resources:

```bash
kubectl wait --for=condition=available --timeout=300s deployment/strimzi-cluster-operator -n kafka-system
```

### 6. Verify CRDs Installation

Confirm that Strimzi Custom Resource Definitions (CRDs) were created:

```bash
kubectl get crds | grep strimzi
```

Expected CRDs include:
- `kafkas.kafka.strimzi.io` - Kafka clusters
- `kafkatopics.kafka.strimzi.io` - Kafka topics
- `kafkausers.kafka.strimzi.io` - Kafka users
- `kafkaconnects.kafka.strimzi.io` - Kafka Connect clusters
- `kafkamirrormaker2s.kafka.strimzi.io` - MirrorMaker 2

## Usage

### Creating a Kafka Cluster (Data Plane)

After installation, you can deploy Kafka clusters in **any namespace**. The operator in `kafka-system` will manage them.

**Example**: Deploy a Kafka cluster in the `production` namespace:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: production  # Data plane namespace
spec:
  kafka:
    version: 3.6.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    storage:
      type: persistent-claim
      size: 100Gi
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 10Gi
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

The operator in `kafka-system` detects this resource in `production` namespace and provisions the Kafka cluster there.

### Creating Topics and Users

Topics and users are also deployed in the data plane namespace where the Kafka cluster exists:

```yaml
# Topic in production namespace
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: orders-topic
  namespace: production
  labels:
    strimzi.io/cluster: my-cluster
spec:
  partitions: 10
  replicas: 3

---
# User in production namespace
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: app-user
  namespace: production
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: tls
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: orders-topic
        operations: [Read, Write, Describe]
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│          Control Plane (kafka-system)           │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │     Strimzi Cluster Operator            │   │
│  │  (watches all namespaces)               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                      │
                      │ Manages
                      ▼
┌──────────────────────────────────────────────────┐
│              Data Plane (Any Namespace)          │
│                                                  │
│  Namespace: production                           │
│  ┌────────────────────────────────────────┐     │
│  │  Kafka Cluster (my-cluster)            │     │
│  │  - Kafka Brokers                       │     │
│  │  - ZooKeeper / KRaft                   │     │
│  │  - Topics                              │     │
│  │  - Users                               │     │
│  └────────────────────────────────────────┘     │
│                                                  │
│  Namespace: staging                              │
│  ┌────────────────────────────────────────┐     │
│  │  Kafka Cluster (staging-cluster)       │     │
│  └────────────────────────────────────────┘     │
└──────────────────────────────────────────────────┘
```

## Troubleshooting

### Check Operator Logs

If Kafka resources aren't being created:

```bash
kubectl logs -n kafka-system deployment/strimzi-cluster-operator -f
```

### Verify RBAC Permissions

Ensure the operator has cluster-wide permissions to watch resources:

```bash
kubectl get clusterrolebinding | grep strimzi
```

### Check Resource Status

View the status of Kafka resources:

```bash
kubectl get kafka -A
kubectl describe kafka my-cluster -n production
```