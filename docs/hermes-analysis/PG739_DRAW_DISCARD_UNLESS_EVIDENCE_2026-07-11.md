# PG739 Draw Discard Unless Evidence - 2026-07-11

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` through
`server/bin/with_new_server_pg.sh`.

## Runtime Scope

PG739 extends the existing fixed draw/discard spell scope for XMage cards that
draw three cards, then discard two cards unless the controller discards one
matching card type.

- Family: `xmage_fixed_draw_discard_spell`
- Scope: `xmage_fixed_draw_discard_spell_v1`
- Cards: `Mystic Meditation`, `Thirst for Discovery`, `Thirst for Identity`,
  `Thirst for Knowledge`, `Thirst for Meaning`
- XMage signature: `DrawCardSourceControllerEffect(3)` followed by
  `DoIfCostPaid(... DiscardControllerEffect(2), DiscardCardCost(filter))`
- Supported filters:
  - creature card
  - basic land card
  - artifact card
  - enchantment card
- Runtime behavior:
  - draws first, then resolves the discard step
  - if a matching discard-unless card is available, discards one matching card
  - otherwise falls back to the normal `discard_count=2` path
  - preserves original `discard_count=2` in `effect_json`

## Package Evidence

Splitter and package artifacts:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg739_draw_discard_unless_new_server_candidate.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg739_draw_discard_unless_new_server_candidate.md`
- `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_package_rollback.sql`

Package results:

- Splitter selected `5` proposals.
- Precheck found `5` Oracle-hash-matched targets.
- Precheck found `2` stale `Thirst for Knowledge` shadow rows to deprecate.
- Apply deprecated `2` stale shadow rows.
- Apply upserted `5` verified executable rows.
- Postcheck confirmed `5/5` promoted verified/auto rows with matching
  `oracle_hash`.

## Focused Tests

Commands:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py`
- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py -k fixed_draw_discard_spell`
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k draw_discard_spell`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k fixed_draw_discard`
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k fixed_draw_discard`

Focused test results:

- Splitter fixed draw/discard tests: `6` passed.
- Runtime draw/discard spell tests: `4` passed.
- Package builder fixed draw/discard tests: `2` passed.
- Battle package fixed draw/discard E2E tests: `2` passed.
- `git diff --check` for touched runtime/test files: `pass`.

## Sync And E2E Evidence

Metadata sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_metadata_sync.json`
- PostgreSQL cards matched: `7426`
- SQLite cache alias rows: `7348`
- `deck_cards`: `2699/2699` matched, `96` card-id updates

Battle-rule sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_battle_rule_sync_report.json`
- `pg_rows_loaded=6339`
- `sqlite_inserted_or_updated=6334`
- `canonical_snapshot_rows_exported=6290`

Package E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_e2e.json`
- Markdown: `docs/hermes-analysis/master_optimizer_reports/pg739_draw_discard_unless_new_server_e2e.md`
- Status: `pass`
- PostgreSQL rows validated: `5`
- SQLite/Hermes rows validated: `5`
- Canonical snapshot rows validated: `5`
- Runtime `get_card_effect` rows validated: `5`
- Battle execution scenarios: `5`
- Battle execution confirmed each promoted card drew `3` and discarded `1`
  matching card through the discard-unless path.

## Current Global Queue After PG739

Readiness:

- `battle_and_oracle_ready=6388`
- `battle_family_mapper_required=27488`
- `generic_runtime_or_no_card_rule=359`
- `commander_illegal_block=2997`
- `official_oracle_identity_unavailable=3`
- `snapshot_has_any_rule=7584`
- `snapshot_has_verified_rule=6413`

XMage authoritative queue:

- `target_identity_count=24565`
- `xmage_authoritative_source_count=24252`
- `xmage_authoritative_adapter_required_count=24252`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`
- `adapter_work_unit_count=11295`
- `draw_cards::xmage_draw_card_variant_review_v1=547`

Validation gates:

- `xmage_strategy_consistency_audit_20260711_post_pg739_draw_discard_unless_new_server`: `pass`, `26/26`
- `pg_hermes_sqlite_contract_audit_20260711_post_pg739_draw_discard_unless_new_server`: `pass`, `51/51`
- `operational_surface_alignment_audit_20260711_post_pg739_draw_discard_unless_new_server`: `pass`
- `legacy_contamination_audit_20260711_post_pg739_draw_discard_unless_new_server`: `pass`
- `./scripts/quality_gate.sh server-target`: `pass`

## Next Queue Signal

The next work should be chosen from the refreshed post-PG739 authoritative
queue, not from stale PG738B artifacts. The largest remaining work units are:

- `recursion::xmage_graveyard_return_variant_review_v1=1792`
- `draw_engine::xmage_draw_card_variant_review_v1=1567`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1=1064`
- `add_counters::source_add_counters_variant_v1=768`
- `direct_damage::targeted_damage_variant_v1=750`
