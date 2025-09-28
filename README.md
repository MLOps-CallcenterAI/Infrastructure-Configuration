# Infrastructure-Configuration

## Project Structure
```
Infrastructure-Configuration
├── manifests
│   ├── default
│   └── monitoring
├── scripts
│   └── deploy-argocd.sh
└── README.md
```

## Overview
This repository contains infrastructure configuration files and deployment scripts for managing and deploying applications using Argo CD. The `manifests` directory holds Kubernetes manifests organized into different environments, while the `scripts` directory includes automation scripts to facilitate deployment processes.

## Directories
- `manifests`: Contains Kubernetes manifests for different environments.
    - `default`: Contains the default environment manifests.
    - `monitoring`: Contains manifests related to monitoring tools and services.
- `scripts`: Contains deployment and automation scripts.

## Usage
### Requirements
- Kubernetes cluster
- Argo CD installed and configured
- kubectl installed
- bash shell

### Installation and Configuration
1. Clone the repository.
2. Navigate to the `scripts` directory.
3. Run the deployment script:
   ```bash
   chmod +x deploy-argocd.sh
   ./deploy-argocd.sh
   ```
4. Follow the prompts to complete the deployment process.