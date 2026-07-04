# Lorehold Spell Pressure Trace Miner

- generated_at: `2026-07-04T23:04:17Z`
- status: `pressure_trace_refutes_pressure_causality`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate_record: `{"games": 4, "losses": 3, "stalls": 0, "wins": 1}`
- baseline_record: `{"games": 4, "losses": 4, "stalls": 0, "wins": 0}`
- baseline_rank: `1`
- candidate_rank: `2`
- tested_pressure_cards: `["Guttersnipe", "Young Pyromancer", "Monastery Mentor"]`
- wins_with_pressure_card_events: `0`
- losses_with_pressure_card_events: `1`
- wins_with_pressure_conversion_events: `0`
- losses_with_pressure_conversion_events: `1`
- pressure_cards_by_result: `{"loss": ["Young Pyromancer"]}`
- failure_modes: `["head_to_head_lost_to_607", "parent_decision_blocks_confirmation", "pressure_seen_only_in_losses", "sisay_win_carried_by_core_topdeck_miracle_engine", "still_structurally_below_607", "winning_game_has_no_pressure_card_events"]`
- promotion_allowed: `false`
- confirmation_allowed: `false`

## Sisay Win Trace

- opponent: `Sisay, Weatherlight Captain #61 (real)`
- turns: `17`
- pressure_card_event_counts: `{}`
- pressure_conversion_event_counts: `{}`
- core_strategic_event_counts: `{"discard_to_top_replacement": 12, "lorehold_rummage_discard_to_top": 12, "lorehold_spell_cast": 20, "lorehold_upkeep_rummage": 12, "miracle_cast": 5, "topdeck_manipulation_activated": 8}`
- core_card_event_counts: `{"cost_paid:Library of Leng": 1, "cost_paid:Lorehold, the Historian": 2, "cost_paid:Scroll Rack": 1, "cost_paid:Sensei's Divining Top": 2, "miracle_cast:Mizzix's Mastery": 1, "spell_cast:Library of Leng": 1, "spell_cast:Scroll Rack": 1, "spell_cast:Sensei's Divining Top": 2, "spell_resolved:Library of Leng": 1, "spell_resolved:Mizzix's Mastery": 1, "spell_resolved:Scroll Rack": 1, "spell_resolved:Sensei's Divining Top": 2, "topdeck_manipulation_activated:Scroll Rack": 7, "topdeck_manipulation_activated:Sensei's Divining Top": 1}`

## Deckbuilding Priority Update

- protect_engine_cards: `["Bender's Waterskin", "Library of Leng", "Scroll Rack", "Sensei's Divining Top", "The Mind Stone", "The Scarlet Witch", "Victory Chimes"]`
- demote_until_proven: `["Young Pyromancer", "Monastery Mentor"]`
- next_pressure_priority: `["Guttersnipe", "Storm-Kiln Artist"]`
- reason: The only candidate win did not use the tested pressure creatures. It used the protected Lorehold topdeck/miracle engine, especially Scroll Rack, Sensei's Divining Top, discard-to-top replacement, Lorehold rummage, and Mizzix's Mastery. Future pressure tests should prefer mana-conversion pressure such as Storm-Kiln Artist plus Guttersnipe only if seed-safe same-lane cuts exist.

## External Learning

- EDHREC average optimized spellslinger: https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger
- EDHREC Boros Miracles budget article: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
- GameTyrant Lorehold deck tech: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech
- Card Kingdom Lorehold synergy article: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/

## Decision

- do_not_confirm_current_spell_pressure_topdeck_shell
- treat_young_pyromancer_result_as_loss_only_sampling_not_win_proof
- mine_or_generate_a_storm_kiln_plus_guttersnipe_hypothesis_before_more_token_pressure
- require_seed_safe_same_lane_cuts_before_any_new_natural_gate
