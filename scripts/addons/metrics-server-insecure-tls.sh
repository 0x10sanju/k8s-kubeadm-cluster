#!/usr/bin/env bash
# Make `kubectl top` work on clusters whose kubelets use self-signed certificates
# (kind, devbox, a fresh kubeadm cluster) by adding --kubelet-insecure-tls to metrics-server.
#
# WARNING: this makes metrics-server skip TLS verification when it talks to kubelets.
# Fine for local/dev clusters. For production, enable kubelet serving certificates
# (serverTLSBootstrap: true) and approve the CSRs instead.
#
# Prerequisite: metrics-server is already deployed. Safe to re-run.
# Overrides: NAMESPACE, DEPLOYMENT, CONTAINER (defaults: kube-system, metrics-server, metrics-server)
set -euo pipefail

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

NAMESPACE=${NAMESPACE:-kube-system}
DEPLOYMENT=${DEPLOYMENT:-metrics-server}
CONTAINER=${CONTAINER:-metrics-server}
FLAG=--kubelet-insecure-tls

# ---------- Preflight ----------
command -v kubectl >/dev/null 2>&1 || die "kubectl not found in PATH"
context=$(kubectl config current-context 2>/dev/null) \
  || die "No current kubectl context. Is your kubeconfig set up?"
log "Cluster context: $context"

kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" >/dev/null 2>&1 \
  || die "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'. Install metrics-server first."

warn "Adding $FLAG disables kubelet certificate verification. Do not use this in production."

# ---------- Find the container ----------
names=$(kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" \
  -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"\n"}{end}')
idx=-1
i=0
while IFS= read -r name; do
  if [ "$name" = "$CONTAINER" ]; then idx=$i; break; fi
  i=$((i + 1))
done <<< "$names"
[ "$idx" -ge 0 ] || die "Container '$CONTAINER' not found in deployment '$DEPLOYMENT' (found: $(echo "$names" | tr '\n' ' '))"

# ---------- Patch (only if needed) ----------
args=$(kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" \
  -o jsonpath="{.spec.template.spec.containers[$idx].args}")

if printf '%s' "$args" | grep -qF -- "\"$FLAG\""; then
  log "$FLAG is already set, nothing to change"
else
  log "Adding $FLAG to $DEPLOYMENT"
  if [ -z "$args" ]; then
    # Container has no args list yet, so create it
    patch="[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/$idx/args\",\"value\":[\"$FLAG\"]}]"
  else
    patch="[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/$idx/args/-\",\"value\":\"$FLAG\"}]"
  fi
  kubectl -n "$NAMESPACE" patch deployment "$DEPLOYMENT" --type=json -p="$patch"
fi

# ---------- Wait for rollout ----------
log "Waiting for rollout"
kubectl -n "$NAMESPACE" rollout status deployment "$DEPLOYMENT" --timeout=120s \
  || die "Rollout did not finish in time. Check: kubectl -n $NAMESPACE describe deployment $DEPLOYMENT"

log "Done. Metrics can take up to a minute to appear; then try: kubectl top nodes"

