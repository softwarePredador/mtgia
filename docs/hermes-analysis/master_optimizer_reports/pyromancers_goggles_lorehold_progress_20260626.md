# Pyromancer's Goggles Lorehold Progress 2026-06-26

## Scope

- target card: `Pyromancer's Goggles`
- objective slice: close one Lorehold-facing `needs_rule_before_strategy` / `mapper_manual` card end to end, including local XMage -> ManaLoom mapper/runtime/tests, PostgreSQL package apply, SQLite/Hermes sync, and fresh candidate-deck evidence
- PostgreSQL writes: `true`
- canonical SQLite mutated: `true`
- git commit/push: `not done in this slice`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `PyromancersGoggles`
  - emitted scope:
    `red_mana_rock_red_instant_sorcery_mana_spent_copy_spell_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - exact-scope batch-safe recognizer for the Goggles mana-copy rock family
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - `copy_when_mana_spent` trigger now honors optional spell-color filters
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - mapper test for Pyromancer's Goggles
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - classifier batch-safe test for Pyromancer's Goggles
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - runtime tests:
    - `test_pyromancers_goggles_copies_red_instant_when_its_mana_is_spent`
    - `test_pyromancers_goggles_skips_nonred_spell_even_when_untapped`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `227` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `212` tests passed
- `python3 battle_card_specific_tests.py`
  - targeted regression script passed with the two new Goggles runtime checks included in the curated run list

## PG233 Package Evidence

- package files:
  - `docs/hermes-analysis/master_optimizer_reports/pg233_pyromancers_goggles_exact_scope_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg233_pyromancers_goggles_exact_scope_manifest.json`
- precheck:
  - output:
    `docs/hermes-analysis/master_optimizer_reports/pg233_pyromancers_goggles_exact_scope_precheck.out`
  - result:
    - `target_card_rows=1`
    - `existing_rule_rows=2`
    - `expected_rule_rows_before=0`
    - `would_deprecate_shadow_rows=2`
- apply:
  - output:
    `docs/hermes-analysis/master_optimizer_reports/pg233_pyromancers_goggles_exact_scope_apply.out`
  - result:
    - `deprecated_shadow_rows=2`
    - `upserted_rows=1`
- postcheck:
  - output:
    `docs/hermes-analysis/master_optimizer_reports/pg233_pyromancers_goggles_exact_scope_postcheck.out`
  - result:
    - `promoted_rule_rows=1`
    - `promoted_verified_auto_rows=1`
    - `promoted_oracle_hash_rows=1`
    - `backup_rows=2`

## SQLite / Hermes Sync Evidence

- targeted PG -> SQLite refresh:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --apply-sqlite-from-pg --only-card "Pyromancer's Goggles" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg233_pyromancers_goggles_20260626.json`
- sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg233_pyromancers_goggles_20260626.json`
- key result:
  - `pg_rows_loaded=1`
  - `generated_rows=1`
  - `sqlite_inserted_or_updated=3`

## Pipeline Evidence

- pre-apply local package checkpoint:
  - pipeline:
    `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg233_pyrogoggles_runtime_v1_proposals.json`
  - matrix:
    `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg233_pyrogoggles_runtime_v1.json`
- post-sync canonical checkpoint:
  - pipeline:
    `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg233_pyrogoggles_postsync_v1_proposals.json`
  - matrix:
    `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg233_pyrogoggles_postsync_v1.json`
  - effective queue:
    `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg233_pyrogoggles_postsync_v1.json`
  - strategy audit:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg233_pyrogoggles_postsync_v1.json`

### Pyromancer's Goggles row movement

- before PG233:
  - `recommendation_lane=needs_rule_before_strategy`
  - `rule_status=mapper_manual`
  - `promotion_lane=mapper_metadata_or_test_scenario_required`
  - `score=10.5`
- pre-apply local package:
  - `recommendation_lane=watchlist_candidate`
  - `rule_status=package_already_prepared`
  - `score=32.5`
- after PG233 apply + SQLite sync:
  - `recommendation_lane=watchlist_candidate`
  - `rule_status=battle_ready`
  - `battle_model_scopes=["red_mana_rock_red_instant_sorcery_mana_spent_copy_spell_v1"]`
  - `executable_rule_count=1`
  - `score=41.5`

