# Lorehold Mana-Base Pair Decision

- generated_at: `2026-07-05T00:52:37Z`
- status: `reject_promotion_keep_607_current_baseline`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate: `+Plateau / -Turbulent Steppe`
- preflight_ready: `true`
- promotion_allowed: `false`
- full_confirmation_allowed_now: `false`
- keep_607_as_protected_baseline: `true`
- blockers: `["forced_opening_hand_diagnostic_lost_to_607"]`

## Gate Results

| Gate | Forced Access | Baseline 607 | Candidate | Candidate Pass |
| --- | --- | ---: | ---: | --- |
| natural_smoke | `none` | `0W/1L/0S` | `0W/1L/0S` | `true` |
| forced_opening_hand | `opening_hand` | `2W/1L/0S` | `1W/2L/0S` | `false` |

## Focus Access

- natural baseline Turbulent Steppe: `{"accessed_games": 1, "dominant_zone": "library", "drawn_games": 0, "library_only_games": 0, "near_access_games": 1, "opening_hand_games": 0, "trace_count": 51, "trace_games": 1, "zone_counts": {"hand": 2, "library": 49}}`
- natural candidate Plateau: `{"accessed_games": 1, "dominant_zone": "library", "drawn_games": 0, "library_only_games": 0, "near_access_games": 1, "opening_hand_games": 0, "trace_count": 71, "trace_games": 1, "zone_counts": {"graveyard": 5, "hand": 1, "library": 65}}`
- forced baseline Turbulent Steppe: `{"accessed_games": 3, "dominant_zone": "battlefield", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 176, "trace_games": 3, "zone_counts": {"battlefield": 124, "hand": 52}}`
- forced candidate Plateau: `{"accessed_games": 3, "dominant_zone": "battlefield", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 204, "trace_games": 3, "zone_counts": {"absent": 2, "battlefield": 153, "hand": 49}}`

## Decision

- current_best_baseline: `deck_607`
- candidate: `+Plateau / -Turbulent Steppe`
- promotion_allowed: `false`
- reason: The candidate passed structural/preflight checks, but cannot be promoted unless it ties or beats protected 607 in natural and focused access diagnostics with actual added-card access.
- next_action: `block_exact_pair_and_keep_607_until_new_material_evidence`
