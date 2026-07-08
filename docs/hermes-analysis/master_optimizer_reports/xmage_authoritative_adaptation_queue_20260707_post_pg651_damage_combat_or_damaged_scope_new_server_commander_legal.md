# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-07T23:47:56+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- Scope: `commander_legal_battle_gap`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Decision

For every target card with a resolvable local XMage class, XMage is the authoritative behavior source.
ManaLoom work is now adapter/runtime translation by family or effect signature, not card-by-card semantic approval.

## Summary

| Metric | Value |
| --- | ---: |
| `target_identity_count` | 24974 |
| `xmage_authoritative_source_count` | 24661 |
| `xmage_missing_source_exception_count` | 313 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 24661 |
| `manual_semantic_decision_units_remaining` | 313 |
| `authoritative_source_coverage_ratio` | 0.9875 |
| `adapter_work_unit_count` | 11328 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 24661 |
| `xmage_missing_source_exception` | 313 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `recursion::xmage_graveyard_return_variant_review_v1` | 1793 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1575 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1080 |
| `add_counters::source_add_counters_variant_v1` | 771 |
| `direct_damage::targeted_damage_variant_v1` | 770 |
| `life_gain::xmage_life_gain_variant_review_v1` | 663 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 579 |
| `tutor::xmage_library_search_variant_review_v1` | 567 |
| `removal_destroy::targeted_destroy_variant_v1` | 495 |
| `add_counters::targeted_add_counters_variant_v1` | 437 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 394 |
| `parser_gap::unknown_superclass::no_signal` | 313 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 270 |
| `untap_target::xmage_targeted_untap_variant_review_v1` | 260 |
| `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 246 |
| `bounce::targeted_return_to_hand_variant_v1` | 222 |
| `counter_spell::counter_target_stack_object_variant_v1` | 133 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 127 |
| `removal_exile::targeted_exile_variant_v1` | 126 |
| `static_cost_reduction::static_cost_reduction_for_matching_spells_v1` | 61 |
| `static_cost_reduction::static_self_spell_cost_reduction_variant_v1` | 53 |
| `passive::xmage_static_rule_restriction_or_tax_variant_review_v1` | 51 |
| `multi_target_damage::xmage_multi_target_damage_variant_review_v1` | 46 |
| `blink::xmage_exile_then_return_target_variant_review_v1` | 44 |
| `ramp_permanent::xmage_land_mana_source_variant_review_v1` | 44 |
| `copy_spell::xmage_copy_stack_object_variant_review_v1` | 40 |
| `copy_spell::copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1` | 34 |
| `treasure_maker::single_treasure_creation_v1` | 31 |
| `topdeck_play::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 30 |
| `ramp_ritual::xmage_spell_mana_ritual_variant_review_v1` | 28 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 11155 |
| `token_maker` | 2306 |
| `recursion` | 1793 |
| `draw_engine` | 1575 |
| `add_counters` | 1208 |
| `grant_protection_from_chosen_color` | 1086 |
| `direct_damage` | 775 |
| `life_gain` | 663 |
| `draw_cards` | 579 |
| `tutor` | 578 |
| `removal_destroy` | 495 |
| `ramp_permanent` | 458 |
| `board_wipe` | 396 |
| `unparsed` | 313 |
| `untap_target` | 260 |
| `free_cast` | 246 |
| `bounce` | 222 |
| `counter_spell` | 144 |
| `removal_exile` | 126 |
| `static_cost_reduction` | 116 |
| `passive` | 88 |
| `copy_spell` | 74 |
| `multi_target_damage` | 46 |
| `creature` | 45 |
| `blink` | 44 |
| `treasure_maker` | 32 |
| `topdeck_play` | 30 |
| `ramp_ritual` | 28 |
| `mill_cards` | 27 |
| `copy_permanent_etb` | 15 |

## Top XMage Signals

| Signal | Cards |
| --- | ---: |
| `targeting` | 13248 |
| `triggered_ability` | 11464 |
| `static_ability` | 5319 |
| `activated_ability` | 5126 |
| `counter` | 3754 |
| `condition` | 3257 |
| `token` | 2354 |
| `draw` | 2080 |
| `mana` | 500 |
| `destroy_all` | 381 |
| `cost_reduction` | 257 |
| `gift` | 18 |

## Samples

### adapter_required

- `A Killer Among Us`
- `A Little Chat`
- `A Realm Reborn`
- `A Tale for the Ages`
- `A.I.M. Scientists`
- `Aang and Katara`
- `Aang's Defense`
- `Aang's Iceberg`
- `Aang's Journey`
- `Aang, A Lot to Learn`
- `Aang, Air Nomad`
- `Aang, Airbending Master`
- `Aang, at the Crossroads // Aang, Destined Savior`
- `Aang, Swift Savior // Aang and La, Ocean's Fury`
- `Aang, the Last Airbender`
- `Aarakocra Sneak`
- `Aatchik, Emerald Radian`
- `Abaddon the Despoiler`
- `Abandon Hope`
- `Abandon Reason`

### parser_gap


### missing_source

- `"Lifetime" Pass Holder`
- `+2 Mace`
- `_____ _____ _____ Trespasser`
- `_____ _____ Rocketship`
- `_____ Balls of Fire`
- `_____ Bird Gets the Worm`
- `_____-o-saurus`
- `________ Goblin`
- `A Good Day to Pie`
- `Absorbing Man`
- `Aerialephant`
- `Aether Searcher`
- `Alaundo the Seer`
- `Alicia Masters, Skilled Sculptor`
- `Alter Reality`
- `Ambassador Blorpityblorpboop`
- `Aminatou, Veil Piercer`
- `Amzu, Swarm's Hunger`
- `Ancestral Hot Dog Minotaur`
- `Anchovy & Banana Pizza`

## Operational Meaning

- `xmage_authoritative_adapter_required`: source truth exists; build/route a ManaLoom adapter for the work unit.
- `xmage_authoritative_parser_gap`: source truth exists; improve XMage parser/hints before adapter generation.
- `xmage_missing_source_exception`: local XMage does not resolve the card; this is the residual manual/external-source queue.
- This report is read-only and does not mutate PostgreSQL or Hermes.