### Lorehold-scoped matrix deltas

- `battle_ready`: `315 -> 316`
- `package_already_prepared`: `42 -> 41`
- `priority_benchmark_candidate`: `44 -> 44`
- `watchlist_candidate`: `121 -> 121`

### Queue / audit state

- post-sync effective queue:
  - `package_ready_unprepared=4`
  - remaining cards:
    `Scholar of New Horizons`, `Velomachus Lorehold`, `Galvanoth`, and `Palantír of Orthanc`
- strategy consistency audit:
  - `17/18` pass
  - only failing check:
    `effective_queue.package_ready_unprepared=4`

## Candidate Deck Evidence

- pre-change generated candidate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg232_v1.json`
  - hash:
    `a2a5793c8c7586bcf2b99860f54afeb0200a93ad127b0b71239fc3ff048d6579`
- post-sync generated candidate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg233_pyrogoggles_postsync_v1.json`
  - hash:
    `a6128298aafade21fd2177eccafe51d756e4b4382e0cf09ea1f7a43c8cf08dbd`

Candidate delta vs PG232:

- added:
  `Boseiju, Who Shelters All`, `Eiganjo, Seat of the Empire`,
  `Glittering Massif`, `Radiant Summit`, `Reliquary Tower`,
  `Reckless Handling`
- removed:
  `Ancient Den`, `City of Brass`, `Gemstone Caverns`,
  `Hall of Heliod's Generosity`, `Mana Confluence`,
  `Goblin Engineer`

## Candidate Smoke

Short real-opponent smoke on the post-sync generated candidate:

- command:
  `MANALOOM_KNOWLEDGE_DB=.../lorehold_generated_candidate_20260626_pg233_pyrogoggles_postsync_v1/knowledge_candidate.db MANALOOM_BATTLE_REAL_OPPONENT_LIMIT=3 MANALOOM_BATTLE_REAL_OPPONENT_SEED=20260626 python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py --games 1`
- result:
  - `1W/2L/0S`
  - opponents:
    - `Vivi Ornitier #99`: `0W/1L`
    - `Sisay, Weatherlight Captain #61`: `1W/0L`
    - `Winota, Joiner of Forces #39`: `0W/1L`

This improved the same short sample from the earlier PG232 candidate smoke
(`0W/3L/0S`) to `1W/2L/0S`.

## Slot Optimizer Smoke

Restricted smoke against the post-sync PG233 matrix:

- command:
  `python3 -u slot_optimizer.py --deck-id 6 --games 1 --max-per-category 1 --candidate-matrix ...pg233... --candidate-lane priority_benchmark_candidate --phase pg233_pyrogoggles_postsync_smoke`
- pre-run evidence before manual interrupt:
  - `baseline_id=9`
  - `baseline_wr=12.5%`
  - `candidate_allowlist_size=46`
  - `selected_candidates=15`
  - `battle_replay_final_status=review_required`
  - `mandatory_gate_divergences=["event_contract_static=review_required"]`
  - category scan reached:
    `[draw] 1 selected candidates (cut target: Valakut Awakening // Valakut Stoneforge)`

This confirms the baseline/hash guard and current priority lane selection still
resolve correctly against the post-sync matrix, while the final WR evidence
remains expensive because each swap still waits on a full battle subprocess and
the mandatory replay gate remains `review_required`.

## Operational Conclusion

- `Pyromancer's Goggles` is no longer in the Lorehold `needs_rule_before_strategy` backlog.
- This slice was closed end to end:
  mapper -> runtime -> tests -> PG233 package -> PG apply -> SQLite sync -> fresh matrix/candidate evidence.
- The post-sync matrix gained exactly one additional `battle_ready` Lorehold-facing card.
- The remaining queue of PG-ready but not yet product-ready cards is now:
  `Scholar of New Horizons`, `Velomachus Lorehold`, `Galvanoth`, and `Palantír of Orthanc`.
- The candidate deck changed materially after this slice and the short real-opponent smoke improved from `0W/3L` to `1W/2L`.
