# PG515 Removal Compensation Tokens Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg515_removal_compensation_tokens_new_server`.

## Scope

PG515 promotes only local-XMage-backed targeted destroy/exile spells where the
same target's controller creates a fixed simple creature token:

- `Afterlife`
- `Angelic Ascension`
- `Beast Within`
- `Bovine Intervention`
- `Harsh Annotation`
- `Reduce to Memory`
- `Secure the Scene`

Unsupported neighbors remain blocked, including non-creature compensation
tokens, changeling tokens, unsupported auxiliary abilities, imprecise oracle
phrasing, and target classes that the current mapper does not model safely.

## Source And Runtime Mapping

XMage source pattern:

- primary removal effect: `DestroyTargetEffect` or `ExileTargetEffect`
- compensation effect: `CreateTokenControllerTargetEffect`
- token class parsed through the existing simple creature-token parser

Runtime scopes:

- `xmage_destroy_target_with_controller_creature_token_compensation_spell_v1`
- `xmage_exile_target_with_controller_creature_token_compensation_spell_v1`

Runtime evidence:
`docs/hermes-analysis/master_optimizer_reports/xmage_pg515_removal_compensation_tokens_new_server_runtime_get_card_effect.out`.

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_rollback.sql`

Execution:

- Precheck: each promoted card had `target_card_rows=1`; `Beast Within` had
  two nonmatching existing rows scheduled for shadow deprecation.
- Apply: `deprecated_shadow_rows=2`, `upserted_rows=7`, `COMMIT`.
- Postcheck: all seven promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg515_removal_compensation_tokens_new_server.json`.

- `selected_card_count=7`.
- `pg_rows_loaded=7`.
- `sqlite_inserted_or_updated=9`.
- `canonical_snapshot_rows_exported=6024`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- New focused parser/runtime tests cover Beast Within and Angelic Ascension
  style mappings.
- Combined exact-scope/runtime suite:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`
  reports `829` tests passing in
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg515_removal_compensation_tokens_new_server_unittest.out`.
- Compile check passed for the changed mapper/runtime/package/sync scripts.
- Battle package end-to-end validation:
  `docs/hermes-analysis/master_optimizer_reports/battle_package_end_to_end_validation_20260705_pg515_removal_compensation_tokens_new_server.md`
  reports `pass` for PostgreSQL, SQLite, canonical snapshot, runtime lookup,
  and no-override battle execution.
- Runtime smoke without rule override removed a creature with `Angelic
  Ascension` and created a `4/4` white `Angel Token` with `flying`.
- XMage strategy consistency: `26/26` pass.
- Operational surface alignment: `39/39` pass.
- Legacy contamination: `32/32` pass.
- PG/Hermes/SQLite contract: `51/51` pass.

## Queue And Readiness

Pre-PG515 authoritative queue:

- `target_identity_count=25999`.
- `xmage_authoritative_source_count=25685`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25685`.
- Candidate exact split: `proposal_count=7`,
  `safe_for_batch_pg_package_count=7`.

Post-sync authoritative queue:

- `target_identity_count=25992`.
- `xmage_authoritative_source_count=25678`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25678`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4958`.
- `battle_family_mapper_required=28915`.
- `snapshot_has_any_rule=6027`.
- `snapshot_has_verified_rule=4780`.

## Decision

PG515 is applied, synced, and validated. Do not rebuild it from the pre-PG515
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg515_removal_compensation_tokens_new_server.md`.
