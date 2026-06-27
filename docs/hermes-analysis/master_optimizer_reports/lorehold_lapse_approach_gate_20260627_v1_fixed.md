# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:41:46.770918+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| lapse_approach_topdeck_cut_tibalts_trickery | approach_topdeck_combo | Lapse of Certainty | Tibalt's Trickery | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -22, spell -18, spell mana +0, birgi mana +0, ritual -1, miracle -7, tutor -6, random discard -1, topdeck -6, discard-to-top +7, rummage-to-top +7, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### lapse_approach_topdeck_cut_tibalts_trickery

- family: approach_topdeck_combo
- hypothesis: Lapse of Certainty is an external Lorehold/Approach line: counter the first Approach of the Second Sun and put it on top, then use Lorehold's first-draw miracle window for the second cast. Tibalt's Trickery is the comparison slot because it is the existing swingy counter/protection card.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Lapse of Certainty": 3}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed_lapse_approach_topdeck_cut_tibalts_trickery/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed_lapse_approach_topdeck_cut_tibalts_trickery.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed_lapse_approach_topdeck_cut_tibalts_trickery.json`
- gate_returncode: `0`
