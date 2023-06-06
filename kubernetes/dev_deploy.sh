#!/bin/bash

GATEWAY_HTTPD_REPLACEMENT_FILE="overlays/dev/local/gateway/configmap/host.yaml"
GATEWAY_HTTPD_REPLACEMENT_FILE_MAC="overlays/dev/local/gateway/configmap/host-mac.yaml"
GATEWAY_HTTPD_REPLACEMENT_FILE_LINUX="overlays/dev/local/gateway/configmap/host-linux.yaml"

HMI_SERVER_REPLACEMENT_FILE="overlays/dev/local/hmi/server/configmap/host.yaml"
HMI_SERVER_REPLACEMENT_FILE_MAC="overlays/dev/local/hmi/server/configmap/host-mac.yaml"
HMI_SERVER_REPLACEMENT_FILE_LINUX="overlays/dev/local/hmi/server/configmap/host-linux.yaml"

SECRET_FILES=()
SECRET_FILES+=("overlays/dev/local/secrets/*.yaml")

source functions.sh

determine_host_machine_for_pods() {
	# Assume Mac using docker
	cp ${GATEWAY_HTTPD_REPLACEMENT_FILE_MAC} ${GATEWAY_HTTPD_REPLACEMENT_FILE}
	cp ${HMI_SERVER_REPLACEMENT_FILE_MAC} ${HMI_SERVER_REPLACEMENT_FILE}

	case $(uname) in
	"Linux")
		# Linux
		cp ${GATEWAY_HTTPD_REPLACEMENT_FILE_LINUX} ${GATEWAY_HTTPD_REPLACEMENT_FILE}
		cp ${HMI_SERVER_REPLACEMENT_FILE_LINUX} ${HMI_SERVER_REPLACEMENT_FILE}

		echo "You are running Linux"
		LOCALHOST=$(hostname -I | awk '{print $1}')
		if [[ "$(</proc/sys/kernel/osrelease)" == *WSL2 ]]; then
			echo "But on Windows in WSL2 mode...  If there's a problem, this is probably it =)"
			LOCALHOST="$(ip a s eth0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)" # Get the IP on eth0
			echo "Assigning docker host to WSL2 VM IP ${LOCALHOST}"
		fi

		echo "editing files replacing 'localhost' with ${LOCALHOST}"

		sed -i.bak "s/localhost/${LOCALHOST}/g" ${GATEWAY_HTTPD_REPLACEMENT_FILE}
		sed -i.bak "s/localhost/${LOCALHOST}/g" ${HMI_SERVER_REPLACEMENT_FILE}
		;;
	esac
}

case ${1} in
-h | --help)
	COMMAND="help"
	;;
test)
	COMMAND="test"
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
decrypt)
	COMMAND="decrypt"
	;;
encrypt)
	COMMAND="encrypt"
	;;
*)
	echo "dev_deploy.sh: illegal option"
	;;
esac

# Default COMMAND to help if empty
COMMAND=${COMMAND:-help}

if [ ${COMMAND} != "help" ]; then
	checkPrograms
fi

case ${COMMAND} in
test)
	echo "## Decrypting secrets"
	decrypt
	echo "## Testing kustomization script"
	kubectl kustomize ./overlays/dev/local | less
	echo "## Restoring secrets as encrypted files"
	restore
	;;
up)
	echo "## Decrypting secrets"
	decrypt
	determine_host_machine_for_pods
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

			user-store)
				echo "Launching USER STORE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/user-store | kubectl apply --filename -
				;;

			message-queue)
				echo "Launching MESSAGE QUEUE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/message-queue | kubectl apply --filename -
				;;

			data-service)
				echo "Launching DATA SERVICE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/data-service | kubectl apply --filename -
				;;

			model-service)
				echo "Launching MODEL SERVICE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/model-service | kubectl apply --filename -
				;;

			services)
				echo "Launching SERVICES on localhost..."
				kubectl kustomize ./overlays/dev/local/services | kubectl apply --filename -
				;;

			hmi)
				echo "Launching HMI on localhost..."
				kubectl kustomize ./overlays/dev/local/hmi | kubectl apply --filename -
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
	echo "## Restoring secrets as encrypted files"
	restore
	;;
down)
	echo "## Decrypting secrets"
	decrypt
	determine_host_machine_for_pods
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

			user-store)
				echo "Tearing down USER STORE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/user-store | kubectl delete --filename -
				;;

			message-queue)
				echo "Tearing down MESSAGE QUEUE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/message-queue | kubectl delete --filename -
				;;

			data-service)
				echo "Tearing down DATA SERVICE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/data-service | kubectl delete --filename -
				;;

			model-service)
				echo "Tearing down MODEL SERVICE on localhost..."
				kubectl kustomize ./overlays/dev/local/services/model-service | kubectl delete --filename -
				;;

			services)
				echo "Tearing down SERVICES on localhost..."
				kubectl kustomize ./overlays/dev/local/services | kubectl delete --filename -
				;;

			hmi)
				echo "Tearing down HMI on localhost..."
				kubectl kustomize ./overlays/dev/local/hmi | kubectl delete --filename -
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
	echo "## Restoring secrets as encrypted files"
	restore
	;;
status)
	kubectl get configMap,svc,po
	;;
decrypt)
	decrypt
	;;
encrypt)
	encrypt
	;;
help)
	echo "
	Usage:
			${0} status              Displays the status of all services
			${0} decrypt             Decrypt secrets for editing
			${0} encrypt             Encrypt secrets for adding to git repo
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
