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
kubectl apply -f ../financial-billing/invoices.yaml -n financial-billing
