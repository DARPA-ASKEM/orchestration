[![Lint & Format](https://github.com/DARPA-ASKEM/orchestration/actions/workflows/lint.yaml/badge.svg?branch=main)](https://github.com/DARPA-ASKEM/orchestration/actions/workflows/lint_format.yaml)
[![Build Docker Images](https://github.com/DARPA-ASKEM/orchestration/actions/workflows/publish.yaml/badge.svg?branch=main)](https://github.com/DARPA-ASKEM/orchestration/actions/workflows/publish.yaml)
# Orchestration
Scripts and deployment information needed to setup and run Terarium

## Common Tasks

### Deploy and Environment
In the `/kubernetes` folder, run the script `deploy.sh`

To test the Staging environment's kustomize script eg:
```shell
/deploy.sh test staging
```

To get help about `deploy.sh`
```shell
/deploy.sh help
```

### Decrypt a Secret
Secrets are encrypted using SPOS and AGE (see Requirements below for details on those).  To view a secret, in the `/kubernetes` directory, use:
```shell
./get_secret_ui.sh
```

NB: the first time running `get_secret_ui.sh` it will need to install a number of packages.  This can take a few moments.

Caveat: `get_secret_ui.sh` is currently unable to encode a secret - this is a TODO

Alternatively, to view secrets, or modify secrets one can:
```shell
/deploy.sh decrypt [staging|production]
```
but one will have to base64 decode/encode any given value by hand


## Authorization Gateway

See [Uncharted-Auth](https://github.com/unchartedsoftware/uncharted-auth) for details about building the Gateway containers.

## Requirements for Building locally

### Install Sops
Required to encrypt/decrypt secrets.

[Mozilla's Secret OPerationS : sops](https://github.com/mozilla/sops)

```shell
brew install sops
```

### Install Nix-Shell
Required to encrypt/decrypt via `get_secrets_ui.sh` (a helpful script to aid in finding the value of a secret).

MacOS
```shell
curl -L https://nixos.org/nix/install | sh
```

Linux
```shell
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

For more details please visit: https://nix.dev/install-nix


### Obtain AGE key

Fetch `https://drive.google.com/file/d/1DiCAxgjAgXOt72nVSktcmXDmWrcfJwSg/view?usp=drive_link` and store in your home directory.

```shell
cp kubernetes/env.template kubernetes/.env
```

edit `kubernetes/.env` changing <user> to your user directory (or if not on a Mac edit as appropriate)

### Enabling Kubernetes

You will need a Kubernetes node running locally, the simplist for development is probably Docker Desktop's Kubernetes capability as it give the easiest access to your local machine from within the Kubernetes (or Docker) containers, but there are other options if one wishes.

To enable Docker Desktop Kubernetes bring up the Docker Desktop `Dashboard`, goto `Settings` (the gear icon), select `Kubernetes`, and `Enable Kubernetes`.  This will require a bried installation and restart of Docker, but once completed you can test that all is working by issuing:

`kubectl get pods` and should see something like

```
NAME                                READY   STATUS    RESTARTS   AGE
```

### Pulling required containers

The application consists of a number of docker images some public and some that are restricted to members of the the organization. If you are a member you can login to the registry by following the instructions described [here](CONTRIBUTING.md#login-to-registry).

Some secrets may be required to be given to the kubernetes cluster so that it can pull on your behalf. To do so follow the following instructions [here](CONTRIBUTING.md#kubernetes)

TODO: edit deployment files to use docker-registry

### Checking errors launching containers

TODO: talk about `kubectl describe <pod-name>`

## Launching TERArium

To launch TERArium run `./deploy-terarium.sh up`.  This will stand up the TERArium services which are comprised of an Apache HTTPD server, a Keycloak server, and a Postgres server for Keycloak.

Running `./deploy-terarium.sh status` will show the status of the various TERArium services and if there are problems with a *pod* (it says something like CrashLoopBackoff or similar), then running `kubectl logs -f <full-pod-name>` will show the log of the problematic container.  The *full-pod-name* is shown in the list of pods when retrieving the status.

To bring the TERArium stack down, simply run `./deploy-terarium.sh down` and all the services will be torn down.

To stop only one service, for example to work on the hmi-client, run `./deploy-terarium.sh stop hmi-client`.
Or for the _Data Service_ `./deploy-terarium.sh stop data-service`.

To only launch the services you need:
```shell
$ ./deploy-terarium.sh dev                  # Launches TERArium without the hmi-server and hmi-client
$ ./deploy-terarium.sh stop hmi-client      # Stop the hmi-client
```

### Private Registries
If the deployments access private registries, Kubernetes will not be able to automatically pull those images for you. To do so, a secret with the required credentials is required and used for the deployment. To do this refer to the [registry documentation](./CONTRIBUTING.md#kubernetes).

## Theming Keycloak
It is possible to theme different Keycloak views. To do so the new themes should be placed under `/opt/keycloak/themes/` directory. This local deployment shows and example of how to retheme the login page by loading a data image that contains the theme that is copied over to the Keycloak POD on initialization. If additional themes are made for other views the main theme image should be update as described [here](keycloak-theme/README.md).
