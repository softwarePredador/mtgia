# Lorehold Promotion Readiness Synthesis

- generated_at: `2026-07-05T03:14:39Z`
- deck_id: `607`
- status: `promotion_readiness_keep_607_no_candidate_ready`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- total cards: `100`
- reports loaded: `7/7`
- unique candidates considered: `139`
- gate-ready candidates: `0`
- hypotheses needing named cut/gate: `98`
- blocked/rejected rows: `39`
- role mapping watch items: `0`
- promotion_allowed: `false`

## Axis Assessments

| Axis | Status | Class | Report |
| --- | --- | --- | --- |
| `card_value` | `card_value_priority_no_direct_cut_ready_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_card_value_priority_synthesis_20260705_current_relearn.json` |
| `interaction` | `interaction_resilience_no_direct_swap_ready_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_interaction_resilience_synthesis_20260704_learning.json` |
| `mana` | `mana_sequence_no_direct_auto_upgrade_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_sequence_policy_synthesis_20260705_current_relearn.json` |
| `payoff` | `payoff_finisher_recursion_no_direct_swap_ready_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_payoff_finisher_recursion_synthesis_20260704_learning.json` |
| `pressure` | `pressure_micro_package_no_gate_ready_keep_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_micro_package_planner_20260704_current.json` |
| `selection` | `selection_access_no_swap_ready_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_selection_access_synthesis_20260704_learning.json` |
| `staple` | `staple_policy_no_direct_auto_include_current_607` | `keep_607` | `docs/hermes-analysis/master_optimizer_reports/lorehold_staple_policy_synthesis_20260704_sequence_learning_probe.json` |

## Candidate Pressure

- classification counts: `{"already_in_607": 28, "blocked_or_rejected": 39, "hypothesis_or_gate_needed": 98}`
- lane counts: `{"access_tutor": 2, "banned_fast_mana": 2, "card_draw_selection": 8, "colored_land_fixing": 17, "combo_synergy_and_finishers": 1, "contextual_mana_source": 2, "cost_reducer": 2, "early_colored_rock": 6, "early_colorless_burst": 1, "fast_colorless_burst": 2, "fast_or_utility_land": 3, "generic_or_low_context_signal": 10, "interaction_removal": 8, "mana_base": 12, "premium_mox_fast_mana": 4, "pressure_payoff": 4, "pressure_protection": 2, "protection_resilience": 5, "ramp": 27, "recursion_recovery": 3, "ritual_or_spell_burst": 2, "spot_removal": 3, "stack_or_spell_protection": 7, "topdeck_protection": 2, "topdeck_setup": 1, "treasure_or_discard_ramp": 6, "turn_cycle_miracle_mana": 2, "tutors_access": 6, "unknown": 14, "utility_land": 1}`

### Highest Pressure Hypotheses

- `Great Furnace` from `mana` lane `colored_land_fixing`: `candidate_requires_same_lane_cut_and_gate`
- `Ancient Den` from `mana` lane `colored_land_fixing`: `candidate_land_upgrade_requires_current_land_cut`
- `City of Brass` from `mana` lane `colored_land_fixing`: `candidate_land_upgrade_requires_current_land_cut`
- `Mana Confluence` from `mana` lane `colored_land_fixing`: `candidate_land_upgrade_requires_current_land_cut`
- `Plateau` from `mana` lane `colored_land_fixing`: `candidate_land_upgrade_requires_current_land_cut`
- `Treasonous Ogre` from `mana` lane `contextual_mana_source`: `candidate_requires_same_lane_cut_and_sequence_gate`
- `Pyretic Ritual` from `mana` lane `early_colored_rock`: `candidate_requires_same_lane_cut_and_sequence_gate`
- `Grim Monolith` from `mana` lane `fast_colorless_burst`: `candidate_fast_mana_requires_fixing_and_use_gate`
- `City of Traitors` from `mana` lane `fast_or_utility_land`: `candidate_land_requires_named_land_cut_and_equal_gate`
- `Gemstone Caverns` from `mana` lane `fast_or_utility_land`: `candidate_land_requires_named_land_cut_and_equal_gate`
- `Rite of Flame` from `mana` lane `ritual_or_spell_burst`: `candidate_spell_ramp_requires_spell_slot_gate`
- `Storm-Kiln Artist` from `mana` lane `treasure_or_discard_ramp`: `candidate_hypothesis_requires_named_cut_and_equal_gate`

