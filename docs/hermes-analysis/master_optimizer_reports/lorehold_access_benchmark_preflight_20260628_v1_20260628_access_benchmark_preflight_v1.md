# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T03:40:20.484608+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- apply_only: `False`
- no_game_checkpoint: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json`
- package_status_counts: `{"skipped_prior_evidence": 3}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_access_benchmark_cut_land_tax | tutor_access_benchmark | Gamble | Land Tax | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| enlightened_access_benchmark_cut_land_tax | tutor_access_benchmark | Enlightened Tutor | Land Tax | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| wheel_hand_filter_cut_big_score | hand_filter_benchmark | Wheel of Fortune | Big Score | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |

## Package Notes

### gamble_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. This is not a promotion candidate by itself: it tests whether Gamble's any-card access can outperform Land Tax's upkeep basic-land access without repeating the failed Thor or Creative Technique cuts.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Gamble"], "adds_signature": ["gamble"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 16.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 36, "lorehold_spell_cast": 30, "lorehold_spell_rummage": 8, "lorehold_upkeep_rummage": 4, "miracle_cast": 4}, "win_rate": 33.33, "wins": 1}, "cuts": ["Land Tax"], "cuts_signature": ["land tax"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "tutor_access_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.md", "gate_returncode": 0, "package_key": "gamble_access_benchmark_cut_land_tax", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -25, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -21, "lorehold_spell_rummage": -4, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -10, "random_discard_after_tutor": 1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -12, "tutor_resolved": -1}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### enlightened_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. Enlightened Tutor is the lower-randomness comparison: it cannot find Approach directly, but it can put artifact/enchantment engines on top for Lorehold's miracle draw window while preserving the failed Thor and Creative Technique slots.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Enlightened Tutor"], "adds_signature": ["enlightened tutor"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 18.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 9, "lorehold_cost_paid": 32, "lorehold_rummage_discard_to_top": 9, "lorehold_spell_cast": 27, "lorehold_upkeep_rummage": 18, "miracle_cast": 14, "topdeck_manipulation_activated": 9}, "win_rate": 33.33, "wins": 1}, "cuts": ["Land Tax"], "cuts_signature": ["land tax"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "tutor_access_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.md", "gate_returncode": 0, "package_key": "enlightened_access_benchmark_cut_land_tax", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "discard_to_top_replacement": 9, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -29, "lorehold_rummage_discard_to_top": 9, "lorehold_spell_cast": -24, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": 0, "random_discard_after_tutor": -1, "ritual_mana_added": 1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### wheel_hand_filter_cut_big_score

- family: hand_filter_benchmark
- hypothesis: After Valakut over Big Score failed, the prior-aware hand-filter cut model ranked Wheel of Fortune as the next exact benchmark. Wheel has verified multiplayer discard/draw runtime and strong Lorehold variant exposure, but this remains an explicit wheel-over-ramp tradeoff because Big Score provides discard, draw, and Treasure.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Wheel of Fortune"], "adds_signature": ["wheel of fortune"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 21, "lorehold_spell_cast": 16, "lorehold_upkeep_rummage": 11, "miracle_cast": 1, "topdeck_manipulation_activated": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Big Score"], "cuts_signature": ["big score"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "hand_filter_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real_wheel_hand_filter_cut_big_score.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real_wheel_hand_filter_cut_big_score.md", "gate_returncode": 0, "package_key": "wheel_hand_filter_cut_big_score", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -35, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -13, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -10, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
