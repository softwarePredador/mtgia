# 17Lands replay_data Profile

- Generated at: `2026-06-29T00:01:13+00:00`
- Source: `17Lands LCI PremierDraft replay_data`
- Rows sampled: `200`
- PostgreSQL writes: `False`
- Source DB mutated: `False`

## Shape

- Fields: `2579`
- Base columns: `629`
- Turn columns: `1950`
- Max turn column: `30`
- Turn suffixes: `33`
- Turn side counts: `{'oppo': 990, 'user': 960}`

## What This Can Improve

- Calibrate battle/deckbuilder tempo priors: land drops, mana spend, cast timing, combat pressure.
- Compare ManaLoom simulated games against real MTGA limited cadence before tuning heuristics.
- Build exposure-aware tests that require a card/action to be observed before judging a candidate swap.
- Map arena_id to card names only as reference metadata; keep reviewed rules in PostgreSQL/Hermes flows.

## ManaLoom General Adjustments

- battle_replay_cadence_gate: `ready` - Compare ManaLoom battle telemetry against external cadence for land drops, spell actions, mana spend, and combat pressure before trusting tuning changes.
- deckbuilder_scoreability_gate: `ready` - Do not score a swap or heuristic unless the candidate card/action was accessed and used, or the run is explicitly marked inconclusive.
- battle_event_contract: `ready` - Normalize battle logs around play_land, cast_creature, cast_noncreature, activate_ability, combat_damage, mana_spent, draw/tutor, and end_turn_state events.
- card_rule_promotion: `blocked_by_methodology` - Keep PostgreSQL/Hermes reviewed rules as the source of card behavior; 17Lands replay columns can expose usage patterns, not exact rules text or stack semantics.

## ManaLoom Signal Coverage

- `{'rows_sampled': 200, 'base_hand_columns_present': ['candidate_hand_1', 'candidate_hand_2', 'candidate_hand_3', 'candidate_hand_4', 'candidate_hand_5', 'candidate_hand_6', 'candidate_hand_7', 'opening_hand'], 'suffix_group_signal': {'access': True, 'land_play': True, 'spell_cast': True, 'ability': True, 'combat': True, 'mana_spend': True, 'end_turn_state': True}, 'battle_prior_ready': True, 'deckbuilder_access_gate_ready': True, 'runtime_rule_oracle_ready': False}`

## What This Must Not Be Used For

- Do not promote card battle rules directly from replay_data.
- Do not treat PremierDraft behavior as Commander/Lorehold strategy proof.
- Do not infer exact stack, target selection, replacement effects, or hidden choices from these columns alone.
- Do not treat every high numeric Arena ID in ability/action columns as a resolved card without annotation.

## Sample Game

- expansion: `LCI`
- event_type: `PremierDraft`
- draft_id: `976d867638234d0087008f387809c325`
- draft_time: `2023-11-09 22:57:41`
- match_number: `1`
- game_number: `1`
- game_time: `2023-11-09 23:43:35`
- rank: `bronze`
- opp_rank: `None`
- main_colors: `RG`
- splash_colors: `WU`
- opp_colors: `WR`
- on_play: `False`
- num_mulligans: `0`
- opp_num_mulligans: `0`
- num_turns: `13`
- won: `False`

## Top Signals

