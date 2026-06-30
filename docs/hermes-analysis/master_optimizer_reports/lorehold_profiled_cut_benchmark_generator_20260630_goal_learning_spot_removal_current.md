# Lorehold Profiled Cut Benchmark Generator - 2026-06-30

- Generated at: `2026-06-30T21:24:01Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Manual review: `docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260630_goal_learning_deck607_exposure_current.json`
- Cut-safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- Requested cut roles: `spot_removal`
- Requested cut cards: `all`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_profiled_cut_benchmark_preflight`
- Unfiltered profiled cuts: `4`
- Profiled cuts: `1`
- Supported cuts: `1`
- Filtered-out cuts: `3`
- Candidate pool: `270`
- Pair evaluations: `270`
- Preflight-ready pairs: `1`
- Selected packages: `1`
- Status counts: `{"blocked": 269, "preflight_ready": 1}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| chaos_warp_same_lane_benchmark_cut_generous_gift | Chaos Warp | Generous Gift | 117 | `spot_removal` | `spot_removal` |

## Blocked Cuts

- `Creative Technique`: filtered_out_by_requested_cut_role (role `big_spell_value`)
- `Bender's Waterskin`: filtered_out_by_requested_cut_role (role `ramp`)
- `Monument to Endurance`: filtered_out_by_requested_cut_role (role `discard_ramp_value`)

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Chaos Warp | Generous Gift | `preflight_ready` | 117 | - |
| Red Elemental Blast | Generous Gift | `blocked` | 117 | candidate_narrow_color_hate |
| Lightning Bolt | Generous Gift | `blocked` | 89 | candidate_scope_not_same_lane |
| Olórin's Searing Light | Generous Gift | `blocked` | 89 | candidate_scope_not_same_lane |
| Untimely Malfunction | Generous Gift | `blocked` | 89 | candidate_scope_not_same_lane |
| Vandalblast | Generous Gift | `blocked` | 89 | candidate_scope_not_same_lane |
| Wear // Tear | Generous Gift | `blocked` | 89 | candidate_scope_not_same_lane |
| Abrade | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Bolt Bend | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Crackle with Power | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Ephemerate | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Lightning Helix | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Razorgrass Ambush // Razorgrass Field | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Sundering Eruption // Volcanic Fissure | Generous Gift | `blocked` | 81 | candidate_scope_not_same_lane |
| Terror of the Peaks | Generous Gift | `blocked` | 76 | candidate_scope_not_same_lane |
| Witch Enchanter // Witch-Blessed Meadow | Generous Gift | `blocked` | 76 | candidate_scope_not_same_lane |
| Restoration Seminar | Generous Gift | `blocked` | 74 | candidate_role_mismatch:unknown |
| Erode | Generous Gift | `blocked` | 73 | candidate_scope_not_same_lane |
| Twinflame Tyrant | Generous Gift | `blocked` | 69 | candidate_role_mismatch:unknown |
| Explosive Singularity | Generous Gift | `blocked` | 63 | candidate_scope_not_same_lane, candidate_much_higher_cmc |
