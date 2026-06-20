# Battle latest counter priority window recheck 2026-06-19

Scope: recheck `BV-064` against the current `latest` battle audit artifact and
the code paths that emit, render and criticize `spell_countered`.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T20:48:26Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `seeds_requested=16`
- `seeds_completed=16`
- `mandatory_gate_divergences=[]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

No high/critical action finding or strategy blocker was present in the latest
summary.

## Result

`BV-064` remains open.

The latest trusted artifact has `10` `spell_countered` events. All `10/10`
events include the core interaction fields:

- `counter`
- `target`
- `stack_object`
- `target_controller`
- `target_effect`
- `result=countered`
- `stack_depth=1`
- `cost`

All `10/10` events still lack both direct temporal fields:

- `phase`
- `priority_window`

This is not currently blocking the mandatory gates, but it means the legality
window for each counter must be inferred from adjacent decision traces or stack
events instead of being proven by the `spell_countered` event itself.

## Event evidence

Extracted from
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`.

| Seed | Turn | Player | Counter | Target | Target effect | Phase | Priority window |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| `63202025` | 2 | `Kraum, Ludevic's Opus #83 (real)` | `Pact of Negation` | `Mystic Remora` | `draw_engine` | missing | missing |
| `63202025` | 5 | `Kraum, Ludevic's Opus #83 (real)` | `Mental Misstep` | `Grand Abolisher` | `silence_opponents` | missing | missing |
| `63202026` | 6 | `Kraum, Ludevic's Opus #83 (real)` | `Pact of Negation` | `Twinflame` | `token_maker` | missing | missing |
| `63202026` | 13 | `Kinnan, Bonder Prodigy #104 (real)` | `Miscast` | `Silence` | `silence_spell` | missing | missing |
| `63202027` | 3 | `Kraum, Ludevic's Opus #83 (real)` | `Pact of Negation` | `Twinflame` | `token_maker` | missing | missing |
| `63202029` | 6 | `Kinnan, Bonder Prodigy #104 (real)` | `Mental Misstep` | `Orim's Chant` | `silence_spell` | missing | missing |
| `63202029` | 9 | `Kraum, Ludevic's Opus #83 (real)` | `Pact of Negation` | `Esper Sentinel` | `draw_engine` | missing | missing |
| `63202030` | 6 | `Rograkh, Son of Rohgahh #62 (real)` | `Pact of Negation` | `Twinflame` | `token_maker` | missing | missing |
| `63202030` | 7 | `Rograkh, Son of Rohgahh #62 (real)` | `Mental Misstep` | `Generous Gift` | `remove_permanent` | missing | missing |
| `63202037` | 7 | `Kinnan, Bonder Prodigy #84 (real)` | `Mental Misstep` | `Aetherflux Reservoir` | `finisher` | missing | missing |

Aggregate check:

```text
10 spell_countered __MISSING__ __MISSING__
```

## Decision trace split

The matching `replay.decision_trace.jsonl` response decisions do carry a phase:

```text
10 precombat_main
```

That means the run has enough nearby evidence to infer that the observed
counters happened during `precombat_main`, but the field is not propagated into
the primary `spell_countered` event or the human replay line.

## Text replay evidence

The human replay still renders counters in this shape:

```text
COUNTER <player>: <counter> -> target=<target> stack_object=<stack_object> result=countered cost=<cost>
```

Observed lines include counters against `Mystic Remora`, `Grand Abolisher`,
`Twinflame`, `Silence`, `Orim's Chant`, `Esper Sentinel`, `Generous Gift` and
`Aetherflux Reservoir`. None of those lines prints `phase` or
`priority_window`.

## Source evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:3424-3457`:
  `Player.use_counterspell(...)` emits `spell_countered` with target, stack,
  result, stack depth, cost and rule fields, but has no `phase` or
  `priority_window` parameter.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:4947-4959`:
  the priority-response caller has `phase` and records it in
  `emit_decision_trace(...)`, but calls `player.use_counterspell(...)` without
  passing `phase`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py:237-246`:
  the renderer writes only counter, target, stack object, result and cost for
  `spell_countered`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py:653-670`:
  the critic checks target, stack object and legal result, but does not require
  `phase` or `priority_window`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py:127-144`:
  the accepted counter fixture has no `phase` or `priority_window` and still
  expects zero findings.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py:17-48`:
  the stack test only asserts that a `spell_countered` event exists.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py:283-286`:
  `spell_resolved` now has an explicit phase/window assertion, but there is no
  equivalent assertion for `spell_countered`.

## Tests run

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py
PASS test_critic_flags_action_level_findings
PASS test_critic_renders_markdown_ledger
PASS test_critic_flags_counter_spell_without_stack_target
PASS test_critic_accepts_counter_with_target_stack_object_and_result
PASS test_critic_flags_trigger_without_auditable_stack_metadata
PASS test_critic_accepts_trigger_with_source_trigger_and_stack_order
PASS test_critic_flags_replacement_without_causal_metadata
PASS test_critic_accepts_replacement_with_causal_metadata
PASS test_critic_accepts_life_replacement_with_affected_player_metadata
PASS test_critic_flags_life_replacement_without_original_final_metadata
PASS test_critic_reports_event_contract_denominators
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
PASS test_counterspell_consumes_card_mana_and_counters_target
PASS test_empty_stack_priority_requires_main_phase
PASS test_empty_stack_priority_casts_main_phase_creature
PASS test_main_phase_priority_loop_casts_bounded_empty_stack_actions
PASS test_empty_stack_priority_emits_apnap_pass_sequence
PASS test_stack_resolution_emits_apnap_pass_sequence_before_resolve
PASS test_spell_resolved_includes_stack_and_zone_provenance
PASS test_conformance_stack_resolves_lifo
PASS test_player_does_not_counter_own_spell
PASS test_end_step_interaction_does_not_cast_counter_without_stack_target
PASS test_lorehold_miracle_does_not_cast_counter_without_stack_target
PASS test_silence_effect_blocks_counterspell_responses
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
PASS test_renderer_writes_land_cost_cast_illegal_and_board_details
PASS test_renderer_differentiates_spell_ability_trigger_and_counter
PASS test_renderer_uses_real_trigger_put_on_stack_fields
PASS test_renderer_explains_noncombat_damage_life_change
PASS test_deck_metrics_are_derived_from_resolved_cards
PASS test_provenance_line_names_source_metrics_and_blocker_domain
```

## Recommended follow-up

- Add `phase` and `priority_window` to `Player.use_counterspell(...)` or derive
  them from the current stack/priority context before emitting
  `spell_countered`.
- Propagate those fields into `battle_replay_v10_3.py` so the human replay line
  shows the counter window.
- Add a critic or event-contract requirement for `spell_countered` phase/window,
  or add an explicit waiver if the contract decision is to infer the window from
  adjacent decision traces.
- Add regression coverage mirroring the existing `spell_resolved` phase/window
  assertions for counter events.

Close condition for `BV-064`: every observed `spell_countered` has
`phase`/`priority_window`, or the event contract publishes a formal waiver and
tests prove the accepted inference path.
