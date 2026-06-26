# PG240 Bolt Bend Redirect Progress 2026-06-26

## Scope

- close the Lorehold-touching XMage -> ManaLoom mapping/runtime gap for
  `Bolt Bend`
- PostgreSQL writes: `true`
- canonical SQLite/Hermes sync: `true`
- target outcome: promote `Bolt Bend` from
  `needs_rule_before_strategy / mapper_manual` to
  `battle_ready / watchlist_candidate`, then regenerate the live
  queue/matrix/audit

## Runtime / Mapper Proof

Verified in the current code state before PG apply:

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `234` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `219` tests passed
- targeted battle proof:
  - `test_pg240_bolt_bend_ferocious_cost_reduction_requires_power_four_creature`
  - `test_pg240_bolt_bend_redirects_with_only_single_red_under_ferocious`
  - result: `ok`

What changed in code:

- new exact XMage mapper for:
  - `single_target_spell_or_ability_redirect_costs_three_less_if_control_power_four_v1`
- classifier now treats that exact redirect scope as
  `targeted_interaction` and `batch_metadata_candidate_requires_pg_precheck`
- battle runtime now honors self spell-cost reduction conditions for:
  - `control_creature_power_4_or_greater`
  - `control_wizard`

## Pre-Sync Discovery

Fresh pipeline prefix before PG apply:

- `xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_presync_v1`

Operational discovery from that run:

- new PG-ready residual:
  - `package_ready_unprepared=1`
- affected card:
  - `Bolt Bend`

Key deltas from the prior post-PG239 state:

- `ready_for_structured_xmage_pull_review_required: 64 -> 65`
- `xmage_source_valid_mapper_required: 317 -> 316`
- `proposal_status.batch_pg_candidate_after_precheck: 0 -> 1`
- matrix:
  - `needs_rule_before_strategy: 241 -> 240`
  - `package_ready: 0 -> 1`

## PG240 Package

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_manifest.json`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_package.md`
- selected cards: `1`

### Precheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_precheck.out`
- target rows:
  - `1`
- existing shadow rows:
  - `2`
- total rows to deprecate:
  - `2`

### Apply

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_apply.out`
- result:
  - `deprecated_shadow_rows=2`
  - `upserted_rows=1`

### Postcheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg240_bolt_bend_redirect_postcheck.out`
- final promoted row state:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`

## PG -> SQLite / Hermes Sync

- report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg240_bolt_bend_redirect_20260626.json`
- result:
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=3`
  - `selected_card_count=1`

## Runtime Proof With Real Card Name

After PG -> SQLite sync, the live runtime resolved `Bolt Bend` by name from the
local database and executed the redirect in battle:

- resolved rule:
  - `effect=redirect_removal`
  - `battle_model_scope=single_target_spell_or_ability_redirect_costs_three_less_if_control_power_four_v1`
  - `review_status=verified`
  - `execution_status=auto`
- focused combat check:
  - Lorehold had only `{R}` available plus one creature with power `4`
  - `Bolt Bend` was cast
  - `Protected Creature` survived
  - `Opponent Threat` died
  - replay emitted `redirect_removal_resolved` with the promoted
    logical rule key

## Post-Sync Pipeline / Queue / Audit

Fresh post-sync prefix:

- `xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_postsync_v1`

Key outputs:

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_postsync_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_postsync_v1_proposals.json`
- effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg240_bolt_bend_postsync_v1.json`
- strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg240_bolt_bend_postsync_v1.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg240_bolt_bend_postsync_v1.json`

Operational deltas that matter:

- effective queue:
  - `package_ready_unprepared: 1 -> 0`
  - residual backlog is now:
    - `manual_mapper_backlog=317`
    - `split_scope_backlog=59`
    - `runtime_family_backlog=4`
    - `blocked_missing_xmage_source=4`
- strategy consistency audit:
  - `18/18 pass`
- severity:
  - `high: 341 -> 340`
  - `medium: 64 -> 63`
  - `pass: 557 -> 559`
- validity:
  - `ready_for_structured_xmage_pull_review_required: 65 -> 64`

Matrix deltas:

- `battle_ready: 722 -> 723`
- `watchlist_candidate: 325 -> 324`
- `low_priority: 171 -> 172`
- `needs_rule_before_strategy: 240 -> 240`

Lorehold-scoped routing deltas:

- `Bolt Bend`
  - `needs_rule_before_strategy / mapper_manual -> watchlist_candidate / battle_ready`
- Lorehold-touching `needs_rule_before_strategy`:
  - `69 -> 68`
- current Lorehold-touching `needs_rule_before_strategy` split:
  - `mapper_manual=60`
  - `split_scope=6`
  - `blocked_missing_xmage_source=2`

## Operational Conclusion

- the `Bolt Bend` slice is closed end to end:
  mapper -> conditional cost runtime -> tests -> PG240 package -> PG apply ->
  SQLite sync -> real-name battle proof -> fresh queue/matrix/audit
- this removed one real Lorehold blocker and kept the benchmark phase closed
- the next highest-ROI Lorehold-first unresolved targets are now:
  `Currency Converter`, `Firesong and Sunspeaker`, `Magmakin Artillerist`,
  `Penance`, and `Radiant Scrollwielder`
