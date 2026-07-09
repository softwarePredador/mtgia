# PG692 Damage Each Opponent And Their Permanents Evidence - 2026-07-09

Status: `applied_validated_new_server`.

PG692 closed the exact XMage spell subpattern where a spell resolves two fixed
effects in order: `DamagePlayersEffect(..., TargetController.OPPONENT)` and a
matching `DamageAllEffect` over permanents those opponents control. The parser
accepts only the exact Oracle/XMage shapes for opponent creatures, or opponent
creatures plus planeswalkers; modal, conditional, sacrifice, discard, mill, d20,
and variable-X neighbors remain blocked.

Promoted cards:

- `End the Festivities`
- `Tectonic Hazard`

Runtime/test changes:

- `xmage_authoritative_exact_scope_split.py` emits a
  `composite_resolution` rule with `damage_each_opponent` and `damage_wipe`
  components for the exact safe source/Oracle match.
- `battle_analyst_v9.py` can resolve `damage_each_opponent` and `damage_wipe`
  as same-spell composite components without finishing the source card twice.
- `xmage_batch_pg_package_builder.py` creates focused E2E scenarios for the
  composite pattern.
- `battle_package_end_to_end_validation.py` verifies opponent life loss,
  opponent creature destruction, optional planeswalker destruction, and
  `composite_rule_resolved` with two applied components.

Package evidence:

- Split candidate:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_pg692_damage_each_opponent_permanents_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_package_manifest.json`
- PostgreSQL precheck/apply/postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_package_postcheck.sql`
- PG -> SQLite/snapshot sync:
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_pg_to_sqlite_sync_runtime_only.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg692_damage_each_opponent_permanents_new_server_e2e_validation.md`

Validation results:

- Precheck: `2/2` target card rows matched by Oracle hash; `4` existing shadow
  rows would be deprecated.
- Apply: `upserted_rows=2`; `deprecated_shadow_rows=4`.
- Postcheck: `2/2` promoted rows are `verified`, `auto`, and carry
  `oracle_hash`.
- Sync: PostgreSQL loaded `6119` rows, SQLite updated `6104`, canonical snapshot
  exported `6081`.
- E2E: `status=pass`, `2` battle execution scenarios, `18` events. `End the
  Festivities` validated opponent creatures and planeswalkers; `Tectonic
  Hazard` validated opponent creatures only.
- Tests:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  passed with `1086 passed, 206 subtests passed`.

Final post-PG692 state:

- Global readiness:
  `battle_and_oracle_ready=6179`, `battle_family_mapper_required=27697`,
  `snapshot_has_verified_rule=6207`, `snapshot_has_any_rule=7395`.
- Authoritative queue:
  `target_identity_count=24774`,
  `xmage_authoritative_source_count=24461`,
  `xmage_missing_source_exception_count=313`,
  `xmage_authoritative_parser_gap_count=0`,
  `xmage_authoritative_adapter_required_count=24461`,
  `adapter_work_unit_count=11305`.
- Exact split recheck:
  `proposal_count=0`, `safe_for_batch_pg_package_count=0`.
- Final gates:
  `server-target` quality gate passed,
  `xmage_strategy_consistency_audit` passed `26/26`,
  `pg_hermes_sqlite_contract_audit` passed `51/51`,
  `operational_surface_alignment_audit` passed,
  `legacy_contamination_audit` passed.
