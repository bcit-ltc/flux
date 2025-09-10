<!-- markdownlint-disable MD051 -->

# Rancher deployment with Flux

Deploying Rancher to a cluster requires that a TLS secret be available for the Helm install.

Follow the `init/README.md` steps to install Flux on a cluster. Then, decrypt a secret with SOPS and deploy it to the Rancher namespace.

## Rancher deployment

1. Ensure the `cattle-system` namespace is present

    ```bash
    kubectl create ns cattle-system
    ```

1. Deploy the `tls-rancher-ingress` secret

    ```bash
    sops -d tls-rancher-ingress.enc.yaml | kubectl apply -n cattle-system -f -
    ```

1. Uncomment the `rancher` resource in `clusters/${CLUSTER}/admin/kustomization.yaml`. Then commit and push the changes, and then reconcile the `flux-system` kustomization.

    ```bash
    git add . && git commit -m "adds sops decryption" && git push origin main

    flux reconcile kustomization flux-system --with-source
    ```
