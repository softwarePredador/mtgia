# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-30T14:01:26Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite current-rule filter: `/Users/desenvolvimentomobile/.codex/worktrees/7a8b/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Raw blocked runtime cards: `61`
- Filtered current verified/auto rules: `0`
- Blocked runtime cards: `61`
- Candidate lanes: `{"contextual": 36, "early_mana": 7, "finisher_or_big_spell": 6, "hand_filter": 9, "pressure_absorber_or_protection": 2, "protection_window": 1}`
- Promotion lanes: `{"batch_metadata_candidate_requires_pg_precheck": 23, "mapper_metadata_or_test_scenario_required": 16, "split_family_scope_review_required": 22}`
- Targeted interaction subfamilies: `{"excess_damage_redirect_to_any_target": 1, "instant_sorcery_lifelink_lifegain_damage_engine": 1, "source_damaged_reflect_to_any_target": 1, "spell_color_trigger_damage_life_engine": 1, "targeted_damage_etb_power_to_any_target": 1}`
- Targeted interaction subfamily statuses: `{"runtime_family_implementation_required": 1, "runtime_supported_family": 4}`
- Family count: `16`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `manual_model` | 16 | `manual_model_required` | `not_batch_safe` | `{"contextual": 10, "early_mana": 2, "finisher_or_big_spell": 2, "hand_filter": 2}` | `{"mapper_metadata_or_test_scenario_required": 16}` | manual Oracle/reference review |
| 2 | `targeted_interaction` | 8 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 6, "finisher_or_big_spell": 1, "pressure_absorber_or_protection": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 5, "split_family_scope_review_required": 3}` | target legality, resolution, zone transition, and event provenance |
| 3 | `free_cast` | 6 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 6}` | `{"batch_metadata_candidate_requires_pg_precheck": 4, "split_family_scope_review_required": 2}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| 4 | `recursion` | 6 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 5, "early_mana": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 5}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| 5 | `board_wipe_choice` | 4 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1, "hand_filter": 2, "pressure_absorber_or_protection": 1}` | `{"split_family_scope_review_required": 4}` | multi-player choice/wipe/sacrifice resolution |
| 6 | `topdeck_play` | 4 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"contextual": 2, "hand_filter": 2}` | `{"batch_metadata_candidate_requires_pg_precheck": 4}` | top-of-library visibility and permission to play cards from library under board-state conditions |
| 7 | `draw_engine` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "early_mana": 1, "hand_filter": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 2, "split_family_scope_review_required": 1}` | static and activated draw-engine bookkeeping with delayed card movement |
| 8 | `passive` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "early_mana": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 3}` | static battlefield annotation and passive support execution |
| 9 | `token_maker` | 2 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1, "finisher_or_big_spell": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 1}` | token creation with stats, abilities, duration, and zone cleanup |
| 10 | `static_damage_modifier` | 2 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"finisher_or_big_spell": 2}` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | continuous replacement effects that modify damage amounts by source controller and target ownership |
| 11 | `targeted_protection` | 2 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"contextual": 1, "protection_window": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 1}` | targeted own-creature protection grant and cleanup-aware target legality |
| 12 | `life_total_change` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"hand_filter": 1}` | `{"split_family_scope_review_required": 1}` | life total gain, doubling, and set-to-derived-value effects |
| 13 | `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| 14 | `ramp_engine` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"early_mana": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | triggered battlefield resource engines and resource-event bookkeeping |
| 15 | `tutor` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| 16 | `static_cost_reducer` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"early_mana": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | battle cost-locking / affordability / payment reducer |

