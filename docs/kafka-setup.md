# Kafka Installation Guide

This file documents the installation steps for Kafka, these are shell commands, not Kubernetes manifests

```bash
 kubectl create namespace kafka-system
```

```bash
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka-system' -n kafka-system
```

```bash
  kubectl get pod -n kafka-system --watch
```

```bash
kubectl logs deployment/strimzi-cluster-operator -n kafka-system -f
```


## Kafka cluster with single example
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: dual-role
  labels:
    strimzi.io/cluster: my-cluster
spec:
  replicas: 1
  roles:
    - controller
    - broker
  storage:
    type: jbod
    volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
        kraftMetadata: shared
---

apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 4.1.0
    metadataVersion: 4.1-IV1
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
  entityOperator:
    topicOperator: {}
    userOperator: {}
```