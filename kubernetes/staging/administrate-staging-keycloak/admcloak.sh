#!/bin/bash

list() {
    kubectl config get-contexts
}

config() {
    kubectl config set-context askem-staging --cluster=askem-staging --namespace=terarium --user=kubernetes-admin

    kubectl config set-cluster askem-staging --server=https://kubernetes.staging.terarium.ai:16443 --certificate-authority=certificate-authority.cert

    kubectl config set-credentials kubernetes-admin --client-certificate=client-certificate.cert --client-key=client-key.cert
}

set() {
    kubectl config use-context "$1"
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        config)
            COMMAND="config"
            ;;
        set)
            NAME="$2"
            shift
            COMMAND="set"
            ;;
        list)
            COMMAND="list" 
            ;;
        *)
            echo "skc: illegal option"
            break
            ;;
    esac
    shift
done

# Default COMMAND to help if empty
COMMAND=${COMMAND:-help}

case ${COMMAND} in
    set)
        set ${NAME}
        ;;
    list)
        list
        ;;
    config)
        config
        ;;
    help)
        echo "
NAME
    skc - manage Staging Kubernetes Configuration

SYNOPSIS
    skc [set <name> | list | config]

DESCRIPTION
  Launch commands:
    set         Set the current context to the name
    list        List the contexts available
    config      Configure the Kubernetes configuration from Askem Staging with the local configuration 
        "
        ;;
esac