- Outcomes: `{'False': 82, 'True': 118}`
- Main colors top: `{'WU': 40, 'UR': 39, 'WR': 38, 'UB': 19, 'WB': 14, 'UG': 13, 'RG': 12, 'BR': 9, 'BG': 8, 'WG': 8}`
- Opponent colors top: `{'WR': 32, 'RG': 24, 'WB': 17, 'WG': 16, 'UB': 14, 'UR': 12, 'WU': 12, 'UG': 11, 'BR': 11, 'WRG': 8, 'B': 6, 'BG': 6}`
- Nonempty turn suffixes top: `{'eot_oppo_cards_in_hand': 3680, 'eot_user_life': 3680, 'eot_oppo_life': 3680, 'eot_user_lands_in_play': 3471, 'eot_oppo_lands_in_play': 3469, 'cards_drawn': 3369, 'eot_user_creatures_in_play': 2895, 'eot_oppo_creatures_in_play': 2794, 'lands_played': 2590, 'eot_user_non_creatures_in_play': 2073, 'creatures_cast': 1972, 'eot_oppo_non_creatures_in_play': 1906, 'cards_drawn_or_tutored': 1679, 'creatures_attacked': 1655, 'user_mana_spent': 1625, 'oppo_mana_spent': 1592, 'creatures_unblocked': 1406, 'user_abilities': 1229, 'oppo_abilities': 1145, 'oppo_combat_damage_taken': 838, 'non_creatures_cast': 786, 'user_combat_damage_taken': 662, 'eot_user_cards_in_hand': 582, 'creatures_blocked': 533, 'creatures_blocking': 533, 'oppo_creatures_killed_combat': 381, 'user_creatures_killed_combat': 362, 'oppo_instants_sorceries_cast': 271, 'user_instants_sorceries_cast': 222, 'user_creatures_killed_non_combat': 168}`
- Card-like Arena IDs top: `{'87584': 4205, '87578': 3925, '87586': 3400, '87579': 3348, '87580': 2842, '87582': 2324, '87483': 1988, '87011': 1560, '87457': 1455, '87155': 1243, '87460': 1160, '87454': 1159, '87585': 916, '87207': 729, '87149': 725, '87220': 684, '87302': 666, '87214': 652, '87485': 650, '84596': 620, '87227': 607, '87017': 601, '87160': 591, '87313': 584, '87199': 579, '87439': 564, '87440': 519, '87455': 517, '87453': 500, '87228': 487, '87458': 479, '87473': 459, '87484': 456, '87186': 453, '87434': 418, '87366': 409, '87175': 406, '87443': 399, '87326': 398, '87480': 397, '83980': 388, '87244': 381, '87163': 380, '87441': 358, '87442': 349, '86341': 341, '87133': 337, '87264': 333, '87321': 329, '87134': 328, '87365': 305, '87274': 290, '87474': 285, '87217': 280, '87386': 275, '87287': 270, '87142': 266, '87328': 260, '87423': 259, '87306': 248, '87146': 244, '87212': 240, '87412': 236, '87292': 236, '87319': 230, '87221': 224, '87166': 223, '87329': 223, '87179': 222, '87140': 221, '87239': 216, '87488': 213, '87246': 209, '87375': 207, '87241': 200, '87197': 196, '87136': 194, '87141': 185}`

## Arena ID Notes

- Small numeric IDs can be hidden/unknown Arena-side markers in replay_data, not Scryfall-resolvable cards.
- High numeric IDs from ability/action columns may still need Scryfall/cache annotation before card-level interpretation.
- EOT *_in_play columns are treated as battlefield card ID lists, not scalar counts.

## Turn Behavior Metrics

