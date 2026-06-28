# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-28T11:24:11Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Blocked runtime cards: `61`
- Candidate lanes: `{"contextual": 36, "early_mana": 7, "finisher_or_big_spell": 6, "hand_filter": 9, "pressure_absorber_or_protection": 2, "protection_window": 1}`
- Promotion lanes: `{"batch_metadata_candidate_requires_pg_precheck": 6, "mapper_metadata_or_test_scenario_required": 52, "split_family_scope_review_required": 3}`
- Targeted interaction subfamilies: `{"creature_damage_controller_reflect_global": 1, "excess_damage_redirect_to_any_target": 1, "instant_sorcery_lifelink_lifegain_damage_engine": 1, "source_damaged_reflect_to_any_target": 1, "spell_color_trigger_damage_life_engine": 1, "targeted_damage_etb_power_to_any_target": 1}`
- Targeted interaction subfamily statuses: `{"runtime_family_implementation_required": 3, "runtime_supported_family": 3}`
- Family count: `5`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `manual_model` | 52 | `manual_model_required` | `not_batch_safe` | `{"contextual": 30, "early_mana": 7, "finisher_or_big_spell": 4, "hand_filter": 8, "pressure_absorber_or_protection": 2, "protection_window": 1}` | `{"mapper_metadata_or_test_scenario_required": 52}` | manual Oracle/reference review |
| 2 | `targeted_interaction` | 6 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 5, "finisher_or_big_spell": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 3, "split_family_scope_review_required": 3}` | target legality, resolution, zone transition, and event provenance |
| 3 | `free_cast` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| 4 | `static_damage_modifier` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"finisher_or_big_spell": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | continuous replacement effects that modify damage amounts by source controller and target ownership |
| 5 | `topdeck_play` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"hand_filter": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | top-of-library visibility and permission to play cards from library under board-state conditions |

## Cards By Family

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 10 cards; lanes `{"contextual": 5, "early_mana": 1, "hand_filter": 3, "protection_window": 1}`; samples `Alhammarret's Archive, Assemble the Players, Blood Moon, Lens of Clarity, Rem Karolus, Stalwart Slayer, Sawhorn Nemesis, Serra Ascendant, The Walls of Ba Sing Se`
- `targeting`: 6 cards; lanes `{"contextual": 2, "finisher_or_big_spell": 1, "hand_filter": 2, "pressure_absorber_or_protection": 1}`; samples `Beacon of Immortality, Chandra's Ignition, Deathbellow War Cry, Ephemerate, Single Combat, Wild Ricochet`
- `targeting;mill;activated_ability`: 5 cards; lanes `{"contextual": 4, "early_mana": 1}`; samples `Codex Shredder, Ghoulcaller's Bell, Leyline Dowser, Perpetual Timepiece, Wand of Vertebrae`
- `triggered_ability`: 5 cards; lanes `{"contextual": 3, "early_mana": 1, "finisher_or_big_spell": 1}`; samples `Ancient Copper Dragon, Ancient Gold Dragon, Charmbreaker Devils, Possibility Storm, Slickshot Show-Off`
- `activated_ability`: 3 cards; lanes `{"contextual": 3}`; samples `Karn's Sylex, Kayla's Music Box, Pyxis of Pandemonium`
- `no_structural_signal`: 3 cards; lanes `{"finisher_or_big_spell": 1, "hand_filter": 2}`; samples `Heroes Remembered, Invincible Hymn, Taunt from the Rampart`
- `targeting;activated_ability`: 3 cards; lanes `{"contextual": 3}`; samples `Chaos Wand, Eight-and-a-Half-Tails, Orcish Spy`
- `targeting;activated_ability;static_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Lantern of Insight, The Warring Triad`
- `damage;static_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Gisela, Blade of Goldnight`
- `damage;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Stuffy Doll`
- `damage;triggered_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence`
- `draw;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Naktamun Lorespinner // Wheel of Fortune`
- `mana_or_cost;static_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Cloud Key`
- `targeting;condition;activated_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Zirda, the Dawnwaker`
- `targeting;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Radiant Performer`
- `targeting;condition;triggered_ability;static_ability`: 1 cards; lanes `{"pressure_absorber_or_protection": 1}`; samples `Unstable Glyphbridge // Sandswirl Wanderglyph`
- `targeting;draw;token;triggered_ability;activated_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Currency Converter`
- `targeting;mana_or_cost;triggered_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Neheb, the Eternal`
- `targeting;mana_or_cost;triggered_ability;static_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Semblance Anvil`
- `targeting;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn, the Great Creator`
- `targeting;token;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Prototype Portal`
- `targeting;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Screaming Nemesis`
- `triggered_ability;activated_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Planetarium of Wan Shi Tong`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ancient Copper Dragon` | 0 | `608, 616` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AncientCopperDragon` |
| `Beacon of Immortality` | 0 | `610, 615` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `BeaconOfImmortality` |
| `Heroes Remembered` | 0 | `614, 615` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `HeroesRemembered` |
| `Invincible Hymn` | 0 | `610, 614` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `InvincibleHymn` |
| `Planetarium of Wan Shi Tong` | 0 | `611, 613` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PlanetariumOfWanShiTong` |
| `Semblance Anvil` | 0 | `612, 616` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SemblanceAnvil` |
| `Taunt from the Rampart` | 0 | `611, 615` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `TauntFromTheRampart` |
| `Alhammarret's Archive` | -10 | `611` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AlhammarretsArchive` |
| `Ancient Gold Dragon` | -10 | `612` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AncientGoldDragon` |
| `Assemble the Players` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AssembleThePlayers` |
| `Blood Moon` | -10 | `616` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `BloodMoon` |
| `Chandra's Ignition` | -10 | `613` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ChandrasIgnition` |
| `Chaos Wand` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ChaosWand` |
| `Charmbreaker Devils` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `CharmbreakerDevils` |
| `Cloud Key` | -10 | `612` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `CloudKey` |
| `Codex Shredder` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `CodexShredder` |
| `Currency Converter` | -10 | `614` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `CurrencyConverter` |
| `Deathbellow War Cry` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `DeathbellowWarCry` |
| `Eight-and-a-Half-Tails` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `EightAndAHalfTails` |
| `Ephemerate` | -10 | `612` | `pressure_absorber_or_protection` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `Ephemerate` |
| `Ghoulcaller's Bell` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `GhoulcallersBell` |
| `Gisela, Blade of Goldnight` | -10 | `612` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `GiselaBladeOfGoldnight` |
| `Karn's Sylex` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KarnsSylex` |
| `Karn, the Great Creator` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KarnTheGreatCreator` |
| `Kayla's Music Box` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KaylasMusicBox` |
| `Lantern of Insight` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LanternOfInsight` |
| `Lens of Clarity` | -10 | `610` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LensOfClarity` |
| `Leyline Dowser` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LeylineDowser` |
| `Naktamun Lorespinner // Wheel of Fortune` | -10 | `608` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `NaktamunLorespinner` |
| `Neheb, the Eternal` | -10 | `616` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `NehebTheEternal` |
| `Orcish Spy` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `OrcishSpy` |
| `Perpetual Timepiece` | -10 | `610` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PerpetualTimepiece` |
| `Possibility Storm` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PossibilityStorm` |
| `Prototype Portal` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PrototypePortal` |
| `Pyxis of Pandemonium` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PyxisOfPandemonium` |
| `Radiant Performer` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RadiantPerformer` |
| `Rem Karolus, Stalwart Slayer` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RemKarolusStalwartSlayer` |
| `Rune-Tail, Kitsune Ascendant // Rune-Tail's Essence` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `RuneTailKitsuneAscendant` |
| `Sawhorn Nemesis` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SawhornNemesis` |
| `Screaming Nemesis` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ScreamingNemesis` |
| `Serra Ascendant` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SerraAscendant` |
| `Single Combat` | -10 | `615` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SingleCombat` |
| `Slickshot Show-Off` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `SlickshotShowOff` |
| `Stuffy Doll` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `StuffyDoll` |
| `The Walls of Ba Sing Se` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `TheWallsOfBaSingSe` |
| `The Warring Triad` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `TheWarringTriad` |
| `Unstable Glyphbridge // Sandswirl Wanderglyph` | -10 | `610` | `pressure_absorber_or_protection` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `UnstableGlyphbridge` |
| `Vedalken Orrery` | -10 | `613` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `VedalkenOrrery` |
| `Wand of Vertebrae` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `WandOfVertebrae` |
| `Whispersilk Cloak` | -10 | `616` | `protection_window` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `WhispersilkCloak` |
| `Wild Ricochet` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `WildRicochet` |
| `Zirda, the Dawnwaker` | -10 | `612` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ZirdaTheDawnwaker` |

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{"creature_damage_controller_reflect_global": 1, "excess_damage_redirect_to_any_target": 1, "instant_sorcery_lifelink_lifegain_damage_engine": 1, "source_damaged_reflect_to_any_target": 1, "spell_color_trigger_damage_life_engine": 1, "targeted_damage_etb_power_to_any_target": 1}`
- Targeted interaction subfamily statuses: `{"runtime_family_implementation_required": 3, "runtime_supported_family": 3}`

