# Administrate Staging Keycloak

## Prerequesits

### Update /etc/hosts

Edit `/etc/hosts` and add the following line `127.0.0.1 kubernetes.terarium.ai`.
Best under the comment `# Added by Docker Desktop` if already there.

### Kubectl Configuration

Run `./admcloak.sh config <user directory>` to add to your ~/.kube/config file the context and certificate files to execute kubectl commands remotely.

### Kubectl Context Switching

Run `./admcloak.sh list` to see the list of contexts configured locally, selecting the `NAME` one wishes to swtich to; eg:

| CURRENT  | NAME           | CLUSTER        | AUTHINFO              | NAMESPACE |
|----------|----------------|----------------|-----------------------|-----------|
| *        | askem-prod     | askem-prod     | kubernetes-prod-admin | terarium  |
|          | docker-desktop | docker-desktop | docker-desktop        |           |

To change the current context run `./admcloak.sh set docker-desktop` to switch from `askem-prod` to `docker-desktop`

### SSH Configuration

Add the following forward (`LocalForward 16443 172.16.60.159:6443`) to your SSH rule for `Host uncharted-askem-prod-askem-prod-kube-manager-1`

## Establishing Port Forwarding for Keycloak

1. Establish local forwarding of 16433 by sshing to the cluster: `ssh uncharted-askem-prod-askem-prod-kube-manager-1`
2. Switch Kubectl context to `askem-prod` by running: `./admcloak.sh set askem-prod`
3. Port forward 8443 by running: `kubectl port-forward deployment/gateway-keycloak 8443:8443`
4. Visit `https://localhost:8443` in your browser

## Reverting Kubectl

Stop the `port-forward` and close the `ssh` session, then run `./admcloak.sh set docker-desktop`