## Cards By Family

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 4 cards; lanes `{"contextual": 4}`; samples `Rem Karolus, Stalwart Slayer, Sawhorn Nemesis, Serra Ascendant, The Walls of Ba Sing Se`
- `no_structural_signal`: 2 cards; lanes `{"finisher_or_big_spell": 1, "hand_filter": 1}`; samples `Invincible Hymn, Taunt from the Rampart`
- `triggered_ability`: 2 cards; lanes `{"contextual": 1, "early_mana": 1}`; samples `Ancient Copper Dragon, Slickshot Show-Off`
- `damage;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Stuffy Doll`
- `damage;triggered_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence`
- `targeting`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Beacon of Immortality`
- `targeting;condition;activated_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Zirda, the Dawnwaker`
- `targeting;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Radiant Performer`
- `targeting;mana_or_cost;triggered_ability;static_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Semblance Anvil`
- `targeting;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Screaming Nemesis`
- `triggered_ability;activated_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Planetarium of Wan Shi Tong`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ancient Copper Dragon` | 0 | `608, 616` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AncientCopperDragon` |
| `Beacon of Immortality` | 0 | `610, 615` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `BeaconOfImmortality` |
| `Invincible Hymn` | 0 | `610, 614` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `InvincibleHymn` |
| `Planetarium of Wan Shi Tong` | 0 | `611, 613` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PlanetariumOfWanShiTong` |
| `Semblance Anvil` | 0 | `612, 616` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SemblanceAnvil` |
| `Taunt from the Rampart` | 0 | `611, 615` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `TauntFromTheRampart` |
| `Radiant Performer` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RadiantPerformer` |
| `Rem Karolus, Stalwart Slayer` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RemKarolusStalwartSlayer` |
| `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RuneTailKitsuneAscendant` |
| `Sawhorn Nemesis` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SawhornNemesis` |
| `Screaming Nemesis` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ScreamingNemesis` |
| `Serra Ascendant` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SerraAscendant` |
| `Slickshot Show-Off` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SlickshotShowOff` |
| `Stuffy Doll` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `StuffyDoll` |
| `The Walls of Ba Sing Se` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `TheWallsOfBaSingSe` |
| `Zirda, the Dawnwaker` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ZirdaTheDawnwaker` |

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{"excess_damage_redirect_to_any_target": 1, "instant_sorcery_lifelink_lifegain_damage_engine": 1, "source_damaged_reflect_to_any_target": 1, "spell_color_trigger_damage_life_engine": 1, "targeted_damage_etb_power_to_any_target": 1}`
- Targeted interaction subfamily statuses: `{"runtime_family_implementation_required": 1, "runtime_supported_family": 4}`

Signal groups:

- `targeting;damage;triggered_ability;static_ability`: 3 cards; lanes `{"contextual": 2, "finisher_or_big_spell": 1}`; samples `Terror of the Peaks, Balefire Liege, Firesong and Sunspeaker`
- `targeting`: 2 cards; lanes `{"contextual": 1, "pressure_absorber_or_protection": 1}`; samples `Ephemerate, Wild Ricochet`
- `damage;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Repercussion`
- `targeting;damage;condition;triggered_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Toralf, God of Fury // Toralf's Hammer`
- `targeting;damage;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Boros Reckoner`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Toralf, God of Fury // Toralf's Hammer` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `excess_damage_redirect_to_any_target` | implement Toralf excess-damage batch trigger and MDFC hammer activated damage separately | `direct_damage` | `targeted_damage_variant_v1` | `ToralfGodOfFury` |
| `Boros Reckoner` | 0 | `612, 616` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `source_damaged_reflect_to_any_target` | prepare PG metadata package after PostgreSQL precheck, then gate Boros Reckoner reflection lines | `creature` | `source_dealt_damage_reflect_to_any_target_v1` | `BorosReckoner` |
| `Terror of the Peaks` | 0 | `608, 612` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `targeted_damage_etb_power_to_any_target` | prepare PG metadata package after PostgreSQL precheck, then gate Terror of the Peaks ETB damage lines | `creature` | `controlled_other_creature_enters_power_damage_any_target_v1` | `TerrorOfThePeaks` |
| `Balefire Liege` | -10 | `616` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `spell_color_trigger_damage_life_engine` | prepare PG metadata package after PostgreSQL precheck, then gate Balefire spell-color lines | `creature` | `red_spell_damage_white_spell_lifegain_static_creature_boost_v1` | `BalefireLiege` |
| `Firesong and Sunspeaker` | -10 | `616` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `instant_sorcery_lifelink_lifegain_damage_engine` | prepare PG metadata package after PostgreSQL precheck, then gate Firesong burn/lifegain lines | `creature` | `red_instant_sorcery_lifelink_white_lifegain_damage_v1` | `FiresongAndSunspeaker` |
| `Ephemerate` | -10 | `612` | `pressure_absorber_or_protection` | `split_family_scope_review_required` | `` |  | `blink` | `xmage_exile_then_return_target_variant_review_v1` | `Ephemerate` |
| `Repercussion` | -10 | `612` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `passive` | `creature_damage_controller_reflect_global_v1` | `Repercussion` |
| `Wild Ricochet` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `` |  | `redirect_target` | `xmage_choose_new_targets_variant_review_v1` | `WildRicochet` |

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `activated_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Kayla's Music Box, Pyxis of Pandemonium`
- `triggered_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Goliath Daydreamer, Possibility Storm`
- `static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Assemble the Players`
- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Chaos Wand`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Goliath Daydreamer` | 10 | `613, 614, 615` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `free_cast` | `instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1` | `GoliathDaydreamer` |
| `Assemble the Players` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `AssembleThePlayers` |
| `Chaos Wand` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `ChaosWand` |
| `Kayla's Music Box` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `free_cast` | `artifact_w_tap_exile_top_face_down_tap_play_owned_exiled_until_eot_v1` | `KaylasMusicBox` |
| `Possibility Storm` | -10 | `616` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `free_cast` | `spell_from_hand_exile_until_shared_type_free_cast_bottom_rest_random_v1` | `PossibilityStorm` |
| `Pyxis of Pandemonium` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `free_cast` | `tap_each_player_exile_top_face_down_seven_tap_sacrifice_put_exiled_permanents_onto_battlefield_v1` | `PyxisOfPandemonium` |

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mill;activated_ability`: 4 cards; lanes `{"contextual": 3, "early_mana": 1}`; samples `Codex Shredder, Leyline Dowser, Perpetual Timepiece, Wand of Vertebrae`
- `targeting;activated_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `The Warring Triad`
- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Charmbreaker Devils`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Charmbreaker Devils` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CharmbreakerDevils` |
| `Codex Shredder` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CodexShredder` |
| `Leyline Dowser` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `recursion` | `pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1` | `LeylineDowser` |
| `Perpetual Timepiece` | -10 | `610` | `early_mana` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `PerpetualTimepiece` |
| `The Warring Triad` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `TheWarringTriad` |
| `Wand of Vertebrae` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `WandOfVertebrae` |

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting`: 2 cards; lanes `{"hand_filter": 2}`; samples `Chandra's Ignition, Single Combat`
- `activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn's Sylex`
- `targeting;condition;triggered_ability;static_ability`: 1 cards; lanes `{"pressure_absorber_or_protection": 1}`; samples `Unstable Glyphbridge // Sandswirl Wanderglyph`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Chandra's Ignition` | -10 | `613` | `hand_filter` | `split_family_scope_review_required` | `` |  | `sweeper_damage` | `xmage_controlled_creature_power_damage_each_other_creature_each_opponent_review_v1` | `ChandrasIgnition` |
| `Karn's Sylex` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `board_wipe` | `xmage_mass_removal_or_sacrifice_variant_review_v1` | `KarnsSylex` |
| `Single Combat` | -10 | `615` | `hand_filter` | `split_family_scope_review_required` | `` |  | `board_wipe` | `xmage_mass_removal_or_sacrifice_variant_review_v1` | `SingleCombat` |
| `Unstable Glyphbridge // Sandswirl Wanderglyph` | -10 | `610` | `pressure_absorber_or_protection` | `split_family_scope_review_required` | `` |  | `board_wipe` | `xmage_mass_removal_or_sacrifice_variant_review_v1` | `UnstableGlyphbridge` |

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 2 cards; lanes `{"hand_filter": 2}`; samples `Verge Rangers, Lens of Clarity`
- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Orcish Spy`
- `targeting;activated_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Lantern of Insight`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Verge Rangers` | 0 | `609, 611, 613` | `hand_filter` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `topdeck_play` | `look_top_library_play_lands_from_top_if_opponent_more_lands_v1` | `VergeRangers` |
| `Lantern of Insight` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `topdeck_play` | `each_player_top_library_revealed_tap_sacrifice_target_player_shuffle_v1` | `LanternOfInsight` |
| `Lens of Clarity` | -10 | `610` | `hand_filter` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `topdeck_play` | `look_top_library_any_time_and_opponent_face_down_creatures_v1` | `LensOfClarity` |
| `Orcish Spy` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `topdeck_play` | `tap_look_top_three_target_player_library_v1` | `OrcishSpy` |

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `draw;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Naktamun Lorespinner // Wheel of Fortune`
- `static_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Alhammarret's Archive`
- `targeting;draw;token;triggered_ability;activated_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Currency Converter`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Alhammarret's Archive` | -10 | `611` | `hand_filter` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `draw_engine` | `static_double_life_gain_and_draw_except_first_draw_step_v1` | `AlhammarretsArchive` |
| `Currency Converter` | -10 | `614` | `early_mana` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `draw_engine` | `currency_converter_discard_exile_draw_discard_token_v1` | `CurrencyConverter` |
| `Naktamun Lorespinner // Wheel of Fortune` | -10 | `608` | `contextual` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `NaktamunLorespinner` |

