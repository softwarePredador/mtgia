# Battle Counter Priority Window Scope Audit - 2026-06-19T19:31:49Z

## Scope

This audit checks whether current counterspell interactions carry enough
provenance to prove target, stack object, result, and priority window. It does
not change PostgreSQL, swaps, runtime code, automation, or commits.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Per-seed sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`

Code/test context inspected:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

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

## Observed Counter Events

The latest corpus has `7` `spell_countered` events:

| Seed | JSONL line | Counter | Target | Stack depth | Result |
| --- | ---: | --- | --- | ---: | --- |
| `63201741` | 451 | `Mental Misstep` | `Mizzix's Mastery` | 1 | `countered` |
| `63201742` | 697 | `Pact of Negation` | `Grand Abolisher` | 1 | `countered` |
| `63201746` | 19 | `Pact of Negation` | `Twinflame` | 1 | `countered` |
| `63201746` | 686 | `Mental Misstep` | `Orim's Chant` | 1 | `countered` |
| `63201747` | 454 | `Pact of Negation` | `Path to Exile` | 1 | `countered` |
| `63201748` | 141 | `Mental Misstep` | `Voice of Victory` | 1 | `countered` |
| `63201748` | 707 | `Mental Misstep` | `Silence` | 1 | `countered` |

All `7/7` events include:

- `counter`
- `target`
- `stack_object`
- `target_controller`
- `target_effect`
- `result=countered`
- `stack_depth=1`

No current `spell_countered` event is missing target, stack object, result, or
stack depth.

## Priority Window Gap

All `7/7` `spell_countered` events are missing:

- `phase`
- `priority_window`

The surrounding events usually let a human infer the phase. For example:

- `seed_63201742`, JSONL lines `694-697`: `Grand Abolisher` is announced,
  paid, cast in `precombat_main`, then countered by `Pact of Negation`.
- `seed_63201746`, JSONL lines `683-686`: `Orim's Chant` is miracle-cast in
  `draw_step`, then countered by `Mental Misstep`.

However, the `spell_countered` event itself does not preserve the response
window. The human replay line also omits it, e.g.:

- `COUNTER ... Mental Misstep -> target=Mizzix's Mastery stack_object=Mizzix's Mastery result=countered cost=1.0`

This matters because the living validation checklist already requires each
counter to prove target, stack object, priority window, and result.

## Auditor/Test Scope

Current guardrails are useful but incomplete for this field:

- `battle_action_critic.py` validates missing target/stack object and invalid
  counter result, but it does not require `phase` or `priority_window` on
  `spell_countered`.
- `test_battle_action_critic.py` accepts a `spell_countered` fixture with
  target, stack object, and result, but without phase/window.
- `battle_stack_casting_tests.py` confirms a counterspell consumes card/mana and
  counters the target, but the test only asserts that a `spell_countered` event
  exists; it does not require phase/window fields.
- The latest corpus has no cast-like rows with `effect=counter`, so the current
  green run proves the observed counter result path, not every future
  counter-cast shape.

## Current Conclusion

The current flow is correct for mandatory gates and no current high/critical
counter finding exists. Counter events now have target, stack object, stack
depth, target controller/effect, and result.

The remaining gap is observability: the counter event does not carry its own
priority-window proof. Until `phase` or an explicit `priority_window` is stored
on `spell_countered`, a future reviewer must infer legality from nearby events,
which is weaker than the contract required by the validation checklist.

Recommended adjustment:

1. Emit `phase` and/or `priority_window` from the counter response path when
   `spell_countered` is created.
2. Add an action-critic finding for `spell_countered` without phase/window, or
   define an explicit waiver if the phase is intentionally inferred from the
   preceding stack item.
3. Render the phase/window in `replay.txt` counter lines.
4. Add fixtures in `battle_stack_casting_tests.py` and
   `test_battle_action_critic.py` that fail when counter window provenance is
   missing.
