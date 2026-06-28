# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T04:46:38.961526+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json`
- package_status_counts: `{"gated": 2}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gods_willing_commander_shield_cut_promise | targeted_commander_protection | Gods Willing | Promise of Loyalty | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -34, spell -32, spell mana +0, birgi mana +0, ritual +0, miracle -9, tutor -4, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -16, squee gy -3, squee return -2, squee explained -2 | reject_or_rework |
| sejiri_shelter_commander_shield_cut_promise | targeted_commander_protection | Sejiri Shelter // Sejiri Glacier | Promise of Loyalty | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -40, spell -34, spell mana +0, birgi mana +0, ritual -1, miracle -11, tutor -6, random discard -1, topdeck -10, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -15, squee gy +0, squee return -1, squee explained -1 | reject_or_rework |

## Package Notes

### gods_willing_commander_shield_cut_promise

- family: targeted_commander_protection
- hypothesis: After the runtime learned targeted protection responses, Gods Willing tests the cheapest 616 commander shield against the seed-7 failure mode where Lorehold died to targeted removal with one mana available. Promise of Loyalty is the pressure-lane comparison slot: it is a five-mana sorcery cleanup spell already challenged by the Ghostly Prison pressure test, while this keeps Mother/Giver, Dawn's Truce, High Noon, topdeck engines, ramp, and the expensive win package intact.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Promise of Loyalty`
- added_rule_counts: `{"Gods Willing": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise.json`
- gate_returncode: `0`

### sejiri_shelter_commander_shield_cut_promise

- family: targeted_commander_protection
- hypothesis: Sejiri Shelter carries the same targeted protection rule as Gods Willing, but costs two mana and is currently evaluated by the local runtime as the spell face rather than as a flexible MDFC land. This benchmark checks whether the extra shield density is still useful when compared against the same five-mana pressure cleanup slot.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Promise of Loyalty`
- added_rule_counts: `{"Sejiri Shelter // Sejiri Glacier": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise.json`
- gate_returncode: `0`