- Turn 1: `{'active_mana_spent_avg_positive': 1.0, 'active_mana_spent_positive_observations': 132, 'creature_cast_entries': 100, 'land_play_entries': 400, 'noncreature_cast_entries': 32, 'spell_action_entries': 132, 'total_combat_damage': 0.0}`
- Turn 2: `{'active_mana_spent_avg_positive': 1.901, 'active_mana_spent_positive_observations': 324, 'creature_cast_entries': 246, 'land_play_entries': 400, 'noncreature_cast_entries': 81, 'spell_action_entries': 327, 'total_combat_damage': 97.0}`
- Turn 3: `{'active_mana_spent_avg_positive': 2.765, 'active_mana_spent_positive_observations': 353, 'creature_cast_entries': 260, 'land_play_entries': 386, 'noncreature_cast_entries': 125, 'spell_action_entries': 385, 'total_combat_damage': 371.0}`
- Turn 4: `{'active_mana_spent_avg_positive': 3.489, 'active_mana_spent_positive_observations': 370, 'creature_cast_entries': 326, 'land_play_entries': 346, 'noncreature_cast_entries': 141, 'spell_action_entries': 467, 'total_combat_damage': 603.0}`
- Turn 5: `{'active_mana_spent_avg_positive': 3.975, 'active_mana_spent_positive_observations': 365, 'creature_cast_entries': 279, 'land_play_entries': 282, 'noncreature_cast_entries': 223, 'spell_action_entries': 502, 'total_combat_damage': 760.0}`
- Turn 6: `{'active_mana_spent_avg_positive': 4.355, 'active_mana_spent_positive_observations': 338, 'creature_cast_entries': 263, 'land_play_entries': 222, 'noncreature_cast_entries': 202, 'spell_action_entries': 465, 'total_combat_damage': 794.0}`
- Turn 7: `{'active_mana_spent_avg_positive': 4.571, 'active_mana_spent_positive_observations': 294, 'creature_cast_entries': 218, 'land_play_entries': 181, 'noncreature_cast_entries': 165, 'spell_action_entries': 383, 'total_combat_damage': 710.0}`
- Turn 8: `{'active_mana_spent_avg_positive': 5.091, 'active_mana_spent_positive_observations': 230, 'creature_cast_entries': 169, 'land_play_entries': 129, 'noncreature_cast_entries': 118, 'spell_action_entries': 287, 'total_combat_damage': 507.0}`
- Turn 9: `{'active_mana_spent_avg_positive': 4.966, 'active_mana_spent_positive_observations': 178, 'creature_cast_entries': 130, 'land_play_entries': 91, 'noncreature_cast_entries': 113, 'spell_action_entries': 243, 'total_combat_damage': 492.0}`
- Turn 10: `{'active_mana_spent_avg_positive': 5.219, 'active_mana_spent_positive_observations': 128, 'creature_cast_entries': 80, 'land_play_entries': 68, 'noncreature_cast_entries': 67, 'spell_action_entries': 147, 'total_combat_damage': 383.0}`
- Turn 11: `{'active_mana_spent_avg_positive': 5.027, 'active_mana_spent_positive_observations': 75, 'creature_cast_entries': 47, 'land_play_entries': 34, 'noncreature_cast_entries': 42, 'spell_action_entries': 89, 'total_combat_damage': 225.0}`
- Turn 12: `{'active_mana_spent_avg_positive': 4.644, 'active_mana_spent_positive_observations': 45, 'creature_cast_entries': 31, 'land_play_entries': 14, 'noncreature_cast_entries': 17, 'spell_action_entries': 48, 'total_combat_damage': 197.0}`

## Card Observation Metrics

