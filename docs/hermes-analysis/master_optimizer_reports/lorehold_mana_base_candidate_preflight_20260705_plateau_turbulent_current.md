# Lorehold Mana Base Candidate Preflight

- generated_at: `2026-07-05T00:49:23Z`
- status: `battle_smoke_preflight_ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- deck_id: `607`
- candidate: `+Plateau / -Turbulent Steppe`
- allow_smoke_battle_gate: `true`
- allow_promotion_gate: `false`
- keep_607_as_protected_baseline: `true`

## Checks

| Check | Pass |
| --- | --- |
| `source_total_cards_100` | `true` |
| `candidate_total_cards_100` | `true` |
| `source_land_quantity_34` | `true` |
| `candidate_land_quantity_34` | `true` |
| `single_add_single_cut` | `true` |
| `expected_add_only` | `true` |
| `expected_cut_only` | `true` |
| `same_lane_land_swap` | `true` |
| `nonland_role_counts_unchanged` | `true` |
| `protected_anchors_unchanged` | `true` |
| `add_has_card_id` | `true` |
| `add_has_oracle_text` | `true` |
| `add_has_active_land_rule` | `true` |
| `candidate_hash_differs_from_source` | `true` |

## Deck Difference

- added: `[{"normalized_name": "plateau", "quantity_delta": 1}]`
- removed: `[{"normalized_name": "turbulent steppe", "quantity_delta": 1}]`

## Protected Anchors

- status: `pass`
- missing: `-`
- changed: `-`

## Added Card Runtime

- added_card_runtime: `{"active_rule_count": 1, "card_id": "2fe01212-cbd4-44a4-a5b2-cb0402c86db0", "card_name": "Plateau", "type_line": "Land \u2014 Mountain Plains"}`

## Decision

- current_best_baseline: `deck_607`
- candidate: `+Plateau / -Turbulent Steppe`
- promotion_allowed: `false`
- next_action: `run_diagnostic_smoke_battle`
