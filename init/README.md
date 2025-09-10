<!-- markdownlint-disable MD046 -->
# Flux Installation

These steps augment the instructions from [Fluxcd.io](https://fluxcd.io/flux/installation/bootstrap/github/#github-organization).

## Requirements

- Vault CLI
- Kubernetes CLI
- Kustomize
- Flux CLI

## Flux bootstrap

1. Login to Vault and set the `VAULT_TOKEN` env var

    ```bash
    vault login -method=oidc username={yourBCITEmail}

    export VAULT_TOKEN={tokenId}
    ```

1. Set your cluster context and set a corresponding environment

    ```bash
    export CLUSTER=cluster0X
    kubectl config set-context ...      # make sure your context matches your `~/.kube/config`
    export CLUSTER_ENV=latest|stable    # (choose one)
    ```

1. Ensure the `flux-system` namespace exists

    ```bash
    kubectl create ns flux-system
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

Flux should now be installed. 🎉

## Optional configuration

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

    # Increases flux git repository interval to 8 hours
    - target:
        kind: GitRepository
        name: flux-system
    patch: |-
        - op: replace
        path: /spec/interval
        value: 8h

    # Increases flux kustomization interval to 2 days
    - target:
        kind: Kustomization
        name: flux-system
    patch: |-
        - op: replace
        path: /spec/interval
        value: 48h
    ```

1. Commit and push the changes, and then reconcile the `flux-system` kustomization

    ```bash
    git add . && git commit -m "adds sops decryption" && git push origin main

    flux reconcile kustomization flux-system --with-source
    ```

## Migrating/re-instantiating clusters

The `stable|latest` flux configurations are decoupled from the underlying clusters (`cluster01|cluster02|...`) by folder architecture.

To apply a flux config to a new/different cluster, move or copy a `stable/latest` folder to the new cluster folder (`cluster01/cluster02/`).

Uncomment the resources in `infrastructure/kustomization.yaml` first. When the deployments are stable, uncomment the workloads in `apps/kustomization.yaml`.

## Secrets

[Vault](https://developer.hashicorp.com/vault/docs) and [SOPS](https://getsops.io/docs/) can be used to encode Kubernetes secrets:

```bash
sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/gitops-key --encrypt \
--encrypted-regex '^(data|stringData)$' file.yaml > file.enc.yaml
```

- YAML manifests must have `stringData` to be used with SOPS

Tokens can be encoded in a similar way:

```bash
printf 'my-secret-token' | sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/gitops-key \
--encrypt /dev/stdin > my-secret-token.encrypted
```

## Pulling images from a private registry

Flux kustomization can configure a `dockerconfig.json` credential to pull images. See `components/registry-credentials`.

## Upgrading Flux

1. Update the `flux` binary

    ```bash
    https://developer.hashicorp.com/vault/install
    ```

1. Re-run the flux bootstrap command above to upgrade Flux.

    See [Flux Upgrade Guide](https://flux-config.io/flux/installation/upgrade/) for details.
