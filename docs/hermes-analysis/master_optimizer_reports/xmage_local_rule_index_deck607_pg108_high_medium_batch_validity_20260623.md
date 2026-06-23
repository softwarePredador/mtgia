# XMage Local Rule Index

Generated at: `2026-06-23T17:52:46+00:00`

Read-only artifact. `mutations_performed=[]`.

- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Summary: `{"not_found_count": 2, "requested_card_count": 13, "resolved_count": 11, "xmage_class_index_size": 31706}`

| Card | Status | XMage class | Superclass | Signals | Primary hint |
| --- | --- | --- | --- | --- | --- |
| `Promise of Loyalty` | `found` | `PromiseOfLoyalty` | `CardImpl` | `targeting, counter` | `vow_counter_each_player_sacrifice_rest` |
| `Starfall Invocation` | `found` | `StarfallInvocation` | `CardImpl` | `targeting, condition, gift` | `gift_destroy_all_creatures_return_own_destroyed_creature` |
| `Pearl Medallion` | `found` | `PearlMedallion` | `CardImpl` | `cost_reduction, static_ability` | `static_cost_reduction` |
| `Emeria's Call // Emeria, Shattered Skyclave` | `found` | `EmeriasCall` | `ModalDoubleFacedCard` | `token, mana` | `token_maker` |
| `Molecule Man` | `not_found` | `None` | `None` | `` | `None` |
| `The Mind Stone` | `found` | `TheMindStone` | `CardImpl` | `targeting, mana, static_ability, triggered_ability, activated_ability` | `mana_rock_with_harnessed_blink` |
| `The Scarlet Witch` | `found` | `TheScarletWitch` | `CardImpl` | `static_ability` | `static_cost_reduction` |
| `Thor, God of Thunder` | `not_found` | `None` | `None` | `` | `None` |
| `Tragic Arrogance` | `found` | `TragicArrogance` | `CardImpl` | `targeting` | `selective_nonland_sacrifice` |
| `Bender's Waterskin` | `found` | `BendersWaterskin` | `CardImpl` | `mana, static_ability` | `other_turn_untapping_any_color_mana_rock` |
| `Victory Chimes` | `found` | `VictoryChimes` | `CardImpl` | `targeting, mana, static_ability` | `other_turn_untapping_target_player_colorless_mana_rock` |
| `Monument to Endurance` | `found` | `MonumentToEndurance` | `CardImpl` | `token, draw, triggered_ability` | `discard_trigger_modal_draw_treasure_opponent_life_loss` |
| `Surge to Victory` | `found` | `SurgeToVictory` | `CardImpl` | `targeting, triggered_ability` | `exile_instant_sorcery_boost_combat_damage_copy_cast` |

## Card Evidence

### Promise of Loyalty

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/p/PromiseOfLoyalty.java`
- Class: `PromiseOfLoyalty` extends `CardImpl`
- Ability classes: `[]`
- Effect classes: `["OneShotEffect", "PromiseOfLoyaltyAttackEffect", "PromiseOfLoyaltyEffect", "RestrictionEffect"]`
- Target classes: `["TargetControlledCreaturePermanent", "TargetPermanent"]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "one_shot", "battle_model_scope": "each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1", "effect": "vow_counter_each_player_sacrifice_rest"}`
- Confidence reason: XMage structure/oracle text indicates vow counters plus sacrifice-rest and attack restriction.

Suggested focused tests:

- `promise_of_loyalty_1`: each player chooses exactly one controlled creature
- `promise_of_loyalty_2`: chosen creatures receive vow counters and other creatures are sacrificed
- `promise_of_loyalty_3`: vow-counter creatures cannot attack the protected player

### Starfall Invocation

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/StarfallInvocation.java`
- Class: `StarfallInvocation` extends `CardImpl`
- Ability classes: `["GiftAbility"]`
- Effect classes: `["OneShotEffect", "StarfallInvocationEffect"]`
- Target classes: `["TargetCard", "TargetCardInYourGraveyard"]`
- Filter classes: `[]`
- Condition classes: `["GiftWasPromisedCondition"]`
- Primary candidate: `{"ability_kind": "one_shot", "battle_model_scope": "gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1", "effect": "gift_destroy_all_creatures_return_own_destroyed_creature"}`
- Confidence reason: XMage/oracle text indicates gift condition, destroy-all, and return destroyed-this-way creature.

