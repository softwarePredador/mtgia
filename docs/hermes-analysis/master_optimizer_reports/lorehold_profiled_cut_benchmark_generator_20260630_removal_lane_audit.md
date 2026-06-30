# Lorehold Profiled Cut Benchmark Generator - 2026-06-30

- Generated at: `2026-06-30T08:26:46Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260628_v2_cut_exposure_profiled.json`
- Cut-safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- Requested cut roles: `spot_removal`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `no_profiled_cut_benchmark_package_ready`
- Unfiltered profiled cuts: `4`
- Profiled cuts: `2`
- Supported cuts: `2`
- Filtered-out cuts: `2`
- Candidate pool: `270`
- Pair evaluations: `540`
- Preflight-ready pairs: `0`
- Selected packages: `0`
- Status counts: `{"blocked": 540}`

## Selected Packages

- none

## Blocked Cuts

- `Creative Technique`: filtered_out_by_requested_cut_role (role `big_spell_value`)
- `Bender's Waterskin`: filtered_out_by_requested_cut_role (role `ramp`)

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Chaos Warp | Stroke of Midnight | `blocked` | 117 | prior_exact_reject |
| Red Elemental Blast | Stroke of Midnight | `blocked` | 117 | candidate_narrow_color_hate |
| Lightning Bolt | Stroke of Midnight | `blocked` | 89 | candidate_scope_not_same_lane |
| Olórin's Searing Light | Stroke of Midnight | `blocked` | 89 | candidate_scope_not_same_lane |
| Untimely Malfunction | Stroke of Midnight | `blocked` | 89 | candidate_scope_not_same_lane |
| Vandalblast | Stroke of Midnight | `blocked` | 89 | candidate_scope_not_same_lane |
| Wear // Tear | Stroke of Midnight | `blocked` | 89 | candidate_scope_not_same_lane |
| Abrade | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Bolt Bend | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Crackle with Power | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Ephemerate | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Lightning Helix | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Razorgrass Ambush // Razorgrass Field | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Sundering Eruption // Volcanic Fissure | Stroke of Midnight | `blocked` | 81 | candidate_scope_not_same_lane |
| Terror of the Peaks | Stroke of Midnight | `blocked` | 76 | candidate_scope_not_same_lane |
| Witch Enchanter // Witch-Blessed Meadow | Stroke of Midnight | `blocked` | 76 | candidate_scope_not_same_lane |
| Restoration Seminar | Stroke of Midnight | `blocked` | 74 | candidate_role_mismatch:unknown |
| Erode | Stroke of Midnight | `blocked` | 73 | candidate_scope_not_same_lane |
| Twinflame Tyrant | Stroke of Midnight | `blocked` | 69 | candidate_role_mismatch:unknown |
| Explosive Singularity | Stroke of Midnight | `blocked` | 63 | candidate_scope_not_same_lane, candidate_much_higher_cmc |
