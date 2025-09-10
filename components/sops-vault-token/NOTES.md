# Optional SOPS configuration

> See <https://fluxcd.io/flux/guides/mozilla-sops/>

Flux can decrypt SOPS secrets on the fly" as they are applied to a cluster. These steps demonstrate how to configure the flux controllers to automatically decrypt SOPS secrets.

## Retrieve the SOPS token and patch

1. Retrieve the "sops-vault-token" credentials

    *If a new token is required, see the [SOPS token requirements](../../components/sops-vault-token/NOTES.md) section of `components/sops-vault-token`*

  ```bash
  SOPS_TOKEN=$(vault kv get -mount="ltc-infrastructure" -field="sops.vault-token" "flux/sops-vault-token") \
  && echo "${SOPS_TOKEN}"
  ```

1. Create the `sops-vault-token` secret in the `flux-system` namespace

  ```bash
  echo ${SOPS_TOKEN} | kubectl create secret generic sops-vault-token \
  -n flux-system --from-file=sops.vault-token=/dev/stdin
  ```

1. Patch the Flux config `flux-system/kustomization.yaml` file

  ```bash
  //flux-system/kustomization.yaml

  # Kustomize flux controllers
  patches:

  # Adds global decryption strategy to `flux-system` Kustomization
  - target:
      kind: Kustomization
      name: flux-system
    patch: |-
      - op: add
        path: /spec/decryption
        value: { provider: sops, secretRef: { name: sops-vault-token } }
  ```

1. Commit and push the changes, and then reconcile the `flux-system` kustomization

  ```bash
  git add . && git commit -m "adds sops decryption" && git push origin main

  flux reconcile kustomization flux-system --with-source
  ```

## SOPS token requirements

The sops encrypt/decrypt token is able to renew itself, but if a new token is required, create and store like this:

```bash
vault token create -role=use-transit-gitops-key

vault kv put -mount="ltc-infrastructure" sops.vault-token=$SOPS_TOKEN "flux/sops-vault-token"
```
