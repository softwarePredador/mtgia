# Lorehold Young Pyromancer Pressure-Window Trace Synthesis

- Generated at: `2026-07-05T03:53:16Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `young_pyromancer_pressure_window_refuted_no_deck_action`
- Target card: `Young Pyromancer`
- Target singleton status: `young_pyromancer_singleton_no_cut_keep_607`
- Target package status: `blocked_no_cut_or_hypothesis_capacity`
- Eligible cuts: `0`
- Wins with pressure-card events: `0`
- Losses with pressure-card events: `1`
- Young Pyromancer seen only in losses: `true`
- Closing-window comparisons: `13`
- Average 607 turn advantage: `10.15`
- Miracle trace failure flags: `7`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Recommended next action: `deprioritize_young_pyromancer_until_new_pressure_cut_or_forced_diagnostic`

## Gap Alignment

| Gap | Count | Young Pyromancer Repair Status | Actionability |
| --- | ---: | --- | --- |
| candidate_died_before_closing_window | 13 | `partial_theoretical_pressure_body` | `diagnostic_only_needs_causal_trace` |
| candidate_lost_multiple_turns_before_607_finish | 13 | `partial_theoretical_pressure_body` | `diagnostic_only_needs_causal_trace` |
| lorehold_spell_volume_deficit | 13 | `indirect_only_from_more_spell_payoffs` | `weak_indirect_not_gate_ready` |
| miracle_cast_deficit | 13 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| topdeck_engine_card_deficit | 11 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| 607_mana_timing_anchor_deficit | 9 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| static_cost_reduction_deficit | 9 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| topdeck_activation_deficit | 9 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| upkeep_rummage_deficit | 9 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |
| approach_conversion_missing | 7 | `does_not_repair` | `do_not_use_young_pyromancer_for_this_gap` |

## Pressure Trace Evidence

- candidate_record: `{"games": 4, "losses": 3, "stalls": 0, "wins": 1}`
- baseline_record: `{"games": 4, "losses": 4, "stalls": 0, "wins": 0}`
- pressure_cards_by_result: `{"loss": ["Young Pyromancer"]}`
- failure_modes: `["head_to_head_lost_to_607", "parent_decision_blocks_confirmation", "pressure_seen_only_in_losses", "sisay_win_carried_by_core_topdeck_miracle_engine", "still_structurally_below_607", "winning_game_has_no_pressure_card_events"]`

## Learning Rules

- `loss_only_pressure_trace_is_not_card_proof`: Young Pyromancer appeared in pressure trace only on losses, so it cannot be promoted or used as positive 607 evidence.
- `token_pressure_does_not_replace_engine_floor`: Most closing-window gaps are miracle, topdeck, spell-volume, mana-timing, or Approach-conversion deficits that Young Pyromancer does not directly repair.
- `diagnostic_is_not_promotion`: A forced Young Pyromancer diagnostic may teach whether tokens buy time, but it must not create a deck-change claim without a named safe cut, structure matrix, natural equal gate, and direct card-use proof.

## Diagnostic Contract

- allowed_now: `false`
- promotion_allowed: `false`
- natural_battle_allowed: `false`
- required_if_run:
  - copied_db_or_non_deck_harness_only
  - no_mutation_of_deck_607
  - track_young_pyromancer_token_creation_and_damage_absorption
  - track_miracle_cast_topdeck_activation_lorehold_spell_cast_floors
  - stop_if_pressure_events_appear_only_in_losses_again

## Decision

- Keep 607 protected: `true`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Reason: Current trace evidence does not show Young Pyromancer repairing the 607 pressure window. The only existing pressure-shell win was carried by the core topdeck/miracle engine, while Young Pyromancer was observed only in losses and still has no eligible cut.
- Next actions:
  - do_not_mutate_or_replace_deck_607
  - do_not_run_a_natural_young_pyromancer_gate_now
  - deprioritize_young_pyromancer_until_a_pressure_compatible_cut_exists
  - if_learning_continues_on_tokens_use_non_deck_forced_diagnostic_only
  - prioritize engine-preserving pressure or conversion routes over broad token-pressure shells
