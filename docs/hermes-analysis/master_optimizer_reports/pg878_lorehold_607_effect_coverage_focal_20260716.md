# Battle Effect Coverage Audit

- generated_at: 2026-07-16T09:06:55.682932+00:00
- deck_id: 607
- opponents_loaded: 0
- total_card_instances: 100
- unique_cards: 94
- runtime_safe_rule_names: 7009
- active_or_review_rule_names: 8073
- non_runtime_safe_rule_names: 1064
- needs_review_rule_names: 1064
- review_only_rule_names: 29
- annotation_only_rule_names: 0
- non_runtime_other_rule_names: 0
- review_status_counts: {"active": 68, "needs_review": 1064, "verified": 6941}
- execution_status_counts: {"auto": 8044, "review_only": 29}

## Source Totals

| Source | Count |
| --- | ---: |
| battle_rule_curated | 66 |
| type_land | 34 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 12 |
| land_utility_ability_not_modeled | 6 |
| oracle_silence_mismatch | 1 |
| oracle_target_removal_mismatch | 4 |
| temporary_effect_not_explicit | 9 |
| trigger_not_explicit | 8 |

## Deck Coverage

| Deck | Cards | Battle Rule Curated | Type Land | Flagged |
| --- | ---: | ---: | ---: | ---: |
| Lorehold target deck | 100 | 66 | 34 | 32 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Surge to Victory | pump_all | battle_rule_curated | cast_permission_not_explicit, oracle_target_removal_mismatch, temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Fated Clash | fated_clash_protect_then_destroy | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Flawless Maneuver | indestructible | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Mizzix's Mastery | overload_recursion | battle_rule_curated | cast_permission_not_explicit, oracle_target_removal_mismatch | Lorehold target deck |
| Pinnacle Monk // Mystic Peak | creature | battle_rule_curated | temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Thor, God of Thunder | creature | battle_rule_curated | oracle_target_removal_mismatch, trigger_not_explicit | Lorehold target deck |
| Artist's Talent | draw_engine | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Avatar's Wrath | airbend_other_creatures | battle_rule_curated | oracle_silence_mismatch | Lorehold target deck |
| Call Forth the Tempest | damage_wipe | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Creative Technique | exile_top_nonland_free_cast | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Dawn's Truce | gift_hexproof_indestructible | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Deflecting Swat | redirect_removal | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Esper Sentinel | draw_engine | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Furygale Flocking | token_maker | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Giver of Runes | creature | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Improvisation Capstone | exile_value | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Insurrection | steal_all_creatures | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Lorehold, the Historian | passive | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Molecule Man | passive | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Monument to Endurance | discard_trigger_modal_draw_treasure_opponent_life_loss | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Mother of Runes | creature | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Prismari Pianist | token_maker | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Reforge the Soul | draw_cards | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Rise of the Eldrazi | composite_resolution | battle_rule_curated | oracle_target_removal_mismatch | Lorehold target deck |
| Smothering Tithe | ramp_engine | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Winds of Abandon | remove_creature | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Eiganjo, Seat of the Empire | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
| Glittering Massif | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
| Plaza of Heroes | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
| Sunbaked Canyon | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
| Urza's Saga | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
| War Room | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
