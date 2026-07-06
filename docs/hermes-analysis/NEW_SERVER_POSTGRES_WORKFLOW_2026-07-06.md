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

## Guardrails

- `server/.env` is the local source for new server credentials.
- `.credentials.env` may still contain an old-server target and must not be used
  for current ManaLoom PostgreSQL writes.
- The wrapper exports `DATABASE_URL`, `PGHOST`, `PGPORT`, `PGDATABASE`,
  `PGUSER`, and `PGPASSWORD` only inside the child process.
- PostgreSQL remains the product source of truth; Hermes SQLite remains cache
  and audit/runtime evidence.
