# Lorehold Pressure Tradeoff Decision Synthesis

- generated_at: `2026-07-04T22:25:14Z`
- status: `pressure_tradeoff_diagnostic_only_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- promotion_allowed: `false`

## Structure

- ranked deck keys: `["candidate_607_pressure_payoff_diagnostic_tradeoff_v1", "deck_607"]`
- baseline score: `139.038`
- candidate score: `140.901`
- score delta: `1.863`

## Natural Smoke Gate

- baseline record: `{"avg_win_turn": 18.67, "losses": 1, "stalls": 0, "win_rate": 75.0, "wins": 3}`
- candidate record: `{"avg_win_turn": 15.67, "losses": 1, "stalls": 0, "win_rate": 75.0, "wins": 3}`
- miracle regressed: `true`
- topdeck regressed: `true`

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| `miracle_cast` | 20 | 5 | -15 |
| `topdeck_manipulation_activated` | 19 | 4 | -15 |
| `discard_to_top_replacement` | 11 | 3 | -8 |
| `lorehold_spell_cast` | 58 | 50 | -8 |
| `lorehold_upkeep_rummage` | 19 | 16 | -3 |
| `static_cost_reduction_total` | 22 | 28 | 6 |

## Card Evidence

| Card | Decision | Natural events | Accessed games |
| --- | --- | ---: | ---: |
| Monastery Mentor | `hypothesis_natural_access_only_needs_smaller_package_or_safe_cut` | 0 | 0 |
| Young Pyromancer | `hypothesis_natural_trigger_signal_but_full_package_regressed_miracle` | 10 | 1 |
| Guttersnipe | `hypothesis_natural_trigger_signal_but_full_package_regressed_miracle` | 9 | 2 |
| Storm-Kiln Artist | `hypothesis_natural_cast_or_cost_signal_but_full_package_regressed_miracle` | 2 | 2 |

## Forced Probes

- `Monastery Mentor`: focus `{"accessed_games": 3, "dominant_zone": "graveyard", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 200, "trace_games": 3, "zone_counts": {"graveyard": 118, "hand": 82}}`, events `{"cost_paid:Monastery Mentor": 3, "spell_cast:Monastery Mentor": 3, "spell_resolved:Monastery Mentor": 3}`, effect_count `3`, treasure_like_count `0`.
- `Storm-Kiln Artist`: focus `{"accessed_games": 3, "dominant_zone": "hand", "drawn_games": 0, "library_only_games": 0, "near_access_games": 0, "opening_hand_games": 3, "trace_count": 196, "trace_games": 3, "zone_counts": {"absent": 2, "battlefield": 31, "graveyard": 21, "hand": 142}}`, events `{"cost_paid:Storm-Kiln Artist": 3}`, effect_count `7`, treasure_like_count `0`.

## Decision

- No seed-safe cut plan exists for the full four-card package.
- The generated candidate is diagnostic-only and explicitly promotion-ineligible.
- The structure matrix ranks the candidate higher, but structure-only improvement is not promotion proof.
- The smoke gate tied baseline wins, but smoke scope is not a confirmed equal-seed promotion gate.
- The candidate regressed Lorehold's miracle/topdeck execution, which is the protected 607 plan.
- next_actions:
  - do_not_promote_or_apply_the_four_card_pressure_tradeoff
  - do_not_rerun_the_full_package_until_a_seed_safe_cut_model_changes
  - use the natural Guttersnipe/Young Pyromancer signal only as a smaller-package hypothesis
  - treat Monastery Mentor and Storm-Kiln Artist forced probes as card-understanding evidence, not natural promotion proof
  - preserve 607 miracle/topdeck cadence as a hard gate for future pressure packages
