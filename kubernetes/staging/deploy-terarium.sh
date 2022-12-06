#!/bin/bash

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl get po,svc,configMap -n terarium
    exit 0
fi

# Launches TERArium
if [[ ${1} == "up" ]]; then
    cat namespace.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat secrets-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat gateway-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat data-*.yaml         |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat model-*.yaml        |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    cat hmi-*.yaml          |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    cat hmi-*.yaml          |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat model-*.yaml        |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat data-*.yaml         |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat gateway-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat secrets-*.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    cat namespace.yaml      |  ssh uncharted-askem-staging-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    exit 0
fi

echo "Usage:"
echo "    ${0} up      Launch TERArium"
echo "    ${0} down    Tear-down TERArium"
