#!/bin/bash

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    kubectl get po,svc,configMap
    exit 0
fi

# Launches TERArium
if [[ ${1} == "up" ]]; then
    kubectl kustomize . | kubectl apply --filename -
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    kubectl kustomize . | kubectl delete --filename -
    exit 0
fi

# Launches only the Gateway and Authentication services
if [[ ${1} == "gateway" ]]; then
    kubectl kustomize gateway | kubectl apply --filename -
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
