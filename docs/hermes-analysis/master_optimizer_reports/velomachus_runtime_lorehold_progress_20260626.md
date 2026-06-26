# Velomachus Runtime Lorehold Progress 2026-06-26

- scope: promote `Velomachus Lorehold` from Lorehold `needs_rule_before_strategy`
  using local XMage source and a new battle runtime executor that reuses the
  free-cast infrastructure already proven by `Galvanoth`.
- xmage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/v/VelomachusLorehold.java`
- matrix checkpoint before:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg230_galvanoth_runtime_v1.json`
- matrix checkpoint after:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg231_velomachus_runtime_v1.json`

## Runtime Slice

Implemented:

- exact XMage mapper scope:
  `attack_top_seven_instant_or_sorcery_lte_power_may_cast_without_paying_mana_v1`
- classifier promotion for the exact scope into
  `batch_metadata_candidate_requires_pg_precheck`
- battle runtime executor:
  `resolve_attack_top_library_free_cast_triggers(...)`
- combat hook from `combat_phase_v8(...)`
- focused tests for mapper, classifier, and battle runtime

## Focused Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `Ran 225 tests ... OK`
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `Ran 210 tests ... OK`
- `python3 test_battle_analyst_v10_3.py`
  - includes `PASS test_pg231_velomachus_attack_casts_best_eligible_top_seven_spell_without_paying_mana`

## Pipeline Delta

Pipeline:

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg231_velomachus_runtime_v1_manifest.json`
- effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg231_velomachus_runtime_v1.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg231_velomachus_runtime_v1.json`
- strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg231_velomachus_runtime_v1.json`

Observed delta versus PG230:

- `needs_rule_before_strategy`: `78 -> 77`
- `mapper_manual`: `69 -> 68`
- `package_ready`: `2 -> 3`
- `low_priority`: `51 -> 52`
- `priority_benchmark_candidate`: unchanged at `44`
- `battle_ready`: unchanged at `315`

Velomachus row movement:

- before:
  `mapper_manual / needs_rule_before_strategy / score=7.5`
- after:
  `package_ready / low_priority / score=31.5`

## Queue / Audit State

- effective queue `package_ready_unprepared=3`:
  `Galvanoth`, `Palantír of Orthanc`, `Velomachus Lorehold`
- strategy consistency audit:
  - `status=fail`
  - only failing check:
    `effective_queue.package_ready_unprepared = 3`

## Slot Optimizer Smoke

Captured from:

- stdout:
  `docs/hermes-analysis/master_optimizer_reports/slot_optimizer_pg231_velomachus_runtime_v1_stdout.txt`
- stderr:
  `docs/hermes-analysis/master_optimizer_reports/slot_optimizer_pg231_velomachus_runtime_v1_stderr.txt`

Pre-run evidence reached before manual interruption:

- `baseline_id=9`
- `baseline_wr=12.5%`
- `candidate_allowlist_size=46`
- `selected_candidates=15`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["event_contract_static=review_required"]`

The optimizer is still structurally wired to the new matrix, but the benchmark
phase remains expensive because it enters the battle subprocess even in the
short smoke configuration.

## Operational Conclusion

- `Velomachus Lorehold` no longer sits in the Lorehold manual mapper backlog.
- The next Lorehold first-priority rule-first targets remain
  `Blood Sun`, `Currency Converter`, `Firesong and Sunspeaker`, and
  `Scholar of New Horizons`.
- The current benchmark bottleneck is still the battle validation layer, not
  the XMage mapper/runtime patch itself.
