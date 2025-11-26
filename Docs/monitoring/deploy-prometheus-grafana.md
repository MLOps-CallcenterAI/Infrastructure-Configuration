# Deploy Prometheus and Grafana on Local Kubernetes Cluster

Complete step-by-step guide for deploying and configuring Prometheus and Grafana on your local Kubernetes cluster.

## Prerequisites

- A running local Kubernetes cluster (minikube, kind, k3s, or Docker Desktop)
- `kubectl` installed and configured
- `helm` installed (recommended method)

## Step 1: Install Helm (if not already installed)

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows (using Chocolatey)
choco install kubernetes-helm
```

## Step 2: Add Prometheus Community Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Step 3: Create a Namespace

```bash
kubectl create namespace monitoring
```

## Step 4: Install Prometheus using Helm

For Docker Desktop (with node exporter disabled):

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set nodeExporter.enabled=false
```

For minikube or kind (with node exporter enabled):

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

This installs:
- Prometheus Operator
- Prometheus server
- Alertmanager
- Grafana
- Node exporter (if enabled)
- Kube-state-metrics
- Pre-configured dashboards

## Step 5: Verify the Installation

```bash
kubectl get pods -n monitoring
```

Wait until all pods are running. This may take a few minutes.

```bash
kubectl get svc -n monitoring
```

## Step 6: Access Prometheus

Forward the Prometheus port to your local machine:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Open your browser and navigate to: `http://localhost:9090`

## Step 7: Access Grafana

Forward the Grafana port:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open your browser and navigate to: `http://localhost:3000`

**Default credentials:**
- Username: `admin`
- Password: `prom-operator`

To get the actual password:

```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Step 8: Configure Grafana Dashboards

Grafana comes pre-configured with several Kubernetes dashboards:

1. Log in to Grafana
2. Click on "Dashboards" (four squares icon) in the left sidebar
3. Browse the pre-installed dashboards:
   - Kubernetes / Compute Resources / Cluster
   - Kubernetes / Compute Resources / Namespace
   - Kubernetes / Compute Resources / Pod
   - Node Exporter / Nodes

## Step 9: Verify Data Sources

The Prometheus data source is already configured. To verify:

1. Go to Configuration → Data Sources
2. You should see "Prometheus" already configured
3. The URL should be: `http://prometheus-kube-prometheus-prometheus.monitoring:9090`

## Step 10: Create a Custom Dashboard (Optional)

1. Click "+" → "Dashboard" → "Add new panel"
2. In the query editor, try a sample query:
   ```promql
   rate(container_cpu_usage_seconds_total[5m])
   ```
3. Customize the visualization and save

## Step 11: Configure Persistent Storage (Optional but Recommended)

By default, data may not persist. To add persistence, create a `values.yaml` file:

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

grafana:
  persistence:
    enabled: true
    size: 5Gi
```

Upgrade the installation:

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values.yaml
```

## Step 12: Configure Alerting (Optional)

Alertmanager is already installed. To configure alerts, create an `alertmanager-config.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      receiver: 'default'
      group_wait: 10s
    receivers:
    - name: 'default'
      webhook_configs:
      - url: 'http://your-webhook-url'
```

Apply it:

```bash
kubectl apply -f alertmanager-config.yaml
```

## Troubleshooting

### Node Exporter CrashLoopBackOff on Docker Desktop

If you see node exporter pods failing with mount propagation errors:

**Error message:**
```
path / is mounted on / but it is not a shared or slave mount
```

**Solution:** Disable node exporter (recommended for Docker Desktop):

```bash
# Uninstall
helm uninstall prometheus -n monitoring

# Reinstall with node exporter disabled
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set nodeExporter.enabled=false
```

### Check Pod Status

```bash
kubectl get pods -n monitoring
kubectl describe pod <pod-name> -n monitoring
kubectl logs <pod-name> -n monitoring
```

## Common Commands

**Check metrics being scraped:**

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Then visit http://localhost:9090/targets
```

**View Prometheus configuration:**

```bash
kubectl get prometheus -n monitoring -o yaml
```

**Restart Grafana:**

```bash
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

**Uninstall:**

```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

## Useful Prometheus Queries

Try these queries in Prometheus or Grafana:

- **CPU usage:** `rate(container_cpu_usage_seconds_total[5m])`
- **Memory usage:** `container_memory_usage_bytes`
- **Pod count:** `count(kube_pod_info)`
- **Node CPU:** `rate(node_cpu_seconds_total[5m])`
- **API server requests:** `rate(apiserver_request_total[5m])`
- **Container restarts:** `rate(kube_pod_container_status_restarts_total[15m])`

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)