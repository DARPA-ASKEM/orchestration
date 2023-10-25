# Creating Production Certificates

## Prerequisites

[minica](https://github.com/jsha/minica)

## Steps

### Generate Certificates

```shell	
minica -domains certificates,keycloak

cp certificates/*.pem overlays/prod/base/keycloak/certificates	

keytool -delete -alias self-signed -storepass changeit -keystore overlays/prod/base/keycloak/keystore/cacerts -storetype JKS	

keytool -import -alias self-signed -noprompt -storepass changeit -file overlays/prod/base/keycloak/certificates/cert.pem -keystore overlays/prod/base/keycloak/keystore/cacerts -storetype JKS	

./deploy.sh encrypt staging	

git add overlays/prod/base/keycloak/certificates	

git add overlays/prod/base/keycloak/keystore	

git commit -m "updating certificates"	
```
