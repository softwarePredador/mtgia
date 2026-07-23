# PG561 Regenerate Source New Server Apply Evidence

- Generated at: `2026-07-06T10:53:57Z`
- Deploy id: `pg561_regenerate_source_new_server`
- Scope: `xmage_permanent_simple_activated_regenerate_source_v1`
- Family: `xmage_permanent_simple_activated_regenerate_source`
- Cards promoted: `24`
- PostgreSQL target: new server `halder`

## Package

- Candidate split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg561_regenerate_source_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_manifest.json`
- SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_postcheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_package_rollback.sql`

## PostgreSQL Apply

- Precheck: `24` target card rows, `0` existing rule rows, `0` shadow rows to deprecate.
- Apply: `upserted_rows=24`, `deprecated_shadow_rows=0`.
- Postcheck: all `24` promoted rows have `review_status=verified`, `execution_status=auto`, matching `oracle_hash`, and one promoted rule row per card.
- Backup table:
  `manaloom_deploy_audit.pg561_regenerate_source_new_server_pg561_20260706_105239`.

## Runtime And Sync

- Runtime added explicit simple activated regeneration support:
  activation creates an until-EOT regeneration shield; destroy/damage consumes the shield, taps the creature, removes it from combat, clears damage, and leaves it on the battlefield.
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_sync_report.json`
  reported `pg_rows_loaded=9024`, `sqlite_inserted_or_updated=8788`, and `canonical_snapshot_rows_exported=6525`.
- Package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg561_regenerate_source_new_server_e2e.md`
  passed `24` scenarios and `48` battle events. Each promoted card activated regeneration, then survived a destroy event on the battlefield with the shield consumed.

## Focused Tests

- `python3 -m py_compile` passed for the splitter, battle runtime, package builder, and package E2E validator.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`: `983` tests passed.
- `python3 -m pytest -q test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`: `60` tests passed.

## Post-Apply Audits

- Post-PG561 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg561_regenerate_source_new_server.md`
  reports `target_identity_count=25467`, `xmage_authoritative_source_count=25153`, and `xmage_authoritative_adapter_required_count=25153`.
- Post-PG561 exact split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg561_regenerate_source_recheck.md`
  reports `proposal_count=0` and `safe_for_batch_pg_package_count=0` for the currently implemented exact scopes in this pass.
- Global readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg561_regenerate_source_new_server.md`
  remains `action_required`, expected for the global all-card backlog, with `battle_and_oracle_ready=5483` and `battle_family_mapper_required=28390`.
- Governance gates passed:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md` (`26/26`),
  `pg_hermes_sqlite_contract_audit_20260706_post_pg561_regenerate_source_new_server_final.md` (`51/51`),
  `operational_surface_alignment_audit_20260706_post_pg561_regenerate_source_new_server_final.md`,
  `legacy_contamination_audit_20260706_post_pg561_regenerate_source_new_server_final.md`.

## Cleanup

- Removed temporary raw queue JSONs:
  `xmage_authoritative_adaptation_queue_20260706_pg561_candidate_source.json` and
  `xmage_authoritative_adaptation_queue_20260706_post_pg561_regenerate_source_new_server.json`.
- Kept compact Markdown summaries and package/evidence files only.
