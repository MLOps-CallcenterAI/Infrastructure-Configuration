# Infrastructure-Configuration

## Project Structure
```
Infrastructure-Configuration
    ├── application.yaml
    ├── manifests
    │   ├── default
    │   │   └── *.yaml
    │   └── monitoring
    │       └── *.yaml
    |── scripts
    │    ├── deploy_argocd.sh
    |    └── update_image.sh
    └── README.md
```

## Overview
This repository contains infrastructure configuration files and deployment scripts for managing and deploying applications using Argo CD. The `manifests` directory holds Kubernetes manifests organized into different environments, while the `scripts` directory includes automation scripts to facilitate deployment processes.

## Features
- **Argo CD Integration**: Seamless integration with Argo CD for continuous delivery.
- **Environment-Specific Manifests**: Separate directories for different environments (default, monitoring).
- **Automation Scripts**: Scripts to automate deployment and configuration tasks.

## Directories
- `manifests`: Contains Kubernetes manifests for different environments.
    - `default`: Contains the default environment manifests.
    - `monitoring`: Contains manifests related to monitoring tools and services.
- `scripts`: Contains deployment and automation scripts.

## Usage
### Requirements
- Kubernetes cluster
- kubectl installed
- bash shell

### Installation and Configuration
1. Clone the repository.
3. Run the deployment script:
   ```bash
   chmod +x scripts/deploy-argocd.sh
   ./scripts/deploy-argocd.sh
   ```
    Note: This operation may take a few minutes to complete.
4. Configure Argo CD to point to the `application.yaml` file for application management.
    ```bash
    kubectl apply -f application.yaml
    ```
5. Access the Argo CD UI to manage and monitor your applications.
