# PG671 Tap Target Spell - New Server PostgreSQL Apply Evidence

Date: 2026-07-08

Database target: new EasyPanel PostgreSQL via `server/bin/with_new_server_pg.sh`

Package:

- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_manifest.json`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_apply.sql`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_precheck.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_postcheck.sql`

Promoted scope: `xmage_tap_target_spell_v1`

Promoted cards:

- Downpour
- Early Frost
- Gridlock
- Lead Astray
- Terashi's Cry
- Word of Binding

## Precheck

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -X -f docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_precheck.sql
```

Result:

- target card rows: 6/6
- expected rule rows before apply: 0/6
- active shadow rows to deprecate: 0

## Apply

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -X -f docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_apply.sql
```

Result:

- transaction committed
- upserted rows: 6
- deprecated shadow rows: 0

## Postcheck

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -X -f docs/hermes-analysis/master_optimizer_reports/pg671_tap_target_spell_new_server_package_postcheck.sql
```

Result:

- promoted rule rows: 6/6
- promoted verified/auto rows: 6/6
- promoted Oracle hash rows: 6/6
- backup rows: 0
