# Lorehold Profiled Cut Benchmark Generator - 2026-06-28

- Generated at: `2026-06-28T09:10:10Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
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
- Preflight-ready pairs: `14`
- Selected packages: `4`
- Status counts: `{"blocked": 1066, "preflight_ready": 14}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| pyretic_ritual_same_lane_benchmark_cut_bender_s_waterskin | Pyretic Ritual | Bender's Waterskin | 101 | `ramp` | `ramp` |
| locket_of_yesterdays_same_lane_benchmark_cut_bender_s_waterskin | Locket of Yesterdays | Bender's Waterskin | 96 | `ramp` | `ramp` |
| razorgrass_ambush_razorgrass_field_same_lane_benchmark_cut_winds_of_abandon | Razorgrass Ambush // Razorgrass Field | Winds of Abandon | 101 | `spot_removal` | `spot_removal` |
| witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon | Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | 96 | `spot_removal` | `spot_removal` |

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Pyretic Ritual | Bender's Waterskin | `preflight_ready` | 101 | - |
| Locket of Yesterdays | Bender's Waterskin | `preflight_ready` | 96 | - |
| Lotus Petal | Bender's Waterskin | `preflight_ready` | 96 | - |
| Millikin | Bender's Waterskin | `preflight_ready` | 96 | - |
| Monologue Tax | Bender's Waterskin | `preflight_ready` | 96 | - |
| Primal Amulet // Primal Wellspring | Bender's Waterskin | `preflight_ready` | 96 | - |
| Tablet of Discovery | Bender's Waterskin | `preflight_ready` | 96 | - |
| Lion's Eye Diamond | Bender's Waterskin | `preflight_ready` | 88 | - |
| Surly Badgersaur | Bender's Waterskin | `preflight_ready` | 88 | - |
| Treasonous Ogre | Bender's Waterskin | `preflight_ready` | 88 | - |
| Razorgrass Ambush // Razorgrass Field | Winds of Abandon | `preflight_ready` | 101 | - |
| Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | `preflight_ready` | 96 | - |
| Erode | Winds of Abandon | `preflight_ready` | 93 | - |
| Electro, Assaulting Battery | Winds of Abandon | `preflight_ready` | 88 | - |
| Seething Song | Bender's Waterskin | `blocked` | 117 | prior_exact_reject |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Mana Vault | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Basalt Monolith | Bender's Waterskin | `blocked` | 104 | prior_exact_reject |
| Desperate Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Chrome Mox | Bender's Waterskin | `blocked` | 96 | candidate_policy_blocked_no_premium_mox |
