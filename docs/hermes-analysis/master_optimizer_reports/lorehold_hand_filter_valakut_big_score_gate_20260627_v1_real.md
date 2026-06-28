# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T00:14:33.206970+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| valakut_hand_filter_cut_big_score | hand_filter_benchmark | Valakut Awakening // Valakut Stoneforge | Big Score | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -40, spell -35, spell mana +0, birgi mana +0, ritual -1, miracle -13, tutor -3, random discard -1, topdeck -10, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### valakut_hand_filter_cut_big_score

- family: hand_filter_benchmark
- hypothesis: The hand-filter cut model ranked Valakut Awakening over Big Score as the first benchmark: Valakut has measured hand-filter exposure and a verified MDFC rule, while Big Score is the least-exposed visible protected cut but still provides discard, draw, and Treasure. This is an explicit hand-filter-over-ramp tradeoff, not a free cut.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Big Score`
- added_rule_counts: `{"Valakut Awakening // Valakut Stoneforge": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real_valakut_hand_filter_cut_big_score/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real_valakut_hand_filter_cut_big_score.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real_valakut_hand_filter_cut_big_score.json`
- gate_returncode: `0`
