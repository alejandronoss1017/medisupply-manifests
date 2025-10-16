#!/bin/bash

set -e

echo "🚀 Setting up Knative Event Mesh Demo"
echo "======================================"

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace medisupply-eventing --dry-run=client -o yaml | kubectl apply -f -
#kubectl create namespace procurement-supply-optimization
# Deploy broker
echo "🔧 Creating event broker..."
kubectl apply -f  broker.yaml

# Wait for broker to be ready
echo "⏳ Waiting for broker to be ready..."
kubectl wait --for=condition=Ready --timeout=60s broker/medisupply-broker -n medisupply-eventing

# Deploy services
echo "🛠️  Deploying services..."

# Procurement Supply Optimization
kubectl apply -f ../procurement-supply-optimization/kafka.yaml
kubectl apply -f ../procurement-supply-optimization/supplier.yaml
kubectl apply -f ../procurement-supply-optimization/purchase-plans.yaml
kubectl apply -f ../procurement-supply-optimization/contracts.yaml

# Commerce Sales
kubectl apply -f ../commerce-sales/sales.yaml

# Financial Billing
kubectl apply -f ../financial-billing/purchases.yaml

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/purchase-plan-service-v1 -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/supplier-service-v1 -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/sales-v1 -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/purchases-v1 -n medisupply-eventing

# Create triggers
echo "🎯 Creating triggers..."
kubectl apply -f ../triggers/

# Wait for triggers to be ready
echo "⏳ Waiting for triggers to be ready..."
kubectl wait --for=condition=Ready --timeout=60s trigger/sales-trigger -n medisupply-eventing
kubectl wait --for=condition=Ready --timeout=60s trigger/purchase-trigger -n medisupply-eventing
echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Current status:"
kubectl get broker,trigger,deployment,service -n medisupply-eventing

echo ""
echo "🧪 To test the event mesh, run:"
echo "   kubectl apply -f ../event-source.yaml"
echo ""
echo "📝 To view logs:"
echo "   kubectl logs -n medisupply-eventing -l app=purchase-plan-service -c purchase-plan-service"
echo "   kubectl logs -n medisupply-eventing -l app=purchase-plan-service -c purchase-plan-worker"
echo "   kubectl logs -n medisupply-eventing -l app=sales -c sales"
echo "   kubectl logs -n medisupply-eventing -l app=purchases -c purchases-web"
echo "   kubectl logs -n medisupply-eventing -l app=purchases -c purchases-worker"

