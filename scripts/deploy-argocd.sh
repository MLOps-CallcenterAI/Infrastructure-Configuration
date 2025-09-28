#!/bin/bash 

kubectl version --client
if [ $? -ne 0 ]; then
  echo "❌ kubectl is not installed or not found in PATH. Please install kubectl and try again."
  exit 1
fi

kubectl cluster-info
if [ $? -ne 0 ]; then
  echo "❌ Cannot connect to the Kubernetes cluster. Please ensure your kubeconfig is set up correctly."
  exit 1
fi

kubectl get namespace argocd &> /dev/null
if [ $? -eq 0 ]; then
  echo "🟠 ArgoCD is already deployed in the 'argocd' namespace."
  kubectl get pods -n argocd
else
    echo "🚀 Deploying ArgoCD to the Kubernetes cluster..."
    
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
if [ $? -ne 0 ]; then
  echo "❌ ArgoCD server did not become ready in time. Please check the deployment status."
  exit 1
fi 

echo "✅ ArgoCD has been successfully deployed!"
echo "To access the ArgoCD UI, run the following command to port-forward:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then open your browser and navigate to https://localhost:8080"
echo "The default username is 'admin'. To get the initial password, run:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"

exit 0