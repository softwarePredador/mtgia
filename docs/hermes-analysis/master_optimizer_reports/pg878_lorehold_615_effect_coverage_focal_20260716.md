# Battle Effect Coverage Audit

- generated_at: 2026-07-16T09:06:55.683625+00:00
- deck_id: 615
- opponents_loaded: 0
- total_card_instances: 100
- unique_cards: 84
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
| battle_rule_curated | 65 |
| known_cards_canonical_snapshot | 1 |
| type_land | 34 |

## Risk Flags

| Flag | Count |
| --- | ---: |
| cast_permission_not_explicit | 15 |
| land_utility_ability_not_modeled | 1 |
| oracle_silence_mismatch | 1 |
| oracle_target_removal_mismatch | 3 |
| temporary_effect_not_explicit | 5 |
| trigger_not_explicit | 12 |

## Deck Coverage

| Deck | Cards | Battle Rule Curated | Type Land | Known Cards Canonical Snapshot | Flagged |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lorehold target deck | 100 | 65 | 34 | 1 | 31 |

## Highest Risk Cards

| Card | Effect | Source | Flags | Decks |
| --- | --- | --- | --- | --- |
| Apex of Power | passive | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Flashback | recursion | battle_rule_curated | cast_permission_not_explicit, temporary_effect_not_explicit | Lorehold target deck |
| Goliath Daydreamer | free_cast | battle_rule_curated | cast_permission_not_explicit, trigger_not_explicit | Lorehold target deck |
| Mizzix's Mastery | overload_recursion | battle_rule_curated | cast_permission_not_explicit, oracle_target_removal_mismatch | Lorehold target deck |
| Velomachus Lorehold | creature | battle_rule_curated | cast_permission_not_explicit, trigger_not_explicit | Lorehold target deck |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | ramp_engine | known_cards_canonical_snapshot | temporary_effect_not_explicit, trigger_not_explicit | Lorehold target deck |
| Boros Charm | modal_boros_charm | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Call Forth the Tempest | damage_wipe | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Deflecting Swat | redirect_removal | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Double Vision | copy_spell | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Esper Sentinel | draw_engine | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Faithless Looting | loot | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Galvanoth | creature | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Goldspan Dragon | creature | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Guttersnipe | creature | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Heroes Remembered | life_total_change | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Insurrection | steal_all_creatures | battle_rule_curated | temporary_effect_not_explicit | Lorehold target deck |
| Invoke Calamity | free_cast | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Longshot, Rebel Bowman | creature | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Lorehold, the Historian | passive | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Monument to Endurance | discard_trigger_modal_draw_treasure_opponent_life_loss | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Primal Amulet // Primal Wellspring | static_cost_reduction | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Red Elemental Blast | counter | battle_rule_curated | oracle_target_removal_mismatch | Lorehold target deck |
| Reforge the Soul | draw_cards | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Rise of the Eldrazi | composite_resolution | battle_rule_curated | oracle_target_removal_mismatch | Lorehold target deck |
| Rite of the Dragoncaller | token_maker | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Silence | silence_spell | battle_rule_curated | oracle_silence_mismatch | Lorehold target deck |
| Smothering Tithe | ramp_engine | battle_rule_curated | trigger_not_explicit | Lorehold target deck |
| Underworld Breach | passive | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Vandalblast | remove_permanent | battle_rule_curated | cast_permission_not_explicit | Lorehold target deck |
| Urza's Saga | land | type_land | land_utility_ability_not_modeled | Lorehold target deck |
