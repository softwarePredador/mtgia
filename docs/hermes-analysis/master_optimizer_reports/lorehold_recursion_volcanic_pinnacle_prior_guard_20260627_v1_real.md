# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T00:40:25.954374+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json`
- package_status_counts: `{"skipped_prior_evidence": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| volcanic_recursion_cut_pinnacle | graveyard_recursion_benchmark | Volcanic Vision | Pinnacle Monk // Mystic Peak | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |

## Package Notes

### volcanic_recursion_cut_pinnacle

- family: graveyard_recursion_benchmark
- hypothesis: The recursion cut model protects Squee, Farewell, Furygale Flocking, and Mizzix's Mastery. Volcanic Vision over Pinnacle Monk is the first non-Squee same-lane benchmark: it trades a low-exposure ETB recursion engine for a high-cost instant/sorcery recursion spell with opponent creature damage annotation.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Volcanic Vision"], "adds_signature": ["volcanic vision"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 21, "lorehold_spell_cast": 14, "lorehold_upkeep_rummage": 11, "miracle_cast": 1}, "win_rate": 0.0, "wins": 0}, "cuts": ["Pinnacle Monk // Mystic Peak"], "cuts_signature": ["pinnacle monk // mystic peak"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "graveyard_recursion_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real_volcanic_recursion_cut_pinnacle.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real_volcanic_recursion_cut_pinnacle.md", "gate_returncode": 0, "package_key": "volcanic_recursion_cut_pinnacle", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -37, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -13, "random_discard_after_tutor": 0, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -12, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
