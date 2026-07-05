# PG481 ETB Draw Patterns E2E Validation

- Generated at: `2026-07-05`
- Scope: `xmage_creature_etb_optional_discard_draw_cards_v1` and `xmage_creature_etb_dynamic_draw_cards_v1`
- Selected cards: `12`

## Cards

- Armorcraft Judge
- Discerning Peddler
- Earthshaker Dreadmaw
- Fissure Wizard
- Immersturm Raider
- Keldon Raider
- Plundering Predator
- Prophet of the Scarab
- Regal Force
- Shinestriker
- Viashino Racketeer
- Yuyan Archers

## PostgreSQL Package

- Package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_manifest.json`
- Precheck: `12/12` target rows, `0` existing expected rows, `0` shadow rows to deprecate.
- Apply: `upserted_rows=12`, `deprecated_shadow_rows=0`.
- Postcheck: `12/12` promoted rows, `12/12` `verified`/`auto`, `12/12` matching Oracle hash, `backup_rows=0`.

## Sync And Runtime

- Metadata sync report: `docs/hermes-analysis/master_optimizer_reports/pg481_etb_draw_patterns_new_server_metadata_sync.json`
  - PostgreSQL cards matched: `6701`
  - SQLite cache alias rows: `6629`
  - deck_cards backfill matched: `2699/2699`
  - unresolved: `1`
- Battle rule sync report: `docs/hermes-analysis/master_optimizer_reports/pg481_etb_draw_patterns_new_server_battle_rules_pg_to_sqlite_sync.json`
  - PostgreSQL rows loaded: `4579`
  - SQLite inserted/updated: `7175`
  - canonical snapshot rows exported: `4550`
- Direct validation:
  - PostgreSQL scope matches: `12/12`
  - SQLite scope matches: `12/12`
  - snapshot scope/status matches: `12/12`
  - runtime `get_card_effect` scope matches: `12/12`

## Tests And Audits

- Focused unit suite: `769` tests passed.
- Package builder test lane: passed.
- Compile check: `battle_analyst_v9.py`, `xmage_authoritative_exact_scope_split.py`, `xmage_batch_pg_package_builder.py`, `sync_battle_card_rules_pg.py`, and `sync_pg_card_metadata_to_hermes.py` passed `py_compile`.
- XMage strategy audit: `26/26` pass.
- Operational surface audit: pass.
- Legacy contamination audit: pass.
- PG/Hermes/SQLite contract audit: `51/51` pass.

## Queue Delta

- Post-PG480 queue:
  - `target_identity_count=26319`
  - `xmage_authoritative_source_count=26005`
  - `xmage_authoritative_adapter_required_count=26005`
  - `draw_engine::xmage_draw_card_variant_review_v1=1605`
- Post-PG481 queue:
  - `target_identity_count=26307`
  - `xmage_authoritative_source_count=25993`
  - `xmage_authoritative_adapter_required_count=25993`
  - `draw_engine::xmage_draw_card_variant_review_v1=1593`
- Exact split recheck after PG481: `proposal_count=0`, `safe_for_batch_pg_package_count=0`.

## Residual Blockers In This Neighbor Family

- `Liliana's Standard Bearer` remains blocked because its ETB draw amount depends on creatures that died under your control this turn.
- `Treetop Sentries` remains blocked because its ETB draw is gated by forage cost payment.
