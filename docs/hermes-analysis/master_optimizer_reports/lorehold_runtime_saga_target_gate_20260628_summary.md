# Lorehold Runtime Saga Target Gate - 2026-06-28

## Change Under Test

- Runtime file: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Test file: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- Scope: Urza's Saga chapter 3 artifact tutor now passes `artifact_cmc_1_or_less` to the contextual scorer.
- Lorehold-specific scoring applies only when the player has `Lorehold, the Historian` in play, commander, or command zone.
- Target priority in Lorehold low-artifact tutor context:
  - `Sensei's Divining Top`: `find_lorehold_topdeck_miracle_engine`
  - `Library of Leng`: `find_lorehold_discard_to_top_engine`
  - `Sol Ring`: `accelerate_lorehold_commander_miracle_plan`

## Validation

- `python3 -m pytest --version`: `pytest 9.1.1`; no install was needed.
- Focused dynamic harness:
  - `PASS test_urzas_saga_tutors_safe_artifact_then_sacrifices`
  - `PASS test_urzas_saga_prefers_topdeck_engine_for_lorehold_plan`
  - `PASS test_senseis_top_sets_up_lorehold_approach_second_cast`
  - `PASS test_lorehold_upkeep_rummage_discards_squee_to_graveyard_for_recursion`
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`: pass.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_battle_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_failure_targeted_synergy_hypotheses.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_next_action_planner.py -q`: `18 passed`.
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_failure_targeted_trace_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_next_hypothesis_queue.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_synergy_package_gate.py -q`: `24 passed, 8 subtests passed`.

## Gate Evidence

Source DB:
`docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`

Common gate arguments:
`--deck-ids 6 --no-candidate --games 1 --opponent-limit 3 --opponent-seed 20260626 --game-timeout-seconds 20 --no-game-checkpoint`

All gates were read-only: `postgres_writes=false`, `source_db_mutated=false`.

| Seed | Report | Record | Key Runtime Signals |
| --- | --- | ---: | --- |
| 7 | `lorehold_runtime_saga_target_gate_20260628_seed7_v1.json` | 0-3-0 | `saga_chapter_resolved=1`, `lorehold_upkeep_rummage=3` |
| 20260625 | `lorehold_runtime_saga_target_gate_20260628_seed20260625_v1.json` | 1-2-0 | `miracle_cast=2`, `lorehold_upkeep_rummage=14` |
| 42 | `lorehold_runtime_saga_target_gate_20260628_seed42_v1.json` | 3-0-0 | `miracle_cast=13`, `topdeck_manipulation_activated=12`, `squee_to_graveyard=3`, `squee_upkeep_return=2` |

## Seed 7 Saga Payload

Real gate trace after the runtime change:

```json
{
  "game_id": "deck_6:Sisay, Weatherlight Captain #61 (real):0",
  "turn": 5,
  "found": "Sensei's Divining Top",
  "selected_reason": "find_lorehold_topdeck_miracle_engine",
  "candidate_names": [
    "Sensei's Divining Top",
    "Library of Leng",
    "Esper Sentinel"
  ],
  "legal_target_names": [
    "Esper Sentinel",
    "Sensei's Divining Top",
    "Library of Leng"
  ]
}
```

## Interpretation

The previous failure mode was not missing legal Saga targets: the trace already showed engine targets were legal. The runtime scorer was treating the choice as generic early value and could select `Esper Sentinel`.

This change closes that specific runtime gap. The weak seed 7 still loses, so the next blocker is not Saga target legality anymore; it is conversion after early engine access, especially getting Top/Library into an actual first-draw miracle window under pressure.
