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

decrypt() {
	DECRYPTED_FILES=()
	for SECRET_FILE in "${SECRET_FILES[@]}"; do
		echo "decrypting file ${SECRET_FILE}"
		#unpack wildcard - now failing
		for FILE in $(ls ${SECRET_FILE}); do
			ansible-vault decrypt --vault-id ~/askem-vault-id.txt "${FILE}"
		done
		STATUS=$?
		if [[ ${STATUS} -eq 0 ]]; then
			DECRYPTED_FILES+=("${SECRET_FILE}")
		fi
	done
}

encrypt() {
	for SECRET_FILE in "${SECRET_FILES[@]}"; do
		#unpack wildcard - now failing
		for FILE in $(ls ${SECRET_FILE}); do
			ansible-vault encrypt --vault-id ~/askem-vault-id.txt "${FILE}"
		done
	done
}

restore() {
	for SECRET_FILE in "${DECRYPTED_FILES[@]}"; do
		git restore "${SECRET_FILE}"
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
