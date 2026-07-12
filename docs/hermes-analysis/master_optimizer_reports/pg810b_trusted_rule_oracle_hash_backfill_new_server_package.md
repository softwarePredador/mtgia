# PG810B Trusted Rule Oracle Hash Backfill

Status: `prepared_read_only_pending_apply_approval`.

This package backfills missing `card_battle_rules.oracle_hash` for trusted executable rules from the current PostgreSQL `cards.oracle_text` md5. It does not create new battle semantics.

- Generated at: `2026-07-12T06:29:00+00:00`
- Target: verified/active curated/manual rows with auto/executable status, non-empty Oracle text, and missing `oracle_hash`
- Expected precheck rows before apply: `55`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg810b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg810b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg810b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg810b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
