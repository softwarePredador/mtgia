# Lorehold External Shell Gate Synthesis

- Generated at: `2026-07-04T21:45:06Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- External reconciliation: `docs/hermes-analysis/master_optimizer_reports/lorehold_external_evidence_reconciler_20260704_current.json`
- Shells audited: `6`
- Promotable shells: `0`
- External signals: `8`
- Recommended next action: `promote_no_shell_keep_607_and_define_smaller_diagnostics`
- Shell decision counts: `{"not_promotable_structure_below_607": 5, "reject_confirmed_lost_to_607": 1}`
- Signal synthesis counts: `{"blocked_by_cut_safety": 2, "blocked_no_named_cut": 1, "covered_by_existing_nonpromotable_shell": 1, "partial_or_uncovered_full_shell": 3, "supports_current_607": 1}`

## Learning Model

- Legality and external popularity are input lanes, not promotion proof.
- For Lorehold, card value is measured by role fit in miracle/topdeck timing, early mana floor, pressure survival, and conversion window.
- A staple only becomes a candidate when it has a named cut or a declared full-shell contract.
- A shell that ranks below 607 structurally or loses the equal gate remains learning evidence, not a deck replacement.
- Winota/fast-pressure regression is a hard guardrail even when aggregate wins improve.

## Shell Decisions

| Shell | Candidate rank | Baseline rank | Lands | Ramp | Draw | Decision | Gate summary |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| access_density_control | 4 | 1 | 34 | 19 | 18 | `not_promotable_structure_below_607` | 607 0/4; candidate 1/4 |
| miracle_pressure_conversion | 2 | 1 | 34 | 19 | 15 | `not_promotable_structure_below_607` | 607 0/4; candidate 0/4 |
| miracle_topdeck_control | 3 | 1 | 34 | 20 | 18 | `not_promotable_structure_below_607` | 607 0/4; candidate 1/4 |
| recursion_discard_engine | 4 | 1 | 34 | 21 | 18 | `not_promotable_structure_below_607` | 607 0/4; candidate 1/4 |
| recursion_discard_pressure_repair | 4 | 1 | 34 | 17 | 18 | `not_promotable_structure_below_607` | 607 0/4; candidate 0/4 |
| spellchain_big_sorcery | 4 | 1 | 33 | 21 | 18 | `reject_confirmed_lost_to_607` | 607 8/24; candidate 3/24 |

## External Signal Coverage

| Signal | Synthesis status | Cards checked | Best shell coverage | Next action |
| --- | --- | --- | --- | --- |
| external_topdeck_miracle_anchor_floor | `supports_current_607` | - | access_density_control 0/0 | `keep_current_anchor` |
| external_brainstone_planetarium_topdeck_extension | `blocked_by_cut_safety` | Brainstone, Planetarium of Wan Shi Tong | - | `do_not_gate_until_cut_safety_changes` |
| external_approach_lapse_deterministic_line | `blocked_no_named_cut` | Lapse of Certainty | - | `name_cut_or_model_as_diagnostic_only` |
| external_cedh_fast_mana_engine | `partial_or_uncovered_full_shell` | Chrome Mox, Mana Vault, Grim Monolith, Mox Diamond, Lion's Eye Diamond, Lotus Petal | miracle_topdeck_control 1/6 | `define_smaller_named_shell_contract_before_battle` |
| external_one_ring_value_engine | `blocked_by_cut_safety` | The One Ring | - | `do_not_gate_until_cut_safety_changes` |
| external_spell_pressure_creature_package | `partial_or_uncovered_full_shell` | Monastery Mentor, Young Pyromancer, Guttersnipe, Storm-Kiln Artist | miracle_topdeck_control 1/4 | `define_smaller_named_shell_contract_before_battle` |
| external_breach_wheel_aetherflux_conversion_shell | `covered_by_existing_nonpromotable_shell` | Underworld Breach, Wheel of Fortune, Aetherflux Reservoir, Birgi, God of Storytelling // Harnfel, Horn of Bounty | access_density_control 4/4 | `do_not_repeat_full_shell_without_new_contract_change` |
| external_discard_reanimator_alt_shell | `partial_or_uncovered_full_shell` | Storm of Souls, Late to Dinner, Karmic Guide | - | `define_smaller_named_shell_contract_before_battle` |

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

- The script reads existing 2026-07-03 shell matrices, decklists, fixed-607 gates, and confirm gates when present.
- Smoke-only positives are not promotion proof.
- Exact card coverage means the shell contained every non-607 add card from the external signal; it does not prove that the shell executed that package well.
- This script does not mutate PostgreSQL, SQLite, deck rows, or generated decklists.
