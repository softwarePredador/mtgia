# PG822 Sage Gate Land Animation And PG823B Hash Backfill Evidence - 2026-07-12

Status: applied on the new-server PostgreSQL target through
`server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Scope

PG822 promotes the XMage-backed exact adapter for `Sage of the Maze`.

- XMage source class:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SageOfTheMaze.java`
- XMage behavior:
  - `SimpleManaAbility(... AddManaInAnyCombinationEffect(2), TapSourceCost())`
  - `ActivateAsSorceryActivatedAbility(new SageOfTheMazeEffect(), TapSourceCost())`
  - `SageOfTheMazeEffect`: target land you control becomes an `X/X`
    `Citizen` with haste until end of turn, where `X = 2 * Gates you control`
  - `SimpleActivatedAbility(new UntapSourceEffect(), new TapTargetCost(... Gate ...))`
- ManaLoom scope:
  `xmage_simple_tap_mana_source_with_gate_land_animation_untap_v1`
- Activated subscopes:
  - `xmage_activated_land_becomes_creature_gate_count_v1`
  - `xmage_activated_tap_gate_untap_source_v1`

PG823B is a companion integrity package. It backfills `oracle_hash` for old
trusted executable rows so the final PostgreSQL/Hermes/SQLite contract remains
green after the new package.

## Implementation

- Runtime: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Splitter:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- Package builder:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- E2E runner:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- Tests:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`

## SQL Packages

PG822:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_rollback.sql`

PG823B:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

## PostgreSQL Evidence

PG822 precheck:

- Card: `Sage of the Maze`
- Oracle hash: `daad64346959bcce99bbacd2fe8b446b`
- Target card rows: `1`
- Existing exact rule rows before apply: `0`
- Shadow rows to deprecate: `0`

PG822 apply/postcheck:

- Deprecated shadow rows: `0`
- Upserted rows: `1`
- Promoted rule rows: `1`
- Promoted verified/auto rows: `1`
- Promoted oracle-hash rows: `1`

PG823B precheck/apply/postcheck:

- Would backfill rows: `32`
- Distinct cards: `31`
- Safe hash groups: `32`
- Unsafe hash groups: `0`
- Backup table existed before apply: `false`
- Backup rows: `32`
- Updated rows: `32`
- Verified/auto rows missing `oracle_hash` after apply: `0`

## Sync

PG822 battle-rule sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_pg_to_sqlite_sync.json`
- `canonical_snapshot_rows_exported`: `7699`
- `pg_rows_loaded`: `10321`
- `sqlite_inserted_or_updated`: `10099`

PG822 metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8638`
- SQLite cache alias rows: `8577`
- `deck_cards` backfill matched: `2699/2699`
- `card_id_updates`: `108`
- unresolved: `1`

PG823B post-backfill sync:

- Battle-rule report:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `canonical_snapshot_rows_exported`: `7699`
- `pg_rows_loaded`: `10321`
- `sqlite_inserted_or_updated`: `10099`
- Metadata report:
  `docs/hermes-analysis/master_optimizer_reports/pg823b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8638`
- SQLite cache alias rows: `8577`
- `deck_cards` backfill matched: `2699/2699`
- `card_id_updates`: `96`
- unresolved: `1`

## Validation

Focused tests:

- `python3 -m py_compile ...`: `pass`
- `pytest ... -k "sage_of_the_maze or gate_land_animation"`: `4 passed`

E2E after final sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg822_sage_gate_land_animation_new_server_post_pg823b_e2e.md`
- Status: `pass`
- PostgreSQL source of truth: `pass`
- SQLite Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime `get_card_effect`: `pass`
- Battle execution: `pass`
- Scenario: `Sage of the Maze animates a land and untaps via Gate`
- Observed: available mana `2`, animated target `E2E Target Plaza`, animated
  P/T `4/4`, keyword `haste`, tapped Gate count `1`, source untapped after
  Gate cost.

Global readiness:

- Pre-PG822 live report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_current_answer.md`
- Final report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg823b_hash_backfill_new_server.md`
- `battle_and_oracle_ready`: `6612 -> 6644`
- `battle_family_mapper_required`: `27151 -> 27150`
- `battle_rule_verification_required`: `70 -> 70`
- `trusted_rule_oracle_hash_backfill`: `31 -> absent`
- `snapshot_has_verified_rule`: `6750 -> 6751`
- `snapshot_has_any_rule`: `7904 -> 7905`

Queue and split:

- Queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg823b_hash_backfill_new_server_commander_legal.md`
- `target_identity_count`: `24239`
- `xmage_authoritative_source_count`: `23926`
- `xmage_missing_source_exception_count`: `313`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `23926`
- Split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg823b_hash_backfill_new_server_recheck.md`
- `safe_for_batch_pg_package_count`: `0`
- Current explicit nearby partial work unit:
  `ramp_permanent::xmage_artifact_mana_source_variant_review_v1 = 2`

Gates:

- `xmage_strategy_consistency_audit_20260712_post_pg823b_hash_backfill_new_server_final`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260712_post_pg823b_hash_backfill_new_server_final`: `pass`, `48/48`
- `legacy_contamination_audit_20260712_post_pg823b_hash_backfill_new_server_final`: `pass`, `32/32`
- `pg_hermes_sqlite_contract_audit_20260712_post_pg823b_hash_backfill_new_server_final`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`
