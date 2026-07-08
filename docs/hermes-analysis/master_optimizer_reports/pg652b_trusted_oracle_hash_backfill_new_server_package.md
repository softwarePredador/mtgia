# PG652b Trusted Rule Oracle Hash Backfill

Status: `prepared_for_apply`.

Purpose: backfill `oracle_hash` for trusted executable `card_battle_rules` rows
that already have a safe `card_id -> cards.oracle_text` source.

This package does not change `effect_json`, `deck_role_json`, review status, or
execution status. It only fills missing `oracle_hash` and records the backfill
note.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg652b_trusted_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg652b_trusted_oracle_hash_backfill_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg652b_trusted_oracle_hash_backfill_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg652b_trusted_oracle_hash_backfill_new_server_rollback.sql`
