# RabbitMQ Installation Guide

This guide documents the installation steps for RabbitMQ on Kubernetes using three essential operators. These are shell commands to install operators, not Kubernetes manifests for RabbitMQ instances themselves.

## Overview

RabbitMQ on Kubernetes requires multiple operators working together:

- **RabbitMQ Cluster Operator**: Manages RabbitMQ cluster lifecycle (deployment, scaling, upgrades)
- **Cert Manager**: Provides TLS certificate management for secure communication
- **RabbitMQ Messaging Topology Operator**: Manages RabbitMQ resources (queues, exchanges, bindings, users, policies)

## Installation Steps

### 1. Install RabbitMQ Cluster Operator

The Cluster Operator is responsible for deploying and managing RabbitMQ clusters in Kubernetes. It handles:
- RabbitMQ cluster creation and deletion
- Scaling clusters up or down
- Rolling upgrades and configuration updates
- Persistent storage management

```bash
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/v2.16.1/cluster-operator.yml
```

### 2. Install Cert Manager

Cert Manager is a prerequisite for the Messaging Topology Operator. It provides:
- Automatic TLS certificate provisioning and renewal
- Certificate lifecycle management
- Secure communication between operator components
- Webhook certificate management for admission controllers

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.5.4/cert-manager.yaml
```

**Note**: Wait for cert-manager to be fully ready before proceeding to the next step.
```bash
kubectl wait --for=condition=available --timeout=300s deployment --all -n cert-manager
```

### 3. Install RabbitMQ Messaging Topology Operator

The Messaging Topology Operator manages RabbitMQ messaging resources through Kubernetes CRDs. It allows you to declare:
- **Queues**: Durable message queues with specific configurations
- **Exchanges**: Message routing components (direct, topic, fanout, headers)
- **Bindings**: Connections between exchanges and queues
- **Users and Permissions**: Access control for RabbitMQ resources
- **Policies**: RabbitMQ operational policies (HA, TTL, etc.)
- **Virtual Hosts**: Logical groupings for multi-tenancy

```bash
kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/download/v1.17.4/messaging-topology-operator-with-certmanager.yaml
```

### 4. Verify Installation

Wait for all deployments in the rabbitmq-system namespace to be ready:

```bash
kubectl wait --for=condition=available --timeout=300s deployment --all -n rabbitmq-system
```

## Key Differences

| Operator | Purpose | What It Manages |
|----------|---------|-----------------|
| **Cluster Operator** | Infrastructure layer | RabbitMQ server instances, clusters, storage, networking |
| **Cert Manager** | Security infrastructure | TLS certificates, certificate lifecycle, webhook security |
| **Messaging Topology Operator** | Application layer | RabbitMQ logical resources (queues, exchanges, bindings, users) |

## Usage

After installation:
1. Use the **Cluster Operator** to create RabbitMQ clusters via `RabbitmqCluster` CRDs
2. Use the **Messaging Topology Operator** to define messaging topology via `Queue`, `Exchange`, `Binding`, `User`, etc. CRDs
3. **Cert Manager** works behind the scenes to secure operator communications

## Example Workflow

```yaml
# 1. Create a cluster (uses Cluster Operator)
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: my-cluster

---
# 2. Create a queue (uses Messaging Topology Operator)
apiVersion: rabbitmq.com/v1beta1
kind: Queue
metadata:
  name: orders-queue
spec:
  rabbitmqClusterReference:
    name: my-cluster
```