#!/bin/bash

function start_gateway() {
    kubectl apply --filename 'gateway-*.yaml'
}



function start_data-service() {
    # Wait for postgres to start
    kubectl apply --filename 'data-service-postgres-*.yaml'
    kubectl rollout status --filename 'data-service-postgres-*.yaml'
    # Wait for graphdb to start
    kubectl apply --filename 'data-service-graphdb-*.yaml'
    kubectl rollout status --filename 'data-service-graphdb-*.yaml'
    kubectl apply --filename 'data-service-deployment.yaml' --filename 'data-service-service.yaml'
}

function start_hmi-server() {
    # Wait for Keyclock, the hmi-server test its existence on start
    kubectl rollout status --filename 'gateway-keycloak-*.yaml'
    kubectl apply --filename 'hmi-server-*.yaml'
}

function start_hmi-client() {
    kubectl apply --filename 'hmi-client-*.yaml'
}

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    kubectl get po,svc,configMap
    exit 0
fi

# Launches TERArium
if [[ ${1} == "up" ]]; then
    start_gateway && \
    start_data-service && \
    start_hmi-server && \
    start_hmi-client
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    kubectl delete \
    --filename 'gateway-*.yaml' \
    --filename 'hmi-server-*.yaml' \
    --filename 'data-service-*.yaml' \
    --filename 'hmi-client-*.yaml'
    exit 0
fi

# Launches only the Gateway and Authentication services
if [[ ${1} == "dev" ]]; then
    start_gateway && \
    start_data-service
    exit 0
fi

# Launches TERArium without the hmi-server
if [[ ${1} == "dev:no-hmi-server" ]]; then
    start_gateway && \
    start_data-service && \
    start_hmi-client
    exit 0
fi

# Launches TERArium without the hmi-client
if [[ ${1} == "dev:no-hmi-client" ]]; then
    start_gateway && \
    start_data-service && \
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

