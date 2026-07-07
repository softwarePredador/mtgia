# PG595 Limited-Times Any-Color Mana Source Apply Evidence

Generated UTC: 2026-07-07

## Scope

PG595 promoted the XMage-authoritative limited-times activated any-color mana
source scope for artifact and artifact-creature permanents with
`LimitedTimesPerTurnActivatedManaAbility`, fixed `{1}` activation cost, and
`AddManaOfAnyColorEffect` or an exact subclass.

- Runtime scope: `xmage_simple_tap_mana_source_permanent_v1`
- Effect: `ramp_permanent`
- Family: `xmage_limited_times_any_color_mana_source_permanent`
- Selected cards: `7`
- Cards: Barrels of Blasting Jelly; Foraging Wickermaw; Gravestone Strider;
  Salvaged Manaworker; Scarecrow Guide; Shire Scarecrow; Three Tree Mascot.
- Blocked by design: Kozilek's Translator and Ramos, Dragon Engine remain
  blocked as `limited_mana_source_cost_not_supported` because their limited
  mana abilities require life payment or removing counters, and the mana-source
  runtime does not yet pay those costs safely.

## Runtime And Splitter

- `xmage_authoritative_exact_scope_split.py` now maps limited-times
  `AddManaOfAnyColorEffect` and exact subclasses when Oracle and XMage agree on
  `{1}: Add one mana of any color. Activate only once each turn.`
- The splitter tolerates same-line non-mana tails, such as Foraging
  Wickermaw becoming the chosen color, only as `_runtime_partial` metadata.
- Auxiliary abilities/effects such as sacrifice-damage, graveyard exile, ETB
  surveil, and changeling remain explicitly listed as unmodeled partials.
- Static keywords remain preserved where already supported: Scarecrow Guide
  keeps `reach`, and Shire Scarecrow keeps `defender`.

## Tests

Focused tests passed before apply:

- `python3 -m py_compile` for the splitter, package builder, E2E validator, and
  battle runtime.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: 724 tests passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: 368 tests passed.

## PostgreSQL Apply

Target: `127.0.0.1:15432/halder`

- Package: `docs/hermes-analysis/master_optimizer_reports/pg595_limited_times_any_color_mana_new_server_package_manifest.json`
- Precheck: 7 target card rows, 0 existing expected executable rows, 0 shadow
  rows to deprecate.
- Apply: 7 rows upserted, 0 shadow rows deprecated.
- Postcheck:
  - 7/7 promoted rule rows.
  - 7/7 `review_status='verified'` and `execution_status='auto'`.
  - 7/7 matching `oracle_hash`.
  - 0 backup rows.

## Sync And E2E

- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg595_limited_times_any_color_mana_new_server_pg_to_sqlite_sync.json`
  - `pg_rows_loaded`: 9354
  - `sqlite_inserted_or_updated`: 9118
  - `canonical_snapshot_rows_exported`: 6798
- Metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg595_limited_times_any_color_mana_new_server_metadata_sync.json`
  - `deck_cards` matched: 2699/2699
  - `card_id_rows_updated`: 88
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg595_limited_times_any_color_mana_new_server_e2e.md`
  - Status: `pass`
  - PostgreSQL rows: 7
  - SQLite rows: 7
  - Snapshot cards: 7
  - Runtime lookup cards: 7
  - Battle execution: 7 scenarios, 28 events

## Queue And Audits

- Queue after PG595: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260707_post_pg595_limited_any_color_mana_new_server_commander_legal.md`
  - `target_identity_count`: 25187
  - `xmage_authoritative_source_count`: 24873
  - `xmage_missing_source_exception_count`: 314
  - `xmage_authoritative_parser_gap_count`: 0
  - `xmage_authoritative_adapter_required_count`: 24873
  - `ramp_permanent::xmage_artifact_mana_source_variant_review_v1`: 127
- Probe after PG595: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260707_probe_post_pg595_limited_any_color_mana_new_server.md`
  - `proposal_count`: 0
  - `safe_for_batch_pg_package_count`: 0
- Final audits:
  - XMage strategy consistency: 26/26 pass.
  - Operational surface alignment: pass.
  - Legacy contamination audit: pass.
  - PG/Hermes/SQLite contract: 51/51 pass.
  - `./scripts/quality_gate.sh server-target`: pass.
