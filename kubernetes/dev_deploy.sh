#!/bin/bash

# Write out an environment file locally to populate the kube configs
filename="overlays/dev/local/environment-variables.env"
# default
LOCALHOST="host.docker.internal"

get_os(){
	case $(uname) in
			"Linux")
					# Linux
					echo "You are running Linux"
					LOCALHOST=$(hostname -I | awk '{print $1}')
					if [[ "$(< /proc/sys/kernel/osrelease)" == *WSL2 ]];
					then
							echo "But on Windows in WSL2 mode...  If there's a problem, this is probably it =)"
							LOCALHOST="`ip a s eth0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2`" # Get the IP on eth0
							echo "Assigning docker host to WSL2 VM IP ${LOCALHOST}"
					fi
					;;
	esac
	echo "LOCALHOST=${LOCALHOST}" > "$filename"
}

get_os

case ${1} in
	-h | --help)
		COMMAND="help"
		;;
	up)
		COMMAND="up"
		shift
		SERVICES=("$@")
		;;
	down)
		COMMAND="down"
		shift
		SERVICES=("$@")
		;;
	status)
		COMMAND="status"
		;;
	*)
		echo "dev_deploy.sh: illegal option"
		;;
esac

# Default COMMAND to help if empty
COMMAND=${COMMAND:-help}

case ${COMMAND} in
	up)
		if [ "${#SERVICES[@]}" -eq 0 ]; then
			echo "Launching TERArium on localhost..."
			kubectl kustomize ./overlays/dev/local | kubectl apply --filename -
		else
			for SERVICE in "${SERVICES[@]}"; do
				case ${SERVICE} in
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

					model-service)
						echo "Launching MODEL SERVICE on localhost..."
						kubectl kustomize ./overlays/dev/local/services/model-service | kubectl apply --filename -
						;;

					gateway)
						echo "Launching GATEWAY on localhost..."
						kubectl kustomize ./overlays/dev/local/gateway | kubectl apply --filename -
						;;

					*)
						echo "'${SERVICE}' is not a valid service. Please specify a valid service."
						;;
				esac
			done
		fi
		;;
	down)
		if [ "${#SERVICES[@]}" -eq 0 ]; then
			echo "Launching TERArium on localhost..."
			kubectl kustomize ./overlays/dev/local | kubectl delete --filename -
		else
			for SERVICE in "${SERVICES[@]}"; do
				case ${SERVICE} in
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
			done
		fi
		;;
	status)
		kubectl get configMap,svc,po
		;;
	help)
		echo "
	Usage:
			${0} status              Displays the status of all services
			${0} up [SERVICE(s)]     Launch TERArium or specific services
			${0} down [SERVICE(s)]   Tear down TERArium or specific service

	SERVICEs include:
			hmi-client
			hmi-server
			hmi-postgres
			data-service
			model-service
			gateway
			"
		;;
esac
