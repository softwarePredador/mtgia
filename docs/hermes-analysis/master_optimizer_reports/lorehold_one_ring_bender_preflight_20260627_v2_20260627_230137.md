# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T23:01:37.749561+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `1`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609.json`
- package_status_counts: `{"skipped_cut_safety": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| one_ring_burden_reset | misc | The One Ring | Bender's Waterskin | `blocked_cut_safety;same_key_different_signature` | - | - | +0.00 | - | skipped_cut_safety |

## Package Notes

### one_ring_burden_reset

- family: misc
- hypothesis: The Mind Stone can reset The One Ring burden counters after harness; test whether that draw engine is worth a non-core utility/ramp slot.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "aggregate upside exists, but it broke the known strong seed", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["The One Ring"], "adds_signature": ["the one ring"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "miracle_cast": 14, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 20, "lorehold_spell_cast": 17, "miracle_cast": 4, "topdeck_manipulation_activated": 4}, "win_rate": 0.0, "wins": 0}, "cuts": ["Artist's Talent"], "cuts_signature": ["artist's talent"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": null, "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_one_ring_burden_reset.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609_one_ring_burden_reset.md", "gate_returncode": 0, "package_key": "one_ring_burden_reset", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_v1_20260627_114609.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -41, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -34, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -10, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -8, "tutor_resolved": -4}}], "reason": "previous package-key result has different add/cut signature", "status": "same_key_different_signature"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
