# PG715 Pain Talisman Evidence - 2026-07-10

Status: `applied_to_new_server_and_validated`

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG715 promotes the exact XMage -> ManaLoom adapter for pain Talisman mana rocks:

- `Talisman of Hierarchy`
- `Talisman of Unity`

The accepted pattern is:

- XMage source has one `ColorlessManaAbility`.
- XMage source has two fixed colored mana abilities.
- Each colored mana ability carries `DamageControllerEffect(1)`.
- Oracle text is exactly the two-line colorless plus color-pair pain mana form.
- ManaLoom runtime scope is `pain_talisman_color_pair_partial_v1`.

## Runtime Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added `PAIN_TALISMAN_UNIT` and `PAIN_TALISMAN_SCOPE`.
  - Added exact Oracle/source parsers for color-pair pain mana.
  - Emits `life_for_colored_mana=1` only after XMage/source agreement.
- `xmage_batch_pg_package_builder.py`
  - Preserves `life_for_colored_mana` in E2E required fields.
  - Builds `expected_conditional_life_loss_by_color` for conditional mana modes.
- `battle_package_end_to_end_validation.py`
  - Validates `conditional_mana_sources[*].modes[*].life_loss_on_spend`.

## Package Evidence

Artifacts generated under `docs/hermes-analysis/master_optimizer_reports/`:

- `xmage_authoritative_exact_scope_split_20260710_pg715_pain_talisman_new_server_candidate.*`
- `pg715_pain_talisman_new_server_package_*`
- `pg715_pain_talisman_new_server_e2e_validation.*`
- `global_card_oracle_battle_readiness_20260710_post_pg715_pain_talisman_new_server.*`
- `xmage_authoritative_adaptation_queue_20260710_post_pg715_pain_talisman_new_server_commander_legal.*`
- `xmage_authoritative_exact_scope_split_20260710_post_pg715_pain_talisman_new_server_recheck.*`

Precheck:

- `target_card_rows=1` for each selected card.
- `expected_rule_rows_before=0` for each selected card.
- `would_deprecate_shadow_rows=2` for each selected card.

Apply:

- `deprecated_shadow_rows=4`
- `upserted_rows=2`

Postcheck:

- `promoted_rule_rows=1` for each selected card.
- `promoted_verified_auto_rows=1` for each selected card.
- `promoted_oracle_hash_rows=1` for each selected card.
- `backup_rows=4`

## Sync Evidence

`sync_battle_card_rules_pg.py`:

- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=6233`
- `sqlite_inserted_or_updated=6228`
- `canonical_snapshot_rows_exported=6184`
- canonical snapshot path:
  `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

`sync_pg_card_metadata_to_hermes.py`:

- `requested unique names=7143`
- `postgres cards matched=7326`
- `sqlite cache alias rows=7245`
- `deck_cards backfill matched=2699/2699`

## E2E Evidence

`battle_package_end_to_end_validation.py` with the tracked canonical snapshot
passed:

- `status=pass`
- `scenario_count=2`
- PostgreSQL source of truth validated: `2`
- SQLite Hermes cache validated: `2`
- Canonical snapshot fallback validated: `2`
- Runtime `get_card_effect` validated: `2`
- Battle execution validated: `2`

Runtime execution proved:

- `Talisman of Hierarchy`
  - `available_mana=1`
  - `conditional_mana=1`
  - `conditional_life_loss_by_color={"colorless": 0, "white": 1, "black": 1}`
- `Talisman of Unity`
  - `available_mana=1`
  - `conditional_mana=1`
  - `conditional_life_loss_by_color={"colorless": 0, "green": 1, "white": 1}`

## Queue And Readiness Delta

Post PG715 readiness:

- `battle_and_oracle_ready=6282`
- `snapshot_has_verified_rule=6307`
- `battle_family_mapper_required=27594`

Post PG715 XMage authoritative queue:

- `target_identity_count=24671`
- `xmage_authoritative_source_count=24358`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=24358`
- `manual_semantic_decision_units_remaining=313`

Exact splitter recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7106`

## Validation Commands

Passed:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`
  - `Ran 940 tests`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  - `234 passed`
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `pg_hermes_sqlite_contract_audit.py`
  - `status=pass`, `51/51`
- `xmage_strategy_consistency_audit.py`
  - `status=pass`, `26/26`
- `operational_surface_alignment_audit.py`
  - `status=pass`
- `legacy_contamination_audit.py`
  - `status=pass`
- `./scripts/quality_gate.sh server-target`
  - `pass`
