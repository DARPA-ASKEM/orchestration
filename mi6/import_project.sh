
function copy_s3_directory {
  SOURCE=$1
  DEST=$2

  AWS_REGION=${AWS_REGION} AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} aws s3 cp "${SOURCE}" "${DEST}" --quiet
}

function execute_sql() {
  local SQL=$1

  PGPASSWORD=${SQL_PWD} psql -h ${SQL_HOST} -p ${SQL_PORT} -U ${SQL_UID} ${SQL_DATABASE} -c "${SQL}"
}

function execute_sql_save_csv() {
  local SQL=$1
  local FILENAME=$2

  PGPASSWORD=${SQL_PWD} psql -h ${SQL_HOST} -p ${SQL_PORT} -U ${SQL_UID} ${SQL_DATABASE} -t -A -F"," -c "${SQL}" > ${FILENAME}
}

CACHED_USER_ID=""
function get_user_id() {
  local USER_NAME=$1

  echo "Cached User check " >&2
  if [ -z ${CACHED_USER_ID} ]; then
    echo "No Cached User Found" >&2
    # Beta environemnt does not have users
    if [ ${ENVIRONMENT} = "beta_" ]; then
      USER_NAME="Import Test"
    fi

    USERS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json" "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/roles/user/users")
    CACHED_USER_ID=$(echo ${USERS_JSON} | jq -r --arg user_name "${USER_NAME}" '.[] | {id: .id, username: (.firstName + " " + .lastName)} | select(.username | contains($user_name) ) | .id')
    if [ -z ${CACHED_USER_ID} ]; then
      echo "No User Found for ${USER_NAME}" >&2
    fi
  fi
  echo "${CACHED_USER_ID}"
}

function getGroupId() {
  local GROUP_NAME=$1

  GROUPS_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json" ${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/groups)
  GROUP_ID=$(echo "${GROUPS_JSON}" | jq -r ".[] | select(.name | contains(\"${GROUP_NAME}\")) | .id")
  if [ -z ${GROUP_ID} ]; then
    echo "  ...ERROR: could not find group \"${GROUP_NAME}\"'s id" >&2
    exit 1
  fi

  echo ${GROUP_ID}
}


function assignGroupToProject() {
  local PROJECT_ID=$1
  local GROUP_ID=$2
  local RELATIONSHIP=$3

  local GROUP_FOUND=$(zed ${SPICEDB_SETTINGS} relationship read project:${PROJECT_ID} 2>/dev/null | grep "${RELATIONSHIP} group:${GROUP_ID}")
  if [ -z "${GROUP_FOUND}" ]; then
    echo "  ...creating Project ${PROJECT_ID} relationship with Group ${GROUP_ID}" >&2
    zed ${SPICEDB_SETTINGS} relationship create project:${PROJECT_ID} ${RELATIONSHIP} group:${GROUP_ID} 2>/dev/null
  else
    echo "  ...Group \"${GROUP_ID}\" is a ${RELATIONSHIP} of Project \"${PROJECT_ID}\"" >&2
  fi
}

function prepare_csv_line_for_sql() {
  local CSV_LINE=$1

  local PREPARED=$(echo ${CSV_LINE}| sed "s/\"/'/g" | sed "s/''/null/g")

  echo "${PREPARED}"
}

