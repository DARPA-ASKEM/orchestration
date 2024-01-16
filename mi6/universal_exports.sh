#!/bin/bash

SECRET_FILES=("export_secrets.sh" "import_secrets.sh")

source ../kubernetes/functions.sh

while [[ $# -gt 0 ]]; do
	case ${1} in
	-h | --help)
		COMMAND="help"
		;;
	export)
		COMMAND="export"
		ID="$2"
		shift
		;;
	import)
		COMMAND="import"
		ID="$2"
		shift
		;;
	encrypt)
		COMMAND="encrypt"
		shift
		;;
	decrypt)
		COMMAND="decrypt"
		shift
		;;
	*)
		echo "universal_exports.sh: illegal option"
		break
		;;
	esac
	shift
done

case ${COMMAND} in
export)
  echo "## Decrypting secrets"
  decrypt

  echo "## Applying kustomization script to Kubernetes cluster"
  ./export_project.sh ${ID}

  echo "## Restoring secrets as encrypted files"
  restore
	;;
import)
  echo "## Decrypting secrets"
  decrypt

  echo "## TODO"
  
  echo "## Restoring secrets as encrypted files"
  restore
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
    universal_exports.sh - export and import projects

SYNOPSIS
    universal_exports.sh [export | import | decrypt | encrypt] PROJECT_ID

DESCRIPTION
    PROJECT_ID        id to be exported or imported

  commands:
    import            Import a specific project
    export            Export a specific project

  Other commands:
    encrypt           Encrypt secrets for adding to git repo
    decrypt           Decrypt secrets for editing
    "
	;;
esac
