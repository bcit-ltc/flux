# Flux Installation

Basic installation follows the instructions from [Fluxcd.io](https://fluxcd.io/flux/installation/bootstrap/github/#github-organization).

1. Export a GitHub personal access token with `repo` permissions. The `LTC TechOps` user was created to bootstrap Flux owned by the `bcit-ltc` organization.

```bash
export GITHUB_TOKEN=<gh-token>
```

1. Set your cluster context and set a corresponding environment

```bash
export CLUSTER=prod-xx
kubectl config set-context ... # make sure your context matches your `~/.kube/config`
export CLUSTER_ENV=latest|stable|review|web     # (choose one)
```

1. Ensure the `flux-system` namespace exists

```bash
kubectl create ns flux-system
```

1. Install Flux on the cluster

```bash
flux bootstrap github \
--token-auth \
--owner=bcit-ltc \
--repository=flux \
--branch=main \
--path=clusters/${CLUSTER}

# --components-extra=image-reflector-controller,image-automation-controller \
```

1. (optional) Adjust the flux controllers by adding the following patches to the `flux-system/kustomization.yaml` file.

```bash
# Kustomize flux controllers
#
patches:

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

1. Commit the changes to the repo and push them to GitHub

1. Reconcile the `flux-system` kustomization by running `flux reconcile kustomization flux-system --with-source` to patch the Kustomize Controller.

Flux should now be installed. :tada:

## Optional configuration

### Vault Secrets Operator

If integrating with [Vault Secrets Operator](https://github.com/hashicorp/vault-secrets-operator), the `vault-tokenauth` service account token needs to be added to the Vault `kubernetes-auth` configuration so that the Vault Secrets Operator can pull secrets into the cluster.

Follow the commands in the `vault-configuration` > `kubernetes-auth/README.md` file to retrieve the token and configure Vault.

### Cluster folder layout

Move the `stable|latest|review|web` folder to the desired cluster (`prod-01/prod-02/etc...`) and begin to uncomment the resources in the **infrastructure** `kustomization.yaml` file to deploy them. Once they are deployed, you can uncomment the **apps** resources in the `kustomization.yaml`.

See the [Flux GitOps Workflow](https://flux-config.io/flux/guides/mozilla-sops/#gitops-workflow).

### Secrets

[Vault](https://developer.hashicorp.com/vault/docs) and [SOPS](https://getsops.io/docs/) can be used to encode `secret`s using the following command:

```bash
sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/gitops-key --encrypt --encrypted-regex '^(data|stringData)$' file.yaml > file.enc.yaml
```

- **must have `stringData` to be applied as a resource**

```bash
printf 'my-secret-token' | sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/gitops-key \
--encrypt /dev/stdin > my-secret-token.encrypted
```

- **can be used with kustomize `secretGenerator`**

### Pulling images from a private registry

Flux kustomization configures a `dockerconfig.json` credentials to pull images. See `components/registry-credentials`.

## Upgrading

1. Update the `flux` binary

```bash
https://developer.hashicorp.com/vault/install
```

1. Re-run the flux bootstrap command above to upgrade Flux.

See [Flux Upgrade Guide](https://flux-config.io/flux/installation/upgrade/).
