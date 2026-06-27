# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:29:19.790175+00:00`
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
| radiant_scrollwielder_cut_scarlet_witch | graveyard_recursion | Radiant Scrollwielder | The Scarlet Witch | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -17, spell -16, spell mana +0, birgi mana +0, ritual +0, miracle -12, tutor -3, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### radiant_scrollwielder_cut_scarlet_witch

- family: graveyard_recursion
- hypothesis: Radiant Scrollwielder tests the 614 recursion/lifegain bridge: it turns a used instant/sorcery into a same-turn recast while giving all controlled instant/sorcery spells lifelink.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `The Scarlet Witch`
- added_rule_counts: `{"Radiant Scrollwielder": 3}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_radiant_scrollwielder_gate_20260627_v1_fixed_radiant_scrollwielder_cut_scarlet_witch/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_radiant_scrollwielder_gate_20260627_v1_fixed_radiant_scrollwielder_cut_scarlet_witch.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_radiant_scrollwielder_gate_20260627_v1_fixed_radiant_scrollwielder_cut_scarlet_witch.json`
- gate_returncode: `0`
