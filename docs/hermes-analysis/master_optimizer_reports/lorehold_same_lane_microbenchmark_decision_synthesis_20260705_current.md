# Lorehold Same-Lane Microbenchmark Decision Synthesis

- generated_at: `2026-07-05T01:20:50Z`
- status: `same_lane_static_ready_prior_natural_rejected_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- static_preflight_ready_pair_count: `1`
- prior_natural_reject_count: `2`
- forced_access_signal_count: `1`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`

## Candidate Decisions

| Package | Candidate | Cut | Decision | Next Action |
| --- | --- | --- | --- | --- |
| possibility_storm_same_lane_benchmark_cut_creative_technique | Possibility Storm | Creative Technique | `static_ready_but_prior_natural_rejected` | `do_not_rerun_natural_gate_without_new_material_evidence` |

## Prior Gate Evidence

| Gate | Mode | Baseline | Candidate | Delta pp | Decision |
| --- | --- | ---: | ---: | ---: | --- |
| lorehold_big_spell_value_creative_technique_gate_20260630_goal_learning_smoke_20260630_213730_possibility_storm_same_lane_benchmark_cut_creative_technique.json | `none` | 11/24 | 3/24 | -33.33 | `prior_natural_reject` |
| lorehold_607_unprotected_staple_relearn_gate_20260704_possibility_storm_smoke_possibility_storm_same_lane_benchmark_cut_creative_technique.json | `none` | 2/4 | 1/4 | -25.0 | `prior_natural_reject` |
| lorehold_607_unprotected_staple_relearn_gate_20260704_possibility_storm_forced_opening_possibility_storm_same_lane_benchmark_cut_creative_technique.json | `opening_hand` | 0/4 | 2/4 | 50.0 | `forced_access_signal_only` |

## Bender's Waterskin Queue

| Candidate | Score | Blockers |
| --- | ---: | --- |
| Seething Song | 117 | prior_exact_reject |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 112 | prior_exact_reject |
| Mana Vault | 112 | prior_exact_reject |
| Basalt Monolith | 104 | prior_exact_reject |
| Desperate Ritual | 101 | prior_exact_reject |
| Pyretic Ritual | 101 | prior_exact_reject |
| Chrome Mox | 96 | candidate_policy_blocked_no_premium_mox |
| Cloud Key | 96 | prior_exact_reject |
| Electro, Assaulting Battery | 96 | prior_exact_reject |
| Locket of Yesterdays | 96 | prior_exact_reject |
| Lotus Petal | 96 | prior_exact_reject |
| Millikin | 96 | prior_exact_reject |

## Decision

- keep_607_as_protected_baseline: `true`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The current static same-lane scan finds Possibility Storm over Creative Technique, but prior natural gates already lost to protected 607. Forced-access improvement is diagnostic only and cannot override natural evidence.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_promote_possibility_storm_over_creative_technique
  - do_not_retest_bender_waterskin_fast_mana_pairs already blocked by prior_exact_reject
  - only reopen this lane with new material evidence, a changed runtime adapter, or a new same-lane candidate not in the exhausted queue
