# PG734 Restricted Spell Mana Evidence - 2026-07-11

## Scope

PG734 adds the exact XMage to ManaLoom adapter for tap mana sources whose mana
can only be spent on supported spell categories.

- Family: `xmage_restricted_spell_category_mana_source`
- Scope: `xmage_simple_tap_restricted_mana_source_permanent_v1`
- Runtime effect: `ramp_permanent`
- Supported restrictions in this wave:
  - `creature_spell`
  - `artifact_spell`
  - `instant_or_sorcery_spell`
  - `noncreature_spell`

Unsupported restriction text remains blocked by the splitter instead of being
promoted as executable PostgreSQL truth.

## Cards Promoted

1. Beastcaller Savant
2. Curious Homunculus // Voracious Reader
3. Herd Heirloom
4. Humble Naturalist
5. Ore-Rich Stalactite // Cosmium Catalyst
6. Pelargir Survivor
7. Vodalian Arcanist

## Implementation

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  adds the restricted mana source parser and routes supported XMage
  `ConditionalAnyColorManaAbility`, `ConditionalColorlessManaAbility`, and
  `ConditionalColoredManaAbility` signatures into the exact scope.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  now preserves configured conditional mana modes during mana activation and
  refresh, preventing restricted colorless mana from entering the free generic
  pool.
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
  requires `conditional_mana_modes` and emits positive/negative spend
  scenarios for this scope.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
  verifies conditional restrictions and checks that restricted mana can pay an
  allowed card but cannot pay a blocked card.

## PostgreSQL Package

Package artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_package_manifest.json`

Apply result:

- Selected cards: 7
- Deprecated shadow rows: 2
- Upserted executable rows: 7
- Promoted rows with `review_status='verified'`: 7
- Promoted rows with `execution_status='auto'`: 7
- Promoted rows with `oracle_hash`: 7

## PG734B Hash Integrity Backfill

The PG/Hermes/SQLite contract audit after PG734 found older trusted executable
PostgreSQL rules without `oracle_hash`; the PG734 rows themselves already had
hashes. PG734B backfilled only the audit-targeted trusted executable rules:

- Predicate: `source IN ('curated', 'manual')`,
  `review_status IN ('verified', 'active')`,
  `execution_status IN ('auto', 'executable')`,
  empty `oracle_hash`, non-empty `cards.oracle_text`.
- Precheck: 55 missing, 55 computable.
- Apply: 55 rows backfilled.
- Postcheck: 0 missing, 55 backup rows, 55 hashes matching `md5(cards.oracle_text)`.
- Backup table:
  `manaloom_deploy_audit.pg734b_trusted_rule_oracle_hash_backfill_new_server_20260711`

PG734B artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg734b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg734b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## Sync And Runtime Validation

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_sync_report.json`
- PostgreSQL cards matched: 7409
- SQLite cache alias rows: 7329
- `deck_cards` matched: 2699/2699
- `card_id_updates`: 87
- Unresolved: 1

Battle rule sync after PG734B:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_after_hash_backfill_battle_rule_sync_report.json`
- Database target: `127.0.0.1:15432/halder`
- PostgreSQL rows loaded: 6323
- SQLite rows inserted or updated: 6318
- Canonical snapshot rows exported: 6274

End-to-end validation:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg734_restricted_spell_mana_new_server_after_hash_backfill_e2e.json`
- Status: `pass`
- PostgreSQL source-of-truth rows: 7
- SQLite cache rows: 7
- Canonical snapshot cards: 7
- Runtime `get_card_effect` cards: 7
- Battle execution scenarios/events: 7/7

## Tests And Gates

Focused tests:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k restricted`
  from `docs/hermes-analysis/manaloom-knowledge/scripts`: 14 tests passed.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k restricted_mana_source`: passed.
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k restricted_mana_source`: 1 passed.
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k restricted_spell_mana`: 1 passed.

Operational gates:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server`: `pass`, 51/51.
- `xmage_strategy_consistency_audit_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server`: `pass`, 26/26.
- `operational_surface_alignment_audit_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server`: `pass`.
- `legacy_contamination_audit_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server`: `pass`.
- `./scripts/quality_gate.sh server-target`: `pass`.
- `git diff --check`: pass.

## Global Queue After PG734B

Readiness report:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server.json`
- `battle_and_oracle_ready`: 6372
- `battle_family_mapper_required`: 27504
- `generic_runtime_or_no_card_rule`: 359
- `commander_illegal_block`: 2997
- `digital_non_commander_rule_exception`: 3
- `official_oracle_identity_unavailable`: 3

XMage authoritative queue:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg734b_restricted_spell_mana_hash_backfill_new_server_commander_legal.json`
- `target_identity_count`: 24581
- `xmage_authoritative_source_count`: 24268
- `xmage_authoritative_adapter_required_count`: 24268
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313
- `adapter_work_unit_count`: 11295

Net PG734 movement:

- `battle_and_oracle_ready`: 6365 -> 6372
- Commander-legal XMage adapter queue: 24275 -> 24268
