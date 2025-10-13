# RabbitMQ Installation Guide
 
This file documents the installation steps for RabbitMQ, these are shell commands, not Kubernetes manifests


```bash
 kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/v2.16.1/cluster-operator.yml
```

```bash
 kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
```

```bash
 kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/download/v1.17.4/messaging-topology-operator.yaml
```

```bash
 kubectl wait --for=condition=available --timeout=300s deployment --all -n rabbitmq-system
```