function insert_project() {
  local USER_ID=$1
  echo "Project" >&2

  local PROJECT_UUID=$(uuidgen | awk '{print tolower($0)}')
  local SQL_DATA=$(jq -r --arg user_id "${USER_ID}" --arg uuid "${PROJECT_UUID}" '{id: $uuid, name: .name, description: .description, timestamp: .timestamp, user_id: $user_id} | map([.] | .[]) | @csv' export/78/project.json)
  local VALUES=$(prepare_csv_line_for_sql "${SQL_DATA}")
  local SQL="insert into project (id, name, description, created_on, user_id) values (${VALUES})"

  local RES=$(execute_sql "${SQL}")
  echo "  ...added Project ${PROJECT_UUID} to database" >&2
  echo "zed ${SPICEDB_SETTINGS} relationship create project:${PROJECT_UUID} creator user:${USER_ID}"
  zed ${SPICEDB_SETTINGS} relationship create project:${PROJECT_UUID} creator user:${USER_ID} 2>/dev/null

  local PUBLIC_PROJECT=$(jq -r '.publicProject' export/${PROJECT_ID}/project.json)
  local USER_PERMISSION=$(jq -r '.userPermission' export/${PROJECT_ID}/project.json)

  if [ "${PUBLIC_PROJECT}" == "true" ]; then
    assignGroupToProject ${PROJECT_UUID} ${PUBLIC_GROUP_ID} ${USER_PERMISSION}
  fi

  local MISSING_TIMESTAMP=""

  # DATASETS
  local IDS=$(jq -r '.datasets[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen | awk '{print tolower($0)}')
    local TIMESTAMP=$(jq -r '.timestamp' export/${PROJECT_ID}/datasets/${ID}/datasets.json)
    if [ "${MISSING_TIMESTAMP}" = "" ]; then
      MISSING_TIMESTAMP="${TIMESTAMP}"
    fi
    local NAME=$(jq -r '.name' export/${PROJECT_ID}/datasets/${ID}/datasets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on, asset_name) values ('${UUID}','${ID}','DATASET','${PROJECT_UUID}','${TIMESTAMP}','${NAME}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Dataset Asset ${UUID} to database" >&2
  done

  # ARTIFACTS
  local IDS=$(jq -r '.artifacts[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen | awk '{print tolower($0)}')
    local TIMESTAMP=$(jq -r --arg id "${ID}" '.artifacts[] | select(.id == $id) | .timestamp' export/${PROJECT_ID}/assets.json)
    local NAME=$(jq -r --arg id "${ID}" '.artifacts[] | select(.id == $id) | .name' export/${PROJECT_ID}/assets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on, asset_name) values ('${UUID}','${ID}','ARTIFACT','${PROJECT_UUID}','${TIMESTAMP}','${NAME}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Artifact Asset ${UUID} to database" >&2
  done

  # MODELS
  local IDS=$(jq -r '.models[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen | awk '{print tolower($0)}')
    local NAME=$(jq -r --arg id "${ID}" '.models[] | select(.id == $id) | .name' export/${PROJECT_ID}/assets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on, asset_name) values ('${UUID}','${ID}','MODEL','${PROJECT_UUID}','${MISSING_TIMESTAMP}', '${NAME}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Model Asset ${UUID} to database" >&2
  done

  # WORKFLOWS
  local IDS=$(jq -r '.workflows[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen | awk '{print tolower($0)}')
    local NAME=$(jq -r --arg id "${ID}" '.workflows[] | select(.id == $id) | .name' export/${PROJECT_ID}/assets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on, asset_name) values ('${UUID}','${ID}','WORKFLOW','${PROJECT_UUID}','${MISSING_TIMESTAMP}','${NAME}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Workflow Asset ${UUID} to database" >&2
  done
}

function import_es_data() {
  INDEX=$1
  ID=$2
  FILE=$3

  RES=$(curl -s -XPUT -H "Content-Type: application/json" ${ES_URL}/${INDEX}_doc/${ID} -d @${FILE})
  if [ "$(echo "$RES" | jq -r '._shards.successful')" != "null" ]; then
    if [ "$(echo "$RES" | jq -r '._shards.successful')" = "0" ]; then
      echo "  ... FAILED to import into ES index ${INDEX} file ${FILE}"
    fi
  else
    echo "es response: ${RES}" >&2
  fi
}

function insert_datasets() {
  USER_ID=$1
  echo "Datasets" >&2

  local IDS=$(jq -r '.datasets[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  Dataset ${ID}" >&2

    $(jq --arg user_id "${USER_ID}" '. += {user_id: $user_id} | with_entries(if .key == "timestamp" then .key = "created_on" else . end) | del(.username, .timestamp) ' export/${PROJECT_ID}/datasets/${ID}/datasets.json > dataset-${ID}.json)
  #echo "find group: ${GROUP_FOUND}" >2&
    echo "  ...prepared import json" >&2

    import_es_data "tds_dataset_tera_1.0" "${ID}" "dataset-${ID}.json"

    for FILE in export/${PROJECT_ID}/datasets/${ID}/files/*; do
      FILENAME="${FILE##*/}"
      copy_s3_directory "${FILE}" "${S3_DIR}/datasets/${ID}/${FILENAME}"
    done

    if [ ! -z "$(ls -A "export/${PROJECT_ID}/datasets/${ID}/sim/*" 2>/dev/null)" ]; then
      for FILE in export/${PROJECT_ID}/datasets/${ID}/sim/*; do
        FILENAME="${FILE##*/}"
        import_es_data "tds_simulation_tera_1.0" "${FILENAME%.*}" "${FILE}"
      done
    fi

    rm dataset-${ID}.json
    echo "  ...imported" >&2
  done
}

function insert_models() {
  USER_ID=$1
  echo "Models" >&2

  local IDS=$(jq -r '.models[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  Model ${ID}" >&2
    import_es_data "tds_model_tera_1.0" "${ID}" "export/${PROJECT_ID}/models/${ID}/models.json"
    MODEL_CONFIGURATION_ID=$(jq -r '.[0].id' export/${PROJECT_ID}/models/${ID}/model_configuration.json)
    import_es_data "tds_modelconfiguration_tera_1.0" "${MODEL_CONFIGURATION_ID}" "export/${PROJECT_ID}/models/${ID}/model_configuration.json"
    echo "  ...imported" >&2
  done
}

function insert_workflows() {
  USER_ID=$1
  echo "Workflows" >&2

  local IDS=$(jq -r '.workflows[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  WORKFLOW ${ID}" >&2
    import_es_data "tds_workflow_tera_1.0" "${ID}" "export/${PROJECT_ID}/workflows/${ID}/workflows.json"
    echo "  ...imported" >&2
  done
}

function insert_artifacts() {
  USER_ID=$1
  echo "Artifacts" >&2

  local IDS=$(jq -r '.artifacts[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  Artifact ${ID}" >&2

    $(jq --arg id "${ID}" --arg user_id "${USER_ID}" '.artifacts[] | select(.id == $id) | . += {user_id: $user_id} | with_entries(if .key == "timestamp" then .key = "created_on" else . end) | del(.username, .timestamp) ' export/${PROJECT_ID}/assets.json > artifact-${ID}.json)
    echo "  ...prepared import json" >&2

    import_es_data "tds_artifact_tera_1.0" "${ID}" "artifact-${ID}.json"
 
    for FILE in export/${PROJECT_ID}/artifacts/${ID}/files/*; do
      FILENAME="${FILE##*/}"
      copy_s3_directory "${FILE}" "${S3_DIR}/artifacts/${ID}/${FILENAME}"
    done

    rm artifact-${ID}.json
    echo "  ...imported" >&2
  done
}

if [[ -z $1 ]]; then
  echo "Please provide a project id"
  exit 1
fi
PROJECT_ID=$1

ENVIRONMENT=""
if [[ ! -z $2 ]]; then
  ENVIRONMENT="$2_"
fi
source ${ENVIRONMENT}import_secrets.sh

echo "Importing project ${PROJECT_ID}" >&2

if [ ! -z "${SSH_ADDRESS}" ]; then
  echo "Establish SSH session for forwarded ports" >&2
  ssh -M -fN -S /tmp/.ssh-uncharted-askem-import ${SSH_ADDRESS}
fi

# Configure spicedb
SPICEDB_SETTINGS="--endpoint ${SPICEDB_TARGET} --token ${SPICEDB_SHARED_KEY}"
if [ "${SPICEDB_INSECURE}" = "true" ]; then
  SPICEDB_SETTINGS="${SPICEDB_SETTINGS} --insecure"
fi

# Aquire Access Token for Keycloak
ACCESS_TOKEN=$(curl -s -d "client_id=${KEYCLOAK_ADMIN_CLIENT_ID}" -d "username=${KEYCLOAK_ADMIN_USERNAME}" -d "password=${KEYCLOAK_ADMIN_PASSWORD}" -d "grant_type=password" "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" | jq -r ".access_token")
PUBLIC_GROUP_ID=$(getGroupId ${PUBLIC_GROUP_NAME})

USERNAME=$(jq -r '.username' export/${PROJECT_ID}/project.json)
USER_ID=$(get_user_id "${USERNAME}")

insert_project ${USER_ID}
insert_datasets ${USER_ID}
insert_models ${USER_ID}
insert_workflows ${USER_ID}
insert_artifacts ${USER_ID}

if [ ! -z "${SSH_ADDRESS}" ]; then
  echo "Disconnect SSH session" >&2
  ssh -S /tmp/.ssh-uncharted-askem-import -O exit ${SSH_ADDRESS}
fi
