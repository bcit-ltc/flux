# App deployment

Adds workloads to be deployed by Flux.

## Requirements

- app container in GitHub Packages
- OCI container (helm chart) in GitHub Packages

## Adding an app

1. Copy the `apps/0-app-template` folder

1. Paste into `apps` and rename based on ${appName}

1. Replace all instances of `app` in the folder with ${appName}

1. Add the folder to `apps/kustomization.yaml`

1. Commit and push the changes, and then reconcile the `flux-system` kustomization

    ```bash
    git add . && git commit -m "adds ${appName}" && git push origin main

    flux reconcile kustomization flux-system --with-source
    ```

1. Confirm deployment on the clusters :)
