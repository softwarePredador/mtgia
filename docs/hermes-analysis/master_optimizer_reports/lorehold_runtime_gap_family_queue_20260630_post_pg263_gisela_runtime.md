# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-30T05:39:53Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite current-rule filter: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Raw blocked runtime cards: `61`
- Filtered current verified/auto rules: `34`
- Blocked runtime cards: `27`
- Candidate lanes: `{"contextual": 17, "early_mana": 4, "finisher_or_big_spell": 2, "hand_filter": 4}`
- Promotion lanes: `{"batch_metadata_candidate_requires_pg_precheck": 1, "mapper_metadata_or_test_scenario_required": 13, "split_family_scope_review_required": 13}`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`
- Family count: `10`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `manual_model` | 13 | `manual_model_required` | `not_batch_safe` | `{"contextual": 9, "early_mana": 1, "finisher_or_big_spell": 1, "hand_filter": 2}` | `{"mapper_metadata_or_test_scenario_required": 13}` | manual Oracle/reference review |
| 2 | `draw_engine` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "early_mana": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 3}` | static and activated draw-engine bookkeeping with delayed card movement |
| 3 | `recursion` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 2, "early_mana": 1}` | `{"split_family_scope_review_required": 3}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| 4 | `free_cast` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 2}` | `{"split_family_scope_review_required": 2}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| 5 | `ramp_permanent` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"early_mana": 1}` | `{"split_family_scope_review_required": 1}` | battlefield mana artifacts and triggered resource permanents |
| 6 | `tutor` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| 7 | `board_wipe_choice` | 1 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | multi-player choice/wipe/sacrifice resolution |
| 8 | `static_damage_modifier` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"finisher_or_big_spell": 1}` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | continuous replacement effects that modify damage amounts by source controller and target ownership |
| 9 | `targeted_protection` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | targeted own-creature protection grant and cleanup-aware target legality |
| 10 | `topdeck_play` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"hand_filter": 1}` | `{"split_family_scope_review_required": 1}` | top-of-library visibility and permission to play cards from library under board-state conditions |

## Cards By Family

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `activated_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Kayla's Music Box, Pyxis of Pandemonium`
- `targeting;mill;activated_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Ghoulcaller's Bell, Leyline Dowser`
- `triggered_ability`: 2 cards; lanes `{"contextual": 1, "finisher_or_big_spell": 1}`; samples `Ancient Gold Dragon, Possibility Storm`
- `mana_or_cost;static_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Cloud Key`
- `static_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Blood Moon`
- `targeting`: 1 cards; lanes `{"hand_filter": 1}`; samples `Chandra's Ignition`
- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Orcish Spy`
- `targeting;activated_ability;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Lantern of Insight`
- `targeting;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn, the Great Creator`
- `targeting;token;triggered_ability;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Prototype Portal`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ancient Gold Dragon` | -10 | `612` | `finisher_or_big_spell` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `AncientGoldDragon` |
| `Blood Moon` | -10 | `616` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `BloodMoon` |
| `Chandra's Ignition` | -10 | `613` | `hand_filter` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `ChandrasIgnition` |
| `Cloud Key` | -10 | `612` | `early_mana` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `CloudKey` |
| `Ghoulcaller's Bell` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `GhoulcallersBell` |
| `Karn, the Great Creator` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KarnTheGreatCreator` |
| `Kayla's Music Box` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KaylasMusicBox` |
| `Lantern of Insight` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LanternOfInsight` |
| `Leyline Dowser` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LeylineDowser` |
| `Orcish Spy` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `OrcishSpy` |
| `Possibility Storm` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PossibilityStorm` |
| `Prototype Portal` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PrototypePortal` |
| `Pyxis of Pandemonium` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PyxisOfPandemonium` |

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
| `Alhammarret's Archive` | -10 | `611` | `hand_filter` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `AlhammarretsArchive` |
| `Currency Converter` | -10 | `614` | `early_mana` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `CurrencyConverter` |
| `Naktamun Lorespinner // Wheel of Fortune` | -10 | `608` | `contextual` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `NaktamunLorespinner` |

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mill;activated_ability`: 2 cards; lanes `{"contextual": 1, "early_mana": 1}`; samples `Codex Shredder, Perpetual Timepiece`
- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Charmbreaker Devils`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Charmbreaker Devils` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CharmbreakerDevils` |
| `Codex Shredder` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CodexShredder` |
| `Perpetual Timepiece` | -10 | `610` | `early_mana` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `PerpetualTimepiece` |

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Assemble the Players`
- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Chaos Wand`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Assemble the Players` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `AssembleThePlayers` |
| `Chaos Wand` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `ChaosWand` |

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mana_or_cost;triggered_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Neheb, the Eternal`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Neheb, the Eternal` | -10 | `616` | `early_mana` | `split_family_scope_review_required` | `` |  | `ramp_permanent` | `xmage_creature_mana_source_variant_review_v1` | `NehebTheEternal` |

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

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn's Sylex`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Karn's Sylex` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `board_wipe` | `xmage_mass_removal_or_sacrifice_variant_review_v1` | `KarnsSylex` |

### static_damage_modifier

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_twinflame_tyrant_doubles_damage_to_each_opponent", "test_twinflame_tyrant_doubles_wipe_damage_only_to_opponent_permanents", "test_twinflame_tyrant_doubles_combat_damage_and_commander_damage", "test_gisela_doubles_any_source_damage_to_opponents", "test_gisela_halves_damage_to_controller_rounded_up"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `damage;static_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Gisela, Blade of Goldnight`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Gisela, Blade of Goldnight` | -10 | `612` | `finisher_or_big_spell` | `batch_metadata_candidate_requires_pg_precheck` | `` |  | `damage_modifier` | `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1` | `GiselaBladeOfGoldnight` |

### targeted_protection

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg204_gods_willing_grants_protection_to_best_creature_until_cleanup"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Eight-and-a-Half-Tails`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Eight-and-a-Half-Tails` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `` |  | `grant_protection_from_chosen_color` | `xmage_targeted_protection_variant_review_v1` | `EightAndAHalfTails` |

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Lens of Clarity`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Lens of Clarity` | -10 | `610` | `hand_filter` | `split_family_scope_review_required` | `` |  | `topdeck_play` | `xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `LensOfClarity` |
