# PG336 XMage Activated Graveyard-To-Library Wave Apply Evidence

- Generated at: `2026-07-01T23:01:12Z`
- Deploy id: `pg336_xmage_activated_graveyard_to_library_wave`
- Scope: `xmage_permanent_simple_activated_graveyard_to_library_v1`
- Cards: `Epitaph Golem`, `Haunted Crossroads`, `Tomb Trawler`

## Source Split

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg336_activated_graveyard_to_library_wave.md`
- `proposal_count=3`
- `safe_for_batch_pg_package_count=3`
- Family counts:
  `{"xmage_permanent_simple_activated_graveyard_to_library": 3}`

The two residual `PutOnLibraryTargetEffect + SimpleActivatedAbility` rows are
blocked as `activated_graveyard_to_library_oracle_not_simple` because they use
`a graveyard` and `owner's library`, which is a different runtime contract from
the self-graveyard/self-library scope promoted here.

## PostgreSQL Package

- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_manifest.json`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_precheck.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_apply.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_postcheck.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_rollback.sql`

Precheck result:

- `target_card_rows=1` for each selected card.
- `expected_rule_rows_before=0` for each selected card.
- `would_deprecate_shadow_rows=0` for each selected card.

Apply result:

- transaction result: `COMMIT`
- `deprecated_shadow_rows=0`
- `upserted_rows=3`

Postcheck result:

- `promoted_rule_rows=1` for each selected card.
- `promoted_verified_auto_rows=1` for each selected card.
- `promoted_oracle_hash_rows=1` for each selected card.
- `backup_rows=0`

## Sync And E2E

PG -> SQLite sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_pg_to_sqlite_sync.json`
- `pg_rows_loaded=7249`
- `sqlite_inserted_or_updated=7043`
- `canonical_snapshot_rows_exported=4838`

E2E validation:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_e2e_validation.md`
- Status: `pass`
- PostgreSQL source of truth: `3/3`
- SQLite Hermes cache: `3/3`
- Canonical snapshot fallback: `3/3`
- Runtime `get_card_effect`: `3/3`

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py`: `178` tests, `OK`
- `python3 -m unittest test_xmage_exact_scope_runtime.py`: `107` tests, `OK`
- `python3 -m pytest test_xmage_batch_pg_package_builder.py`: `4` tests, `passed`

## Queue Reduction

Post-PG335 baseline:

- `target_identity_count=27245`
- `xmage_authoritative_adapter_required_count=26931`
- `recursion::xmage_graveyard_return_variant_review_v1=1927`

Post-PG336 recheck:

- Readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg336_activated_graveyard_to_library_wave_recheck.md`
- Authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg336_activated_graveyard_to_library_wave_commander_legal.md`
- `target_identity_count=27242`
- `xmage_authoritative_adapter_required_count=26928`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=314`
- `recursion::xmage_graveyard_return_variant_review_v1=1924`

Current splitter recheck after PG336:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg336_supported_recheck.md`
- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7949`

## Alignment Audits

- XMage strategy consistency:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`
  - status: `pass`
  - `26/26` checks pass
- Operational surface alignment:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`
  - status: `pass`
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`
  - status: `pass`
  - `48 pass`, `1 warn`
  - warning is the known global residual
    `trusted_executable_rules_missing_oracle_hash=1418`; all PG336 rows have
    matching `oracle_hash`.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`
  - status: `pass`

## Next Queue Signal

The next cycle must add a new exact subpattern. Rerunning the current splitter
unchanged on the post-PG336 queue returns no package candidates.

Top remaining work unit:

- `recursion::xmage_graveyard_return_variant_review_v1=1924`

Top remaining global lanes:

- `draw_engine::xmage_draw_card_variant_review_v1=1660`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1=1162`
- `direct_damage::targeted_damage_variant_v1=928`
- `add_counters::source_add_counters_variant_v1=795`
