# Kafka Installation Guide

This file documents the installation steps for Kafka, these are shell commands, not Kubernetes manifests

## Prerequisites

- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/)

1. Create namespace for kafka operator

    ```bash
    kubectl create namespace kafka-system
    ```
2. Add Strimzi repository
    ```bash
    helm repo add strimzi https://strimzi.io/charts
    helm repo update
    ```

3. Install Strimzi operator

    ```bash
    helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator \
      --namespace kafka-system \
      --set watchAnyNamespace=true
   ```
   > This will install the Strimzi operator in the `kafka-system` namespace and enable it to watch all namespaces.

4. Check operator installation
    ```bash
    helm ls -n kafka-system
    ```