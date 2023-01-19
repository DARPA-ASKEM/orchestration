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

# Launches the Gateway and Authentication services only
if [[ ${1} == "gateway-up" ]]; then
    kubectl kustomize gateway | kubectl apply --filename -
    exit 0
fi

# Tears down the Gateway and Authentication services
if [[ ${1} == "gateway-down" ]]; then
    kubectl kustomize gateway | kubectl delete --filename -
    exit 0
fi

# Launches the TERArium HMI server
if [[ ${1} == "hmi-server-up" ]]; then
    kubectl kustomize hmi/server | kubectl apply --filename -
    exit 0
fi

# Tears down the TERArium HMI server
if [[ ${1} == "hmi-server-down" ]]; then
    kubectl kustomize hmi/server | kubectl delete --filename -
    exit 0
fi

# Launches the TERArium HMI client
if [[ ${1} == "hmi-client-up" ]]; then
    kubectl kustomize hmi/client | kubectl apply --filename -
    exit 0
fi

# Tears down the TERArium HMI client
if [[ ${1} == "hmi-client-down" ]]; then
    kubectl kustomize hmi/client | kubectl delete --filename -
    exit 0
fi


echo "Usage:"
echo "    ${0} status               Displays the status of all services"
echo "    ${0} up                   Launches TERArium"
echo "    ${0} down                 Tears down TERArium"
echo "    ${0} gateway-up           Launches the Gateway and Authentication services"
echo "    ${0} gateway-down         Tears down the Gateway and Authentication services"
echo "    ${0} hmi-server-up        Launches the TERArium HMI server"
echo "    ${0} hmi-server-down      Tears down the TERArium HMI server"
echo "    ${0} hmi-client-up        Launches the TERArium HMI client"
echo "    ${0} hmi-client-down      Tears down the TERArium HMI client"
