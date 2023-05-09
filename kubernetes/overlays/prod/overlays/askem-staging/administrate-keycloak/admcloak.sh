#!/bin/bash

SECRET_FILES=( "*.cert" )

decrypt() {
    DECRYPTED_FILES=()
    for SECRET_FILE in ${SECRET_FILES[@]}; do
        echo "decrypting file ${SECRET_FILE}"
        ansible-vault decrypt --vault-id ~/askem-vault-id.txt ${SECRET_FILE}
        STATUS=$?
        if [[ ${STATUS} -eq 0 ]]; then
            DECRYPTED_FILES+=( ${SECRET_FILE} )
        fi
    done
}

encrypt() {
    for SECRET_FILE in ${SECRET_FILES[@]}; do
        ansible-vault encrypt --vault-id ~/askem-vault-id.txt ${SECRET_FILE}
    done
}

restore() {
    for SECRET_FILE in ${DECRYPTED_FILES[@]}; do
        git restore ${SECRET_FILE}
    done
}

list() {
    kubectl config get-contexts
}

config() {
    decrypt
    cp *.cert ~/.kube/
    restore

    kubectl config set-context askem-staging --cluster=askem-staging --user=kubernetes-staging-admin

    kubectl config set-cluster askem-staging --server=https://kubernetes.staging.terarium.ai:16443 --certificate-authority=${1}/.kube/askem-staging-certificate-authority.cert

    kubectl config set-credentials kubernetes-staging-admin --client-certificate=${1}/.kube/askem-staging-client-certificate.cert --client-key=${1}/.kube/askem-staging-client-key.cert
}

set() {
    kubectl config use-context "$1"
}

while [[ $# -gt 0 ]]; do
    case ${1} in
        config)
            HOME_DIR="$2"
            shift
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
        encrypt)
            COMMAND="encrypt"
            ;;
        decrypt)
            COMMAND="decrypt"
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
        config ${HOME_DIR}
        ;;
    encrypt)
        encrypt
        ;;
    decrypt)
        decrypt
        ;;
    help)
        echo "
NAME
    skc - manage Staging Kubernetes Configuration

SYNOPSIS
    skc [set NAME | list | config HOME_DIR]

DESCRIPTION
  Launch commands:
    set         Set the current context to the name
    list        List the contexts available
    config      Configure the Kubernetes configuration from Askem Staging with the local configuration
      HOME_DIR  Absolute path to your home directory
        "
        ;;
esac
