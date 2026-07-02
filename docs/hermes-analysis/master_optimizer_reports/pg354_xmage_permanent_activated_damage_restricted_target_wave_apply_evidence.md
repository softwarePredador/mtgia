# PG354 Permanent Activated Damage Restricted Target Wave Evidence

- Status: `applied_synced_e2e_validated`
- Generated/applied at: `2026-07-02`
- Package: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_manifest.json`
- PostgreSQL source of truth: `card_battle_rules`
- Hermes SQLite cache: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Scope

PG354 promotes `22` exact XMage-authoritative permanent activated damage rules
into ManaLoom's existing `xmage_permanent_simple_activated_damage_v1` runtime
scope.

The wave extends that exact scope beyond simple `any target` and
`target creature` to source/Oracle-matched restricted targets:

- `player_or_planeswalker`: `8`
- `attacking_or_blocking_creature`: `10`
- `flying_creature`: `3`
- `blocking_creature`: `1`

Selected cards:

`Centaur Archer`, `Chandra's Magmutt`, `Crossbow Infantry`,
`D'Avenant Archer`, `Duergar Assailant`, `Elite Archers`,
`Expendable Troops`, `Flamewave Invoker`, `Font of Ire`,
`Goblin Fireslinger`, `Grapeshot Catapult`, `Heavy Ballista`,
`Lady Caleria`, `Sacellum Archers`, `Scalding Devil`, `Soldier Replica`,
`Telim'Tor's Darts`, `Tor Wauki`, `Viridian Scout`, `Volcanic Rambler`,
`Vulshok Replica`, and `War-Torch Goblin`.

## Runtime And Splitter Validation

- `test_xmage_authoritative_exact_scope_split.py`: `233` tests, `OK`
- `test_xmage_exact_scope_runtime.py`: `142` tests, `OK`
- Package/E2E helper tests:
  `test_xmage_batch_pg_package_builder.py` and
  `test_battle_package_end_to_end_validation.py`: `6 passed`

New focused coverage:

- `TargetPlayerOrPlaneswalker` maps to `target=player_or_planeswalker`.
- `TargetPermanent(StaticFilters.FILTER_CREATURE_FLYING)` maps to
  `target=flying_creature`.
- `TargetAttackingOrBlockingCreature` maps to
  `target=attacking_or_blocking_creature`.
- `TargetBlockingCreature` maps to `target=blocking_creature`.
- Activated runtime selection honors `required_keywords=["flying"]` and
  `combat_state="blocking"` constraints before resolving damage.

## PostgreSQL Evidence

Precheck output:

- File: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_precheck.out`
- Result: `22/22` target card rows found.
- Existing expected rows before apply: `0`.
- Shadow rows scheduled for deprecation: `0`.

Apply output:

- File: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_apply.out`
- `deprecated_shadow_rows=0`
- `upserted_rows=22`
- Transaction ended with `COMMIT`.

Postcheck output:

- File: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_postcheck.out`
- `22/22` promoted rule rows.
- `22/22` promoted verified/auto rows.
- `22/22` matching Oracle hash rows.
- Backup rows: `0`, because no pre-existing active rows matched the target
  names.

## Sync And E2E Evidence

PG -> Hermes/SQLite sync:

- JSON: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7349`
- SQLite rows inserted/updated: `7143`
- Canonical snapshot rows exported: `4925`

Package E2E validation:

- Markdown: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_e2e_validation.md`
- JSON: `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_e2e_validation.json`
- Status: `pass`
- PostgreSQL source of truth: `22/22`
- SQLite Hermes cache: `22/22`
- Canonical snapshot fallback: `22/22`
- Runtime `get_card_effect`: `22/22`
- Battle execution no-override: `pass`

## Queue Reduction

Post-PG353 queue:

- `target_identity_count=27164`
- `xmage_authoritative_adapter_required_count=26850`
- `direct_damage::targeted_damage_variant_v1=928`

Post-PG354 queue:

- `target_identity_count=27142`
- `xmage_authoritative_adapter_required_count=26828`
- `direct_damage::targeted_damage_variant_v1=906`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=314`

Measured reduction:

- `22` target identities removed from the global Commander-legal battle-gap
  queue.
- `22` XMage-authoritative adapter-required identities closed.
- `22` direct-damage work-unit identities closed.

Post-PG354 supported splitter recheck:

- File: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg354_supported_recheck.md`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7899`

## Alignment Audits

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  reports `26/26` pass.
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  reports `pass`.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  reports `pass`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave.md`
  reports `pass` with `48` pass and `1` inherited warning for trusted
  executable SQLite rows missing Oracle hash. PG354 rows all carry matching
  Oracle hashes.
