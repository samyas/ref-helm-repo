# Runbook: bad release or rising 5xx on crococoder-status

**Use when:** the alert `ErrorBudgetFastBurn` or `HighErrorRate` fires, or Argo CD shows
`crococoder-status-<env>` as `Degraded`.

## Golden rule

The cluster follows Git. **Do not fix things by hand with `kubectl`**: Argo CD (self-heal) puts
back what is in Git within seconds. Fix **Git**, then let Argo CD apply it.

## 1. Assess (first 5 minutes)

```bash
# What does Argo CD say?
kubectl get applications -n argocd
argocd app get crococoder-status-dev        # replace dev with prod if needed

# What are the Pods doing?
kubectl get pods -n dev
kubectl describe pod -n dev <pod-name>      # read the Events at the bottom
kubectl logs -n dev <pod-name> --tail=50
kubectl get events -n dev --sort-by=.lastTimestamp | tail -15

# How bad is it for users? (Prometheus UI, Graph tab)
sum(rate(http_requests_total{namespace="dev",status=~"5.."}[5m])) / sum(rate(http_requests_total{namespace="dev"}[5m]))
```

Note the time you started and what you see; the post-mortem needs it.

## 2. Diagnose: which case is it?

| What you see | Likely cause | Go to |
|---|---|---|
| `ImagePullBackOff` or `ErrImagePull` | Wrong image tag, or package not readable | 3A |
| `CrashLoopBackOff` | The new version crashes at start | 3B |
| Pods `Running` but 5xx ratio high | The new version returns errors | 3B |
| Pods `Pending`, event mentions `exceeded quota` | Quota too small for the rollout | 3C |
| Prometheus target DOWN, app answers on port-forward | NetworkPolicy blocks `monitoring` | 3D |

Check what changed: `git log --oneline -10` in the config repo. The last commit on
`apps/crococoder-status/values-*.yaml` is the first suspect.

## 3. Mitigate

### 3A / 3B. Bad version: revert in Git

```bash
cd ref-config-repo                  # your config repo
git log --oneline -5                # find the faulty commit
git revert <commit-sha>             # creates a new commit that undoes it
git push
```

- **dev:** Argo CD syncs by itself within a few minutes. Speed it up with
  `argocd app sync crococoder-status-dev`.
- **prod:** use a merge request, then press **Sync** on `crococoder-status-prod`.

With `maxUnavailable: 0` a rollout that cannot start the new Pod keeps the old Pods serving, so
users often see nothing during a bad tag. That is normal; still fix it.

### 3C. Quota

Check `kubectl describe resourcequota quota -n <env>`. If the quota is really too low, change it
in `ref-infra`, plan and apply. Do not delete the quota by hand.

### 3D. NetworkPolicy

Check `networkPolicy.enabled` and `monitoringNamespace` in the values, and that the policy exists:
`kubectl get networkpolicy -n <env>`.

## 4. Verify the recovery

- `kubectl get pods -n <env>`: all `Running` and `READY`.
- Argo CD shows `Synced` and `Healthy`.
- The 5xx ratio is back to normal and the alert returns to **Inactive** (the 5m window clears
  first, the 1h window later).
- `curl` through a port-forward shows the expected version on `/`.

## 5. After the incident

- Write the post-mortem (`docs/postmortem-template.md`) within a few days, blameless.
- Compute how much error budget was used and apply the policy in `docs/slo.md`.
- Update this runbook with anything that was missing or wrong.

## Roles (when more than one person is available)

Incident commander (decides, keeps the timeline), operator (runs the commands),
communicator (informs stakeholders), scribe (writes times and actions). When working alone, one
person takes each role in turn and still writes the timeline.
