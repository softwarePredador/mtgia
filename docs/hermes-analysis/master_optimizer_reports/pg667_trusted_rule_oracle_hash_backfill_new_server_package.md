# PG667 Trusted Rule Oracle Hash Backfill

- Deploy id: `PG667`
- Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`
- Scope: trusted executable `card_battle_rules` rows where `review_status in ('verified', 'active')`, `execution_status = 'auto'`, and `oracle_hash` is missing.
- Method: metadata-only backfill from `md5(coalesce(cards.oracle_text, ''))` through `card_battle_rules.card_id = cards.id`.
- Purpose: restore PG/Hermes/SQLite contract hash coverage after PG666 before continuing the global XMage adapter queue.

Files:

- Precheck: `pg667_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply: `pg667_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck: `pg667_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback: `pg667_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
