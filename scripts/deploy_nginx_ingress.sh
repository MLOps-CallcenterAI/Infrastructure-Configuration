#!/usr/bin/env bash
set -e

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
INGRESS_CHART="ingress-nginx/ingress-nginx"

echo "===================================================="
echo " 🚀 Installing NGINX Ingress Controller"
echo "===================================================="

# Check Helm
if ! command -v helm &>/dev/null; then
    echo "⚠️ Helm not found. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Add Repo
echo "📦 Adding ingress-nginx Helm repo..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo update >/dev/null

# Create Namespace if missing
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

echo "📥 Installing ingress-nginx..."
helm upgrade --install $RELEASE_NAME $INGRESS_CHART \
  --namespace $NAMESPACE

echo "⏳ Waiting for controller to be ready..."
kubectl wait --namespace $NAMESPACE \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "===================================================="
echo " ✅ Ingress Controller Installed Successfully"
echo "===================================================="

# Get IP / NodePort
SERVICE="ingress-nginx-controller"
EXTERNAL_IP=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
NODE_PORT=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "🔍 Ingress service info:"
kubectl get svc $SERVICE -n $NAMESPACE
echo ""

if [[ -n "$EXTERNAL_IP" ]]; then
    echo "🌍 Public IP: $EXTERNAL_IP"
else
    echo "🖥 No LoadBalancer → using NodePort: $NODE_PORT"
fi
echo ""

echo "===================================================="
echo " 📄 Applying ingress for all vhosts"
echo "===================================================="

kubectl apply -f manifests/ingress-controller/ingress-nginx.yaml

echo "===================================================="
echo " 🎉 All vhosts configured for:"
echo " - callcenterai.com"
echo " - argocd.callcenterai.com"
echo " - k8s.callcenterai.com"
echo " - prometheuse.callcenterai.com"
echo " - grafana.callcenterai.com"
echo "===================================================="

echo "🔧 IMPORTANT: Update your DNS records to point all above domains to:"
[[ -n "$EXTERNAL_IP" ]] && echo "👉 $EXTERNAL_IP" || echo "👉 Your cluster Node IP"
echo "===================================================="
