#!/bin/bash

# Knative Eventing Installation Script
# This script installs Knative Eventing with In-Memory Channel and MT-Channel Broker

set -e  # Exit on error

echo "=================================================="
echo "Knative Eventing Installation Script"
echo "=================================================="
echo ""

# Configuration
KNATIVE_VERSION="knative-v1.19.6"

# Step 1: Install Knative Eventing CRDs and core components
echo "Step 1: Installing Knative Eventing CRDs and core components..."
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/eventing-core.yaml
echo "✓ Core components installed"
echo ""

# Step 2: Verify installation
echo "Step 2: Verifying core installation..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n knative-eventing
kubectl get pods -n knative-eventing
echo "✓ Core installation verified"
echo ""

# Step 3: Install In-Memory Channel layer
echo "Step 3: Installing In-Memory Channel (for development/testing only)..."
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/in-memory-channel.yaml
echo "✓ In-Memory Channel installed"
echo ""

# Step 4: Install MT-Channel Based Broker
echo "Step 4: Installing MT-Channel Based Broker..."
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/mt-channel-broker.yaml
echo "✓ MT-Channel Broker installed"
echo ""

# Step 5: Wait for all deployments to be ready
echo "Step 5: Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n knative-eventing
echo "✓ All deployments ready"
echo ""

# Step 6: Final verification
echo "Step 6: Final verification..."
kubectl get pods -n knative-eventing
echo ""

echo "=================================================="
echo "✓ Knative Eventing installation completed successfully!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  - Knative Eventing Core"
echo "  - In-Memory Channel (development/testing)"
echo "  - MT-Channel Based Broker"

