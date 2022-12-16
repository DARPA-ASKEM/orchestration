#!/bin/bash

decrypt() {
    ansible-vault decrypt --vault-id ~/askem-vault-id.txt secrets*.yaml
    ansible-vault decrypt --vault-id ~/askem-vault-id.txt gateway/keycloak/certificates/*.pem
    ansible-vault decrypt --vault-id ~/askem-vault-id.txt gateway/keycloak/realm/*.json
}

encrypt() {
    ansible-vault encrypt --vault-id ~/askem-vault-id.txt secrets*.yaml
    ansible-vault encrypt --vault-id ~/askem-vault-id.txt gateway/keycloak/certificates/*.pem
    ansible-vault encrypt --vault-id ~/askem-vault-id.txt gateway/keycloak/realm/*.json
}

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl get po,svc,configMap -n terarium
    exit 0
fi

if [[ ${1} == "decrypt" ]]; then
    decrypt
    exit 0
fi
if [[ ${1} == "encrypt" ]]; then
    encrypt
    exit 0
fi

# Launches TERArium
if [[ ${1} == "up" ]]; then
    decrypt
    kubectl kustomize . | ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl apply --filename -
    exit 0
fi

# Tears down TERArium
if [[ ${1} == "down" ]]; then
    decrypt
    kubectl kustomize . | ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl delete --filename -
    exit 0
fi

echo "Usage:"
echo "    ${0} up      Launch TERArium"
echo "    ${0} down    Tear-down TERArium"
echo "    ${0} status  Display status of running TERArium"
echo "    ${0} decrypt Decrypt secret files"
echo "    ${0} encrypt Encrypt secret files"
