# Lorehold Runtime Gap Family Queue

- Generated at: `2026-06-30T13:43:28Z`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- SQLite current-rule filter: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- Raw blocked runtime cards: `61`
- Filtered current verified/auto rules: `53`
- Blocked runtime cards: `8`
- Candidate lanes: `{"contextual": 5, "finisher_or_big_spell": 1, "hand_filter": 2}`
- Promotion lanes: `{"split_family_scope_review_required": 8}`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`
- Family count: `6`

## Family Queue

| Rank | Family | Cards | Support | Batch strategy | Candidate lanes | Promotion lanes | Implementation unit |
| ---: | --- | ---: | --- | --- | --- | --- | --- |
| 1 | `passive` | 2 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 2}` | static battlefield annotation and passive support execution |
| 2 | `board_wipe_choice` | 2 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"contextual": 1, "hand_filter": 1}` | `{"split_family_scope_review_required": 2}` | multi-player choice/wipe/sacrifice resolution |
| 3 | `draw_engine` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | static and activated draw-engine bookkeeping with delayed card movement |
| 4 | `recursion` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| 5 | `tutor` | 1 | `runtime_family_partially_supported_review_required` | `split_by_scope_before_metadata_batch` | `{"contextual": 1}` | `{"split_family_scope_review_required": 1}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| 6 | `token_maker` | 1 | `runtime_family_required` | `implement_family_before_metadata_batch` | `{"finisher_or_big_spell": 1}` | `{"split_family_scope_review_required": 1}` | token creation with stats, abilities, duration, and zone cleanup |

## Cards By Family

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

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `triggered_ability`: 1 cards; lanes `{"contextual": 1}`; samples `Charmbreaker Devils`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Charmbreaker Devils` | -10 | `612` | `contextual` | `split_family_scope_review_required` | `` |  | `recursion` | `xmage_graveyard_return_variant_review_v1` | `CharmbreakerDevils` |

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

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Targeted interaction subfamilies: `{}`
- Targeted interaction subfamily statuses: `{}`

Signal groups:

- `triggered_ability`: 1 cards; lanes `{"finisher_or_big_spell": 1}`; samples `Ancient Gold Dragon`

| Card | Score | Variant decks | Lane | Promotion | Subfamily | Next step | Effect | Scope | XMage class |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ancient Gold Dragon` | -10 | `612` | `finisher_or_big_spell` | `split_family_scope_review_required` | `` |  | `token_maker` | `xmage_combat_damage_d20_faerie_dragon_token_review_v1` | `AncientGoldDragon` |
