# PG332 XMage Graveyard Exile Wave Apply Evidence

- Generated UTC: `2026-07-01`
- Deploy ID: `PG332`
- Status: `applied_synced_validated`
- Scope: `xmage_permanent_simple_activated_exile_graveyard_card_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_manifest.json`

Selected cards:

1. `Carrion Beetles`
2. `Crypt Creeper`
3. `Famished Ghoul`
4. `Heap Doll`
5. `Rag Dealer`
6. `Thraben Heretic`
7. `Withered Wretch`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg332_graveyard_exile_wave.md`
- Proposal count: `7`
- Safe for batch package: `7`
- Family: `xmage_permanent_simple_activated_graveyard_exile`
- Scope: `xmage_permanent_simple_activated_exile_graveyard_card_v1`
- Rows considered by supported splitter before apply: `7969`

The PG332 splitter extension covers exact permanent simple activated
graveyard-exile effects where XMage and Oracle agree on a target card or
target creature card in a graveyard, with mana, tap, and source self-sacrifice
costs only.

Blocked neighbors remain explicit:

- `Martyr of Bones`: `activated_graveyard_exile_oracle_not_simple`
- `Mortiphobia`: `activated_graveyard_exile_oracle_not_simple`
- `Steamclaw`: `activated_graveyard_exile_oracle_not_simple`

## PostgreSQL Result

Precheck:

- Target card rows: `7/7`
- Existing expected rows before apply: `0/7`
- Stale shadow rows to deprecate: `0`

Apply/postcheck:

- Deprecated shadow rows: `0`
- Upserted rows: `7`
- Promoted package rows: `7/7`
- Promoted rows verified/auto: `7/7`
- Promoted rows with matching Oracle hash: `7/7`
- Backup rows: `0`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7236`
- SQLite rows inserted/updated: `7030`
- Canonical snapshot rows exported: `4826`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `7/7`
- SQLite Hermes cache: `pass`, `7/7`
- Canonical snapshot fallback: `pass`, `7/7`
- Runtime `get_card_effect`: `pass`, `7/7`
- Battle execution no-override gate: `pass`

Focused tests:

- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `96` tests pass.
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `166` tests pass.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: `4` tests pass.

## Post-PG332 Queue Delta

Post-PG332 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg332_graveyard_exile_wave_recheck.md`
- `battle_and_oracle_ready`: `2369`
- `battle_family_mapper_required`: `30178`
- `snapshot_has_verified_rule`: `3517`

Post-PG332 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg332_graveyard_exile_wave_commander_legal.md`
- `target_identity_count`: `27255`
- `xmage_authoritative_source_count`: `26941`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26941`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1937`

Post-PG332 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg332_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7962`

This means the next package must implement another exact runtime-backed
subpattern rather than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=1418`. PG332 rows themselves were
validated with matching Oracle hashes.
