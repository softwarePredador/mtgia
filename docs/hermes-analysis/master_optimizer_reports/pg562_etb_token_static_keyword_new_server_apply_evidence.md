# PG562 ETB Token Static Keyword New Server Apply Evidence

- Generated at: `2026-07-06T11:14:08Z`
- Deploy id: `pg562`
- Slug: `etb_token_static_keyword_new_server`
- Scopes: `xmage_creature_etb_create_tokens_v1`, `xmage_creature_etb_create_treasure_v1`
- Families: `xmage_creature_etb_create_tokens`, `xmage_creature_etb_create_treasure`
- Cards promoted: `27`
- PostgreSQL target: new server `halder`

## Package

- Candidate split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg562_etb_token_static_keyword_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_manifest.json`
- SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_postcheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_package_rollback.sql`

## PostgreSQL Apply

- Precheck: `27` target card rows, `0` existing rule rows, `0` shadow rows to deprecate.
- Apply: `upserted_rows=27`, `deprecated_shadow_rows=0`.
- Postcheck: all `27` promoted rows have `review_status=verified`, `execution_status=auto`, matching `oracle_hash`, and one promoted rule row per card.
- Backup table:
  `manaloom_deploy_audit.pg562_etb_token_static_keyword_new_serve_20260706_110958`.

## Runtime And Sync

- Splitter now accepts ETB `CreateTokenEffect` rows when `EntersBattlefieldTriggeredAbility` is accompanied only by safe static self keyword abilities.
- The emitted `effect_json` preserves the source creature keywords with `keywords` and `_keywords_are_self` fields while reusing the existing ETB token/Treasure runtime.
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_sync_report.json`
  reported `pg_rows_loaded=9051`, `sqlite_inserted_or_updated=8815`, and `canonical_snapshot_rows_exported=6552`.
- Package E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg562_etb_token_static_keyword_new_server_e2e.md`
  passed `27` scenarios and `27` battle events, validating token/Treasure creation and preserved source keywords.

## Focused Tests

- `python3 -m py_compile` passed for the splitter, battle runtime, package builder, and package E2E validator.
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`: `984` tests passed.
- `python3 -m pytest -q test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`: `60` tests passed.

## Post-Apply Audits

- Post-PG562 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg562_etb_token_static_keyword_new_server.md`
  reports `target_identity_count=25440`, `xmage_authoritative_source_count=25126`, and `xmage_authoritative_adapter_required_count=25126`.
- Post-PG562 exact split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg562_etb_token_static_keyword_recheck.md`
  reports `proposal_count=0` and `safe_for_batch_pg_package_count=0`.
- Global readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg562_etb_token_static_keyword_new_server.md`
  remains `action_required`, expected for the global all-card backlog, with `battle_and_oracle_ready=5510` and `battle_family_mapper_required=28363`.
- Governance gates passed:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md` (`26/26`),
  `pg_hermes_sqlite_contract_audit_20260706_post_pg562_etb_token_static_keyword_new_server_final.md` (`51/51`),
  `operational_surface_alignment_audit_20260706_post_pg562_etb_token_static_keyword_new_server_final.md`,
  `legacy_contamination_audit_20260706_post_pg562_etb_token_static_keyword_new_server_final.md`.

## Cleanup

- Temporary raw queue JSONs are disposable after commit:
  `xmage_authoritative_adaptation_queue_20260706_pg562_candidate_source.json`,
  `xmage_authoritative_adaptation_queue_20260706_pg562_candidate_source_commander_legal.json`, and
  `xmage_authoritative_adaptation_queue_20260706_post_pg562_etb_token_static_keyword_new_server.json`.
- Compact Markdown summaries, package SQL, manifest, sync, E2E, readiness, and audit evidence are kept.
