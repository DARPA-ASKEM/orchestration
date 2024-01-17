source import_secrets.sh

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

function get_user_id() {
  local USER_NAME=$1
  local USER_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json" "${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}/roles/user/users")
  local USER_ID=$(echo ${USER_JSON} | jq -r --arg user_name "${USER_NAME}" '.[] | {id: .id, username: (.firstName + " " + .lastName)} | select(.username | contains($user_name) ) | .id')
  echo "${USER_ID}"
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
  echo "Project" >&2

  local USERNAME=$(jq -r '.username' export/${PROJECT_ID}/project.json)
  local USER_ID=$(get_user_id "${USERNAME}")
  local PROJECT_UUID=$(uuidgen)
  local SQL_DATA=$(jq -r --arg user_id "${USER_ID}" --arg uuid "${PROJECT_UUID}" '{id: $uuid, name: .name, description: .description, timestamp: .timestamp, user_id: $user_id} | map([.] | .[]) | @csv' export/78/project.json)
  local VALUES=$(prepare_csv_line_for_sql "${SQL_DATA}")
  local SQL="insert into project (id, name, description, created_on, user_id) values (${VALUES})"

  local RES=$(execute_sql "${SQL}")
  echo "  ...added Project ${PROJECT_UUID} to database" >&2

  local PUBLIC_PROJECT=$(jq -r '.publicProject' export/${PROJECT_ID}/project.json)
  local USER_PERMISSION=$(jq -r '.userPermission' export/${PROJECT_ID}/project.json)

  if [ "${PUBLIC_PROJECT}" == "true" ]; then
    assignGroupToProject ${PROJECT_UUID} ${PUBLIC_GROUP_ID} ${USER_PERMISSION}
  fi

  # DATASETS
  local IDS=$(jq -r '.datasets[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen)
    local TIMESTAMP=$(jq -r '.timestamp' export/${PROJECT_ID}/datasets/${ID}/datasets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on) values ('${UUID}','${ID}','DATASET','${PROJECT_UUID}','${TIMESTAMP}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Dataset Asset ${UUID} to database" >&2
  done


  # ARTIFACTS
  local IDS=$(jq -r '.artifacts[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen)
    local TIMESTAMP=$(jq -r --arg id "${ID}" '.artifacts[] | select(.id == $id) | .timestamp' export/${PROJECT_ID}/assets.json)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id, created_on) values ('${UUID}','${ID}','ARTIFACT','${PROJECT_UUID}','${TIMESTAMP}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Artifact Asset ${UUID} to database" >&2
  done

  # MODELS
  local IDS=$(jq -r '.models[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id) values ('${UUID}','${ID}','MODEL','${PROJECT_UUID}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Model Asset ${UUID} to database" >&2
  done

  # WORKFLOWS
  local IDS=$(jq -r '.workflows[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    local UUID=$(uuidgen)
    local SQL="insert into project_asset (id, asset_id, asset_type, project_id) values ('${UUID}','${ID}','WORKFLOW','${PROJECT_UUID}')"
    local RES=$(execute_sql "${SQL}")
    echo "  ...added Project Workflow Asset ${UUID} to database" >&2
  done
}

function import_es_data() {
  INDEX=$1
  ID=$2
  FILE=$3

  RES=$(curl -s -XPUT -H "Content-Type: application/json" http://localhost:9200/${INDEX}_doc/${ID} -d @${FILE})
  if [ "$(echo "$RES" | jq -r '._shards.successful')" != "null" ]; then
    if [ "$(echo "$RES" | jq -r '._shards.successful')" -eq 0 ]; then
      echo "  ... FAILED to import into ES index ${INDEX} file ${FILE}"
    fi
  fi
}

function insert_datasets() {
  echo "Datasets" >&2

  local IDS=$(jq -r '.datasets[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  Dataset ${ID}" >&2

    local USERNAME=$(jq -r '.username' export/${PROJECT_ID}/datasets/${ID}/datasets.json)
    local USER_ID=$(get_user_id "${USERNAME}")
    $(jq --arg user_id "${USER_ID}" '. += {user_id: $user_id} | with_entries(if .key == "timestamp" then .key = "created_on" else . end) | del(.username, .timestamp) ' export/${PROJECT_ID}/datasets/${ID}/datasets.json > dataset-${ID}.json)
    echo "  ...prepared import json" >&2

    import_es_data "tds_dataset_tera_1.0" "${ID}" "dataset-${ID}.json"

    for FILE in export/${PROJECT_ID}/datasets/${ID}/files/*; do
      FILENAME="${FILE##*/}"
      copy_s3_directory "export/${PROJECT_ID}/datasets/${ID}/files/${FILE}" "${S3_DIR}/datasets/${ID}/${FILE}"
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
  echo "Workflows" >&2

  local IDS=$(jq -r '.workflows[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  WORKFLOW ${ID}" >&2
    import_es_data "tds_workflow_tera_1.0" "${ID}" "export/${PROJECT_ID}/workflows/${ID}/workflows.json"
    echo "  ...imported" >&2
  done
}

function insert_artifacts() {
  echo "Artifacts" >&2

  local IDS=$(jq -r '.artifacts[].id' export/${PROJECT_ID}/assets.json)
  for ID in ${IDS}; do
    echo "  Artifact ${ID}" >&2

    local USERNAME=$(jq -r --arg id "${ID}" '.artifacts[] | select(.id == $id) | .username' export/${PROJECT_ID}/assets.json)
    local USER_ID=$(get_user_id "${USERNAME}")
    $(jq --arg id "${ID}" --arg user_id "${USER_ID}" '.artifacts[] | select(.id == $id) | . += {user_id: $user_id} | with_entries(if .key == "timestamp" then .key = "created_on" else . end) | del(.username, .timestamp) ' export/${PROJECT_ID}/assets.json > artifact-${ID}.json)
    echo "  ...prepared import json" >&2

    import_es_data "tds_artifact_tera_1.0" "${ID}" "artifact-${ID}.json"
 
    for FILE in export/${PROJECT_ID}/artifacts/${ID}/files/*; do
      FILENAME="${FILE##*/}"
      copy_s3_directory "export/${PROJECT_ID}/artifacts/${ID}/files/${FILE}" "${S3_DIR}/artifacts/${ID}/${FILE}"
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

insert_project
insert_datasets
insert_models
insert_workflows
insert_artifacts

if [ ! -z "${SSH_ADDRESS}" ]; then
  echo "Disconnect SSH session" >&2
  ssh -S /tmp/.ssh-uncharted-askem-import -O exit ${SSH_ADDRESS}
fi