### passive

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 2 cards; lanes `{"early_mana": 1, "hand_filter": 1}`; samples `Blood Moon, Vedalken Orrery`
- `targeting;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn, the Great Creator`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Blood Moon` | -10 | `616` | `hand_filter` | `split_family_scope_review_required` | `` |  | `passive` | `xmage_nonbasic_lands_are_mountains_static_review_v1` | `BloodMoon` |
| `Karn, the Great Creator` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `passive` | `xmage_artifact_activation_lock_planeswalker_wish_review_v1` | `KarnTheGreatCreator` |
| `Vedalken Orrery` | -10 | `613` | `early_mana` | `split_family_scope_review_required` | `` |  | `passive` | `static_cast_as_flash_permission_variant_review_v1` | `VedalkenOrrery` |

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;token;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Prototype Portal`
- `triggered_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Ancient Gold Dragon`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ancient Gold Dragon` | -10 | `612` | `finisher_or_big_spell` | `split_family_scope_review_required` | `` |  | `token_maker` | `xmage_combat_damage_d20_faerie_dragon_token_review_v1` | `AncientGoldDragon` |
| `Prototype Portal` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `token_maker` | `imprint_artifact_from_hand_create_token_copy_x_mana_value_v1` | `PrototypePortal` |

### static_damage_modifier

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_twinflame_tyrant_doubles_damage_to_each_opponent", "test_twinflame_tyrant_doubles_wipe_damage_only_to_opponent_permanents", "test_twinflame_tyrant_doubles_combat_damage_and_commander_damage", "test_gisela_doubles_any_source_damage_to_opponents", "test_gisela_halves_damage_to_controller_rounded_up"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `damage;static_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Gisela, Blade of Goldnight`
- `static_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Twinflame Tyrant`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Twinflame Tyrant` | 0 | `608, 611, 615` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `damage_modifier` | `controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1` | `TwinflameTyrant` |
| `Gisela, Blade of Goldnight` | -10 | `612` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `damage_modifier` | `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1` | `GiselaBladeOfGoldnight` |

