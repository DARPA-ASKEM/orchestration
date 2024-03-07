#!/bin/bash
if [ ! -f .env ]; then
  echo "Missing .env file"
  help
  exit 1
fi

# import enviroment variables (.env file)
unamestr=$(uname)
if [ "$unamestr" = 'Linux' ]; then
 export $(grep -v '^#' .env | xargs -d '\n')
elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
 export $(grep -v '^#' .env | xargs -0)
fi


SECRET_FILES=("export_secrets.sh" "staging_import_secrets.sh" "production_import_secrets.sh" "import_secrets.sh")

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
    ENVIRONMENT="$3"
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

  echo "## Export data"
  ./export_project.sh ${ID}

  echo "## Restoring secrets as encrypted files"
  restore
	;;
import)
  echo "## Decrypting secrets"
  decrypt

  echo "## Import data"
  ./import_project.sh ${ID} ${ENVIRONMENT}

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
