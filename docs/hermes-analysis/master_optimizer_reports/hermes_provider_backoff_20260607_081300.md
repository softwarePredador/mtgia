# Hermes Provider Backoff Report

- jobs_path: `/opt/data/cron/jobs.json`
- mode: apply
- candidates: 10
- changed: 10
- backup: `/opt/data/cron/jobs.json.bak_provider_backoff_20260607_081300`

## Jobs

| Status | Name | Enabled | State | Last Status | Reason |
| --- | --- | --- | --- | --- | --- |
| paused | manaloom-hermes-normal-audit | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-commander-knowledge-deep | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-gamechanger-research | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-tag-accuracy-reporter | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-mana-base-validator | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-code-structure-auditor | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-logic-coherence-auditor | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-knowledge-synthesis | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | mtg-rules-auditor | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |
| paused | manaloom-cron-governor-report | False | paused | error | provider_429_backoff: paused by hermes_provider_backoff.py |

## Policy

- Operational no-agent jobs are not paused by this script.
- Provider-limited agent jobs should be resumed only after quota/backoff is resolved.
- Resume manually by setting `enabled=true`, `state=scheduled`, and clearing `paused_reason`.
