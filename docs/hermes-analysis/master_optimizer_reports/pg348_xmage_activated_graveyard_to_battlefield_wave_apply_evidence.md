# PG348 XMage Activated Graveyard-To-Battlefield Wave Apply Evidence

- Generated UTC: `2026-07-02`
- Deploy ID: `PG348`
- Status: `applied_synced_validated`
- Scope: `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_manifest.json`

Selected cards:

1. `Doomed Necromancer`
2. `Protomatter Powder`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg348_activated_graveyard_to_battlefield_wave.md`
- Proposal count: `2`
- Safe for batch package: `2`
- Family: `xmage_permanent_simple_activated_graveyard_to_battlefield`
- Scope: `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`
- Rows considered by supported splitter before apply: `7937`

The PG348 splitter extension covers exact
`ReturnFromGraveyardToBattlefieldTargetEffect + SimpleActivatedAbility`
battlefield permanents with a single supported self-graveyard target,
source-controller battlefield destination, and mana/tap/source self-sacrifice
costs only.

Blocked neighbors remain explicit:

- `activated_recursion_battlefield_oracle_cost_not_supported`: `5`
- `activated_recursion_battlefield_target_not_supported`: `2`

## PostgreSQL Result

Precheck:

- Target card rows: `2/2`
- Existing expected rows before apply: `0/2`
- Stale shadow rows to deprecate: `0`

Apply/postcheck:

- Deprecated shadow rows: `0`
- Upserted rows: `2`
- Promoted package rows: `2/2`
- Promoted rows verified/auto: `2/2`
- Promoted rows with matching Oracle hash: `2/2`
- Backup rows: `0`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7313`
- SQLite rows inserted/updated: `7107`
- Canonical snapshot rows exported: `4890`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `2/2`
- SQLite Hermes cache: `pass`, `2/2`
- Canonical snapshot fallback: `pass`, `2/2`
- Runtime `get_card_effect`: `pass`, `2/2`
- Battle execution no-override gate: `pass`

Focused tests:

- `python3 -m py_compile ...`: pass for splitter, runtime, focused tests, and package builder.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: `219` tests pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `131` tests pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: pass.

## Post-PG348 Queue Delta

Post-PG348 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg348_activated_graveyard_to_battlefield_wave_recheck.md`
- `battle_and_oracle_ready`: `2446`
- `battle_family_mapper_required`: `30101`
- `snapshot_has_verified_rule`: `3594`

Post-PG348 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg348_activated_graveyard_to_battlefield_wave_commander_legal.md`
- `target_identity_count`: `27178`
- `xmage_authoritative_source_count`: `26864`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26864`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1874`

Post-PG348 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg348_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7935`

The next package must implement another exact runtime-backed subpattern rather
than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=16`. PG348 rows themselves were
validated with matching Oracle hashes.