Suggested focused tests:

- `starfall_invocation_1`: destroy all creatures without gift and return none
- `starfall_invocation_2`: gift promised returns one own creature put into graveyard this way

### Pearl Medallion

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/p/PearlMedallion.java`
- Class: `PearlMedallion` extends `CardImpl`
- Ability classes: `["SimpleStaticAbility"]`
- Effect classes: `["SpellsCostReductionControllerEffect"]`
- Target classes: `[]`
- Filter classes: `["FilterCard"]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "static", "applies_to_controller": "source_controller", "battle_model_scope": "static_cost_reduction_for_matching_spells_v1", "cost_reduction_applies_to": "spells_you_cast", "cost_reduction_generic": 1, "effect": "static_cost_reduction"}`
- Confidence reason: XMage uses a spell-cost-reduction effect; this is support/cost shaping, not mana production.

Suggested focused tests:

- `pearl_medallion_1`: cast matching spell with one less generic cost
- `pearl_medallion_2`: cast non-matching spell without reduction

### Emeria's Call // Emeria, Shattered Skyclave

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/e/EmeriasCall.java`
- Class: `EmeriasCall` extends `ModalDoubleFacedCard`
- Ability classes: `["AsEntersBattlefieldAbility", "IndestructibleAbility", "WhiteManaAbility"]`
- Effect classes: `["CreateTokenEffect", "GainAbilityAllEffect", "TapSourceUnlessPaysEffect"]`
- Target classes: `[]`
- Filter classes: `["FilterControlledCreaturePermanent", "FilterPermanent"]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "one_shot", "battle_model_scope": "xmage_create_token_variant_emeriascall_v1", "effect": "token_maker"}`
- Confidence reason: XMage uses token creation classes.

Suggested focused tests:

- `emeria_s_call_emeria_shattered_skyclave_1`: create expected token count and stats
- `emeria_s_call_emeria_shattered_skyclave_2`: apply duration-limited protection or indestructible effect

### Molecule Man

- Status: `not_found`
- Candidate class names: `["MoleculeMan"]`

### The Mind Stone

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheMindStone.java`
- Class: `TheMindStone` extends `CardImpl`
- Ability classes: `["BeginningOfEndStepTriggeredAbility", "IndestructibleAbility", "SimpleActivatedAbility", "SimpleStaticAbility", "WhiteManaAbility"]`
- Effect classes: `["ExileThenReturnTargetEffect", "GainHarnessedAbilitySourceEffect", "HarnessSourceEffect"]`
- Target classes: `["TargetControlledPermanent"]`
- Filter classes: `["FilterControlledPermanent"]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "activated", "battle_model_scope": "legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1", "effect": "mana_rock_with_harnessed_blink", "target_constraints": {"card_types": ["permanent"], "controller_scope": "source_controller"}}`
- Confidence reason: XMage structure indicates mana ability plus harnessed delayed blink support.

Suggested focused tests:

- `the_mind_stone_1`: focused behavior scenario for mana_rock_with_harnessed_blink

### The Scarlet Witch

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheScarletWitch.java`
- Class: `TheScarletWitch` extends `CardImpl`
- Ability classes: `["SimpleStaticAbility", "SpellAbility"]`
- Effect classes: `["TheScarletWitchEffect"]`
- Target classes: `[]`
- Filter classes: `["FilterInstantOrSorceryCard"]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "static", "battle_model_scope": "static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1", "effect": "static_cost_reduction"}`
- Confidence reason: XMage custom inner effect extends CostModificationEffectImpl and reduces spell costs.

Suggested focused tests:

- `the_scarlet_witch_1`: cast matching spell with one less generic cost
- `the_scarlet_witch_2`: cast non-matching spell without reduction

### Thor, God of Thunder

- Status: `not_found`
- Candidate class names: `["ThorGodOfThunder"]`

