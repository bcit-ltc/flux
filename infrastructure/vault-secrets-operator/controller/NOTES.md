# Vault Secrets Operator Notes

If integrating with [Vault Secrets Operator](https://github.com/hashicorp/vault-secrets-operator) (VSO), a service account token is required for the Kubernetes auth configuration.

Deploy the necessary resources to prepare the cluster for VSO.

1. Apply the init resources

    ```bash
    kustomize build infrastructure/vault-secrets-operator/init/ | kubectl apply -f -
    ```

    This creates:

    - the `vault-secrets-operator-system` namespace
    - a service account and a token
    - a cluster role binding

1. Next, follow the steps in the `vault` repo `modules/kubernetes-auth/NOTES.md`

    This provisions a service account token and configures Vault to accept connections using the Kubernetes auth method.
