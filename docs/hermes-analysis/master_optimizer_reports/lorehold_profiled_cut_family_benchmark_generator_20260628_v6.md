# Lorehold Profiled Cut Benchmark Generator - 2026-06-28

- Generated at: `2026-06-28T09:29:39Z`
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
- Preflight-ready pairs: `4`
- Selected packages: `4`
- Status counts: `{"blocked": 1076, "preflight_ready": 4}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| tablet_of_discovery_same_lane_benchmark_cut_bender_s_waterskin | Tablet of Discovery | Bender's Waterskin | 96 | `ramp` | `ramp` |
| lion_s_eye_diamond_same_lane_benchmark_cut_bender_s_waterskin | Lion's Eye Diamond | Bender's Waterskin | 88 | `ramp` | `ramp` |
| surly_badgersaur_same_lane_benchmark_cut_bender_s_waterskin | Surly Badgersaur | Bender's Waterskin | 88 | `ramp` | `ramp` |
| treasonous_ogre_same_lane_benchmark_cut_bender_s_waterskin | Treasonous Ogre | Bender's Waterskin | 88 | `ramp` | `ramp` |

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Tablet of Discovery | Bender's Waterskin | `preflight_ready` | 96 | - |
| Lion's Eye Diamond | Bender's Waterskin | `preflight_ready` | 88 | - |
| Surly Badgersaur | Bender's Waterskin | `preflight_ready` | 88 | - |
| Treasonous Ogre | Bender's Waterskin | `preflight_ready` | 88 | - |
| Seething Song | Bender's Waterskin | `blocked` | 117 | prior_exact_reject |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Mana Vault | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Basalt Monolith | Bender's Waterskin | `blocked` | 104 | prior_exact_reject |
| Desperate Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Pyretic Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Chrome Mox | Bender's Waterskin | `blocked` | 96 | candidate_policy_blocked_no_premium_mox |
| Locket of Yesterdays | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Lotus Petal | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Millikin | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Monologue Tax | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Primal Amulet // Primal Wellspring | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Helm of Awakening | Bender's Waterskin | `blocked` | 92 | candidate_scope_not_same_lane |
| Mox Opal | Bender's Waterskin | `blocked` | 88 | candidate_policy_blocked_no_premium_mox |
| Goldspan Dragon | Bender's Waterskin | `blocked` | 84 | candidate_scope_not_same_lane |
| Mana Geyser | Bender's Waterskin | `blocked` | 81 | candidate_scope_not_same_lane |
