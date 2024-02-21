STAGING_SECRET_FILES=("overlays/prod/base/keycloak/certificates/cert.pem" "overlays/prod/base/keycloak/certificates/key.pem"
	"overlays/prod/overlays/askem-staging/secrets/*.yaml"
	"overlays/prod/overlays/askem-staging/keycloak/realm/*.json"
	"overlays/prod/overlays/askem-staging/check-latest/check-latest-rsa" "overlays/prod/overlays/askem-staging/check-latest/secrets.yaml")

PRODUCTION_SECRET_FILES=("overlays/prod/base/keycloak/certificates/cert.pem" "overlays/prod/base/keycloak/certificates/key.pem"
	"overlays/prod/overlays/askem-production/secrets/*.yaml"
	"overlays/prod/overlays/askem-production/keycloak/realm/*.json"
	"overlays/prod/overlays/askem-production/check-latest/check-latest-rsa" "overlays/prod/overlays/askem-production/check-latest/secrets.yaml")
