# Lorehold Deck 6 Eliminated Player Cleanup And Magus+Sphere Gate-Clean Candidate - 2026-06-22

## Scope

This cycle audited the `board_wipe_without_timing_justification` blocker from
the Magus+Sphere candidate. The blocker appeared in seed `63231314` after
`Blasphemous Act` resolved with `Teferi's Protection`.

No PostgreSQL write, permanent deck swap, commit, push, or stash was performed.
All Magus+Sphere deck tests used temporary local SQLite swaps and restored the
official runtime deck after each run.

## Finding

The first trace repair proved a deeper simulator issue:

- Focus artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_141624/summary.json`.
- It made seed `63231314` gate-clean, but the decision trace showed
  `opponent_creatures_destroyed=10` and
  `live_opponent_creatures_destroyed=0`.
- Those destroyed permanents belonged to eliminated players, so they were stale
  game objects and must not count as strategic board-wipe benefit.

Root cause:

- Eliminated players kept battlefield/phased-out objects in the runtime state.
- Later global effects, including board wipes, could still see and remove those
  obsolete objects.

## Runtime Changes

Changed files:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`

Behavior:

- State-based actions now remove battlefield and phased-out objects from a
  player when that player is eliminated.
- `player_eliminated` events now include:
  `battlefield_removed_from_game` and `phased_out_removed_from_game`.
- Board-wipe decision trace now records actual resolution metrics:
  `actual_destroyed`, `own_creatures_destroyed`,
  `opponent_creatures_destroyed`, `live_opponent_creatures_destroyed`,
  `stale_opponent_creatures_destroyed`, `actual_asymmetry`, and
  `self_protected_from_wipe`.
- Strategic justification uses live opponent destruction only. Stale permanents
  from eliminated players remain diagnostic but do not justify a wipe.

## Test Evidence

Commands passed:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`

Regression coverage:

- `test_eliminated_player_battlefield_leaves_game`
- `test_board_wipe_trace_uses_resolution_result_after_phase_out`

The full audit runner for artifact `20260622_142625` also reports
`test_results_status_counts={"pass":18}`.

## Official Deck Control Run

While this work was in progress, an external/full official deck run completed:

- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_141844/summary.json`.
- `run_profile=recurring_16_seed`.
- `invocation_kind=manual_cli`.
- `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- Lorehold wins: `1`.
- Opponent wins: `14`.
- Opponent combat to Lorehold: `301`.
- Opponent combat to other players: `12`.
- Strategy residue:
  `strategy_code_counts={"forced_keep_after_bad_mulligan":1}` in seed
  `63231422`.

This confirms the official restored deck still fails under real battle pressure.

## Candidate Validation

Candidate:

- Temporary local SQLite swap only:
  `Magus of the Moat` + `Sphere of Safety` over
  `Electroduplicate` + `Victory Chimes`.
- The runtime SQLite was restored after the run.

Focused proof:

- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_142458/summary.json`.
- Seed: `63231314`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- Lorehold wins: `1/1`.
- Board-wipe trace:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_142458/seed_63231314/replay.decision_trace.jsonl`.
- `decision-000299` now has `live_opponent_creatures_destroyed=1`,
  `stale_opponent_creatures_destroyed=0`, `actual_asymmetry=1`, and
  `risk_flags=[]`.

Full candidate:

- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_142625/summary.json`.
- `run_profile=candidate_magus_sphere_elimination_cleanup_16_seed`.
- `invocation_kind=codex_candidate_magus_sphere_elimination_cleanup_16_seed`.
- `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- Lorehold wins: `2`.
- Opponent wins: `14`.
- Opponent combat to Lorehold: `267`.
- Opponent combat to other players: `3`.
- Strategy residue:
  `strategy_code_counts={"forced_keep_after_bad_mulligan":1}` in seed
  `63231318`.
- Lorehold win seeds: `63231314`, `63231324`.

## Current Deck State

Post-run SQLite check:

- Source:
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- `Electroduplicate=1`.
- `Victory Chimes=1`.
- deck rows: `100`.
- deck quantity: `100`.
- `Magus of the Moat` and `Sphere of Safety` are not in the restored official
  runtime deck.

## Decision

- The stale eliminated-player battlefield contamination is closed by code,
  tests, and battle artifact evidence.
- The Magus+Sphere candidate is now gate-clean, but still only wins `2/16`
  (`12.5%`) in the same seed window.
- This is not enough for PostgreSQL deck deploy by itself.
- Magus+Sphere remains the strongest current direction because it cuts pressure
  to Lorehold from the prior same-window official `328` to `267`, but the deck
  still needs loss-pattern analysis and likely additional changes before a
  durable deck package.

## Next Work

1. Analyze the `14` Magus+Sphere losses in `20260622_142625`, starting with
   high-confidence seeds that are not low-confidence mulligan artifacts.
2. Compare losses against the official control `20260622_141844` and prior
   official same-window `20260622_134502`.
3. Propose the next candidate around early combat denial plus a faster
   post-stabilization closer.
4. Prepare PostgreSQL only after a candidate shows a stronger and repeatable
   gain than `2/16`.
