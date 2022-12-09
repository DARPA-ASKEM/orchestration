# Requirements

[Mozilla's Secret OPerationS : sops](https://github.com/mozilla/sops)

`brew install sops`

# How to use

dt [up | down | replace --file <yaml> | status | decrypt [--file <file>] | encrypt [--file <file>]]

## Editing Secrets

`./dt decrypt` will decrypt all secret files

`./dt decrypt --file <file_name>` will decrypt a specific secret file for editing

`./dt encrypt` will encrypt the secret files for submitting into GIT

`./dt encrypt --file <file_name>` will encrypt a secret file for submitting into GIT

## Deploying Services

It is not necessary to decrypt the secret files before running `up` or `down` as these functions will first decrypt the secret files, and afterward will `git restore` those files that were decrypted, files that were not decrypted when running up will not be restored.  This allows for editing a specific secret and either encrypting and `git commit`ing the file or leaving it decrypted to see that the values are correct.  This functionality allows for easier understanding what was changed as the encryption function changes files that were not edited due to timestamp encryption methodology.

`./dt up` will "apply" the kubernetes configurations to the remote servers

`./dt down` will "delete" the kubernetes confgurations from the remote servers

`./dt status` will return the current status on the remote servers
