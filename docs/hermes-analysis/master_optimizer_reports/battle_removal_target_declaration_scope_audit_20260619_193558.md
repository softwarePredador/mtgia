# Battle Removal Target Declaration Scope Audit - 2026-06-19T19:35:58Z

## Scope

This audit checks whether targeted removal spells declare and preserve their
target at cast time, or only select a target at resolution time. It does not
change PostgreSQL, swaps, runtime code, automation, or commits.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Per-seed sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`

Code/test context inspected:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`

## Current Latest Result

- `timestamp_utc=2026-06-19T18:47:21Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16`
- `events=14679`
- `action_findings=0`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

No current alert condition was found for high/critical action findings or
strategy blockers.

## Event Evidence

The latest corpus has removal-like cast/resolution rows for:

- `remove_creature`
- `remove_permanent`
- `redirect_removal`

Observed counts:

| Event shape | Count | Target present |
| --- | ---: | ---: |
| cast-like removal events | 49 | 0 |
| `spell_resolved` removal events | 31 | 0 |
| `removal_resolved` events | 13 | 13 |

Cast-like removal events include:

- `cast_announced/remove_creature`: `7`
- `spell_cast/remove_creature`: `7`
- `cast_announced/remove_permanent`: `4`
- `spell_cast/remove_permanent`: `4`
- `cast_announced/redirect_removal`: `6`
- `spell_cast/redirect_removal`: `6`
- `end_step_instant/remove_creature`: `4`
- `end_step_instant/remove_permanent`: `4`
- `end_step_instant/redirect_removal`: `2`
- `miracle_cast/remove_permanent`: `2`
- `miracle_cast/redirect_removal`: `3`

Every cast-like row above is missing `target` and has empty or absent
`targets`.

Example from `seed_63201734`:

- Line `242`: `cast_announced` for `Generous Gift`, `effect=remove_permanent`,
  `targets=[]`.
- Line `244`: `spell_cast` for `Generous Gift`, `targets=[]`.
- Line `249`: `spell_resolved` for `Generous Gift`, no target.
- Line `250`: `removal_resolved`, target becomes `Kraum, Ludevic's Opus`.

Example from `seed_63201747`:

- Line `451`: `cast_announced` for `Path to Exile`, `effect=remove_creature`,
  `targets=[]`.
- Line `453`: `spell_cast` for `Path to Exile`, `targets=[]`.
- Line `454`: `spell_countered` counters `Path to Exile`, but the removal
  target that spell would have used is not available on the stack object.

## Runtime Shape

`CastingContext` already supports targets:

- It accepts `targets`.
- `to_replay_fields()` emits `targets`.
- `battle_stack_casting_tests.py` has generic context tests showing targets can
  be carried by `cast_announced`.

The normal removal flow does not use that capability:

- `cast_spells_v8(...)` calls `begin_cast_context(...)` for normal spells
  without preselecting targets.
- `apply_effect_immediate(...)` later handles `remove_creature`,
  `remove_permanent`, and `remove_artifact_or_3dmg`.
- `apply_effect_immediate(...)` chooses a legal target at resolution time via
  `removal_target_candidates(...)`, `choose_best_creature_target(...)`, and
  `targeting_decision(...)`.

The targeting tests are useful but cover the resolution side:

- `battle_targeting_tests.py` validates hexproof/protection/ward and confirms
  `removal_resolved` includes formal targeting metadata.
- It does not require a removal target to be declared in `cast_announced` or
  preserved on `spell_cast`.

## Current Conclusion

This is not just a renderer gap. It is a target-declaration/provenance gap.
Targeted removal spells should lock their targets as part of casting, then
resolution should validate whether those declared targets are still legal.

Current behavior chooses or records targets only at resolution. This means:

1. The stack object for a removal spell can lack the target it is supposed to
   have.
2. Counter/response decisions cannot inspect the exact object being threatened.
3. If board state changes before resolution, the engine can choose a later best
   target rather than resolve the target declared at cast time.
4. `spell_resolved` and `replay.txt` cannot explain which target was pending on
   stack before resolution.

Recommended adjustment:

1. For targeted removals, select and persist declared target metadata before or
   during `begin_cast_context(...)`.
2. Emit that target in `cast_announced`, `spell_cast`, `miracle_cast`,
   `end_step_instant`, and `spell_resolved`.
3. Make `apply_effect_immediate(...)` resolve declared targets through
   `is_legal_target(...)` instead of choosing a fresh best target at resolution.
4. Add action-critic coverage for removal cast-like rows without declared
   target metadata.
5. Add tests proving targeted removal declares a target at cast time and only
   revalidates that target at resolution.
