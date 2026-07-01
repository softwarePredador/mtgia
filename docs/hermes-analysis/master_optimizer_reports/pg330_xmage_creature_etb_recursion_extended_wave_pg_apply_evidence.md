# PG330 XMage Creature ETB Recursion Extended Wave Apply Evidence

- Generated UTC: `2026-07-01`
- Deploy ID: `PG330`
- Status: `applied_synced_validated`
- Scope: `xmage_creature_etb_return_graveyard_card_to_hand_v1`

## Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_package.md`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_postcheck.sql`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_manifest.json`

Selected cards:

1. `Barrow Witches`
2. `Disciple of the Sun`
3. `Leonin Squire`
4. `Pillardrop Rescuer`
5. `Ragamuffin Raptor`
6. `Scholar of the Ages`
7. `Strongarm Thug`

## Source Split

- Split report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg330_creature_etb_recursion_extended_wave.md`
- Proposal count: `7`
- Safe for batch package: `7`
- Family: `xmage_creature_etb_graveyard_to_hand`
- Scope: `xmage_creature_etb_return_graveyard_card_to_hand_v1`
- Rows considered by supported splitter before apply: `7981`

The PG330 splitter extension covers exact creature ETB graveyard-to-hand
recursion where XMage and Oracle agree on one of these constrained targets:
subtype card (`Knight`, `Mercenary`), artifact/permanent/creature cards with
mana-value ceilings, instant and/or sorcery cards, and creature-or-Food cards.

## PostgreSQL Result

- Promoted package rows: `7/7`.
- Promoted rows verified/auto: `7/7`.
- Promoted rows with matching Oracle hash: `7/7`.
- Stale shadow rows deprecated: `0`.

Post-apply proof is the PG330 E2E validation, which re-read PostgreSQL source
of truth and validated `7` package rows:

- E2E: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_e2e_validation.md`
- PostgreSQL stage: `pass`, `validated_rows=7`

## PG -> Hermes/SQLite Sync

- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7224`
- SQLite rows inserted/updated: `7018`
- Canonical snapshot rows exported: `4815`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## E2E Validation

`docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_e2e_validation.md`:

- PostgreSQL source of truth: `pass`, `7/7`
- SQLite Hermes cache: `pass`, `7/7`
- Canonical snapshot fallback: `pass`, `7/7`
- Runtime `get_card_effect`: `pass`, `7/7`
- Battle execution no-override gate: `pass`

## Post-PG330 Queue Delta

Post-PG330 readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg330_creature_etb_recursion_extended_wave_recheck.md`
- `battle_and_oracle_ready`: `2357`
- `battle_family_mapper_required`: `30190`
- `snapshot_has_verified_rule`: `3505`

Post-PG330 authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg330_creature_etb_recursion_extended_wave_commander_legal.md`
- `target_identity_count`: `27267`
- `xmage_authoritative_source_count`: `26953`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26953`
- Top remaining work unit: `recursion::xmage_graveyard_return_variant_review_v1` with `1949`.

Post-PG330 supported splitter recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg330_supported_recheck.md`
- `proposal_count`: `0`
- Rows considered: `7974`

This means the next package must implement another exact runtime-backed
subpattern rather than rerunning the current splitter unchanged.

## Final Audits

- XMage strategy audit: `pass`, `26/26`.
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`
- Operational surface audit: `pass`, `35/35`.
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`
- PG/Hermes/SQLite contract audit: `pass`, `48 pass / 1 warn`.
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`
- Legacy contamination audit: `pass`, `28/28`.
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`

The remaining PG/Hermes/SQLite warning is inherited:
`trusted_executable_rules_missing_oracle_hash=1418`. PG330 rows themselves were
validated with matching Oracle hashes.
