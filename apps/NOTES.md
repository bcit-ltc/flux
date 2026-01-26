# App deployment

Adds workloads to be deployed by Flux.

## Requirements

- app container in GitHub Packages (ghcr.io/{orgName})
- OCI container (helm chart) in GitHub Packages (oci://ghcr.io/{orgName/oci/appName{tag})
- Flux CLI for manual reconciliation
- Kubernetes CLI & cluster connection
- Terraform

## Adding an app

1. Add the app name (microservice name - `qcon-api` not `qcon`) to Vault:

    1. Clone Vault repo:

        ```bash
        git clone https://github.com/bcit-ltc/vault
        ```

    1. Prepare Copy `identities` and `tfvars` from Vault

        ```bash
        cd vault
        export VAULT_ADDR=https://vault.ltc.bcit.ca:8200
        vault login -method=oidc username={yourUsername}
        vault kv get -mount="ltc-infrastructure" -field="identities.yaml" "vault/identities" > identities.yaml
        vault kv get -mount="ltc-infrastructure" -field="terraform.tfvars" "vault/tfvars" > terraform.tfvars
        ```

    1. Add app to the list of `apps` at the top of the `terraform.tfvars` file

        - **if the app is a microservice, list it under the `apps_grouped` key**

    1. Apply the config to Vault via Terraform

        ```bash
        terraform plan
        terraform apply
        ```

1. Add the app to Flux

    1. Copy the `apps/0-app-template` folder

    1. Paste into `apps` and rename based on ${appName}

    1. Replace all instances of `app` in the folder with ${appName}

    1. Add the app name to `apps/kustomization.yaml`

    1. Commit and push the changes, and then reconcile the `flux-system` kustomization

        ```bash
        git add . && git commit -m "adds ${appName}" && git push origin main

        flux reconcile kustomization flux-system --with-source
        ```

1. Confirm deployment on the clusters :)
