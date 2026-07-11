# PG755 Color Wisps Draw Evidence - 2026-07-11

Status: `applied_new_server_synced_e2e_pass`.

## Scope

XMage exact-scope adapter/runtime promotion for target-creature color-change
until end of turn plus draw-card Wisps patterns.

Cards promoted:

- `Aphotic Wisps`: target creature becomes black, gains fear until EOT, draw 1.
- `Viridescent Wisps`: target creature becomes green, gets +1/+0 until EOT, draw 1.

Explicitly not promoted in this batch:

- `Cerulean Wisps` and `Niveous Wisps`: require tap/untap color-draw composite support.
- `Crimson Wisps`: not present in the post-PG754 adapter queue as an outstanding gap.

## Runtime And Adapter Changes

- `battle_analyst_v9.py`: `stat_modifier_until_eot` now supports
  `target_colors_until_eot` with EOT restoration and replay evidence.
- `xmage_authoritative_exact_scope_split.py`: added exact XMage/Oracle scopes:
  - `xmage_fixed_color_keyword_target_creature_until_eot_draw_card_spell_v1`
  - `xmage_fixed_color_boost_target_creature_until_eot_draw_card_spell_v1`
- `xmage_batch_pg_package_builder.py`: includes `target_colors_until_eot` in
  executable required fields and E2E scenarios.
- `battle_package_end_to_end_validation.py`: validates final target color and
  replay `target_colors_until_eot`.

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_postcheck.sql`

Precheck result:

- `Aphotic Wisps`: `target_card_rows=1`, existing expected rule rows `0`.
- `Viridescent Wisps`: `target_card_rows=1`, existing expected rule rows `0`.

Apply result:

- `upserted_rows=2`
- `deprecated_shadow_rows=0`

Postcheck result:

- `Aphotic Wisps`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`.
- `Viridescent Wisps`: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`,
  `promoted_oracle_hash_rows=1`.

## Sync And E2E

SQLite/Hermes sync report:

- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_sqlite_sync.json`
- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=10067`
- `sqlite_inserted_or_updated=9845`
- `canonical_snapshot_rows_exported=7459`

E2E report:

- `docs/hermes-analysis/master_optimizer_reports/pg755_color_wisps_draw_new_server_e2e.json`
- status: `pass`
- stages passed: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime get-card-effect, battle execution.

Battle execution evidence:

- `Aphotic Wisps`: drew 1, granted `fear`, target colors `["B"]`, target stayed
  `2/2`.
- `Viridescent Wisps`: drew 1, target colors `["G"]`, target became `3/2`.

## Queue Impact

Readiness after PG755:

- `battle_and_oracle_ready=6418`
- `snapshot_has_verified_rule=6497`
- `battle_family_mapper_required=27404`
- `trusted_rule_oracle_hash_backfill=54`

Commander-legal XMage queue after PG755:

- `target_identity_count=24481`
- `xmage_authoritative_source_count=24168`
- `xmage_authoritative_adapter_required_count=24168`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Delta from PG754:

- ready count: `6416 -> 6418`
- adapter-required queue: `24170 -> 24168`
- draw-card review unit: `543 -> 541`
