# 17Lands General Absorption Audit

- Generated at: `2026-06-29T00:01:13+00:00`
- Status: `general_absorption_ready`
- Source: `https://17lands-public.s3.amazonaws.com/analysis_data/replay_data/replay_data_public.LCI.PremierDraft.csv.gz`
- Profile: `docs/hermes-analysis/master_optimizer_reports/seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json`
- PostgreSQL writes: `False`
- Source DB mutated: `False`

## Source Evidence

- `{'field_count': 2579, 'max_turn_column': 30, 'rows_sampled': 200, 'signal_coverage': {'base_hand_columns_present': ['candidate_hand_1', 'candidate_hand_2', 'candidate_hand_3', 'candidate_hand_4', 'candidate_hand_5', 'candidate_hand_6', 'candidate_hand_7', 'opening_hand'], 'battle_prior_ready': True, 'deckbuilder_access_gate_ready': True, 'rows_sampled': 200, 'runtime_rule_oracle_ready': False, 'suffix_group_signal': {'ability': True, 'access': True, 'combat': True, 'end_turn_state': True, 'land_play': True, 'mana_spend': True, 'spell_cast': True}}, 'turn_behavior_turn_count': 24}`

## Absorbed Into ManaLoom

- seventeenlands_replay_profile.py: `implemented` - general_signal_coverage (profile.manaloom_signal_coverage)
- seventeenlands_replay_profile.py: `implemented` - card_access_vs_use_metrics (profile.sample_summary.card_observation_metrics)
- seventeenlands_battle_prior_compare.py: `implemented` - candidate_scoreability_thresholds (--min-accessed-games, --min-used-events, --min-trace-count)
- battle/deckbuilder methodology: `enforced_by_report_boundary` - 17lands_is_behavior_prior_not_rules_oracle (profile.not_recommended_use)

## General Adjustments

- battle_replay_cadence_gate: `ready` - Compare ManaLoom battle telemetry against external cadence for land drops, spell actions, mana spend, and combat pressure before trusting tuning changes.
- deckbuilder_scoreability_gate: `ready` - Do not score a swap or heuristic unless the candidate card/action was accessed and used, or the run is explicitly marked inconclusive.
- battle_event_contract: `ready` - Normalize battle logs around play_land, cast_creature, cast_noncreature, activate_ability, combat_damage, mana_spent, draw/tutor, and end_turn_state events.
- card_rule_promotion: `blocked_by_methodology` - Keep PostgreSQL/Hermes reviewed rules as the source of card behavior; 17Lands replay columns can expose usage patterns, not exact rules text or stack semantics.

## Card Observation Metric Sample

- top_by_direct_use_first: `{'ability_entries': 0, 'access_minus_use_entries': -451, 'arena_id': '87155', 'attack_or_block_entries': 446, 'battlefield_eot_entries': 587, 'creature_cast_entries': 80, 'direct_use_entries': 526, 'discard_entries': 3, 'drawn_entries': 29, 'drawn_or_tutored_entries': 0, 'first_access_turn': 2, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 75, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 46, 'total_observation_entries': 1243, 'tutored_entries': 0}`
- top_by_natural_access_first: `{'ability_entries': 0, 'access_minus_use_entries': -29, 'arena_id': '87584', 'attack_or_block_entries': 2, 'battlefield_eot_entries': 3587, 'creature_cast_entries': 0, 'direct_use_entries': 313, 'discard_entries': 21, 'drawn_entries': 104, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 311, 'natural_access_entries': 284, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 180, 'total_observation_entries': 4205, 'tutored_entries': 0}`
- top_by_total_observations_first: `{'ability_entries': 0, 'access_minus_use_entries': -29, 'arena_id': '87584', 'attack_or_block_entries': 2, 'battlefield_eot_entries': 3587, 'creature_cast_entries': 0, 'direct_use_entries': 313, 'discard_entries': 21, 'drawn_entries': 104, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 311, 'natural_access_entries': 284, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 180, 'total_observation_entries': 4205, 'tutored_entries': 0}`

## Blocked Uses

- Do not promote card battle rules directly from replay_data.
- Do not treat PremierDraft behavior as Commander/Lorehold strategy proof.
- Do not infer exact stack, target selection, replacement effects, or hidden choices from these columns alone.
- Do not treat every high numeric Arena ID in ability/action columns as a resolved card without annotation.
