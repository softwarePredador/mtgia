# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-04T20:14:50+00:00`
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
| `target_identity_count` | 26350 |
| `xmage_authoritative_source_count` | 26036 |
| `xmage_missing_source_exception_count` | 314 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 26036 |
| `manual_semantic_decision_units_remaining` | 314 |
| `authoritative_source_coverage_ratio` | 0.9881 |
| `adapter_work_unit_count` | 11393 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 26036 |
| `xmage_missing_source_exception` | 314 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `recursion::xmage_graveyard_return_variant_review_v1` | 1799 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1610 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1103 |
| `direct_damage::targeted_damage_variant_v1` | 811 |
| `add_counters::source_add_counters_variant_v1` | 795 |
| `life_gain::xmage_life_gain_variant_review_v1` | 728 |
| `removal_destroy::targeted_destroy_variant_v1` | 612 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 597 |
| `tutor::xmage_library_search_variant_review_v1` | 584 |
| `add_counters::targeted_add_counters_variant_v1` | 459 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 433 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 337 |
| `parser_gap::unknown_superclass::no_signal` | 314 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 267 |
| `bounce::targeted_return_to_hand_variant_v1` | 262 |
| `untap_target::xmage_targeted_untap_variant_review_v1` | 260 |
| `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 247 |
| `counter_spell::counter_target_stack_object_variant_v1` | 157 |
| `removal_exile::targeted_exile_variant_v1` | 149 |
| `passive::xmage_static_rule_restriction_or_tax_variant_review_v1` | 67 |
| `multi_target_damage::xmage_multi_target_damage_variant_review_v1` | 61 |
| `static_cost_reduction::static_cost_reduction_for_matching_spells_v1` | 61 |
| `static_cost_reduction::static_self_spell_cost_reduction_variant_v1` | 53 |
| `blink::xmage_exile_then_return_target_variant_review_v1` | 44 |
| `ramp_permanent::xmage_land_mana_source_variant_review_v1` | 44 |
| `copy_spell::xmage_copy_stack_object_variant_review_v1` | 40 |
| `token_maker::xmage_signature::CreateTokenEffect::no_ability_class::no_target_class::no_condition_class::token` | 36 |
| `xmage_signature::AttachEffect,BoostEnchantedEffect::EnchantAbility,SimpleStaticAbility::TargetCreaturePermanent,TargetPermanent::no_condition_class::targeting,static_ability` | 35 |
| `treasure_maker::single_treasure_creation_v1` | 35 |
| `token_maker::xmage_signature::CreateTokenEffect::SimpleActivatedAbility::no_target_class::no_condition_class::token,activated_ability` | 34 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 11673 |
| `token_maker` | 2411 |
| `recursion` | 1799 |
| `draw_engine` | 1610 |
| `add_counters` | 1254 |
| `grant_protection_from_chosen_color` | 1109 |
| `direct_damage` | 816 |
| `life_gain` | 728 |
| `ramp_permanent` | 672 |
| `removal_destroy` | 612 |
| `draw_cards` | 597 |
| `tutor` | 595 |
| `board_wipe` | 435 |
| `unparsed` | 314 |
| `bounce` | 262 |
| `untap_target` | 260 |
| `free_cast` | 247 |
| `counter_spell` | 168 |
| `removal_exile` | 149 |
| `static_cost_reduction` | 116 |
| `passive` | 104 |
| `copy_spell` | 74 |
| `multi_target_damage` | 61 |
| `blink` | 44 |
| `creature` | 43 |
| `treasure_maker` | 36 |
| `topdeck_play` | 30 |
| `ramp_ritual` | 28 |
| `mill_cards` | 27 |
| `remove_permanent` | 17 |

## Top XMage Signals

| Signal | Cards |
| --- | ---: |
| `targeting` | 13805 |
| `triggered_ability` | 11824 |
| `activated_ability` | 5537 |
| `static_ability` | 5529 |
| `counter` | 3865 |
| `condition` | 3288 |
| `token` | 2463 |
| `draw` | 2155 |
| `mana` | 707 |
| `destroy_all` | 421 |
| `cost_reduction` | 280 |
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
