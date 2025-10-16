# Knative Eventing Installation Guide

This file documents the installation steps for Knative Eventing, these are shell commands, not Kubernetes manifests

## Key Differences: Channel vs Broker Layer

### Channel (Messaging) Layer
Channels are the underlying messaging infrastructure for point-to-point event delivery, think of them as the "pipes" for events.

#### Characteristics:
- Direct messaging primitive - provides basic pub/sub functionality
- Point-to-point or fan-out - events go from source to subscribers
- No built-in filtering - subscribers receive all events from the channel
- Lower-level abstraction - you directly work with publishers and subscribers

#### Available implementations:
- KafkaChannel - backed by Apache Kafka (production-ready)
- InMemoryChannel - simple, in-memory (NOT for production)
- NATS Streaming Channel - backed by NATS

### Broker Layer
Brokers provide a higher-level event routing abstraction with filtering capabilities Installing, they use Triggers to route events to subscribers based on event attributes.

#### Characteristics:
- Event routing with filtering - uses Triggers to filter events by attributes
- Higher-level abstraction - easier to use for complex event routing scenarios
- Decouples producers from consumers - producers don't need to know about subscribers
- Can use Channels underneath - some Broker implementations (like MT-Channel-Broker) use Channels as their transport layer

#### Available implementations:
- Kafka Broker - backed by Apache Kafka (production-ready, efficient)
- MT-Channel-Broker - uses Channels underneath (simpler installation)
- RabbitMQ Broker - backed by RabbitMQ

### When to Use What?

#### Use Channels when:
- You need simple point-to-point messaging
- You want direct control over the messaging topology
- Your use case doesn't require event filtering

#### Use Brokers when:
- You need event filtering based on attributes (type, source, etc.)
- You want to decouple event producers from consumers
- You're building a more complex event-driven architecture
- You want an easier, more declarative approach to event routing

## Run these commands to install Knative Eventing:

1. Install Knative Eventing CRDs and core components
    ```bash
    kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.6/eventing-crds.yaml
    kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.6/eventing-core.yaml
    ```

2. Verify installation
    ```bash
    kubectl get pods -n knative-eventing
    ```

3. Install a default channel (messaging) layer, options are In-memory, Kafka or NATS

    - In-memory Channel (for development/testing only)
    ```bash
    kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.6/in-memory-channel.yaml
    ```

    - Kafka Channel
    ```bash
    kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.8/eventing-kafka-controller.yaml
    kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.8/eventing-kafka-channel.yaml
    ```
    - NATS Channel
    ```bash
    kubectl apply -f https://github.com/knative-extensions/eventing-natss/releases/download/knative-v1.19.6/eventing-jsm.yaml
    ```

4. Install a Broker layer

    - MT-Channel Based Broker
    ```bash
    kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.19.6/mt-channel-broker.yaml
    ```

    - Kafka Based Broker
    ```bash
    kubectl apply -f kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.19.7/eventing-kafka-broker.yaml
    ```

    - RabbitMQ Based Broker
    ```bash
    kubectl apply -f https://github.com/knative-extensions/eventing-rabbitmq/releases/download/knative-v1.19.6/rabbitmq-source.yaml
    kubectl apply -f https://github.com/knative-extensions/eventing-rabbitmq/releases/download/knative-v1.19.6/rabbitmq-broker.yaml
    ```

5. Wait for deployments to be ready
    ```bash
    kubectl wait --for=condition=available --timeout=300s deployment --all -n knative-eventing
    ```

6. Verify installation
    ```bash
    kubectl get pods -n knative-eventing
    ```