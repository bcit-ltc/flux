# CNPG + VSO Dynamic Secrets

Apps get short‑lived DB users from Vault via Vault Secrets Operator (`VaultDynamicSecret`). Terraform codifies Vault DB engine config.

## Notes

- The admin DB user used by Vault to CREATE ROLE (e.g., postgres) is `init-secret`.
