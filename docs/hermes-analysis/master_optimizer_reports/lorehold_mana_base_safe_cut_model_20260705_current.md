# Lorehold Mana Base Safe-Cut Model

- generated_at: `2026-07-05T00:14:46Z`
- status: `lorehold_mana_base_safe_cut_model_ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- deck_id: `607`
- current_land_quantity: `34`
- candidate_count: `7`
- model_ready_pair_count: `2`
- diagnostic_pair_count: `43`
- blocked_pair_count: `151`
- promotion_allowed: `false`
- allow_battle_gate_now: `false`

## Current Mana Base Counts

- counts: `{"always_tapped_rows": 2, "colorless_only_rows": 6, "conditional_tapped_rows": 2, "direct_rw_rows": 11, "fetch_or_search_rows": 8, "land_quantity": 34, "protected_utility_rows": 9, "red_access_rows": 20, "topdeck_or_card_flow_land_rows": 5, "typed_mountain_plains_rows": 5, "white_access_rows": 21}`

## Model-Ready Pairs

| Score | Add | Cut | Reasons |
| --- | --- | --- | --- |
| `52` | `Plateau` | `Radiant Summit` | tempo_upgrade_preserves_color_and_fetch_target_type |
| `52` | `Plateau` | `Turbulent Steppe` | tempo_upgrade_preserves_color_and_fetch_target_type |

## Diagnostic Pairs

| Score | Status | Add | Cut | Reasons |
| --- | --- | --- | --- | --- |
| `43` | `diagnostic_only` | `Plateau` | `Battlefield Forge` | no_clear_upgrade_without_forced_diagnostic |
| `43` | `diagnostic_only` | `Plateau` | `Exotic Orchard` | no_clear_upgrade_without_forced_diagnostic |
| `43` | `diagnostic_only` | `Plateau` | `Spectator Seating` | no_clear_upgrade_without_forced_diagnostic |
| `43` | `diagnostic_only` | `Plateau` | `Sunbillow Verge` | no_clear_upgrade_without_forced_diagnostic |
| `33` | `diagnostic_only_loses_topdeck_utility` | `Plateau` | `Elegant Parlor` | cut_loses_topdeck_or_card_flow_land_utility |
| `26` | `diagnostic_only_loses_topdeck_utility` | `Plateau` | `Glittering Massif` | cut_loses_topdeck_or_card_flow_land_utility |
| `23` | `diagnostic_only` | `Plateau` | `Sacred Foundry` | no_clear_upgrade_without_forced_diagnostic |
| `19` | `diagnostic_only` | `Rugged Prairie` | `Battlefield Forge` | no_clear_upgrade_without_forced_diagnostic |
| `19` | `diagnostic_only` | `Rugged Prairie` | `Exotic Orchard` | no_clear_upgrade_without_forced_diagnostic |
| `19` | `diagnostic_only` | `Rugged Prairie` | `Spectator Seating` | no_clear_upgrade_without_forced_diagnostic |
| `19` | `diagnostic_only` | `Rugged Prairie` | `Sunbillow Verge` | no_clear_upgrade_without_forced_diagnostic |
| `9` | `diagnostic_only_loses_fetch_target_type` | `Rugged Prairie` | `Elegant Parlor` | cut_loses_fetchable_mountain_plains_type, cut_loses_topdeck_or_card_flow_land_utility |

## Candidate Lands

- `Plateau` score `121` tapped `reliably_untapped` typed `true` colorless `false` utility `none` variants `7`
- `Clifftop Retreat` score `82` tapped `conditional_tapped` typed `false` colorless `false` utility `none` variants `6`
- `Boseiju, Who Shelters All` score `16` tapped `always_tapped` typed `false` colorless `true` utility `anti_countermagic` variants `4`
- `Rugged Prairie` score `97` tapped `reliably_untapped` typed `false` colorless `false` utility `none` variants `4`
- `Sundown Pass` score `78` tapped `conditional_tapped` typed `false` colorless `false` utility `none` variants `4`
- `Boros Garrison` score `44` tapped `always_tapped` typed `false` colorless `false` utility `bounce_land_tempo_risk` variants `3`
- `Cavern of Souls` score `39` tapped `reliably_untapped` typed `false` colorless `true` utility `anti_countermagic` variants `3`

## Protected Current Lands

- `Ancient Tomb`: fast_mana_life_cost_floor
- `Command Beacon`: commander_tax_recovery
- `Command Tower`: best_any_color_commander_source
- `Eiganjo, Seat of the Empire`: untapped_white_plus_combat_removal
- `Plaza of Heroes`: legendary_casting_and_lorehold_protection
- `Reliquary Tower`: hand_size_for_rummage_and_big_draw
- `Sunbaked Canyon`: untapped_color_source_plus_card_flow
- `Urza's Saga`: artifact_tutor_for_topdeck_engine
- `War Room`: colorless_card_flow

## Policy

- land_count: Keep 34 lands for the 607 shell unless a later battle result explicitly proves a different count.
- typed_fetch_targets: Typed Mountain Plains lands are not interchangeable with non-typed fixing when fetch density and Land Tax/Scroll Rack shuffling matter.
- utility_lands: Protected utility lands require exact same-function proof before cutting.
- battle_gate: A model-ready land swap must still be materialized, structure-checked, miracle-access preflighted, and battle-gated before promotion.

## External Research Refresh

- Scryfall Boros land oracle data: https://scryfall.com/search?as=grid&order=edhrec&q=t%3Aland+ci%3Drw&unique=cards
  - Candidate land text must be judged by actual Oracle text, not only by EDH popularity.
- Scryfall Plateau: https://scryfall.com/card/3ed/284/plateau
  - Plateau is an untapped Mountain Plains, so it preserves fetch-target type while improving tempo over tapped typed lands.
- EDHREC Lorehold average topdeck deck: https://edhrec.com/average-decks/lorehold-the-historian/topdeck
  - Public topdeck shells include common Boros fixing such as Clifftop Retreat, but public average lists are evidence lanes, not cuts.
- EDHREC Lorehold budget miracles: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
  - Lorehold mana base needs lands and utility that avoid dead miracle draws and support opponent-turn spell windows.
- Draftsim Lorehold guide: https://draftsim.com/lorehold-the-historian-edh-deck/
  - External decklists also use Boseiju, Clifftop Retreat, Rugged Prairie, Sundown Pass, and utility lands, but still frame mana-base changes as budget/meta choices.
- Commander deckbuilding contract: docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md
  - Mana foundation, same-lane cuts, protected anchors, and battle/replay validation are separate gates.

## Decision

- current_best_baseline: `deck_607`
- promotion_allowed: `false`
- best_structural_learning_pair: `+Plateau / -Radiant Summit`
- reason: The mana-base model found structural candidates, but no land swap has yet passed candidate materialization, miracle-access preflight, equal battle gate, and replay trace checks.
- next_action: `materialize the highest scoring model-ready land pair only as a diagnostic candidate, then rerun structural and miracle-access gates`
