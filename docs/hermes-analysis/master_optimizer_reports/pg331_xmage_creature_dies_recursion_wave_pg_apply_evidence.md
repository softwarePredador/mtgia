# PG331 XMage Creature Dies Recursion Wave Apply Evidence

- Generated UTC: `2026-07-01`
- Deploy ID: `PG331`
- Status: `applied_synced_validated`
- Scope: `xmage_creature_dies_return_graveyard_card_to_hand_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_manifest.json`

Selected cards:

1. `Dutiful Attendant`
2. `Elderfang Ritualist`
3. `Living Lightning`
4. `Myr Retriever`
5. `Workshop Assistant`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg331_creature_dies_recursion_wave.md`
- Proposal count: `5`
- Safe for batch package: `5`
- Family: `xmage_creature_dies_graveyard_to_hand`
- Scope: `xmage_creature_dies_return_graveyard_card_to_hand_v1`
- Rows considered by supported splitter before apply: `7974`

The PG331 splitter extension covers exact creature dies triggered
graveyard-to-hand recursion where XMage and Oracle agree on a single target
card from the controller's graveyard to hand. It supports creature, Elf,
instant/sorcery, and artifact targets, and records whether the dying source
itself must be excluded from target selection.

Blocked neighbors remain explicit:

- `Carrion Thrash`: `dies_recursion_optional_cost_not_supported`
- `Junk Diver`: `dies_recursion_target_not_supported`

## PostgreSQL Result

Precheck:

- Target card rows: `5/5`
- Existing expected rows before apply: `0/5`
- Stale shadow rows to deprecate: `2`, both under `Myr Retriever`

Apply/postcheck:

- Deprecated shadow rows: `2`
- Upserted rows: `5`
- Promoted package rows: `5/5`
- Promoted rows verified/auto: `5/5`
- Promoted rows with matching Oracle hash: `5/5`
- Backup rows: `2`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7229`
- SQLite rows inserted/updated: `7023`
- Canonical snapshot rows exported: `4819`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `5/5`
- SQLite Hermes cache: `pass`, `5/5`
- Canonical snapshot fallback: `pass`, `5/5`
- Runtime `get_card_effect`: `pass`, `5/5`
- Battle execution no-override gate: `pass`

## Post-PG331 Queue Delta

Post-PG331 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg331_creature_dies_recursion_wave_recheck.md`
- `battle_and_oracle_ready`: `2362`
- `battle_family_mapper_required`: `30185`
- `snapshot_has_verified_rule`: `3510`

Post-PG331 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg331_creature_dies_recursion_wave_commander_legal.md`
- `target_identity_count`: `27262`
- `xmage_authoritative_source_count`: `26948`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26948`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1944`

Post-PG331 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg331_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7969`

This means the next package must implement another exact runtime-backed
subpattern rather than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`
- Operational surface audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`
- Legacy contamination audit: `pass`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=1418`. PG331 rows themselves were
validated with matching Oracle hashes.
