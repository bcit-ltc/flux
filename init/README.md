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
    ```

1. Set the cluster context and a corresponding environment

    ```bash
    export CLUSTER=cluster0X

    export CLUSTER_ENV=latest|stable        # (choose one)

    kubectl config use-context ${CLUSTER}   # make sure your context matches your `~/.kube/config`
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

    # Increases flux git repository interval to 1 day
    - target:
        kind: GitRepository
        name: flux-system
        patch: |-
        - op: replace
            path: /spec/interval
            value: 24h

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
    git add . && git commit -m "increases flux-system sync interval" && git push origin main

    flux reconcile kustomization flux-system --with-source
    ```

## Migrating/re-instantiating clusters

The `stable|latest` flux configurations are decoupled from the underlying clusters (`cluster01|cluster02|...`) by folder architecture.

To apply a flux config to a new/different cluster, move or copy a `stable`/`latest`/etc... folder to a new/different cluster folder (`cluster01`/`cluster02`/etc...).

Test a cluster's `kustomization` by uncommenting resource entries in the `cluster0x/{env}/kustomization.yaml` and the `/infrastructure|/apps` `kustomization.yaml`.

## Secrets

[Vault](https://developer.hashicorp.com/vault/docs) and [SOPS](https://getsops.io/docs/) can be used to encode Kubernetes secrets:

See the [Flux SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/) for information.

## Upgrading Flux

1. Re-run the flux bootstrap command above to upgrade Flux.

    See [Flux Upgrade Guide](https://flux-config.io/flux/installation/upgrade/) for details.
