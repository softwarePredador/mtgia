# PG686 Keyword Draw Evidence

Status: applied and validated on the new PostgreSQL target
`127.0.0.1:15432/halder`.

## Scope

- Family: `xmage_fixed_keyword_draw_card_spell`
- Runtime scope: `xmage_fixed_keyword_target_creature_until_eot_draw_card_spell_v1`
- Card promoted: `Poison the Blade`
- Remaining related block: `Psychotic Fury` still requires multicolored target
  filter support and was not promoted by this batch.

## Runtime Changes

- Allowed exact XMage source parsing for `GainAbilityTargetEffect(...)` without
  an explicit `Duration.EndOfTurn` argument when Oracle text fixes the duration
  as until end of turn.
- Added package scenario type `target_keyword_draw_spell`.
- Added battle package runner coverage that verifies keyword grant, unchanged
  power/toughness for keyword-only effects, draw count, library decrement, and
  composite draw events.

## PostgreSQL Evidence

- Precheck: 1 Oracle-hash-matched card, 0 existing rows, 0 shadow rows.
- Apply: 1 upserted row, 0 deprecated rows.
- Postcheck: 1 promoted row, `verified` and `auto`, with matching Oracle hash.
- PG -> SQLite sync:
  - `pg_rows_loaded`: 6087
  - `sqlite_inserted_or_updated`: 6072
  - `canonical_snapshot_rows_exported`: 6049

## E2E Evidence

`docs/hermes-analysis/master_optimizer_reports/pg686_keyword_draw_new_server_e2e_validation.md`

- Status: `pass`
- PostgreSQL source of truth: 1 row validated
- SQLite/Hermes cache: 1 row validated
- Canonical snapshot fallback: 1 card validated
- Runtime `get_card_effect`: 1 card validated
- Battle execution: 1 scenario, 5 events
- `Poison the Blade` granted `deathtouch` and drew 1 card from the controller
  library.

## Post-Apply Global Metrics

`docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260709_post_pg686_keyword_draw_new_server.md`

- `snapshot_has_any_rule`: 7365
- `snapshot_has_verified_rule`: 6175
- `battle_and_oracle_ready`: 6147
- `battle_family_mapper_required`: 27729

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260709_post_pg686_keyword_draw_new_server_commander_legal.md`

- Target identities: 24806
- XMage authoritative source: 24493
- Missing-source exceptions: 313
- Parser gaps: 0
- Adapter required: 24493

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg686_keyword_draw_new_server_recheck.md`

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

## Verification

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  - `1516 passed, 230 subtests passed`
- `./scripts/quality_gate.sh server-target`
  - pass
- `xmage_strategy_consistency_audit_20260709_post_pg686_keyword_draw_new_server_final`
  - pass, 26 checks
- `operational_surface_alignment_audit_20260709_post_pg686_keyword_draw_new_server_final`
  - pass
- `legacy_contamination_audit_20260709_post_pg686_keyword_draw_new_server_final`
  - pass
- `pg_hermes_sqlite_contract_audit_20260709_post_pg686_keyword_draw_new_server_final`
  - pass, 51 checks
