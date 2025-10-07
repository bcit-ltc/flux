# Cloudnative-pg + Vault Secrets Operator - Dynamic Secrets

Cloudnative-pg provides a Postgres cluster, and app databases are provisioned using the `app-databases` config. Apps get short‑lived DB users from Vault via Vault Secrets Operator (`VaultDynamicSecret`). Terraform codifies Vault DB engine config.

## Usage

Uncomment the `./cnpg-operator` resource in `./kustomization.yaml` When the operator has been deployed, uncomment the `./cnpg-cluster` resource and let it stabilize. Troubleshoot if there are errors.

When the cluster is healthy, uncomment app database configs, like `./app-databases/qcon-api`.

## Notes

- The admin DB user used by Vault to CREATE ROLE (e.g., postgres) is `init-secret`.

## Check app DB connection

    kubectl -n qcon run psql-test --rm -it --restart=Never \
    --image=ghcr.io/cloudnative-pg/postgresql:16 -- \
    bash -ceu "
        export PGHOST=$(kubectl -n qcon get secret db-credentials -o jsonpath='{.data.PGHOST}' | base64 -d)
        export PGUSER=$(kubectl -n qcon get secret db-credentials -o jsonpath='{.data.PGUSER}' | base64 -d)
        export PGPASSWORD=$(kubectl -n qcon get secret db-credentials -o jsonpath='{.data.PGPASSWORD}' | base64 -d)
        export PGDATABASE=$(kubectl -n qcon get secret db-credentials -o jsonpath='{.data.PGDATABASE}' | base64 -d)
        export PGPORT=$(kubectl -n qcon get secret db-credentials -o jsonpath='{.data.PGPORT}' | base64 -d)
        echo 'Testing connection to '$PGDATABASE' as '$PGUSER'...'
        psql \"host=\$PGHOST port=\$PGPORT user=\$PGUSER password=\$PGPASSWORD dbname=\$PGDATABASE sslmode=require\" \
        -c 'SELECT current_user, current_database();'
    "

Or use the kubectl plugin for cnpg:

    kubectl cnpg status pg-core-stable -n postgres
