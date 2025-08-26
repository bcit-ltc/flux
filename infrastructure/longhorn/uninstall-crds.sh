#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
NAMESPACE="${NAMESPACE:-longhorn-system}"
# Tune parallelism: override with JOBS=8 ./script.sh
JOBS="${JOBS:-$(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# Namespaced Longhorn kinds
RES_KINDS=(
  "volumes.longhorn.io"
  "snapshot.longhorn.io"
  "replicas.longhorn.io"
  "engines.longhorn.io"
  "nodes.longhorn.io"
)
# ==================

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need kubectl
need jq

echo "This will remove finalizers from Longhorn resources in namespace: ${NAMESPACE}"
echo "Parallelism: ${JOBS} concurrent patches"
read -r -p "Type 'yes' to continue: " CONFIRM
[[ $CONFIRM == "yes" ]] || { echo "Aborted."; exit 1; }

# Remove finalizers from all objects of a namespaced kind (in parallel)
definalize_ns_kind() {
  local kind="$1" ns="$2"
  echo "→ Removing finalizers from ${kind} in ${ns}…"

  if ! kubectl -n "$ns" get "$kind" >/dev/null 2>&1; then
    echo "  (kind ${kind} not found in ${ns}, skipping)"
    return 0
  fi

  mapfile -t names < <(kubectl -n "$ns" get "$kind" -o jsonpath='{.items[*].metadata.name}' \
                       | tr ' ' '\n' | sed '/^$/d')
  (( ${#names[@]} )) || { echo "  (no ${kind} objects)"; return 0; }

  printf '%s\0' "${names[@]}" \
  | xargs -0 -I{} -P "${JOBS}" kubectl -n "$ns" patch "$kind" "{}" \
      --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null || true

  echo "  (patched ${#names[@]} objects)"
}

# 1) De-finalize the common namespaced kinds (parallel per-object)
for kind in "${RES_KINDS[@]}"; do
  definalize_ns_kind "$kind" "$NAMESPACE"
done

# 2) Longhorn CRDs: de-finalize instances in our namespace, delete them, then drop the CRD
echo "→ Processing Longhorn CRDs…"
mapfile -t crds < <(kubectl get crd -o json \
  | jq -r '.items[].metadata.name' \
  | grep -E '(^|\.)(longhorn\.io)$' || true)

if (( ${#crds[@]} == 0 )); then
  echo "  (no Longhorn CRDs found)"
else
  for crd in "${crds[@]}"; do
    echo "  • $crd"

    # Some CRDs are namespaced; we respect your constraint and scope to the Longhorn namespace
    if kubectl -n "$NAMESPACE" get "$crd" >/dev/null 2>&1; then
      # Patch all instances (parallel)
      mapfile -t inst < <(kubectl -n "$NAMESPACE" get "$crd" -o json \
        | jq -r '.items[].metadata.name' 2>/dev/null | sed '/^$/d')
      if (( ${#inst[@]} )); then
        printf '%s\0' "${inst[@]}" \
        | xargs -0 -I{} -P "${JOBS}" kubectl -n "$NAMESPACE" patch "$crd" "{}" \
            --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1 || true
        echo "    (patched ${#inst[@]} instances)"
      else
        echo "    (no instances in ${NAMESPACE})"
      fi

      # Delete all instances without waiting
      kubectl -n "$NAMESPACE" delete "$crd" --all --wait=false >/dev/null 2>&1 || true
    else
      echo "    (no namespaced instances of $crd in ${NAMESPACE})"
    fi

    # Finally delete the CRD itself
    kubectl delete crd "$crd" >/dev/null 2>&1 || true
  done
fi

echo "Done."

# If this fails, try:

#     kubectl delete ValidatingWebhookConfiguration longhorn-webhook-validator
#     kubectl delete MutatingWebhookConfiguration longhorn-webhook-mutator

# Then run again.