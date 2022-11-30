#!/bin/bash

function start_gateway() {
    cat 'gateway-*.yaml' |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
}

function start_hmi-server() {
    # Wait for Keyclock, the hmi-server test its existence on start
    kubectl rollout status --filename 'gateway-keycloak-*.yaml'
    kubectl apply --filename 'hmi-server-*.yaml','data-service-*.yaml'
}

function start_hmi-client() {
    kubectl apply --filename 'hmi-client-*.yaml'
}

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl get po,svc,configMap -n terarium
    exit 0
fi

# Launches TERArium
if [[ ${1} == "up" ]]; then
    cat namespace.yaml |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat secrets-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat gateway-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat hmi-*.yaml          |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat data-*.yaml         |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    cat gateway-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat hmi-*.yaml          |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat data-*.yaml         |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat secrets-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat namespace.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    exit 0
fi

# Launches only the Gateway and Authentication services
if [[ ${1} == "dev" ]]; then
    start_gateway
    exit 0
fi

# Launches TERArium without the hmi-server
if [[ ${1} == "dev:no-hmi-server" ]]; then
    start_gateway && \
    start_hmi-client
    exit 0
fi

# Launches TERArium without the hmi-client
if [[ ${1} == "dev:no-hmi-client" ]]; then
    start_gateway && \
    start_hmi-server
    exit 0
fi

echo "Usage:"
echo "    ${0} status               Displays the status of all services"
echo "    ${0} up                   Launches TERArium"
echo "    ${0} down                 Tears down TERArium"
echo "    ${0} dev                  Launches only the Gateway and Authentication services"
echo "    ${0} dev:no-hmi-server    Launches TERArium without the hmi-server"
echo "    ${0} dev:no-hmi-client    Launches TERArium without the hmi-client"

