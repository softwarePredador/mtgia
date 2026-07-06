# PG563 Regenerate Static Keyword New Server Apply Evidence

- Generated at: `2026-07-06T11:28:30Z`
- Deploy id: `pg563`
- Slug: `regenerate_static_keyword_new_server`
- Scope: `xmage_permanent_simple_activated_regenerate_source_v1`
- Family: `xmage_permanent_simple_activated_regenerate_source`
- Cards promoted: `22`
- PostgreSQL target: new server `halder`

## Package

- Candidate split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg563_regenerate_static_keyword_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_manifest.json`
- SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_postcheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_package_rollback.sql`

## PostgreSQL Apply

- Precheck: `22` target card rows, `0` existing rule rows, `0` shadow rows to deprecate.
- Apply: `upserted_rows=22`, `deprecated_shadow_rows=0`.
- Postcheck: all `22` promoted rows have `review_status=verified`, `execution_status=auto`, matching `oracle_hash`, and one promoted rule row per card.
- Backup table:
  `manaloom_deploy_audit.pg563_regenerate_static_keyword_new_serv_20260706_112424`.

## Runtime And Sync

- The splitter now accepts `RegenerateSourceEffect + SimpleActivatedAbility`
  rows when the only auxiliary abilities are safe static self keywords and
  the row has no targeting signal.
- The emitted `effect_json` preserves those source creature keywords with
  `keywords`, `_keywords_are_self`, and boolean keyword flags while reusing
  the existing simple activated regenerate-source runtime.
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_sync_report.json`
  reported `pg_rows_loaded=9073`, `sqlite_inserted_or_updated=8837`, and
  `canonical_snapshot_rows_exported=6574`.
- Package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg563_regenerate_static_keyword_new_server_e2e.md`
  passed `22` scenarios and `44` battle events, validating PG source of
  truth, Hermes SQLite cache, canonical snapshot fallback, runtime lookup,
  and regenerate-source battle execution.

## Focused Tests

- `python3 -m py_compile` passed for the splitter, battle runtime, package
  builder, and package E2E validator.
- Focused regenerate-source splitter/runtime tests: `5` tests passed.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`: `986` tests passed.
- `python3 -m pytest -q test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`: `60` tests passed.

## Post-Apply Audits

- Post-PG563 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg563_regenerate_static_keyword_new_server.md`
  reports `target_identity_count=25418`, `xmage_authoritative_source_count=25104`, and `xmage_authoritative_adapter_required_count=25104`.
- Post-PG563 exact split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg563_regenerate_static_keyword_recheck.md`
  reports `proposal_count=0` and `safe_for_batch_pg_package_count=0`.
- Global readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg563_regenerate_static_keyword_new_server.md`
  remains `action_required`, expected for the global all-card backlog, with
  `battle_and_oracle_ready=5532` and `battle_family_mapper_required=28341`.
- Governance gates passed:
  `xmage_strategy_consistency_audit_20260706_post_pg563_regenerate_static_keyword_new_server_final.md` (`26/26`),
  `pg_hermes_sqlite_contract_audit_20260706_post_pg563_regenerate_static_keyword_new_server_final.md` (`51/51`),
  `operational_surface_alignment_audit_20260706_post_pg563_regenerate_static_keyword_new_server_final.md`,
  `legacy_contamination_audit_20260706_post_pg563_regenerate_static_keyword_new_server_final.md`.

## Cleanup

- Temporary raw queue JSONs are disposable after commit:
  `xmage_authoritative_adaptation_queue_20260706_pg563_candidate_source.json`,
  `xmage_authoritative_adaptation_queue_20260706_post_pg563_regenerate_static_keyword_new_server.json`,
  and the probe split files
  `xmage_authoritative_exact_scope_split_20260706_pg563_candidate_probe.{json,md}`.
- Compact Markdown summaries, package SQL, manifest, sync, E2E, readiness,
  and audit evidence are kept.