## Promotion Gate Checklist

- `baseline_deck_shape`: passed `true`; 100 cards, commanders=['Lorehold, the Historian']
- `all_axis_reports_loaded`: passed `true`; card_value, interaction, mana, payoff, pressure, selection, staple
- `axis_decisions_do_not_promote_candidate`: passed `true`; gate_ready_candidate_count=0
- `role_tag_watch_before_new_cuts`: passed `true` required-before-promotion; role_mapping_watch_items=0
- `same_lane_cut_named`: passed `false` required-before-promotion; No current candidate has a complete named cut plus equal gate proof.
- `equal_battle_gate_with_card_use`: passed `false` required-before-promotion; No current challenger has equal-opponent, equal-seed, card-used promotion proof over 607.

## Learned Deckbuilding Model

### Deckbuilding Principles
- Legality is only the first filter; promotion needs commander-plan fit and battle proof.
- Every replacement must name the same-lane card it challenges.
- A famous staple is pressure to investigate, not automatic inclusion.
- Protected anchors cannot be cut unless the candidate preserves the same function and wins an equal gate.
- A candidate must be drawn/cast/used in evidence traces before a battle result can promote it.

### Lorehold Priority Order
- commander miracle/topdeck cadence
- Top/Rack/Library/Land Tax access package
- turn-cycle miracle mana such as Bender's Waterskin and Victory Chimes
- interaction/protection that keeps the commander turn alive
- payoff conversion and recursion that actually closes games
- generic staples only after lane and sequence proof

### Mana Policy
- Keep land/ramp counts and Boros source counts inside the proven 607 profile unless a candidate proves the tradeoff.
- Fast colorless mana has to improve the critical turn without breaking colored fixing or miracle cadence.
- Mana Vault is not blocked by Commander legality; it is blocked by current 607 gate evidence.

### Staple Policy
- The One Ring is legal but not automatically better than the current draw/protection/topdeck structure.
- Original Moxen, Mana Crypt, and Jeweled Lotus remain Commander-banned under current official banlist evidence.
- Premium or cEDH-style packages require budget/policy approval plus same-lane promotion proof.

### Pressure Policy
- Pressure payoffs are valid hypotheses only when they preserve the miracle/topdeck cadence that makes 607 win.
- A pressure package with a better structural score is still rejected if its natural traces collapse topdeck setup.
- Forced-access probes explain card behavior, but natural promotion still requires same-lane cuts and equal-gate proof.

## External Sources

- Wizards Commander format page: https://magic.wizards.com/en/formats/commander
- Wizards banned and restricted list: https://magic.wizards.com/en/banned-restricted-list
- Scryfall Mana Vault API: https://api.scryfall.com/cards/named?exact=Mana%20Vault
- Scryfall The One Ring API: https://api.scryfall.com/cards/named?exact=The%20One%20Ring
- EDHREC Lorehold articles: https://edhrec.com/articles/tag/lorehold

## Decision

- keep_607_as_protected_baseline: `true`
- promotion_allowed: `false`
- reason: The current learning axes agree that 607 remains protected: no candidate has a complete same-lane cut, equal-seed battle gate, and card-use proof. Legal cards such as Mana Vault and The One Ring stay hypotheses or blocked prior evidence until they beat the current role they challenge.
- next_actions:
  - generate only named same-lane packages from a specific 607 failure target
  - run equal opponent and seed gates with trace proof that the candidate was drawn, cast, and used
  - promote only if the challenger preserves land/ramp/draw/removal/protection/wincon density and beats 607
