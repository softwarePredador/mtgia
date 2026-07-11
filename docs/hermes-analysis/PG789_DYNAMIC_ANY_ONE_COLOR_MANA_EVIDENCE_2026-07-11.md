# PG789 Dynamic Any-One-Color Mana Evidence - 2026-07-11

Status: `applied_synced_validated`

Target: new-server PostgreSQL via `./server/bin/with_new_server_pg.sh`
(`127.0.0.1:15432/halder`).

## Scope

PG789 adds exact XMage -> ManaLoom support for dynamic mana sources whose
amount is a battlefield or graveyard count, including "any one color" choice
and one fixed-color Forest-count case.

Runtime/mapper changes:

- New exact scope:
  `xmage_dynamic_any_one_color_mana_source_permanent_v1`
- Extended fixed-color dynamic mana source support for Forest count.
- Runtime dynamic mana count now supports:
  `controller_graveyard_card_count`.
- Package/E2E manifest now preserves:
  `dynamic_mana_graveyard_count_card_types`.
- E2E manifest now validates conditional mana colors from
  `conditional_mana_modes`.

Promoted cards:

- Deathbloom Ritualist
- Harabaz Druid
- Rofellos, Llanowar Emissary
- Sanctum Weaver
- Wirewood Channeler

## Tests

Focused test command:

```bash
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q
```

Result:

- `1434 passed`
- `238 subtests passed`

## Package

Proposal split:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg789_dynamic_any_one_color_mana_new_server.json`
- `safe_for_batch_pg_package_count=5`
- Family counts:
  - `xmage_dynamic_any_one_color_mana_source=4`
  - `xmage_fixed_color_dynamic_mana_source=1`

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_package_manifest.json`

## PostgreSQL Apply

Precheck:

- `5` target rows
- `0` expected rule rows before
- `2` old shadow rows to deprecate for Sanctum Weaver

Apply:

- `upserted_rows=5`
- `deprecated_shadow_rows=2`

Postcheck:

- `5/5` promoted rows
- `5/5` `review_status=verified`
- `5/5` `execution_status=auto`
- `5/5` matching `oracle_hash`

## Sync

Battle rule sync:

- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=10166`
- `sqlite_inserted_or_updated=9944`
- `canonical_snapshot_rows_exported=7554`

Metadata sync:

- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_metadata_sync.json`
- `postgres_target=127.0.0.1:15432/halder`
- `requested_unique_names=8300`
- `postgres_cards_matched=8491`
- `sqlite_cache_alias_rows=8430`
- `deck_cards_backfill.matched_cache_rows=2699/2699`

## E2E

Report:

- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/pg789_dynamic_any_one_color_mana_new_server_e2e_validation.md`

Status: `pass`

Validated stages:

- PostgreSQL source of truth: `5/5`
- SQLite Hermes cache: `5/5`
- Canonical snapshot fallback: `5/5`
- Runtime `get_card_effect`: `5/5`
- Battle execution: `5` scenarios, `5` events

Battle execution proved:

- Deathbloom Ritualist: `controller_graveyard_card_count`, 3 creature cards in
  graveyard -> 3 conditional WUBRG mana.
- Harabaz Druid: controlled Ally count -> 3 conditional WUBRG mana.
- Rofellos, Llanowar Emissary: controlled Forest count -> 3 green mana.
- Sanctum Weaver: controlled enchantment count -> 3 conditional WUBRG mana.
- Wirewood Channeler: all-battlefield Elf count -> 3 conditional WUBRG mana.

## Final Audits

- XMage strategy consistency:
  `xmage_strategy_consistency_audit_20260711_post_pg789_dynamic_any_one_color_mana_new_server_final`
  passed `26/26`
- Operational surface alignment:
  `operational_surface_alignment_audit_20260711_post_pg789_dynamic_any_one_color_mana_new_server_final`
  passed
- Legacy contamination:
  `legacy_contamination_audit_20260711_post_pg789_dynamic_any_one_color_mana_new_server_final`
  passed
- PG/Hermes/SQLite contract:
  `pg_hermes_sqlite_contract_audit_20260711_post_pg789_dynamic_any_one_color_mana_new_server_final`
  passed `51/51`
- Server target quality gate:
  `./scripts/quality_gate.sh server-target` passed

## Global Queue After PG789

Readiness:

- `battle_and_oracle_ready=6560`
- `battle_family_mapper_required=27305`
- `snapshot_has_any_rule=7760`
- `snapshot_has_verified_rule=6596`

Note: PG789 promoted 5 verified battle rules, while `battle_and_oracle_ready`
increased by 4 because Rofellos is still blocked by Commander legality, not by
missing battle/oracle rule.

XMage authoritative queue:

- `target_identity_count=27258`
- `xmage_authoritative_source_count=24323`
- `xmage_authoritative_adapter_required_count=24323`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=2935`

The global all-card goal remains active.
