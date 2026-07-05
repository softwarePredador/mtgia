# Lorehold Pressure Package Size Router

- Generated at: `2026-07-05T03:41:09Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Contract report: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json`
- Cut-pool report: `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.json`
- Decision status: `smaller_pressure_packages_blocked_current_607`
- Packages evaluated: `10`
- Singleton packages: `4`
- Pair packages: `6`
- Gate-ready packages: `0`
- Diagnostic-only packages: `0`
- Gate-ready cut count: `0`
- Diagnostic cut count: `0`
- Hypothesis natural gate-ready count: `0`
- Best singleton learning package: `pressure_1_card_young_pyromancer`
- Recommended next action: `build_single_card_cut_safety_model_or_non_deck_forced_diagnostic`

## Package Queue

| Package | Adds | Required cuts | Status | Score | Blockers |
| --- | --- | ---: | --- | ---: | --- |
| pressure_1_card_young_pyromancer | Young Pyromancer | 1 | `blocked_no_cut_or_hypothesis_capacity` | 75 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_1_card_guttersnipe | Guttersnipe | 1 | `blocked_no_cut_or_hypothesis_capacity` | 71 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_1_card_monastery_mentor | Monastery Mentor | 1 | `blocked_no_cut_or_hypothesis_capacity` | 67 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_1_card_storm_kiln_artist | Storm-Kiln Artist | 1 | `blocked_no_cut_or_hypothesis_capacity` | 19 | blocked_prior_reject, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, no_card_level_natural_gate_ready |
| pressure_2_card_young_pyromancer_guttersnipe | Young Pyromancer, Guttersnipe | 2 | `blocked_no_cut_or_hypothesis_capacity` | 146 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_2_card_young_pyromancer_monastery_mentor | Young Pyromancer, Monastery Mentor | 2 | `blocked_no_cut_or_hypothesis_capacity` | 142 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_2_card_guttersnipe_monastery_mentor | Guttersnipe, Monastery Mentor | 2 | `blocked_no_cut_or_hypothesis_capacity` | 138 | insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_2_card_young_pyromancer_storm_kiln_artist | Young Pyromancer, Storm-Kiln Artist | 2 | `blocked_no_cut_or_hypothesis_capacity` | 94 | blocked_prior_reject, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_2_card_guttersnipe_storm_kiln_artist | Guttersnipe, Storm-Kiln Artist | 2 | `blocked_no_cut_or_hypothesis_capacity` | 90 | blocked_prior_reject, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |
| pressure_2_card_monastery_mentor_storm_kiln_artist | Monastery Mentor, Storm-Kiln Artist | 2 | `blocked_no_cut_or_hypothesis_capacity` | 86 | blocked_prior_reject, insufficient_diagnostic_cut_capacity, insufficient_hypothesis_natural_gate_capacity, insufficient_seed_safe_cut_capacity, missing_current_hypothesis_queue, no_card_level_natural_gate_ready |

## External Support

- `GameTyrant Lorehold deck tech`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech - Monastery Mentor and Young Pyromancer convert spell chains into bodies; Guttersnipe turns multiple spells into noncombat damage; Storm-Kiln Artist supports big turns through Treasure.
- `EDHREC Lorehold core spellslinger`: https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger - Current public tags keep Lorehold in topdeck, spellslinger, discard, and reanimator lanes; pressure work must preserve those axes.
- `Draftsim Lorehold guide`: https://draftsim.com/lorehold-the-historian-edh-deck/ - Lorehold value depends on miracle setup and topdeck manipulation such as Library of Leng, Brainstone, and Scroll Rack; pressure creatures are costly if they dilute that engine.

## Method Notes

- This router does not generate or mutate a decklist.
- A smaller pressure package still needs one cut per added card.
- Missing hypothesis-queue rows and prior rejects block natural gates even when local runtime preflight passes.
- If no seed-safe or diagnostic cut capacity exists, the next work is cut-safety modeling or non-deck forced diagnostics, not a natural battle.
