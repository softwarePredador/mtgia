# Lorehold Mana Base Candidate Materializer

- generated_at: `2026-07-05T00:24:19Z`
- status: `candidate_materialized_structure_ready_battle_gate_closed`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- deck_id: `607`
- candidate: `+Plateau / -Radiant Summit`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_candidate_materializer_20260705_plateau_radiant_current_candidate/knowledge_candidate.db`
- source_unchanged: `true`
- source_candidate_hash_differs: `true`
- promotion_allowed: `false`
- allow_battle_gate_now: `false`
- allow_next_preflight: `true`

## Structure Validation

- status: `pass`
- deck_summary: `{"avg_cmc": 3.576, "cards": 100, "deck_id": 607, "hash": "5f592c700c3f78b76f84e3a3ba475b353e7b5f2c7feb223419fe6ae048314709", "lands": 34, "nonlands": 66, "ruleset_hash": "3e20c3ecd3828653d6c7b6aac9f9ce8e09a1f0d6736c2d0d93c292873d71ba5e", "semantics_hash": "cbd37a6ce23bdcb22ef291b174c2b27e9d1872f7095d3aed4134f2dadf562648"}`

| Check | Pass |
| --- | --- |
| `total_cards_100` | `true` |
| `land_quantity_34` | `true` |
| `commander_count_1` | `true` |
| `add_present_once` | `true` |
| `cut_absent` | `true` |
| `nonbasic_singleton_ok` | `true` |
| `unresolved_card_rows_0` | `true` |

## Mana Base Delta

- source_before: `{"always_tapped_rows": 2, "colorless_only_rows": 6, "conditional_tapped_rows": 2, "direct_rw_rows": 11, "fetch_or_search_rows": 8, "land_quantity": 34, "protected_utility_rows": 9, "red_access_rows": 20, "topdeck_or_card_flow_land_rows": 5, "typed_mountain_plains_rows": 5, "white_access_rows": 21}`
- candidate: `{"always_tapped_rows": 2, "colorless_only_rows": 6, "conditional_tapped_rows": 1, "direct_rw_rows": 11, "fetch_or_search_rows": 8, "land_quantity": 34, "protected_utility_rows": 9, "red_access_rows": 20, "topdeck_or_card_flow_land_rows": 5, "typed_mountain_plains_rows": 5, "white_access_rows": 21}`
- delta_candidate_minus_source: `{"always_tapped_rows": 0, "colorless_only_rows": 0, "conditional_tapped_rows": -1, "direct_rw_rows": 0, "fetch_or_search_rows": 0, "land_quantity": 0, "protected_utility_rows": 0, "red_access_rows": 0, "topdeck_or_card_flow_land_rows": 0, "typed_mountain_plains_rows": 0, "white_access_rows": 0}`

## Decision

- current_best_baseline: `deck_607`
- candidate: `+Plateau / -Radiant Summit`
- promotion_allowed: `false`
- reason: The candidate preserves 100 cards, 34 lands, one commander, and source DB immutability, but has not passed battle or replay evidence.
- next_action: `run miracle-access preflight and an equal battle gate using the candidate DB while keeping deck 607 as fixed protected baseline`

## Policy

- baseline: Deck 607 remains the protected baseline.
- candidate_scope: The swap exists only inside the copied Hermes SQLite candidate DB.
- promotion_gate: Promotion stays closed until miracle-access preflight, equal battle gate, replay trace, and same-lane decision review pass.
