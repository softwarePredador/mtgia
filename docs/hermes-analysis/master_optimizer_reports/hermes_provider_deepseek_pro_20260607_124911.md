# Hermes Provider Migration — deepseek-pro

- created_at: 2026-06-07T12:49:11+00:00
- server: `ubuntu@3.16.217.179`
- container: `d5fe57bf9de2`
- secret handling: API key stored only on the server; not written to this repository.

## Requested target

Configure Hermes to run provider-backed jobs through `deepseek-pro`.

The literal model value `opencode` was tested first because it was requested by the operator. Hermes created sessions with `model=opencode`, but the provider returned:

```text
RuntimeError: HTTP 404 — Not Found | opencode
```

That value is not a working model identifier for the current Hermes/OpenCode endpoint.

## Working configuration

The functional configuration is:

- provider: `deepseek-pro`
- model: `deepseek-v4-pro`
- base URL: `https://opencode.ai/zen/go/v1`
- env provider marker: `OPENCODE_PROVIDER=deepseek-pro`
- env model marker: `OPENCODE_MODEL=deepseek-v4-pro`

The first custom provider attempt used `https://opencode.ai/api/v1`; Hermes returned `HTTP 404`. Historical successful billing/session metadata showed the working endpoint as `https://opencode.ai/zen/go/v1`, so both `deepseek-pro` and `opencode-go` provider entries were aligned to that endpoint.

## Backups created on server

- `/opt/data/.env.bak_model_env_fix_20260607_123834`
- `/opt/data/secrets/opencode.env.bak_model_env_fix_20260607_123834`
- `/opt/data/config.yaml.bak_zen_base_url_20260607_124416`
- `/opt/data/cron/jobs.json.bak_zen_base_url_trigger_20260607_124416`

## Validation

Job validated:

- job: `manaloom-hermes-normal-audit`
- id: `660397bb97e1`
- provider: `deepseek-pro`
- model: `deepseek-v4-pro`

Failed proof before endpoint fix:

- `2026-06-07T12:41:15+00:00`
- status: `error`
- error: `RuntimeError: HTTP 404 — Not Found | opencode`

Passing proof after endpoint fix:

- `2026-06-07T12:49:11.907701+00:00`
- status: `ok`
- provider: `deepseek-pro`
- model: `deepseek-v4-pro`
- next run: `2026-06-07T18:49:11.907701+00:00`

The successful run produced findings and confirmed backend/app checks in the cron output. It also exposed an ownership issue in `docs/hermes-analysis`, which was corrected with `hermes:hermes` ownership so future report jobs can write docs.

## Current caution

Older jobs may still show stale `last_error` values until their next scheduled run. Do not treat old `HTTP 404 | opencode` or previous `HTTP 429` fields as current provider state unless `last_run_at` is after `2026-06-07T12:49:11+00:00`.
