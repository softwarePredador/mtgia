# PG046 Approach of the Second Sun Focused Replay Summary

Generated: 2026-06-23T00:02:05.206155+00:00

## Scope
- Card: `Approach of the Second Sun`
- SQLite cache: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Logical rule key: `battle_rule_v1:ed74fb069b6c1d635392d907804a1d98`
- Oracle hash: `0838960b80a282fb4508532f7bae8c2b`
- Model scope: `approach_second_cast_win_v2`

## Scenario
1. Attempted to track a copied Approach spell and confirmed it did not increment the cast ledger.
2. Cast Approach from hand, marked the stack item countered, and resolved the countered spell through `Stack.resolve_top()`.
3. Cast a second Approach from hand and resolved it through `apply_effect_immediate()`.

## Results
- Copy attempt recorded: `False`; count before/after: `0` -> `0`.
- Countered first cast resolve result: `None`; Approach count after counter: `1`; life: `40`.
- Final Approach count: `2`.
- Final life: `40`.
- Final win reason: `approach`.
- Second `spell_resolved` destination: `graveyard`.
- Replay events: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl`.
- Decision trace: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_decision_trace_20260622_235039.jsonl` (`0` rows; this direct stack/effect scenario does not invoke strategic decisions).

## Checks
- copy_attempt_recorded_false: PASS
- copy_attempt_did_not_increment: PASS
- sqlite_rule_key_loaded: PASS
- sqlite_oracle_hash_loaded: PASS
- first_cast_countered_no_resolution: PASS
- countered_first_cast_counted: PASS
- countered_first_cast_no_life_gain: PASS
- tracked_cast_counts_are_1_2: PASS
- tracked_events_use_pg046_key: PASS
- tracked_events_use_pg046_hash: PASS
- second_cast_wins: PASS
- second_cast_no_life_gain: PASS
- second_spell_resolved_destination_graveyard: PASS
- no_first_resolution_branch_on_second_cast: PASS
- game_won_event_emitted: PASS
