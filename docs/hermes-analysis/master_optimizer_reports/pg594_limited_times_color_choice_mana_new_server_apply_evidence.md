# PG594 Limited-Times Color-Choice Mana Source Apply Evidence

Generated UTC: 2026-07-07

## Scope

PG594 promoted the XMage-authoritative limited-times activated mana source
scope for creatures with `LimitedTimesPerTurnActivatedManaAbility` and
`AddManaFromColorChoicesEffect`.

- Runtime scope: `xmage_simple_tap_mana_source_permanent_v1`
- Effect: `ramp_permanent`
- Family: `xmage_limited_times_color_choice_mana_source_permanent`
- Selected cards: `4`
- Cards: Abzan Devotee; Jeskai Devotee; Sultai Devotee; Temur Devotee.
- Partial runtime marker: Abzan Devotee and Jeskai Devotee execute only the
  mana-source subset because their auxiliary XMage ability/effect classes
  remain unmodeled.
- Static keyword preservation: Sultai Devotee keeps `deathtouch`; Temur Devotee
  keeps `defender`.

## Runtime And Splitter

- `xmage_authoritative_exact_scope_split.py` now maps fixed
  `LimitedTimesPerTurnActivatedManaAbility` + `AddManaFromColorChoicesEffect`
  sources with generic activation cost, no tap cost, and
  `activation_limit_per_turn=1`.
- Conditional mana, conditional colorless/colored mana, unsupported non-mana
  classes, and mismatched Oracle/source costs remain blocked.
- `battle_analyst_v9.py` now tracks mana-source activation counts per turn,
  skips activation after the configured per-turn limit, and emits
  `mana_source_activation_skipped` with reason `activation_limit_per_turn`.
- `xmage_batch_pg_package_builder.py` and
  `battle_package_end_to_end_validation.py` now preserve and validate
  `activation_limit_per_turn` in focused simple-mana-source scenarios.

## Tests

Focused tests passed after implementation and before final commit:

- `python3 -m py_compile` for the splitter, package builder, E2E validator, and
  battle runtime.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: 720 tests passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: 368 tests passed.

## PostgreSQL Apply

Target: `127.0.0.1:15432/halder`

- Package: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_package_manifest.json`
- Precheck: 4 target card rows, 0 existing expected executable rows, 0 shadow
  rows to deprecate.
- Apply: 4 rows upserted, 0 shadow rows deprecated.
- Postcheck:
  - 4/4 promoted rule rows.
  - 4/4 `review_status='verified'` and `execution_status='auto'`.
  - 4/4 matching `oracle_hash`.
  - 0 backup rows.

## Sync And E2E

- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_pg_to_sqlite_sync.json`
  - `pg_rows_loaded`: 9347
  - `sqlite_inserted_or_updated`: 9111
  - `canonical_snapshot_rows_exported`: 6791
- Metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_metadata_sync.json`
  - `deck_cards` matched: 2699/2699
  - `card_id_rows_updated`: 105
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg594_limited_times_color_choice_mana_new_server_e2e.md`
  - Status: `pass`
  - PostgreSQL rows: 4
  - SQLite rows: 4
  - Snapshot cards: 4
  - Runtime lookup cards: 4
  - Battle execution: 4 scenarios, 16 events

## Queue And Audits

- Queue after PG594: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260707_post_pg594_limited_mana_new_server_commander_legal.md`
  - `target_identity_count`: 25194
  - `xmage_authoritative_source_count`: 24880
  - `xmage_missing_source_exception_count`: 314
  - `xmage_authoritative_parser_gap_count`: 0
  - `xmage_authoritative_adapter_required_count`: 24880
  - `ramp_permanent::xmage_creature_mana_source_variant_review_v1`: 273
- Probe after PG594: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260707_probe_post_pg594_limited_mana_new_server.md`
  - `proposal_count`: 0
  - `safe_for_batch_pg_package_count`: 0
- Final audits:
  - XMage strategy consistency: 26/26 pass.
  - Operational surface alignment: pass.
  - Legacy contamination audit: pass.
  - PG/Hermes/SQLite contract: 51/51 pass.
  - `./scripts/quality_gate.sh server-target`: pass.
