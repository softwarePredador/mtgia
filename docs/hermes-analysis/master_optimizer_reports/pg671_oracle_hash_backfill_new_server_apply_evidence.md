# PG671 Oracle Hash Backfill - New Server Apply Evidence

Date: 2026-07-08

Database target: new EasyPanel PostgreSQL via `server/bin/with_new_server_pg.sh`

Reason: `pg_hermes_sqlite_contract_audit_20260708_post_pg671_tap_target_spell_new_server_final` found `44` trusted executable PostgreSQL battle rules without `oracle_hash`.

Scope:

- `card_battle_rules.source IN ('curated', 'manual')`
- `card_battle_rules.review_status IN ('verified', 'active')`
- `card_battle_rules.execution_status IN ('auto', 'executable')`
- `card_battle_rules.oracle_hash` blank
- resolvable to `cards.oracle_text`

## Precheck

Ad hoc deduplicated resolution:

- resolved rule rows: 44
- resolved names: 44
- blank hashes after resolution: 0

## Apply

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -X -f docs/hermes-analysis/master_optimizer_reports/pg671_oracle_hash_backfill_new_server_apply.sql
```

Result:

- updated rows: 44

## Postcheck

Command:

```bash
./server/bin/with_new_server_pg.sh psql -v ON_ERROR_STOP=1 -X -f docs/hermes-analysis/master_optimizer_reports/pg671_oracle_hash_backfill_new_server_postcheck.sql
```

Result:

- trusted executable rules missing Oracle hash: 0
- recently hashed trusted executable rules: 50

Note: `recently_hashed_trusted_executable_rules=50` includes the 44 backfilled legacy rules plus the 6 PG671 tap-target rows touched in the same work window.
