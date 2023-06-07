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
