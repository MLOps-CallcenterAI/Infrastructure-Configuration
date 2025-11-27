#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
RELEASE_NAME="prometheus"
HELM_CHART="prometheus-community/kube-prometheus-stack"

# Functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    else
        print_success "$1 is installed"
        return 0
    fi
}

wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    
    print_info "Waiting for all pods to be ready in namespace $namespace (timeout: ${timeout}s)..."
    
    if kubectl wait --for=condition=ready pod --all -n $namespace --timeout=${timeout}s 2>/dev/null; then
        print_success "All pods are ready!"
        return 0
    else
        print_warning "Some pods may still be starting. Checking status..."
        kubectl get pods -n $namespace
        return 1
    fi
}

detect_kubernetes_platform() {
    local context=$(kubectl config current-context 2>/dev/null || echo "unknown")
    
    if [[ "$context" == *"docker-desktop"* ]]; then
        echo "docker-desktop"
    elif [[ "$context" == *"kind"* ]]; then
        echo "kind"
    elif [[ "$context" == *"minikube"* ]]; then
        echo "minikube"
    elif [[ "$context" == *"k3s"* ]]; then
        echo "k3s"
    else
        echo "unknown"
    fi
}

# Main script
print_header "Prometheus + Grafana Deployment Script"

# Check prerequisites
print_header "Step 1: Checking Prerequisites"

all_good=true

if ! check_command kubectl; then
    all_good=false
fi

if ! check_command helm; then
    all_good=false
fi

# Check kubectl context
if kubectl cluster-info &> /dev/null; then
    print_success "kubectl is configured and cluster is accessible"
    CURRENT_CONTEXT=$(kubectl config current-context)
    print_info "Current context: $CURRENT_CONTEXT"
else
    print_error "Cannot connect to Kubernetes cluster"
    all_good=false
fi

if [ "$all_good" = false ]; then
    print_error "Prerequisites not met. Please install missing tools."
    exit 1
fi

# Detect platform
PLATFORM=$(detect_kubernetes_platform)
print_info "Detected platform: $PLATFORM"

# Ask for confirmation
print_warning "This will deploy Prometheus and Grafana to namespace '$NAMESPACE'"
read -p "Do you want to continue? (yes/no): " confirm