Signal groups:

- `targeting;damage;triggered_ability;static_ability`: 3 cards; lanes `{"contextual": 2, "finisher_or_big_spell": 1}`; samples `Terror of the Peaks, Balefire Liege, Firesong and Sunspeaker`
- `damage;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Repercussion`
- `targeting;damage;condition;triggered_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Toralf, God of Fury // Toralf's Hammer`
- `targeting;damage;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Boros Reckoner`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Repercussion` | -10 | `612` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `creature_damage_controller_reflect_global` | prepare PG metadata package after PostgreSQL precheck, then gate Repercussion sweeper synergy | `direct_damage` | `creature_damage_controller_reflect_global_v1` | `Repercussion` |
| `Toralf, God of Fury // Toralf's Hammer` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `excess_damage_redirect_to_any_target` | implement Toralf excess-damage batch trigger and MDFC hammer activated damage separately | `direct_damage` | `targeted_damage_variant_v1` | `ToralfGodOfFury` |
| `Boros Reckoner` | 0 | `612, 616` | `contextual` | `split_family_scope_review_required` | `source_damaged_reflect_to_any_target` | implement Boros-Reckoner style damage reflection and target choice tests | `direct_damage` | `targeted_damage_variant_v1` | `BorosReckoner` |
| `Terror of the Peaks` | 0 | `608, 612` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `targeted_damage_etb_power_to_any_target` | prepare PG metadata package after PostgreSQL precheck, then gate Terror of the Peaks ETB damage lines | `creature` | `controlled_other_creature_enters_power_damage_any_target_v1` | `TerrorOfThePeaks` |
| `Balefire Liege` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `spell_color_trigger_damage_life_engine` | split Balefire Liege red and white spell triggers before PG metadata promotion | `direct_damage` | `targeted_damage_variant_v1` | `BalefireLiege` |
| `Firesong and Sunspeaker` | -10 | `616` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `instant_sorcery_lifelink_lifegain_damage_engine` | prepare PG metadata package after PostgreSQL precheck, then gate Firesong burn/lifegain lines | `creature` | `red_instant_sorcery_lifelink_white_lifegain_damage_v1` | `FiresongAndSunspeaker` |

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Goliath Daydreamer`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Goliath Daydreamer` | 10 | `613, 614, 615` | `contextual` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `free_cast` | `instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1` | `GoliathDaydreamer` |

### static_damage_modifier

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_twinflame_tyrant_doubles_damage_to_each_opponent", "test_twinflame_tyrant_doubles_wipe_damage_only_to_opponent_permanents", "test_twinflame_tyrant_doubles_combat_damage_and_commander_damage"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Twinflame Tyrant`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Twinflame Tyrant` | 0 | `608, 611, 615` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `damage_modifier` | `controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1` | `TwinflameTyrant` |

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Verge Rangers`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Verge Rangers` | 0 | `609, 611, 613` | `hand_filter` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `topdeck_play` | `look_top_library_play_lands_from_top_if_opponent_more_lands_v1` | `VergeRangers` |
