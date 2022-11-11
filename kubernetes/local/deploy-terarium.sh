#!/bin/bash


if [[ ${1} == "up" ]]; then

    kubectl apply \
    -f gateway-postgres-service.yaml \
    -f gateway-postgres-deployment.yaml \
    -f gateway-keycloak-realm.yaml \
    -f gateway-keycloak-service.yaml \
    -f gateway-keycloak-deployment.yaml \
    -f gateway-httpd-config.yaml \
    -f gateway-httpd-htdocs.yaml \
    -f gateway-httpd-service.yaml \
    -f gateway-httpd-deployment.yaml \
    -f hmi-server-service.yaml \
    -f hmi-server-deployment.yaml \
    -f hmi-client-service.yaml \
    -f hmi-client-deployment.yaml

    exit 0
fi

if [[ ${1} == "down" ]]; then
    kubectl delete \
    -f gateway-postgres-service.yaml \
    -f gateway-postgres-deployment.yaml \
    -f gateway-keycloak-realm.yaml \
    -f gateway-keycloak-service.yaml \
    -f gateway-keycloak-deployment.yaml \
    -f gateway-httpd-config.yaml \
    -f gateway-httpd-htdocs.yaml \
    -f gateway-httpd-service.yaml \
    -f gateway-httpd-deployment.yaml \
    -f hmi-server-service.yaml \
    -f hmi-server-deployment.yaml \
    -f hmi-client-service.yaml \
    -f hmi-client-deployment.yaml

    exit 0
fi

if [[ ${1} == "status" ]]; then
    kubectl get po,svc,configMap

    exit 0
fi

if [[ ${1} == "dev" ]]; then

    kubectl apply \
    -f gateway-postgres-service.yaml \
    -f gateway-postgres-deployment.yaml \
    -f gateway-keycloak-realm.yaml \
    -f gateway-keycloak-service.yaml \
    -f gateway-keycloak-deployment.yaml \
    -f gateway-httpd-config.yaml \
    -f gateway-httpd-htdocs.yaml \
    -f gateway-httpd-service.yaml \
    -f gateway-httpd-deployment.yaml

    exit 0
fi

echo "Usage:"
echo "    ${0} up        launches TERArium"
echo "    ${0} down      tears down TERArium"
echo "    ${0} dev       launches only the Gateway and Authentication services"
echo "    ${0} status    displays the status of the Gateway and Authentication services"
