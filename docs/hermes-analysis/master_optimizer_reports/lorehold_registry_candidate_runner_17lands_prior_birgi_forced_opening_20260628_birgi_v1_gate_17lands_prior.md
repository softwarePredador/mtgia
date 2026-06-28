# 17Lands Battle Prior Comparison

- Prior: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json`
- Gate report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_17lands_prior_birgi_forced_opening_20260628_birgi_v1_gate.json`
- Status: `battle_prior_warning`
- Event count: `617`
- Game count: `1`
- Player slots: `2`
- PostgreSQL writes: `False`

## Flags

- `{'metric': 'spell_action_entries', 'observed_per_player_slot': 39.5, 'prior_per_player_slot': 8.9, 'ratio': 4.4382, 'scope': 'whole_game'}`
- `{'metric': 'creature_cast_entries', 'observed_per_player_slot': 2.5, 'prior_per_player_slot': 5.49, 'ratio': 0.4554, 'scope': 'whole_game'}`
- `{'metric': 'noncreature_cast_entries', 'observed_per_player_slot': 37.0, 'prior_per_player_slot': 3.41, 'ratio': 10.8504, 'scope': 'whole_game'}`
- `{'metric': 'total_combat_damage', 'observed_per_player_slot': 0.0, 'prior_per_player_slot': 13.2575, 'ratio': 0.0, 'scope': 'whole_game'}`

## Candidate Observations

- Birgi, God of Storytelling // Harnfel, Horn of Bounty: `{'accessed_games': 1, 'direct_card_events': 4, 'drawn_games': 0, 'evidence_level': 'accessed', 'first_turn': None, 'focus_summary_card_name': 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'library_only_games': 0, 'near_access_games': 0, 'observed': True, 'opening_hand_games': 1, 'total_events': 75, 'trace_count': 71}`

## Turn Comparison

- Whole game: `{'land_play_entries': {'observed_per_player_slot': 5.5, 'prior_per_player_slot': 6.4825, 'ratio': 0.8484}, 'spell_action_entries': {'observed_per_player_slot': 39.5, 'prior_per_player_slot': 8.9, 'ratio': 4.4382}, 'creature_cast_entries': {'observed_per_player_slot': 2.5, 'prior_per_player_slot': 5.49, 'ratio': 0.4554}, 'noncreature_cast_entries': {'observed_per_player_slot': 37.0, 'prior_per_player_slot': 3.41, 'ratio': 10.8504}, 'total_combat_damage': {'observed_per_player_slot': 0.0, 'prior_per_player_slot': 13.2575, 'ratio': 0.0}}`
