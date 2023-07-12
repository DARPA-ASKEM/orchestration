# Creating Production Certificates

## Prerequisites

[minica](https://github.com/jsha/minica)

## Steps

### Generate Certificates

```shell	
minica -domains certificates,gateway-keycloak,gateway-envoy	

cp certificates/*.pem overlays/prod/base/gateway/certificates	

keytool -delete -alias self-signed -storepass changeit -keystore overlays/prod/base/gateway/keystore/cacerts -storetype JKS	

keytool -import -alias self-signed -noprompt -storepass changeit -file overlays/prod/base/gateway/certificates/cert.pem -keystore overlays/prod/base/gateway/keystore/cacerts -storetype JKS	

./production_deploy.sh encrypt staging	

git add overlays/prod/base/gateway/certificates	

git add overlays/prod/base/gateway/keystore	

git commit -m "updating certificates"	
```
