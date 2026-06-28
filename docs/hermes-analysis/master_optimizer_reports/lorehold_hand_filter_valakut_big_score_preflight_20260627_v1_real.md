# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T00:14:16.693887+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json`
- package_status_counts: `{"preflight_ready": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| valakut_hand_filter_cut_big_score | hand_filter_benchmark | Valakut Awakening // Valakut Stoneforge | Big Score | `clear` | - | - | +0.00 | - | preflight_ready |

## Package Notes

### valakut_hand_filter_cut_big_score

- family: hand_filter_benchmark
- hypothesis: The hand-filter cut model ranked Valakut Awakening over Big Score as the first benchmark: Valakut has measured hand-filter exposure and a verified MDFC rule, while Big Score is the least-exposed visible protected cut but still provides discard, draw, and Treasure. This is an explicit hand-filter-over-ramp tradeoff, not a free cut.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
