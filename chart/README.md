# crococoder-status chart

Deploys the crococoder-status API: a Deployment, a Service and an optional ServiceMonitor.
It is written to pass the Pod Security `restricted` level and the namespace quota
created by `ref-infra`.

The environment values (image tag, replicas, resources) are NOT in this folder: they live in
`ref-gitops/apps/crococoder-status/`.

```bash
# validate, from the root of ref-app-node
helm lint ./chart -f ../ref-gitops/apps/crococoder-status/values-dev.yaml
helm template test ./chart -f ../ref-gitops/apps/crococoder-status/values-dev.yaml
helm template test ./chart -f ../ref-gitops/apps/crococoder-status/values-prod.yaml
```

Rendering fails on purpose if `image.tag` is empty or `latest`.
