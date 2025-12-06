#!/usr/bin/env bash
set -e

DASHBOARD_URL="https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
ADMIN_YAML="manifests/k8s-dashboard/dashboard-admin-user.yaml"

echo "===================================================="
echo " 🚀 Deploying Kubernetes Dashboard"
echo "===================================================="

# 1. Install Dashboard
echo "👉 Applying Dashboard manifest..."
kubectl apply -f "$DASHBOARD_URL"

# 2. Create Admin User
echo "👉 Creating admin ServiceAccount & ClusterRoleBinding..."

cat <<EOF > $ADMIN_YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f $ADMIN_YAML

# 3. Get Login Token
echo "👉 Fetching Dashboard login token..."
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)

echo ""
echo "===================================================="
echo " ✅ Kubernetes Dashboard Installed"
echo "===================================================="
echo ""
echo "🔑 Login Token:"
echo "$TOKEN"
echo ""
echo "🌐 Access Dashboard via kubectl proxy:"
echo "  kubectl proxy"
echo ""
echo "Then open:"
echo "  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "===================================================="
echo "🎉 Done!"
echo "===================================================="
