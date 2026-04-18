#!/usr/bin/env bash
set -euo pipefail

STRATEGY="${1:-rolling-update}"
NAMESPACE="${2:-aceest}"
CANDIDATE_IMAGE="${3:-aceest-app:latest}"
STABLE_IMAGE="${4:-$CANDIDATE_IMAGE}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is required to deploy ACEest manifests." >&2
    exit 1
  fi
}

rollout() {
  kubectl rollout status "deployment/$1" -n "$NAMESPACE"
}

require_kubectl
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/base/configmap.yaml"

case "$STRATEGY" in
  rolling-update)
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/base/service.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/rolling-update/deployment.yaml"
    kubectl set image deployment/aceest-app aceest-app="$CANDIDATE_IMAGE" -n "$NAMESPACE"
    rollout aceest-app
    ;;
  blue-green)
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/blue-green/deployment-blue.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/blue-green/deployment-green.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/blue-green/service-active-blue.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/blue-green/service-preview-green.yaml"
    kubectl set image deployment/aceest-app-blue aceest-app="$STABLE_IMAGE" -n "$NAMESPACE"
    kubectl set image deployment/aceest-app-green aceest-app="$CANDIDATE_IMAGE" -n "$NAMESPACE"
    rollout aceest-app-blue
    rollout aceest-app-green
    echo "Preview is exposed through service/aceest-app-preview."
    echo "Promote green by applying k8s/blue-green/service-active-green.yaml."
    ;;
  canary)
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/base/service.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/canary/deployment-stable.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/canary/deployment-canary.yaml"
    kubectl set image deployment/aceest-app-stable aceest-app="$STABLE_IMAGE" -n "$NAMESPACE"
    kubectl set image deployment/aceest-app-canary aceest-app="$CANDIDATE_IMAGE" -n "$NAMESPACE"
    rollout aceest-app-stable
    rollout aceest-app-canary
    echo "Traffic split follows replica ratio 4:1 (stable:canary)."
    ;;
  shadow)
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/shadow/service-primary.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/shadow/service-shadow.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/shadow/deployment-primary.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/shadow/deployment-shadow.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/shadow/ingress-mirror.yaml"
    kubectl set image deployment/aceest-app-primary aceest-app="$STABLE_IMAGE" -n "$NAMESPACE"
    kubectl set image deployment/aceest-app-shadow aceest-app="$CANDIDATE_IMAGE" -n "$NAMESPACE"
    rollout aceest-app-primary
    rollout aceest-app-shadow
    ;;
  ab-testing)
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/service-a.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/service-b.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/deployment-a.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/deployment-b.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/ingress-primary.yaml"
    kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/ab-testing/ingress-experiment.yaml"
    kubectl set image deployment/aceest-app-a aceest-app="$STABLE_IMAGE" -n "$NAMESPACE"
    kubectl set image deployment/aceest-app-b aceest-app="$CANDIDATE_IMAGE" -n "$NAMESPACE"
    rollout aceest-app-a
    rollout aceest-app-b
    echo "Send header 'X-Experiment: B' to route a client into variant B."
    ;;
  *)
    echo "Unknown strategy: $STRATEGY" >&2
    exit 1
    ;;
esac

kubectl get pods,svc,ingress -n "$NAMESPACE"
