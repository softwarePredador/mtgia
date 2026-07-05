# Lorehold Pressure Safe-Cut Expansion Model

- generated_at: `2026-07-05T01:10:45Z`
- status: `pressure_cut_expansion_no_seed_safe_cut_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- current_baseline: `deck_607`
- seed_safe_cut_ready_count: `0`
- same_lane_only_cut_count: `2`
- gate_ready_package_count: `0`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`

## Deckbuilding Priority Model

| Priority | Meaning |
| ---: | --- |
| 1 | `legal_identity_and_deck_shape` |
| 2 | `commander_intent_and_win_plan` |
| 3 | `mana_foundation_lands_sources_ramp` |
| 4 | `card_flow_selection_and_resource_engine` |
| 5 | `interaction_protection_and_resilience` |
| 6 | `commander_specific_packages` |
| 7 | `staple_impact_by_role` |
| 8 | `same_lane_cut_cost` |
| 9 | `battle_and_replay_validation` |

## Staple, Artifact, And Land Learning

| Card | Lane | Status | Reason |
| --- | --- | --- | --- |
| Mana Vault | `artifact_fast_mana_game_changer` | `blocked_not_auto_include` | Legal/colorless power is real, but prior Lorehold evidence rejected the one-card Bender's Waterskin replacement. Early mana is protected unless a same-lane plan preserves the miracle timing window. |
| The One Ring | `artifact_draw_protection_game_changer` | `blocked_not_auto_include` | The card is a powerful draw/protection engine, but tested draw/value cuts lost to protected 607. Its value is contextual only if a safe draw/protection cut and natural trace proof appear. |
| Storm-Kiln Artist | `contextual_spell_payoff_mana_extension` | `research_package_only` | It fits Lorehold's spell-chain pressure/treasure lane, but prior evidence forbids treating it as a generic mana-rock replacement. |
| Plateau | `land_untapped_typed_dual` | `simple_swap_rejected` | A cleaner land can still fail if the active shell loses battle timing. Both Plateau over Radiant Summit and Plateau over Turbulent Steppe were rejected in copied-DB diagnostics. |

## Pressure Package Routes

| Route | Adds | Status | Required Cuts | Seed-Safe Cuts | Gate Ready |
| --- | --- | --- | ---: | ---: | --- |
| primary_four_card_pressure_package | Monastery Mentor, Young Pyromancer, Guttersnipe, Storm-Kiln Artist | `blocked_no_seed_safe_cut_plan` | 4 | 0 | `false` |
| pressure_natural_trigger_pair_guttersnipe_young_pyromancer | Guttersnipe, Young Pyromancer | `blocked_no_seed_safe_cut` | 2 | 0 | `false` |
| pressure_single_guttersnipe | Guttersnipe | `blocked_no_seed_safe_cut` | 1 | 0 | `false` |
| pressure_single_young_pyromancer | Young Pyromancer | `blocked_no_seed_safe_cut` | 1 | 0 | `false` |
| pressure_single_monastery_mentor_probe_only | Monastery Mentor | `blocked_no_seed_safe_cut` | 1 | 0 | `false` |
| storm_kiln_artist_haze_of_rage_combo_research | Storm-Kiln Artist, Haze of Rage | `research_only_runtime_and_cut_safety_required` | 2 | 0 | `false` |

## Cut Expansion Targets

| Rank | Card | Lane | Investigation Status | Exposure | Direct Events |
| ---: | --- | --- | --- | ---: | ---: |
| 1 | Creative Technique | `big_spell_value` | `same_lane_microbenchmark_only` | 58 | 54 |
| 2 | Bender's Waterskin | `early_mana` | `same_lane_microbenchmark_only` | 268 | 216 |
| 3 | Generous Gift | `removal` | `blocked_high_exposure_anchor` | 52 | 19 |
| 4 | Improvisation Capstone | `draw` | `blocked_structural_dependency` | 59 | 49 |
| 5 | Esper Sentinel | `draw` | `blocked_high_exposure_anchor` | 527 | 442 |
| 6 | Path to Exile | `removal` | `blocked_high_exposure_anchor` | 166 | 117 |
| 7 | Swords to Plowshares | `removal` | `blocked_high_exposure_anchor` | 271 | 240 |
| 8 | Stroke of Midnight | `removal` | `blocked_prior_rejected_signature` | 43 | 32 |
| 9 | Winds of Abandon | `removal` | `blocked_prior_rejected_signature` | 59 | 32 |
| 10 | Monument to Endurance | `early_mana` | `blocked_high_exposure_anchor` | 73 | 19 |
| 11 | Sensei's Divining Top | `draw` | `blocked_high_exposure_anchor` | 3816 | 3514 |
| 12 | Smothering Tithe | `early_mana` | `blocked_high_exposure_anchor` | 859 | 801 |

## External Learning

- Wizards Commander format: https://magic.wizards.com/en/formats/commander -> `legal_identity_gate_only`
- Official Commander rules: https://mtgcommander.net/index.php/rules/ -> `shape_singleton_color_identity_gate`
- EDHREC How to Build a Commander Deck: https://edhrec.com/articles/how-to-build-a-commander-deck -> `role_density_and_curve_are_inputs_not_promotion`
- Commander Spellbook Storm-Kiln Artist + Haze of Rage: https://commanderspellbook.com/combo/3940-5195/ -> `combo_package_research_requires_runtime_cut_and_battle_proof`
- Scryfall card data: https://scryfall.com/docs/api/cards -> `card_data_is_not_deck_quality_by_itself`

## Decision

- keep_607_as_protected_baseline: `true`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The model has real external pressure/combo signals and internal trigger evidence, but zero seed-safe cuts. The next deckbuilding lesson is cut-cost discovery, not another natural battle gate.
- next_actions:
  - do_not_mutate_or_replace_deck_607
  - do_not_run_natural_battle_for_pressure_package_until_seed_safe_cut_exists
  - treat Creative Technique and Bender's Waterskin as diagnostic-only same-lane cases
  - keep Mana Vault and The One Ring as legal staple hypotheses blocked by prior evidence and cut safety
  - mine or generate more trace evidence specifically for low-exposure non-anchor slots
