#!/bin/bash

function start_gateway() {
    kubectl apply --filename 'gateway-httpd-*.yaml'
    kubectl apply --filename 'gateway-postgres-*.yaml'

    # Wait for the Database to be setup, keycloak needs it
    kubectl rollout status --filename 'gateway-postgres-*.yaml'
    kubectl apply --filename 'gateway-keycloak-*.yaml'
}

function start_db() {
	kubectl apply --filename 'data-service-postgres-*.yaml'
	kubectl apply --filename 'data-service-graphdb-*.yaml'
}

function start_data-service() {
    # Wait for postgres and graphdb to start
    kubectl rollout status --filename 'data-service-postgres-*.yaml'
    kubectl rollout status --filename 'data-service-graphdb-*.yaml'
    kubectl apply --filename 'data-service-deployment.yaml' --filename 'data-service-service.yaml'
}

function start_model-service() {
    kubectl apply --filename 'model-service-*.yaml'
}

function start_document-service() {
    kubectl apply --filename 'document-service-*.yaml'
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
    start_db && \
    start_model-service && \
    start_data-service && \
    start_document-service && \
    start_hmi-server && \
    start_hmi-client
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    kubectl delete \
    --filename 'gateway-*.yaml' \
    --filename 'hmi-server-*.yaml' \
    --filename 'document-service-*.yaml' \
    --filename 'model-service-*.yaml' \
    --filename 'data-service-*.yaml' \
    --filename 'hmi-client-*.yaml'
    exit 0
fi

# Launches only the Gateway and Authentication services
if [[ ${1} == "gateway" ]]; then
    start_gateway
    exit 0
fi

# Start the specified service only. i.e. start model-service
if [[ ${1} == "start" ]]; then
    kubectl apply --filename "$2-*.yaml"
    exit 0
fi

# Stop the specified service only. i.e. stop hmi-server
if [[ ${1} == "stop" ]]; then
    kubectl delete --filename "$2-*.yaml"
    exit 0
fi


echo "Usage:"
echo "    ${0} status               Displays the status of all services"
echo "    ${0} up                   Launches TERArium"
echo "    ${0} down                 Tears down TERArium"
echo "    ${0} gateway              Launches only the Gateway and Authentication services"
echo "    ${0} start [service]      Start the specified service only. i.e. start model-service"
echo "    ${0} stop [service]       Stop the specified service only. i.e. stop hmi-server"
