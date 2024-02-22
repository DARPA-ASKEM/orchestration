#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p gum yq-go jq

if [[ -z $IN_NIX_SHELL ]]; then
  echo "Please install `nix-shell` - for Mac use:"
  echo ""
  echo "curl -L https://nixos.org/nix/install | sh"
  echo ""
  echo "For more details see: https://nix.dev/install-nix"
  echo ""
  exit 1
fi

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

source secret_files.sh
source functions.sh

set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Extract Secret.
 
This script will find all the secrets for a given environment,
decrypting them as requested.'

ENVIRONMENT=$(gum choose "staging" "production")

echo "Using $(gum style --foreground 212 "${ENVIRONMENT}") environment"

case ${ENVIRONMENT} in
staging)
  SECRET_FILES=(${STAGING_YAML[@]})
	;;
production)
  SECRET_FILES=(${PRODUCTION_YAML[@]})
	;;
esac

decrypt

declare -A FILE_LOCATIONS

FILES=()
for LOCATION in ${SECRET_FILES[@]}; do
  FILE=${LOCATION##*/}
  FILE_LOCATIONS+=([${FILE}]=${LOCATION})
  FILES+=(${FILE})
done

FILE=$(gum choose ${FILES[@]})

echo "Using secrets from $(gum style --foreground 212 "${FILE}")"

KEYS=$(yq -o json '.data | keys' ${FILE_LOCATIONS[${FILE}]} | jq -r '@sh' | tr -d \')

KEY=$(gum choose ${KEYS[@]})

BASE64_VALUE=$(argkey="${KEY}" yq -o json '.data[env(argkey)]' ${FILE_LOCATIONS[${FILE}]} | tr -d \")

echo "For key $(gum style --foreground 212 "${KEY}")"
echo "  Base64 Value is $(gum style --foreground 212 "${BASE64_VALUE}")"

VALUE=$(echo ${BASE64_VALUE} | base64 -d)

echo "  Value is $(gum style --foreground 212 "${VALUE}")"

restore
