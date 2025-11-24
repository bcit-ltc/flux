# Cloudnative-pg + Vault Secrets Operator dynamic secrets

Cloudnative-pg provides a Postgres cluster, and app databases are provisioned using the configuration in `app-databases`. Apps get short‑lived DB users from Vault via the Vault Secrets Operator (`VaultDynamicSecret`) resource. Terraform codifies Vault DB engine config (see [Vault repository](https://www.github.io/bcit-ltc/vault)).

## Usage

Resources in this path are kustomized by the [cluster kustomization.yaml](../../clusters/), not by the infrastructure `kustomization.yaml`.

App databases are provisioned by the resources in [./app-databases](./app-databases/).

Use the kubectl plugin to check the cluster health:

    krew install cnpg
    kubectl cnpg status pg-core -n postgres

## Adding new app databases

kubectl apply -f fluxRoot/infrastructure/cloudnative-pg/bootstrap-app-privs-job.yaml
