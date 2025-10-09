#!/bin/bash

# ======================================================
# Script: deploy_prometheus.sh
# Description: Deploy Prometheus Operator on Kubernetes using Helm
# ======================================================

set -e

NAMESPACE="monitoring"
PROM_RELEASE="prometheus"

echo "🚀 Starting Prometheus Operator deployment..."

# Step 0: Check prerequisites
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl is not installed. Please install it first:"
  echo "👉 https://kubernetes.io/docs/tasks/tools/"
  exit 1
fi

if ! command -v helm &> /dev/null; then
  echo "❌ Helm is not installed. Please install it first:"
  echo "👉 https://helm.sh/docs/intro/install/"
  exit 1
fi

# Step 1: Create namespace
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "📦 Creating namespace '$NAMESPACE'..."
  kubectl create namespace $NAMESPACE
else
  echo "✅ Namespace '$NAMESPACE' already exists."
fi

# Step 2: Add Helm repo
echo "🔗 Adding Helm stable repository..."
helm repo add stable https://charts.helm.sh/stable || true
helm repo update

# Step 3: Deploy Prometheus Operator
if helm status $PROM_RELEASE -n $NAMESPACE >/dev/null 2>&1; then
  echo "⚙️  Prometheus Operator already deployed. Upgrading..."
  helm upgrade $PROM_RELEASE stable/prometheus-operator -n $NAMESPACE
else
  echo "📈 Installing Prometheus Operator..."
  helm install $PROM_RELEASE stable/prometheus-operator -n $NAMESPACE
fi

# Step 4: Wait for pods to be ready
echo "⏳ Waiting for Prometheus Operator pods to become ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-operator -n $NAMESPACE --timeout=180s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $NAMESPACE --timeout=180s || true

# Step 5: Display services
echo ""
echo "🔍 Prometheus Services:"
kubectl get svc -n $NAMESPACE | grep prometheus

# Step 6: Port-forward instructions
echo ""
echo "🌐 To access Prometheus locally, run:"
echo "kubectl port-forward svc/${PROM_RELEASE}-prometheus-oper-prometheus 9090:9090 -n ${NAMESPACE}"
echo ""
echo "✅ Prometheus Operator deployed successfully!"
