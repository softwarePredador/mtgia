# PG693 Target Player X Draw Evidence - 2026-07-09

Status: `applied_validated_new_server`.

PG693 closed the exact XMage spell subpattern where a spell targets one player
and resolves `DrawCardTargetEffect(GetXValue.instance)`, matching Oracle text
`Target player draws X cards.` The runtime now reads `draw_count_source:
x_value` from cast context and resolves the target-player draw through the
existing battle draw path. Multi-target, Domain, assist, cost-reduction, and
other non-exact neighbors remain blocked.

Promoted cards:

- `Braingeyser`
- `Stroke of Genius`

Runtime/test changes:

- `xmage_authoritative_exact_scope_split.py` maps exact target-player X draw
  source/Oracle pairs to `xmage_fixed_target_player_draw_spell_v1` with
  `draw_count_source=x_value`.
- `battle_analyst_v9.py` resolves target-player draw counts from `_cast_context`
  when `draw_count_source` is `x_value`.
- `xmage_batch_pg_package_builder.py` creates focused E2E scenarios with
  `x_value=3`.
- `battle_package_end_to_end_validation.py` verifies the card is actually
  resolved and emits `draw_cards_resolved` with `target_player_draw=true`,
  `cards_drawn=3`, and `requested_draw_count=3`.

Package evidence:

- Split candidate:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_pg693_target_player_x_draw_candidate.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_package_package.md`
- Manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_package_manifest.json`
- PostgreSQL precheck/apply/postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_package_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_package_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_package_postcheck.sql`
- PG -> SQLite/snapshot sync:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_pg_to_sqlite_sync_runtime_only.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_e2e_validation.md`

Validation results:

- Split candidate: `2` safe package candidates.
- Package manifest: `2` battle execution scenarios.
- Precheck: `2/2` target card rows matched by Oracle hash; `0` existing
  matching rules and `0` shadow rows.
- Apply: `upserted_rows=2`; `deprecated_shadow_rows=0`.
- Postcheck: `2/2` promoted rows are `verified`, `auto`, and carry
  `oracle_hash`.
- Sync: PostgreSQL loaded `6121` rows, SQLite updated `6106`, canonical snapshot
  exported `6083`.
- E2E: `status=pass`, `2` battle execution scenarios, `4` events. Both
  `Braingeyser` and `Stroke of Genius` resolved with `x_value=3` and drew
  `3` cards.
- Tests:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
  passed with `1088 passed, 206 subtests passed`.

Hash-backfill repair:

- `pg_hermes_sqlite_contract_audit` exposed `44` trusted executable PostgreSQL
  rules missing `oracle_hash`.
- Backfill package:
  `docs/hermes-analysis/master_optimizer_reports/pg693_trusted_rule_oracle_hash_backfill_precheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_trusted_rule_oracle_hash_backfill_apply.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_trusted_rule_oracle_hash_backfill_postcheck.sql`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_trusted_rule_oracle_hash_backfill_rollback.sql`
- Backfill precheck: `target_rows=44`, `unresolved_card_id_rows=0`,
  `empty_oracle_hash_rows=0`.
- Backfill apply: `backed_up_rows=44`, `updated_rows=44`.
- Backfill postcheck:
  `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=44`.
- Post-backfill sync/E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_post_hash_backfill_pg_to_sqlite_sync_runtime_only.json`,
  `docs/hermes-analysis/master_optimizer_reports/pg693_target_player_x_draw_new_server_post_hash_backfill_e2e_validation.md`

Final post-PG693 state:

- Global readiness:
  `battle_and_oracle_ready=6181`, `battle_family_mapper_required=27695`,
  `snapshot_has_verified_rule=6209`, `snapshot_has_any_rule=7397`.
- Authoritative queue:
  `target_identity_count=24772`,
  `xmage_authoritative_source_count=24459`,
  `xmage_missing_source_exception_count=313`,
  `xmage_authoritative_parser_gap_count=0`,
  `xmage_authoritative_adapter_required_count=24459`,
  `adapter_work_unit_count=11305`.
- Exact split recheck:
  `proposal_count=0`, `safe_for_batch_pg_package_count=0`.
- Final gates:
  `server-target` quality gate passed,
  `xmage_strategy_consistency_audit` passed `26/26`,
  `pg_hermes_sqlite_contract_audit` passed `51/51`,
  `operational_surface_alignment_audit` passed,
  `legacy_contamination_audit` passed.
