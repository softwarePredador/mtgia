# PG741 Beginning End Step Conditional Draw Evidence - 2026-07-11

Status: `applied_validated_synced`.

## Scope

PG741 promotes the exact XMage subpattern:

- `DrawCardSourceControllerEffect`
- `BeginningOfEndStepTriggeredAbility`
- fixed draw one card
- runtime-checkable end-step condition
- `battle_model_scope=xmage_beginning_end_step_conditional_draw_v1`

Promoted cards:

- `Deathreap Ritual`
- `Mercadian Atlas`
- `Owlbear Shepherd`
- `Sygg, River Cutthroat`
- `The Gaffer`
- `Twinblade Assassins`
- `Well of Discovery`

Held back by design:

- `April O'Neil, Hacktivist`: dynamic draw count.
- `Narset, Jeskai Waymaster`: dynamic draw count / additional hand handling.
- `Vaultguard Trooper`: discard-hand cost and draw two branch.

## Code Changes

- Added exact-scope split support in `xmage_authoritative_exact_scope_split.py`.
- Added runtime end-step condition executor in `battle_analyst_v9.py`.
- Added package manifest/E2E scenario support in `xmage_batch_pg_package_builder.py`.
- Added E2E runner in `battle_package_end_to_end_validation.py`.
- Added focused parser, runtime, builder, and validator tests.

## PostgreSQL Apply

Package:

- `docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_rollback.sql`

Precheck:

- 7/7 proposed cards resolved to exactly one Oracle-hash-matched PostgreSQL card row.
- Existing shadow rows before apply: 2 for `Deathreap Ritual`, 2 for `The Gaffer`.

Apply:

- Backup rows: 4.
- Deprecated stale shadow rows: 4.
- Upserted verified/auto rows: 7.

Postcheck:

- 7/7 promoted rows present.
- 7/7 promoted rows are `review_status=verified` and `execution_status=auto`.
- 7/7 promoted rows retain the expected `oracle_hash`.

## Hermes And E2E

Sync reports:

- `docs/hermes-analysis/master_optimizer_reports/sync_battle_card_rules_pg741_beginning_end_step_draw_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/sync_pg_card_metadata_pg741_beginning_end_step_draw_new_server.json`

Sync results:

- PG -> SQLite loaded rows: 7.
- SQLite inserted/updated rows: 7.
- Canonical snapshot rows exported: 6301.
- Metadata sync target: `127.0.0.1:15432/halder`.
- Metadata sync requested unique names: 7261.
- SQLite cache alias rows: 7366.

E2E validation:

- `docs/hermes-analysis/master_optimizer_reports/battle_package_e2e_validation_pg741_beginning_end_step_draw_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_package_e2e_validation_pg741_beginning_end_step_draw_new_server.md`
- Status: `pass`.
- PostgreSQL source of truth: 7/7.
- SQLite Hermes cache: 7/7.
- Canonical snapshot fallback: 7/7.
- Runtime `get_card_effect`: 7/7.
- Battle execution scenarios: 7/7.

## Global Impact

Before PG741:

- `battle_and_oracle_ready=6394`
- `battle_family_mapper_required=27482`
- `snapshot_has_verified_rule=6419`
- Commander-legal XMage adapter required: 24246
- `draw_engine::xmage_draw_card_variant_review_v1=1561`

After PG741:

- `battle_and_oracle_ready=6401`
- `battle_family_mapper_required=27475`
- `snapshot_has_verified_rule=6426`
- Strict function + verified rule cards: 4906
- Commander-legal XMage adapter required: 24239
- `draw_engine::xmage_draw_card_variant_review_v1=1554`

## Validation Commands

Passed:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k end_step`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_xmage_exact_scope_runtime.py -k beginning_end_step`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m pytest -q test_xmage_batch_pg_package_builder.py -k beginning_end_step`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m pytest -q test_battle_package_end_to_end_validation.py -k beginning_end_step`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_sync_battle_card_rules_manual_preserve.py test_sync_battle_card_rules_pg_selection.py`
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m unittest test_sync_pg_card_metadata_to_hermes.py`
- `./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py --manifest docs/hermes-analysis/master_optimizer_reports/pg741_beginning_end_step_draw_new_server_package_manifest.json --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --snapshot docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json --output-json docs/hermes-analysis/master_optimizer_reports/battle_package_e2e_validation_pg741_beginning_end_step_draw_new_server.json --output-md docs/hermes-analysis/master_optimizer_reports/battle_package_e2e_validation_pg741_beginning_end_step_draw_new_server.md`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260711_post_pg741_beginning_end_step_draw_new_server`
- `./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260711_post_pg741_beginning_end_step_draw_new_server`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260711_post_pg741_beginning_end_step_draw_new_server`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260711_post_pg741_beginning_end_step_draw_new_server`

Audit results:

- XMage strategy consistency: `pass`, 26/26.
- PG/Hermes/SQLite contract: `pass`, 51/51.
- Operational surface alignment: `pass`.
- Legacy contamination: `pass`.
