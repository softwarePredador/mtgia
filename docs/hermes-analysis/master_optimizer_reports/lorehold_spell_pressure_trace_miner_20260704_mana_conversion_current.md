# Lorehold Spell Pressure Trace Miner

- generated_at: `2026-07-04T23:04:17Z`
- status: `pressure_trace_partial_presence_not_conversion_proof`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate_record: `{"games": 4, "losses": 2, "stalls": 0, "wins": 2}`
- baseline_record: `{"games": 4, "losses": 4, "stalls": 0, "wins": 0}`
- baseline_rank: `1`
- candidate_rank: `2`
- tested_pressure_cards: `["Guttersnipe", "Storm-Kiln Artist"]`
- wins_with_pressure_card_events: `1`
- losses_with_pressure_card_events: `0`
- wins_with_pressure_conversion_events: `0`
- losses_with_pressure_conversion_events: `0`
- pressure_cards_by_result: `{"win": ["Storm-Kiln Artist"]}`
- failure_modes: `["head_to_head_lost_to_607", "pressure_seen_without_conversion_events", "still_structurally_below_607"]`
- promotion_allowed: `false`
- confirmation_allowed: `false`

## Sisay Win Trace

- no_sisay_win_trace: `true`

## Deckbuilding Priority Update

- protect_engine_cards: `["Bender's Waterskin", "Library of Leng", "Scroll Rack", "Sensei's Divining Top", "The Mind Stone", "The Scarlet Witch", "Victory Chimes"]`
- demote_until_proven: `["Young Pyromancer", "Monastery Mentor"]`
- next_pressure_priority: `["Guttersnipe", "Storm-Kiln Artist"]`
- reason: Pressure cards are only useful when they execute their role inside the protected Lorehold topdeck/miracle engine. A mere cost-paid or cast event is exposure, not proof of conversion; require a trigger, damage, mana-conversion, or spell-resolution signal before treating the pressure package as learned value.

## External Learning

- EDHREC average optimized spellslinger: https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger
- EDHREC Boros Miracles budget article: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
- GameTyrant Lorehold deck tech: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech
- Card Kingdom Lorehold synergy article: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/

## Decision

- do_not_confirm_current_spell_pressure_mana_conversion_shell
- treat_storm_kiln_cost_paid_as_exposure_not_conversion_proof
- repair_structural_overfill_before_larger_seed_window
- keep_607_protected_until_head_to_head_and_conversion_trace_pass
