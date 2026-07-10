# PG719 Target Keyword Aliases Evidence - 2026-07-10

Status: `applied_synced_validated`

Current PostgreSQL target: `server/bin/with_new_server_pg.sh`

## Scope

PG719 promoted exact XMage-derived keyword alias support for four cards:

- `Breach`
- `Hooded Kavu`
- `Shriek of Dread`
- `Withstand Death`

Runtime/parser changes:

- Added `fear` and `intimidate` to target keyword Oracle mapping.
- Accepted `Target creature is indestructible this turn` as an indestructible-until-EOT grant.
- Stripped parenthetical reminder text before simple keyword complexity checks.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg719_target_keyword_aliases_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719_target_keyword_aliases_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719_target_keyword_aliases_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719_target_keyword_aliases_new_server_package_rollback.sql`

Candidate report:

- `proposal_count=4`
- `safe_for_batch_pg_package_count=4`
- `proposal_status_counts.batch_pg_candidate_after_precheck=4`

Post-apply validation:

- `Breach`: `battle_rule_v1:1a80a59bfe60d19ce999c58d8ac0625d`
- `Hooded Kavu`: `battle_rule_v1:5f8dd5e86f63f36f1155e92d6949b87b`
- `Shriek of Dread`: `battle_rule_v1:8d46159e8ae2f9b5ee8b04b9f0b2db80`
- `Withstand Death`: `battle_rule_v1:64b2eb6d72830a72e6188d12589b5e97`
- All four rows are `review_status=verified`, `execution_status=auto`, with non-empty `oracle_hash`.

## PG719B Hash Backfill

The first PG/Hermes contract audit after PG719 found an unrelated legacy integrity issue:

- `trusted_executable_rules_missing_oracle_hash=55`

PG719B backfilled only trusted executable rules where current `cards.oracle_text` produced exactly one safe hash:

- Precheck: `trusted_auto_missing_hash_rows=55`, `safe_backfillable_rows=55`, `unsafe_distinct_hash_rows=0`, `unmatched_missing_hash_rows=0`
- Apply: `oracle_hash_rows_backfilled=55`
- Postcheck: `backfilled_rows=55`, `rows_with_oracle_hash=55`, `rows_matching_current_oracle_hash=55`, `remaining_trusted_auto_missing_hash_rows=0`

PG719B files:

- `docs/hermes-analysis/master_optimizer_reports/pg719b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg719b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync

PG719 sync:

- `pg_rows_loaded=6241`
- `sqlite_inserted_or_updated=6236`
- `canonical_snapshot_rows_exported=6192`
- metadata sync matched `deck_cards=2699/2699`

PG719B sync:

- `pg_rows_loaded=6241`
- `sqlite_inserted_or_updated=6236`
- `canonical_snapshot_rows_exported=6192`
- metadata sync matched `deck_cards=2699/2699`

## E2E

`docs/hermes-analysis/master_optimizer_reports/pg719_target_keyword_aliases_new_server_e2e_validation.md`

- Status: `pass`
- PostgreSQL source rows validated: `4`
- SQLite cache rows validated: `4`
- Canonical snapshot cards validated: `4`
- Runtime `get_card_effect` cards validated: `4`
- Battle execution scenarios: `4`

Behavior validated:

- `Breach` grants `fear` and applies the expected temporary boost.
- `Hooded Kavu` activates its self keyword ability and gains `fear`.
- `Shriek of Dread` grants `fear`.
- `Withstand Death` grants `indestructible`.

## Final Audits

Post-PG719B reports:

- PG/Hermes/SQLite contract: `pass`, `51/51`
- XMage strategy consistency: `pass`, `26/26`
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- Server target quality gate: `pass`

Tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `946` tests passed
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`: `240` tests passed

## Remaining Global Queue

Post-PG719B readiness:

- `battle_and_oracle_ready=6290`
- `snapshot_has_verified_rule=6315`
- `battle_family_mapper_required=27586`

Post-PG719B authoritative queue:

- `target_identity_count=24663`
- `xmage_authoritative_adapter_required_count=24350`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7098`

Conclusion: PG719/PG719B is closed. The global goal remains active because the remaining work is new family/runtime implementation, not residual PG719 data integrity.
