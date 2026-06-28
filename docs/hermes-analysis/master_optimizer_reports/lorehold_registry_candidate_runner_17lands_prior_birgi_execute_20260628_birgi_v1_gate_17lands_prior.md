# 17Lands Battle Prior Comparison

- Prior: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json`
- Gate report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_execute_20260628_birgi_v1_gate.json`
- Status: `inconclusive_candidate_unobserved`
- Event count: `448`
- Game count: `1`
- Player slots: `2`
- PostgreSQL writes: `False`

## Flags

- `{'metric': 'spell_action_entries', 'observed_per_player_slot': 37.5, 'prior_per_player_slot': 8.9, 'ratio': 4.2135, 'scope': 'whole_game'}`
- `{'metric': 'creature_cast_entries', 'observed_per_player_slot': 1.0, 'prior_per_player_slot': 5.49, 'ratio': 0.1821, 'scope': 'whole_game'}`
- `{'metric': 'noncreature_cast_entries', 'observed_per_player_slot': 36.5, 'prior_per_player_slot': 3.41, 'ratio': 10.7038, 'scope': 'whole_game'}`
- `{'metric': 'total_combat_damage', 'observed_per_player_slot': 0.0, 'prior_per_player_slot': 13.2575, 'ratio': 0.0, 'scope': 'whole_game'}`
- `{'card': 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'evidence_level': 'library_only', 'metric': 'candidate_observation', 'reason': 'candidate_card_never_accessed_or_near_accessed'}`

## Candidate Observations

- Birgi, God of Storytelling // Harnfel, Horn of Bounty: `{'accessed_games': 0, 'direct_card_events': 0, 'drawn_games': 0, 'evidence_level': 'library_only', 'first_turn': None, 'focus_summary_card_name': 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'library_only_games': 1, 'near_access_games': 0, 'observed': False, 'opening_hand_games': 0, 'total_events': 45, 'trace_count': 45}`

## Turn Comparison

- Whole game: `{'land_play_entries': {'observed_per_player_slot': 5.0, 'prior_per_player_slot': 6.4825, 'ratio': 0.7713}, 'spell_action_entries': {'observed_per_player_slot': 37.5, 'prior_per_player_slot': 8.9, 'ratio': 4.2135}, 'creature_cast_entries': {'observed_per_player_slot': 1.0, 'prior_per_player_slot': 5.49, 'ratio': 0.1821}, 'noncreature_cast_entries': {'observed_per_player_slot': 36.5, 'prior_per_player_slot': 3.41, 'ratio': 10.7038}, 'total_combat_damage': {'observed_per_player_slot': 0.0, 'prior_per_player_slot': 13.2575, 'ratio': 0.0}}`
