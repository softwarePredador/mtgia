# Lorehold Profiled Cut Benchmark Generator - 2026-06-28

- Generated at: `2026-06-28T08:36:05Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Manual review: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_manual_cut_review_20260628_v2_cut_exposure_profiled.json`
- Variant deck IDs: `608, 609, 610, 611, 612, 613, 614, 615, 616`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_profiled_cut_benchmark_preflight`
- Profiled cuts: `4`
- Supported cuts: `2`
- Candidate pool: `270`
- Pair evaluations: `1080`
- Preflight-ready pairs: `9`
- Selected packages: `3`
- Status counts: `{"blocked": 1071, "preflight_ready": 9}`

## Selected Packages

| Package | Add | Cut | Score | Candidate Role | Cut Role |
| --- | --- | --- | ---: | --- | --- |
| chaos_warp_interaction_benchmark_cut_stroke_of_midnight | Chaos Warp | Stroke of Midnight | 117 | `spot_removal` | `spot_removal` |
| lightning_bolt_interaction_benchmark_cut_winds_of_abandon | Lightning Bolt | Winds of Abandon | 109 | `spot_removal` | `spot_removal` |
| ol_rin_s_searing_light_interaction_benchmark_cut_winds_of_abandon | Olórin's Searing Light | Winds of Abandon | 109 | `spot_removal` | `spot_removal` |

## Blocked Cuts

- `Creative Technique`: no supported generator for this cut role yet (role `unmeasured`)
- `Bender's Waterskin`: no supported generator for this cut role yet (role `unmeasured`)

## Top Pair Evaluations

| Candidate | Cut | Status | Score | Blockers |
| --- | --- | --- | ---: | --- |
| Chaos Warp | Stroke of Midnight | `preflight_ready` | 117 | - |
| Lightning Bolt | Winds of Abandon | `preflight_ready` | 109 | - |
| Olórin's Searing Light | Winds of Abandon | `preflight_ready` | 109 | - |
| Crackle with Power | Winds of Abandon | `preflight_ready` | 101 | - |
| Lightning Helix | Winds of Abandon | `preflight_ready` | 101 | - |
| Razorgrass Ambush // Razorgrass Field | Winds of Abandon | `preflight_ready` | 101 | - |
| Witch Enchanter // Witch-Blessed Meadow | Winds of Abandon | `preflight_ready` | 96 | - |
| Erode | Winds of Abandon | `preflight_ready` | 93 | - |
| Electro, Assaulting Battery | Winds of Abandon | `preflight_ready` | 88 | - |
| Enlightened Tutor | Bender's Waterskin | `blocked` | 82 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Goblin Engineer | Bender's Waterskin | `blocked` | 77 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Mana Vault | Bender's Waterskin | `blocked` | 77 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Untimely Malfunction | Bender's Waterskin | `blocked` | 74 | unsupported_cut_role:unmeasured, candidate_role_mismatch:spot_removal |
| Vandalblast | Bender's Waterskin | `blocked` | 74 | unsupported_cut_role:unmeasured, candidate_role_mismatch:spot_removal |
| Wear // Tear | Bender's Waterskin | `blocked` | 74 | unsupported_cut_role:unmeasured, candidate_role_mismatch:spot_removal |
| Storm-Kiln Artist | Bender's Waterskin | `blocked` | 69 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Abrade | Bender's Waterskin | `blocked` | 66 | unsupported_cut_role:unmeasured, candidate_role_mismatch:spot_removal |
| Molten Duplication | Bender's Waterskin | `blocked` | 66 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Ultima | Bender's Waterskin | `blocked` | 66 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown |
| Boros Charm | Bender's Waterskin | `blocked` | 62 | unsupported_cut_role:unmeasured, candidate_role_mismatch:unknown, candidate_scope_not_same_lane |
