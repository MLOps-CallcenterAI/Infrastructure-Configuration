# Deploy ArgoCD Script

## Overview

The `deploy_argocd.sh` script automates the deployment of **ArgoCD** to a Kubernetes cluster.
It performs environment checks, deploys ArgoCD if necessary, and provides instructions to access the ArgoCD UI.

---

## File Location

```
scripts/deploy_argocd.sh
```

---

## Prerequisites

* Kubernetes cluster
* `kubectl` installed and configured
* Bash shell

---

## Usage

```bash
./scripts/deploy_argocd.sh
```

---

## Script Workflow

1. **Check `kubectl` installation**
   Ensures `kubectl` is installed and available in the PATH.

2. **Verify Kubernetes cluster connectivity**
   Confirms that the current `kubeconfig` points to a reachable cluster.

3. **Check for `argocd` namespace**

   * If it exists, prints existing ArgoCD pods.
   * If not, creates the namespace and deploys ArgoCD using official manifests:

   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

4. **Wait for ArgoCD server readiness**
   Uses `kubectl wait` with a timeout of 600 seconds.

5. **Print access instructions**

   * Port-forward to access ArgoCD UI:

     ```bash
     kubectl port-forward svc/argocd-server -n argocd 8080:443
     ```

   * Open browser: [https://localhost:8080](https://localhost:8080)

   * Default username: `admin`

   * Get initial password:

     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
     ```

---

## Example Output

```
🟠 ArgoCD is already deployed in the 'argocd' namespace.
NAME                                         READY   STATUS    RESTARTS   AGE
argocd-server-5f8d7c6c9b-abcde             1/1     Running   0          5m
✅ ArgoCD has been successfully deployed!
To access the ArgoCD UI, run the following command to port-forward:
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## Notes

* Exits if `kubectl` is missing or cluster is unreachable.
* Designed for **first-time deployment** or **re-deployment** of ArgoCD.
* Can be safely re-run; it will detect existing ArgoCD deployments.

---

