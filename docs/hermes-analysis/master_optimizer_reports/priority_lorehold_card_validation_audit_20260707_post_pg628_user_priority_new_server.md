# Priority Lorehold Card Validation Audit

- Generated at: `2026-07-07T17:42:33.190737+00:00`
- Status: `pass`
- PostgreSQL target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- Summary: `{"battle_rule_cards_passed": 24, "checks_failed": 0, "checks_total": 81, "functional_classification_cards_passed": 24, "functional_classification_cards_required": 9, "target_card_count": 24, "xmage_source_found_count": 21, "xmage_source_missing_count": 3}`

| Card | PG rule | SQLite rule | Snapshot | Functional tags | Battle scope(s) | Missing tags | XMage source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Lorehold, the Historian` | `pass` | `pass` | `pass` | `not_required` | lorehold_opponent_upkeep_miracle_v1 | - | `missing` |
| `Farewell` | `pass` | `pass` | `pass` | `not_required` | modal_exile_wipe_creature_runtime_baseline_v1 | - | `found` |
| `Fellwar Stone` | `pass` | `pass` | `pass` | `not_required` | conditional_opponent_color_mana_rock_v1 | - | `found` |
| `Flawless Maneuver` | `pass` | `pass` | `pass` | `not_required` | flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1 | - | `found` |
| `Hit the Mother Lode` | `pass` | `pass` | `pass` | `not_required` | discover_10_as_one_card_value_component_v1, discover_10_treasure_difference_average_v1 | - | `found` |
| `Improvisation Capstone` | `pass` | `pass` | `pass` | `not_required` | exile_value_free_casts_paradigm_annotation_v1 | - | `found` |
| `Land Tax` | `pass` | `pass` | `pass` | `not_required` | land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1 | - | `found` |
| `Library of Leng` | `pass` | `pass` | `pass` | `not_required` | discard_replacement_to_top_v1 | - | `found` |
| `Scroll Rack` | `pass` | `pass` | `pass` | `not_required` | scroll_rack_upkeep_single_exchange_v1 | - | `found` |
| `Swords to Plowshares` | `pass` | `pass` | `pass` | `not_required` | swords_to_plowshares_creature_exile_life_equal_power_v1 | - | `found` |
| `Talisman of Conviction` | `pass` | `pass` | `pass` | `not_required` | pain_talisman_color_pair_partial_v1 | - | `found` |
| `Teferi's Protection` | `pass` | `pass` | `pass` | `not_required` | teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1 | - | `found` |
| `Tibalt's Trickery` | `pass` | `pass` | `pass` | `not_required` | counterspell_with_random_replacement_annotation_v1 | - | `found` |
| `Command Tower` | `pass` | `pass` | `pass` | `not_required` | commander_identity_land_mana_source_v1 | - | `found` |
| `Sol Ring` | `pass` | `pass` | `pass` | `not_required` | two_colorless_mana_rock_v1 | - | `found` |
| `Thor, God of Thunder` | `pass` | `pass` | `pass` | `pass` | etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1 | - | `missing` |
| `Furygale Flocking` | `pass` | `pass` | `pass` | `pass` | per_opponent_two_3_3_flying_hasty_elementals_graveyard_cost_reduction_runtime_attack_requirement_v1 | - | `found` |
| `Molecule Man` | `pass` | `pass` | `pass` | `pass` | nonland_hand_miracle_zero_static_v1 | - | `missing` |
| `Pearl Medallion` | `pass` | `pass` | `pass` | `pass` | static_cost_reduction_for_matching_spells_v1 | - | `found` |
| `Prismari Pianist` | `pass` | `pass` | `pass` | `pass` | instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1 | - | `found` |
| `Redirect Lightning` | `pass` | `pass` | `pass` | `pass` | single_target_spell_or_ability_redirect_additional_cost_annotation_v1 | - | `found` |
| `The Mind Stone` | `pass` | `pass` | `pass` | `pass` | legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1 | - | `found` |
| `The Scarlet Witch` | `pass` | `pass` | `pass` | `pass` | static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1 | - | `found` |
| `Turbulent Steppe` | `pass` | `pass` | `pass` | `pass` | land_enters_tapped_unless_opponents_control_lands_count_mana_source_v1 | - | `found` |
