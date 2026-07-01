# PG334 XMage Graveyard To Library Spell Wave Apply Evidence

- Generated UTC: `2026-07-01`
- Deploy ID: `PG334`
- Status: `applied_synced_validated`
- Scope: `xmage_put_target_graveyard_card_on_library_spell_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_manifest.json`

Selected cards:

1. `False Mourning`
2. `Reclaim`
3. `Reinforcements`
4. `Salvage`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg334_graveyard_to_library_spell_wave.md`
- Proposal count: `4`
- Safe for batch package: `4`
- Family: `xmage_graveyard_to_library_spell`
- Scope: `xmage_put_target_graveyard_card_on_library_spell_v1`
- Rows considered by supported splitter before apply: `7959`

The PG334 splitter extension covers exact `PutOnLibraryTargetEffect` spells
with no extra ability class, exact self-graveyard Oracle/source agreement, and
top/bottom library destinations. The initial package intentionally covers
spell-only rows; activated permanents such as `Epitaph Golem`,
`Haunted Crossroads`, `Reito Lantern`, and `Tomb Trawler` remain a separate
activation-cost subpattern.

## PostgreSQL Result

Precheck:

- Target card rows: `4/4`
- Existing expected rows before apply: `0/4`
- Stale shadow rows to deprecate: `0`

Apply/postcheck:

- Deprecated shadow rows: `0`
- Upserted rows: `4`
- Promoted package rows: `4/4`
- Promoted rows verified/auto: `4/4`
- Promoted rows with matching Oracle hash: `4/4`
- Backup rows: `0`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7243`
- SQLite rows inserted/updated: `7037`
- Canonical snapshot rows exported: `4832`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `4/4`
- SQLite Hermes cache: `pass`, `4/4`
- Canonical snapshot fallback: `pass`, `4/4`
- Runtime `get_card_effect`: `pass`, `4/4`
- Battle execution no-override gate: `pass`

Focused tests:

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `100` tests pass.
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `171` tests pass.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests pass.
- `python3 -m py_compile ...`: pass for runtime, registry, splitter, and package builder.

## Post-PG334 Queue Delta

Post-PG334 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg334_graveyard_to_library_spell_wave_recheck.md`
- `battle_and_oracle_ready`: `2376`
- `battle_family_mapper_required`: `30171`
- `snapshot_has_verified_rule`: `3524`

Post-PG334 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg334_graveyard_to_library_spell_wave_commander_legal.md`
- `target_identity_count`: `27248`
- `xmage_authoritative_source_count`: `26934`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26934`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1930`

Post-PG334 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg334_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7955`

This means the next package must implement another exact runtime-backed
subpattern rather than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg334_graveyard_to_library_spell_wave_final_docs.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg334_graveyard_to_library_spell_wave_final_docs.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg334_graveyard_to_library_spell_wave_final_docs.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg334_graveyard_to_library_spell_wave_final_docs.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=1418`. PG334 rows themselves were
validated with matching Oracle hashes.
