# PG736 Fixed Color Dynamic Mana Evidence - 2026-07-11

## Scope

PG736 promotes the exact local-XMage fixed-color dynamic mana permanent scope:

- family: `xmage_fixed_color_dynamic_mana_source`
- battle model scope: `xmage_fixed_color_dynamic_mana_source_permanent_v1`
- source signal: exact `DynamicManaAbility`
- supported amount sources: battlefield permanent count, devotion to a fixed color, source power
- excluded: any-one-color dynamic mana and target-sacrifice dynamic mana

Promoted cards:

- `Karametra's Acolyte`
- `Magus of the Coffers`
- `Priest of Titania`
- `Viridian Joiner`

## Implementation

Runtime support was added to:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`

XMage splitting and package generation were added to:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`

Focused tests were added or extended in:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg736_fixed_color_dynamic_mana_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg736_fixed_color_dynamic_mana_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg736_fixed_color_dynamic_mana_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg736_fixed_color_dynamic_mana_new_server_package_rollback.sql`

Postcheck on the new server target `127.0.0.1:15432/halder`:

- promoted rows: `4/4`
- promoted `review_status=verified` and `execution_status=auto`: `4/4`
- promoted rows with Oracle hash: `4/4`
- backup rows retained: `2` per promoted card

## Sync And E2E

Metadata sync:

- PostgreSQL cards matched: `7420`
- SQLite cache alias rows: `7342`
- `deck_cards` matched: `2699/2699`
- card id updates: `108`
- unresolved names: `1`

Battle rule sync:

- PostgreSQL rows loaded: `6331`
- SQLite rows inserted or updated: `6326`
- canonical snapshot rows exported: `6282`

Package E2E:

- status: `pass`
- PostgreSQL source of truth: `4` rows validated
- SQLite/Hermes cache: `4` rows validated
- canonical snapshot fallback: `4` cards validated
- runtime `get_card_effect`: `4` cards validated
- battle execution: `4` scenarios, `5` events

## Global State After PG736

Readiness:

- total known cards: `34331`
- `battle_and_oracle_ready`: `6380`
- `snapshot_has_verified_rule`: `6405`
- `battle_family_mapper_required`: `27496`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`
- `digital_non_commander_rule_exception`: `3`
- `official_oracle_identity_unavailable`: `3`

XMage Commander-legal queue:

- target identities: `24573`
- XMage authoritative source count: `24260`
- XMage adapter-required count: `24260`
- XMage parser-gap count: `0`
- XMage missing-source exception count: `313`
- top remaining ramp permanent creature work unit: `252`

## Validation

Focused test battery:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k dynamic_mana`
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k fixed_color_dynamic_mana`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k fixed_color_dynamic_mana`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k fixed_color_dynamic_mana`

Audits and gates:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg736_fixed_color_dynamic_mana_new_server`: `pass`, `51/51`
- `xmage_strategy_consistency_audit_20260711_post_pg736_fixed_color_dynamic_mana_new_server`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260711_post_pg736_fixed_color_dynamic_mana_new_server`: `pass`
- `legacy_contamination_audit_20260711_post_pg736_fixed_color_dynamic_mana_new_server`: `pass`
- `./scripts/quality_gate.sh server-target`: `pass`
- `git diff --check`: `pass`
