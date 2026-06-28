# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T01:07:14.470033+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| plateau_timing_upgrade_cut_turbulent_steppe | mana_base | Plateau | Turbulent Steppe | `clear` | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -55, spell -48, spell mana +0, birgi mana +0, ritual -3, miracle -12, tutor +1, random discard +2, topdeck -20, discard-to-top -16, rummage-to-top -13, spell-rummage-to-top -3, hand to top +0, spell rummage -17, squee gy -4, squee return -2, squee explained -2 | reject_or_rework |

## Package Notes

### plateau_timing_upgrade_cut_turbulent_steppe

- family: mana_base
- hypothesis: After Plateau over Radiant Summit failed the real gate, the mana-base validator still marks Plateau over Turbulent Steppe as a separate strict timing upgrade: it preserves red and white sources, keeps land count unchanged, and removes a late-game-only conditional tapped dual without cutting fetches or utility lands.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Plateau": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real_plateau_timing_upgrade_cut_turbulent_steppe/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real_plateau_timing_upgrade_cut_turbulent_steppe.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real_plateau_timing_upgrade_cut_turbulent_steppe.json`
- gate_returncode: `0`
