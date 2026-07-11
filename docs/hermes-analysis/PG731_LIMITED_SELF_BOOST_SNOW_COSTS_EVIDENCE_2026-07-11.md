# PG731 Limited Self-Boost And Snow Activation Costs Evidence - 2026-07-11

Status: `applied_and_validated`

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Scope

PG731 promoted 13 XMage-authoritative cards that were blocked by one of these
already-runtime-backed exact patterns:

- numeric `LimitedTimesPerTurnActivatedAbility` self-boost limits above 1;
- snow mana `{S}` activation costs in already supported activated families;
- trailing Oracle reminder text after Phyrexian or snow cost text.

Promoted cards:

- Boreal Centaur
- Chilling Shade
- Frostwalla
- Hailstorm Valkyrie
- Icebind Pillar
- Immolating Souleater
- Ohran Yeti
- Phyrexian Battleflies
- Pit Imp
- Rimebound Dead
- Roterothopter
- Sewer Rats
- Vampire Bats

Families promoted:

- `xmage_permanent_simple_activated_self_boost_until_eot`: 10
- `xmage_permanent_simple_activated_tap_target`: 1
- `xmage_permanent_simple_activated_target_keyword_until_eot`: 1
- `xmage_permanent_simple_activated_regenerate_source`: 1

## Implementation

Updated:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  - Parses `{S}` as a one-mana activation cost while preserving
    `activation_cost_mana="{S}"`.
  - Strips parenthetical Oracle reminders before exact self-boost parsing.
  - Accepts fixed positive per-turn activation limits from Oracle text such as
    `Activate no more than twice each turn` and
    `Activate no more than three times each turn`.
  - Accepts fixed positive integer limits from XMage
    `LimitedTimesPerTurnActivatedAbility`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
  - Adds generic manifest mana for `{S}` activation scenarios.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
  - Validates per-turn limits greater than 1 by allowing activations up to the
    limit and blocking the next activation.

## PostgreSQL Package

Generated package:

- Package markdown:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_manifest.json`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_precheck.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_apply.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_postcheck.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_package_rollback.sql`

Precheck:

- `13/13` target card rows found.
- `0` existing expected rule rows.
- `0` shadow rows to deprecate.

Apply:

- `upserted_rows=13`
- `deprecated_shadow_rows=0`

Postcheck:

- `13/13` promoted rows.
- `13/13` `verified` + `auto` rows.
- `13/13` rows with `oracle_hash`.

## Sync And E2E

PG -> SQLite sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_pg_to_sqlite_sync.json`
- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=9947`
- `sqlite_inserted_or_updated=9725`
- `canonical_snapshot_rows_exported=7347`

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_metadata_sync.json`
- `postgres_cards_matched=8294`
- `sqlite_cache_alias_rows=8231`
- `deck_cards` remained matched at `2699/2699`

Battle package E2E:

- JSON:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_e2e_validation.json`
- Markdown:
  `docs/hermes-analysis/master_optimizer_reports/pg731_limited_self_boost_snow_costs_new_server_e2e_validation.md`
- Status: `pass`
- Validated `13` scenarios with `38` runtime events.
- Passed PostgreSQL source-of-truth, SQLite cache, canonical snapshot,
  runtime lookup, and battle execution stages.

## Queue Impact

Global readiness after PG731:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_004858_post_pg731_limited_self_boost_snow_costs_new_server.md`
- `battle_and_oracle_ready=6352`
- `battle_family_mapper_required=27524`
- `snapshot_has_verified_rule=6377`
- `snapshot_has_any_rule=7553`

XMage authoritative queue after PG731:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_004925_post_pg731_limited_self_boost_snow_costs_new_server.md`
- `target_identity_count=24601`
- `xmage_authoritative_source_count=24288`
- `xmage_authoritative_adapter_required_count=24288`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Final exact-scope recheck:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_005006_post_pg731_limited_self_boost_snow_costs_new_server_recheck.md`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

## Validation

Compilation:

- `python3 -m py_compile` passed for:
  - `xmage_authoritative_exact_scope_split.py`
  - `xmage_batch_pg_package_builder.py`
  - `battle_package_end_to_end_validation.py`
  - `battle_analyst_v9.py`

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py -k "snow or limited_activated_self_boost or activated_self_boost"`:
  `15 passed`
- `test_xmage_batch_pg_package_builder.py -k "simple_activated_self_boost or activated_tap_target or activated_target_keyword or regenerate_source"`:
  `10 passed`
- `test_battle_package_end_to_end_validation.py -k "simple_activated_self_boost or activated_tap_target or activated_target_keyword or regenerate_source"`:
  `7 passed`

Full touched-script tests:

- `test_xmage_authoritative_exact_scope_split.py`: `969 passed`
- `test_xmage_batch_pg_package_builder.py`: `171 passed`
- `test_battle_package_end_to_end_validation.py`: `92 passed`
- `test_xmage_exact_scope_runtime.py -k "simple_activated_self_boost or activated_target_keyword or activated_tap_target or regenerate_source"`:
  `16 passed`

Audits:

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260711_005031_post_pg731_limited_self_boost_snow_costs_new_server.md`
  - `pass`, `26/26`
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260711_005031_post_pg731_limited_self_boost_snow_costs_new_server.md`
  - `pass`, `48/48`
- PG/Hermes/SQLite contract with new-server wrapper:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260711_005048_post_pg731_limited_self_boost_snow_costs_new_server_new_pg.md`
  - `pass`, `51/51`
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260711_005031_post_pg731_limited_self_boost_snow_costs_new_server.md`
  - `pass`, `32/32`
- `./scripts/quality_gate.sh server-target`
  - `pass`

## Residual Queue

PG731 does not close the global goal. The remaining current queue is still:

- `xmage_authoritative_adapter_required_count=24288`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`

Next work should continue with the largest exact-safe subpattern available from
the post-PG731 queue, starting from the highest-volume supported work units.
