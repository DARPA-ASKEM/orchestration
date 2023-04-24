# import enviroment variables (.env file)
unamestr=$(uname)
if [ "$unamestr" = 'Linux' ]; then
  export $(grep -v '^#' .env | xargs -d '\n')
elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
  export $(grep -v '^#' .env | xargs -0)
fi

decrypt_ansible() {
	DECRYPTED_FILES=()
	for SECRET_FILE in "${SECRET_FILES[@]}"; do
		echo "decrypting file ${SECRET_FILE}"
		#unpack wildcard - now failing
		for FILE in `ls ${SECRET_FILE}`; do
			ansible-vault decrypt --vault-id ~/askem-vault-id.txt "${FILE}"
		done
		STATUS=$?
		if [[ ${STATUS} -eq 0 ]]; then
			DECRYPTED_FILES+=("${SECRET_FILE}")
		fi
	done
}

encrypt_ansible() {
	for SECRET_FILE in "${SECRET_FILES[@]}"; do
		#unpack wildcard - now failing
		for FILE in `ls ${SECRET_FILE}`; do
			ansible-vault encrypt --vault-id ~/askem-vault-id.txt "${FILE}"
		done
	done
}

restore_ansible() {
	for SECRET_FILE in "${DECRYPTED_FILES[@]}"; do
		git restore "${SECRET_FILE}"
	done
}

# SOPS
decrypt_sops() {
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

restore_sops() {
    for SECRET_FILE in ${DECRYPTED_FILES[@]}; do
        git restore ${SECRET_FILE}
    done
}

encrypt_sops() {
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