# Kubernetes Deployment Strategies

This folder contains assignment-ready manifests for the five rollout styles requested in Assignment 2:

- `rolling-update/` keeps the `aceest-app` service stable while new pods replace old pods gradually.
- `blue-green/` keeps a stable `blue` deployment live and a `green` candidate available for preview and promotion.
- `canary/` uses a shared service and a 4:1 replica split so a small percentage of requests reach the candidate pods.
- `shadow/` mirrors production traffic to a shadow deployment using NGINX Ingress annotations.
- `ab-testing/` routes experiment traffic to variant B when the request header `X-Experiment: B` is present.

## Quick usage

```bash
chmod +x scripts/deploy_strategy.sh
./scripts/deploy_strategy.sh rolling-update aceest your-dockerhub-user/aceest-app:v3.2.4
./scripts/deploy_strategy.sh canary aceest your-dockerhub-user/aceest-app:v3.2.5 your-dockerhub-user/aceest-app:v3.2.4
```

## Rollback examples

- Rolling update: `kubectl rollout undo deployment/aceest-app -n aceest`
- Blue-green: `kubectl apply -n aceest -f k8s/blue-green/service-active-blue.yaml`
- Canary: `kubectl scale deployment/aceest-app-canary --replicas=0 -n aceest`
- Shadow: remove `k8s/shadow/ingress-mirror.yaml` if the candidate should stop receiving mirrored traffic
- A/B testing: delete `k8s/ab-testing/ingress-experiment.yaml` to keep all traffic on variant A
