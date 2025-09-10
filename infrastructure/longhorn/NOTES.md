# Longhorn

## Uninstalling

Longhorn uninstall requires a patch and removal of CRD's.

1. Patch the deployment

   `kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag`

1. Delete the CRD's manually

   `./uninstall-crds.sh`