- Direct use `87155`: `{'ability_entries': 0, 'attack_or_block_entries': 446, 'battlefield_eot_entries': 587, 'creature_cast_entries': 80, 'direct_use_entries': 526, 'discard_entries': 3, 'drawn_entries': 29, 'drawn_or_tutored_entries': 0, 'first_access_turn': 2, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 75, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 46, 'total_observation_entries': 1243, 'tutored_entries': 0, 'access_minus_use_entries': -451}`
- Direct use `87483`: `{'ability_entries': 0, 'attack_or_block_entries': 401, 'battlefield_eot_entries': 1587, 'creature_cast_entries': 0, 'direct_use_entries': 401, 'discard_entries': 0, 'drawn_entries': 0, 'drawn_or_tutored_entries': 0, 'first_access_turn': None, 'first_seen_turn': 3, 'first_use_turn': 3, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 0, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 0, 'total_observation_entries': 1988, 'tutored_entries': 0, 'access_minus_use_entries': -401}`
- Direct use `87584`: `{'ability_entries': 0, 'attack_or_block_entries': 2, 'battlefield_eot_entries': 3587, 'creature_cast_entries': 0, 'direct_use_entries': 313, 'discard_entries': 21, 'drawn_entries': 104, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 311, 'natural_access_entries': 284, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 180, 'total_observation_entries': 4205, 'tutored_entries': 0, 'access_minus_use_entries': -29}`
- Direct use `87578`: `{'ability_entries': 0, 'attack_or_block_entries': 2, 'battlefield_eot_entries': 3403, 'creature_cast_entries': 0, 'direct_use_entries': 289, 'discard_entries': 7, 'drawn_entries': 77, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 287, 'natural_access_entries': 226, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 144, 'total_observation_entries': 3925, 'tutored_entries': 5, 'access_minus_use_entries': -63}`
- Direct use `87207`: `{'ability_entries': 0, 'attack_or_block_entries': 229, 'battlefield_eot_entries': 349, 'creature_cast_entries': 58, 'direct_use_entries': 287, 'discard_entries': 3, 'drawn_entries': 26, 'drawn_or_tutored_entries': 0, 'first_access_turn': 2, 'first_seen_turn': 2, 'first_use_turn': 2, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 64, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 38, 'total_observation_entries': 729, 'tutored_entries': 0, 'access_minus_use_entries': -223}`
- Direct use `87220`: `{'ability_entries': 0, 'attack_or_block_entries': 232, 'battlefield_eot_entries': 333, 'creature_cast_entries': 46, 'direct_use_entries': 278, 'discard_entries': 0, 'drawn_entries': 16, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 53, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 36, 'total_observation_entries': 684, 'tutored_entries': 1, 'access_minus_use_entries': -225}`
- Direct use `87302`: `{'ability_entries': 0, 'attack_or_block_entries': 220, 'battlefield_eot_entries': 303, 'creature_cast_entries': 56, 'direct_use_entries': 276, 'discard_entries': 0, 'drawn_entries': 16, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 49, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 33, 'total_observation_entries': 666, 'tutored_entries': 0, 'access_minus_use_entries': -227}`
- Direct use `87586`: `{'ability_entries': 0, 'attack_or_block_entries': 2, 'battlefield_eot_entries': 2975, 'creature_cast_entries': 0, 'direct_use_entries': 250, 'discard_entries': 1, 'drawn_entries': 75, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 248, 'natural_access_entries': 174, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 98, 'total_observation_entries': 3400, 'tutored_entries': 1, 'access_minus_use_entries': -76}`
- Direct use `87579`: `{'ability_entries': 0, 'attack_or_block_entries': 0, 'battlefield_eot_entries': 2858, 'creature_cast_entries': 0, 'direct_use_entries': 245, 'discard_entries': 14, 'drawn_entries': 118, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 245, 'natural_access_entries': 231, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 112, 'total_observation_entries': 3348, 'tutored_entries': 1, 'access_minus_use_entries': -14}`
- Direct use `87580`: `{'ability_entries': 0, 'attack_or_block_entries': 6, 'battlefield_eot_entries': 2374, 'creature_cast_entries': 0, 'direct_use_entries': 225, 'discard_entries': 10, 'drawn_entries': 100, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 219, 'natural_access_entries': 233, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 130, 'total_observation_entries': 2842, 'tutored_entries': 3, 'access_minus_use_entries': 8}`
- Direct use `87160`: `{'ability_entries': 0, 'attack_or_block_entries': 157, 'battlefield_eot_entries': 284, 'creature_cast_entries': 68, 'direct_use_entries': 225, 'discard_entries': 0, 'drawn_entries': 20, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 3, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 48, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 28, 'total_observation_entries': 591, 'tutored_entries': 0, 'access_minus_use_entries': -177}`
- Direct use `87227`: `{'ability_entries': 0, 'attack_or_block_entries': 141, 'battlefield_eot_entries': 282, 'creature_cast_entries': 69, 'direct_use_entries': 210, 'discard_entries': 2, 'drawn_entries': 40, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 3, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 75, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 35, 'total_observation_entries': 607, 'tutored_entries': 0, 'access_minus_use_entries': -135}`
- Direct use `87313`: `{'ability_entries': 0, 'attack_or_block_entries': 137, 'battlefield_eot_entries': 281, 'creature_cast_entries': 68, 'direct_use_entries': 205, 'discard_entries': 1, 'drawn_entries': 18, 'drawn_or_tutored_entries': 0, 'first_access_turn': 2, 'first_seen_turn': 2, 'first_use_turn': 3, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 52, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 33, 'total_observation_entries': 584, 'tutored_entries': 1, 'access_minus_use_entries': -153}`
- Direct use `87149`: `{'ability_entries': 0, 'attack_or_block_entries': 129, 'battlefield_eot_entries': 442, 'creature_cast_entries': 66, 'direct_use_entries': 195, 'discard_entries': 1, 'drawn_entries': 27, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 2, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 54, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 27, 'total_observation_entries': 725, 'tutored_entries': 0, 'access_minus_use_entries': -141}`
- Direct use `87214`: `{'ability_entries': 0, 'attack_or_block_entries': 142, 'battlefield_eot_entries': 383, 'creature_cast_entries': 49, 'direct_use_entries': 191, 'discard_entries': 1, 'drawn_entries': 20, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 2, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 55, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 35, 'total_observation_entries': 652, 'tutored_entries': 0, 'access_minus_use_entries': -136}`
- Direct use `87473`: `{'ability_entries': 0, 'attack_or_block_entries': 183, 'battlefield_eot_entries': 276, 'creature_cast_entries': 0, 'direct_use_entries': 183, 'discard_entries': 0, 'drawn_entries': 0, 'drawn_or_tutored_entries': 0, 'first_access_turn': None, 'first_seen_turn': 3, 'first_use_turn': 4, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 0, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 0, 'total_observation_entries': 459, 'tutored_entries': 0, 'access_minus_use_entries': -183}`
- Direct use `87582`: `{'ability_entries': 0, 'attack_or_block_entries': 0, 'battlefield_eot_entries': 2036, 'creature_cast_entries': 0, 'direct_use_entries': 171, 'discard_entries': 3, 'drawn_entries': 47, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 171, 'natural_access_entries': 114, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 64, 'total_observation_entries': 2324, 'tutored_entries': 3, 'access_minus_use_entries': -57}`
- Direct use `87228`: `{'ability_entries': 0, 'attack_or_block_entries': 114, 'battlefield_eot_entries': 225, 'creature_cast_entries': 53, 'direct_use_entries': 167, 'discard_entries': 0, 'drawn_entries': 23, 'drawn_or_tutored_entries': 0, 'first_access_turn': 1, 'first_seen_turn': 1, 'first_use_turn': 4, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 61, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 36, 'total_observation_entries': 487, 'tutored_entries': 2, 'access_minus_use_entries': -106}`
- Direct use `1268`: `{'ability_entries': 145, 'attack_or_block_entries': 0, 'battlefield_eot_entries': 0, 'creature_cast_entries': 0, 'direct_use_entries': 145, 'discard_entries': 0, 'drawn_entries': 0, 'drawn_or_tutored_entries': 0, 'first_access_turn': None, 'first_seen_turn': 2, 'first_use_turn': 2, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 0, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 0, 'total_observation_entries': 145, 'tutored_entries': 0, 'access_minus_use_entries': -145}`
- Direct use `116886`: `{'ability_entries': 140, 'attack_or_block_entries': 0, 'battlefield_eot_entries': 0, 'creature_cast_entries': 0, 'direct_use_entries': 140, 'discard_entries': 0, 'drawn_entries': 0, 'drawn_or_tutored_entries': 0, 'first_access_turn': None, 'first_seen_turn': 1, 'first_use_turn': 1, 'instant_sorcery_cast_entries': 0, 'land_played_entries': 0, 'natural_access_entries': 0, 'noncreature_cast_entries': 0, 'opening_or_candidate_hand_entries': 0, 'total_observation_entries': 140, 'tutored_entries': 0, 'access_minus_use_entries': -140}`

