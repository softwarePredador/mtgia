# PG756 Color Tap/Untap Wisps Draw Evidence - 2026-07-11

Status: `applied_new_server_synced_e2e_pass`.

## Scope

XMage exact-scope adapter/runtime promotion for target-creature color-change
until end of turn plus tap/untap plus draw-card Wisps patterns.

Cards promoted:

- `Cerulean Wisps`: target creature becomes blue until EOT, untap that
  creature, draw 1.
- `Niveous Wisps`: target creature becomes white until EOT, tap that creature,
  draw 1.

## Runtime And Adapter Changes

- `battle_analyst_v9.py`:
  - `tap_target` now supports `target_colors_until_eot`.
  - `stat_modifier_until_eot_untap_target` now supports
    `target_colors_until_eot`.
  - `composite_resolution` can execute `tap_target` and
    `stat_modifier_until_eot_untap_target` components without finishing the
    spell before later components.
- `xmage_authoritative_exact_scope_split.py` added exact scopes:
  - `xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1`
  - `xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1`
- `xmage_batch_pg_package_builder.py` added a focused execution scenario for
  color + tap/untap + draw.
- `battle_package_end_to_end_validation.py` validates final color, tapped
  state, draw, and component replay events.

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_postcheck.sql`

Precheck result:

- `Cerulean Wisps`: `target_card_rows=1`, existing expected rule rows `0`.
- `Niveous Wisps`: `target_card_rows=1`, existing expected rule rows `0`.

Apply result:

- `upserted_rows=2`
- `deprecated_shadow_rows=0`

Postcheck result:

- `Cerulean Wisps`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- `Niveous Wisps`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.

Direct PostgreSQL field check:

- `Cerulean Wisps`: scope
  `xmage_fixed_color_untap_target_creature_until_eot_draw_card_spell_v1`,
  `target_colors_until_eot=["U"]`, `untap_target=true`, `draw_count=1`.
- `Niveous Wisps`: scope
  `xmage_fixed_color_tap_target_creature_until_eot_draw_card_spell_v1`,
  `target_colors_until_eot=["W"]`, `tap_target=true`, `draw_count=1`.

## Sync And E2E

SQLite/Hermes sync report:

- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_sqlite_sync.json`
- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=10069`
- `sqlite_inserted_or_updated=9847`
- `canonical_snapshot_rows_exported=7461`

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg756_color_tap_untap_wisps_draw_new_server_e2e.json`
- status: `pass`
- stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime get-card-effect, battle execution.

Battle execution evidence:

- `Cerulean Wisps`: action `untap`, target colors `["U"]`,
  `target_tapped=false`, drew 1.
- `Niveous Wisps`: action `tap`, target colors `["W"]`,
  `target_tapped=true`, drew 1.

## Queue Impact

Readiness after PG756:

- `battle_and_oracle_ready=6420`
- `snapshot_has_verified_rule=6499`
- `battle_family_mapper_required=27402`
- `trusted_rule_oracle_hash_backfill=54`

Commander-legal XMage queue after PG756:

- `target_identity_count=24479`
- `xmage_authoritative_source_count=24166`
- `xmage_authoritative_adapter_required_count=24166`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Delta from PG755:

- ready count: `6418 -> 6420`
- adapter-required queue: `24168 -> 24166`
- draw-card review unit: `541 -> 540`
- untap-target review unit: `208 -> 207`
