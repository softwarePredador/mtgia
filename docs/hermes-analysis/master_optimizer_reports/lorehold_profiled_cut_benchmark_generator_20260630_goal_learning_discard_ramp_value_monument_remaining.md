# Lorehold Profiled Cut Benchmark Generator - 2026-06-30

- Generated at: `2026-06-30T21:30:02Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Manual review: `docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260630_goal_learning_deck607_exposure_current.json`
- Cut-safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- Requested cut roles: `discard_ramp_value`
- Requested cut cards: `Monument to Endurance`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_profiled_cut_benchmark_preflight`
- Unfiltered profiled cuts: `1`
- Profiled cuts: `1`
- Supported cuts: `1`
- Filtered-out cuts: `0`
- Candidate pool: `270`
- Pair evaluations: `270`
- Preflight-ready pairs: `3`
- Selected packages: `3`
- Status counts: `{"blocked": 267, "preflight_ready": 3}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance | Glint-Horn Buccaneer | Monument to Endurance | 96 | `discard_ramp_value` | `discard_ramp_value` |
| magmakin_artillerist_same_lane_benchmark_cut_monument_to_endurance | Magmakin Artillerist | Monument to Endurance | 96 | `discard_ramp_value` | `discard_ramp_value` |
| surly_badgersaur_same_lane_benchmark_cut_monument_to_endurance | Surly Badgersaur | Monument to Endurance | 88 | `discard_ramp_value` | `discard_ramp_value` |

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Glint-Horn Buccaneer | Monument to Endurance | `preflight_ready` | 96 | - |
| Magmakin Artillerist | Monument to Endurance | `preflight_ready` | 96 | - |
| Surly Badgersaur | Monument to Endurance | `preflight_ready` | 88 | - |
| Cool but Rude | Monument to Endurance | `blocked` | 104 | prior_exact_reject |
| Currency Converter | Monument to Endurance | `blocked` | 96 | prior_exact_reject |
| Boros Charm | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Chaos Warp | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:spot_removal, candidate_scope_not_same_lane |
| Deflecting Palm | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Enlightened Tutor | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Gamble | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Red Elemental Blast | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:spot_removal, candidate_scope_not_same_lane |
| Reprieve | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Seething Song | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:ramp, candidate_scope_not_same_lane |
| Silence | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Twinflame | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Valakut Awakening // Valakut Stoneforge | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Wheel of Fortune | Monument to Endurance | `blocked` | 62 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Monument to Endurance | `blocked` | 57 | candidate_role_mismatch:ramp, candidate_scope_not_same_lane |
| Dragon's Rage Channeler | Monument to Endurance | `blocked` | 57 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
| Dualcaster Mage | Monument to Endurance | `blocked` | 57 | candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
