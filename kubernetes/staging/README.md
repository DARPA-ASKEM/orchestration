# Requirements

[Mozilla's Secret OPerationS : sops](https://github.com/mozilla/sops)

`brew install sops`

# How to use

## Editing Secrets

`./dt decrypt` will decrypt secret files for editing

`./dt encrypt` will encrypt the secret files for submitting into GIT

## Deploying Services

`./dt up` will "apply" the kubernetes configurations to the remote servers

`./dt down` will "delete" the kubernetes confgurations from the remote servers

`./dt status` will return the current status on the remote servers
