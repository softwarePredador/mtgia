# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T23:30:00.813395+00:00`
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
| austere_command_wipe_over_emeria_tradeoff | pressure_reset_tradeoff | Austere Command | Emeria's Call // Emeria, Shattered Skyclave | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -38, spell -31, spell mana +0, birgi mana +0, ritual -1, miracle -11, tutor -4, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### austere_command_wipe_over_emeria_tradeoff

- family: pressure_reset_tradeoff
- hypothesis: Austere Command is a flexible board reset with active runtime rules, but Emeria's Call now has measured token/protection exposure. This gate is therefore an explicit wipe-over-rebuild tradeoff: it must prove that extra board-reset control beats losing Emeria's rebuild tokens, protection window, and miracle hit density.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Emeria's Call // Emeria, Shattered Skyclave`
- added_rule_counts: `{"Austere Command": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff.json`
- gate_returncode: `0`
