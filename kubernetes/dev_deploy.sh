#!/bin/bash

# Displays the status of all services
if [[ ${1} == "status" ]]; then
    kubectl get configMap,svc,po
    exit 0
fi



# Launches TERArium
if [[ ${1} == "up" ]]; then
	case ${2} in
    hmi-client)
    	echo "Launching HMI CLIENT on localhost..."
      kubectl kustomize ./overlays/dev/local/hmi/client | kubectl apply --filename -
      ;;

    hmi-server)
    	echo "Launching HMI SERVER on localhost..."
      kubectl kustomize ./overlays/dev/local/hmi/server | kubectl apply --filename -
      ;;

    hmi-postgres)
    	echo "Launching HMI POSTGRES DB on localhost..."
      kubectl kustomize ./overlays/dev/local/hmi/server/postgres | kubectl apply --filename -
    	;;

  	data-service)
  		echo "Launching DATA SERVICE on localhost..."
    	kubectl kustomize ./overlays/dev/local/services/data-service | kubectl apply --filename -
      ;;

    document-service)
    	echo "Launching DOCUMENT SERVICE on localhost..."
      kubectl kustomize ./overlays/dev/local/services/document-service | kubectl apply --filename -
    	;;

    model-service)
    	echo "Launching MODEL SERVICE on localhost..."
      kubectl kustomize ./overlays/dev/local/services/model-service | kubectl apply --filename -
      ;;

    gateway)
    	echo "Launching GATEWAY on localhost..."
      kubectl kustomize ./overlays/dev/local/gateway | kubectl apply --filename -
      ;;

    "")
    	echo "Launching TERArium on localhost..."
      kubectl kustomize ./overlays/dev/local | kubectl apply --filename -
      ;;

    *)
      echo "Please specify a valid service or leave blank to launch TERArium."
      ;;
  esac
    exit 0
fi



# Tears down TERArium
if [[ ${1} == "down" ]]; then
	case ${2} in
      hmi-client)
      	echo "Tearing down HMI CLIENT on localhost..."
        kubectl kustomize ./overlays/dev/local/hmi/client | kubectl delete --filename -
        ;;

      hmi-server)
      	echo "Tearing down HMI SERVER on localhost..."
        kubectl kustomize ./overlays/dev/local/hmi/server | kubectl delete --filename -
        ;;

      hmi-postgres)
      	echo "Tearing down HMI POSTGRES DB on localhost..."
        kubectl kustomize ./overlays/dev/local/hmi/server/postgres | kubectl delete --filename -
      	;;

    	data-service)
    		echo "Tearing down DATA SERVICE on localhost..."
      	kubectl kustomize ./overlays/dev/local/services/data-service | kubectl delete --filename -
        ;;

      document-service)
      	echo "Tearing down DOCUMENT SERVICE on localhost..."
        kubectl kustomize ./overlays/dev/local/services/document-service | kubectl delete --filename -
      	;;

      model-service)
      	echo "Tearing down MODEL SERVICE on localhost..."
        kubectl kustomize ./overlays/dev/local/services/model-service | kubectl delete --filename -
        ;;

      gateway)
      	echo "Tearing down GATEWAY on localhost..."
        kubectl kustomize ./overlays/dev/local/gateway | kubectl delete --filename -
        ;;

      "")
      	echo "Tearing down TERArium on localhost..."
        kubectl kustomize ./overlays/dev/local | kubectl delete --filename -
        ;;

      *)
        echo "Please specify a valid service or leave blank to launch TERArium."
        ;;
    esac
      exit 0
fi



echo "Usage:"
echo "    ${0} status           Displays the status of all services"
echo "    ${0} up [service]     Launch TERArium or individual service"
echo "    ${0} down [service]   Tear down TERArium or individual service"
echo " "
echo "Services include:"
echo "    - hmi-client"
echo "    - hmi-server"
echo "    - hmi-postgres"
echo "    - data-service"
echo "    - document-service"
echo "    - model-service"
echo "    - gateway"
