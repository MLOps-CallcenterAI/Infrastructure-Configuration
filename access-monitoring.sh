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
