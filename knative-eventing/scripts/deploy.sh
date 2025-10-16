#!/bin/bash

set -e

echo "🚀 Setting up Knative Event Mesh Demo"
echo "======================================"

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace medisupply-eventing --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace procurement-supply-optimization --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace commerce-sales --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace financial-billing --dry-run=client -o yaml | kubectl apply -f -
# Deploy broker
echo "🔧 Creating event broker..."
kubectl apply -f  broker.yaml


# Wait for broker to be ready
echo "⏳ Waiting for broker to be ready..."
kubectl wait --for=condition=Ready --timeout=60s broker/medisupply-broker -n medisupply-eventing

kubectl apply -f triggers/purchase-trigger.yaml -n medisupply-eventing
kubectl apply -f triggers/sales-trigger.yaml -n medisupply-eventing
# Deploy services
echo "🛠️  Deploying services..."

# Procurement Supply Optimization
kubectl apply -f ../procurement-supply-optimization/kafka.yaml -n procurement-supply-optimization
kubectl apply -f ../procurement-supply-optimization/suppliers.yaml -n procurement-supply-optimization
kubectl apply -f ../procurement-supply-optimization/purchase-plans.yaml -n procurement-supply-optimization
kubectl apply -f ../procurement-supply-optimization/contracts.yaml -n procurement-supply-optimization

# Commerce Sales
kubectl apply -f ../commerce-sales/sales.yaml -n commerce-sales

# Financial Billing

kubectl apply -f ../financial-billing/purchases.yaml -n financial-billing
# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/purchase-plan-service -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/supplier-service -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/sales -n medisupply-eventing
kubectl wait --for=condition=available --timeout=120s deployment/purchases -n medisupply-eventing

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

