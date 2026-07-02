# PG349 XMage Graveyard Self-Return Discard Battlefield Wave Apply Evidence

- Generated UTC: `2026-07-02`
- Deploy ID: `PG349`
- Status: `applied_synced_validated`
- Scope: `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_manifest.json`

Selected cards:

1. `Advanced Stitchwing`
2. `Ghoulsteed`
3. `Stitchwing Skaab`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg349_graveyard_self_return_discard_battlefield_wave.md`
- Proposal count: `3`
- Safe for batch package: `3`
- Family: `xmage_graveyard_simple_activated_self_return_to_battlefield`
- Scope: `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`
- Rows considered by supported splitter before apply: `7935`

The PG349 splitter extension covers exact
`ReturnSourceFromGraveyardToBattlefieldEffect + SimpleActivatedAbility`
graveyard self-return creatures with a `ManaCostsImpl` activation cost plus
exact `DiscardTargetCost(new TargetCardInHand(2, StaticFilters.FILTER_CARD_CARDS))`.
The runtime now treats the two-card discard as a real activation cost before
moving the source from graveyard to battlefield.

Blocked neighbors remain explicit:

- `graveyard_self_return_battlefield_ability_class_not_simple`: `2`
- `graveyard_self_return_battlefield_oracle_not_simple`: `1` (`Bone Dragon`)

## PostgreSQL Result

Precheck:

- Target card rows: `3/3`
- Existing expected rows before apply: `0/3`
- Stale shadow rows to deprecate: `0`

Apply/postcheck:

- Deprecated shadow rows: `0`
- Upserted rows: `3`
- Promoted package rows: `3/3`
- Promoted rows verified/auto: `3/3`
- Promoted rows with matching Oracle hash: `3/3`
- Backup rows: `0`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7316`
- SQLite rows inserted/updated: `7110`
- Canonical snapshot rows exported: `4893`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `3/3`
- SQLite Hermes cache: `pass`, `3/3`
- Canonical snapshot fallback: `pass`, `3/3`
- Runtime `get_card_effect`: `pass`, `3/3`
- Battle execution no-override gate: `pass`

Focused tests:

- `python3 -m py_compile ...`: pass for splitter, runtime, focused tests, and package builder.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: `221` tests pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `133` tests pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: pass.

## Post-PG349 Queue Delta

Post-PG349 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_recheck.md`
- `battle_and_oracle_ready`: `2449`
- `battle_family_mapper_required`: `30098`
- `snapshot_has_verified_rule`: `3597`

Post-PG349 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_commander_legal.md`
- `target_identity_count`: `27175`
- `xmage_authoritative_source_count`: `26861`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26861`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1871`

Post-PG349 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg349_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7932`

The next package must implement another exact runtime-backed subpattern rather
than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=16`. PG349 rows themselves were
validated with matching Oracle hashes.
