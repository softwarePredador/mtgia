# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T09:43:11.969051+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `1`
- opponent_seed: `99`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- forced_access_mode: `none`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `-`
- cut_safety_report: `-`
- protected_cut_registry: `-`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`
- package_decision_counts: `{"inconclusive_low_exposure": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| mana_vault_fast_mana_cut_arcane_signet | fast_mana | Mana Vault | Arcane Signet | `not_checked` | 1/0/0 `100.00%` | 1/0/0 `100.00%` | +0.00 | cost -6, spell -2, spell mana +0, birgi mana +0, ritual +0, miracle +3, tutor +1, random discard +1, topdeck -4, shield +0, discard-to-top +4, rummage-to-top +4, spell-rummage-to-top +0, hand to top +0, spell rummage +0, squee gy +0, squee return +0, squee explained +0 | candidate_added_card_low_access: Mana Vault use=0 access_games=0 near_games=0 dominant_zone=library | inconclusive_low_exposure |

## Package Notes

### mana_vault_fast_mana_cut_arcane_signet

- family: fast_mana
- hypothesis: Mana Vault is legal, battle-ready fast mana and appears in multiple Lorehold variants. This tests whether one-mana colorless burst accelerates commander and expensive spell windows more than Arcane Signet's colored fixing, without cutting protected medallions, Bender's Waterskin, Victory Chimes, or Jeska's Will.
- status: `gated`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [], "reason": "cut-safety preflight disabled", "status": "not_checked"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Mana Vault": 1}`
- exposure_summary: `{"baseline_cut_cards": {"all_cards_accessed": false, "all_cards_near_access": false, "all_cards_used": false, "card_count": 1, "cards": [{"access_profile": {"accessed_games": 0, "accessed_trace_count": 0, "dominant_zone": "library", "drawn_games": 0, "drawn_trace_count": 0, "library_only_games": 1, "near_access_games": 0, "near_access_trace_count": 0, "opening_hand_games": 0, "opening_hand_trace_count": 0, "trace_count": 47, "trace_games": 1, "zone_counts": {"library": 47}}, "card_name": "Arcane Signet", "event_breakdown": {}, "location_trace_count": 47, "location_trace_games": 1, "recorded_use_count": 0, "status": "library_only_not_used"}], "cards_with_access": 0, "cards_with_near_access": 0, "cards_with_recorded_use": 0, "total_recorded_use_count": 0}, "candidate_added_cards": {"all_cards_accessed": false, "all_cards_near_access": false, "all_cards_used": false, "card_count": 1, "cards": [{"access_profile": {"accessed_games": 0, "accessed_trace_count": 0, "dominant_zone": "library", "drawn_games": 0, "drawn_trace_count": 0, "library_only_games": 1, "near_access_games": 0, "near_access_trace_count": 0, "opening_hand_games": 0, "opening_hand_trace_count": 0, "trace_count": 52, "trace_games": 1, "zone_counts": {"library": 52}}, "card_name": "Mana Vault", "event_breakdown": {}, "location_trace_count": 52, "location_trace_games": 1, "recorded_use_count": 0, "status": "library_only_not_used"}], "cards_with_access": 0, "cards_with_near_access": 0, "cards_with_recorded_use": 0, "total_recorded_use_count": 0}, "low_candidate_added_card_access": true, "low_candidate_added_card_use": true, "next_step": "increase_sample_or_run_forced_access_gate", "status": "candidate_added_card_low_access"}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_decision_contract_20260628_v2_20260628_191500_mana_vault_fast_mana_cut_arcane_signet/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_decision_contract_20260628_v2_20260628_191500_mana_vault_fast_mana_cut_arcane_signet.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_decision_contract_20260628_v2_20260628_191500_mana_vault_fast_mana_cut_arcane_signet.json`
- gate_returncode: `0`
