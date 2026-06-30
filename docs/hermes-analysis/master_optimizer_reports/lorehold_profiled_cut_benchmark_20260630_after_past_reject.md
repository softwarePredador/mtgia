# Lorehold Profiled Cut Benchmark Generator - 2026-06-30

- Generated at: `2026-06-30T04:27:32Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260628_v2_cut_exposure_profiled.json`
- Cut-safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_profiled_cut_benchmark_preflight`
- Profiled cuts: `4`
- Supported cuts: `4`
- Candidate pool: `270`
- Pair evaluations: `1080`
- Preflight-ready pairs: `3`
- Selected packages: `3`
- Status counts: `{"blocked": 1077, "preflight_ready": 3}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| the_warring_triad_same_lane_benchmark_cut_bender_s_waterskin | The Warring Triad | Bender's Waterskin | 96 | `ramp` | `ramp` |
| planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique | Planetarium of Wan Shi Tong | Creative Technique | 96 | `big_spell_value` | `big_spell_value` |
| ephemerate_same_lane_benchmark_cut_winds_of_abandon | Ephemerate | Winds of Abandon | 101 | `spot_removal` | `spot_removal` |

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| The Warring Triad | Bender's Waterskin | `preflight_ready` | 96 | - |
| Planetarium of Wan Shi Tong | Creative Technique | `preflight_ready` | 96 | - |
| Ephemerate | Winds of Abandon | `preflight_ready` | 101 | - |
| Seething Song | Bender's Waterskin | `blocked` | 117 | prior_exact_reject |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Mana Vault | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Basalt Monolith | Bender's Waterskin | `blocked` | 104 | prior_exact_reject |
| Desperate Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Pyretic Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Chrome Mox | Bender's Waterskin | `blocked` | 96 | candidate_policy_blocked_no_premium_mox |
| Electro, Assaulting Battery | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Locket of Yesterdays | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Lotus Petal | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Millikin | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Monologue Tax | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Primal Amulet // Primal Wellspring | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Tablet of Discovery | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Helm of Awakening | Bender's Waterskin | `blocked` | 92 | candidate_scope_not_same_lane |
| Lion's Eye Diamond | Bender's Waterskin | `blocked` | 88 | prior_exact_reject, candidate_unmodeled_discard_hand_cost |
| Mox Opal | Bender's Waterskin | `blocked` | 88 | candidate_policy_blocked_no_premium_mox |
