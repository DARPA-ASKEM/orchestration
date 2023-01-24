#!/bin/bash

## import enviroment variables (.env file)
#unamestr=$(uname)
#if [ "$unamestr" = 'Linux' ]; then
#  export $(grep -v '^#' .env | xargs -d '\n')
#elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
#  export $(grep -v '^#' .env | xargs -0)
#fi

SECRET_FILES=( )

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

while [[ $# -gt 0 ]]; do
    case ${1} in
        -h|--help)
            COMMAND="help"
            ;;
        test)
            COMMAND="test"
            ENVIRONMENT="$2"
            shift
            ;;
        up)
            COMMAND="up"
            ENVIRONMENT="$2"
            shift
            ;;
        down)
            COMMAND="down"
            ENVIRONMENT="$2"
            shift
            ;;
        status)
            COMMAND="status"
            ENVIRONMENT="$2"
            shift
            ;;
        encrypt)
            COMMAND="encrypt"
            ENVIRONMENT="$2"
            shift
            ;;
        decrypt)
            COMMAND="decrypt"
            ENVIRONMENT="$2"
            shift
            ;;
        *)
            echo "deploy.sh: illegal option"
            break
            ;;
    esac
    shift
done

# Default COMMAND to help if empty
COMMAND=${COMMAND:-help}
if [ -z "${ENVIRONMENT}" ]; then
    echo "deploy.sh: missing ENVIRONMENT"
    COMMAND="help"
fi

case ${ENVIRONMENT} in
    d | development)
        KUSTOMIZATION=dev/local
        KUBECTL_CMD="kubectl"
        ;;
    s | staging)
        SECRET_FILES+=("prod/base/gateway/certificates/cert.pem" "prod/base/gateway/certificates/key.pem")
        SECRET_FILES+=("prod/askem-staging/secrets/*.yaml")
        SECRET_FILES+=("prod/askem-staging/gateway/keycloak/realm/*.json")
        KUSTOMIZATION=prod/askem-staging
        KUBECTL_CMD="ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl"
        ;;
    p | production)
        SECRET_FILES+=("prod/base/gateway/certificates/cert.pem" "prod/base/gateway/certificates/key.pem")
        SECRET_FILES+=("prod/askem-production/secrets/*.yaml")
        SECRET_FILES+=("prod/askem-production/gateway/keycloak/realm/*.json")
        KUSTOMIZATION=prod/askem-production
        KUBECTL_CMD="ssh uncharted-askem-prod-askem-prod-kube-manager-1 sudo kubectl"
        ;;
esac

case ${COMMAND} in
    test)
        echo "## Decrypting secrets"
        decrypt
        echo "## Testing kustomization script"
        kubectl kustomize ${KUSTOMIZATION} | less
        echo "## Restoring secrets as encrypted files"
        restore
        ;;
    up)
        echo "## Decrypting secrets"
        decrypt
        echo "## Applying kustomization script to Kubernetes cluster"
        kubectl kustomize ${KUSTOMIZATION} | ${KUBECTL_CMD} apply --filename -
        echo "## Restoring secrets as encrypted files"
        restore
        ;;
    down)
        echo "## Decrypting secrets"
        decrypt
        echo "## Deleting kustomization script from Kubernetes cluster"
        kubectl kustomize ${KUSTOMIZATION} | ${KUBECTL_CMD} delete --filename -
        echo "## Restoring secrets as encrypted files"
        restore
        ;;
    status)
        ${KUBECTL_CMD} get configMap,secrets,deployments,svc,po
        ;;
    decrypt)
        decrypt
        ;;
    encrypt)
        encrypt
        ;;
    help)
        echo "
NAME
    deploy.sh - deploy TERArium

SYNOPSIS
    deploy.sh [up | down | status | test | decrypt | encrypt] ENVIRONMENT

DESCRIPTION
  Environment:
    ENVIRONMENT        Must be supplied to indicate which environment should be processed
      d | development
      s | staging
      p | production

  Launch commands:
    up                Launches the entire TERArium stack
    down              Tears down the entire TERArium stack

  Other commands:
    status            Displays the status of the TERArium cluster
    encrypt           Encrypt secrets for adding to git repo
    decrypt           Decrypt secrets for editing
    "
    ;;

#  Environment Variables will be read from a '.env' file, the following can be set
#    AGE_PUBLIC_KEY    the 'askem.agekey' file's public key
#    SOPS_AGE_KEY_FILE location of the file 'askem.agekey'
esac
