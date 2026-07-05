# Lorehold Engine-Preserving Pressure Conversion Router

- Generated at: `2026-07-05T04:02:31Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `engine_preserving_pressure_conversion_not_gate_ready_keep_607`
- Routes evaluated: `3`
- Gate-ready routes: `0`
- Diagnostic-ready routes: `0`
- Gate-ready cut count: `0`
- Hypothesis natural gate-ready count: `0`
- Best next learning route: `guttersnipe_storm_kiln_engine_preserving_pair`
- Best next learning status: `best_next_learning_route_contract_required_no_deck_action`
- Storm-Kiln prior decision: `rejected_for_deck_promotion_pressure_regression`
- Recommended next action: `build_engine_preserving_hypothesis_contract_and_find_named_safe_cuts`

## Source Reports

- `closing_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.json`
- `cut_pool`: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.json`
- `miracle_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_trace_failure_miner_20260704_current.json`
- `package_router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_package_size_router_20260705_current_relearn.json`
- `pressure_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json`
- `spell_pressure_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_spell_pressure_trace_miner_20260704_current.json`
- `storm_kiln_decision`: `docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_arcane_runtime_decision_20260630.md`
- `young_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_young_pyromancer_pressure_window_trace_synthesis_20260705_current_relearn.json`

## Route Queue

| Route | Adds | Lane | Required cuts | Status | Blockers | Next action |
| --- | --- | --- | ---: | --- | --- | --- |
| guttersnipe_storm_kiln_engine_preserving_pair | Guttersnipe, Storm-Kiln Artist | engine_preserving_pressure_conversion_pair | 2 | `best_next_learning_route_contract_required_no_deck_action` | blocked_prior_reject, fast_pressure_slice_not_protected, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready, no_current_positive_guttersnipe_trace, pressure_causality_unproven, pressure_conversion_unproven, storm_kiln_arcane_signet_swap_rejected | write_hypothesis_contract_and_find_two_seed_safe_same_lane_cuts_before_any_battle |
| guttersnipe_noncombat_spell_pressure | Guttersnipe | noncombat_spell_pressure | 1 | `research_candidate_missing_hypothesis_and_cut` | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready, no_current_positive_guttersnipe_trace, pressure_causality_unproven | add_only_to_hypothesis_contract_after_named_safe_cut_or_non_deck_diagnostic |
| storm_kiln_artist_mana_conversion | Storm-Kiln Artist | spell_chain_mana_conversion | 1 | `blocked_prior_reject_engine_signal_requires_new_package` | blocked_prior_reject, fast_pressure_slice_not_protected, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, no_card_level_natural_gate_ready, pressure_conversion_unproven, storm_kiln_arcane_signet_swap_rejected | do_not_retest_as_arcane_signet_swap_only_revisit_with_pressure_safe_package |

## Learning Rules

- `external_value_is_priority_not_permission`: EDHREC, Commander Spellbook, and deck-tech evidence can rank cards, but current 607 promotion still requires safe cuts, hypothesis readiness, trace proof, and equal battle gates.
- `do_not_repeat_storm_kiln_arcane_signet_swap`: Storm-Kiln has real Treasure-conversion evidence, but its direct Arcane Signet swap regressed in the Winota fast-pressure slice.
- `guttersnipe_needs_current_trace_contract`: Guttersnipe is the cleaner noncombat pressure lesson, but it is missing the current hypothesis queue and has no positive current pressure trace.
- `pair_is_learning_route_not_deck_action`: Guttersnipe plus Storm-Kiln is the next engine-preserving idea to formalize, but current cut capacity is zero and 607 remains protected.

## External Support

- `EDHREC Lorehold core spellslinger`: https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger - Public Lorehold shells remain in topdeck/spellslinger/discard lanes; pressure additions must preserve those axes.
- `Commander Spellbook Storm-Kiln Artist + Haze of Rage`: https://commanderspellbook.com/combo/3940-5195/ - Storm-Kiln can convert storm/copy chains into Treasure and magecraft loops, so it is a real conversion card rather than filler ramp.
- `GameTyrant Lorehold deck tech`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech - Guttersnipe provides direct spell damage and Storm-Kiln supports big spell turns, but both belong behind the core topdeck/miracle engine.

## Method Notes

- This router does not build, stage, or mutate any decklist.
- Deck 607 remains the protected baseline until a route has named safe cuts and passes gates.
- The pair route is intentionally ranked as learning priority even while blocked.
- A future battle requires direct Guttersnipe damage or Storm-Kiln Treasure events, not only aggregate wins.
