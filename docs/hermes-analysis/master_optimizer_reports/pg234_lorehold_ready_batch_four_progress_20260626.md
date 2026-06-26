# PG234 Lorehold Ready Batch Four Progress 2026-06-26

## Scope

- package/apply the full `package_ready_unprepared` residual from the
  post-PG233 Lorehold queue:
  `Galvanoth`, `Velomachus Lorehold`, `Palantir of Orthanc`, and
  `Scholar of New Horizons`
- PostgreSQL writes: `true`
- canonical SQLite/Hermes sync: `true`
- target outcome: clear the operational PG-ready residual, rerun the live
  queue/matrix/audits, then recheck generated-candidate and slot-optimizer
  behavior on the fresh post-sync state

## Focused Runtime / Mapper Proof

Verified in the current code state before PG apply:

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `227` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `212` tests passed
- `python3 battle_card_specific_tests.py`
  - exit code `0`

These cover the exact XMage-backed scopes already implemented for:

- `Galvanoth`
  - `controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1`
- `Velomachus Lorehold`
  - `attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1`
- `Palantir of Orthanc`
  - `controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1`
- `Scholar of New Horizons`
  - `activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1`

## PG234 Package

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_manifest.json`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_package.md`
- selected cards: `4`
- backup table:
  `manaloom_deploy_audit.pg234_lorehold_ready_batch_four_20260626_082257`

### Precheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_precheck.out`
- matched target rows: `1` for each of the four cards
- existing shadow rows detected:
  - `Galvanoth`: `2`
  - `Velomachus Lorehold`: `2`
  - `Palantir of Orthanc`: `2`
  - `Scholar of New Horizons`: `0`

### Apply

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_apply.out`
- result:
  - `deprecated_shadow_rows=6`
  - `upserted_rows=4`

### Postcheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg234_lorehold_ready_batch_four_postcheck.out`
- each card finished with:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`

## PG -> SQLite / Hermes Sync

- report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg234_lorehold_ready_batch_four_20260626.json`
- result:
  - `pg_rows_loaded=4`
  - `sqlite_inserted_or_updated=10`
  - `selected_card_count=4`

## Post-Sync Pipeline / Queue / Audit

Fresh pipeline prefix:

- `xmage_current_replay_batch_pipeline_20260626_pg234_lorehold_ready_batch_four_postsync_v1`

Key outputs:

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg234_lorehold_ready_batch_four_postsync_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg234_lorehold_ready_batch_four_postsync_v1_proposals.json`
- effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`
- strategy benchmark:
  `docs/hermes-analysis/master_optimizer_reports/xmage_acceleration_strategy_benchmark_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`
- strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`

Operational deltas that matter:

- effective queue:
  - `package_ready_unprepared: 4 -> 0`
  - `package_already_prepared: 1`
  - residual backlog is now only:
    `manual_mapper_backlog=326`,
    `split_scope_backlog=61`,
    `runtime_family_backlog=4`,
    `blocked_missing_xmage_source=4`
- strategy consistency audit:
  - `18/18 pass`
- acceleration benchmark:
  - `recommended_strategy_id=hybrid_effective_queue_pattern_registry`
  - `exact_scope_cluster_first` remains the highest raw next-modeling lane,
    but not the replacement for the hybrid operational routing

Per-card post-sync status in the fresh matrix:

- `Galvanoth`
  - `watchlist_candidate / battle_ready / score=42.0`
- `Velomachus Lorehold`
  - `watchlist_candidate / battle_ready / score=38.5`
- `Palantir of Orthanc`
  - `watchlist_candidate / battle_ready / score=36.5`
- `Scholar of New Horizons`
  - `watchlist_candidate / battle_ready / score=42.0`

## Generated Candidate

- report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`
- markdown:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg234_lorehold_ready_batch_four_postsync_v1.md`

Hash delta versus the post-PG233 candidate:

- pre:
  `a6128298aafade21fd2177eccafe51d756e4b4382e0cf09ea1f7a43c8cf08dbd`
- post:
  `3d827d72b023d4cceb1277c388863000794a29de0ad1c338c9d01bd8c86cac19`

Main post-PG234 candidate adds:

- `Exotic Orchard`
- `Goblin Engineer`
- `Hexing Squelcher`
- `Increasing Vengeance`
- `Library of Leng`
- `Misty Rainforest`
- `Polluted Delta`
- `Reforge the Soul`
- `Restoration Seminar`
- `Underworld Breach`
- `Verdant Catacombs`

Main post-PG234 candidate cuts:

- `Aetherflux Reservoir`
- `Ancient Den`
- `Brainstone`
- `Crawlspace`
- `Drannith Magistrate`
- `Great Furnace`
- `Hall of Heliod's Generosity`
- `Inspiring Vantage`
- `Magus of the Moat`
- `Silent Arbiter`
- `Sphere of Safety`
- `Windborn Muse`

### Short Real-Opponent Smoke

Using the isolated candidate DB:

- seed `20260626`
- `3` real opponents
- `1` game each
- result: `0W/3L/0S`

This is worse than the short PG233 post-sync sample and is exactly why the
workflow still requires slot benchmarking rather than trusting rule-closure
alone.

## Slot Optimizer Smoke

Command:

- `python3 -u docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py --deck-id 6 --games 1 --max-per-category 1 --candidate-matrix ...pg234... --candidate-lane priority_benchmark_candidate --phase pg234_lorehold_ready_batch_four_postsync_smoke`

Observed before manual interruption in the long-running battle subprocess:

- `baseline_id=9`
- `baseline_wr=12.5%`
- `baseline_hash=8f719f40b096e17644e1e9308c8f1be9ea2a6c122344d61967cad9fedd358d9f`
- `candidate_allowlist_size=75`
- `selected_candidates=15`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["event_contract_static=review_required"]`
- first active benchmark category reached:
  - `[draw] 1 selected candidates (cut target: Valakut Awakening // Valakut Stoneforge)`

This confirms the post-PG234 lane is wired correctly into the baseline/hash
guard flow, but final WR benchmarking remains bottlenecked by the battle
subprocess plus the still-open mandatory replay gate.

## Operational Conclusion

- the full `package_ready_unprepared` residual from the post-PG233 Lorehold
  queue is now closed in PostgreSQL and synchronized back into SQLite/Hermes
- the operational strategy audit is green again (`18/18 pass`)
- the next work should return to the remaining
  `needs_rule_before_strategy` families rather than opening new PG-ready
  residual
- the deck-generation side still needs slot-level battle evidence, because the
  fresh post-PG234 generated candidate regressed on the short sample
