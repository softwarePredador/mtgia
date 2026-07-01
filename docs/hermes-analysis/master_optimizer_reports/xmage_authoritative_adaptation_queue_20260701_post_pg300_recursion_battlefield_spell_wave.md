# XMage Authoritative Adaptation Queue

- Generated at: `2026-07-01T11:22:51+00:00`
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
| `target_identity_count` | 27759 |
| `xmage_authoritative_source_count` | 27445 |
| `xmage_missing_source_exception_count` | 314 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 27445 |
| `manual_semantic_decision_units_remaining` | 314 |
| `authoritative_source_coverage_ratio` | 0.9887 |
| `adapter_work_unit_count` | 11905 |

## Translation Lanes

| Lane | Count |
| --- | ---: |
| `xmage_authoritative_adapter_required` | 27445 |
| `xmage_missing_source_exception` | 314 |

## Top Adapter Work Units

| Work Unit | Cards |
| --- | ---: |
| `recursion::xmage_graveyard_return_variant_review_v1` | 1995 |
| `draw_engine::xmage_draw_card_variant_review_v1` | 1698 |
| `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` | 1206 |
| `direct_damage::targeted_damage_variant_v1` | 973 |
| `add_counters::source_add_counters_variant_v1` | 795 |
| `life_gain::xmage_life_gain_variant_review_v1` | 780 |
| `draw_cards::xmage_draw_card_variant_review_v1` | 676 |
| `removal_destroy::targeted_destroy_variant_v1` | 672 |
| `tutor::xmage_library_search_variant_review_v1` | 626 |
| `add_counters::targeted_add_counters_variant_v1` | 470 |
| `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` | 433 |
| `ramp_permanent::xmage_creature_mana_source_variant_review_v1` | 373 |
| `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` | 315 |
| `parser_gap::unknown_superclass::no_signal` | 314 |
| `bounce::targeted_return_to_hand_variant_v1` | 264 |
| `untap_target::xmage_targeted_untap_variant_review_v1` | 260 |
| `free_cast::xmage_cast_or_play_from_alternate_zone_variant_review_v1` | 247 |
| `counter_spell::counter_target_stack_object_variant_v1` | 157 |
| `removal_exile::targeted_exile_variant_v1` | 156 |
| `xmage_signature::BoostSourceEffect::SimpleActivatedAbility::no_target_class::no_condition_class::activated_ability` | 86 |
| `passive::xmage_static_rule_restriction_or_tax_variant_review_v1` | 67 |
| `multi_target_damage::xmage_multi_target_damage_variant_review_v1` | 61 |
| `static_cost_reduction::static_cost_reduction_for_matching_spells_v1` | 61 |
| `static_cost_reduction::static_self_spell_cost_reduction_variant_v1` | 53 |
| `xmage_signature::BoostTargetEffect::SimpleActivatedAbility::TargetCreaturePermanent::no_condition_class::targeting,activated_ability` | 46 |
| `xmage_signature::BoostControlledEffect::SimpleStaticAbility::no_target_class::no_condition_class::static_ability` | 45 |
| `blink::xmage_exile_then_return_target_variant_review_v1` | 44 |
| `ramp_permanent::xmage_land_mana_source_variant_review_v1` | 44 |
| `copy_spell::xmage_copy_stack_object_variant_review_v1` | 40 |
| `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` | 39 |

## Top Effects

| Effect | Cards |
| --- | ---: |
| `external_reference_required_manual_model` | 12068 |
| `token_maker` | 2497 |
| `recursion` | 1995 |
| `draw_engine` | 1698 |
| `add_counters` | 1265 |
| `grant_protection_from_chosen_color` | 1212 |
| `direct_damage` | 978 |
| `life_gain` | 780 |
| `ramp_permanent` | 756 |
| `draw_cards` | 676 |
| `removal_destroy` | 672 |
| `tutor` | 651 |
| `board_wipe` | 435 |
| `unparsed` | 314 |
| `bounce` | 264 |
| `untap_target` | 260 |
| `free_cast` | 247 |
| `counter_spell` | 168 |
| `removal_exile` | 156 |
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
| `targeting` | 14494 |
| `triggered_ability` | 12028 |
| `activated_ability` | 5927 |
| `static_ability` | 5597 |
| `counter` | 3886 |
| `condition` | 3303 |
| `token` | 2549 |
| `draw` | 2326 |
| `mana` | 791 |
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
