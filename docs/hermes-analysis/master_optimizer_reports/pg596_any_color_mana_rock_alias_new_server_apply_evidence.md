# PG596 Any-Color Mana Rock Alias Apply Evidence

Generated UTC: 2026-07-07

## Scope

PG596 routed the legacy XMage work unit
`ramp_permanent::one_any_color_mana_rock_v1` into the supported ManaLoom
mana-source runtime units.

- Runtime scopes:
  - `xmage_simple_tap_mana_source_permanent_v1`
  - `xmage_self_sacrifice_mana_source_permanent_v1`
  - `xmage_target_sacrifice_mana_source_permanent_v1`
- Effect: `ramp_permanent`
- Selected cards: `5`
- Cards: Celestial Prism; Chromatic Sphere; Mana Cylix; Manalith; Phyrexian
  Altar.
- Blocked by design: Phyrexian Lens and Standing Stones remain blocked as
  `mana_source_source_pay_life_cost_not_supported`; the current mana-source
  runtime does not safely pay life as activation cost.

## Runtime And Splitter

- `xmage_authoritative_exact_scope_split.py` now treats
  `ramp_permanent::one_any_color_mana_rock_v1` as a supported ramp unit.
- The package builder now preserves `mana_activation_requires_sacrifice_target`
  in E2E manifests.
- E2E scenario generation now accepts the manifest aliases
  `activation_requires_sacrifice_target` and `activation_sacrifice_target`, so
  target-sacrifice mana sources such as Phyrexian Altar do not get misrouted as
  self-sacrifice sources.
- `battle_package_end_to_end_validation.py` now exercises contextual sacrifice
  mana-source activation, including source sacrifice and target sacrifice
  assertions.

## Tests

Focused tests passed before final evidence:

- `python3 -m py_compile` for the package builder, E2E validator, and package
  builder tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: 368 tests passed.
- Earlier splitter test run for the alias expansion:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`:
  728 tests passed.

## PostgreSQL Apply

Target: `127.0.0.1:15432/halder`

- Package: `docs/hermes-analysis/master_optimizer_reports/pg596_any_color_mana_rock_alias_new_server_package_manifest.json`
- Precheck: 5 target rows, 0 existing expected rows; Phyrexian Altar had 2
  nonmatching trusted shadow rows to deprecate.
- Apply: 5 rows upserted, 2 shadow rows deprecated.
- Postcheck:
  - 5/5 promoted rule rows.
  - 5/5 `review_status='verified'` and `execution_status='auto'`.
  - 5/5 matching `oracle_hash`.
  - 2 backup rows.

## Sync And E2E

- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg596_any_color_mana_rock_alias_new_server_pg_to_sqlite_sync.json`
  - `pg_rows_loaded`: 9359
  - `sqlite_inserted_or_updated`: 9123
  - `canonical_snapshot_rows_exported`: 6802
- Metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg596_any_color_mana_rock_alias_new_server_metadata_sync.json`
  - `postgres_target`: `127.0.0.1:15432/halder`
  - `postgres_cards_matched`: 7767
  - `sqlite_cache_alias_rows`: 7703
  - `deck_cards` matched: 2699/2699
  - `card_id_rows_updated`: 107
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg596_any_color_mana_rock_alias_new_server_e2e_validation.md`
  - Status: `pass`
  - PostgreSQL rows: 5
  - SQLite rows: 5
  - Snapshot cards: 5
  - Runtime lookup cards: 5
  - Battle execution: 5 scenarios, 9 events
  - Chromatic Sphere proved `self_sacrifice_mana_source_activated`.
  - Phyrexian Altar proved `target_sacrifice_mana_source_activated` with the
    source preserved and the creature target sacrificed.

## Queue And Audits

- Final queue after PG596B hash backfill:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260707_post_pg596b_oracle_hash_backfill_new_server_commander_legal.md`
  - `target_identity_count`: 25182
  - `xmage_authoritative_source_count`: 24868
  - `xmage_missing_source_exception_count`: 314
  - `xmage_authoritative_parser_gap_count`: 0
  - `xmage_authoritative_adapter_required_count`: 24868
  - `adapter_work_unit_count`: 11338
- Final readiness after PG596B hash backfill:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260707_post_pg596b_oracle_hash_backfill_new_server.md`
  - `snapshot_has_any_rule`: 6805
  - `snapshot_has_verified_rule`: 5590
  - `battle_and_oracle_ready`: 5768
  - `battle_family_mapper_required`: 28105
- Final probe after PG596B hash backfill:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260707_probe_post_pg596b_oracle_hash_backfill_new_server.md`
  - `proposal_count`: 0
  - `safe_for_batch_pg_package_count`: 0
- Final audits:
  - XMage strategy consistency: 26/26 pass.
  - Operational surface alignment: pass.
  - Legacy contamination audit: pass.
  - PG/Hermes/SQLite contract: passed after PG596B hash backfill.
  - `./scripts/quality_gate.sh server-target`: pass.

## Workspace Hygiene

- The 40 MB raw queue JSON files generated only for post-PG596 and
  post-PG596B probes were removed.
- The stale post-PG596 pre-backfill queue/readiness/probe artifacts and the
  intermediate failing PG/Hermes/SQLite audit were removed; retained reports
  point at the final passing post-PG596B state.
