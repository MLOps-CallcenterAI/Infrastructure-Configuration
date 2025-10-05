# CallCenterAI SVM Deployment Manifest

## Overview

This manifest deploys the **CallCenterAI TF-IDF + SVM model** as a service in a Kubernetes cluster.
It includes configuration, secrets, deployment, and service definitions.

---

## File Location

```
manifests/default/svm.yaml
```

---

## Components

### 1. ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: callcenterai-svm-config
data:
  MODEL_URI: "models:/m-49e62ea546064bd1b56cff76a8aded2f"
  EXPERIMENT_NAME: "/Users/medhedimaaroufi@gmail.com/CallCenterAI-Model1-TF-IDF-SVM"
```

* Stores **non-sensitive configuration** for the SVM model.
* Includes:

  * `MODEL_URI`: MLflow model URI
  * `EXPERIMENT_NAME`: MLflow experiment name

---

### 2. Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: callcenterai-svm-secret
type: Opaque
data:
  DATABRICKS_HOST: "aHR0cHM6Ly9kYmMtMjBhNmE1MzUtNWIzNS5jbG91ZC5kYXRhYnJpY2tzLmNvbQ=="
  DATABRICKS_TOKEN: "ZGFwaTE3ZTJmYTZiMmU5MmFjZDcyYzA2NzEyOTE2Mjk2Y2I4"
```

* Stores **sensitive credentials** in base64-encoded format.
* Includes:

  * `DATABRICKS_HOST`: Databricks workspace URL
  * `DATABRICKS_TOKEN`: Databricks API token

---

### 3. Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: callcenterai-svm-deployment
  labels:
    app: callcenterai-svm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: callcenterai-svm
  template:
    metadata:
      labels:
        app: callcenterai-svm
    spec:
      containers:
        - name: callcenterai-svm
          image: medhedimaaroufi/callcenterai-svm:v1.0.1
          ports:
            - containerPort: 8000
          envFrom:
            - configMapRef:
                name: callcenterai-svm-config
            - secretRef:
                name: callcenterai-svm-secret
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

* Defines the **SVM model deployment**.
* Key features:

  * `replicas`: Number of pod replicas (1 for now)
  * `image`: Docker image for the model
  * `ports`: Container exposes port `8000`
  * `envFrom`: Loads environment variables from `ConfigMap` and `Secret`
  * `resources`: CPU and memory **requests and limits** for the pod

---

### 4. Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: callcenterai-svm-service
spec:
  selector:
    app: callcenterai-svm
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
  type: ClusterIP
```

* Exposes the deployment internally within the cluster.
* Key features:

  * `ClusterIP` service type
  * Maps port `8000` to the container

---

## Deployment Instructions

1. Apply the manifest:

```bash
kubectl apply -f manifests/default/svm.yaml
```

2. Verify the deployment:

```bash
kubectl get pods -l app=callcenterai-svm
kubectl get svc callcenterai-svm-service
```

3. Update image (if needed) before redeployment:

```bash
./scripts/update_image.sh manifests/default/svm.yaml v1.0.2
```

---

## Notes

* Keep secrets **secure** and do not commit plain text tokens.
* Adjust `resources` according to your cluster capacity.
* The service is **internal only** (`ClusterIP`). Use an Ingress or port-forward to access externally.

---