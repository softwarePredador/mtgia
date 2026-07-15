# New Server PostgreSQL Workflow - 2026-07-06

Status: `current_operational_target`.

The active ManaLoom server is the new EasyPanel environment from `server/.env`.
Local PostgreSQL work must use `server/bin/with_new_server_pg.sh`, not the old
`.credentials.env` target.

## Target

- EasyPanel app: `evolution-cartinhas.2ta7qx.easypanel.host`
- Server IP: `137.184.5.11`
- Internal PostgreSQL service: `evolution_manaloom-postgres:5432/halder`
- Local developer tunnel: `127.0.0.1:15432/halder`

Do not print or commit `DATABASE_URL`, DB passwords, EasyPanel tokens, SSH keys,
or auth headers.

## Commands

Health check:

```bash
curl -fsS https://evolution-cartinhas.2ta7qx.easypanel.host/health
```

Open or reuse the SSH tunnel and verify the database:

```bash
server/bin/with_new_server_pg.sh
```

Run a SQL command against the new PostgreSQL target:

```bash
server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 -At -c 'select count(*) from cards;'
```

Run Python/Hermes scripts against the new PostgreSQL target:

```bash
server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/<script>.py ...
```

Run XMage package apply/sync commands by prefixing the existing command with the
wrapper:

```bash
server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_apply_evidence.py ...
server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py ...
```

Run Dart database commands the same way. Dart scripts that load `.env` must let
the wrapper-exported `Platform.environment` values win over local `.env` values,
otherwise local runs may try to resolve the internal Docker host
`evolution_manaloom-postgres`.

```bash
server/bin/with_new_server_pg.sh bash -c 'cd server && dart run bin/migrate.dart --status'
```

## Validated State

Validated on 2026-07-06 from this checkout:

- Public health endpoint returned `healthy` for `mtgia-server` at git SHA
  `43d1d9c94203c74cd37ec786406934342478db47`.
- `server/bin/with_new_server_pg.sh psql ... 'select current_database(), count(*) from cards;'`
  returned `halder|34331`.
- Python/Hermes scripts resolve the same target when run through the wrapper:
  `127.0.0.1:15432/halder`.
- A read-only XMage authoritative queue smoke test completed against this
  target with `25395` target identities, `25081` local XMage-authoritative
  sources, `314` missing-source exceptions, and `0` parser gaps.
- `dart run bin/migrate.dart --status` through the wrapper returned `29`
  executed migrations and `0` pending migrations.

## Artifact Retention

`docs/hermes-analysis/master_optimizer_reports/` is historical/audit evidence,
not runtime input. New generated `.md`/`.json` reports in that folder are
ignored by `.gitignore`; recurring wrappers should write diagnostics to `/tmp`
unless a package explicitly needs retained evidence.

After the 2026-07-06 retention cleanup:

- `docs/hermes-analysis/master_optimizer_reports/`: about `122 MB` on disk.
- Unreferenced tracked raw reports were removed.
- Remaining report files are primarily markdown summaries plus referenced raw
  artifacts needed by current scripts/tests/contracts.

Cleanup should be a separate evidence-retention commit: keep living contracts,
deploy registers, latest/current summaries, and applied package evidence; remove
or external-archive stale per-run reports that are no longer referenced by a
living contract. Do not mix that cleanup with card-rule package commits.

Use `/tmp` for one-off audit outputs when the result is only a local diagnostic:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py \
  --out-prefix /tmp/legacy_contamination_audit_current
```

## Guardrails

- `server/.env` is the local source for new server credentials.
- `.credentials.env` must not exist as an operational entrypoint; if a local
  ignored copy appears, delete it instead of using it.
- The wrapper exports `DATABASE_URL`, `PGHOST`, `PGPORT`, `PGDATABASE`,
  `PGUSER`, and `PGPASSWORD` only inside the child process.
- PostgreSQL remains the product source of truth; Hermes SQLite remains cache
  and audit/runtime evidence.

## Battle Strategy Audit

The official battle-strategy evidence producer runs in the versioned
`evolution_manaloom-ops` service. It must not depend on local LaunchAgents or
paths under a developer home directory.

- Runner: `server/bin/manaloom_battle_strategy_audit.sh`.
- Scheduler: `server/bin/manaloom_ops_daemon.py`.
- Persistent artifact root:
  `/data/manaloom-ops/artifacts/battle-strategy-audit`.
- Consumer contract:
  `/data/manaloom-ops/artifacts/battle-strategy-audit/latest/summary.json`.
- Recurring audit: `16` seeds, outside the nightly validation window.
- Nightly audit: `64` seeds at `06:05 UTC`.
- Both jobs run in background and share the runner lock, so a long replay does
  not block PostgreSQL/Hermes synchronization jobs or start a duplicate audit.

The optimizer must remain fail-closed when the summary is missing,
`review_required`, or contains mandatory divergences. Never copy a local or
historical `summary.json` into the persistent volume to open the gate. Deploy
the versioned runner, execute it in the live `manaloom-ops` container, and use
the newly generated summary as evidence.

### Runtime ownership and audit

`evolution_manaloom-ops` is intentionally managed as a direct Docker Swarm
service on the active host. It is not an EasyPanel API app record.

- Deploy/update: `./scripts/manaloom_deploy_ops_image.sh`.
- Read-only runtime and cron audit:
  `python3 server/bin/audit_easypanel_cron_runtime.py --artifact-dir /tmp/manaloom-cron-audit`.
- Runtime/PG alignment:
  `server/bin/with_new_server_pg.sh python3 server/bin/audit_easypanel_runtime_alignment.py --stdout-only`.
- Optional provider lab: `hermes-lab` is report/research-only and is not a
  dependency of the product, battle runtime, PostgreSQL sync, or old-server
  shutdown. Pass `--require-hermes-lab` to the cron audit only when explicitly
  validating that optional service.
- `server/bin/reconcile_easypanel_services.py` is limited to explicitly named,
  optional EasyPanel app services. It must never be used for `manaloom-ops`.

The cron audit first checks the EasyPanel API and then uses the SSH target from
`server/.env` for direct Swarm services. It records an absent optional
`hermes-lab` as `not_configured`; it does not invent a product blocker.

## Historical-only Quarantine

These old targets are historical-only quarantine markers. They may appear in
audit evidence explaining past migration work, but must not appear as active
runtime defaults, agent instructions, tests, runbooks, deploy commands, or local
PostgreSQL entrypoints:

- `evolution-cartinhas.8ktevp.easypanel.host`
- `143.198.230.247`
- PostgreSQL port `5433`
- `.credentials.env`

Run this guard before handing work to another agent or before changing
deployment/database defaults:

```bash
./scripts/quality_gate.sh server-target
```
