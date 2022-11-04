#!/bin/bash


if [[ ${1} == "up" ]]; then

		# Manually pulling images here, as the K8s sometimes timeout
		docker pull ghcr.io/unchartedsoftware/httpd-openidc:0.1.2
		docker pull ghcr.io/unchartedsoftware/keycloak:0.1.2
		docker pull docker.uncharted.software/auth/terarium-theme:0.0.1
		docker pull ghcr.io/darpa-askem/hmi-server:dev
		docker pull ghcr.io/darpa-askem/webapp:dev

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
    -f webapp-service.yaml \
    -f webapp-deployment.yaml

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
    -f webapp-service.yaml \
    -f webapp-deployment.yaml

    exit 0
fi

if [[ ${1} == "status" ]]; then
    kubectl get po,svc,configMap

    exit 0
fi

echo "Usage:"
echo "    ${0} up        launches the Gateway and Authentication services"
echo "    ${0} down      tears down the Gateway and Authentication services"
echo "    ${0} status    displays the status of the Gateway and Authentication services"
