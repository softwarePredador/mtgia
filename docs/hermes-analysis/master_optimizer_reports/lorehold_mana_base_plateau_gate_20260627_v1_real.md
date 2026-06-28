# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T01:02:46.916321+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| plateau_timing_upgrade_cut_radiant_summit | mana_base | Plateau | Radiant Summit | `clear` | 8/1/0 `88.89%` | 2/7/0 `22.22%` | -66.67 | cost -57, spell -51, spell mana +0, birgi mana +0, ritual -2, miracle -19, tutor -5, random discard +2, topdeck -28, discard-to-top -13, rummage-to-top -10, spell-rummage-to-top -3, hand to top +0, spell rummage -19, squee gy -2, squee return -2, squee explained -2 | reject_or_rework |

## Package Notes

### plateau_timing_upgrade_cut_radiant_summit

- family: mana_base
- hypothesis: The deterministic mana-base validator marks Plateau over Radiant Summit as a strict Boros-source timing upgrade: it preserves red and white access, keeps land count unchanged, and removes a conditional tapped dual without cutting fetches or utility lands.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Plateau": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real_plateau_timing_upgrade_cut_radiant_summit/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real_plateau_timing_upgrade_cut_radiant_summit.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real_plateau_timing_upgrade_cut_radiant_summit.json`
- gate_returncode: `0`
