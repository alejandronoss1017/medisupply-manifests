# KEDA Installation and Usage Guide

This guide documents how to install and use KEDA (Kubernetes Event-Driven Autoscaling) in your cluster. These are shell commands and example manifests to help you get started quickly; they are not application manifests.

## Overview

KEDA adds event-driven autoscaling to Kubernetes. It monitors external systems (Kafka, RabbitMQ, HTTP, Prometheus, etc.) and feeds metrics to Kubernetes HPA so your Deployments/Jobs scale up and down automatically based on real workload.

Key concepts:
- ScaledObject: Binds a Deployment/ReplicaSet/StatefulSet to one or more triggers and manages its HPA.
- ScaledJob: Creates Kubernetes Jobs based on event backlog.
- TriggerAuthentication / ClusterTriggerAuthentication: Provides secrets/credentials for scalers.

When to use KEDA:
- To scale consumers based on RabbitMQ queue length, Kafka lag, HTTP queue depth, etc.
- To scale to zero when idle and back up when events arrive.

## Prerequisites
- kubectl
- helm v3+
- A running Kubernetes cluster (v1.24+ recommended)
- Cluster-admin permissions

## Install KEDA with Helm

1) Add the Helm repo and update indexes
```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
```

2) Install KEDA into the keda namespace
```bash
helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --wait
```

You can customize the installation with --set values (operator replica count, logging level, metrics, etc.). See the chart values for details.

3) Verify the installation
```bash
helm ls -n keda
kubectl get pods -n keda
kubectl get crds | grep -i keda
# Expect to see CRDs like:
#  scaledobjects.keda.sh
#  scaledjobs.keda.sh
#  triggerauthentications.keda.sh
#  clustertriggerauthentications.keda.sh
```

## Quick start: your first ScaledObject
KEDA watches your ScaledObject and creates an HPA for the target Deployment. When the trigger metric is above threshold, pods scale up; when below, they scale down (even to 0 if minReplicaCount=0).

The examples below align with this repo's usage of RabbitMQ (financial-billing) and Kafka.

### RabbitMQ queue length scaler (financial-billing)

1) Create a secret with your RabbitMQ connection string
Replace the host URL with your cluster address/credentials. If you installed RabbitMQ via the operators in docs/rabbitmq-setup.md and created a cluster named financial-billing-rabbitmq in the financial-billing namespace, the service is typically reachable at financial-billing-rabbitmq.rabbitmq.svc:5672.
```bash
kubectl -n financial-billing create secret generic rabbitmq-conn \
  --from-literal=host="amqp://user:password@financial-billing-rabbitmq.rabbitmq.svc:5672/"
```

2) Create a TriggerAuthentication to use that secret
```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
  namespace: financial-billing
spec:
  secretTargetRef:
    - parameter: host   # parameter name expected by the RabbitMQ scaler
      name: rabbitmq-conn
      key: host
```

3) Create a ScaledObject for your consumer Deployment
Replace targetRef.name with the name of your consumer deployment (for example, purchases-worker) and set the queueName to purchases.events or invoices.events to match the topology in this repo.
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: purchases-worker-scaler
  namespace: financial-billing
spec:
  scaleTargetRef:
    name: purchases-worker       # Your Deployment processing messages
  minReplicaCount: 0             # Scale to zero when idle
  maxReplicaCount: 10
  cooldownPeriod: 60             # Seconds to wait to scale down after last activity
  pollingInterval: 15            # How often to poll RabbitMQ (seconds)
  triggers:
    - type: rabbitmq
      metadata:
        protocol: amqp
        queueName: purchases.events
        mode: QueueLength        # Scale by queue length
        value: "10"             # Desired messages per replica
        activationValue: "2"    # Below this, keep at minReplicaCount
      authenticationRef:
        name: rabbitmq-auth
```

4) Apply the manifests and verify
```bash
kubectl apply -f rabbitmq-triggerauth.yaml
kubectl apply -f purchases-worker-scaledobject.yaml

kubectl get scaledobject -n financial-billing
kubectl describe scaledobject purchases-worker-scaler -n financial-billing
kubectl get hpa -n financial-billing
```
Generate some test messages to purchases.events, then watch replicas increase:
```bash
kubectl get deploy purchases-worker -n financial-billing -w
```

### Kafka lag scaler

Use this when consuming from a Kafka topic and you want to scale consumers based on partition lag.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: kafka-consumer-scaler
  namespace: default
spec:
  scaleTargetRef:
    name: kafka-consumer         # Your Kafka consumer Deployment
  minReplicaCount: 0
  maxReplicaCount: 20
  pollingInterval: 15
  cooldownPeriod: 60
  triggers:
    - type: kafka
      metadata:
        bootstrapServers: my-cluster-kafka-bootstrap.kafka:9092  # Replace with your cluster svc
        consumerGroup: keda-consumer-group                       # Must match your app's group.id
        topic: knative-demo-topic                                # Replace with your topic
        lagThreshold: "100"                                     # Messages per replica target
        activationLagThreshold: "10"                            # Below this, keep at min
      # If SASL/TLS is required, define TriggerAuthentication and reference it here
```

Apply and verify:
```bash
kubectl apply -f kafka-consumer-scaledobject.yaml
kubectl get scaledobject
kubectl describe scaledobject kafka-consumer-scaler
kubectl get hpa
```

## Verifying scaling behavior
- ScaledObject status: kubectl describe scaledobject <name> -n <ns>
- HPA created by KEDA: kubectl get hpa -n <ns>
- Operator logs: kubectl logs -n keda deploy/keda-operator
- Check target deployment replicas in real time: kubectl get deploy <name> -n <ns> -w

## Best practices
- One ScaledObject per consumer Deployment for clarity.
- Start with conservative maxReplicaCount; tune after observing throughput.
- Use activationValue/activationLagThreshold to avoid flapping when near zero load.
- Set reasonable pollingInterval and cooldownPeriod to balance responsiveness and cost.
- Keep credentials in Secrets via TriggerAuthentication; prefer least privilege.
- If you also use Knative Serving for HTTP autoscaling, do not attach a KEDA ScaledObject to the same Knative-managed Deployment. Use separate components to avoid controller conflicts.

## Troubleshooting
- No HPA created:
  - kubectl describe scaledobject to check Conditions and Events
  - Ensure CRDs exist and the keda-operator pod is Running
- FailedGetMetrics or authentication errors:
  - Verify your TriggerAuthentication and Secret keys match scaler expectations
  - Check operator logs: kubectl logs -n keda deploy/keda-operator
- Not scaling up despite backlog:
  - Verify the consumerGroup (Kafka) matches your app
  - Verify queue/topic names and connection endpoints
  - Increase pollingInterval frequency or lower value/lagThreshold
- Not scaling down:
  - Confirm cooldownPeriod; reduce if you want faster scale-down
  - Ensure activationValue/activationLagThreshold are set appropriately

## Uninstallation
```bash
helm uninstall keda -n keda
# Optionally remove CRDs (only if you no longer need any KEDA resources)
kubectl delete crd scaledobjects.keda.sh \
  scaledjobs.keda.sh \
  triggerauthentications.keda.sh \
  clustertriggerauthentications.keda.sh
```

## References
- KEDA docs: https://keda.sh/docs/
- RabbitMQ scaler: https://keda.sh/docs/2.14/scalers/rabbitmq-queue/
- Kafka scaler: https://keda.sh/docs/2.14/scalers/kafka/
- Helm chart: https://github.com/kedacore/charts
