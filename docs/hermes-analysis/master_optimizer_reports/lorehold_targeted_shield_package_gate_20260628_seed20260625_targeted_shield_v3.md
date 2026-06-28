# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T04:48:59.998136+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `20260625`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json`
- package_status_counts: `{"gated": 2}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gods_willing_commander_shield_cut_promise | targeted_commander_protection | Gods Willing | Promise of Loyalty | `clear` | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | cost -1, spell -2, spell mana +0, birgi mana +0, ritual +0, miracle +3, tutor -4, random discard +1, topdeck +3, discard-to-top -8, rummage-to-top -8, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +0, squee return +0, squee explained +0 | tie_watch_strategy_regression |
| sejiri_shelter_commander_shield_cut_promise | targeted_commander_protection | Sejiri Shelter // Sejiri Glacier | Promise of Loyalty | `clear` | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | cost -14, spell -11, spell mana +0, birgi mana +0, ritual -1, miracle -1, tutor -4, random discard -1, topdeck +0, discard-to-top +5, rummage-to-top +5, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +0, squee return +0, squee explained +0 | reject_or_rework |

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
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_gods_willing_commander_shield_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_gods_willing_commander_shield_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_gods_willing_commander_shield_cut_promise.json`
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
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_sejiri_shelter_commander_shield_cut_promise/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_sejiri_shelter_commander_shield_cut_promise.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_sejiri_shelter_commander_shield_cut_promise.json`
- gate_returncode: `0`
