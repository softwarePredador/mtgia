# Lorehold Topdeck Forced Access Audit

- generated_at: `2026-07-05T06:11:49Z`
- status: `topdeck_forced_access_diagnostic_ready_no_natural_gate_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- current_baseline: `deck_607`
- target_card_count: `5`
- diagnostic_ready_count: `5`
- natural_gate_ready_count: `0`
- safe_cut_ready_count: `0`
- preflight_gate_ready_now_count: `0`
- promotion_allowed: `false`
- deck_action_allowed_now: `false`
- recommended_first_diagnostic: `Penance`

## Source Reports

- `hypothesis_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_preflight_20260704_current.json`
- `trace_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_trace_failure_miner_20260704_current.json`
- `value_priority`: `docs/hermes-analysis/master_optimizer_reports/lorehold_card_value_priority_synthesis_20260705_current_relearn.json`

## Source Snapshot

- EDHREC Lorehold commander page: https://edhrec.com/commanders/lorehold-the-historian
  - Current public Lorehold evidence tags the commander as Topdeck and Spellslinger and gives card-specific signals for Galvanoth and Dragon's Rage Channeler.
- EDHREC optimized Topdeck Lorehold page: https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck
  - Used as shell context only; optimized public lists do not replace the 607 gate.
- EDHREC Miracles Every Turn with Lorehold: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Imported lesson: opponent-upkeep rummage creates first-draw miracle windows, so top-library setup is a core engine floor.
- Card Kingdom Lorehold synergy review: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/
  - Imported lesson: Library of Leng, Penance, Sensei's Divining Top, Scroll Rack, Land Tax, Victory Chimes, and Bender's Waterskin are coherent with the plan.

## Candidates

| Rank | Card | Signal | Hypothesis status | Diagnostic | Natural gate | Blockers |
| ---: | --- | --- | --- | ---: | ---: | --- |
| 1 | `Penance` | `direct_hand_to_top_setup` | `needs_safe_cut_model` | `true` | `false` | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` |
| 2 | `Galvanoth` | `top_card_free_cast_engine` | `needs_safe_cut_model` | `true` | `false` | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` |
| 3 | `Dragon's Rage Channeler` | `noncreature_spell_surveillance` | `needs_safe_cut_model` | `true` | `false` | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` |
| 4 | `Valakut Awakening // Valakut Stoneforge` | `modal_hand_refresh` | `needs_safe_cut_model` | `true` | `false` | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` |
| 5 | `Wheel of Fortune` | `mass_redraw_high_variance` | `needs_safe_cut_model` | `true` | `false` | `deck_607_protected_no_mutation, miracle_access_first_preflight_closed, needs_named_same_lane_safe_cut_model, no_natural_gate_ready_row` |

## Required Trace Floors

- strategic_floors_from_607: `5` floors tracked
- strategic details: `{"lorehold_cost_paid": 27, "lorehold_spell_cast": 22, "lorehold_upkeep_rummage": 5, "miracle_cast": 4, "topdeck_manipulation_activated": 5}`
- anchor details: `{"Land Tax": 1, "Library of Leng": 0, "Lorehold, the Historian": 3, "Scroll Rack": 1, "Sensei's Divining Top": 2, "The Mind Stone": 2, "Urza's Saga": 1}`

## Required Before Any Natural Gate

- name the exact current 607 cut slot and functional lane
- preserve or beat current 607 strategic floors for miracle/topdeck execution
- preserve or beat current 607 natural access to topdeck anchors
- show candidate card drawn/cast/activated in focused traces
- tie or beat 607 in the same opponent and seed window
- avoid fast-pressure regression before any deck mutation

## Protected 607 Anchors

`Bender's Waterskin`, `Creative Technique`, `Land Tax`, `Library of Leng`, `Lorehold, the Historian`, `Mizzix's Mastery`, `Molecule Man`, `Scroll Rack`, `Sensei's Divining Top`, `Storm Herd`, `The Mind Stone`, `The Scarlet Witch`, `Urza's Saga`, `Victory Chimes`

## Decision

- current_best_baseline: `deck_607`
- highest_learning_priority: `Penance`
- allow_forced_access_microbenchmarks: `true`
- allow_natural_gate_now: `false`
- allow_deck_mutation_now: `false`
- promotion_allowed: `false`
- reason: The topdeck cards are good learning targets because they directly test Lorehold's miracle-access problem. They still have zero safe-cut/natural-gate proof, so the only permitted next step is forced-access diagnostics that cannot promote or mutate 607.
- next_action: `build_forced_access_microbenchmarks_for_topdeck_candidates_without_deck_mutation`
