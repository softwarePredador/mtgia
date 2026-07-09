# PG687 Multicolored Keyword Draw Evidence

Status: applied and validated on the new PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

- Family: `xmage_fixed_keyword_draw_card_spell`
- Runtime scope: `xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1`
- Card promoted: `Psychotic Fury`
- Exact XMage pattern: `TargetPermanent(filter)` where `filter` is
  `FilterCreaturePermanent("multicolored creature")` with
  `MulticoloredPredicate.instance`.

## Runtime Changes

- Extended the exact keyword-plus-draw parser to carry target constraints from
  both XMage source and Oracle text.
- Added the restricted multicolored creature target constraint:
  `{"card_types": ["creature"], "color_count_min": 2}`.
- Updated package scenario generation so target keyword draw tests build both a
  matching target and a nonmatching target from the rule constraints.
- Updated the `target_keyword_draw_spell` E2E runner to place a nonmatching
  target on the battlefield and verify it is not modified or granted the
  keyword.

## PostgreSQL Evidence

- Precheck: 1 Oracle-hash-matched card, 0 existing rows, 0 shadow rows.
- Apply: 1 upserted row, 0 deprecated rows.
- Postcheck: 1 promoted row, `verified` and `auto`, with matching Oracle hash.
- PG -> SQLite sync:
  - `pg_rows_loaded`: 6088
  - `sqlite_inserted_or_updated`: 6073
  - `canonical_snapshot_rows_exported`: 6050

## E2E Evidence

`docs/hermes-analysis/master_optimizer_reports/pg687_multicolored_keyword_draw_new_server_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: 1 row validated
- SQLite/Hermes cache: 1 row validated
- Canonical snapshot fallback: 1 card validated
- Runtime `get_card_effect`: 1 card validated
- Battle execution: 1 scenario, 5 events
- `Psychotic Fury` granted `double_strike` to the multicolored target, drew 1
  card, and left the monocolored illegal target unchanged.

## Post-Apply Global Metrics

`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260709_post_pg687_multicolored_keyword_draw_new_server.md`

- `snapshot_has_any_rule`: 7366
- `snapshot_has_verified_rule`: 6176
- `battle_and_oracle_ready`: 6148
- `battle_family_mapper_required`: 27728

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260709_post_pg687_multicolored_keyword_draw_new_server_commander_legal.md`

- Target identities: 24805
- XMage authoritative source: 24492
- Missing-source exceptions: 313
- Parser gaps: 0
- Adapter required: 24492

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg687_multicolored_keyword_draw_new_server_recheck.md`

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

## Verification

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  - `1519 passed, 230 subtests passed`
- `./scripts/quality_gate.sh server-target`
  - pass
- `xmage_strategy_consistency_audit_20260709_post_pg687_multicolored_keyword_draw_new_server_final`
  - pass, 26 checks
- `operational_surface_alignment_audit_20260709_post_pg687_multicolored_keyword_draw_new_server_final`
  - pass
- `legacy_contamination_audit_20260709_post_pg687_multicolored_keyword_draw_new_server_final`
  - pass
- `pg_hermes_sqlite_contract_audit_20260709_post_pg687_multicolored_keyword_draw_new_server_final`
  - pass, 51 checks
