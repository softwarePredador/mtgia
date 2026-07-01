# PG333 XMage Graveyard Self-Return Battlefield Wave Apply Evidence

- Generated UTC: `2026-07-01`
- Deploy ID: `PG333`
- Status: `applied_synced_validated`
- Scope: `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_manifest.json`

Selected cards:

1. `Persistent Specimen`
2. `Reassembling Skeleton`
3. `Tunnel Rats`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg333_graveyard_self_return_battlefield_wave.md`
- Proposal count: `3`
- Safe for batch package: `3`
- Family: `xmage_graveyard_simple_activated_self_return_to_battlefield`
- Scope: `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`
- Rows considered by supported splitter before apply: `7962`

The PG333 splitter extension covers exact `ReturnSourceFromGraveyardToBattlefieldEffect`
cards with `SimpleActivatedAbility` in `Zone.GRAVEYARD`, mana-only activation
costs, exact self-return Oracle/source agreement, and tapped battlefield entry.

Blocked neighbors remain explicit:

- `graveyard_self_return_battlefield_ability_class_not_simple`: `2`
- `graveyard_self_return_battlefield_oracle_not_simple`: `4`

## PostgreSQL Result

Precheck:

- Target card rows: `3/3`
- Existing expected rows before apply: `0/3`
- Stale shadow rows to deprecate: `2`

Apply/postcheck:

- Deprecated shadow rows: `2`
- Upserted rows: `3`
- Promoted package rows: `3/3`
- Promoted rows verified/auto: `3/3`
- Promoted rows with matching Oracle hash: `3/3`
- Backup rows: `2`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7239`
- SQLite rows inserted/updated: `7033`
- Canonical snapshot rows exported: `4828`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `3/3`
- SQLite Hermes cache: `pass`, `3/3`
- Canonical snapshot fallback: `pass`, `3/3`
- Runtime `get_card_effect`: `pass`, `3/3`
- Battle execution no-override gate: `pass`

Focused tests:

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `98` tests pass.
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `168` tests pass.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests pass.
- `python3 -m py_compile ...`: pass for runtime, registry, splitter, and package builder.

## Post-PG333 Queue Delta

Post-PG333 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg333_graveyard_self_return_battlefield_wave_recheck.md`
- `battle_and_oracle_ready`: `2372`
- `battle_family_mapper_required`: `30175`
- `snapshot_has_verified_rule`: `3520`

Post-PG333 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg333_graveyard_self_return_battlefield_wave_commander_legal.md`
- `target_identity_count`: `27252`
- `xmage_authoritative_source_count`: `26938`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26938`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1934`

Post-PG333 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg333_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7959`

This means the next package must implement another exact runtime-backed
subpattern rather than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=1418`. PG333 rows themselves were
validated with matching Oracle hashes.
