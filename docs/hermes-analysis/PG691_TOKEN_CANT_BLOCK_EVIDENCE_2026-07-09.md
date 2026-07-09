# PG691 Token Cant-Block Evidence - 2026-07-09

Status: `applied_validated_new_server`.

PG691 closed the safe XMage token subpattern where a created creature token has
only a static `CantBlockSourceEffect(Duration.WhileOnBattlefield)` restriction.
The parser still blocks token classes that combine cant-block with unsupported
token abilities, triggered text, toxic/infect/banding, or other static effects.

Promoted cards:

- `Edgewall Pack`
- `Harried Spearguard`
- `Synapse Necromage`

Runtime/test changes:

- `xmage_authoritative_exact_scope_split.py` now emits structured
  `token_cant_block`, `etb_token_cant_block`, or `dies_token_cant_block`
  only for the safe XMage static restriction.
- `battle_analyst_v9.py` creates tokens with `cant_block=True` and maps ETB/dies
  token fields into the shared token creator.
- `xmage_batch_pg_package_builder.py` preserves the field in package execution
  scenarios.
- `battle_package_end_to_end_validation.py` verifies that expected tokens are
  seen by `creature_cannot_block`.

Package evidence:

- Split candidate:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_pg691_token_cant_block_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_package_manifest.json`
- PostgreSQL precheck/apply/postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_package_postcheck.sql`
- PG -> SQLite/snapshot sync:
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_pg_to_sqlite_sync_runtime_only.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg691_token_cant_block_new_server_e2e_validation.md`

Validation results:

- Precheck: `3/3` target card rows matched by Oracle hash; `0` shadow rows.
- Apply: `upserted_rows=3`; `deprecated_shadow_rows=0`.
- Postcheck: `3/3` promoted rows are `verified`, `auto`, and carry
  `oracle_hash`.
- Sync: PostgreSQL loaded `6117` rows, SQLite updated `6102`, canonical snapshot
  exported `6079`.
- E2E: `status=pass`, `3` battle execution scenarios, `5` events. All promoted
  tokens validated with `token_cant_block=true`.
- Tests:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  passed with `1082 passed, 206 subtests passed`.

Final post-PG691 state:

- Global readiness:
  `battle_and_oracle_ready=6177`, `battle_family_mapper_required=27699`,
  `snapshot_has_verified_rule=6205`, `snapshot_has_any_rule=7395`.
- Authoritative queue:
  `target_identity_count=24776`,
  `xmage_authoritative_source_count=24463`,
  `xmage_missing_source_exception_count=313`,
  `xmage_authoritative_parser_gap_count=0`,
  `xmage_authoritative_adapter_required_count=24463`,
  `adapter_work_unit_count=11305`.
- Exact split recheck:
  `proposal_count=0`, `safe_for_batch_pg_package_count=0`.
- Final gates:
  `server-target` quality gate passed,
  `xmage_strategy_consistency_audit` passed `26/26`,
  `pg_hermes_sqlite_contract_audit` passed `51/51`,
  `operational_surface_alignment_audit` passed,
  `legacy_contamination_audit` passed.
