# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-01T08:20:51+00:00`
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
| `target_identity_count` | 31333 |
| `xmage_authoritative_source_count` | 28397 |
| `xmage_missing_source_exception_count` | 2936 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 28397 |
| `manual_semantic_decision_units_remaining` | 2936 |
| `authoritative_source_coverage_ratio` | 0.9063 |
| `adapter_work_unit_count` | 12093 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 28397 |
| `xmage_missing_source_exception` | 2936 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `parser_gap::unknown_superclass::no_signal` | 2936 |
| `recursion::xmage_graveyard_return_variant_review_v1` | 2062 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1739 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1249 |
| `direct_damage::targeted_damage_variant_v1` | 986 |
| `life_gain::xmage_life_gain_variant_review_v1` | 818 |
| `add_counters::source_add_counters_variant_v1` | 803 |
| `removal_destroy::targeted_destroy_variant_v1` | 692 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 682 |
| `tutor::xmage_library_search_variant_review_v1` | 638 |
| `add_counters::targeted_add_counters_variant_v1` | 476 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 452 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 374 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 323 |
| `bounce::targeted_return_to_hand_variant_v1` | 266 |
| `untap_target::xmage_targeted_untap_variant_review_v1` | 260 |
| `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 248 |
| `counter_spell::counter_target_stack_object_variant_v1` | 159 |
| `removal_exile::targeted_exile_variant_v1` | 157 |
| `xmage_signature::no_effect_class::FlyingAbility::no_target_class::no_condition_class::no_signal` | 98 |
| `xmage_signature::BoostSourceEffect::SimpleActivatedAbility::no_target_class::no_condition_class::activated_ability` | 86 |
| `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` | 82 |
| `passive::xmage_static_rule_restriction_or_tax_variant_review_v1` | 68 |
| `multi_target_damage::xmage_multi_target_damage_variant_review_v1` | 61 |
| `static_cost_reduction::static_cost_reduction_for_matching_spells_v1` | 61 |
| `static_cost_reduction::static_self_spell_cost_reduction_variant_v1` | 53 |
| `xmage_signature::BoostTargetEffect::SimpleActivatedAbility::TargetCreaturePermanent::no_condition_class::targeting,activated_ability` | 47 |
| `xmage_signature::BoostControlledEffect::SimpleStaticAbility::no_target_class::no_condition_class::static_ability` | 45 |
| `blink::xmage_exile_then_return_target_variant_review_v1` | 44 |
| `ramp_permanent::xmage_land_mana_source_variant_review_v1` | 44 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 12694 |
| `unparsed` | 2936 |
| `token_maker` | 2525 |
| `recursion` | 2062 |
| `draw_engine` | 1739 |
| `add_counters` | 1279 |
| `grant_protection_from_chosen_color` | 1255 |
| `direct_damage` | 991 |
| `life_gain` | 818 |
| `ramp_permanent` | 766 |
| `removal_destroy` | 692 |
| `draw_cards` | 682 |
| `tutor` | 663 |
| `board_wipe` | 454 |
| `bounce` | 266 |
| `untap_target` | 260 |
| `free_cast` | 248 |
| `counter_spell` | 170 |
| `removal_exile` | 157 |
| `static_cost_reduction` | 116 |
| `passive` | 114 |
| `copy_spell` | 76 |
| `creature` | 64 |
| `multi_target_damage` | 61 |
| `blink` | 44 |
| `treasure_maker` | 36 |
| `topdeck_play` | 31 |
| `ramp_ritual` | 29 |
| `mill_cards` | 28 |
| `remove_permanent` | 17 |

## Top XMage Signals

| Signal | Cards |
| --- | ---: |
| `targeting` | 14727 |
| `triggered_ability` | 12258 |
| `activated_ability` | 5975 |
| `static_ability` | 5653 |
| `counter` | 3923 |
| `condition` | 3326 |
| `token` | 2577 |
| `draw` | 2375 |
| `mana` | 802 |
| `destroy_all` | 440 |
| `cost_reduction` | 289 |
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
- `Aardvark Sloth`
- `Aatchik, Emerald Radian`
- `Abaddon the Despoiler`

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