## Arena ID Annotations

- `87584`: `{'arena_id': '87584', 'name': 'Mountain', 'oracle_id': 'a3fb7228-e76b-4e96-a40e-20b5fed75685', 'resolved': True, 'scryfall_id': 'adf13285-d127-4534-9f49-aa86914da175'}`
- `87578`: `{'arena_id': '87578', 'name': 'Plains', 'oracle_id': 'bc71ebf6-2056-41f7-be35-b2e5c34afa99', 'resolved': True, 'scryfall_id': '5bb495cc-9908-455e-bec9-3993d595f4f9'}`
- `87586`: `{'arena_id': '87586', 'name': 'Forest', 'oracle_id': 'b34bb2dc-c1af-4d77-b0b3-a0fb342a5fc6', 'resolved': True, 'scryfall_id': '07264de1-4322-4adb-8f08-c0aa236747c7'}`
- `87579`: `{'arena_id': '87579', 'name': 'Island', 'oracle_id': 'b2c6aa39-2d2a-459c-a555-fb48ba993373', 'resolved': True, 'scryfall_id': 'bbeca27a-6c5b-40b9-83a4-a3a2096ff6f8'}`
- `1`: `{'arena_id': '1', 'resolved': False, 'skipped': True, 'reason': 'likely_hidden_or_unknown_marker'}`
- `87580`: `{'arena_id': '87580', 'name': 'Island', 'oracle_id': 'b2c6aa39-2d2a-459c-a555-fb48ba993373', 'resolved': True, 'scryfall_id': '671516eb-b088-4a15-aec9-1781ca016e11'}`
- `87582`: `{'arena_id': '87582', 'name': 'Swamp', 'oracle_id': '56719f6a-1a6c-4c0a-8d21-18f7d7350b68', 'resolved': True, 'scryfall_id': 'd86cd8fb-4ba7-4311-b0f3-b06fa112eda5'}`
- `87483`: `{'arena_id': '87483', 'error': 'curl: (56) The requested URL returned error: 404', 'resolved': False}`
- `87011`: `{'arena_id': '87011', 'name': 'Plains', 'oracle_id': 'bc71ebf6-2056-41f7-be35-b2e5c34afa99', 'resolved': True, 'scryfall_id': '486fbcf9-3a04-47f6-8927-886c2a454499'}`
- `87457`: `{'arena_id': '87457', 'resolved': False, 'skipped': True}`
- `87155`: `{'arena_id': '87155', 'name': "Miner's Guidewing", 'oracle_id': 'eb161d0b-e534-463c-b1d1-7210bfba5d28', 'resolved': True, 'scryfall_id': '9048cd9d-df3f-4705-a5f4-e5b09760c631'}`
- `87460`: `{'arena_id': '87460', 'resolved': False, 'skipped': True}`
- `87454`: `{'arena_id': '87454', 'resolved': False, 'skipped': True}`
- `87585`: `{'arena_id': '87585', 'resolved': False, 'skipped': True}`
- `87207`: `{'arena_id': '87207', 'name': 'Oaken Siren', 'oracle_id': 'a06a35a9-a23e-4a0a-90bc-84e7a52d2cef', 'resolved': True, 'scryfall_id': 'd7731ef5-da74-4436-8ee7-01c065cbefae'}`
- `87149`: `{'arena_id': '87149', 'name': 'Ironpaw Aspirant', 'oracle_id': 'fab5f694-4a9c-4e72-b164-f236e8212ff7', 'resolved': True, 'scryfall_id': 'f70689a0-ac69-4052-84fc-9055e9e1c54b'}`
- `87220`: `{'arena_id': '87220', 'name': 'Spyglass Siren', 'oracle_id': '4ec9d9eb-14e2-47ea-88a2-d2394e363784', 'resolved': True, 'scryfall_id': '41e54343-95e5-4dc4-9f18-e4a415fe5e0a'}`
- `87302`: `{'arena_id': '87302', 'name': 'Goblin Tomb Raider', 'oracle_id': '37ce95bb-8ff5-47b9-85e4-21be7a794940', 'resolved': True, 'scryfall_id': '018160fe-f602-43f5-8495-241a08eaa69c'}`
- `87214`: `{'arena_id': '87214', 'resolved': False, 'skipped': True}`
- `87485`: `{'arena_id': '87485', 'resolved': False, 'skipped': True}`

## Next Integration Steps

- Persist this profile as an artifact, not a database write.
- Use the normalized event schema as an adapter target for ManaLoom battle replay comparators.
- Add per-card observation gates to deckbuilder experiments so substitutions are scored only when drawn/cast/used.
- Use Scryfall arena_id resolution only as a cache-backed annotation layer.
