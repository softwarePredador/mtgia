# Lorehold Plateau/Radiant Mana-Base Decision

- generated_at: `2026-07-05T00:35:04Z`
- status: `reject_promotion_keep_607_current_baseline`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate: `+Plateau / -Radiant Summit`
- preflight_ready: `true`
- promotion_allowed: `false`
- full_confirmation_allowed_now: `false`
- keep_607_as_protected_baseline: `true`
- blockers: `["forced_opening_hand_diagnostic_lost_to_607", "natural_smoke_did_not_access_plateau", "natural_smoke_lost_to_607"]`

## Gate Results

| Gate | Forced Access | Baseline 607 | Candidate | Candidate Pass |
| --- | --- | ---: | ---: | --- |
| natural_smoke | `none` | `2W/1L/0S` | `1W/2L/0S` | `false` |
| forced_opening_hand | `opening_hand` | `2W/1L/0S` | `1W/2L/0S` | `false` |

## Focus Access

- natural baseline Radiant Summit: `{"accessed_games": 1, "dominant_zone": "library", "drawn_games": 0, "library_only_games": 1, "near_access_games": 1, "opening_hand_games": 1, "trace_count": 152, "trace_games": 3, "zone_counts": {"battlefield": 32, "hand": 14, "library": 106}}`
- natural candidate Plateau: `{"accessed_games": 0, "dominant_zone": "library", "drawn_games": 0, "library_only_games": 2, "near_access_games": 1, "opening_hand_games": 0, "trace_count": 134, "trace_games": 3, "zone_counts": {"library": 134}}`
- forced baseline Radiant Summit: `{"accessed_games": 3, "dominant_zone": "battlefield", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 147, "trace_games": 3, "zone_counts": {"battlefield": 105, "hand": 42}}`
- forced candidate Plateau: `{"accessed_games": 3, "dominant_zone": "battlefield", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 169, "trace_games": 3, "zone_counts": {"battlefield": 127, "hand": 42}}`

## Decision

- current_best_baseline: `deck_607`
- candidate: `+Plateau / -Radiant Summit`
- promotion_allowed: `false`
- reason: The candidate passed structural/preflight checks, but lost both the natural smoke and the opening-hand forced diagnostic against protected 607. Natural smoke did not access Plateau, so this is not card-level proof that Plateau is bad; it is enough to keep promotion and larger confirmation closed for this exact isolated swap.
- next_action: `keep_607_and_move_to_next_learning_hypothesis_or_revisit_only_with_new_mana_trace_evidence`
