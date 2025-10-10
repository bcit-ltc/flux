<!-- markdownlint-disable MD051 -->

# Rancher deployment with Flux

Deploying Rancher to a cluster requires that a TLS secret be available for the Helm install.

Follow the `init/README.md` steps to install Flux on a cluster. Then, create a secret for Rancher and deploy it to the Rancher namespace.

## Rancher deployment

1. Ensure the `cattle-system` namespace is present

    ```bash
    kubectl create ns cattle-system
    ```

1. Set `VAULT_TOKEN` and `VAULT_ADDR`

    ```bash
    export VAULT_TOKEN={yourVaultToken} && export VAULT_ADDR=https://vault.ltc.bcit.ca:8200
    ```

1. Deploy the `tls-rancher-ingress` secret

    ```bash
    curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/ltc-infrastructure/data/ssl-certificates/star-ltc-bcit-ca" \
    | jq '{
        apiVersion: "v1",
        kind: "Secret",
        metadata: { name: "tls-rancher-ingress", namespace: "default" },
        type: "kubernetes.io/tls",
        data: {
        "tls.crt": (.data.data["tls.crt"] | @base64),
        "tls.key": (.data.data["tls.key"] | @base64)
        }
    }' \
    | kubectl apply -f -
    ```

1. Uncomment the `rancher` resource in `clusters/${CLUSTER}/admin/kustomization.yaml`. Then commit and push the changes, and then reconcile the `flux-system` kustomization.

    ```bash
    git add . && git commit -m "adds Rancher" && git push origin main

    flux reconcile kustomization flux-system --with-source
    ```
