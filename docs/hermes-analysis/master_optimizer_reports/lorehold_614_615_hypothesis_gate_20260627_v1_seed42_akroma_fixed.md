# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:06:02.410470+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| akromas_will_cut_avatar_wrath | pressure_absorber | Akroma's Will | Avatar's Wrath | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -35, spell -26, spell mana +0, birgi mana +0, ritual -1, miracle -10, tutor -4, random discard -1, topdeck -9, discard-to-top +12, rummage-to-top +12, spell-rummage-to-top +0, hand to top +0, spell rummage -10, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### akromas_will_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Akroma's Will is a 614 protection/finisher bridge with active local battle rules. It challenges Avatar's Wrath without touching the locked protection shell or the medallion/topdeck engine.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Avatar's Wrath`
- added_rule_counts: `{"Akroma's Will": 3}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed_akromas_will_cut_avatar_wrath/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed_akromas_will_cut_avatar_wrath.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed_akromas_will_cut_avatar_wrath.json`
- gate_returncode: `0`
