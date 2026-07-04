# Lorehold External Evidence Reconciliation

- Generated at: `2026-07-04T21:35:56Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- External corpus: `docs/hermes-analysis/LOREHOLD_EXTERNAL_EVIDENCE_CORPUS_2026-07-04.json`
- Champion snapshot: `docs/hermes-analysis/master_optimizer_reports/lorehold_current_champion_snapshot_20260704_learning_refresh.json`
- Trace cut evidence: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json`
- Planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260704_role_tag_repair_learning.json`
- External signals: `8`
- Direct deck-change ready: `0`
- Next learning queue: `7`
- Recommended next action: `continue_external_research_but_keep_607_protected`
- Status counts: `{"already_represented_by_current_607": 1, "blocked_by_cut_safety": 2, "blocked_no_named_cut": 1, "requires_separate_full_shell_contract": 4}`
- Blocker counts: `{"no_named_cut_card": 1, "not_a_current_one_for_one_cut": 4, "prior_internal_inconclusive_low_exposure": 1, "prior_internal_reject": 3, "proposed_cut_not_seed_safe": 2}`

## Signals

| Signal | Status | Lane | Add cards missing from 607 | Proposed cuts | Next action |
| --- | --- | --- | --- | --- | --- |
| external_topdeck_miracle_anchor_floor | `already_represented_by_current_607` | `topdeck_miracle_setup` | - | - | `treat_as_external_support_for_existing_607_anchor` |
| external_brainstone_planetarium_topdeck_extension | `blocked_by_cut_safety` | `topdeck_miracle_setup` | Brainstone, Planetarium of Wan Shi Tong | Creative Technique | `do_not_gate_until_cut_safety_changes` |
| external_approach_lapse_deterministic_line | `blocked_no_named_cut` | `deterministic_finisher` | Lapse of Certainty | - | `find_seed_safe_cut_or_model_as_diagnostic_only` |
| external_cedh_fast_mana_engine | `requires_separate_full_shell_contract` | `early_plan` | Chrome Mox, Mana Vault, Grim Monolith, Mox Diamond, Lion's Eye Diamond, Lotus Petal | Bender's Waterskin | `declare_full_shell_contract_before_battle` |
| external_one_ring_value_engine | `blocked_by_cut_safety` | `card_draw_selection` | The One Ring | Creative Technique, Improvisation Capstone, Redirect Lightning | `do_not_gate_until_cut_safety_changes` |
| external_spell_pressure_creature_package | `requires_separate_full_shell_contract` | `pressure_absorber` | Monastery Mentor, Young Pyromancer, Guttersnipe, Storm-Kiln Artist | - | `declare_full_shell_contract_before_battle` |
| external_breach_wheel_aetherflux_conversion_shell | `requires_separate_full_shell_contract` | `spell_chain_conversion` | Underworld Breach, Wheel of Fortune, Aetherflux Reservoir, Birgi, God of Storytelling // Harnfel, Horn of Bounty | - | `declare_full_shell_contract_before_battle` |
| external_discard_reanimator_alt_shell | `requires_separate_full_shell_contract` | `graveyard_recursion` | Storm of Souls, Late to Dinner, Karmic Guide | - | `declare_full_shell_contract_before_battle` |

## Next Learning Queue

- `external_brainstone_planetarium_topdeck_extension` status `blocked_by_cut_safety`: do_not_gate_until_cut_safety_changes.
- `external_approach_lapse_deterministic_line` status `blocked_no_named_cut`: find_seed_safe_cut_or_model_as_diagnostic_only.
- `external_cedh_fast_mana_engine` status `requires_separate_full_shell_contract`: declare_full_shell_contract_before_battle.
- `external_one_ring_value_engine` status `blocked_by_cut_safety`: do_not_gate_until_cut_safety_changes.
- `external_spell_pressure_creature_package` status `requires_separate_full_shell_contract`: declare_full_shell_contract_before_battle.
- `external_breach_wheel_aetherflux_conversion_shell` status `requires_separate_full_shell_contract`: declare_full_shell_contract_before_battle.
- `external_discard_reanimator_alt_shell` status `requires_separate_full_shell_contract`: declare_full_shell_contract_before_battle.

## Sources

- `wizards_commander_format`: https://magic.wizards.com/en/formats/commander (official_rules)
- `scryfall_lorehold_mana_vault_one_ring`: https://scryfall.com/ (oracle_legality_game_changer)
- `edhrec_miracles_every_turn`: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander (public_strategy_article)
- `draftsim_approach_lapse_combo`: https://draftsim.com/lorehold-approach-combo/ (public_combo_article)
- `edhrec_cedh_average_deck`: https://edhrec.com/average-decks/lorehold-the-historian/cedh (public_average_deck)
- `draftsim_lorehold_deck_guide`: https://draftsim.com/lorehold-the-historian-edh-deck/ (public_strategy_article)
- `gametyrant_lorehold_deck_tech`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech (public_strategy_article)
- `cardkingdom_lorehold_synergy`: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/ (public_strategy_article)

## Method Notes

- External popularity is source evidence, not a deck promotion.
- A signal can become a deck-change candidate only with a named add/cut package and seed-safe cut.
- Full-shell signals require a separate shell contract and cannot reuse the exhausted one-for-one gate.
- This script is read-only and does not mutate PostgreSQL, SQLite, or deck contents.
