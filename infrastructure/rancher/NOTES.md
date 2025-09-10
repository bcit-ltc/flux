<!-- markdownlint-disable MD051 -->

# Rancher deployment with Flux

Deploying Rancher to a cluster requires that a TLS secret be available for the Helm install.

This is a modified init procedure that adds SOPS decryption to the Flux controllers.

## Requirements

- Vault CLI
- Kubernetes CLI
- Kustomize
- Flux CLI

## Flux bootstrap

> Assuming `admin` cluster is associated with "cluster00"

1. Start by ensuring the `resources` section of `admin/kustomization.yaml` is commented out. This ensures Rancher isn't deployed until the cluster is configured.

1. Login to Vault and set the `VAULT_TOKEN` env var

    ```bash
    vault login -method=oidc username={yourBCITEmail}

    export VAULT_TOKEN={tokenId}
    ```

1. Set the cluster context and set a corresponding environment

    ```bash
    export CLUSTER=cluster00

    kubectl config set-context cluster00   # make sure your context matches your `~/.kube/config`

    export CLUSTER_ENV=admin
    ```

1. Ensure the `flux-system` namespace exists

    ```bash
    kubectl create ns flux-system
    ```

1. Retrieve the "sops-vault-token" credentials

    *If a new token is required, see the [SOPS token requirements](../../components/sops-vault-token/NOTES.md) section of the `sops-vault-token` component*

    ```bash
    SOPS_TOKEN=$(vault kv get -mount="ltc-infrastructure" -field="sops.vault-token" "flux/sops-vault-token") \
      && echo ${SOPS_TOKEN}
    ```

1. Create the `sops-vault-token` secret in the `flux-system` namespace

    ```bash
    echo ${SOPS_TOKEN} | kubectl create secret generic sops-vault-token \
    -n flux-system --from-file=sops.vault-token=/dev/stdin
    ```

1. A GitHub personal access token with `repo` permissions is required; the `LTC TechOps` user was created for this purpose. Retrieve it and set the env var:

    ```bash
    export GITHUB_TOKEN=$(vault kv get -mount="ltc-infrastructure" -field="github-token" "flux/bootstrap-token") \
    && echo ${GITHUB_TOKEN}
    ```

1. Install Flux on the cluster

    ```bash
    flux bootstrap github \
    --token-auth \
    --owner=bcit-ltc \
    --repository=flux \
    --branch=main \
    --path=clusters/${CLUSTER}
    ```

1. Pull the changes from the remote and reconcile the `flux-system` kustomization

    ```bash
    git fetch && git pull

    flux reconcile kustomization flux-system --with-source
    ```

1. Adjust the flux controller by adding the following patch to the `flux-system/kustomization.yaml` file

    ```bash
    //flux-system/kustomization.yaml

    # Kustomize flux controllers
    patches:

    # Adds global decryption strategy to `flux-system` Kustomization
    - target:
        kind: Kustomization
    patch: |-
        - op: add
        path: /spec/decryption
        value: { provider: sops, secretRef: { name: sops-vault-token }}
    ```

1. Commit and push the changes, and then reconcile the `flux-system` kustomization

    ```bash
    git add . && git commit -m "adds sops decryption" && git push origin/main

    flux reconcile kustomization flux-system --with-source
    ```

Flux with SOPS should now be installed. 🎉

## Rancher deployment

1. If Flux is bootstrapped with SOPS decryption, now all that's needed is for the `resources` section of `admin/kustomization.yaml` to be uncommented.

    Then commit and push the changes, and then reconcile the `flux-system` kustomization.

### Alternate method

1. Ensure the `cattle-system` namespace is present

    ```bash
    kubectl create ns cattle-system
    ```

1. Deploy the `tls-rancher-ingress` secret

    ```bash
    vault kv get -mount=ltc-infrastructure "rancher/admin/tls-rancher-ingress" | kubectl apply -f -
    ```

    Or alternatively,

    ```bash
    sops -d tls-rancher-ingress.enc.yaml | kubectl apply -f -
    ```

1. Deploy Rancher

    ```bash
    kustomize build clusters/admin-03/admin | kubectl apply -f -
    ```

1. Adjust the flux controllers by adding the following patches to the `flux-system/kustomization.yaml` file.

    ```bash
    # Kustomize flux controllers
    patches:

    # Adds global decryption strategy to `flux-system` Kustomization
    - target:
        kind: Kustomization
        patch: |-
        - op: add
            path: /spec/decryption
            value: { provider: sops, secretRef: { name: sops-vault-token }}
    ```

1. Commit and push the changes, and then reconcile the `flux-system` kustomization

    ```bash
    git add . && git commit -m "adds sops decryption" && git push origin/main

    flux reconcile kustomization flux-system --with-source
    ```
