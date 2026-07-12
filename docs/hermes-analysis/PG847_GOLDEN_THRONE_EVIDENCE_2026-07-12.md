# PG847 Golden Throne Evidence - 2026-07-12

Status: `applied_verified_synced`.

Database target: `server/bin/with_new_server_pg.sh`
(`127.0.0.1:15432/halder`).

## Scope

- Card: `The Golden Throne`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheGoldenThrone.java`
- ManaLoom scope: `xmage_target_sacrifice_mana_source_permanent_v1`
- Behavior covered:
  - activated mana ability: tap, sacrifice target creature, add three mana in any combination of colors
  - static replacement: if the controller would lose the game, exile the source and set life total to 1

## Runtime Changes

- `battle_sba_support.py` accepts an optional loss-replacement callback before player elimination SBAs.
- `battle_analyst_v9.py` implements `replace_losing_game_exile_self_life_total_1` via `apply_loss_replacement`.
- `xmage_authoritative_exact_scope_split.py` classifies `TheGoldenThroneEffect` as modeled when paired with the target-sacrifice mana source scope.
- `xmage_batch_pg_package_builder.py` preserves loss-replacement fields and now emits multiple execution scenarios for a composite rule.
- `battle_package_end_to_end_validation.py` runs the package-level `loss_replacement` scenario.

## PostgreSQL Package

- Package prefix: `docs/hermes-analysis/master_optimizer_reports/pg847_golden_throne_new_server`
- Precheck: `target_card_rows=1`, `existing_rule_rows=1`, `expected_rule_rows_before=1`, `would_deprecate_shadow_rows=0`
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`

## Sync

- Metadata sync report: `pg847_golden_throne_new_server_metadata_sync.json`
  - requested unique names: `8543`
  - PostgreSQL cards matched: `8734`
  - SQLite alias rows: `8673`
  - `deck_cards` matched: `2699/2699`
- Rule sync report: `pg847_golden_throne_new_server_sqlite_sync.json`
  - PostgreSQL rows loaded: `10533`
  - SQLite rows inserted/updated: `10311`
  - canonical snapshot rows exported: `7797`

## Validation

- Focused builder tests: `4 passed`
- Focused battle package tests: `9 passed`
- Focused exact-scope split tests: `2 passed`
- Package E2E: `pass`
  - PostgreSQL source of truth: `pass`
  - SQLite/Hermes cache: `pass`
  - canonical snapshot fallback: `pass`
  - runtime lookup: `pass`
  - battle execution: `pass`
  - battle scenarios: `2`
    - `The Golden Throne replaces a loss by exiling itself`
    - `The Golden Throne activates contextual sacrifice mana source`
- XMage strategy consistency audit: `pass`, `26/26`
- PG/Hermes/SQLite contract audit: `pass`, `51/51`
- Operational surface alignment audit: `pass`

## Post-PG847 Queue

- `target_identity_count`: `24137`
- `xmage_authoritative_source_count`: `23824`
- `xmage_authoritative_adapter_required_count`: `23824`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
- `adapter_work_unit_count`: `11224`

The global goal remains active. PG847 closes one source-authoritative XMage
identity and leaves the remaining global queue for subsequent family/subpattern
batches.
