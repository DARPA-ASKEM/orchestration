# Microservice Case Study
> A case study on the steps required to create a microservice for Terarium within the DARPA-ASKEM GitHub organization 
> and deploy to AWS

## Introduction
This document is intended to provide some documentation on how to deploy a microservice within the Terarium ecosystem. We 
will be using [Skema](https://github.com/DARPA-ASKEM/skema) as the example as all code is committed and the edge cases
are handled. These are the steps for a "pure" microservice. "Pure" meaning that the service does not depend on any other
services and provides "data-in-data-out" functionality.


## Process
The general steps of the process are outlined below:
1. [Fork the Repository](#fork-the-repository)
2. [Setup CI and Package Access](#setup-ci-and-package-access)
3. [Add Manifests to Orchestration](#add-manifests-to-orchestration)
4. [Add Configuration to Terarium](#add-configuration-to-terarium)

### Fork the Repository
**Goals**: Ensure that the repository is in the DARPA-ASKEM GitHub repository. If this was a service maintained directly by Terarium maintainers
this step may be omitted.

**Where**: Within the GitHub UI

For Skema, the original repository does not live within the DARPA-ASKEM GitHub organization. Thus, we wish to make a fork
of this repository so that Terarium maintainers can control versioning and releases. The original repository [can be found here](https://github.com/ml4ai/skema).
We can fork this repository by clicking `Fork` and ensuring that we fork the repository into the correct organization:
![mcs_1.png](images%2Fmcs_1.png)

### Setup CI and Package Access
**Goals**: Ensure that the microservice image(s) have Continuous Integration for builds and that generated Docker images follow the 
naming convention of the organization and have the correct access permissions.

**Where**: Within the [Skema](https://github.com/DARPA-ASKEM/skema) repository and the GitHub UI

To ensure CI is built, we simply need to make a `.github/publish.yaml` file. When creating a new microservice, we can use this file
as an example and create changes as needed. A walkthrough of the important bits of this file follows:

```yaml
name: Build and Publish
on:
  push:
    branches: ['main']
    tags: ['*']
```
This code block names the workflow as it will appear in github actions. The `on` clause defines when this job will be ran.
Namely, on all merges to `main` and on any Git tag push. 

```yaml
jobs:
  tag-generator:
    name: Determine image tag
...
```
The first job of this workflow is to determine the tag name for the corresponding built Docker images. The convention for DARPA-ASKEM 
is that pushes to the `main` branch will update the `latest` tag, and pushing a tag of the format `vX.Y.Z` will create a tag named
`x.y.z`.  For example, `v0.3.5` will create the image `ghcr.io/darpa-askem/skema-py:0.3.5`.

```yaml
  bake:
    needs:
      - tag-generator
    with:
      file: 'docker-bake.hcl'
...
    secrets:
      username: ${{ github.repository_owner }}
      password: ${{ secrets.GITHUB_TOKEN }}
```
This block defines the `bake` job that creates platform specific Docker images from the `docker-bake.hcl` file in the root
directory of the Skema repository. Note that this job depends on the `tag-generator` job, so will not run until it is complete.
Additionally, the `secrets` section is organization wide, so no manual steps are necessary once the repository is within the DARPA-ASKEM
organization.

The meat of the `docker-bake.hcl` is below:
```hcl
target "_platforms" {
  # Currently skema-rs fails to compile on arm64 so we build only for amd at the moment
  # platforms = ["linux/amd64", "linux/arm64"]
  platforms = ["linux/amd64"]
}

target "skema-rs-base" {
  context = "."
  tags = tag("skema-rs", "", "")
  dockerfile = "Dockerfile.skema-rs"
}

target "skema-rs" {
  inherits = ["_platforms", "skema-rs-base"]
}
```
The `platforms` section tells GitHub to build both the amd and arm versions of the image. (Note that it is currently
commented out as this particular service fails to build on ARM achitecture).

When creating a new service, this can simply be copy/pasted with the correct edits.

### Add Manifests to Orchestration
**Goals**: To create Kubernetes manifests to ensure that service is deployed to AWS environments and, in staging, updates
automatically on successful builds to the `main` branch.

**Where**: Within the [Orchestration](https://github.com/DARPA-ASKEM/orchestration) (aka, this) repository.

The Orchestration repository uses [Kustomize](https://kustomize.io/) to layer Kubernetes manifests files together to reduce
duplication and allow for parameter replacement when deploying.

We can see the base definitions for the Skema services in the `kubernetes/base/services/skema` directory. The `skema-rs-deployment.yaml` file defines the images
used for this deployment:
```yaml
...
spec:
  containers:
    - image: skema-rs-image
      name: skema-rs
      command: ['cargo']
      args: ['run', '--release', '--bin', 'skema_service', '--', '--host', '0.0.0.0', '--db-host', 'skema-memgraph']
      ports:
        - containerPort: 8080
...
```
The `skema-rs-image` is effectively a Kustomize parameter that is overriden in:
- `kubernetes/overlays/prod/overlays/askem-production/kustomization.yaml`
- `kubernetes/overlays/prod/overlays/askem-staging/kustomization.yaml`

In staging for instance, we specify the `latest` tag:
```yaml
  - name: skema-py-image
    newName: ghcr.io/darpa-askem/skema-py
    newTag: latest
  - name: skema-rs-image
    newName: ghcr.io/darpa-askem/skema-rs
    newTag: latest
```

The manifest used for the service deployment (`kubernetes/base/services/skema/skema-rs-service.yaml`):
```yaml
spec:
  type: NodePort
  ports:
    - name: 4040-tcp
      port: 4040
      protocol: TCP
      targetPort: 8080
  selector:
    software.uncharted.terarium/name: skema-rs
```
We map port `4040` to the container port `8080` defined in the deployment file.  The TCP port must be unique in the K8s
cluster we're deploying into.  We specify that this service is a `NodePort` to make it accessible to the outside world.

We must also add these new service/deployment files to the `kustomization.yaml` file:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - skema-rs-deployment.yaml
  - skema-rs-service.yaml
```

The final step is creating an `ingress` file that exposes this service to the outside world.
The file `kubernetes/overlays/prod/overlays/askem-staging/services/skema-rs-ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: terarium
  name: skema-rs
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/security-groups: askem-staging-web-private
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '443'
    alb.ingress.kubernetes.io/healthcheck-path: '/ping'
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: skema-rs
                port:
                  number: 4040
  tls:
    - hosts:
        - "skema-rs.staging.terarium.ai"
```
Important bits from above:
1. `alb.ingress.kubernetes.io/security-groups: askem-staging-web-private` ensures that the service is only available to the _private_ web. Aka, Uncharted/Jataware IP's only.
2. `alb.ingress.kubernetes.io/healthcheck-path: '/ping'`: This is the healthcheck that AWS will use to ensure the service is alive.  All microservices **must** have a healthcheck or
traffic will not be routed to them
3. `"skema-rs`.staging.terarium.ai"`: This must be within the `*.staging.terarium.ai` domain block or else it will not work.
4. `number: 4040`: This needs to route to the port exposed in the `service.yaml` definition.

We now configure Terarium itself to expect these services.  A deeper explanation is provided in the [FAW](#faq).
Within `kubernetes/overlays/prod/base/hmi/hmi-server-deployment.yaml` we have an environment override:
```yaml
spec:
  template:
    spec:
      containers:
        - name: hmi-server
          env:
            - name: SKEMA_RUST_MP_REST_URL
              value: "http://skema-rs:4040"
``` 

For staging, we want this service to auto-update.  We can add the following line to `kubernetes/overlays/prod/overlays/askem-staging/check-latest/images.txt`:
```text
software.uncharted.terarium/name=skema-rs ghcr.io/darpa-askem/skema-rs:latest
```
This tells our updating cronjob that the pods with the selector in the first column should use the latest version of image name in the second column.

Finally, we must deploy all of this.  In order to get access to the staging environment, please message @chris on Slack.  

We can deploy the service itself by running
```bash
./production_deploy.sh up staging
```
to create the deployment.

We then can create the ingress by running (from `kubernetes/overlays/prod/overlays/askem-staging/services`):
```bash
cat skema-rs-ingress.yaml | ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl apply --filename -
```

### Add Configuration to Terarium
**Goals**: To ensure that Terarium is connecting to the microservice via a Quarkus `@Proxy`

**Where**: Within the [Terarium](https://github.com/DARPA-ASKEM/orchestration) repository

Finally, we can configure a Proxy within Terarium itself to use this service.

From `software/uncharted/hmispringserver/proxies/skema/SkemaRustProxy.java`:
```java
@RegisterRestClient(configKey = "skema-rust")
public interface SkemaRustProxy {
    // File contents here
}
```
and in `resources/application.properties`:
```properties
skema-rust/mp-rest/url=https://skema-rs.staging.terarium.ai
```
Note the matching `skema-rust` string from the `@RegisterRestClient` annotation and the name of the property itself. The domain
was configured in the previous step of deploying the ingress.

## FAQ
Q: "Does that mean that the production version of Terarium is using staging's instances of Skema?"

A: No. Although Terarium itself is configured to use the staging DNS entry by default, within the `hmi-server-deployment.yaml` file that gets 
respected in AWS environments, we use the internal DNS of Kubernetes itself.  Thus, each AWS deployment uses its own version of SKEMA and the DNS
is really only used when running locally.



Q: "What happens if something goes wrong? Where do I look?"

A: 
1. Ensure the pod is running:
  ```bash
   ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl get pods | grep skema-rs
  ```
	skema-rs-68b646c5d7-c58gk               1/1     Running            0                 10d 
2. `exec` into the pod and try running the health check:
  ```bash
  ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl exec skema-rs-68b646c5d7-c58gk "curl localhost:8080/ping" 
  ```
	The SKEMA Rust web services are running.

3. Ensure the ingress is functional:
  ```bash
  ssh uncharted-askem-prod-askem-staging-kube-manager-1 sudo kubectl describe ingress
  ```
	Name:             skema-rs
	Labels:           <none>
	Address:          ********.amazonaws.com
	Namespace:        terarium
	Ingress Class:    alb
	Default backend:  <default>
	TLS:
	   SNI routes skema-rs.staging.terarium.ai
	Rules:
		Host        Path  Backends
            ----        ----  --------
		*
                 /   skema-rs:4040 (10.***.*.***:8080)
	Events:       <none>

4. Ensure the load balancers are healthy within AWS.  You can find them in the `EC2 -> Load Balancers` page in the AWS console.  The 
name of the load balancer can be found using the `Address` field from the ingress description

Q: "Why don't we run this on our local machine?"

A: Because we don't have to. This service doesn't interact with anything else. In general, we should aim to produce standalone microservices
whenever possible so that they can be exposed in the aforementioned way. This saves developer resources.