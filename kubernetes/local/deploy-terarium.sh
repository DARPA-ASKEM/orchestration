#!/bin/bash

function start_gateway() {
    kubectl apply --filename 'gateway-*.yaml'
}

function start_hmi-server() {
    # Wait for Keyclock, the hmi-server test its existence on start
    kubectl rollout status --filename 'gateway-keycloak-*.yaml'
    kubectl apply --filename 'hmi-server-*.yaml','mock-data-service-*.yaml'
}

function start_hmi-client() {
    kubectl apply --filename 'hmi-client-*.yaml'
}

# launches TERArium
if [[ ${1} == "up" ]]; then
    start_gateway && \
    start_hmi-server && \
    start_hmi-client
    exit 0
fi

# tears down TERArium
if [[ ${1} == "down" ]]; then
    kubectl delete \
    --filename 'gateway-*.yaml' \
    --filename 'hmi-server-*.yaml' \
    --filename 'mock-data-service-*.yaml' \
    --filename 'hmi-client-*.yaml'
    exit 0
fi

# displays the status of all services
if [[ ${1} == "status" ]]; then
    kubectl get po,svc,configMap
    exit 0
fi

# launches only the Gateway and Authentication services
if [[ ${1} == "dev" ]]; then
    start_gateway
    exit 0
fi

# launches TERArium without hmi-server
if [[ ${1} == "dev:hmi-server" ]]; then
    start_gateway && \
    start_hmi-client
    exit 0
fi

# launches TERArium without hmi-client
if [[ ${1} == "dev:hmi-client" ]]; then
    start_gateway && \
    start_hmi-server
    exit 0
fi

echo "Usage:"
echo "    ${0} status            displays the status of all services"
echo "    ${0} up                launches TERArium"
echo "    ${0} down              tears down TERArium"
echo "    ${0} dev               launches only the Gateway and Authentication services"
echo "    ${0} dev:hmi-server    launches TERArium without hmi-server"
echo "    ${0} dev:hmi-client    launches TERArium without hmi-client"

