# 17Lands replay_data Profile

- Generated at: `2026-06-28T17:41:31+00:00`
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

## What This Must Not Be Used For

- Do not promote card battle rules directly from replay_data.
- Do not treat PremierDraft behavior as Commander/Lorehold strategy proof.
- Do not infer exact stack, target selection, replacement effects, or hidden choices from these columns alone.

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
- Card-like Arena IDs top: `{'87155': 656, '87584': 618, '87578': 522, '87579': 490, '87580': 468, '87586': 425, '87483': 401, '87207': 380, '87302': 363, '87220': 351, '87227': 325, '87160': 307, '87313': 303, '87582': 288, '87149': 283, '87011': 280, '87214': 269, '87228': 262, '87186': 187, '87473': 183, '87326': 182, '87460': 179, '87244': 176, '87134': 166, '87454': 161, '87457': 157, '87133': 152, '87386': 150, '87287': 146, '1268': 145, '87199': 142, '116886': 140, '87264': 137, '87217': 135, '87423': 133, '87319': 130, '169531': 124, '87221': 121, '87366': 118, '1319': 118, '87146': 116, '87328': 112, '87179': 111, '87175': 109, '87279': 107, '87166': 107, '87365': 102, '87439': 101, '87455': 101, '87017': 101, '87239': 100, '87412': 98, '87321': 97, '87329': 97, '87480': 96, '87197': 96, '87142': 94, '87303': 94, '87241': 93, '84596': 92, '87285': 90, '87585': 88, '169432': 88, '87246': 88, '87281': 87, '87150': 84, '87474': 84, '87390': 84, '87368': 80, '87167': 79, '87409': 79, '87248': 78, '87332': 76, '87163': 74, '87306': 73, '87375': 72}`

## Arena ID Notes

- Small numeric IDs can be hidden/unknown Arena-side markers in replay_data, not Scryfall-resolvable cards.
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

## Arena ID Annotations

- `1`: `{'arena_id': '1', 'resolved': False, 'skipped': True, 'reason': 'likely_hidden_or_unknown_marker'}`
- `87155`: `{'arena_id': '87155', 'name': "Miner's Guidewing", 'oracle_id': 'eb161d0b-e534-463c-b1d1-7210bfba5d28', 'resolved': True, 'scryfall_id': '9048cd9d-df3f-4705-a5f4-e5b09760c631'}`
- `87584`: `{'arena_id': '87584', 'name': 'Mountain', 'oracle_id': 'a3fb7228-e76b-4e96-a40e-20b5fed75685', 'resolved': True, 'scryfall_id': 'adf13285-d127-4534-9f49-aa86914da175'}`
- `87578`: `{'arena_id': '87578', 'name': 'Plains', 'oracle_id': 'bc71ebf6-2056-41f7-be35-b2e5c34afa99', 'resolved': True, 'scryfall_id': '5bb495cc-9908-455e-bec9-3993d595f4f9'}`
- `87579`: `{'arena_id': '87579', 'name': 'Island', 'oracle_id': 'b2c6aa39-2d2a-459c-a555-fb48ba993373', 'resolved': True, 'scryfall_id': 'bbeca27a-6c5b-40b9-83a4-a3a2096ff6f8'}`
- `87580`: `{'arena_id': '87580', 'name': 'Island', 'oracle_id': 'b2c6aa39-2d2a-459c-a555-fb48ba993373', 'resolved': True, 'scryfall_id': '671516eb-b088-4a15-aec9-1781ca016e11'}`
- `87586`: `{'arena_id': '87586', 'name': 'Forest', 'oracle_id': 'b34bb2dc-c1af-4d77-b0b3-a0fb342a5fc6', 'resolved': True, 'scryfall_id': '07264de1-4322-4adb-8f08-c0aa236747c7'}`
- `87483`: `{'arena_id': '87483', 'error': 'curl: (56) The requested URL returned error: 404', 'resolved': False}`
- `2`: `{'arena_id': '2', 'resolved': False, 'skipped': True, 'reason': 'likely_hidden_or_unknown_marker'}`
- `87207`: `{'arena_id': '87207', 'name': 'Oaken Siren', 'oracle_id': 'a06a35a9-a23e-4a0a-90bc-84e7a52d2cef', 'resolved': True, 'scryfall_id': 'd7731ef5-da74-4436-8ee7-01c065cbefae'}`
- `87302`: `{'arena_id': '87302', 'name': 'Goblin Tomb Raider', 'oracle_id': '37ce95bb-8ff5-47b9-85e4-21be7a794940', 'resolved': True, 'scryfall_id': '018160fe-f602-43f5-8495-241a08eaa69c'}`
- `87220`: `{'arena_id': '87220', 'name': 'Spyglass Siren', 'oracle_id': '4ec9d9eb-14e2-47ea-88a2-d2394e363784', 'resolved': True, 'scryfall_id': '41e54343-95e5-4dc4-9f18-e4a415fe5e0a'}`
- `87227`: `{'arena_id': '87227', 'name': 'Waterwind Scout', 'oracle_id': 'db65f874-6bf3-4fdb-a977-10b01b7ee2e9', 'resolved': True, 'scryfall_id': '8a7738fb-0a1b-4010-b8c0-e1129739c765'}`
- `87160`: `{'arena_id': '87160', 'name': 'Oltec Cloud Guard', 'oracle_id': '922a8e27-a367-40c6-84df-86ed32f71c7c', 'resolved': True, 'scryfall_id': '02d68a38-2e0b-401b-b67d-a55e2af5b18d'}`
- `87313`: `{'arena_id': '87313', 'name': 'Plundering Pirate', 'oracle_id': '3ab13412-1eaf-40c0-905d-8a3ca0c51be5', 'resolved': True, 'scryfall_id': '5bb2552f-8370-4931-83e1-93706d51413a'}`
- `87582`: `{'arena_id': '87582', 'name': 'Swamp', 'oracle_id': '56719f6a-1a6c-4c0a-8d21-18f7d7350b68', 'resolved': True, 'scryfall_id': 'd86cd8fb-4ba7-4311-b0f3-b06fa112eda5'}`
- `87149`: `{'arena_id': '87149', 'name': 'Ironpaw Aspirant', 'oracle_id': 'fab5f694-4a9c-4e72-b164-f236e8212ff7', 'resolved': True, 'scryfall_id': 'f70689a0-ac69-4052-84fc-9055e9e1c54b'}`
- `87011`: `{'arena_id': '87011', 'name': 'Plains', 'oracle_id': 'bc71ebf6-2056-41f7-be35-b2e5c34afa99', 'resolved': True, 'scryfall_id': '486fbcf9-3a04-47f6-8927-886c2a454499'}`
- `87214`: `{'arena_id': '87214', 'resolved': False, 'skipped': True}`
- `87228`: `{'arena_id': '87228', 'resolved': False, 'skipped': True}`

## Next Integration Steps

- Persist this profile as an artifact, not a database write.
- Use the normalized event schema as an adapter target for ManaLoom battle replay comparators.
- Add per-card observation gates to deckbuilder experiments so substitutions are scored only when drawn/cast/used.
- Use Scryfall arena_id resolution only as a cache-backed annotation layer.
