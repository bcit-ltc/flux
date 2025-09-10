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

Follow the steps in the `vault` repo `modules/kubernetes-auth/NOTES.md` file to retrieve the service account token and configure the Vault Kubernetes auth method.
