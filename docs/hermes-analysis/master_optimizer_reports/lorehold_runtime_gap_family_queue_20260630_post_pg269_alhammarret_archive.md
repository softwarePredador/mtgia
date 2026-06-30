# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-30T07:00:59Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite current-rule filter: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Raw blocked runtime cards: `61`
- Filtered current verified/auto rules: `40`
- Blocked runtime cards: `21`
- Candidate lanes: `{"contextual": 16, "early_mana": 2, "finisher_or_big_spell": 1, "hand_filter": 2}`
- Promotion lanes: `{"mapper_metadata_or_test_scenario_required": 12, "split_family_scope_review_required": 9}`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`
- Family count: `6`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `manual_model` | 12 | `manual_model_required` | `not_batch_safe` | `{"contextual": 9, "finisher_or_big_spell": 1, "hand_filter": 2}` | `{"mapper_metadata_or_test_scenario_required": 12}` | manual Oracle/reference review |
| 2 | `recursion` | 3 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 2, "early_mana": 1}` | `{"split_family_scope_review_required": 3}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| 3 | `draw_engine` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "early_mana": 1}` | `{"split_family_scope_review_required": 2}` | static and activated draw-engine bookkeeping with delayed card movement |
| 4 | `free_cast` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 2}` | `{"split_family_scope_review_required": 2}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| 5 | `tutor` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| 6 | `board_wipe_choice` | 1 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | multi-player choice/wipe/sacrifice resolution |

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
| `Ghoulcaller's Bell` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `GhoulcallersBell` |
| `Karn, the Great Creator` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KarnTheGreatCreator` |
| `Kayla's Music Box` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `KaylasMusicBox` |
| `Lantern of Insight` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LanternOfInsight` |
| `Leyline Dowser` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `LeylineDowser` |
| `Orcish Spy` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `OrcishSpy` |
| `Possibility Storm` | -10 | `616` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PossibilityStorm` |
| `Prototype Portal` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PrototypePortal` |
| `Pyxis of Pandemonium` | -10 | `610` | `contextual` | `mapper_metadata_or_test_scenario_required` | `` |  | `external_reference_required_manual_model` | `xmage_reference_requires_manual_model_review_v1` | `PyxisOfPandemonium` |

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

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `draw;condition;triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Naktamun Lorespinner // Wheel of Fortune`
- `targeting;draw;token;triggered_ability;activated_ability`: 1 cards; lanes `{"early_mana": 1}`; samples `Currency Converter`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Currency Converter` | -10 | `614` | `early_mana` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `CurrencyConverter` |
| `Naktamun Lorespinner // Wheel of Fortune` | -10 | `608` | `contextual` | `split_family_scope_review_required` | `` |  | `draw_engine` | `xmage_draw_card_variant_review_v1` | `NaktamunLorespinner` |

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
