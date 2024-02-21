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

# SOPS
decrypt() {
  DECRYPTED_FILES=()
  for LOCATION in ${SECRET_FILES[@]}; do
    for SECRET_FILE in `ls -1 ${LOCATION}`; do
      echo "decrypting file ${SECRET_FILE}"
      sops --decrypt --in-place ${SECRET_FILE}
      STATUS=$?
      if [[ ${STATUS} -eq 0 ]]; then
        DECRYPTED_FILES+=( ${SECRET_FILE} )
      fi
    done
  done
}

encrypt() {
  echo ${AGE_PUBLIC_KEY}
  for LOCATION in ${SECRET_FILES[@]}; do
    for SECRET_FILE in `ls -1 ${LOCATION}`; do
      echo "encrypting file ${SECRET_FILE}"
      if [[ ${SECRET_FILE} == *.yaml ]]; then
        # YAML
        sops --age=${AGE_PUBLIC_KEY} --encrypt --encrypted-regex '^(data|stringData)$' --in-place ${SECRET_FILE}
      else
        # JSON and other
        sops --age=${AGE_PUBLIC_KEY} --encrypt --in-place ${SECRET_FILE}
      fi
      STATUS=$?
      if [[ ${STATUS} -eq 0 ]]; then
        DECRYPTED_FILES+=( ${SECRET_FILE} )
      fi
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
