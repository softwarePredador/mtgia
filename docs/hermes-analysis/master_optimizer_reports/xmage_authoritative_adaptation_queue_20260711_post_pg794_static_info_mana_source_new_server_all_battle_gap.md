# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-12T00:06:17+00:00`
- Status: `action_required`
- Contract: `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- Scope: `all_battle_gap`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Decision

For every target card with a resolvable local XMage class, XMage is the authoritative behavior source.
ManaLoom work is now adapter/runtime translation by family or effect signature, not card-by-card semantic approval.

## Summary

| Metric | Value |
| --- | ---: |
| `target_identity_count` | 27221 |
| `xmage_authoritative_source_count` | 24286 |
| `xmage_missing_source_exception_count` | 2935 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 24286 |
| `manual_semantic_decision_units_remaining` | 2935 |
| `authoritative_source_coverage_ratio` | 0.8922 |
| `adapter_work_unit_count` | 11404 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 24286 |
| `xmage_missing_source_exception` | 2935 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `parser_gap::unknown_superclass::no_signal` | 2935 |
| `recursion::xmage_graveyard_return_variant_review_v1` | 1803 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1566 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1070 |
| `add_counters::source_add_counters_variant_v1` | 776 |
| `direct_damage::targeted_damage_variant_v1` | 740 |
| `life_gain::xmage_life_gain_variant_review_v1` | 633 |
| `tutor::xmage_library_search_variant_review_v1` | 579 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 536 |
| `removal_destroy::targeted_destroy_variant_v1` | 476 |
| `add_counters::targeted_add_counters_variant_v1` | 424 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 363 |
| `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 246 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 234 |
| `bounce::targeted_return_to_hand_variant_v1` | 207 |
| `untap_target::xmage_targeted_untap_variant_review_v1` | 202 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 121 |
| `removal_exile::targeted_exile_variant_v1` | 118 |
| `counter_spell::counter_target_stack_object_variant_v1` | 116 |
| `static_cost_reduction::static_cost_reduction_for_matching_spells_v1` | 61 |
| `static_cost_reduction::static_self_spell_cost_reduction_variant_v1` | 53 |
| `passive::xmage_static_rule_restriction_or_tax_variant_review_v1` | 52 |
| `multi_target_damage::xmage_multi_target_damage_variant_review_v1` | 46 |
| `blink::xmage_exile_then_return_target_variant_review_v1` | 44 |
| `ramp_permanent::xmage_land_mana_source_variant_review_v1` | 44 |
| `copy_spell::xmage_copy_stack_object_variant_review_v1` | 42 |
| `copy_spell::copy_target_instant_or_sorcery_stack_spell_choose_new_targets_runtime_v1` | 34 |
| `topdeck_play::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 31 |
| `treasure_maker::single_treasure_creation_v1` | 30 |
| `passive::static_cast_as_flash_permission_variant_review_v1` | 28 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 11089 |
| `unparsed` | 2935 |
| `token_maker` | 2294 |
| `recursion` | 1803 |
| `draw_engine` | 1566 |
| `add_counters` | 1200 |
| `grant_protection_from_chosen_color` | 1076 |
| `direct_damage` | 745 |
| `life_gain` | 633 |
| `tutor` | 590 |
| `draw_cards` | 536 |
| `removal_destroy` | 476 |
| `ramp_permanent` | 415 |
| `board_wipe` | 365 |
| `free_cast` | 246 |
| `bounce` | 207 |
| `untap_target` | 202 |
| `counter_spell` | 127 |
| `removal_exile` | 118 |
| `static_cost_reduction` | 116 |
| `passive` | 91 |
| `copy_spell` | 76 |
| `multi_target_damage` | 46 |
| `creature` | 45 |
| `blink` | 44 |
| `treasure_maker` | 31 |
| `topdeck_play` | 31 |
| `mill_cards` | 28 |
| `ramp_ritual` | 25 |
| `copy_permanent_etb` | 15 |

## Top XMage Signals

| Signal | Cards |
| --- | ---: |
| `targeting` | 13020 |
| `triggered_ability` | 11479 |
| `static_ability` | 5354 |
| `activated_ability` | 5054 |
| `counter` | 3723 |
| `condition` | 3249 |
| `token` | 2341 |
| `draw` | 2022 |
| `mana` | 460 |
| `destroy_all` | 348 |
| `cost_reduction` | 258 |
| `gift` | 18 |

## Samples

### adapter_required

- `"Ach! Hans, Run!"`
- `A Killer Among Us`
- `A Little Chat`
- `A Realm Reborn`
- `A Tale for the Ages`
- `A.I.M. Scientists`
- `Aang and Katara`
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

- `"Brims" Barone, Midway Mobster`
- `"Lifetime" Pass Holder`
- `"Rumors of My Death . . ."`
- `+2 Mace`
- `17-Year Cicadas`
- `1996 World Champion`
- `_____`
- `_____ _____ _____ Trespasser`
- `_____ _____ Rocketship`
- `_____ Balls of Fire`
- `_____ Bird Gets the Worm`
- `_____-o-saurus`
- `________ Goblin`
- `A Chaotic Night in Vegas`
- `A Container of Booster Packs`
- `A Display of My Dark Power`
- `A Girl and Her Dogs`
- `A Golden Opportunity`
- `A Good Day to Pie`
- `A Good Thing`

## Operational Meaning

- `xmage_authoritative_adapter_required`: source truth exists; build/route a ManaLoom adapter for the work unit.
- `xmage_authoritative_parser_gap`: source truth exists; improve XMage parser/hints before adapter generation.
- `xmage_missing_source_exception`: local XMage does not resolve the card; this is the residual manual/external-source queue.
- This report is read-only and does not mutate PostgreSQL or Hermes.
