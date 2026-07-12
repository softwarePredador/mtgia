# PG820 Heraldic Banner Chosen Color Static Boost Evidence - 2026-07-12

Status: applied on the new-server PostgreSQL target through
`server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Scope

PG820 promotes the XMage-backed exact adapter for `Heraldic Banner`.

- XMage source class: `HeraldicBanner`
- XMage behavior:
  - `AsEntersBattlefieldAbility(new ChooseColorEffect(...))`
  - `SimpleStaticAbility(new HeraldicBannerEffect())`
  - `SimpleManaAbility(... new AddManaChosenColorEffect(), new TapSourceCost())`
- ManaLoom mana scope: `xmage_simple_tap_mana_source_permanent_v1`
- Composite static component:
  `xmage_static_controlled_power_toughness_boost_v1`
- Static rule: creatures you control of the chosen color get `+1/+0`.

This is an exact source/runtime adapter, not a generic review promotion.

## Implementation

- Runtime: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Splitter:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
- Package builder:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py`
- Tests:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`

## SQL Package

- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_manifest.json`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_package.md`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_rollback.sql`
- Backup table:
  `manaloom_deploy_audit.pg820_heraldic_banner_chosen_color_stati_20260712_084027`

## PostgreSQL Apply Evidence

Precheck:

- Card: `Heraldic Banner`
- Oracle hash: `ed7379514aeb8e44fccbd2964c6fedda`
- Target card rows: `1`
- Existing exact rule rows before apply: `0`
- Shadow rows to deprecate: `2`

Apply:

- Deprecated shadow rows: `2`
- Upserted rows: `1`

Postcheck:

- Promoted rule rows: `1`
- Promoted verified/auto rows: `1`
- Promoted oracle-hash rows: `1`
- Backup rows: `2`

Current verified PostgreSQL row:

- Card: `Heraldic Banner`
- Rule: `battle_rule_v1:c47ed426b45962ec47c53926d1a6c9e3`
- Review/execution: `verified` / `auto`
- Oracle hash: `ed7379514aeb8e44fccbd2964c6fedda`
- Battle model scope: `xmage_simple_tap_mana_source_permanent_v1`
- `chosen_color_mana`: `true`
- Composite component count: `1`
- Composite component scope:
  `xmage_static_controlled_power_toughness_boost_v1`
- Composite component `static_required_chosen_color`: `true`

## Sync

Battle-rule sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_pg_to_sqlite_sync.json`
- `canonical_snapshot_rows_exported`: `7697`
- `pg_rows_loaded`: `10319`
- `sqlite_inserted_or_updated`: `10097`

Metadata sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_metadata_sync.json`
- PostgreSQL cards matched: `8636`
- SQLite cache alias rows: `8575`
- `deck_cards` backfill matched: `2699/2699`
- `card_id_updates`: `99`
- unresolved: `1`

## Validation

Focused tests:

- `python3 -m py_compile ...`: `pass`
- `test_xmage_authoritative_exact_scope_split.py -k chosen_color_mana_source_static_controlled_pt_boost`: `pass`
- `test_xmage_exact_scope_runtime.py -k composite_chosen_color_mana_source_static_pt_boost`: `pass`
- `pytest test_xmage_batch_pg_package_builder.py -k chosen_color_mana_source_manifest`: `2 passed`

E2E:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg820_heraldic_banner_chosen_color_static_boost_new_server_e2e.md`
- Status: `pass`
- PostgreSQL source of truth: `pass`
- SQLite Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime `get_card_effect`: `pass`
- Battle execution: `pass`
- Scenario: `Heraldic Banner refreshes modeled mana source`
- Battle event: conditional mana `1`, available mana `1`, tapped `true`

Global readiness:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg820_heraldic_banner_chosen_color_static_boost_new_server.md`
- `battle_and_oracle_ready`: `6642`
- `battle_family_mapper_required`: `27152`
- `battle_rule_verification_required`: `70`
- `snapshot_has_verified_rule`: `6749`

Gates:

- `xmage_strategy_consistency_audit_20260712_post_pg820_heraldic_banner_chosen_color_static_boost_new_server_final`: `pass`, `26/26`
- `operational_surface_alignment_audit_20260712_post_pg820_heraldic_banner_chosen_color_static_boost_new_server_final`: `pass`
- `legacy_contamination_audit_20260712_post_pg820_heraldic_banner_chosen_color_static_boost_new_server_final`: `pass`
- `pg_hermes_sqlite_contract_audit_20260712_post_pg820_heraldic_banner_chosen_color_static_boost_new_server_final`: `pass`, `51/51`
- `./scripts/quality_gate.sh server-target`: `pass`