if [[ $confirm != "yes" && $confirm != "y" ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Add Helm repository
print_header "Step 2: Adding Prometheus Community Helm Repository"

if helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &> /dev/null; then
    print_success "Helm repository added"
else
    print_info "Helm repository already exists, updating..."
fi

helm repo update
print_success "Helm repositories updated"

# Create namespace
print_header "Step 3: Creating Namespace"

if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace '$NAMESPACE' already exists"
else
    kubectl create namespace $NAMESPACE
    print_success "Namespace '$NAMESPACE' created"
fi

# Check if release already exists
print_header "Step 4: Checking Existing Installation"

if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    print_warning "Release '$RELEASE_NAME' already exists in namespace '$NAMESPACE'"
    read -p "Do you want to upgrade the existing installation? (yes/no): " upgrade_confirm
    
    if [[ $upgrade_confirm == "yes" || $upgrade_confirm == "y" ]]; then
        ACTION="upgrade"
    else
        print_info "Skipping installation"
        exit 0
    fi
else
    ACTION="install"
fi

# Install or upgrade Prometheus stack
print_header "Step 5: ${ACTION^}ing Prometheus Stack"

# Set node exporter based on platform
if [[ "$PLATFORM" == "docker-desktop" ]]; then
    print_warning "Docker Desktop detected - disabling node exporter due to mount propagation issues"
    NODE_EXPORTER_FLAG="--set nodeExporter.enabled=false"
else
    print_info "Enabling node exporter"
    NODE_EXPORTER_FLAG="--set nodeExporter.enabled=true"
fi

# Perform installation/upgrade
if [ "$ACTION" == "install" ]; then
    helm install $RELEASE_NAME $HELM_CHART \
        --namespace $NAMESPACE \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        $NODE_EXPORTER_FLAG \
        --wait \
        --timeout 10m
    print_success "Prometheus stack installed successfully"
else
    helm upgrade $RELEASE_NAME $HELM_CHART \
        --namespace $NAMESPACE \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        $NODE_EXPORTER_FLAG \
        --wait \
        --timeout 10m
    print_success "Prometheus stack upgraded successfully"
fi

# Wait for pods to be ready
print_header "Step 6: Verifying Deployment"

sleep 10
wait_for_pods $NAMESPACE 300

# Get pod status
print_info "Pod Status:"
kubectl get pods -n $NAMESPACE

# Get services
print_info "\nService Status:"
kubectl get svc -n $NAMESPACE

# Get Grafana password
print_header "Step 7: Retrieving Grafana Credentials"

GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE $RELEASE_NAME-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

print_success "Grafana credentials retrieved"

# Print access information
print_header "Deployment Complete!"

echo -e "${GREEN}Prometheus and Grafana have been successfully deployed!${NC}\n"

echo -e "${BLUE}=== Access Information ===${NC}\n"

echo -e "${YELLOW}Prometheus:${NC}"
echo -e "  To access Prometheus, run:"
echo -e "  ${GREEN}kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-prometheus 9090:9090${NC}"
echo -e "  Then open: ${GREEN}http://localhost:9090${NC}\n"

echo -e "${YELLOW}Grafana:${NC}"
echo -e "  To access Grafana, run:"
echo -e "  ${GREEN}kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-grafana 3000:80${NC}"
echo -e "  Then open: ${GREEN}http://localhost:3000${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}$GRAFANA_PASSWORD${NC}\n"

echo -e "${YELLOW}Alertmanager:${NC}"
echo -e "  To access Alertmanager, run:"
echo -e "  ${GREEN}kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-alertmanager 9093:9093${NC}"
echo -e "  Then open: ${GREEN}http://localhost:9093${NC}\n"

# Create port-forward script
print_header "Step 8: Creating Port-Forward Helper Script"

cat > access-monitoring.sh << 'EOF'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="monitoring"
RELEASE_NAME="prometheus"

echo -e "${BLUE}=== Monitoring Access Helper ===${NC}\n"

echo -e "${YELLOW}Choose a service to access:${NC}"
echo "1) Prometheus"
echo "2) Grafana"
echo "3) Alertmanager"
echo "4) All (in separate terminals - requires tmux)"
echo "5) Show Grafana password"
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo -e "\n${GREEN}Starting port-forward for Prometheus...${NC}"
        echo -e "Access at: ${GREEN}http://localhost:9090${NC}"
        kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-prometheus 9090:9090
        ;;
    2)
        echo -e "\n${GREEN}Starting port-forward for Grafana...${NC}"
        echo -e "Access at: ${GREEN}http://localhost:3000${NC}"
        GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE $RELEASE_NAME-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
        echo -e "Username: ${GREEN}admin${NC}"
        echo -e "Password: ${GREEN}$GRAFANA_PASSWORD${NC}"
        kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-grafana 3000:80
        ;;
    3)
        echo -e "\n${GREEN}Starting port-forward for Alertmanager...${NC}"
        echo -e "Access at: ${GREEN}http://localhost:9093${NC}"
        kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-alertmanager 9093:9093
        ;;
    4)
        if command -v tmux &> /dev/null; then
            tmux new-session -d -s monitoring "kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-prometheus 9090:9090"
            tmux split-window -h "kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-grafana 3000:80"
            tmux split-window -v "kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-kube-prometheus-alertmanager 9093:9093"
            echo -e "${GREEN}All services started in tmux session 'monitoring'${NC}"
            echo "Attach with: tmux attach -t monitoring"
        else
            echo -e "${YELLOW}tmux not found. Please install tmux or choose individual services.${NC}"
        fi
        ;;
    5)
        GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE $RELEASE_NAME-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
        echo -e "\n${GREEN}Grafana Credentials:${NC}"
        echo -e "Username: ${GREEN}admin${NC}"
        echo -e "Password: ${GREEN}$GRAFANA_PASSWORD${NC}"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
EOF

chmod +x access-monitoring.sh
print_success "Created helper script: ./access-monitoring.sh"

# Print useful commands
print_header "Useful Commands"

echo -e "${YELLOW}View all pods:${NC}"
echo -e "  kubectl get pods -n $NAMESPACE\n"

echo -e "${YELLOW}View services:${NC}"
echo -e "  kubectl get svc -n $NAMESPACE\n"

echo -e "${YELLOW}View logs (example):${NC}"
echo -e "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=prometheus\n"

echo -e "${YELLOW}Uninstall:${NC}"
echo -e "  helm uninstall $RELEASE_NAME -n $NAMESPACE\n"

echo -e "${YELLOW}Access services easily:${NC}"
echo -e "  ./access-monitoring.sh\n"

print_success "Deployment script completed successfully!"