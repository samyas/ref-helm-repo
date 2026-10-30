# SLO: crococoder-status availability

One-page service level document. The alert in the Helm chart (`ErrorBudgetFastBurn`) is
built from the numbers below: if you change one, change the other.

## Service

`crococoder-status`, an internal HTTP API, deployed in the `dev` and `prod` namespaces.
The SLO applies to **prod**. Dev uses the same rules so the alerts can be tested.

## SLI (what we measure)

The share of HTTP requests that are **not** server errors:

```promql
sum(rate(http_requests_total{namespace="prod",status!~"5.."}[5m]))
  / sum(rate(http_requests_total{namespace="prod"}[5m]))
```

Source: the `http_requests_total` counter exposed on `/metrics`, scraped by Prometheus.

**Known limitation.** Kubernetes probes call `/health` every few seconds and are counted as
successful requests. With little real traffic they dilute the error ratio and make the service
look healthier than users experience. Improvement for later: add a `route` label to the metric
and exclude `/health`.

## SLO (the target)

**99.5% of requests are not 5xx, over a rolling 30 days.**

## Error budget

- Budget = 100% - 99.5% = **0.5% of requests** may fail.
- As time: 30 days x 24 h x 60 min x 0.005 = **216 minutes** of full outage per 30 days.

## Alert: fast burn rate

The burn rate is how fast the budget is being spent. Burn rate 1 spends exactly the whole
budget in 30 days.

| Item | Value |
|---|---|
| Burn rate threshold | 14.4 |
| Error ratio threshold | 14.4 x 0.005 = **0.072** (7.2%) |
| Windows | 1 hour **and** 5 minutes, both above the threshold |
| Hold time | 2 minutes |
| Severity | critical (someone must act now) |

Why these numbers: at burn rate 14.4, **2% of the monthly budget is spent in 1 hour**, and the
whole budget would be gone in about 2 days. The 1h window proves the problem is sustained, and
the 5m window makes the alert stop quickly once the problem is fixed.

## Policy: what we do with the budget

| Budget remaining (30 days) | Decision |
|---|---|
| More than 50% | Normal pace: features and releases go ahead. |
| 25% to 50% | Releases need a second look; reliability work is added to the next iteration. |
| Less than 25% | Freeze non-urgent releases. Only reliability fixes go to prod. |
| Exhausted | Full release freeze until the budget recovers. A post-mortem is mandatory. |

Any incident that triggers `ErrorBudgetFastBurn` gets a blameless post-mortem
(`docs/postmortem-template.md`) and, if it was caused by a release, an action to prevent the
same change from reaching prod unchecked.

## Review

Review the SLO after every incident and at least once a quarter. If the budget is never used,
the target may be too loose for what users need. If it is always empty, it may be too strict,
or the service needs work.
