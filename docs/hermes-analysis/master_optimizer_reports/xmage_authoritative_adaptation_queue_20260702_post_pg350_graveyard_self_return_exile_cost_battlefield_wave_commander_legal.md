# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-02T04:09:30+00:00`
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
| `target_identity_count` | 27172 |
| `xmage_authoritative_source_count` | 26858 |
| `xmage_missing_source_exception_count` | 314 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 26858 |
| `manual_semantic_decision_units_remaining` | 314 |
| `authoritative_source_coverage_ratio` | 0.9884 |
| `adapter_work_unit_count` | 11429 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 26858 |
| `xmage_missing_source_exception` | 314 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `recursion::xmage_graveyard_return_variant_review_v1` | 1868 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1646 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1162 |
| `direct_damage::targeted_damage_variant_v1` | 928 |
| `add_counters::source_add_counters_variant_v1` | 795 |
| `life_gain::xmage_life_gain_variant_review_v1` | 740 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 676 |
| `removal_destroy::targeted_destroy_variant_v1` | 636 |
| `tutor::xmage_library_search_variant_review_v1` | 613 |
| `add_counters::targeted_add_counters_variant_v1` | 459 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 433 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 363 |
| `parser_gap::unknown_superclass::no_signal` | 314 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 309 |
| `bounce::targeted_return_to_hand_variant_v1` | 264 |
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
| `token_maker::xmage_signature::CreateTokenEffect::no_ability_class::no_target_class::no_condition_class::token` | 42 |
| `copy_spell::xmage_copy_stack_object_variant_review_v1` | 40 |
| `token_maker::xmage_signature::CreateTokenEffect::DiesSourceTriggeredAbility::no_target_class::no_condition_class::token,triggered_ability` | 40 |
| `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` | 39 |
| `xmage_signature::AttachEffect,BoostEnchantedEffect::EnchantAbility,SimpleStaticAbility::TargetCreaturePermanent,TargetPermanent::no_condition_class::targeting,static_ability` | 35 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 11926 |
| `token_maker` | 2443 |
| `recursion` | 1868 |
| `draw_engine` | 1646 |
| `add_counters` | 1254 |
| `grant_protection_from_chosen_color` | 1168 |
| `direct_damage` | 933 |
| `life_gain` | 740 |
| `ramp_permanent` | 740 |
| `draw_cards` | 676 |
| `tutor` | 638 |
| `removal_destroy` | 636 |
| `board_wipe` | 435 |
| `unparsed` | 314 |
| `bounce` | 264 |
| `untap_target` | 260 |
| `free_cast` | 247 |
| `counter_spell` | 168 |
| `removal_exile` | 149 |
| `static_cost_reduction` | 116 |
| `passive` | 111 |
| `copy_spell` | 74 |
| `creature` | 64 |
| `multi_target_damage` | 61 |
| `blink` | 44 |
| `treasure_maker` | 36 |
| `topdeck_play` | 30 |
| `ramp_ritual` | 28 |
| `mill_cards` | 27 |
| `remove_permanent` | 17 |

## Top XMage Signals

| Signal | Cards |
| --- | ---: |
| `targeting` | 14199 |
| `triggered_ability` | 11927 |
| `activated_ability` | 5702 |
| `static_ability` | 5547 |
| `counter` | 3871 |
| `condition` | 3296 |
| `token` | 2495 |
| `draw` | 2274 |
| `mana` | 775 |
| `destroy_all` | 421 |
| `cost_reduction` | 287 |
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