### targeted_protection

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg204_gods_willing_grants_protection_to_best_creature_until_cleanup"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"protection_window": 1}`; samples `Whispersilk Cloak`
- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Eight-and-a-Half-Tails`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Eight-and-a-Half-Tails` | -10 | `616` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `creature` | `creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1` | `EightAndAHalfTails` |
| `Whispersilk Cloak` | -10 | `616` | `protection_window` | `split_family_scope_review_required` | `` |  | `grant_protection_from_chosen_color` | `xmage_targeted_protection_variant_review_v1` | `WhispersilkCloak` |

### life_total_change

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_life_total_change_runtime"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `no_structural_signal`: 1 cards; lanes `{"hand_filter": 1}`; samples `Heroes Remembered`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Heroes Remembered` | 0 | `614, 615` | `hand_filter` | `split_family_scope_review_required` | `` |  | `life_gain` | `xmage_life_gain_variant_review_v1` | `HeroesRemembered` |

### mill_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_brain_freeze_mills_library_instead_of_dealing_life_damage"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mill;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Ghoulcaller's Bell`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ghoulcaller's Bell` | -10 | `610` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `mill_engine` | `artifact_tap_each_player_mill_one_v1` | `GhoulcallersBell` |

### ramp_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mana_or_cost;triggered_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Neheb, the Eternal`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Neheb, the Eternal` | -10 | `616` | `early_mana` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `ramp_engine` | `postcombat_main_add_red_for_opponents_life_lost_this_turn_v1` | `NehebTheEternal` |

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting`: 1 cards; lanes `{"contextual": 1}`; samples `Deathbellow War Cry`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Deathbellow War Cry` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `` |  | `tutor` | `xmage_library_search_variant_review_v1` | `DeathbellowWarCry` |

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `mana_or_cost;static_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Cloud Key`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Cloud Key` | -10 | `612` | `early_mana` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `static_cost_reduction` | `chosen_card_type_cost_reduction_v1` | `CloudKey` |
