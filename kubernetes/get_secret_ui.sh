#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p gum yq-go jq

if [[ -z $IN_NIX_SHELL ]]; then
  echo "Please install 'nix-shell'

for Mac use:

  curl -L https://nixos.org/nix/install | sh

for Linux

  curl -L https://nixos.org/nix/install | sh -s -- --daemon

For more details see: https://nix.dev/install-nix
  "
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

OPERATION=$(gum choose "decrypt" "encrypt")

ENVIRONMENT=$(gum choose "staging" "production" "dev")

echo "Using $(gum style --foreground 212 "${ENVIRONMENT}") environment"

case ${ENVIRONMENT} in
staging)
  SECRET_FILES=(${STAGING_YAML[@]})
	;;
production)
  SECRET_FILES=(${PRODUCTION_YAML[@]})
	;;
dev)
	SECRET_FILES=(${DEV_YAML[@]})
	;;
esac

select_file() {
  # delcare array/map called FILE_LOCATIONS
  declare -A FILE_LOCATIONS

  local FILES=()
  for SECRET_FILE in ${SECRET_FILES[@]}; do
    local FILE=${SECRET_FILE##*/}
    FILE_LOCATIONS+=([${FILE}]=${SECRET_FILE})
    FILES+=(${FILE})
  done

  local FILE=$(gum choose ${FILES[@]})
  echo ${FILE_LOCATIONS[${FILE}]}
}

FILE=$(select_file)

echo "Using secrets from $(gum style --foreground 212 "${FILE}")"

ENC_FILENAME=$(get_enc_filename ${FILE})

echo ${ENC_FILENAME}

KEYS=$(yq -o json '.data | keys' ${ENC_FILENAME} | jq -r '@sh' | tr -d \')

KEY=$(gum choose ${KEYS[@]})

decrypt_file ${FILE}

if [ ${OPERATION} == decrypt ]; then
  BASE64_VALUE=$(argkey="${KEY}" yq -o json '.data[env(argkey)]' ${FILE} | tr -d \")

  echo "For key $(gum style --foreground 212 "${KEY}")"
  echo "  Base64 Value is $(gum style --foreground 212 "${BASE64_VALUE}")"

  VALUE=$(echo ${BASE64_VALUE} | base64 -d)

  echo "  Value is $(gum style --foreground 212 "${VALUE}")"
else
  echo "TODO encrypt"
fi

restore
