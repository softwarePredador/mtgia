# PG519 Counter Gain Life Apply Evidence

Generated on 2026-07-05 for deploy id
`xmage_pg519_counter_gain_life_new_server`.

## Scope

PG519 promotes only local-XMage-backed instant spells with the exact fixed
pattern:

- counter target spell;
- controller gains a fixed amount of life when the counter resolves.

Runtime scope:

- `xmage_counter_target_and_controller_gain_life_spell_v1`

Promoted cards:

- `Absorb`
- `Fall of the Gavel`

## PostgreSQL Apply

Package files:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg519_xmage_pg519_counter_gain_life_new_server_rollback.sql`

Execution:

- Precheck: each promoted card had `target_card_rows=1`; no existing rule row
  or shadow row needed deprecation.
- Apply: `deprecated_shadow_rows=0`, `upserted_rows=2`, `COMMIT`.
- Postcheck: both promoted cards have `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Hermes/SQLite Sync

Sync report:
`docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg519_counter_gain_life_new_server.json`.

- `selected_card_count=2`.
- `pg_rows_loaded=2`.
- `sqlite_inserted_or_updated=2`.
- `canonical_snapshot_rows_exported=6036`.

The canonical snapshot file was refreshed at
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`.

## Validation

- Focused unit suite:
  `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py`
  reports `845` tests passing.
- Focused runtime smoke without override resolved `Absorb` through
  `get_card_effect`, countered `Target Finisher`, moved `Absorb` to graveyard,
  and raised the responder life total from `12` to `15` with
  `life_gain_on_counter=3`.
- Battle package end-to-end validation:
  `docs/hermes-analysis/master_optimizer_reports/battle_package_end_to_end_validation_20260705_pg519_counter_gain_life_new_server.md`
  reports `pass` for PostgreSQL, SQLite, canonical snapshot, and runtime lookup.
- XMage strategy consistency: `26/26` pass.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `51/51` pass.

## Queue And Readiness

Pre-PG519 authoritative queue:

- `target_identity_count=25980`.
- `xmage_authoritative_source_count=25666`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25666`.
- Candidate exact split: `proposal_count=2`,
  `safe_for_batch_pg_package_count=2`.

Post-sync authoritative queue:

- `target_identity_count=25978`.
- `xmage_authoritative_source_count=25664`.
- `xmage_missing_source_exception_count=314`.
- `xmage_authoritative_parser_gap_count=0`.
- `xmage_authoritative_adapter_required_count=25664`.
- Final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`.

Global readiness after this sync:

- `battle_and_oracle_ready=4972`.
- `battle_family_mapper_required=28901`.
- `snapshot_has_any_rule=6039`.
- `snapshot_has_verified_rule=4794`.

## Decision

PG519 is applied, synced, and validated. Do not rebuild it from the pre-PG519
candidate queue. The next global card-adaptation wave must start from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg519_counter_gain_life_new_server_commander_legal.md`.
