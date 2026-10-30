# Post-mortem: <short title of the incident>

> **Blameless.** The goal is to learn how the system and the process allowed this to happen,
> not to find someone to blame. Describe actions and decisions, not people's faults.
> Fill every section with **real data from your incident** (timestamps from your notes,
> numbers from Prometheus and Argo CD). Remove the hints in italics when done.

| | |
|---|---|
| Date | *YYYY-MM-DD* |
| Environment | *dev / prod* |
| Status | *Draft / Final* |
| Severity | *Minor / Major / Critical* |
| Duration | *from detection to recovery* |

## Roles

| Role | Who |
|---|---|
| Incident commander | |
| Operator | |
| Communicator | |
| Scribe | |

*Working alone? Write your name next to each role and say so.*

## Summary

*Two or three sentences: what happened, what users or the service experienced, how it was fixed.*

## Impact

- **User impact:** *what failed, for how long? (HTTP 5xx? no impact because old Pods kept serving?)*
- **SLO impact:** *peak 5xx ratio, error budget consumed, remaining budget. Use the numbers from docs/slo.md.*
- **Alerts that fired:** *name, time it went Pending, time it went Firing.*

## Timeline (UTC)

| Time | Event |
|---|---|
| *hh:mm* | *Change merged / pushed (which commit?)* |
| *hh:mm* | *Argo CD synced; first symptom* |
| *hh:mm* | *Alert Pending, then Firing* |
| *hh:mm* | *Incident declared; roles assigned* |
| *hh:mm* | *Diagnosis: what was checked, what was found* |
| *hh:mm* | *Mitigation started (git revert, commit sha)* |
| *hh:mm* | *Service recovered; alert resolved* |

## Detection

*How was it noticed: alert, dashboard, a person? How long between the cause and the detection?
Was that fast enough?*

## Root causes

*Go beyond the trigger. Ask "why" several times.*

1. **Trigger:** *e.g. a tag that does not exist was committed to values-dev.yaml.*
2. **Why was it possible?** *e.g. nothing checks that the tag exists in the registry before merge.*
3. **Why was it not caught earlier?** *e.g. no validation in the merge request.*

## What went well

- *e.g. rolling update with maxUnavailable 0 kept the old Pods serving.*
- *e.g. the alert fired and the runbook led to the right fix.*

## What went badly

- *…*

## Where we got lucky

- *Things that could have made it worse but did not.*

## Action items

| Action | Type (prevent / detect / mitigate) | Owner | Due date |
|---|---|---|---|
| *e.g. Add a CI check that the image tag exists in GHCR before merging a values change* | prevent | | |
| *e.g. Alert when a Deployment has unavailable replicas for more than 5 minutes* | detect | | |
| *e.g. Update the runbook step …* | mitigate | | |

## Lessons

*What does this incident teach about the platform, the process or the tooling?*
