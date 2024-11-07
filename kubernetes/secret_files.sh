CERTS=(
  "overlays/prod/base/keycloak/certificates/cert.pem"
  "overlays/prod/base/keycloak/certificates/key.pem"
)

STAGING_YAML=(
  "overlays/prod/overlays/askem-staging/secrets/secrets-adobe-api-key.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-beaker-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-data-service-s3.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-dkg.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-es-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-keycloak-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-logging-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-chatgpt.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-mq-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-neo4j-auth.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-rds-creds.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-spicedb-shared.yaml"
  "overlays/prod/overlays/askem-staging/secrets/secrets-xdd-api-key.yaml"
	"overlays/prod/overlays/askem-staging/check-latest/secrets.yaml"
)
STAGING_ADDITIONAL=(
  "overlays/prod/overlays/askem-staging/check-latest/check-latest-rsa"
)

PRODUCTION_YAML=(
  "overlays/prod/overlays/askem-production/secrets/secrets-adobe-api-key.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-beaker-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-data-service-s3.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-dkg.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-es-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-keycloak-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-logging-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-chatgpt.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-mq-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-neo4j-auth.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-rds-creds.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-spicedb-shared.yaml"
  "overlays/prod/overlays/askem-production/secrets/secrets-xdd-api-key.yaml"
	"overlays/prod/overlays/askem-production/check-latest/secrets.yaml"
)
PRODUCTION_ADDITIONAL=(
  "overlays/prod/overlays/askem-production/check-latest/check-latest-rsa"
)

DEV_YAML=(
  "overlays/prod/overlays/askem-dev/secrets/secrets-chatgpt.yaml"
  "overlays/prod/overlays/askem-dev/secrets/secrets-mq-creds.yaml"
  "overlays/prod/overlays/askem-dev/check-latest/secrets.yaml"
)
DEV_ADDITIONAL=(
  "overlays/prod/overlays/askem-dev/check-latest/check-latest-rsa"
)

STAGING_SECRET_FILES=(${CERTS[@]} ${STAGING_YAML[@]} ${STAGING_ADDITIONAL[@]})
PRODUCTION_SECRET_FILES=(${CERTS[@]} ${PRODUCTION_YAML[@]} ${PRODUCTION_ADDITIONAL[@]})
DEV_SECRET_FILES=(${CERTS[@]} ${DEV_YAML[@]} ${DEV_ADDITIONAL[@]})
