# Knative Eventing Installation Guide

This file documents the installation steps for Knative Eventing, these are shell commands, not Kubernetes manifests

## Run these commands to install Knative Eventing:

```bash
# 1. Install Knative Serving CRDs and Core
 kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.16.0/serving-crds.yaml
 kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.16.0/serving-core.yaml

# 2. Install Knative Eventing CRDs and Core
 kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.16.0/eventing-crds.yaml
 kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.16.0/eventing-core.yaml

# 3. Install RabbitMQ Eventing Source
 kubectl apply -f https://github.com/knative-extensions/eventing-rabbitmq/releases/download/knative-v1.16.0/rabbitmq-source.yaml

# 4. Install RabbitMQ Broker
 kubectl apply -f https://github.com/knative-extensions/eventing-rabbitmq/releases/download/knative-v1.16.0/rabbitmq-broker.yaml

# 5. Wait for deployments to be ready
 kubectl wait --for=condition=available --timeout=300s deployment --all -n knative-serving
 kubectl wait --for=condition=available --timeout=300s deployment --all -n knative-eventing

# 6. Verify installation
 kubectl get pods -n knative-serving
 kubectl get pods -n knative-eventing
```
