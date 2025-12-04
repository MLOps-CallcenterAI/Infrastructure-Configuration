# Infrastructure-Configuration

## Project Structure

```
Infrastructure-Configuration
├── application.yaml
├── Docs
│   ├── manifests
│   │   └── default
│   │       ├── app.md
│   │       └── svm.md
│   └── scripts
│       ├── deploy_argocd.md
│       └── update_image.md
├── manifests
│   └── default
│       ├── app.yaml
│       └── svm.yaml
├── scripts
│   ├── deploy_argocd.sh
│   ├── deploy_prometheuse.sh
│   └── update_image.sh
└── README.md
```

## Overview

This repository contains infrastructure configuration files and deployment scripts for managing and deploying applications using **Argo CD**.

* `manifests` contains Kubernetes manifests organized by environment (`default` for the SVM model, `monitoring` for monitoring tools).
* `scripts` includes automation scripts to deploy Argo CD and update container image tags.
* `application.yaml` defines Argo CD applications to deploy both the SVM model and monitoring stack automatically.

## Features

* **Argo CD Integration**: Automate continuous delivery with Argo CD.
* **Environment-Specific Manifests**: Separate manifests for default application and monitoring environments.
* **Automation Scripts**: Scripts for Argo CD deployment and updating Docker image tags.

## Documentation

Detailed guides are available in the `Docs` folder:

* **Manifests**

  * [`svm.md`](Docs/manifests/default/svm.md) → Details about the SVM model Kubernetes configuration (ConfigMap, Secret, Deployment, Service).
* **Scripts**

  * [`deploy_argocd.md`](Docs/scripts/deploy_argocd.md) → Instructions for deploying Argo CD to the cluster.
  * [`update_image.md`](Docs/scripts/update_image.md) → How to update container image tags in Kubernetes manifests.


## Directories

* `manifests`

  * `default`: Manifests for deploying the SVM model.
  * `monitoring`: Manifests for monitoring tools like Nginx.
* `scripts`

  * `deploy_argocd.sh`: Deploys Argo CD in the cluster.
  * `update_image.sh`: Updates Docker image tags in manifest files.

## Usage

### Requirements

* Kubernetes cluster
* `kubectl` installed
* Bash shell

### Deploy Argo CD

1. Make the deployment script executable:

```bash
chmod +x scripts/deploy_argocd.sh
```

2. Run the script:

```bash
./scripts/deploy_argocd.sh
```

* This will deploy Argo CD to the `argocd` namespace.

3. Apply the `application.yaml` to register Argo CD applications:

```bash
kubectl apply -f application.yaml
```

* This will create two applications in Argo CD:

  * **callcenter-ai** → Deploys the SVM model (`manifests/default`)
  * **monitoring** → Deploys monitoring resources (`manifests/monitoring`)

4. Access the Argo CD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

* Open [https://localhost:8080](https://localhost:8080)
* Default username: `admin`
* Get initial password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Update Docker Image Tag

To update the container image in a manifest:

```bash
chmod +x scripts/update_image.sh
./scripts/update_image.sh <filepath> <image_tag>
```

* Example:

```bash
./scripts/update_image.sh manifests/default/svm.yaml v1.0.2
```

This will replace the image tag in the manifest with the new tag.

### Apply Changes

After updating the image tag, Argo CD will automatically sync the deployment (if automated sync is enabled in `application.yaml`) or you can manually sync via the UI.

---