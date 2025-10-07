# Cloudnative-pg + Vault Secrets Operator - Dynamic Secrets

Cloudnative-pg provides a Postgres cluster, and app databases are provisioned using the `app-databases` config. Apps get short‑lived DB users from Vault via Vault Secrets Operator (`VaultDynamicSecret`). Terraform codifies Vault DB engine config.

## Usage

Uncomment the `./cnpg-operator` resource in `./kustomization.yaml` When the operator has been deployed, uncomment the `./cnpg-cluster` resource and let it stabilize. Troubleshoot if there are errors.

When the cluster is healthy, uncomment app database configs, like `./app-databases/qcon-api`.

## Notes

- The admin DB user used by Vault to CREATE ROLE (e.g., postgres) is `init-secret`.
