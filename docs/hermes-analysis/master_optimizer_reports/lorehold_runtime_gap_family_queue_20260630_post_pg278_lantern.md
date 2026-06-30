# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-30T12:07:46Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite current-rule filter: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Raw blocked runtime cards: `61`
- Filtered current verified/auto rules: `47`
- Blocked runtime cards: `14`
- Candidate lanes: `{"contextual": 11, "finisher_or_big_spell": 1, "hand_filter": 2}`
- Promotion lanes: `{"split_family_scope_review_required": 14}`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`
- Family count: `8`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `free_cast` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 3}` | `{"split_family_scope_review_required": 3}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| 2 | `passive` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 2}` | static battlefield annotation and passive support execution |
| 3 | `recursion` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 2}` | `{"split_family_scope_review_required": 2}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| 4 | `board_wipe_choice` | 2 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 2}` | multi-player choice/wipe/sacrifice resolution |
| 5 | `token_maker` | 2 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1, "finisher_or_big_spell": 1}` | `{"split_family_scope_review_required": 2}` | token creation with stats, abilities, duration, and zone cleanup |
| 6 | `draw_engine` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | static and activated draw-engine bookkeeping with delayed card movement |
| 7 | `tutor` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| 8 | `topdeck_play` | 1 | `runtime_supported_family` | `metadata_batch_after_pg_precheck` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | top-of-library visibility and permission to play cards from library under board-state conditions |

## Cards By Family

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `activated_ability`: 2 cards; lanes `{"contextual": 2}`; samples `Kayla's Music Box, Pyxis of Pandemonium`
- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Possibility Storm`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Kayla's Music Box` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_artifact_exile_top_face_down_play_owned_exiled_review_v1` | `KaylasMusicBox` |
| `Possibility Storm` | -10 | `616` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_spell_from_hand_exile_until_shared_type_free_cast_review_v1` | `PossibilityStorm` |
| `Pyxis of Pandemonium` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `free_cast` | `xmage_each_player_exile_top_face_down_put_permanents_battlefield_review_v1` | `PyxisOfPandemonium` |

### passive

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `static_ability`: 1 cards; lanes `{"hand_filter": 1}`; samples `Blood Moon`
- `targeting;static_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn, the Great Creator`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Blood Moon` | -10 | `616` | `hand_filter` | `split_family_scope_review_required` | `` |  | `passive` | `xmage_nonbasic_lands_are_mountains_static_review_v1` | `BloodMoon` |
| `Karn, the Great Creator` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `passive` | `xmage_artifact_activation_lock_planeswalker_wish_review_v1` | `KarnTheGreatCreator` |

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;mill;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Leyline Dowser`
- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Charmbreaker Devils`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Charmbreaker Devils` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CharmbreakerDevils` |
| `Leyline Dowser` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_artifact_mill_one_put_milled_instant_sorcery_into_hand_untap_review_v1` | `LeylineDowser` |

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Karn's Sylex`
- `targeting`: 1 cards; lanes `{"hand_filter": 1}`; samples `Chandra's Ignition`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Chandra's Ignition` | -10 | `613` | `hand_filter` | `split_family_scope_review_required` | `` |  | `sweeper_damage` | `xmage_controlled_creature_power_damage_each_other_creature_each_opponent_review_v1` | `ChandrasIgnition` |
| `Karn's Sylex` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `board_wipe` | `xmage_mass_removal_or_sacrifice_variant_review_v1` | `KarnsSylex` |

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
| `Prototype Portal` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `token_maker` | `xmage_imprint_artifact_create_copy_token_x_cost_review_v1` | `PrototypePortal` |

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `draw;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Naktamun Lorespinner // Wheel of Fortune`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Naktamun Lorespinner // Wheel of Fortune` | -10 | `608` | `contextual` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `NaktamunLorespinner` |

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

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `targeting;activated_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Orcish Spy`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Orcish Spy` | -10 | `610` | `contextual` | `split_family_scope_review_required` | `` |  | `topdeck_play` | `xmage_tap_look_top_three_target_player_library_review_v1` | `OrcishSpy` |
