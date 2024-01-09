function copy_s3_directory {
  DIR=$1
  ID=$2
  OUT_DIR=$3

  LS=$(AWS_REGION=${AWS_REGION} AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} aws s3 ls ${S3_DIR}/${DIR}/${ID}/)

  echo "${LS}" | while read line; do
    FILE=$(echo "${line}" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[[:space:]]*//')
    AWS_REGION=${AWS_REGION} AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} aws s3 cp "${S3_DIR}/${DIR}/${ID}/${FILE}" "${OUT_DIR}/${ID}/files/${FILE}" --quiet
  done
}

function is_ok {
  DATA=${1}

  IS_ARRAY=$(echo "${DATA}" | jq 'if type=="array" then true else false end')
  if [ "${IS_ARRAY}" == "false" ]; then
    IS_404=$(echo "${DATA}" | jq 'contains({"status": 404})')
    if [ ! ${IS_404} ]; then
      echo true
    fi
    echo false
  else 
    echo true
  fi
}

function copy_api_data {
  TYPE=$1
  ASSETS="$2"

  echo "Retrieve ${TYPE}"
  TYPE_ASSETS=$(echo "${ASSETS}" | jq --arg type "${TYPE}" '. | to_entries | .[] | select( .key == $type ) ')
  IDS=$(echo "${TYPE_ASSETS}" | jq -r '.value[] | .id')
  for ID in ${IDS}; do
    echo "...exporting ${ID}"
    if [ "${TYPE}" == "artifacts" ] || [ "${TYPE}" == "datasets" ]; then
      copy_s3_directory "${TYPE}" ${ID} "export/${PROJECT_ID}/${TYPE}"
    fi

    if [ "${TYPE}" != "artifacts" ]; then
      JSON=$(fetch_data "${TYPE}/${ID}")
      ANNOTATIONS=$(fetch_data "annotations?artifact_type=${TYPE}&artifact_id=${ID}")


      mkdir -p export/${PROJECT_ID}/${TYPE}/${ID}
      echo "${JSON}" > export/${PROJECT_ID}/${TYPE}/${ID}/${TYPE}.json
      if [ $(is_ok "${ANNOTATIONS}") == true ]; then
        echo "${ANNOTATION}" > export/${PROJECT_ID}/${TYPE}/${ID}/annotation.json
      fi
    fi

    if [ "${TYPE}" == "models" ]; then
      MODEL_CONFIGURATION_JSON=$(fetch_data "${TYPE}/${ID}/model_configurations")
      if [ $(is_ok "${MODEL_CONFIGURATION_JSON}") == true ]; then
        echo "${MODEL_CONFIGURATION_JSON}" > export/${PROJECT_ID}/${TYPE}/${ID}/model_configuration.json
      fi
    fi
  done

}

function fetch_data {
  local PATH="$1"

  local RES=$(/usr/bin/curl -s -H "Authorization: Bearer ${BEARER_TOKEN}" -H "Content-Type: application/json" "${API_URL}/${PATH}")
  echo ${RES}
}

if [[ -z $1 ]]; then
  echo "Please provide a project id"
  exit 1
fi

PROJECT_ID=${1}

echo "Getting Bearer Token"

BEARER_TOKEN=$(curl -s ${KEYCLOAK_URL} -d "client_id=${CLIENT_ID}&username=${USER_ID}&password=${PWD}&grant_type=password" | jq -r '.access_token')

echo "Retrieve project"
PROJECT_JSON=$(fetch_data "/projects/${PROJECT_ID}")
PROJECT_ASSETS=$(fetch_data "/projects/${PROJECT_ID}/assets?types=datasets&types=model_configurations&types=models&types=publications&types=simulations&types=workflows&types=artifacts&types=code&types=documents")

mkdir -p export/${PROJECT_ID}
echo "${PROJECT_JSON}" > export/${PROJECT_ID}/project.json
echo "${PROJECT_ASSETS}" > export/${PROJECT_ID}/assets.json

copy_api_data "artifacts" "${PROJECT_ASSETS}"
CODE=$(echo "${PROJECT_ASSETS}" | jq '.code')
DOCUMENTS=$(echo "${PROJECT_ASSETS}" | jq '.documents')
copy_api_data "datasets" "${PROJECT_ASSETS}"
copy_api_data "models" "${PROJECT_ASSETS}"
PUBLICATIONS=$(echo "${PROJECT_ASSETS}" | jq '.publications')
#${URL}/annotations?artifact_type=publications&artifact_id=61
copy_api_data "workflows" "${PROJECT_ASSETS}"
