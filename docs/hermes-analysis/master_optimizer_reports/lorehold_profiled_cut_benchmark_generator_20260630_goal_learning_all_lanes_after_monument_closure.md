# Lorehold Profiled Cut Benchmark Generator - 2026-06-30

- Generated at: `2026-06-30T21:37:06Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Manual review: `docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260630_goal_learning_deck607_exposure_current.json`
- Cut-safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- Requested cut roles: `all`
- Requested cut cards: `all`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_profiled_cut_benchmark_preflight`
- Unfiltered profiled cuts: `4`
- Profiled cuts: `4`
- Supported cuts: `4`
- Filtered-out cuts: `0`
- Candidate pool: `270`
- Pair evaluations: `1080`
- Preflight-ready pairs: `1`
- Selected packages: `1`
- Status counts: `{"blocked": 1079, "preflight_ready": 1}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| possibility_storm_same_lane_benchmark_cut_creative_technique | Possibility Storm | Creative Technique | 96 | `big_spell_value` | `big_spell_value` |

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Possibility Storm | Creative Technique | `preflight_ready` | 96 | - |
| Seething Song | Bender's Waterskin | `blocked` | 117 | prior_exact_reject |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Mana Vault | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |
| Basalt Monolith | Bender's Waterskin | `blocked` | 104 | prior_exact_reject |
| Desperate Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Pyretic Ritual | Bender's Waterskin | `blocked` | 101 | prior_exact_reject |
| Chrome Mox | Bender's Waterskin | `blocked` | 96 | candidate_policy_blocked_no_premium_mox |
| Cloud Key | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Electro, Assaulting Battery | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Locket of Yesterdays | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Lotus Petal | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Millikin | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Monologue Tax | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Primal Amulet // Primal Wellspring | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Tablet of Discovery | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| The Warring Triad | Bender's Waterskin | `blocked` | 96 | prior_exact_reject |
| Helm of Awakening | Bender's Waterskin | `blocked` | 92 | candidate_scope_not_same_lane |
| Lion's Eye Diamond | Bender's Waterskin | `blocked` | 88 | prior_exact_reject, candidate_unmodeled_discard_hand_cost |
| Mox Opal | Bender's Waterskin | `blocked` | 88 | candidate_policy_blocked_no_premium_mox |