### Tragic Arrogance

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TragicArrogance.java`
- Class: `TragicArrogance` extends `CardImpl`
- Ability classes: `[]`
- Effect classes: `["OneShotEffect", "TragicArroganceEffect"]`
- Target classes: `["TargetPermanent"]`
- Filter classes: `["FilterArtifactPermanent", "FilterCreaturePermanent", "FilterEnchantmentPermanent", "FilterPlaneswalkerPermanent"]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "one_shot", "battle_model_scope": "controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1", "effect": "selective_nonland_sacrifice"}`
- Confidence reason: Oracle text indicates Tragic Arrogance-style per-type/per-player selection and sacrifice.

Suggested focused tests:

- `tragic_arrogance_1`: controller chooses one permanent per requested type and player
- `tragic_arrogance_2`: all other nonland permanents are sacrificed

### Bender's Waterskin

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/BendersWaterskin.java`
- Class: `BendersWaterskin` extends `CardImpl`
- Ability classes: `["AnyColorManaAbility", "SimpleStaticAbility"]`
- Effect classes: `["UntapSourceDuringEachOtherPlayersUntapStepEffect"]`
- Target classes: `[]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "activated", "battle_model_scope": "artifact_untaps_each_other_player_untap_step_tap_any_color_v1", "effect": "other_turn_untapping_any_color_mana_rock"}`
- Confidence reason: XMage uses the shared other-player untap static effect plus AnyColorManaAbility.

Suggested focused tests:

- `bender_s_waterskin_1`: focused behavior scenario for other_turn_untapping_any_color_mana_rock

### Victory Chimes

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/v/VictoryChimes.java`
- Class: `VictoryChimes` extends `CardImpl`
- Ability classes: `["SimpleManaAbility", "SimpleStaticAbility"]`
- Effect classes: `["ManaEffect", "UntapSourceDuringEachOtherPlayersUntapStepEffect", "VictoryChimesManaEffect"]`
- Target classes: `["TargetPlayer"]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "activated", "battle_model_scope": "artifact_untaps_each_other_player_untap_step_tap_target_player_add_colorless_v1", "effect": "other_turn_untapping_target_player_colorless_mana_rock", "target_constraints": {"mana_pool_owner": "chosen_player", "target": "player"}}`
- Confidence reason: XMage uses the shared other-player untap static effect and a custom ManaEffect that chooses a player for {C}.

Suggested focused tests:

- `victory_chimes_1`: focused behavior scenario for other_turn_untapping_target_player_colorless_mana_rock

### Monument to Endurance

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/m/MonumentToEndurance.java`
- Class: `MonumentToEndurance` extends `CardImpl`
- Ability classes: `["DiscardCardControllerTriggeredAbility"]`
- Effect classes: `["CreateTokenEffect", "DrawCardSourceControllerEffect", "LoseLifeOpponentsEffect"]`
- Target classes: `[]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "triggered", "battle_model_scope": "discard_trigger_choose_unchosen_mode_draw_or_treasure_or_each_opponent_loses_3_v1", "effect": "discard_trigger_modal_draw_treasure_opponent_life_loss"}`
- Confidence reason: XMage models the discard trigger with once-per-turn mode limiting, draw, Treasure creation, and opponent life loss modes.

Suggested focused tests:

- `monument_to_endurance_1`: focused behavior scenario for discard_trigger_modal_draw_treasure_opponent_life_loss

### Surge to Victory

- XMage path: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SurgeToVictory.java`
- Class: `SurgeToVictory` extends `CardImpl`
- Ability classes: `["DelayedTriggeredAbility", "SurgeToVictoryTriggeredAbility"]`
- Effect classes: `["BoostControlledEffect", "OneShotEffect", "SurgeToVictoryCastEffect", "SurgeToVictoryExileEffect"]`
- Target classes: `["TargetCardInYourGraveyard"]`
- Filter classes: `[]`
- Condition classes: `[]`
- Primary candidate: `{"ability_kind": "triggered", "battle_model_scope": "exile_target_instant_sorcery_boost_team_and_combat_damage_copy_cast_free_v1", "effect": "exile_instant_sorcery_boost_combat_damage_copy_cast", "target_constraints": {"card_types": ["instant", "sorcery"], "zone": "graveyard"}}`
- Confidence reason: XMage custom effects exile a targeted instant/sorcery, boost controlled creatures by mana value, and add delayed combat-damage copy/cast behavior.

Suggested focused tests:

- `surge_to_victory_1`: focused behavior scenario for exile_instant_sorcery_boost_combat_damage_copy_cast
