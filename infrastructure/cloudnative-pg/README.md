# CNPG + VSO Dynamic Secrets

Apps get short‑lived DB users from Vault via Vault Secrets Operator (`VaultDynamicSecret`). Terraform codifies Vault DB engine config.

## Notes

- The admin DB user used by Vault must be able to CREATE ROLE (e.g., postgres). You can later tighten privileges by using a dedicated 'vault_admin' with specific grants.
- To avoid Terraform state holding the admin password long-term, consider removing the `password` field from the connection after first apply (and/or rotate via Vault), per HashiCorp guidance.
