# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:04:05.172934+00:00`
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
| perch_protection_cut_avatar_wrath | pressure_absorber | Perch Protection | Avatar's Wrath | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -20, spell -16, spell mana +0, birgi mana +0, ritual +0, miracle -10, tutor -5, random discard -1, topdeck -8, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -8, squee gy +0, squee return +1, squee explained +1 | reject_or_rework |

## Package Notes

### perch_protection_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Perch Protection is present in the two strongest non-607 variants and has active local battle rules. It tests a same-lane protection upgrade over Avatar's Wrath while preserving Dawn's Truce, Fated Clash, Hexing Squelcher, High Noon, medallions, Storm Herd, and Thor.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Avatar's Wrath`
- added_rule_counts: `{"Perch Protection": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed_perch_protection_cut_avatar_wrath/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed_perch_protection_cut_avatar_wrath.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed_perch_protection_cut_avatar_wrath.json`
- gate_returncode: `0`
