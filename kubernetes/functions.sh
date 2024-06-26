checkPrograms() {
	if ! command -v ansible-vault &>/dev/null; then
		echo "[ERROR] the program \"ansible-vault\" could not be found."
		exit
	fi

	if ! command -v git &>/dev/null; then
		echo "[ERROR] the program \"git\" could not be found."
		exit
	fi

	if ! command -v kubectl &>/dev/null; then
		echo "[ERROR] the program \"kubectl\" could not be found."
		exit
	fi
}

get_enc_filename() {
  local SECRET_FILE=${1}

  local EXTENSION="${SECRET_FILE##*.}"
  local FILENAME="${SECRET_FILE%.*}"
  local ENC_FILENAME="${FILENAME}.enc.${EXTENSION}"
  if [[ ${EXTENSION} == ${FILENAME} ]]; then
    ENC_FILENAME="${FILENAME}.enc"
  fi
  
  echo ${ENC_FILENAME}
}

decrypt() {
  DECRYPTED_FILES=()
  for SECRET_FILE in ${SECRET_FILES[@]}; do
    decrypt_file ${SECRET_FILE}
  done
}

get_file_by_name() {
  FILE_NAME=${1}
  for SECRET_FILE in ${SECRET_FILES[@]}; do
    if [ ${SECRET_FILE##*/} == ${FILE_NAME} ]; then
      echo ${SECRET_FILE}
      local FILE=${SECRET_FILE}
    fi
  done
  if [ ! -z ${FILE} ]; then
    echo ${FILE}
  fi
}

decrypt_file_by_name() {
  local FILE_NAME=${1}
  local FILE=$(get_file_by_name ${FILE_NAME})
  if [[ -z ${FILE} ]]; then
    echo "did not find file to decrypt"
  else
    decrypt_file ${FILE}
    echo "file decrypted"
  fi
}

decrypt_file() {
  SECRET_FILE=${1}
  ENC_FILENAME=$(get_enc_filename ${SECRET_FILE})

  # echo "decrypting file ${SECRET_FILE}"
  sops --decrypt ${ENC_FILENAME} > ${SECRET_FILE}
  STATUS=$?
  if [[ ${STATUS} -eq 0 ]]; then
    DECRYPTED_FILES+=( ${SECRET_FILE} )
  fi
}

encrypt_file_by_name() {
  local FILE_NAME=${1}
  local FILE=$(get_file_by_name ${FILE_NAME})
  if [[ -z ${FILE} ]]; then
    echo "did not find file to encrypt"
  else
    encrypt_file ${FILE}
    echo "file encrypted"
  fi
}

encrypt() {
  if [[ -z ${AGE_PUBLIC_KEY} ]]; then
    echo "Encryption key not set correctly in .env"
  else
    for SECRET_FILE in ${SECRET_FILES[@]}; do
      encrypt_file ${SECRET_FILE}
    done
  fi
}

encrypt_file() {
  local SECRET_FILE=${1}
  local ENC_FILENAME=$(get_enc_filename ${SECRET_FILE})

  local EXTENSION="${SECRET_FILE##*.}"
  # echo "encrypting file ${SECRET_FILE}"
  if [[ ${EXTENSION} == yaml ]]; then
    # YAML
    sops --age=${AGE_PUBLIC_KEY} --encrypt --encrypted-regex '^(data|stringData)$' ${SECRET_FILE} > ${ENC_FILENAME}
  else
    # JSON and other
    sops --age=${AGE_PUBLIC_KEY} --encrypt ${SECRET_FILE} > ${ENC_FILENAME}
  fi
  STATUS=$?
  if [[ ${STATUS} -eq 0 ]]; then
    DECRYPTED_FILES+=( ${SECRET_FILE} )
  fi
}

restore() {
  for SECRET_FILE in ${SECRET_FILES[@]}; do
		rm ${SECRET_FILE}
	done
}

dumpIpForInterface() {
  IT=$(ifconfig "$1")
  if [[ "$IT" != *"status: active"* ]]; then
    return
  fi
  if [[ "$IT" != *" broadcast "* ]]; then
    return
  fi
  echo "$IT" | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
}

getMacIpAddress() {
  # snagged from here: https://superuser.com/a/627581/38941
  DEFAULT_ROUTE=$(route -n get 0.0.0.0 2>/dev/null | awk '/interface: / {print $2}')
  if [ -n "$DEFAULT_ROUTE" ]; then
    dumpIpForInterface "$DEFAULT_ROUTE"
  else
    for i in $(ifconfig -s | awk '{print $1}' | awk '{if(NR>1)print}')
    do
      if [[ $i != *"vboxnet"* ]]; then
        dumpIpForInterface "$i"
      fi
    done
  fi
}
