# PG653 Trusted Oracle Hash Repair

Status: `applied_postchecked_synced_validated`.

Purpose: repair live trusted executable `card_battle_rules` rows whose
`oracle_hash` was still blank after the post-PG652b readiness recheck. The
repair is metadata-only: it does not change `effect_json`, `deck_role_json`,
review status, execution status, or runtime behavior.

Scope:

- trusted/reviewed executable rows only;
- requires a safe `card_id -> cards.oracle_text` source;
- writes `oracle_hash = md5(cards.oracle_text)`;
- stores the original rows in `manaloom_deploy_audit.pg653_trusted_oracle_hash_repair_20260708`
  for rollback.

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg653_trusted_oracle_hash_repair_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg653_trusted_oracle_hash_repair_new_server_apply.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg653_trusted_oracle_hash_repair_new_server_postcheck.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg653_trusted_oracle_hash_repair_new_server_rollback.sql`

Applied result:

- precheck: `backfillable_rule_rows=44`, `affected_card_ids=43`,
  `affected_normalized_names=44`, `unsafe_missing_hash_rows=0`;
- apply: `oracle_hash_rows_repaired=44`;
- postcheck: `remaining_trusted_executable_missing_hash_rows=0`,
  `repaired_rows_with_expected_hash=44`;
- sync: `pg_rows_loaded=5922`, `sqlite_inserted_or_updated=5908`,
  `canonical_snapshot_rows_exported=5885`.
