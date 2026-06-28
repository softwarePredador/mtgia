# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T10:02:43.237800+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- apply_only: `False`
- no_game_checkpoint: `False`
- forced_access_mode: `none`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `-`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`
- package_decision_counts: `{"reject_or_rework": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Exposure | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- |
| mana_vault_fast_mana_cut_arcane_signet | fast_mana | Mana Vault | Arcane Signet | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -20, spell -18, spell mana +0, birgi mana +0, ritual +0, miracle -4, tutor -4, random discard -1, topdeck +0, shield +0, discard-to-top +11, rummage-to-top +11, spell-rummage-to-top +0, hand to top +0, spell rummage -16, squee gy -1, squee return +0, squee explained +0 | candidate_added_cards_used: Mana Vault use=4 access_games=2 near_games=0 dominant_zone=library | reject_or_rework |

## Package Notes

### mana_vault_fast_mana_cut_arcane_signet

- family: fast_mana
- hypothesis: Mana Vault is legal, battle-ready fast mana and appears in multiple Lorehold variants. This tests whether one-mana colorless burst accelerates commander and expensive spell windows more than Arcane Signet's colored fixing, without cutting protected medallions, Bender's Waterskin, Victory Chimes, or Jeska's Will.
- status: `gated`
- forced_access_mode: `none`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Mana Vault": 1}`
- exposure_summary: `{"baseline_cut_cards": {"all_cards_accessed": true, "all_cards_near_access": true, "all_cards_used": true, "card_count": 1, "cards": [{"access_profile": {"accessed_games": 2, "accessed_trace_count": 79, "dominant_zone": "library", "drawn_games": 2, "drawn_trace_count": 2, "library_only_games": 1, "near_access_games": 0, "near_access_trace_count": 32, "opening_hand_games": 0, "opening_hand_trace_count": 0, "trace_count": 218, "trace_games": 3, "zone_counts": {"battlefield": 77, "hand": 2, "library": 139}}, "card_name": "Arcane Signet", "event_breakdown": {"cost_paid": 2, "spell_cast": 2}, "location_trace_count": 218, "location_trace_games": 3, "recorded_use_count": 4, "status": "used"}], "cards_with_access": 1, "cards_with_near_access": 1, "cards_with_recorded_use": 1, "total_recorded_use_count": 4}, "candidate_added_cards": {"all_cards_accessed": true, "all_cards_near_access": true, "all_cards_used": true, "card_count": 1, "cards": [{"access_profile": {"accessed_games": 2, "accessed_trace_count": 71, "dominant_zone": "library", "drawn_games": 1, "drawn_trace_count": 1, "library_only_games": 1, "near_access_games": 0, "near_access_trace_count": 29, "opening_hand_games": 0, "opening_hand_trace_count": 0, "trace_count": 146, "trace_games": 3, "zone_counts": {"battlefield": 38, "exile": 29, "hand": 4, "library": 75}}, "card_name": "Mana Vault", "event_breakdown": {"cost_paid": 2, "spell_cast": 2}, "location_trace_count": 146, "location_trace_games": 3, "recorded_use_count": 4, "status": "used"}], "cards_with_access": 1, "cards_with_near_access": 1, "cards_with_recorded_use": 1, "total_recorded_use_count": 4}, "low_candidate_added_card_access": false, "low_candidate_added_card_use": false, "next_step": "evaluate_winrate_and_strategy_delta", "status": "candidate_added_cards_used"}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237_mana_vault_fast_mana_cut_arcane_signet/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237_mana_vault_fast_mana_cut_arcane_signet.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237_mana_vault_fast_mana_cut_arcane_signet.json`
- gate_returncode: `0`
